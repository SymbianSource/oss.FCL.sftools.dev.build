#============================================================================ 
#Name        : test_bomtofile.py 
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

import tempfile
from shutil import rmtree
import logging
import unittest
from bomtofile import BOMWriter

_logger = logging.getLogger('test.bomtofile')
logging.basicConfig(level=logging.INFO)

class BomtofileTest(unittest.TestCase):
    """Verifiying bomtofile module"""
        
    def test_writeprojects(self):
        """Verifying writeprojects"""
        tmpdir = tempfile.mkdtemp()
        testProject = _emulateProject(("testProject1", "testProject2"))
        bomWriter = BOMWriter(None, "PythonUnitTesting", testProject, tmpdir)
        bomWriter.writeprojects()
        myFile = open(tmpdir+"/PythonUnitTesting_projects.txt",'r')
        contents = myFile.readlines()
        myFile.close()
        rmtree(tmpdir)
        assert len(contents) == 2

    def test_writebaselines(self):
        """Verifying writebaselines"""
        tmpdir = tempfile.mkdtemp()
        testProject = _emulateProject(("testProject1", "testProject2"))
        testSession = _emulateSession("testbaseline1")
        bomWriter = BOMWriter(testSession, "PythonUnitTesting", testProject, tmpdir)
        bomWriter.writebaselines()
        myFile = open(tmpdir+"/PythonUnitTesting_baselines.txt",'r')
        contents = myFile.readlines()
        myFile.close()
        rmtree(tmpdir)
        assert len(contents) == 4

    def test_writebaselines_withnodata(self):
        """Verifying writebaselines with no baseline"""
        tmpdir = tempfile.mkdtemp()
        testProject = _emulateProject(("testProject1", "testProject2"))
        testSession = _emulateSession(None)
        bomWriter = BOMWriter(testSession, "PythonUnitTesting", testProject, tmpdir)
        bomWriter.writebaselines()
        myFile = open(tmpdir+"/PythonUnitTesting_baselines.txt",'r')
        contents = myFile.readlines()
        myFile.close()
        rmtree(tmpdir)
        assert len(contents) == 4


    def test_writetasks(self):
        """Verifying writetasks"""
        tmpdir = tempfile.mkdtemp()
        testProject = _emulateProject(None, ("testTask1", "testTask2"))
        bomWriter = BOMWriter(None, "PythonUnitTesting", testProject, tmpdir)
        bomWriter.writetasks()
        myFile = open(tmpdir+"/PythonUnitTesting_tasks.txt",'r')
        contents = myFile.readlines()
        myFile.close()
        rmtree(tmpdir)
        assert len(contents) == 2
           
class _emulateProject():
    """Emulate a project"""
    def __init__(self, project = None, task = None):
        self.baseline = project
        self.task = task
# just emulate amara xml_properties dictionary, as the idea is 
# not to test xml file processing with amara 
        self.xml_properties = { 'task': None } 

class _emulateSession():
    """Emulate a session"""
    def __init__(self, baseline):
        self.baseline = baseline

    def create(self, project):
        return _emulateProject(self.baseline)
