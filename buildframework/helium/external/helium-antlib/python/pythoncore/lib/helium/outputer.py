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

##
# Outputer module
# Description : Port to python of the ISIS::Logger3::XML2HTML perl module
#
# 1.0.0 (13/12/2006)
#  - First version of the module.
##
import codecs
import xml.dom.minidom
from helium.output.widgets import *
import urllib2
import amara
import re
import dataurl

class Configuration:
    def __init__(self, url):
        f = urllib2.urlopen(url)#
        data = f.read()
        f.close()
        self.__xml = amara.parse(data)
        
    def getClass(self, type, default = None):
        return self._getValue(type, "class", default)

    def getImg(self, type, default = None):
        return self._getValue(type, "img", default)
    
    def getWidth(self, type, default = None):
        return self._getValue(type, "width", default)
    
    def getHeight(self, type, default = None):
        return self._getValue(type, "height", default)
    
    def _getValue(self, type, attr, default = None):
        r = self.__xml.xml_xpath("/htmloutput/icons/icon[@type='%s']" % type)
        if len(r) == 0:
            if default == None:
                raise Exception("Not found")
            else:
                return default
        return r[0][attr]
    
class XML2XHTML:
    
    def __init__(self, filename, url="http://fawww.europe.nokia.com/isis/isis_interface/configuration.xml", usedataurl=False):
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
        self.__id += 1
        return self.__id

    def addCSSLink(self, url):
        self.__css.append(url)
        
    def addJScriptLink(self, url):
        self.__javascript.append(url)
        
    def _generateCSSLinks(self, container):
        for link in self.__css:
            l = self.__doc.createElementNS("", "link")
            if self.__usedataurl:
                l.setAttributeNS("", "href", dataurl.from_url(link))
            else:
                l.setAttributeNS("", "href", link)
            l.setAttributeNS("", "rel", "stylesheet")
            l.setAttributeNS("", "type", "text/css")
            container.appendChild(l)
            
    def _generateJScriptLink(self, container):
        for link in self.__javascript:
            l = self.__doc.createElementNS("", "script")
            if self.__usedataurl:
                l.setAttributeNS("", "src", dataurl.from_url(link))
            else:
                l.setAttributeNS("", "src", link)
            l.setAttributeNS("", "type", "text/javascript")
            l.appendChild(self.__doc.createTextNode(""))
            container.appendChild(l)
        
        
    def generate(self):
        root = self.__srcdoc.documentElement
        if root.tagName != "__log":
            raise Exception("Invalid document must be __log.")

        for c in root.getElementsByTagName("__customoutputer"):
            self.__factory[c.attributes['type'].value] = XML2XHTML.forname(c.attributes['module'].value)

        
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
        
                    
        for c in root.childNodes:            
            if c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "__header":
                self._handleHeader(c, body)
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "__summary":
                self._handleSummary(c, body)
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "__maincontent":
                self._handleMainContent(c, body)
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "build":
                self._handleBuild(c, body)
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "task" and c.attributes.has_key('type') and c.attributes['type'] == "maincontent":
                self._handleMainContent(c, body)

        try:
            footer = root.getElementsByTagName("__footer")[0]
            f = self.__factory["__footer"](self.__doc, body)
            if footer.attributes.has_key("title"):
                f.setTitle(footer.attributes['title'].value)
            if footer.attributes.has_key("subtitle"):
                f.setSubTitle(footer.attributes['subtitle'].value)
        except Exception:            
            pass
        # Generate summary
        self._createSummary()

    def _handleHeader(self, node, container):
        h = self.__factory["__header"](self.__doc, container)
        if node.attributes.has_key('title'):
            self.__title.data = node.attributes['title'].value
            h.setTitle(node.attributes['title'].value)        
        if node.attributes.has_key("subtitle"):
            h.setSubTitle(node.attributes['subtitle'].value)
        
    def _handleSummary(self, node, container):
        box = self.__factory["__summary"](self.__doc, container)
        if node.attributes.has_key('title'):
            box.setTitle(node.attributes["title"].value)
        
        for c in node.getElementsByTagName("__elmt"):           
            box.addElement(c.attributes['tag'].value, c.attributes['val'].value)
        self.__xhtml_summary = box
    
    def _handleBuild(self, node, container):
        for c in node.childNodes:
            if c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "task" and c.attributes.has_key('type') and c.attributes['type'].value == 'maincontent':
                self._handleMainContent(c, container)
                

    def _handleMainContent(self, node, container):
        box = self.__factory["__maincontent"](self.__doc, container)
        if node.attributes.has_key("title"):
            box.setTitle(node.attributes["title"].value)
        if node.attributes.has_key("name"):
            box.setTitle(node.attributes["name"].value)
        for c in node.childNodes:
            if c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "__event":
                self._handleEvent(c, box.getDOMContainer())
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "task" and c.attributes.has_key('type') and c.attributes['type'].value == 'event':
                self._handleEvent(c, box.getDOMContainer())
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "message":
                self._handleMessage(c, box.getDOMContainer())
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE:
                self._handlePrint(c, box.getDOMContainer())

    def _handleEvent(self, node, container):
        tags = self.__tags
        self.__tags = {}
        event = self.__factory["__event"](self.__doc, container, self._getId())
        if node.attributes.has_key('title'):
            event.setTitle(node.attributes['title'].value)
        elif node.attributes.has_key('name'):
            event.setTitle(node.attributes['name'].value)
        for c in node.childNodes:            
            if c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "__event":
                self._handleEvent(c, event.getDOMContainer())
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "task" and c.attributes.has_key('type') and c.attributes['type'].value == 'event':
                self._handleEvent(c, event.getDOMContainer())
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE and c.tagName == "message":
                self._handleMessage(c, event.getDOMContainer())
            elif c.nodeType == xml.dom.Node.ELEMENT_NODE:
                self._handlePrint(c, event.getDOMContainer())
                
        keys = self.__tags.keys()
        keys.sort()
        for name in keys:         
            event.addStatistics(name.replace("__", ""), self.__tags[name])
        self.__tags = self._mergeStatistics(tags, self.__tags)
        
    def _handleMessage(self, node, container):
        if node.attributes['priority'].value == "printraw":
            t = self.__factory["__printraw"](self.__doc, container)
            for n in node.childNodes:
                if n.nodeType == xml.dom.Node.CDATA_SECTION_NODE:
                    t.appendText(n.data)
        else:
            t = self.__factory["__print"](self.__doc, container)
            for n in node.childNodes:
                if n.nodeType == xml.dom.Node.CDATA_SECTION_NODE:
                    t.appendText(n.data)
            if node.attributes['priority'].value != "print":
                t.setIcon(self.__config.getClass(node.attributes['priority'].value, "icn_dft"))
                if self.__tags.has_key(node.attributes['priority'].value):
                    self.__tags[node.attributes['priority'].value] += 1
                else:
                    self.__tags[node.attributes['priority'].value] = 1

    def _handlePrint(self, node, container):
        if node.tagName == "__printraw":
            t = self.__factory["__printraw"](self.__doc, container)
            for n in node.childNodes:
                if n.nodeType == xml.dom.Node.CDATA_SECTION_NODE or n.nodeType == xml.dom.Node.TEXT_NODE:
                    t.appendText(n.data)
        else:
            t = self.__factory["__print"](self.__doc, container)
            for n in node.childNodes:
                if n.nodeType == xml.dom.Node.CDATA_SECTION_NODE or n.nodeType == xml.dom.Node.TEXT_NODE:
                    t.appendText(n.data)
            if node.tagName != "__print":
                t.setIcon(self.__config.getClass(node.tagName, "icn_dft"))
                if self.__tags.has_key(node.tagName):
                    self.__tags[node.tagName] += 1
                else:
                    self.__tags[node.tagName] = 1

    def _createSummary(self):
        # pylint: disable-msg=E1101
        if self.__xhtml_summary == None:
            self.__xhtml_summary = Summary(self.__doc, self.__body)
            self.__xhtml_summary.setTitle("Global Statistics")
        keys = self.__tags.keys()
        keys.sort()
        for name in keys:
            self.__xhtml_summary.addStatistics(name.replace("__", ""), self.__tags[name])

   
    def _mergeStatistics(self, tags, newTags):
        for name in newTags.keys():
            if tags.has_key(name):
                tags[name] += newTags[name]
            else:
                tags[name] = newTags[name]
        return tags
        
    def WriteToFile(self, filename):        
        file_object = open(filename, "w")
        file_object.write(codecs.BOM_UTF8)
        file_object.write(self.__doc.toprettyxml(encoding="utf-8"))
        file_object.close()
    
    
    @staticmethod
    def forname(classname):
        r = re.match("^(?P<modname>(?:\w+\.?)*)\.(?P<classname>(\w+?))$", classname)
        if r != None:
            return getattr(__import__(r.groupdict()['modname'], [], [], r.groupdict()['classname']), r.groupdict()['classname'])
        else:
            raise Exception("Error retreiving module and classname for %s" % classname)
        

