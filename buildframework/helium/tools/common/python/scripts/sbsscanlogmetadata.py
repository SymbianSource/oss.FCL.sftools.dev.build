#============================================================================ 
#Name        : sbsscanlogmetadata.py
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
import sys
import re
import xml.sax
import datetime
import time
from xml.sax.handler import ContentHandler
from xml.dom.minidom import parse, parseString
from xml.sax.saxutils import XMLGenerator
from xml.sax.xmlreader import AttributesNSImpl
import codecs
from optparse import OptionParser


IGNORE_TEXT_REG_EX = "warning: no newline at end of file"

STREAM_REGEX =  {   "clean" : [r'<clean', r'</clean'],
                    "what" : [r'<whatlog', r'</whatlog'],
                    "warning" : [r'<warning', r'</warning']
                }

class SBSScanlogMetadata(object):
    """parses the raptor meatadata logs and separates the info out into HTML and XML logs for writing 
    to diamonds and other logs"""

    def initializeLogPath(self):
        index = self.logFileName.rfind(".")
        if index < 0:
            index = len(self.logFileName)
        for stream in STREAM_REGEX.keys():
            self.stream_path[stream] = self.logFileName[:index] + "." + stream + \
                        self.logFileName[index:]            
        if os.environ.has_key('SBS_CLEAN_LOG_FILE'):
            self.stream_path['clean'] = os.environ['SBS_CLEAN_LOG_FILE']
        if os.environ.has_key('SBS_WHAT_LOG_FILE'):
            self.stream_path['what'] = os.environ['SBS_WHAT_LOG_FILE']
            
    def initialize(self, logFile):
        """Initialize helium log filter"""
        self.ignoreTextCompileObject = re.compile(IGNORE_TEXT_REG_EX);
        self.logFileName = str(logFile)
        self.streamStatus = {}
        self.streams = {}
        self.stream_path = {}
        self.start_time = datetime.datetime.now()
        self.loggerout = open(self.logFileName,"w")
        self.compiled_stream_object = {}
        print "logName: %s\n" % self.logFileName
        self.initializeLogPath()
        for stream in STREAM_REGEX.keys():
            self.compiled_stream_object[stream] = []
            self.streams[stream] = open(self.stream_path[stream], "w")
            self.streamStatus[stream] = False
            self.streams[stream].write(\
"""<?xml version="1.0" encoding="ISO-8859-1" ?>
<buildlog sbs_version="" xmlns="http://symbian.com/xml/build/log" xmlns:progress="http://symbian.com/xml/build/log/progress" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://symbian.com/xml/build/log http://symbian.com/xml/build/log/1_0.xsd">""")
            for  searchString in STREAM_REGEX[stream]:
                self.compiled_stream_object[stream].append(re.compile(searchString))
        return True

    def open(self, logFile):
        self.logFileName = str(logFile)
        return self.initialize(logFile)
        
        
    def write(self, text):
        """ callback function which is to process the logs"""
        stream_list = STREAM_REGEX.keys()
        for textLine in text.splitlines():
            textLine = textLine + '\n'
            if textLine.startswith("<?xml ") or textLine.startswith("<buildlog ") \
                or textLine.startswith("</buildlog"):
                self.loggerout.write(textLine)
                continue
            if(self.ignoreTextCompileObject.search(textLine)):
                continue
            for stream in stream_list:
                if( (not self.streamStatus[stream]) and self.compiled_stream_object[stream][0].search(textLine)!= None):
                    self.streamStatus[stream] = True
                if (self.streamStatus[stream] and self.compiled_stream_object[stream][1].search(textLine)!= None):
                    self.streams[stream].write(textLine)
                    self.streamStatus[stream] = False
                    break
    
                if(self.streamStatus[stream]):
                    if textLine.startswith("<?xml ") or textLine.startswith("<buildlog ") \
                        or textLine.startswith("</buildlog"):
                        continue
                    self.streams[stream].write(textLine)
                    break

            self.loggerout.write(textLine)
        return True
        
    def summary(self):
        """Write Summary"""
        sys.stdout.write("sbs: build log in %s\n" % str(self.logFileName))
        return False

    def close(self):
        """Close the log file"""

        try:
            self.loggerout.close()
            for stream in self.streams.keys():
                self.streams[stream].write('</buildlog>')
                self.streams[stream].close()
            return True
        except:
            self.loggerout = None
            self.streams = None
        return False

if __name__ == "__main__":

    """ standalone app """
    cli = OptionParser(usage="%prog [options]")
    cli.add_option("--log", help="Raptor log file")
    cli.add_option("--output", help="Raptor log file")
                   
    opts, dummy_args = cli.parse_args()
    if not opts.log:
        cli.print_help()
        sys.exit(-1)

    filter = SBSScanlogMetadata()
    filter.open(opts.output)

    logFile = open(opts.log, 'r')

    for line in logFile:
        filter.write(line)

    filter.summary()
    filter.close()