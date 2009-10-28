#============================================================================ 
#Name        : io.py 
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
# pylint: disable-msg=W0212,W0141
""" IO module for SystemDefinitionFile.
    - Allow convertion to m,a 
"""
import re
import sys
import os
import buildtools
import sysdef.api

def path_to_makefile_echo(path):
    """ Cleanup the path to transfer it to the makefile.
        This is needed for echo command for example.
    """
    result = os.path.join(os.environ['EPOCROOT'], path)
    result = re.sub(r'(.*(?:\\\\)*)\\$', r'\1\\\\', result)
    return result

def path_to_makefile_command(path):
    """ Cleanup the path to transfer it to the makefile.
        This is needed for echo command for example.
    """
    result = re.sub(r'%EPOCROOT%', '', path)
    return result


def command_to_makefile(cmd):
    return re.sub(r'(.*(?:\\\\)*)\\\s*$', r'\1\\\\', cmd)

def command_to_echo(cmd):
    """ Precede special characters with a caret so
        that they can output with the DOS echo command 
    """
    result = re.sub(r'\|', r'^|', cmd)
    result = re.sub(r'&', r'^&', result)
    result = re.sub(r'>', r'^>', result)
    result = re.sub(r'<', r'^<', result)
    return result

def get_localtime_command(title='Started at'): 
    return "perl -e \"print '++ %s '.localtime().\\\"\\n\\\"\"" % title

def get_hires_command(title='Start'): 
    return "perl -e \"use Time::HiRes; print '+++ HiRes %s '.Time::HiRes::time().\\\"\\n\\\";\"" % title

def is_abld_what_or_check_command(command):
    """ This function is used to determined if the command is using -c/-w/-what/-check flag. """
    return re.match(r'abld\s+(\w+\s+)*(-c(heck)?|-w(hat)?)(\s+.*)?', command) != None

def to_target(name):
    return re.sub("\s", "_", name)


