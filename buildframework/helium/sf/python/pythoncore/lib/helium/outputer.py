#============================================================================ 
#Name        : outputer.py 
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

"""Port to python of the ISIS::Logger3::XML2HTML perl module

1.0.0 (13/12/2006)
 - First version of the module."""

import codecs
import xml.dom.minidom
from helium.output.widgets import *
import urllib2
import amara
import re
import dataurl

class Configuration:
    """ Class  for isis Configuration """
    def __init__(self, url):
        url_file = urllib2.urlopen(url)#
        data = url_file.read()
        url_file.close()
        self.__xml = amara.parse(data)
        
    def getClass(self, type_, default = None):
        """get Class"""
        return self._getValue(type_, "class", default)

    def getImg(self, type_, default = None):
        """ get Image"""
        return self._getValue(type_, "img", default)
    
    def getWidth(self, type_, default = None):
        """get Width"""
        return self._getValue(type_, "width", default)
    
    def getHeight(self, type_, default = None):
        """get height"""
        return self._getValue(type_, "height", default)
    
    def _getValue(self, type_, attr, default = None):
        """get value"""
        r_attr = self.__xml.xml_xpath("/htmloutput/icons/icon[@type='%s']" % type_)
        if len(r_attr) == 0:
            if default == None:
                raise Exception("Not found")
            else:
                return default
        return r_attr[0][attr]
    
