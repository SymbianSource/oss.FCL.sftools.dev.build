#============================================================================ 
#Name        : dependancygraph.py
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
"""create the dependancy graph for the documentation"""

import os
import amara
import codecs
import zipfile

class Library:
    """ Class Library holds information of the required modules or components such as license and the version """
    def __init__(self, name, license_, version=''):
        self.name = name
        self.license_ = license_
        self.version = version
        self.requires = []

class ModuleGroup:
    """ This class represents a group of module """
    def __init__(self):
        self.libraries = {}
    def addConf(self, name, des, color):
        """add configuration"""
        self.libraries[name] = (des, [], color)
    def addLibrary(self, conf, library):
        """add library"""
        for lib in self.getLibraries(conf):
            if lib.name.lower() == library.name.lower():
                lib.license_ = library.license_
                return
        self.getLibraries(conf).append(library)
    def getLibraries(self, conf):
        """get Libraries"""
        (_, libs, _) = self.libraries[conf]
        return libs
    def getDescription(self, conf):
        """get description"""
        (des, _, _) = self.libraries[conf]
        return des
    def getColor(self, conf):
        """get colour"""
        (_, _, color) = self.libraries[conf]
        return color

COLORS = ['pink', 'red', 'lightblue', 'orange', 'green', 'yellow', 'turquoise', 'limegreen']

class ReadIvyConfig:
    """ Class to read the ivy configuration """
    def __init__(self, ivyfilename):
        self.ivyfilename = ivyfilename
        self.ivyxml = amara.parse(open(ivyfilename))
        self.group = ModuleGroup()

    def readConfigurations(self):
        """read configurations"""
        for conf in self.ivyxml['ivy-module'].configurations.conf:
            color = COLORS.pop()
            self.group.addConf(conf.name, conf.description, color)

    def readModules(self):
        """read modules"""
        license_ = ''
        for module in self.ivyxml['ivy-module'].dependencies.xml_children:
            if hasattr(module, 'data'):
                if 'License:' in module.data:
                    license_ = module.data.strip()
            elif hasattr(module, 'name'):
                modulename = module.name.replace('-', '_')
            
                if module.org != 'SWEPT':
                    self.group.addLibrary(module.conf, Library(modulename, license_))
                    license_ = ''

    def readSubModules(self):
        """read Sub Modules"""
        for module in self.ivyxml['ivy-module'].dependencies.xml_children:
            if hasattr(module, 'name'):
                if 'jars' in module.name:
                    ivydir = os.path.dirname(self.ivyfilename)
                    ivydir = os.path.join(ivydir, 'modules')
                    ivyjarfile = os.path.join(ivydir, module.name + '-1.0.ivy.xml')
                    ivymodulexml = amara.parse(open(ivyjarfile))
                    license_ = ''
                    for artifact in ivymodulexml['ivy-module'].publications.xml_children:
                        if hasattr(artifact, 'data'):
                            if 'License:' in artifact.data:
                                license_ = artifact.data.strip()
                        elif hasattr(artifact, 'name'):
                            bits = artifact.name.split('-')
                            name = bits[0]
                            version = ''
                            if len(bits) > 1:
                                version = bits[1]
                            self.group.addLibrary(module.conf, Library(name, license_, version))
                            license_ = ''

PYTHON_GROUP = True
SUBCON_PYTHON_GROUP = False

def readEggs(libraries, dirtosearch, internaldir):
    """read Egg files"""
    libraries.addConf(PYTHON_GROUP, 'Python libs', libraries.getColor('core_install'))
    libraries.addConf(SUBCON_PYTHON_GROUP, 'Python subcon libs', libraries.getColor('subcon'))
    
    for _xx in [os.walk(dirtosearch, topdown=False), os.walk(internaldir, topdown=False)]:
        for root, _, files in _xx:
            notinsubcon = os.path.normpath(internaldir) in os.path.normpath(root)
            
            for fname in files:
                filename = os.path.join(root, fname)
                if fname == 'PKG-INFO':
                    pkgmetafile = open(filename)
                    library = readPkgInfo(pkgmetafile)
                    pkgmetafile.close()
                    
                    requirefilename = os.path.join(filename, '..', 'requires.txt')
                    if os.path.exists(requirefilename):
                        requiresfile = open(requirefilename)
                        readRequiresFile(requiresfile, library)
                        requiresfile.close()
                        
                    libraries.addLibrary(notinsubcon, library)
                    
                if os.path.isfile(filename) and fname.endswith('.egg'):
                    eggfile = zipfile.ZipFile(filename, 'r', zipfile.ZIP_DEFLATED)
                    
                    data = eggfile.read('EGG-INFO/PKG-INFO')
                    
                    library = readPkgInfo(data.split('\n'))
                    
                    if 'EGG-INFO/requires.txt' in eggfile.namelist():
                        requiresdata = eggfile.read('EGG-INFO/requires.txt')
                        readRequiresFile(requiresdata.split('\n'), library)
                        
                    libraries.addLibrary(notinsubcon, library)
                    
                    eggfile.close()

