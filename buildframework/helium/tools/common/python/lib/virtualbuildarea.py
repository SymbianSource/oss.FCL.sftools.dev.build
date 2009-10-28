#============================================================================ 
#Name        : virtualbuildarea.py 
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

"""
This modules helps to recreate a fake synergy project for the 
ccm toolkit. The fake project can be composed of any real synergy 
objects. 
"""


# pylint: disable-msg=E1103


import ccm
import xml.dom.minidom
import traceback
import sys
DEBUG_VIRTUALDIR = True

class VirtualDir(ccm.Dir):
    """ Fake directory object.
        The four parts name will be: <dirname>-1:dir:fakedb#1
    """
    def __init__(self, session, name, project):
        fpn = "%s-1:dir:fakedb#1" % name
        ccm.Dir.__init__(self, session, fpn)
        self.__data = []
        self._project = project
        
    def addChild(self, o, project):
        """ Add an object to the directory. """
        if (o.type == 'dir'):
            if DEBUG_VIRTUALDIR:
                print "Dir adding %s to %s" % (o, self)
            vdir = self.getDirNamed(o.name)            
            if vdir == None:
                # Adding a directory, convert it into a virtual one
                if DEBUG_VIRTUALDIR:
                    print "Dir not found creating a virtual one"
                vdir = VirtualDir(self._session, o.name, self._project)
                self.__data.append(vdir)
            elif vdir.type == 'project':
                # this is a project, covert it into a directory
                self.__data.remove(vdir)
                self.addChild(vdir.root_dir(), vdir)
                vdir = self.getDirNamed(o.name)
                
            # Adding content of the directory into the virtual one
            for child in o.children(project):
                vdir.addChild(child, project)
        elif (o.type == 'project'):
            # Adding a project
            if DEBUG_VIRTUALDIR:
                print "Project adding %s to %s" % (o, self)
            # check for directory with the same name first            
            vdir = self.getDirNamed(o.name)
            if vdir == None:
                # if it is new, just add it 
                if DEBUG_VIRTUALDIR:
                    print "Adding project directly"
                self.__data.append(o)
            else:
                if vdir.type == 'project':
                    if DEBUG_VIRTUALDIR:
                        print "Replacing project by dir %s" % vdir
                    self.__data.remove(vdir)
                    self.addChild(vdir.root_dir(), vdir)
                    vdir = self.getDirNamed(o.name)                    
                # if a directory already exist grab the content
                if DEBUG_VIRTUALDIR:
                    print "Adding childs under %s" % vdir
                for child in o.root_dir().children(o):
                    vdir.addChild(child, o)
        else:
            self.__data.append(o)
            
    def getDirNamed(self, name):
        """ Look for a subdirectory named in its children.
        The test is done in a case insensitive way.
        """
        for o in self.__data:
            if (o.name.lower() == name.lower()):
                return o
        return None
    
    def children(self, project):
        """ Returns a copy of the children list. """
        return self.__data[:]
    
    def virtualproject(self):
        """ Return the associated virtual project. """
        return self._project
    
    
class VirtualProject(ccm.Project):
    """ Create a fake project containing on fake directory.
    The four part name will be <projectname>-1:project:fakedb#1.
    """
    def __init__(self, session, name):
        fpn = "%s-1:project:fakedb#1" % name
        ccm.Project.__init__(self, session, fpn)
        self._root_dir = VirtualDir(session, name, self)
    
    def root_dir(self):
        """ Returns the associated virtual directory object. """
        return self._root_dir


def __removeEmptyStrings(a):
    o = []
    for e in a:
        if (len(e)>0):
            o.append(e)
    return o

def __createVirtualPath(vpath, root):
    """ Creating a directory structure using the vpath list given as input.    
    """
    vpath = __removeEmptyStrings(vpath)
    if (root.type == 'project'):
        root = root.root_dir()
    if (len(vpath) == 0):
        return root
    else:
        name = vpath.pop(0)
        root.addChild(VirtualDir(root.session, name, root.virtualproject()), root.virtualproject())
        return __createVirtualPath(vpath, root.getDirNamed(name))

def __getObjects(project, spath, dir=None):
    name = spath.pop(0)
    if (len(spath) == 0 and dir == None):
        result = []
        for o in project.root_dir().children(project):
            result.append({'project':project, 'object':o})
        return result
    
    if (dir == None):
        root_dir = project.root_dir()
        if (root_dir.name.lower() == name.lower()):
            return __getObjects(project, spath, root_dir)
        else:
            Exception("getObjects: root_dir.name(%s)!=name(%s)" % (root_dir.name, name))
    else:
        for d in dir.children(project):
            if d.type == 'dir' and d.name.lower() == name.lower():
                return __getObjects(project, spath, d)
        raise Exception("Could not find object %s" % name)
                


def create(session, file, name = "vba"):
    """ Creates a virtual toplevel project using the XML configuration. """
    try:
        dom = xml.dom.minidom.parse(file)
        #dom = xml.dom.minidom.parseString(input)

        vba = VirtualProject(session, name)
        virtualBA = dom.documentElement
        for child in virtualBA.childNodes:
            if (child.nodeType == xml.dom.Node.ELEMENT_NODE) and (child.nodeName == 'add'):
                print "add node :%s (%d)" % (child.getAttribute('project'), len(child.childNodes))
                pathobject = __createVirtualPath(child.getAttribute('to').split('/'), vba)
                if len(child.childNodes) == 0:
                    p = session.create(child.getAttribute('project'))
                    pathobject.addChild(p, p)
                else:
                    project = session.create(child.getAttribute('project'))
                    for subChild in child.childNodes:
                        if (subChild.nodeType == xml.dom.Node.ELEMENT_NODE) and (subChild.nodeName == 'objects'):
                            spath = __removeEmptyStrings(subChild.getAttribute('from').split('/'))
                            for t in __getObjects(project, spath):
                                pathobject.addChild(t['object'], t['project'])
        virtualBA.unlink()
        return vba
    except Exception, e:
        traceback.print_exc(file = sys.stdout)
        raise Exception("XML cannot be parsed properly %s" % e)
    
