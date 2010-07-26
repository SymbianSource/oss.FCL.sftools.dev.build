#============================================================================ 
#Name        : amara.py 
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
"""amara"""

# pylint: disable-msg=E1103
import sys
if 'java' in sys.platform:
    import xml.dom.minidom
    import urllib
    
    def parse(param):
        """parse"""
        return MinidomAmara(param)
    
    def create_document(name=None):
        """create document"""
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
            for t_text in self.dom.childNodes:
                if t_text.nodeType == t_text.TEXT_NODE and t_text.data != None:
                    text = text + t_text.data
            return text
        
        def xml(self, out=None, indent=True, omitXmlDeclaration=False, encoding=''):
            """xml"""
            if out:
                out.write(self.dom.toprettyxml())
            if indent:
                return self.dom.toprettyxml()
            return self.dom.toxml()
        
        def xml_append_fragment(self, text):
            """xml append fragment"""
            self.dom.appendChild(xml.dom.minidom.parseString(text).documentElement)
    
        def xml_set_attribute(self, name, value):
            """set XML attribute"""
            self.dom.setAttribute(name, value)
        
        def _getxml_children(self):
            """get xml children"""
            l_attrib = []
            for elem in self.dom.childNodes:
                if elem.nodeType == elem.ELEMENT_NODE:
                    l_attrib.append(MinidomAmara(elem))
            return l_attrib
        
        def _getxml_attributes(self):
            """get aml attributes"""
            l_attrib = self.dom.attributes
            out = {}
            for i in range(l_attrib.length):
                out[l_attrib.item(i).name] = l_attrib.item(i).nodeValue
            return out
        
        def xml_append(self, value):
            """append to XML """
            if hasattr(self.dom, 'documentElement') and self.dom.documentElement != None:
                value.dom.documentElement = self.dom.documentElement.appendChild(value.dom.documentElement)
            else:
                value.dom.documentElement = self.dom.appendChild(value.dom.documentElement)
        
        def xml_create_element(self, name, content=None, attributes=None):
            """ create XML element"""
            elem = create_document(name)
            if attributes:
                for attrib in attributes.keys():
                    elem[name].dom.setAttribute(attrib, attributes[attrib])
            if content:
                impl = xml.dom.minidom.getDOMImplementation()
                newdoc = impl.createDocument(None, None, None)
                elem[name].dom.appendChild(newdoc.createTextNode(content))
            return elem
        
        def _getnodetype(self):
            """get node type"""
            return self.dom.nodeType
        def _getnodename(self):
            """get node nmae"""
            return self.dom.nodeName
            
        nodeType = property(_getnodetype)
        nodeName = property(_getnodename)
        childNodes = property(_getxml_children)
        xml_children = property(_getxml_children)
        xml_attributes = property(_getxml_attributes)
        
        def __eq__(self, obj):
            return str(self) == obj
        
        def __len__(self):
            return len(self.parent.getElementsByTagName(self.dom.tagName))
        
        def xml_xpath(self, xpath):
            """append to the XML path"""
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
                p_iterator = iterator.next()
                out.append(MinidomAmara(p_iterator.asXML()))
            return out