class MakeWriter(buildtools.AbstractOutputWriter):
    def __init__(self, output):
        buildtools.AbstractOutputWriter.__init__(self, output)
                 
    def write(self, sdf):
        self._fileOut.write("# Generated makefile\n")
        for option in sdf._options:
            self._fileOut.write("%s := %s\n\n" % (option, sdf._options[option].filteredOption))
        for cf in sdf._configurations:
            self._configuration_to_makefile(sdf._configurations[cf])
    
    def _configuration_to_makefile(self, config):
        sys.stderr.write(" * Generating configuration %s\n" % config.name)
        
        self._fileOut.write("%s-UNITLIST := " % config.target)
        
        for unit in config.units():
            self._fileOut.write(" \\\n   %s" % unit.path)
        
        self._fileOut.write("\n\n")    
        self._fileOut.write("%s:\n" % config.target)
        mainoutput = ""
        for task in config.tasks:
            self._fileOut.write(self._task_to_makefile_target(task))
            mainoutput +=  task._task_to_makefile()
        
        self._fileOut.write("\n\n" + mainoutput)
       
    def _task_to_makefile(self, task):
        output = ""
        if isinstance(task.job, sysdef.api.BuildLayer):
            if len(task.job.targetList) > 0:        
                output += "%s-buildLayer-%s:" % (task.job.config.target, task.job.target)
                for target in task.job.targetList:
                    output += " $(foreach UNIT,$(%s-UNITLIST),$(UNIT)-command-%s-%s)" % (task.job.config.target, task.job.target, target.target)
                output += "\n\n"                 
                for target in task.job.targetList:
                    if is_abld_what_or_check_command(task.job.command):
                        command = "%s %s" % (task.job.command, target.abldTarget)
                    else: 
                        command = "%s $(KEEPGOING) %s" % (task.job.command, target.abldTarget) 
                    output += "%%-command-%s-%s:\n" % (task.job.target, target.target) 
                    output += "\t@echo === Stage=%s == $*\n" % task.job.target             
                    output += "\t@echo --- ElectricCloud Executed ID %s\n" % command_to_makefile(command_to_echo(command))
                    output += "\t@echo -- %s\n" % command_to_makefile(command_to_echo(command))
                    output += "\t-@%s\n" % get_localtime_command()
                    output += "\t-@%s\n" % get_hires_command()
                    output += "\t@echo Chdir $*\n" 
                    output += "\t-@cd $* && %s\n" % command_to_makefile(command) 
                    output += "\t-@%s\n" % get_localtime_command("End")
                    output += "\t-@%s\n" % get_localtime_command("Finished at")
            else:
                if not is_abld_what_or_check_command(task.job.command):
                    command = "%s $(KEEPGOING)" % task.job.command
                else:
                    command = task.job.command
                output += "%s-buildLayer-%s: $(foreach UNIT,$(%s-UNITLIST),$(UNIT)-command-%s)\n\n" % (task.job.config.target, task.job.target, task.job.config.target, task.job.target)
                output += "%%-command-%s:\n" % task.job.target 
                output += "\t@echo === Stage=%s == $*\n" % task.job.target           
                output += "\t@echo --- ElectricCloud Executed ID %s\n" % command_to_makefile(command_to_echo(command))
                output += "\t@echo -- %s\n" % re.sub(r'\|', r'^|', command)
                output += "\t-@%s\n" % get_localtime_command()
                output += "\t-@%s\n" % get_hires_command()
                output += "\t@echo Chdir $*\n" 
                output += "\t-@cd $* && %s\n" % command_to_makefile(command) 
                output += "\t-@%s\n" % get_localtime_command("End")
                output += "\t-@%s\n\n" % get_localtime_command("Finished at")
            
        return output
    
    def _task_to_makefile_target(self, task):
        output = ""
        if isinstance(task.job, sysdef.api.SpecialInstruction):
            output = ("\t@echo ===-------------------------------------------------\n")
            output += ("\t@echo === Stage=%s\n" % task.job.name)
            output += ("\t@echo ===-------------------------------------------------\n")
            output += ("\t-@perl -e \"print '=== Stage=%s started '.localtime().\\\"\\n\\\"\"\n" % task.job.name)
            output += "\t@echo === Stage=%s == %s\n" % (task.job.name, task.job.name)
            output += "\t@echo --- ElectricCloud Executed ID %s\n" % command_to_makefile(command_to_echo(task.job.command))
            output += "\t@echo -- %s\n" % command_to_makefile(command_to_echo(task.job.command))
            output += "\t-@%s\n" % get_localtime_command()
            output += "\t-@%s\n" % get_hires_command()
            output += "\t@echo Chdir %s\n" % path_to_makefile_echo(task.job.path)
            output += "\t-@cd %s && %s\n" % (os.path.join(os.path.sep, path_to_makefile_command(task.job.path)), command_to_makefile(task.job.command))
            output += "\t-@%s\n" % get_localtime_command("End")
            output += "\t-@%s\n\n" % get_localtime_command("Finished at")
            output += ("\t-@perl -e \"print '=== Stage=%s finished '.localtime().\\\"\\n\\\"\"\n\n" % task.job.name)
        else:
            output = ("\t@echo ===-------------------------------------------------\n")
            output += ("\t@echo === Stage=%s\n" % task.job.target)
            output += ("\t@echo ===-------------------------------------------------\n")
            output += ("\t-@perl -e \"print '=== Stage=%s started '.localtime().\\\"\\n\\\"\"\n" % task.job.target)
            output += "\t-@$(MAKE) -k %s-buildLayer-%s\n" % (task.job.config.target, task.job.target)
            output += ("\t-@perl -e \"print '=== Stage=%s finished '.localtime().\\\"\\n\\\"\"\n\n" % task.job.target)    
        return output
        
        
