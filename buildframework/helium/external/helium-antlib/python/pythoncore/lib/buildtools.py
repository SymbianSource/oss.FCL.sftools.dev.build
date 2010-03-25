#============================================================================ 
#Name        : buildtools.py 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description:
#===============================================================================

"""Enables creation of build command list in several formats.

This module implements class that represent shell commands.
It supports build stage and command parallelization (depends of the output format).
CommandList can be generated in different format: ant, make, ebs, batch.

Example:
from mc.buildtools import CommandList, Convert
list = CommandList()
list.addCommand("\\epoc32\\rombuild", "make_fpsx.bat..yy...", "build_xx_rom")
list.addCommand("\\epoc32\\rombuild", "make_fpsx.bat..xx...", "build_yy_rom")
list.addCommand("\\epoc32\\rombuild", "copy \\foo \\bar", "simple copy", False)

convert(list, "outputfile.mk", "make")
convert(list, "outputfile.ant.xml", "ant")
convert(list, "outputfile.ebs.xml", "ebs")
convert(list, "outputfile.bat", "bat")

"""
import os
import types
import xml.dom.minidom
import sys

class PreBuilder(object):
    """ This class implements an abstract prebuilder.
        A prebuilder takes a configurationset as input and generates a build file.
    """
    def __init__(self, configSet):
        self.configSet = configSet
        # Select the first configuration as a default, for referencing common properties
        self.config = None
        configs = configSet.getConfigurations()
        if len(configs) > 0:
            self.config = configs[0]

    def writeBuildFile(self, taskList, buildFilePath, output='ant'):
        """ Converting a task list into output format and writing it into buildFilePath file. """
        writer = None
        buildFileDir = os.path.dirname(buildFilePath)
        if len(buildFileDir) > 0 and not os.path.exists(buildFileDir):
            os.makedirs(buildFileDir)
        writer = get_writer(output, open(buildFilePath, 'w'))
        writer.write(taskList)


class Task(object):
    """ Abstract Task object. """
    pass

        
class Command(Task):
    """
        This class implements a command definition.
        It handles command id and stage.
        All command from one stage should be finished before starting the next stage.
    """
    def __init__(self, executable, path, args=None, name=''):
        Task.__init__(self)
        if args == None:
            args = []
        self._id  = 1
        self._stage = 1
        self._name = name
        self._executable = executable
        self._path = path
        self._args = args

    def setJobId(self, idn):
        """ Set the command id. """
        self._id = idn

    def setStage(self, stage):
        """ Set the command stage. """
        self._stage = stage

    def jobId(self):
        """ Get the command id. """
        return self._id

    def stage(self):
        """ Get the command stage. """
        return self._stage

    def name(self):
        """ Get the command name. """
        return self._name

    def executable(self):
        """ Get the command executable. """
        return self._executable

    def path(self):
        """ Get the command path. """
        return self._path

    def cmd(self):
        """ Get the command line. """
        return ' '.join(self._args)

    def addArg(self, arg):
        """ Add a command line argument. """
        self._args.append(arg)

    def __repr__(self):
        argsString = ' '.join(self._args)
        return "%s: %s: %s" % (self.name(), self.path(), argsString)


class AntTask(Task):
    """ Interface that defines supports for an Ant task rendering. """
    
    def toAntTask(self, doc):
        """ Override this method to convert a specific command into Ant command.
            e.g: Delete Class will use delete task from Ant, else convert into perl ... remove filename.__getCommandByStage
        """ 
        pass


class Delete(AntTask, Command):
    """ Implements file/directory deleletion mechanism. """
    
    def __init__(self, filename=None, dirname=None):
        Command.__init__(self, "perl", "")
        AntTask.__init__(self)
        self._filename = filename
        self._dir = dirname
        self._args.append("-MExtUtils::Command")
        self._args.append("-e")
        if self._filename != None:
            self._args.append("rm_f")
            self._args.append('"' + self._filename + '"')
        elif self._dir != None:
            self._args.append("rm_rf")
            self._args.append('"' + self._dir + '"')

    def toAntTask(self, doc):
        """ Render the delete as an Ant task. """
        node = doc.createElementNS("", "delete")
        node.setAttributeNS("", "verbose", "true")
        node.setAttributeNS("", "failonerror", "false")
        if self._filename != None:
            node.setAttributeNS("", "file", self._filename)
        elif self._dir != None:
            node.setAttributeNS("", "dir", self._dir)
        return node


