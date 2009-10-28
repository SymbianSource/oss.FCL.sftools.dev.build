#============================================================================ 
#Name        : logger.py 
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
# Logger module
# Description : Port to python of the ISIS::Logger3 perl module
#
# 1.0.0 (13/12/2006)
#  - First version of the module.
##

# pylint: disable-msg=E1101,E1103

import codecs
import xml.dom.minidom
import datetime
from os import popen
import traceback

#
# This is an Internal helper call. 
#
class _CustomizePrint(object):
    
    ##
    # Initialise the instance content 
    # @param logger a Logger instance
    # @param name method name (e.g. Print, Error), could be any strings
    def __init__(self, logger, name):
        self.__logger = logger
        self.__name = name
    
    ##
    # Make this object callable. Call _print from the logger instance.
    # @params *args a list of arguments
    def __call__(self, *args):
        self.__logger._print(self.__name, args)        
    
##
# The Logger enables to create xml logging in Python.
#
class Logger(object):
    
    ##
    # Constructor of the Logger.
    def __init__(self):
        self.__step = 1
        self.__doc = xml.dom.minidom.Document()
        self.__lognode = self.__doc.createElementNS("", "__log")        
        self.__header = self.__doc.createElementNS("", "__header")
        self.__footer = self.__doc.createElementNS("", "__footer")
        self.__summary = self.__doc.createElementNS("", "__summary")
        self.__lognode.appendChild(self.__header)
        self.__lognode.appendChild(self.__summary)
        self.__lognode.appendChild(self.__footer)        
        self.__lognode.setAttributeNS("", "date", "%s" % datetime.datetime.now().ctime())
        self.__footer.setAttributeNS("", "title", "")
        self.__footer.setAttributeNS("", "subtitle", "")
        self.__doc.appendChild(self.__lognode)
        self.__build = self.__doc.createElementNS("", "build")
        self.__lognode.appendChild(self.__build)
        self.__current_node = self.__build
        self.__stack = []
        self.__verbose = True
        #<__log date="Wed Dec  6 03:07:25 2006">

    ##
    # Set the url of interface to use.
    def SetInterface(self, url):
        self.__lognode.setAttributeNS("", "interface", url)

    ##
    # Enable/Disable shell output
    # @param v boolean to set the logger output
    def SetVerbose(self, v):
        self.__verbose = v
    
    ##
    # Set the title of the document
    # @param title the title to set
    def SetTitle(self, title):        
        self.__header.setAttributeNS("", "title", title)
        
    ##
    # Set the subtitle of the document
    # @param subtitle the subtitle to set
    def SetSubTitle(self, title):        
        self.__header.setAttributeNS("", "subtitle", title)

    ##
    # Set the sumamry title
    # @param title the title to set
    def SetSummaryTitle(self, title):
        self.__summary.setAttributeNS("", "title", title)
        
    ##
    # Creates a summary couple.
    # @param tag the description
    # @param value the value
    def AddSummaryElement(self, tag, value):
        e = self.__doc.createElementNS("", "__elmt")
        e.setAttributeNS("", "tag", tag)
        e.setAttributeNS("", "val", value)
        self.__summary.appendChild(e)
        
        
    ##
    # Open a MainContent section.
    # @param title title of the MainContent section
    def OpenMainContent(self, title=""):
        self.__stack.append(self.__current_node)
        n = self.__doc.createElementNS("", "task")
        n.setAttributeNS("", "name", title)
        n.setAttributeNS("", "type", "maincontent")
        n.setAttributeNS("", "time", datetime.datetime.now().ctime())
        self.__current_node.appendChild(n)
        self.__current_node = n
        if self.__verbose:
            print ("---------------------------------------------------------------------")
            print ("  %s" % title)
            print ("---------------------------------------------------------------------")

        
    ##
    # Close the current main content section.
    # Make sure you have closed other Event/Section first
    def CloseMainContent(self):
        if self.__current_node.nodeName != "task" and not (self.__current_node.attributes.has_key('type') and self.__current_node.attributes['type']=="maincontent"):
            raise Exception("not closing a 'maincontent' typed node")
        self.__current_node = self.__stack.pop()
        
        
    ##
    # Create an Event section (can be opened/closed)
    # @param title title of the MainContent section
    def OpenEvent(self, title=""):
        self.__stack.append(self.__current_node)
        n = self.__doc.createElementNS("", "task")
        n.setAttributeNS("", "name", title)
        n.setAttributeNS("", "type", "event")
        n.setAttributeNS("", "time", datetime.datetime.now().ctime())
        self.__current_node.appendChild(n)
        self.__current_node = n
        if self.__verbose:
            print ("---------------------------------------------------------------------")
            print (" + %s" % title)

    def SetCustomOutputer(self, type, classname, config = None):
        n = self.__doc.createElementNS("", "__customoutputer")
        n.setAttributeNS("", "type", type)
        n.setAttributeNS("", "module", classname)
        if config != None:
            n.appendChild(config)
        self.__lognode.appendChild(n)
        
    ##
    # Close the current Event
    # Make sure you have closed other Event/Section first
    def CloseEvent(self):
        if self.__current_node.nodeName != "task" and (self.__current_node.attributes.has_key('type') and self.__current_node.attributes['type']=="event"):
            raise Exception("not closing a 'event' typed node")
        self.__current_node = self.__stack.pop()
    
    ##
    # __getattribute__ has been overrided to enable dynamic messaging.
    # @param attr the name of the method (or attribute...)
    def __getattribute__(self, attr):
        try:
            return object.__getattribute__(self, attr)  
        except AttributeError:
            return _CustomizePrint(self, attr)        
            
    ##
    # Generic method that handle the print in the XML document
    # @param kind type of output
    # @param *args a list of arguments (must be strings)
    def _print(self, kind, *args):
        output = u"".join(map(lambda x: u"%s" % x, list(*args)))
        nodetype = kind.lower()
        msgtype = ""
        if nodetype != "print" and nodetype != "info" and nodetype != "debug":
            msgtype = "%s:" % nodetype.upper()
        if self.__verbose:
            print "%s %s" % (msgtype, output.encode('utf-8'))
        
                
        n = self.__doc.createElementNS("", "message")
        n.setAttributeNS("", "priority", nodetype)
        #n.setAttributeNS("", "time", datetime.datetime.now().ctime())
        n.appendChild(self.__doc.createCDATASection(output))
        self.__current_node.appendChild(n)