class MakeWriter2(buildtools.AbstractOutputWriter):
    def __init__(self, output):
        buildtools.AbstractOutputWriter.__init__(self, output)
        self._command_targets = {}
               
    def __read_file(self, filename):
        f = open(filename)
        content = f.read()
        f.close()
        return content
     
    def write(self, sdf):
        self._fileOut.write("# Generated makefile\n")
        self._fileOut.write(self.__read_file(os.path.join(os.environ['HELIUM_HOME'], 'tools/compile/ec/ec_functions.mk')))
        self._fileOut.write("\n\n")

        # options
        self._fileOut.write("\n# Options\n")
        for option in sdf._options:
            self._fileOut.write("%s := %s\n\n" % (option, sdf._options[option].filteredOption))
        self._fileOut.write("\n# Units\n")
        for unitid in sdf.units.keys():
            self._unit_to_makefile(sdf.units[unitid])
        self._fileOut.write("\n# Layers\n")
        for layerid in sdf.layers.keys():
            self._group_to_makefile(sdf.layers[layerid], "LAYER")        
        self._fileOut.write("\n# Unitlists\n")
        for unitlistid in sdf.unitlists.keys():            
            self._group_to_makefile(sdf.unitlists[unitlistid], "UNITLIST")

        self._fileOut.write("\n# Configurations\n")
        for cf in sdf.configurations.keys():
            self._configuration_to_makefile(sdf._configurations[cf])

        self._fileOut.write("\n# Helps\n")
        self._fileOut.write("\nhelp:\n")
        self._fileOut.write("\t@echo (e)make configurations           display all available configurations.\n")
        self._fileOut.write("\t@echo (e)make units                    display all available units.\n")
        
        self._fileOut.write("\nconfigurations:\n")
        for cf in sdf.configurations.keys():
            self._fileOut.write("\t@echo %s\n" % sdf._configurations[cf].name)

        self._fileOut.write("\nunits:\n")
        for unit in sdf.units.keys():
            self._fileOut.write("\t@echo %s\n" % sdf.units[unit].id)
                    
        
    def _unit_to_makefile(self, unit):
        self._fileOut.write("UNIT_%s:=%s|%s|%s\n" % (unit.id, unit.name, unit.path, " ".join(unit.filters)))

    def _group_to_makefile(self, group, gtype):
        self._fileOut.write("%s_%s:=" % (gtype, to_target(group.name)))
        for unit in group.units:
            self._fileOut.write(" \\\n%s" % unit.id)
        self._fileOut.write(" \n\n")
        
    def _configuration_to_makefile(self, config):        
        for task in config.tasks:
            self._fileOut.write(self._task_to_makefile(task))
        self._fileOut.write("\n\n")
         
        self._fileOut.write("%s: FILTERS=%s\n" % (config.name, " ".join(config.filters)))
        self._fileOut.write("%s:\n" % (config.name))        
        for task in config.tasks:
            self._fileOut.write(self._task_to_makefile_target(task))
            
        self._fileOut.write("\n\n")

    def _task_to_makefile(self, task):
        output = ""
        if isinstance(task.job, sysdef.api.BuildLayer):
            
            # generating the list of required unit groups
            glist = []
            for unitlist in task.job.config.unitlistrefs:
                glist.append("$(UNITLIST_%s)" % to_target(unitlist.name))
            for layer in task.job.config.layerrefs:
                glist.append("$(LAYER_%s)" % to_target(layer.name))

            if len(task.job.targetList) > 0:
                
                if not self._buildlayer_target_dep(task.job) in self._command_targets:                    
                    self._command_targets[self._buildlayer_target_dep(task.job)] = True
                    output += "%s:" % self._buildlayer_target_dep(task.job)
                    if task.job.unitParallel:                    
                        for target in task.job.targetList:
                            output += " $(foreach unit,$(call filter-unitlist,%s),$(unit)-command-%s-%s)" % (" ".join(glist), self._buildlayer_target(task.job), to_target(target.name))
                        output += "\n\n"
                    else:
                        output += " ; "
                        for target in task.job.targetList:
                            output += " $(foreach unit,$(call filter-unitlist,%s),$(call serialize,$(unit)-command-%s-%s))" % (" ".join(glist), self._buildlayer_target(task.job), to_target(target.name))
                        output += "\n\n"
                        
                                                 
                for target in task.job.targetList:
                    target_name = "%%-command-%s-%s" % (self._buildlayer_target(task.job), to_target(target.name))
                    if not target_name in self._command_targets:
                        self._command_targets[target_name] = True
                        if is_abld_what_or_check_command(task.job.command):
                            command = "%s %s" % (task.job.command, target.abldTarget)
                        else: 
                            command = "%s $(KEEPGOING) %s" % (task.job.command, target.abldTarget) 
                        output += "%s:\n" % target_name 
                        output += "\t@echo === Stage=%s == $(call get_unit_name,$*)\n" % self._buildlayer_target(task.job)            
                        output += "\t@echo --- ElectricCloud Executed ID $(call get_unit_name,$*)\n"
                        output += "\t@echo -- %s\n" % command_to_makefile(command_to_echo(command))
                        output += "\t-@%s\n" % get_localtime_command()
                        output += "\t-@%s\n" % get_hires_command()
                        output += "\t@echo Chdir $(call get_unit_path,$*)\n" 
                        output += "\t-@cd $(call get_unit_path,$*) && %s\n" % command_to_makefile(command) 
                        output += "\t-@%s\n" % get_localtime_command("End")
                        output += "\t-@%s\n" % get_localtime_command("Finished at")
                        output += "\n\n"                 
            else:                
                if not self._buildlayer_target_dep(task.job) in self._command_targets:
                    self._command_targets[self._buildlayer_target_dep(task.job)] = True
                    if task.job.unitParallel:
                        output += "%s: $(foreach unit,$(call filter-unitlist,%s),$(unit)-command-%s)\n\n" % (self._buildlayer_target_dep(task.job), 
                                                                                                         " ".join(glist), 
                                                                                                         self._buildlayer_target(task.job))
                    else:
                        output += "%s: ; $(foreach unit,$(call filter-unitlist,%s),$(call serialize,$(unit)-command-%s))\n\n" % (self._buildlayer_target_dep(task.job),
                                                                                                         " ".join(glist),
                                                                                                         self._buildlayer_target(task.job))
                        
                cmd_target_name = "%%-command-%s" % self._buildlayer_target(task.job)                
                if not cmd_target_name in self._command_targets: 
                    self._command_targets[cmd_target_name] = True                                    
                    if not is_abld_what_or_check_command(task.job.command):
                        command = "%s $(KEEPGOING)" % task.job.command
                    else:
                        command = task.job.command
                    output += "%s:\n" % cmd_target_name 
                    output += "\t@echo === Stage=%s == $(call get_unit_name,$*)\n" % self._buildlayer_target(task.job)           
                    output += "\t@echo --- ElectricCloud Executed ID %s\n" % command_to_makefile(command_to_echo(command))
                    output += "\t@echo -- %s\n" % command_to_makefile(command_to_echo(task.job.command))
                    output += "\t-@%s\n" % get_localtime_command()
                    output += "\t-@%s\n" % get_hires_command()
                    output += "\t@echo Chdir $(call get_unit_path,$*)\n" 
                    output += "\t-@cd $(call get_unit_path,$*) && %s\n" % command_to_makefile(command) 
                    output += "\t-@%s\n" % get_localtime_command("End")
                    output += "\t-@%s\n\n" % get_localtime_command("Finished at")            
        return output

    def _task_to_makefile_target(self, task):
        output = ""        
        if isinstance(task.job, sysdef.api.SpecialInstruction):
            output = ("\t@echo ===-------------------------------------------------\n")
            output += ("\t@echo === Stage=%s\n" % task.job.name)
            output += ("\t@echo ===-------------------------------------------------\n")
            output += ("\t-@perl -e \"print '=== Stage=%s started '.localtime().\\\"\\n\\\"\"\n" % task.job.name)
            output += "\t@echo === Stage=%s == %s\n" % (task.job.name, task.job.name)
            output += "\t@echo --- ElectricCloud Executed ID %s\n" % command_to_makefile(command_to_echo(task.job.command))
            output += "\t@echo -- %s\n" % command_to_makefile(command_to_echo(task.job.command))
            output += "\t-@%s\n" % get_localtime_command()
            output += "\t-@%s\n" % get_hires_command()
            output += "\t@echo Chdir %s\n" % path_to_makefile_echo(task.job.path)
            output += "\t-@cd %s && %s\n" % (os.path.join(os.path.sep, path_to_makefile_command(task.job.path)), command_to_makefile(task.job.command))
            output += "\t-@%s\n" % get_localtime_command("End")
            output += "\t-@%s\n" % get_localtime_command("Finished at")
            output += ("\t-@perl -e \"print '=== Stage=%s finished '.localtime().\\\"\\n\\\"\"\n\n" % task.job.name)
        else:
            output = ("\t@echo ===-------------------------------------------------\n")
            output += ("\t@echo === Stage=%s\n" % self._buildlayer_target(task.job))
            output += ("\t@echo ===-------------------------------------------------\n")
            output += ("\t-@perl -e \"print '=== Stage=%s started '.localtime().\\\"\\n\\\"\"\n" % self._buildlayer_target(task.job))
            output += "\t-@$(MAKE) $(MAKEFILE_CMD_LINE) -k %s \"FILTERS=$(FILTERS)\"\n" % self._buildlayer_target_dep(task.job)
            output += ("\t-@perl -e \"print '=== Stage=%s finished '.localtime().\\\"\\n\\\"\"\n\n" % self._buildlayer_target(task.job))    
        return output
    
    def _buildlayer_target(self, bl):
        cmd = bl.command + "_".join(map(lambda x: x.name, bl.targetList))
        cmd = re.sub("[\s]", "_", cmd)
        cmd = re.sub("[|]", "_pipe_", cmd)
        cmd = re.sub("[&]", "_and_", cmd)
        return cmd

    def _buildlayer_target_dep(self, bl):
        """ Generating target name for buildlayer:
             <config_name>-buildLayer-<_buildlayer_target_cmd>
        """
        return "%s-buildLayer-%s" % (to_target(bl.config.name), self._buildlayer_target(bl))