class Copy(AntTask, Command):
    """ Implement copy command. """
    def __init__(self, srcFile, todir):
        Command.__init__(self, "perl", os.path.dirname(srcFile))
        AntTask.__init__(self)
        self.srcFile = srcFile
        self.todir = todir
        self._args.append("-MExtUtils::Command")
        self._args.append("-e")
        self._args.append("cp")
        self._args.append('"' + self.srcFile + '"')
        self._args.append('"' + os.path.join(self.todir, os.path.basename(self.srcFile)) + '"')
        
    def toAntTask(self, doc):
        """ Render the copy as an Ant task. """
        node = doc.createElementNS("", "copy")
        node.setAttributeNS("", "verbose", "true")
        node.setAttributeNS("", "failonerror", "false")
        node.setAttributeNS("", "file", self.srcFile)
        node.setAttributeNS("", "todir", self.todir)
        node.setAttributeNS("", "overwrite", "true")
        return node
         

class CommandList(object):
    """
        This class allows to safely handle Command object into lists
    """
    def __init__(self):
        self.__cmds = []

    def allCommands(self):
        """ Returns all command list. """
        return self.__cmds

    def addCommand(self, cmd, newstage=False):
        """ Add a Command to the list. """
        stage = 1
        idn = 1
        if len(self.__cmds) > 0:
            lastcmd = self.__cmds[-1]
            idn = lastcmd.jobId() + 1
            stage = lastcmd.stage()
            if newstage:
                stage = stage + 1
        cmd.setStage(stage)
        cmd.setJobId(idn)
        self.__cmds.append(cmd)


class AbstractOutputWriter:
    """Base class which contains define an AbstractOutputWriter.

    The subclass must implement a convert method which compute a command list into
    some output file.
    """
    def __init__(self, fileOut):
        if isinstance(fileOut, basestring):
            self._fileOut = open(fileOut, 'w')
        else:
            self._fileOut = fileOut

    def write(self, cmdList):
        """ Method to override to implement format specific output. """
    def writeTopLevel(self, config_list, spec_name, output_path, xml_file):
        """ Method to override to implement top level commands. """

    def __call__(self, cmdList):
        self.write(cmdList)

    def close(self):
        """ Close the output stream. """
        self._fileOut.close()

    def __del__(self):
        self.close()


class StringWriter(AbstractOutputWriter):
    """ Implements a Writer which is able to directly write to the output stream. """
    
    def __init__(self, fileOut):
        AbstractOutputWriter.__init__(self, fileOut)

    def write(self, content):
        """ Write content to the output. """
        self._fileOut.write(content)


class EBSWriter(AbstractOutputWriter):
    """ Implements EBS XML output format. """
    
    def __init__(self, fileOut):
        AbstractOutputWriter.__init__(self, fileOut)

    def write(self, cmdList):
        """ Write the command list to EBS format. """
        doc = xml.dom.minidom.Document()
        productnode = doc.createElementNS("", "Product")
        cmdsnode = doc.createElementNS("", "Commands")
        productnode.appendChild(cmdsnode)
        doc.appendChild(productnode)

        for cmd in cmdList.allCommands():
            cmdsnode.appendChild(self.__commandToXml(doc, cmd))

        self._fileOut.write(doc.toprettyxml())

    @staticmethod
    def __commandToXml(doc, cmd):
        """ Convert a Command into an EBS command. """
        # <Execute ID="1" Stage="1" Component="MAS" Cwd="%EPOCROOT%" CommandLine="getrel MAS 92_013_Symbian_OS"/>
        cmdsnode = doc.createElementNS("", "Execute")
        cmdsnode.setAttributeNS("", "ID", "%d" % cmd.jobId())
        cmdsnode.setAttributeNS("", "Stage", "%d" % cmd.stage())
        cmdsnode.setAttributeNS("", "Component", cmd.name())
        cmdsnode.setAttributeNS("", "Cwd", cmd.path())
        cmdsnode.setAttributeNS("", "CommandLine", cmd.executable()+" "+cmd.cmd())
        return cmdsnode


