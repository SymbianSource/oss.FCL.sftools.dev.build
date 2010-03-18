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

import os
import amara
import codecs
import zipfile

class Library:
    def __init__(self, name, license, version=''):
        self.name = name
        self.license = license
        self.version = version
        self.requires = []

class ModuleGroup:
    def __init__(self):
        self.libraries = {}
    def addConf(self, name, des, color):
        self.libraries[name] = (des, [], color)
    def addLibrary(self, conf, library):
        for lib in self.getLibraries(conf):
            if lib.name.lower() == library.name.lower():
                lib.license = library.license
                return
        self.getLibraries(conf).append(library)
    def getLibraries(self, conf):
        (_, libs, _) = self.libraries[conf]
        return libs
    def getDescription(self, conf):
        (des, _, _) = self.libraries[conf]
        return des
    def getColor(self, conf):
        (_, _, color) = self.libraries[conf]
        return color

COLORS = ['pink', 'red', 'lightblue', 'orange', 'green', 'yellow', 'turquoise', 'limegreen']

class ReadIvyConfig:
    def __init__(self, ivyfilename):
        self.ivyfilename = ivyfilename
        self.ivyxml = amara.parse(open(ivyfilename))
        self.group = ModuleGroup()

    def readConfigurations(self):
        for conf in self.ivyxml['ivy-module'].configurations.conf:
            color = COLORS.pop()
            self.group.addConf(conf.name, conf.description, color)

    def readModules(self):
        license = ''
        for module in self.ivyxml['ivy-module'].dependencies.xml_children:
            if hasattr(module, 'data'):
                if 'License:' in module.data:
                    license = module.data.strip()
            elif hasattr(module, 'name'):
                modulename = module.name.replace('-', '_')
            
                if module.org != 'SWEPT':
                    self.group.addLibrary(module.conf, Library(modulename, license))
                    license = ''

    def readSubModules(self):
        for module in self.ivyxml['ivy-module'].dependencies.xml_children:
            if hasattr(module, 'name'):
                if 'jars' in module.name:
                    ivydir = os.path.dirname(self.ivyfilename)
                    ivydir = os.path.join(ivydir, 'modules')
                    ivyjarfile = os.path.join(ivydir, module.name + '-1.0.ivy.xml')
                    ivymodulexml = amara.parse(open(ivyjarfile))
                    license = ''
                    for artifact in ivymodulexml['ivy-module'].publications.xml_children:
                        if hasattr(artifact, 'data'):
                            if 'License:' in artifact.data:
                                license = artifact.data.strip()
                        elif hasattr(artifact, 'name'):
                            bits = artifact.name.split('-')
                            name = bits[0]
                            version = ''
                            if len(bits) > 1:
                                version = bits[1]
                            self.group.addLibrary(module.conf, Library(name, license, version))
                            license = ''

PYTHON_GROUP = True
SUBCON_PYTHON_GROUP = False

def readEggs(libraries, dirtosearch, internaldir):
    libraries.addConf(PYTHON_GROUP, 'Python libs', libraries.getColor('core_install'))
    libraries.addConf(SUBCON_PYTHON_GROUP, 'Python subcon libs', libraries.getColor('subcon'))
    
    for x in [os.walk(dirtosearch, topdown=False), os.walk(internaldir, topdown=False)]:
        for root, _, files in x:
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
    for line in data:
        line = line.strip()
        if line != '' and not (line.startswith('[') and line.endswith(']')):
            library.requires.append(line.split('>=')[0].strip())

def readPkgInfo(data):
    name = ''
    version = ''
    license = ''
    license2 = ''
  
    for line in data:
        if 'Name:' in line:
            name = line.strip().replace('Name: ', '')
        if 'Version:' in line:
            version = line.strip().replace('Version: ', '')
        if 'License:' in line:
            license = line.strip().replace('License: ', '')                    
        if 'Classifier: License :: ' in line:
            license2 = license2 + ' ' + line.strip().replace('Classifier: License :: ', '').replace('OSI Approved :: ', '')
    
    if license.lower() == 'unknown' or license == '' or license2 != '':
        license = license2
    
    return Library(name, license, version)