class MakeWriter3(buildtools.AbstractOutputWriter):    
    
    def __init__(self, output):
        buildtools.AbstractOutputWriter.__init__(self, output)
        self._command_targets = {}
        self.build_layers_always_parallel = True
               
    def __read_file(self, filename):
        f = open(filename)
        content = f.read()
        f.close()
        return content
     
    def write(self, sdf):
        self._fileOut.write("# Generated makefile\n")
        self._fileOut.write(self.__read_file(os.path.join(os.environ['HELIUM_HOME'], 'tools/compile/ec/ec_functions.mk')))
        self._fileOut.write("\n\n")

        # options
        self._fileOut.write("\n# Options\n")
        for option in sdf._options:
            self._fileOut.write("%s := %s\n\n" % (option, sdf._options[option].filteredOption))
        self._fileOut.write("\n# Units\n")
        for unitid in sdf.units.keys():
            self._unit_to_makefile(sdf.units[unitid])
        self._fileOut.write("\n# Layers\n")
        for layerid in sdf.layers.keys():
            self._group_to_makefile(sdf.layers[layerid], "LAYER")        
        self._fileOut.write("\n# Unitlists\n")
        for unitlistid in sdf.unitlists.keys():            
            self._group_to_makefile(sdf.unitlists[unitlistid], "UNITLIST")

        self._fileOut.write("\n# Configurations\n")
        for cf in sdf.configurations.keys():
            self._configuration_to_makefile(sdf._configurations[cf])

        self._fileOut.write("\n# Helps\n")
        self._fileOut.write("\nhelp:\n")
        self._fileOut.write("\t@echo (e)make configurations           display all available configurations.\n")
        self._fileOut.write("\t@echo (e)make units                    display all available units.\n")
        
        self._fileOut.write("\nconfigurations:\n")
        for cf in sdf.configurations.keys():
            self._fileOut.write("\t@echo %s\n" % sdf._configurations[cf].name)

        self._fileOut.write("\nunits:\n")
        for unit in sdf.units.keys():
            self._fileOut.write("\t@echo %s\n" % sdf.units[unit].id)
                    
        
    def _unit_to_makefile(self, unit):
        self._fileOut.write("UNIT_%s:=%s|%s|%s\n" % (unit.id, unit.name, unit.path, " ".join(unit.filters)))

    def _group_to_makefile(self, group, gtype):
        self._fileOut.write("%s_%s:=" % (gtype, to_target(group.name)))
        for unit in group.units:
            self._fileOut.write(" \\\n%s" % unit.id)
        self._fileOut.write(" \n\n")
        
    def _configuration_to_makefile(self, config):        
        for task in config.tasks:
            self._fileOut.write(self._task_to_makefile(task))
        self._fileOut.write("\n\n")
         
        self._fileOut.write("%s: FILTERS=%s\n" % (config.name, " ".join(config.filters)))
        self._fileOut.write("%s:" % (config.name))
        if len(config.tasks)>0:
            self._fileOut.write(" %s-task-%d" % (config.name, len(config.tasks)-1))
        else:
            self._fileOut.write(" ; @echo Nothing to do for configuration %s" % (config.name))
        self._fileOut.write("\n\n")
        
        count = 0
        for task in config.tasks:
            if count == 0:
                self._fileOut.write("%s-task-%d:\n" % (config.name, count))
            else:    
                self._fileOut.write("%s-task-%d: %s-task-%d\n" % (config.name, count, config.name, count-1))
            self._fileOut.write(self._task_to_makefile_target(task))
            count += 1
            
        self._fileOut.write("\n\n")

    def _task_to_makefile(self, task):
        output = ""
        if isinstance(task.job, sysdef.api.BuildLayer):
            
            # generating the list of required unit groups
            glist = []
            for unitlist in task.job.config.unitlistrefs:
                glist.append("$(UNITLIST_%s)" % to_target(unitlist.name))
            for layer in task.job.config.layerrefs:
                glist.append("$(LAYER_%s)" % to_target(layer.name))

            if len(task.job.targetList) > 0:
                
                if not self._buildlayer_target_dep(task.job) in self._command_targets:                    
                    self._command_targets[self._buildlayer_target_dep(task.job)] = True
                    output += "%s:" % self._buildlayer_target_dep(task.job)
                    if task.job.unitParallel or self.build_layers_always_parallel:                    
                        for target in task.job.targetList:
                            output += " $(foreach unit,$(call filter-unitlist,%s),$(unit)-command-%s-%s)" % (" ".join(glist), self._buildlayer_target(task.job), to_target(target.name))
                        output += "\n\n"
                    else:
                        output += " ; "
                        for target in task.job.targetList:
                            output += " $(foreach unit,$(call filter-unitlist,%s),$(call serialize,$(unit)-command-%s-%s))" % (" ".join(glist), self._buildlayer_target(task.job), to_target(target.name))
                        output += "\n\n"
                        
                                                 
                for target in task.job.targetList:
                    target_name = "%%-command-%s-%s" % (self._buildlayer_target(task.job), to_target(target.name))
                    if not target_name in self._command_targets:
                        self._command_targets[target_name] = True
                        if is_abld_what_or_check_command(task.job.command):
                            command = "%s %s" % (task.job.command, target.abldTarget)
                        else: 
                            command = "%s $(KEEPGOING) %s" % (task.job.command, target.abldTarget) 
                        output += "%s:\n" % target_name 
                        output += "\t@echo === Stage=%s == $(call get_unit_name,$*)\n" % self._buildlayer_target(task.job)            
                        output += "\t@echo --- ElectricCloud Executed ID $(call get_unit_name,$*)\n"
                        output += "\t@echo -- %s\n" % command_to_makefile(command_to_echo(command))
                        output += "\t-@%s\n" % get_localtime_command()
                        output += "\t-@%s\n" % get_hires_command()
                        output += "\t@echo Chdir $(call get_unit_path,$*)\n" 
                        output += "\t-@cd $(call get_unit_path,$*) && %s\n" % command_to_makefile(command) 
                        output += "\t-@%s\n" % get_localtime_command("End")
                        output += "\t-@%s\n" % get_localtime_command("Finished at")
                        output += "\n\n"                 
            else:                
                if not self._buildlayer_target_dep(task.job) in self._command_targets:
                    self._command_targets[self._buildlayer_target_dep(task.job)] = True
                    if task.job.unitParallel or self.build_layers_always_parallel:
                        output += "%s: $(foreach unit,$(call filter-unitlist,%s),$(unit)-command-%s)\n\n" % (self._buildlayer_target_dep(task.job), 
                                                                                                         " ".join(glist), 
                                                                                                         self._buildlayer_target(task.job))
                    else:
                        output += "%s: ; $(foreach unit,$(call filter-unitlist,%s),$(call serialize,$(unit)-command-%s))\n\n" % (self._buildlayer_target_dep(task.job),
                                                                                                         " ".join(glist),
                                                                                                         self._buildlayer_target(task.job))
                        
                cmd_target_name = "%%-command-%s" % self._buildlayer_target(task.job)                
                if not cmd_target_name in self._command_targets: 
                    self._command_targets[cmd_target_name] = True                                    
                    if not is_abld_what_or_check_command(task.job.command):
                        command = "%s $(KEEPGOING)" % task.job.command
                    else:
                        command = task.job.command
                    output += "%s:\n" % cmd_target_name 
                    output += "\t@echo === Stage=%s == $(call get_unit_name,$*)\n" % self._buildlayer_target(task.job)           
                    output += "\t@echo --- ElectricCloud Executed ID %s\n" % command_to_makefile(command_to_echo(command))
                    output += "\t@echo -- %s\n" % command_to_makefile(command_to_echo(task.job.command))
                    output += "\t-@%s\n" % get_localtime_command()
                    output += "\t-@%s\n" % get_hires_command()
                    output += "\t@echo Chdir $(call get_unit_path,$*)\n" 
                    output += "\t-@cd $(call get_unit_path,$*) && %s\n" % command_to_makefile(command) 
                    output += "\t-@%s\n" % get_localtime_command("End")
                    output += "\t-@%s\n\n" % get_localtime_command("Finished at")            
        return output

    def _task_to_makefile_target(self, task):
        output = ""        
        if isinstance(task.job, sysdef.api.SpecialInstruction):
            output = ("\t@echo ===-------------------------------------------------\n")
            output += ("\t@echo === Stage=%s\n" % task.job.name)
            output += ("\t@echo ===-------------------------------------------------\n")
            output += ("\t-@perl -e \"print '=== Stage=%s started '.localtime().\\\"\\n\\\"\"\n" % task.job.name)
            output += "\t@echo === Stage=%s == %s\n" % (task.job.name, task.job.name)
            output += "\t@echo --- ElectricCloud Executed ID %s\n" % command_to_makefile(command_to_echo(task.job.command))
            output += "\t@echo -- %s\n" % command_to_makefile(command_to_echo(task.job.command))
            output += "\t-@%s\n" % get_localtime_command()
            output += "\t-@%s\n" % get_hires_command()
            output += "\t@echo Chdir %s\n" % path_to_makefile_echo(task.job.path)
            output += "\t-@cd %s && %s\n" % (os.path.join(os.path.sep, path_to_makefile_command(task.job.path)), command_to_makefile(task.job.command))
            output += "\t-@%s\n" % get_localtime_command("End")
            output += "\t-@%s\n" % get_localtime_command("Finished at")
            output += ("\t-@perl -e \"print '=== Stage=%s finished '.localtime().\\\"\\n\\\"\"\n\n" % task.job.name)
        else:
            output = ("\t@echo ===-------------------------------------------------\n")
            output += ("\t@echo === Stage=%s\n" % self._buildlayer_target(task.job))
            output += ("\t@echo ===-------------------------------------------------\n")
            output += ("\t-@perl -e \"print '=== Stage=%s started '.localtime().\\\"\\n\\\"\"\n" % self._buildlayer_target(task.job))
            output += "\t-@$(MAKE) $(MAKEFILE_CMD_LINE) -k %s \"FILTERS=$(FILTERS)\"\n" % self._buildlayer_target_dep(task.job)
            output += ("\t-@perl -e \"print '=== Stage=%s finished '.localtime().\\\"\\n\\\"\"\n\n" % self._buildlayer_target(task.job))    
        return output
    
    def _buildlayer_target(self, bl):
        cmd = bl.command + "_".join(map(lambda x: x.name, bl.targetList))
        cmd = re.sub("[\s]", "_", cmd)
        cmd = re.sub("[|]", "_pipe_", cmd)
        cmd = re.sub("[&]", "_and_", cmd)
        return cmd

    def _buildlayer_target_dep(self, bl):
        """ Generating target name for buildlayer:
             <config_name>-buildLayer-<_buildlayer_target_cmd>
        """
        return "%s-buildLayer-%s" % (to_target(bl.config.name), self._buildlayer_target(bl))


class FlashImageSizeWriter(object):
    """ Writes a .csv file listing the content of the flash images. """
    def __init__(self, output):
        """ Initialisation. """
        self.output = output
        self._out = file(output, 'w')
        
    def write(self, sys_def, config_list):
        """ Write the .csv data to a file for the given System Definition and configuration name. """
        self._out.write('component,binary,rom,rofs1,rofs2,rofs3\n')
        for configuration in sys_def.configurations.values():
            #print configuration.name  
            if configuration.name in config_list:
                for unit in configuration.units:
                    #print str(unit.name) + '  ' + str(unit.binaries)
                    for binary in unit.binaries:
                        # Only print out the binaries for which there is size information
                        if hasattr(binary, 'size'):
                            rom_types = {'rom': 0, 'rofs1': 1, 'rofs2': 2, 'rofs3': 3}
                            rom_type_values = ['', '', '', '']
                            rom_type_values[rom_types[binary.rom_type]] = str(binary.size)
                            rom_type_text = ','.join(rom_type_values)
                            self._out.write('%s,%s,%s\n' % (unit.name, binary.name, rom_type_text))
                    
    def close(self):
        """ Closing the writer. """
        self._out.close()
    
    
    
