#============================================================================ 
#Name        : test_log2xml.py 
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

""" Acceptance tests for freedisk.py

"""

import unittest
import logging
import os
import log2xml
from xml.dom import minidom
import tempfile

logger = logging.getLogger('test.log2xml')


class Log2XMLTest(unittest.TestCase):

    def test_log_conversion(self):
        """
        Convert a log into xml.
        """
        logfile = os.path.join(os.environ['TEST_DATA'], 'data', 'log2xml_test.log')
        testfile = os.path.join(tempfile.gettempdir(), "log2xml_test.xml")
        log2xml.convert(logfile, testfile)        
        minidom.parse(testfile)        

    def test_log_utf16_conversion(self):
        """
        Convert a log into xml.
        """
        logfile = os.path.join(os.environ['TEST_DATA'], 'data', 'log2xml_failure.log')
        testfile = os.path.join(tempfile.gettempdir(), "log2xml_test2.xml")
        log2xml.convert(logfile, testfile)        
        minidom.parse(testfile)        


if __name__ == '__main__':
    unittest.main()