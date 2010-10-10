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

# pylint: disable=E1103
#import sys
#if 'java' in sys.platform:
#    pass
if True:
    import os
    import xml.dom.minidom
    import urllib
    import xpath
    import xml.etree.ElementTree
    import xml.etree.ElementInclude
    
    # pylint: disable=W0212
    def fixed_writexml(self, writer, indent="", addindent="", newl=""):
        # indent = current indentation
        # addindent = indentation to add to higher levels
        # newl = newline string
        writer.write(indent + "<" + self.tagName)
    
        attrs = self._get_attributes()
        a_names = attrs.keys()
        a_names.sort()
    
        for a_name in a_names:
            writer.write(" %s=\"" % a_name)
            xml.dom.minidom._write_data(writer, attrs[a_name].value)
            writer.write("\"")
        if self.childNodes:
            if len(self.childNodes) == 1 \
              and self.childNodes[0].nodeType == xml.dom.minidom.Node.TEXT_NODE:
                writer.write(">")
                self.childNodes[0].writexml(writer, "", "", "")
                writer.write("</%s>%s" % (self.tagName, newl))
                return
            writer.write(">%s" % (newl))
            for node in self.childNodes:
                if node.__class__ == xml.dom.minidom.Text and node.data.strip() == '':
                    continue
                node.writexml(writer, indent + addindent, addindent, newl)
            writer.write("%s</%s>%s" % (indent, self.tagName, newl))
        else:
            writer.write("/>%s" % (newl))
    # replace minidom's function with ours
    xml.dom.minidom.Element.writexml = fixed_writexml
    
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
                cwd_backup = os.getcwd()
                if dom.startswith('file:///') or dom.startswith('///') or os.path.exists(dom):
                    try:
                        path = urllib.url2pathname(dom)
                        path = path.replace('file:///', '')
                        os.chdir(os.path.dirname(path))
                    except IOError:
                        pass
                    dom = urllib.urlopen(dom).read()
                
                ettree = xml.etree.ElementTree.fromstring(dom)
                xml.etree.ElementInclude.include(ettree)
                dom = xml.etree.ElementTree.tostring(ettree)
                os.chdir(cwd_backup)
                self.dom = xml.dom.minidom.parseString(dom)
            else:
                self.dom = dom
        
        def __getitem__(self, name):
            return self.__getattr__(name)
            
        def __setitem__(self, key, value):
            self.xml_set_attribute(key, value)
            
        def __getattr__(self, attr):        
            if attr == 'xml_child_elements':
                return self._getxml_child_elements()
            if isinstance(attr, basestring):
                res = self.dom.getElementsByTagName(attr)
                if len(res) == 0:
                    if hasattr(self.dom, 'documentElement'):
                        val = self.dom.documentElement.getAttribute(attr)
                        if not self.dom.documentElement.hasAttribute(attr):
                            raise AttributeError(attr + ' not found')
                    else:
                        val = self.dom.getAttribute(attr)
                        if not self.dom.hasAttribute(attr):
                            raise AttributeError(attr + ' not found')
                    return val
                return MinidomAmara(res[0], self.dom)
            if self.parent:
                return MinidomAmara(self.parent.getElementsByTagName(self.dom.tagName)[attr])
            else:
                raise AttributeError(str(attr) + ' not found')
    
        def __setattr__(self, name, value):
            if isinstance(value, basestring):
                self.xml_set_attribute(name, value)
            else:
                object.__setattr__(self, name, value)
        
        def __iter__(self):
            for entry in self.parent.getElementsByTagName(self.dom.tagName):
                yield MinidomAmara(entry)
    
        def _get_text(self, node):
            """ Recursive method to collate sub-node strings. """
            text = ''
            for child in node.childNodes:
                if child.nodeType == child.TEXT_NODE and child.data != None:
                    text = text + ' ' + child.data
                else:
                    text += self._get_text(child)
            return text.strip()
        
        def __str__(self):
            """ Output a string representing the XML node. """
            return self._get_text(self.dom)

        def xml(self, out=None, indent=False, omitXmlDeclaration=False, encoding='utf-8'):
            """xml"""
            if omitXmlDeclaration:
                pass
            if out:
                out.write(self.dom.toprettyxml(encoding=encoding))
            if indent:
                return self.dom.toprettyxml(encoding=encoding)
            return self.dom.toxml(encoding=encoding)
        
        def xml_append_fragment(self, text):
            """xml append fragment"""
            self.dom.appendChild(xml.dom.minidom.parseString(text).documentElement)
    
        def xml_set_attribute(self, name, value):
            """set XML attribute"""
            self.dom.setAttribute(name, value)
        
        def xml_remove_child(self, value):
            self.dom.removeChild(value.dom)
        
        def _getxml_children(self):
            """get xml children"""
            l_attrib = []
            for elem in self.dom.childNodes:
                if elem.nodeType == elem.ELEMENT_NODE:
                    l_attrib.append(MinidomAmara(elem))
            return l_attrib

        def _getxml_child_elements(self):
            """get xml children"""
            l_attrib = {}
            for elem in self.dom.childNodes:
                if elem.nodeType == elem.ELEMENT_NODE:
                    l_attrib[elem.tagName] = MinidomAmara(elem)
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
        xml_child_elements = property(_getxml_child_elements)
        
        def __eq__(self, obj):
            return str(self) == obj
        def __ne__(self, obj):
            return str(self) != obj
        
        def __len__(self):
            if self.parent:
                return len(self.parent.getElementsByTagName(self.dom.tagName))
            return 1
        
        def xml_xpath(self, axpath):
            """append to the XML path"""
            results  = [] 
            for result in xpath.find(axpath, self.dom): 
                results.append(MinidomAmara(result)) 
            return results 
#            import java.io.ByteArrayInputStream
#            import org.dom4j.io.SAXReader
#            import org.dom4j.DocumentHelper
#
#            stream = java.io.ByteArrayInputStream(java.lang.String(self.dom.toxml()).getBytes("UTF-8"))
#            xmlReader = org.dom4j.io.SAXReader()
#            doc = xmlReader.read(stream)
#            xpath = org.dom4j.DocumentHelper.createXPath(xpath)
#            signalNodes = xpath.selectNodes(doc)
#            iterator = signalNodes.iterator()
#            out = []
#            while iterator.hasNext():
#                p_iterator = iterator.next()
#                out.append(MinidomAmara(p_iterator.asXML()))
#            return out