def addLicensesColors(graphdata, group):
    newgraphdata = []
    for line in graphdata:
        newline = line
        for conf in group.libraries:
            for module in group.getLibraries(conf):
                if module.name.lower() in line.lower() and 'label=' in line:
                    newline = line.replace('label=', 'color=%s,label=' % group.getColor(conf))
                    
                    if module.license != '':
                        newline = newline.replace("\"];", "|%s\"];" % module.license)
                    
                    break
        newgraphdata.append(newline)
    return newgraphdata
    
def createKey(group):
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
    destgraphfile = codecs.open(graphfilename, 'r', 'utf8')
    graphdata = []
    for line in destgraphfile:
        graphdata.append(line)
    destgraphfile.close()
    return graphdata

def addToGraph(graphfilenametoadd, destgraphfilename):
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
    graphdata = loadGraphFile(destgraphfilename)
  
    output = "helium_ant -> helium_python;\n"
    
    if subcon:
        list = [SUBCON_PYTHON_GROUP]
    else:
        list = [SUBCON_PYTHON_GROUP, PYTHON_GROUP]
    
    for group in list:
        for lib in libraries.getLibraries(group):
            output = output + ("helium_python -> \"%s\";\n" % lib.name)
            output = output + ("\"%s\" [style=filled,shape=record,color=%s,label=\"%s %s|%s\"];\n" % (lib.name, libraries.getColor(group), lib.name, lib.version, lib.license))
            
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
    out = open(output, 'w')
    db = amara.parse(open(database))
    out.write('digraph G {\n')
    for p in db.antDatabase.project:
        items = []
        if hasattr(p, 'property'):
            for prop in p.property:
                if 'external' + os.sep in os.path.abspath(str(prop.defaultValue)):
                    items.append(str(prop.defaultValue))
        if hasattr(p, 'fileDependency'):
            for dep in p.fileDependency:
                dep = str(dep).split(' ')[0]
                if 'external' + os.sep in os.path.abspath(str(dep)):
                    items.append(str(dep))
                    
        items = set(items)
        for i in items:
            out.write('\"%s\" -> \"%s\"\n' % (str(p.name), i.replace(os.environ['HELIUM_HOME'], 'helium').replace(os.sep, '/')))
    out.write('}')                
    out.close()

def appendLogs(t, p, output, macro=False):
    if hasattr(t, 'signal'):
        for signal in t.signal:
            if macro:
                output.append("\"%s\" [fontname=\"Times-Italic\"];" % str(t.name))
            output.append('subgraph \"cluster%s\" {label = \"%s\"; \"%s\"}\n' % (str(p.name), str(p.name), str(t.name)))
            s = str(signal).split(',')
            if len(s) > 1:
                if s[1] == 'now':
                    color = 'red'
                elif s[1] == 'defer':
                    color = 'yellow'
                else:
                    color = 'green'
                output.append('subgraph \"cluster%s\" {color=%s;style=filled;label = \"Failbuild: %s\"; \"%s\"}\n' % (str(s[1]), color, str(s[1]), str(s[0])))
            output.append('\"%s\" -> \"%s\" [style=dotted]\n' % (str(t.name), str(s[0])))
    if hasattr(t, 'log'):
        for log in t.log:
            logdir = '/output/logs/'
            logname = os.path.basename(str(log))
            if not ('**' in logname):
                logname = logname.replace('*', '${sysdef.configuration}').replace('--logfile=', '')
                if not logdir in logname:
                    logname = logdir + logname
                logname = logname.replace(os.sep, '/')
                
                if macro:
                    output.append("\"%s\" [fontname=\"Times-Italic\"];" % str(t.name))
                output.append('subgraph \"cluster%s\" {label = \"%s\"; \"%s\"}\n' % (str(p.name), str(p.name), str(t.name)))
                output.append('\"%s\" -> \"%s\"\n' % (str(t.name), logname))

def findLogFiles(database, output):
    out = open(output, 'w')
    db = amara.parse(open(database))
    out.write('digraph G {\n')
    output = []
    
    root_objects = []
    for project in db.antDatabase.project:
        root_objects.append(project)
    for antlib in db.antDatabase.antlib:
        root_objects.append(antlib)
    for p in root_objects:
        if hasattr(p, 'macro'):
            for t in p.macro:
                appendLogs(t, p, output, True)
        if hasattr(p, 'target'):
            for t in p.target:
                appendLogs(t, p, output)
    for l in set(output):
        out.write(l)
    out.write('}')                
    out.close()
    
