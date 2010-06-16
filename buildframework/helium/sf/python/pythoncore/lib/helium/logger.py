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

""" Port to python of the ISIS::Logger3 perl module

 1.0.0 (13/12/2006)
  - First version of the module.
"""

# pylint: disable-msg=E1101,E1103

import codecs
import xml.dom.minidom
import datetime
import traceback

class _CustomizePrint(object):
    """ This is an Internal helper call. """
    
    def __init__(self, logger, name):
        """Initialise the instance content 
        @param logger a Logger instance
        @param name method name (e.g. Print, Error), could be any strings"""
        self.__logger = logger
        self.__name = name
    
    def __call__(self, *args):
        """Make this object callable. Call _print from the logger instance.
        @params *args a list of arguments"""
        self.__logger._print(self.__name, args)


class Logger(object):
    """ Logger class used to create xml logging in python """
    def __init__(self):
        """Constructor of the Logger."""
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

    def SetInterface(self, url):
        """Set the url of interface to use."""
        self.__lognode.setAttributeNS("", "interface", url)

    def SetVerbose(self, v):
        """Enable/Disable shell output
        @param v boolean to set the logger output"""
        self.__verbose = v
    
    def SetTitle(self, title):
        """Set the title of the document
        @param title the title to set"""
        self.__header.setAttributeNS("", "title", title)
        
    def SetSubTitle(self, title):
        """Set the subtitle of the document
        @param subtitle the subtitle to set"""
        self.__header.setAttributeNS("", "subtitle", title)

    def SetSummaryTitle(self, title):
        """Set the sumamry title
        @param title the title to set"""
        self.__summary.setAttributeNS("", "title", title)
        
    def AddSummaryElement(self, tag, value):
        """Creates a summary couple.
        @param tag the description
        @param value the value"""
        elem = self.__doc.createElementNS("", "__elmt")
        elem.setAttributeNS("", "tag", tag)
        elem.setAttributeNS("", "val", value)
        self.__summary.appendChild(elem)
        
        
    def OpenMainContent(self, title=""):
        """Open a MainContent section.
        @param title title of the MainContent section"""
        self.__stack.append(self.__current_node)
        node = self.__doc.createElementNS("", "task")
        node.setAttributeNS("", "name", title)
        node.setAttributeNS("", "type", "maincontent")
        node.setAttributeNS("", "time", datetime.datetime.now().ctime())
        self.__current_node.appendChild(node)
        self.__current_node = node
        if self.__verbose:
            print ("---------------------------------------------------------------------")
            print ("  %s" % title)
            print ("---------------------------------------------------------------------")

        
    def CloseMainContent(self):
        """ Close the current main content section.
        Make sure you have closed other Event/Section first"""
        if self.__current_node.nodeName != "task" and not (self.__current_node.attributes.has_key('type') and self.__current_node.attributes['type']=="maincontent"):
            raise Exception("not closing a 'maincontent' typed node")
        self.__current_node = self.__stack.pop()
        
        
    def OpenEvent(self, title=""):
        """Create an Event section (can be opened/closed)
        @param title title of the MainContent section"""
        self.__stack.append(self.__current_node)
        node = self.__doc.createElementNS("", "task")
        node.setAttributeNS("", "name", title)
        node.setAttributeNS("", "type", "event")
        node.setAttributeNS("", "time", datetime.datetime.now().ctime())
        self.__current_node.appendChild(node)
        self.__current_node = node
        if self.__verbose:
            print ("---------------------------------------------------------------------")
            print (" + %s" % title)

    def SetCustomOutputer(self, type, classname, config = None):
        """set custom out puter"""
        node = self.__doc.createElementNS("", "__customoutputer")
        node.setAttributeNS("", "type", type)
        node.setAttributeNS("", "module", classname)
        if config != None:
            node.appendChild(config)
        self.__lognode.appendChild(node)
        
    def CloseEvent(self):
        """# Close the current Event
        Make sure you have closed other Event/Section first"""
        if self.__current_node.nodeName != "task" and (self.__current_node.attributes.has_key('type') and self.__current_node.attributes['type']=="event"):
            raise Exception("not closing a 'event' typed node")
        self.__current_node = self.__stack.pop()
    
    def __getattribute__(self, attr):
        """__getattribute__ has been overrided to enable dynamic messaging.
        @param attr the name of the method (or attribute...)"""
        try:
            return object.__getattribute__(self, attr)  
        except AttributeError:
            return _CustomizePrint(self, attr)        

    def _print(self, kind, *args):
        """Generic method that handle the print in the XML document
            @param kind type of output
            @param *args a list of arguments (must be strings)"""
        output = u"".join(map(lambda x: u"%s" % x, list(*args)))
        nodetype = kind.lower()
        msgtype = ""
        if nodetype != "print" and nodetype != "info" and nodetype != "debug":
            msgtype = "%s:" % nodetype.upper()
        if self.__verbose:
            print "%s %s" % (msgtype, output.encode('utf-8'))

        node = self.__doc.createElementNS("", "message")
        node.setAttributeNS("", "priority", nodetype)
        #n.setAttributeNS("", "time", datetime.datetime.now().ctime())
        node.appendChild(self.__doc.createCDATASection(output))
        self.__current_node.appendChild(node)
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
    
    
    def SetFooterTitle(self, title):
        """set footer title"""
        self.__footer.attributes['title'] = title
        
    def SetFooterSubTitle(self, subtitle):
        """set footer sub title"""
        self.__footer.attributes['subtitle'] = subtitle
    
    def Die(self, title, subtitle, exception):
        """Die - kill it off?"""
        self.SetFooterTitle(title)
        self.SetFooterSubTitle("%s\nException raised: %s\n%s" % (subtitle, exception, traceback.format_exc()))

    def WriteToFile(self, filename):
        """Write the DOM tree into a file.
         @param filename the file to write in."""
        file_object = open(filename, "w")
        file_object.write(codecs.BOM_UTF8)
        file_object.write(self.__doc.toprettyxml(encoding = "utf-8"))
        file_object.close()


    ##
    # Write the DOM tree into a file.
    # @param filename the file to write in.
    def __str__(self):
        return self.__doc.toprettyxml(encoding="utf-8")