#        nodetype = kind.lower()
#        if kind.lower() != "print" and kind.lower() != "printraw":
#            nodename = kind.lower()
#
#        if nodename=="__print" and self.__current_node.lastChild!=None and self.__current_node.lastChild.nodeName  == nodename:
#            self.__current_node.lastChild.appendChild(self.__doc.createTextNode("".join(*args).decode('iso-8859-1')))
#        else:
#            n = self.__doc.createElementNS("", nodename)
#            n.setAttributeNS("", "step", "%d" % self.__step)
#            self.__step += 1
#            n.setAttributeNS("", "time", datetime.datetime.now().ctime())
#            text_content = "".join(map(lambda x: str(x), list(*args))).decode('iso-8859-1')
#            n.appendChild(self.__doc.createTextNode(text_content))
#            self.__current_node.appendChild(n)
    
    
    ##
    #
    def SetFooterTitle(self, title):
        self.__footer.attributes['title'] = title
        
    def SetFooterSubTitle(self, subtitle):
        self.__footer.attributes['subtitle'] = subtitle
    
    def Die(self, title, subtitle, exception):
        self.SetFooterTitle(title)
        self.SetFooterSubTitle("%s\nException raised: %s\n%s" % (subtitle, exception, traceback.format_exc()))

    ##
    # Write the DOM tree into a file.
    # @param filename the file to write in.
    def WriteToFile(self, filename):        
        file_object = open(filename, "w")
        file_object.write(codecs.BOM_UTF8)
        file_object.write(self.__doc.toprettyxml(encoding = "utf-8"))
        file_object.close()


    ##
    # Write the DOM tree into a file.
    # @param filename the file to write in.
    def __str__(self):        
        return self.__doc.toprettyxml(encoding="utf-8")