def readRequiresFile(data, library):
    """read Requires File"""
    for line in data:
        line = line.strip()
        if line != '' and not (line.startswith('[') and line.endswith(']')):
            library.requires.append(line.split('>=')[0].strip())

def readPkgInfo(data):
    """read Pkg info"""
    name = ''
    version = ''
    license_ = ''
    license2 = ''
  
    for line in data:
        if 'Name:' in line:
            name = line.strip().replace('Name: ', '')
        if 'Version:' in line:
            version = line.strip().replace('Version: ', '')
        if 'License:' in line:
            license_ = line.strip().replace('License: ', '')
        if 'Classifier: License :: ' in line:
            license2 = license2 + ' ' + line.strip().replace('Classifier: License :: ', '').replace('OSI Approved :: ', '')
    
    if license_.lower() == 'unknown' or license_ == '' or license2 != '':
        license_ = license2
    
    return Library(name, license_, version)

def addLicensesColors(graphdata, group):
    """add license colours"""
    newgraphdata = []
    for line in graphdata:
        newline = line
        for conf in group.libraries:
            for module in group.getLibraries(conf):
                if module.name.lower() in line.lower() and 'label=' in line:
                    newline = line.replace('label=', 'color=%s,label=' % group.getColor(conf))
                    if module.license_ != '':
                        newline = newline.replace("\"];", "|%s\"];" % module.license_)
                    break
        newgraphdata.append(newline)
    return newgraphdata
    
def createKey(group):
    """create key"""
    key = """subgraph cluster1 {
    label = "Key";
    style=filled;
    color=lightgrey;
    """
    
    for conf in group.libraries:
        if conf != PYTHON_GROUP and conf != SUBCON_PYTHON_GROUP:
            key = key + "\"%s: %s\" [style=filled,color=%s];" % (conf, group.getDescription(conf), group.getColor(conf))
    
    key = key + "}"
    return key

def createGraph(ivyxmlfilename, graphfilename, dirtosearch, internaldir, subcon):
    """create graph """
    readivy = ReadIvyConfig(ivyxmlfilename)
    readivy.readConfigurations()
    readivy.readModules()
    readivy.readSubModules()
    
    group = readivy.group
    
    readEggs(group, dirtosearch, internaldir)
    
    key = createKey(group)
    
    graphdata = loadGraphFile(graphfilename)
    
    newgraphdata = addLicensesColors(graphdata, group)
    
    #add key to graph
    newgraphdata[-1] = newgraphdata[-1].replace('}', key + '\n}')
    
    graphwritefile = codecs.open(graphfilename, 'w', 'utf8')
    graphwritefile.writelines(newgraphdata)
    graphwritefile.close()
    
    linkPythonLibs(group, graphfilename, subcon)

def loadGraphFile(graphfilename):
    """load graph file"""
    destgraphfile = codecs.open(graphfilename, 'r', 'utf8')
    graphdata = []
    for line in destgraphfile:
        graphdata.append(line)
    destgraphfile.close()
    return graphdata

def addToGraph(graphfilenametoadd, destgraphfilename):
    """add to graph"""
    graphdata = loadGraphFile(destgraphfilename)
    
    graphfile = codecs.open(graphfilenametoadd, 'r', 'utf8')
    graphdatatoadd = ''
    for line in graphfile:
        line = line.replace('digraph {', '')
        graphdatatoadd = graphdatatoadd + line
    graphfile.close()
    
    graphdata[-1] = graphdata[-1].replace('}', graphdatatoadd)
    
    graphwritefile = codecs.open(destgraphfilename, 'w', 'utf8')
    graphwritefile.writelines(graphdata)
    graphwritefile.close()

