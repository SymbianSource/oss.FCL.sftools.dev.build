#============================================================================ 
#Name        : filter_metadatalog.py
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
import raptor
import filter_interface
import re
import xml.sax
import datetime
import time
from xml.sax.handler import ContentHandler
from xml.dom.minidom import parse, parseString
from xml.sax.saxutils import XMLGenerator
from xml.sax.xmlreader import AttributesNSImpl
import codecs
from sbsscanlogmetadata import SBSScanlogMetadata
from optparse import OptionParser




""" plugin that gets copied to raptor folder so that wehn raptor (SBS) runs it
    knows the format of the log files.
"""
class FilterMetadataLog(filter_interface.Filter):
    """Log scanner for filter logs"""
    def open(self, raptor_instance):
        """Open a log file for the various I/O methods to write to."""
        self.raptor = raptor_instance
        self.logFileName = self.raptor.logFileName
        self.scanlog = SBSScanlogMetadata()

        # insert the time into the log file name
        if self.logFileName:
            self.logFileName.path = self.logFileName.path.replace("%TIME",
                    self.raptor.timestring)
    
            try:
                dirname = str(self.raptor.logFileName.Dir())
                if dirname and not os.path.isdir(dirname):
                    os.makedirs(dirname)
            except Exception, e_error:
                return False
            return  self.scanlog.initialize(self.logFileName)
        else:
            self.out = sys.stdout
                
        return True

    def write(self, text):
        """write the text to the opened file"""
        return self.scanlog.write(text)

    def summary(self):
        """write the summary file"""
        return self.scanlog.summary()

    def close(self):
        """close the log file"""
        return self.scanlog.close()
