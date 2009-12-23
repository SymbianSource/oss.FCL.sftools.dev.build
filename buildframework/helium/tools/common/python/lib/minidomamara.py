#============================================================================ 
#Name        : minidomamara.py 
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

# pylint: disable-msg=E1103

import xml.dom.minidom
from xml.etree.ElementTree import ElementTree

def parse(f):
    return MinidomAmara(f)

def create_document(name):
    impl = xml.dom.minidom.getDOMImplementation()
    newdoc = impl.createDocument(None, name, None).toxml()
    return MinidomAmara(newdoc)

class MinidomAmara(object):
    """ amara api using minidom """
    
    def __init__(self, dom, parent=None):
        self.parent = parent
        if isinstance(dom, file):
            self.dom = xml.dom.minidom.parse(dom)
        elif isinstance(dom, basestring):
            self.dom = xml.dom.minidom.parseString(dom)
        else:
            self.dom = dom
    
    def __getitem__(self, name):
        if type(self.dom).__name__ == 'instance':
            return self
        return MinidomAmara(self.dom[name])
    
    def __getattr__(self, attr):
        self.attr = attr
        res = self.dom.getElementsByTagName(attr)
        if len(res) == 0:
            return self.dom.getAttribute(attr)
        return MinidomAmara(res[0], self.dom)

    def __iter__(self):
        for entry in self.parent.getElementsByTagName(self.dom.tagName):
            yield MinidomAmara(entry)

    def __str__(self):
        text = ''
        for t in self.dom.childNodes:
            if t.nodeType == t.TEXT_NODE and t.data != None:
                text = text + t.data
        return text
    
    def xml(self):
        return self.dom.toxml()
    
    def xml_append_fragment(self, text):
        self.dom.appendChild(xml.dom.minidom.parseString(text).documentElement)

    def xml_set_attribute(self, name, value):
        self.dom.setAttribute(name, value)
    
    def _getxml_children(self):
        return [MinidomAmara(entry) for entry in self.dom.childNodes]
        
    def xml_append(self, value):
        pass
    
    def xml_create_element(self, name, content=None, attributes=None):
        pass
    
    xml_children = property(_getxml_children)
    
#    def xml_xpath(self, xpath):
#        tree = ElementTree()
#        tree.parse(self.dom.toxml())
#        return tree.findall(xpath)

def test():
    x = parse(r'<commentLog><branchInfo category="" error="kkk" file="tests/data/comments_test.txt" originator="sanummel" since="07-03-22">Add rofsfiles for usage in paged images</branchInfo></commentLog>')
    assert str(x.commentLog.branchInfo) == 'Add rofsfiles for usage in paged images'
    
    x = parse(r'<commentLog><branchInfo>1</branchInfo><branchInfo>2</branchInfo></commentLog>')
    for y in x.commentLog.branchInfo:
        assert str(y) == '1'
        break
    