def linkPythonLibs(libraries, destgraphfilename, subcon):
    """link Python Libraries"""
    graphdata = loadGraphFile(destgraphfilename)
  
    output = "helium_ant -> helium_python;\n"
    
    if subcon:
        libs_list = [SUBCON_PYTHON_GROUP]
    else:
        libs_list = [SUBCON_PYTHON_GROUP, PYTHON_GROUP]
    
    for group in libs_list:
        for lib in libraries.getLibraries(group):
            output = output + ("helium_python -> \"%s\";\n" % lib.name)
            output = output + ("\"%s\" [style=filled,shape=record,color=%s,label=\"%s %s|%s\"];\n" % (lib.name, libraries.getColor(group), lib.name, lib.version, lib.license_))
            
            for require in lib.requires:
                output = output + ("\"%s\" -> \"%s\";\n" % (lib.name, require))
    
    graphdata.reverse()
    for line in graphdata:
        if line.strip() == '':
            graphdata.pop(0)
        else:
            break
    graphdata.reverse()
    
    graphdata[-1] = graphdata[-1].replace('}', output + '}')
    
    graphwritefile = codecs.open(destgraphfilename, 'w', 'utf8')
    graphwritefile.writelines(graphdata)
    graphwritefile.close()

def externalDependancies(database, output):
    """External Dependancies"""
    out = open(output, 'w')
    dbase = amara.parse(open(database))
    out.write('digraph G {\n')
    for proj in dbase.antDatabase.project:
        items = []
        if hasattr(proj, 'property'):
            for prop in proj.property:
                if 'external' + os.sep in os.path.abspath(str(prop.defaultValue)):
                    items.append(str(prop.defaultValue))
        if hasattr(proj, 'fileDependency'):
            for dep in proj.fileDependency:
                dep = str(dep).split(' ')[0]
                if 'external' + os.sep in os.path.abspath(str(dep)):
                    items.append(str(dep))

        items = set(items)
        for i in items:
            out.write('\"%s\" -> \"%s\"\n' % (str(proj.name), i.replace(os.environ['HELIUM_HOME'], 'helium').replace(os.sep, '/')))
    out.write('}')
    out.close()

def appendLogs(targ, proj, output, macro=False):
    """append logs"""
    if hasattr(targ, 'signal'):
        for signal in targ.signal:
            if macro:
                output.append("\"%s\" [fontname=\"Times-Italic\"];" % str(targ.name))
            output.append('subgraph \"cluster%s\" {label = \"%s\"; \"%s\"}\n' % (str(proj.name), str(proj.name), str(targ.name)))
            splt = str(signal).split(',')
            if len(splt) > 1:
                if splt[1] == 'now':
                    color = 'red'
                elif splt[1] == 'defer':
                    color = 'yellow'
                else:
                    color = 'green'
                output.append('subgraph \"cluster%s\" {color=%s;style=filled;label = \"Failbuild: %s\"; \"%s\"}\n' % (str(splt[1]), color, str(splt[1]), str(splt[0])))
            output.append('\"%s\" -> \"%s\" [style=dotted]\n' % (str(targ.name), str(splt[0])))
    if hasattr(targ, 'log'):
        for log in targ.log:
            logdir = '/output/logs/'
            logname = os.path.basename(str(log))
            if not ('**' in logname):
                logname = logname.replace('*', '${sysdef.configuration}').replace('--logfile=', '')
                if not logdir in logname:
                    logname = logdir + logname
                logname = logname.replace(os.sep, '/')
                
                if macro:
                    output.append("\"%s\" [fontname=\"Times-Italic\"];" % str(targ.name))
                output.append('subgraph \"cluster%s\" {label = \"%s\"; \"%s\"}\n' % (str(proj.name), str(proj.name), str(targ.name)))
                output.append('\"%s\" -> \"%s\"\n' % (str(targ.name), logname))

def findLogFiles(database, output):
    """find Log files"""
    out = open(output, 'w')
    dbase = amara.parse(open(database))
    out.write('digraph G {\n')
    output = []
    
    root_objects = []
    for project in dbase.antDatabase.project:
        root_objects.append(project)
    for antlib in dbase.antDatabase.antlib:
        root_objects.append(antlib)
    for p_ro in root_objects:
        if hasattr(p_ro, 'macro'):
            for t_targ in p_ro.macro:
                appendLogs(t_targ, p_ro, output, True)
        if hasattr(p_ro, 'target'):
            for t_targ in p_ro.target:
                appendLogs(t_targ, p_ro, output)
    for l_list in set(output):
        out.write(l_list)
    out.write('}')
    out.close()