class AntWriter(AbstractOutputWriter):
    """ Implements Ant XML output format. """
    
    def __init__(self, fileOut):
        AbstractOutputWriter.__init__(self, fileOut)

    def writeTopLevel(self, config_list, spec_name, output_path, xml_file):
        doc = xml.dom.minidom.Document()
        projectnode = doc.createElementNS("", "project")
        projectnode.setAttributeNS("", "name", '')
        projectnode.setAttributeNS("", "default", "all")
        projectnode.setAttributeNS("", "xmlns:hlm", "http://www.nokia.com/helium")
        doc.appendChild(projectnode)
        target = doc.createElementNS("", "target")
        target.setAttributeNS("", "name", "all")
        projectnode.appendChild(target)

        parallel = doc.createElementNS("", "parallel")
        parallel.setAttributeNS("", "threadCount", "${number.of.threads}")
        target.appendChild(parallel)
        index = 0
        for config in config_list:
            sequential = doc.createElementNS("", "sequential")
            outputfile = os.path.normpath(os.path.join(output_path, config + ".xml"))
            exec_element = doc.createElementNS("", "hlm:exec")
            exec_element.setAttributeNS("", "executable", "python")
            exec_element.setAttributeNS("", "failonerror", "true")

            args = doc.createElementNS("", "arg")
            args.setAttributeNS("", "line", "-m CreateZipInput")
            exec_element.appendChild(args)

            args = doc.createElementNS("", "arg")
            args.setAttributeNS("", "line", "--output=%s" % outputfile)
            exec_element.appendChild(args)
            args = doc.createElementNS("", "arg")
            args.setAttributeNS("", "line", "--config=%s" % spec_name)
            exec_element.appendChild(args)
            args = doc.createElementNS("", "arg")
            args.setAttributeNS("", "line", "--filename=%s" % xml_file)
            exec_element.appendChild(args)
            args = doc.createElementNS("", "arg")
            args.setAttributeNS("", "line", "--id=%d" % index)
            exec_element.appendChild(args)
            args = doc.createElementNS("", "arg")
            args.setAttributeNS("", "line", "--writertype=ant")
            exec_element.appendChild(args)
            sequential.appendChild(exec_element)
            index += 1
            ant_exec = doc.createElementNS("", "ant")
            ant_exec.setAttributeNS("", "antfile", outputfile)
            sequential.appendChild(ant_exec)
            parallel.appendChild(sequential)
        
        self._fileOut.write(doc.toprettyxml())
        self._fileOut.close()
        
    def write(self, cmdList):
        """ Writes the command list to Ant format. """
        doc = xml.dom.minidom.Document()
        projectnode = doc.createElementNS("", "project")
        projectnode.setAttributeNS("", "name", '')
        projectnode.setAttributeNS("", "default", "all")
        projectnode.setAttributeNS("", "xmlns:hlm", "http://www.nokia.com/helium")
        doc.appendChild(projectnode)

        stages = self.__getCommandByStage(cmdList)

        for stage in stages.keys():
            projectnode.appendChild(self.__stageToTarget(doc, stage, stages[stage]))

        target = doc.createElementNS("", "target")
        target.setAttributeNS("", "name", "all")
        def __toStage(stage):
            """ Convert the stage id into and Ant target name. """
            return "stage%s" % stage
        target.setAttributeNS("", "depends", ','.join([__toStage(stage) for stage in stages.keys()]))
        projectnode.appendChild(target)

        self._fileOut.write(doc.toprettyxml())

    def __stageToTarget(self, doc, stage, cmds):
        """ Convert a stage into an Ant target. """
        target = doc.createElementNS("", "target")
        target.setAttributeNS("", "name", "stage%s" % stage)
        parallel = doc.createElementNS("", "parallel")
        parallel.setAttributeNS("", "threadCount", "${number.of.threads}")
        target.appendChild(parallel)

        for cmd in cmds:
            parallel.appendChild(self.__commandToAnt(doc, cmd))
        return target

    @staticmethod
    def __commandToAnt(doc, cmd):
        """ Convert a command into an Ant task. """
        # does the API support Ant task conversion.
        # else treat it as a cmd
        if issubclass(type(cmd), AntTask):
            return cmd.toAntTask(doc)
        else:
            execnode = doc.createElementNS("", "hlm:exec")
            execnode.setAttributeNS("", "executable", cmd.executable())
            execnode.setAttributeNS("", "dir", cmd.path())
            arg = doc.createElementNS("", "arg")
            arg.setAttributeNS("", "line", cmd.cmd())
            execnode.appendChild(arg)
            return execnode

    @staticmethod
    def __getCommandByStage(cmdList):
        """ Reorder a CommandList into a list of stages. """
        stages = {}
        for cmd in cmdList.allCommands():
            if not stages.has_key(cmd.stage()):
                stages[cmd.stage()]=[]
            stages[cmd.stage()].append(cmd)

        return stages