class XML2XHTML:
    """ This class is used to generate an html file from the given xml """
    def __init__(self, filename, url="http://fawww.europe.nokia.com/isis/isis_interface/configuration.xml", usedataurl=False):
        self.__title = None
        self.__config = Configuration(url)
        self.__filename = filename
        self.__srcdoc = xml.dom.minidom.parse(filename)
        self.__srcdoc.normalize()
        self.__usedataurl = usedataurl
        
        # xhtml output
        dom = xml.dom.minidom.getDOMImplementation()
        doctype = dom.createDocumentType("html", 
              "-//W3C//DTD XHTML 1.0 Strict//EN", 
              "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd")
        self.__doc = dom.createDocument(None, "html", doctype)
        self.__xhtml = self.__doc.getElementsByTagName("html")[0]
        self.__xhtml.setAttributeNS("", "xmlns", "http://www.w3.org/1999/xhtml")
        self.__id = 0
        self.__xhtml_summary = None
        self.__tags = {}
        self.__css = ["http://fawww.europe.nokia.com/isis/isis_interface/css/logger2.css"]
        self.__javascript = ["http://fawww.europe.nokia.com/isis/isis_interface/javascript/expand2.js"]
        self.__factory = {'__header' : XML2XHTML.forname('helium.output.widgets.Header'),
                          '__footer' : XML2XHTML.forname('helium.output.widgets.Footer'),
                          '__maincontent' : XML2XHTML.forname('helium.output.widgets.Box'),
                          '__summary' : XML2XHTML.forname('helium.output.widgets.Summary'),
                          '__print' : XML2XHTML.forname('helium.output.widgets.Text'),
                          '__printraw' : XML2XHTML.forname('helium.output.widgets.RawText'),
                          '__event' : XML2XHTML.forname('helium.output.widgets.Event')}
    
    def _getId(self):
        """get ID"""
        self.__id += 1
        return self.__id

    def addCSSLink(self, url):
        """add CSS Link"""
        self.__css.append(url)
        
    def addJScriptLink(self, url):
        """add Script Link"""
        self.__javascript.append(url)
        
    def _generateCSSLinks(self, container):
        """generate CSS Links"""
        for link in self.__css:
            l_link = self.__doc.createElementNS("", "link")
            if self.__usedataurl:
                l_link.setAttributeNS("", "href", dataurl.from_url(link))
            else:
                l_link.setAttributeNS("", "href", link)
            l_link.setAttributeNS("", "rel", "stylesheet")
            l_link.setAttributeNS("", "type", "text/css")
            container.appendChild(l_link)

    def _generateJScriptLink(self, container):
        """generate J Script Link"""
        for link in self.__javascript:
            l_link = self.__doc.createElementNS("", "script")
            if self.__usedataurl:
                l_link.setAttributeNS("", "src", dataurl.from_url(link))
            else:
                l_link.setAttributeNS("", "src", link)
            l_link.setAttributeNS("", "type", "text/javascript")
            l_link.appendChild(self.__doc.createTextNode(""))
            container.appendChild(l_link)

    def generate(self):
        """generate"""
        root = self.__srcdoc.documentElement
        if root.tagName != "__log":
            raise Exception("Invalid document must be __log.")

        for cust_out in root.getElementsByTagName("__customoutputer"):
            self.__factory[cust_out.attributes['type'].value] = XML2XHTML.forname(cust_out.attributes['module'].value)

        head = self.__doc.createElementNS("", "head")
        title = self.__doc.createElementNS("", "title")
        self.__title = self.__doc.createTextNode("")
        title.appendChild(self.__title)
        head.appendChild(title)
        
        self._generateCSSLinks(head)
        self._generateJScriptLink(head)
        
        body = self.__doc.createElementNS("", "body") 
        self.__xhtml.appendChild(head)
        self.__xhtml.appendChild(body)

        for child in root.childNodes:
            if child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "__header":
                self._handleHeader(child, body)
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "__summary":
                self._handleSummary(child, body)
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "__maincontent":
                self._handleMainContent(child, body)
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "build":
                self._handleBuild(child, body)
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "task" and child.attributes.has_key('type') and child.attributes['type'] == "maincontent":
                self._handleMainContent(child, body)

        footer = root.getElementsByTagName("__footer")[0]
        f_foot = self.__factory["__footer"](self.__doc, body)
        if footer.attributes.has_key("title"):
            f_foot.setTitle(footer.attributes['title'].value)
        if footer.attributes.has_key("subtitle"):
            f_foot.setSubTitle(footer.attributes['subtitle'].value)

        # Generate summary
        self._createSummary()

    def _handleHeader(self, node, container):
        """handle Header"""
        header = self.__factory["__header"](self.__doc, container)
        if node.attributes.has_key('title'):
            self.__title.data = node.attributes['title'].value
            header.setTitle(node.attributes['title'].value)
        if node.attributes.has_key("subtitle"):
            header.setSubTitle(node.attributes['subtitle'].value)
        
    def _handleSummary(self, node, container):
        """handle Summary"""
        box = self.__factory["__summary"](self.__doc, container)
        if node.attributes.has_key('title'):
            box.setTitle(node.attributes["title"].value)
        
        for c_tag in node.getElementsByTagName("__elmt"):
            box.addElement(c_tag.attributes['tag'].value, c_tag.attributes['val'].value)
        self.__xhtml_summary = box
    
    def _handleBuild(self, node, container):
        """handle Build"""
        for child in node.childNodes:
            if child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "task" and child.attributes.has_key('type') and child.attributes['type'].value == 'maincontent':
                self._handleMainContent(child, container)
                

    def _handleMainContent(self, node, container):
        """handle Main Content"""
        box = self.__factory["__maincontent"](self.__doc, container)
        if node.attributes.has_key("title"):
            box.setTitle(node.attributes["title"].value)
        if node.attributes.has_key("name"):
            box.setTitle(node.attributes["name"].value)
        for child in node.childNodes:
            if child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "__event":
                self._handleEvent(child, box.getDOMContainer())
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "task" and child.attributes.has_key('type') and child.attributes['type'].value == 'event':
                self._handleEvent(child, box.getDOMContainer())
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "message":
                self._handleMessage(child, box.getDOMContainer())
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE:
                self._handlePrint(child, box.getDOMContainer())

    def _handleEvent(self, node, container):
        """hnadle Event"""
        tags = self.__tags
        self.__tags = {}
        event = self.__factory["__event"](self.__doc, container, self._getId())
        if node.attributes.has_key('title'):
            event.setTitle(node.attributes['title'].value)
        elif node.attributes.has_key('name'):
            event.setTitle(node.attributes['name'].value)
        for child in node.childNodes:            
            if child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "__event":
                self._handleEvent(child, event.getDOMContainer())
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "task" and child.attributes.has_key('type') and child.attributes['type'].value == 'event':
                self._handleEvent(child, event.getDOMContainer())
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE and child.tagName == "message":
                self._handleMessage(child, event.getDOMContainer())
            elif child.nodeType == xml.dom.Node.ELEMENT_NODE:
                self._handlePrint(child, event.getDOMContainer())
                
        keys = self.__tags.keys()
        keys.sort()
        for name in keys:
            event.addStatistics(name.replace("__", ""), self.__tags[name])
        self.__tags = self._mergeStatistics(tags, self.__tags)
        
    def _handleMessage(self, node, container):
        """ handle Message"""
        if node.attributes['priority'].value == "printraw":
            t_print = self.__factory["__printraw"](self.__doc, container)
            for n_node in node.childNodes:
                if n_node.nodeType == xml.dom.Node.CDATA_SECTION_NODE:
                    t_print.appendText(n_node.data)
        else:
            t_print = self.__factory["__print"](self.__doc, container)
            for n_node in node.childNodes:
                if n_node.nodeType == xml.dom.Node.CDATA_SECTION_NODE:
                    t_print.appendText(n_node.data)
            if node.attributes['priority'].value != "print":
                t_print.setIcon(self.__config.getClass(node.attributes['priority'].value, "icn_dft"))
                if self.__tags.has_key(node.attributes['priority'].value):
                    self.__tags[node.attributes['priority'].value] += 1
                else:
                    self.__tags[node.attributes['priority'].value] = 1

    def _handlePrint(self, node, container):
        """handle print"""
        if node.tagName == "__printraw":
            t_print = self.__factory["__printraw"](self.__doc, container)
            for n_node in node.childNodes:
                if n_node.nodeType == xml.dom.Node.CDATA_SECTION_NODE or n_node.nodeType == xml.dom.Node.TEXT_NODE:
                    t_print.appendText(n_node.data)
        else:
            t_print = self.__factory["__print"](self.__doc, container)
            for n_node in node.childNodes:
                if n_node.nodeType == xml.dom.Node.CDATA_SECTION_NODE or n_node.nodeType == xml.dom.Node.TEXT_NODE:
                    t_print.appendText(n_node.data)
            if node.tagName != "__print":
                t_print.setIcon(self.__config.getClass(node.tagName, "icn_dft"))
                if self.__tags.has_key(node.tagName):
                    self.__tags[node.tagName] += 1
                else:
                    self.__tags[node.tagName] = 1

    def _createSummary(self):
        """create Summary"""
        # pylint: disable=E1101
        if self.__xhtml_summary == None:
            self.__xhtml_summary = Summary(self.__doc, self.__body)
            self.__xhtml_summary.setTitle("Global Statistics")
        keys = self.__tags.keys()
        keys.sort()
        for name in keys:
            self.__xhtml_summary.addStatistics(name.replace("__", ""), self.__tags[name])
        # pylint: enable-msg=E1101

    def _mergeStatistics(self, tags, newTags):
        """merge Statistics"""
        for name in newTags.keys():
            if tags.has_key(name):
                tags[name] += newTags[name]
            else:
                tags[name] = newTags[name]
        return tags

    def WriteToFile(self, filename):
        """write to file"""
        file_object = open(filename, "w")
        file_object.write(codecs.BOM_UTF8)
        file_object.write(self.__doc.toprettyxml(encoding="utf-8"))
        file_object.close()


    @staticmethod
    def forname(classname):
        """forname"""
        result = re.match("^(?P<modname>(?:\w+\.?)*)\.(?P<classname>(\w+?))$", classname)
        if result != None:
            return getattr(__import__(result.groupdict()['modname'], [], [], result.groupdict()['classname']), result.groupdict()['classname'])
        else:
            raise Exception("Error retreiving module and classname for %s" % classname)
