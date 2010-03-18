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
import sys
if 'java' in sys.platform:
    import xml.dom.minidom
    import urllib
    
    def parse(f):
        return MinidomAmara(f)
    
    def create_document(name=None):
        impl = xml.dom.minidom.getDOMImplementation()
        newdoc = impl.createDocument(None, name, None)
        return MinidomAmara(newdoc)
    
    class MinidomAmara(object):
        """ amara api using minidom """
        
        def __init__(self, dom, parent=None):
            self.parent = parent
            if isinstance(dom, file):
                self.dom = xml.dom.minidom.parse(dom)
            elif isinstance(dom, basestring):
                if dom.startswith('file:///'):
                    dom = urllib.urlopen(dom).read()
                self.dom = xml.dom.minidom.parseString(dom)
            else:
                self.dom = dom
        
        def __getitem__(self, name):
            return self.__getattr__(name)
        
        def __getattr__(self, attr):
            if isinstance(attr, basestring):
                res = self.dom.getElementsByTagName(attr)
                if len(res) == 0:
                    if hasattr(self.dom, 'documentElement'):
                        val = self.dom.documentElement.getAttribute(attr)
                    else:
                        val = self.dom.getAttribute(attr)
                    if val == '':
                        raise Exception(attr + ' not found')
                    return val
                return MinidomAmara(res[0], self.dom)
            return MinidomAmara(self.parent.getElementsByTagName(self.dom.tagName)[attr])
    
        def __iter__(self):
            for entry in self.parent.getElementsByTagName(self.dom.tagName):
                yield MinidomAmara(entry)
    
        def __str__(self):
            text = ''
            for t in self.dom.childNodes:
                if t.nodeType == t.TEXT_NODE and t.data != None:
                    text = text + t.data
            return text
        
        def xml(self, out=None, indent=True, omitXmlDeclaration=False, encoding=''):
            if out:
                out.write(self.dom.toprettyxml())
            if indent:
                return self.dom.toprettyxml()
            return self.dom.toxml()
        
        def xml_append_fragment(self, text):
            self.dom.appendChild(xml.dom.minidom.parseString(text).documentElement)
    
        def xml_set_attribute(self, name, value):
            self.dom.setAttribute(name, value)
        
        def _getxml_children(self):
            l = []
            for e in self.dom.childNodes:
                if e.nodeType == e.ELEMENT_NODE:
                    l.append(MinidomAmara(e))
            return l
        
        def _getxml_attributes(self):
            l = self.dom.attributes
            out = {}
            for i in range(l.length):
                out[l.item(i).name] = l.item(i).nodeValue
            return out
        
        def xml_append(self, value):
            if hasattr(self.dom, 'documentElement') and self.dom.documentElement != None:
                value.dom.documentElement = self.dom.documentElement.appendChild(value.dom.documentElement)
            else:
                value.dom.documentElement = self.dom.appendChild(value.dom.documentElement)
        
        def xml_create_element(self, name, content=None, attributes=None):
            e = create_document(name)
            if attributes:
                for a in attributes.keys():
                    e[name].dom.setAttribute(a, attributes[a])
            if content:
                impl = xml.dom.minidom.getDOMImplementation()
                newdoc = impl.createDocument(None, None, None)
                e[name].dom.appendChild(newdoc.createTextNode(content))
            return e
        
        def _getnodetype(self):
            return self.dom.nodeType
        def _getnodename(self):
            return self.dom.nodeName
            
        nodeType = property(_getnodetype)
        nodeName = property(_getnodename)
        childNodes = property(_getxml_children)
        xml_children = property(_getxml_children)
        xml_attributes = property(_getxml_attributes)
        
        def __eq__(self, o):
            return str(self) == o
        
        def __len__(self):
            return len(self.parent.getElementsByTagName(self.dom.tagName))
        
        def xml_xpath(self, xpath):
            import java.io.ByteArrayInputStream
            import org.dom4j.io.SAXReader
            import org.dom4j.DocumentHelper
            
            stream = java.io.ByteArrayInputStream(java.lang.String(self.dom.toxml()).getBytes("UTF-8"))    
            xmlReader = org.dom4j.io.SAXReader()
            doc = xmlReader.read(stream)
            xpath = org.dom4j.DocumentHelper.createXPath(xpath)
            signalNodes = xpath.selectNodes(doc)
            iterator = signalNodes.iterator()
            out = []
            while iterator.hasNext():
                p = iterator.next()
                out.append(MinidomAmara(p.asXML()))
            return out
            