class MakeWriter(AbstractOutputWriter):
    """ Implements Makefile writer. """
    
    def __init__(self, fileOut):
        AbstractOutputWriter.__init__(self, fileOut)

    def writeTopLevel(self, config_list, spec_name, output_path, xml_file):
        content = "\n\nall: zip_inputs zip_files\n\n"
        index = 0
        input_list = "zip_inputs: "
        zip_list = "\n\nzip_files: "
        full_content = ""
        script_path =  os.path.normpath(os.path.join(os.environ['HELIUM_HOME'], 'tools/compile/ec'))
        for config in config_list:
            outputfile = os.path.normpath(os.path.join(output_path, config + ".mk"))
            input_list += " \\\n\t zip_input%d" % index
            zip_list += " \\\n\t zip_files%d" % index
            content += "\n\nzip_input%d :\n" % index
            content += "\t@echo === identifying files for %s\n" % config
            
            content += "\tpython -m CreateZipInput --config=%s --filename=%s --id=%d --output=%s --writertype=%s\n\n" % (spec_name, xml_file, index, outputfile,'make')
            content += "\n\nzip_files%d :zip_input%d\n" % (index, index)
            content += "\t@echo === identifying files for %s\n" % config
            content += "\t$(MAKE) -f %s" % (outputfile)
            index += 1
        
        full_content += input_list
        full_content += zip_list
        full_content += content
        self._fileOut.write(full_content)
    def write(self, cmdList):
        """ Converts the list of command into Makefile. """
        stages = {}
        for cmd in cmdList.allCommands():
            if not stages.has_key(cmd.stage()):
                stages[cmd.stage()] = []
            stages[cmd.stage()].append(cmd)
        
        # Write the all rule
        def __toStage(stage):
            """ Convert stage Id into a target name. """
            return "stage%s" % stage
                
        #self._fileOut.write("all : %s\n" % ' '.join(map(__toStage, max(stages.keys())))
        if len(stages.keys()) > 0:
            self._fileOut.write("all : stage%s ;\n" % max(stages.keys()))
        else:
            self._fileOut.write("all: ;\n")
            
        for stage in stages.keys():
            # Write each stage rule
            def __toId(cmd):
                """ Convert command Id into a target name. """
                self.__commandToTarget(cmd)
                return "id%s" % cmd.jobId()
            self._fileOut.write("stage%s : %s\n" % (stage, ' '.join([__toId(task) for task in stages[stage]])))

    def __commandToTarget(self, cmd):
        """ Converting a Command into a Makefile target. """
        deps = ""
        if cmd.stage() > 1:
            deps = " stage%s" % (cmd.stage() - 1)
        self._fileOut.write("id%s:%s\n" % (cmd.jobId(), deps))
        self._fileOut.write("\t@echo Target %s\n" % cmd.name())
        winargs = ""
        if os.sep == '\\':
            winargs = "/d"
        self._fileOut.write("\tcd %s %s && %s " % (winargs, cmd.path(), cmd.executable()))
        self._fileOut.write("%s\n" % cmd.cmd())
        self._fileOut.write("\n")


__writerConstructors = { 'ant': AntWriter,
                         'make': MakeWriter,
                         'ebs': EBSWriter }


def convert(cmdList, filename, outputtype="ant"):
    """ Helper to directly convert a command list into a specific runnable command format.
        e.g:
        cmdList = CommandList()
        cmdList.addCommand(...)
        convert(cmdList, "echo Hello world", "ant")
    """
    writer = __writerConstructors[outputtype](filename)
    writer(cmdList)


def get_writer(buildTool, fileOut):
    """ Get a Writer for a specific format. """
    return __writerConstructors[buildTool](fileOut)


def supported_writers():
    """ Return the list of supported Writer. """
    return __writerConstructors.keys()


