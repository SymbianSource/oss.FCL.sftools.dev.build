#============================================================================ 
#Name        : filter_heliumlog.py 
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

WARNING_TAG = "<warning>.*</warning>"

class SBSScanlogMetadata():
    def initialize(self, logFile):
        """Initialize helium log filter"""
        self.ignoreTextCompileObject = re.compile(IGNORE_TEXT_REG_EX);
        self.warningCompileObject = re.compile(WARNING_TAG);
        self.startRecording = False
        self.logFileName = logFile
        self.warningFileName = "%s%s" % (logFile, "exceptions.xml")
        self.inReceipe = False
        self.start_time = datetime.datetime.now()
        self.loggerout = open(str(self.logFileName),"w")
        self.warningout = open(str(self.warningFileName),"w")
        print "logName: %s\n" % self.logFileName
        return True

    def open(self, logFile):
        self.logFileName = logFile
        self.initialize(logFile)
        
        
    def write(self, text):
        """ callback function which is to process the logs"""
        for textLine in text.splitlines():
            textLine = textLine + '\n'
            if(self.ignoreTextCompileObject.search(textLine)):
                continue

            #only temporary until the fix for special character handling from raptor is available
            if(self.warningCompileObject.search(textLine)):
                self.warningout.write(textLine + "\n")
                continue
            self.loggerout.write(textLine)
        return True
        
    def summary(self):
        """Write Summary"""
        sys.stdout.write("sbs: build log in %s\n" % str(self.logFileName))
        return False

    def close(self):
        """Close the log file"""

        try:
            self.warningout.close()
            self.loggerout.close()
            return True
        except:
            self.loggerout = None
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