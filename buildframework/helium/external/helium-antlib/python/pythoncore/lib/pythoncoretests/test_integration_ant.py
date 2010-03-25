#============================================================================ 
#Name        : test_integration_ant.py
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
""" Testing integration.ant module """  

import tempfile
import os
import logging
import unittest
import integration.ant

_logger = logging.getLogger('test.integration.ant')
logging.basicConfig(level=logging.INFO)

class IntegrationAntTest(unittest.TestCase):
    """Verifying integration ant module"""
    def test_check_build_duplicates_task(self):
        """Verifying check_build_duplicates_task method """
        (fileDes, outputFilename) = tempfile.mkstemp()
        os.close(fileDes)
        integration.ant.check_build_duplicates_task(None, _emulateTask(), _emulateAttributes(outputFilename),  _emulateElements())
        outputFile = open(outputFilename, 'r')
        contents = outputFile.readlines() 
        outputFile.close()
        os.unlink(outputFilename)
        assert len(contents) == 15
    def test_check_build_duplicates_task_invalid(self):
        """Verifying check_build_duplicates_task (invalid args) method"""
        self.assertRaises(Exception, integration.ant.check_build_duplicates_task, None, None, None, None)

class _emulateTask():
    """Emulate task"""
    def log(self, message):
        """Emulate log method"""
        pass

class _emulateAttributes():
    """Emulate attributes"""
    def __init__(self, outputFilename):
        self.outputFilename = outputFilename
    def get(self, attribute):
        """Emulate get method"""
        return self.outputFilename

class _emulateElements():
    """Emulate elements"""
    def get(self, fileset):
        """Emulate get method"""
        return _emulateFileset()

class _emulateFileset():
    """Emulate fileset"""
    def get(self, eid):
        """Emulate get method"""
        return _emulateDirScanner()
    def size(self):
        """Emulate size method"""
        return 1

class _emulateDirScanner():
    """Emulate dirscanner"""
    def scan(self):
        """Emulate scan method"""
        pass
    def getIncludedFiles(self):
        """Emulate getIncludedFiles method """
        if os.sep == '\\':
            return ['test_build_compile.log']
        elif os.sep == '/':
            return ['test_build_compile_linux.log']
    def getDirectoryScanner(self, project):
        """Emulate getDirectoryScanner method """
        return self
    def getBasedir(self):
        """Emulate getBasedir method """
        return os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'logs')
