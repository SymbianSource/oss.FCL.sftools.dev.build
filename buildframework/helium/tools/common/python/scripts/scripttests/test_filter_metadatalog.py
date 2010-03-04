#============================================================================ 
#Name        : test_filter_metadatalog.py 
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

""" Test cases for filter meta data logs.

"""

# pylint: disable-msg=E1101

import logging
import os
import sys
import time
import mocker
import re
import tempfile
import shutil

_logger = logging.getLogger('test.test_filter_metadatalog')
logging.basicConfig(level=logging.DEBUG)

TEMP_PATH = tempfile.mkdtemp()
#NOTE: THE COMMENTED OUT CODE IS REQUIRED WHEN RUNNING THIS TEST USING THE PT TARGET
#WITH THE COMMENTED OUT CODE IT DOES NOT WORK IN THE FULL UNITTEST TARGET DUE TO RAPTOR.PY
#FILE BEING CALLED WITHOUT ALL THE ENVIRONMENT VARIABLES SET WHEN RUN SINGLY AND THEY ARE SET WHEN
#RUN AS PART OF THE UNITTEST TARGET.

PYTHON_FILE_NAME = os.path.join(TEMP_PATH, 'raptor.py')
FILTER_FILE_NAME = os.path.join(TEMP_PATH, 'filter_interface.py')

sys.path = [TEMP_PATH] + sys.path

def setup_module():
    """ Setup for test_filter_metadata """
    #in order to allow the filter_metadata.py file to compile we need to create a dummy 
    #raptor.py file as this is part of SBS and not present here, the classes and objects 
    #it uses from raptor.py file are created in this file, the same goes for the file filter_interface.py
    #does not exist so create empty python.py file
    f_handle = open(PYTHON_FILE_NAME, "w")
    f_handle.write("class testRaptor():\n")
    f_handle.write("    def testRaptorFunc(self):\n")
    f_handle.write("        return True \n")
    f_handle.close()
    #does not exist so create empty python.py file
    f_handle = open(FILTER_FILE_NAME, "w")
    f_handle.write("class Filter():\n")
    f_handle.write("    def testFilterFunc(self):\n")
    f_handle.write("        return True \n")
    f_handle.close()


def teardown_module():
    """ Teardown test_filter_metadata. """
    print("teardown called")
    if os.path.exists(TEMP_PATH):
        shutil.rmtree(TEMP_PATH)

# regex for "bare" drive letters  
DRIVERE = re.compile('^[A-Za-z]:$')

# are we on windows, and if so what is the current drive letter
ISWIN = sys.platform.lower().startswith("win")
if ISWIN:
    DRIVE = re.match('^([A-Za-z]:)', os.getcwd()).group(0)

# Base class
class Path(object):
    """This class represents a file path.                                      
                                                                               
    A generic path object supports operations without needing to know          
    about Windows and Linux differences. The standard str() function can       
    obtain a string version of the path in Local format for use by             
    platform-specific functions (file opening for example).                    
                                                                               
    We use forward slashes as path separators (even on Windows).               
                                                                               
    For example,                                                               
                                                                               
      path1 = generic_path.Path("/foo")                                        
      path2 = generic_path.Path("bar", "bing.bang")                            
                                                                               
      print str(path1.Append(path2))                                           
                                                                               
    Prints /foo/bar/bing.bang   on Linux                                       
    Prints c:/foo/bar/bing.bang   on Windows (if c is the current drive)       
    """                                                                        

    def __init__(self, *arguments):
        """construct a path from a list of path elements"""
        
        if len(arguments) == 0:
            self.path = ""
            return
        
        list = []
        for i, arg in enumerate(arguments):
            if ISWIN:
                if i == 0:
                    # If the first element starts with \ or / then we will
                    # add the current drive letter to make a fully absolute path
                    if arg.startswith("\\\\"):
                        list.append(arg) # A UNC path - don't mess with it
                    elif arg.startswith("\\") or arg.startswith("/"):
                        list.append(DRIVE + arg)
                    # If the first element is a bare drive then dress it with a \
                    # temporarily otherwise "join" will not work properly.
                    elif DRIVERE.match(arg):
                        list.append(arg + "\\")
                    # nothing special about the first element
                    else:
                        list.append(arg)
                else:
                    if arg.startswith("\\\\"):
                        raise ValueError("non-initial path components must not start with \\\\ : %s" % arg)
                    else:
                        list.append(arg)
                if ";" in arg:
                    raise ValueError("An individual windows Path may not contain ';' : %s" % arg)
            else:
                list.append(arg)
      
        self.path = os.path.join(*list)
        
        # normalise to avoid nastiness with dots and multiple separators
        # but do not normalise "" as it will become "."
        if self.path != "":
            self.path = os.path.normpath(self.path)
        
        # always use forward slashes as separators
        self.path = self.path.replace("\\", "/")
        
        # remove trailing slashes unless we are just /
        if self.path != "/":
            self.path = self.path.rstrip("/")

    def Dir(self):
        "return an object for the directory part of this path"
        if DRIVERE.match(self.path):
            return Path(self.path)
        else:
            return Path(os.path.dirname(self.path))
    def __str__(self):
        return self.path


class Raptor(object):
    """An instance of a running Raptor program.

    When operated from the command-line there is a single Raptor object
    created by the Main function. When operated by an IDE several Raptor
    objects may be created and operated at the same time."""

    def defaultSetUp(self):
        """ setup some variables for use by the unit under test """
        self.logFile = None #self.mocker.proxy(generic_path.Join)
        self.summary = True
        # things to initialise
        self.starttime = time.time()
        self.timestring = time.strftime("%Y-%m-%d-%H-%M-%S")
        self.logFileName = Path(os.path.join(TEMP_PATH, 'makefile_2009-11-12-12-32-34.log'))

class FilterMetaDataLogTest(mocker.MockerTestCase):
    """ Tests the filter_metadataLog wrapper to the SBS plugin. 
    The plugin uses the SBS API of open, write, summary and close. """

#    def test_a_setupOK(self):       #need to call it this to get it executed in the right order (alphabetical)
#        """test_a_setupOK: tests that we have imported the correct files and that they are present 
#        before importing the file to be tested and having it fail due to missing files"""
#        print("got to test-a-setup ")
#        import filter_metadatalog
#        print("got passed import filter file to test-a-setup ")
#        #setup an instance of the class and test it exists OK
#        obj = filter_metadatalog.raptor.testRaptor()
#        result = obj.testRaptorFunc()
#        assert result == True
#        obj = filter_metadatalog.filter_interface.Filter()
#        result = obj.testFilterFunc()
#        assert result == True

    def test_openWriteSummaryCloseInvalidData(self):
        """test_openWriteSummaryCloseInvalidData: test the opening writing, summary and 
        closing of the log file with invalid data."""
        import filter_metadatalog
        obj = self.mocker.patch(filter_metadatalog.SBSScanlogMetadata)
        obj.initialize(mocker.ANY)
        self.mocker.result(False)
        self.mocker.replay()
        
        raptor_instance = Raptor()
        raptor_instance.defaultSetUp()
        raptor_instance.logFileName = Path("..")
        filter_mLog = filter_metadatalog.FilterMetadataLog()
        result = filter_mLog.open(raptor_instance)
        assert result == False
        result = filter_mLog.close()
        assert result == False

    def test_openValidData_default(self):
        """test_openValidData_default: test the opening of the log file with valid data."""
        import filter_metadatalog
        obj = self.mocker.patch(filter_metadatalog.SBSScanlogMetadata)
        obj.initialize(mocker.ANY)
        self.mocker.result(True)
        self.mocker.replay()
        
        raptor_instance = Raptor()
        raptor_instance.defaultSetUp()
        filter_mLog = filter_metadatalog.FilterMetadataLog()
        result = filter_mLog.open(raptor_instance)
        assert result == True

    def test_openValidData_empty(self):
        """test_openValidData_empty: test the opening of the log file with valid data."""
        import filter_metadatalog
        obj = self.mocker.patch(filter_metadatalog.SBSScanlogMetadata)
        obj.initialize(mocker.ANY)
        self.mocker.result(True)
        self.mocker.replay()
        
        raptor_instance = Raptor()
        raptor_instance.defaultSetUp()
        raptor_instance.logFileName = Path("")
        filter_mLog = filter_metadatalog.FilterMetadataLog()
        result = filter_mLog.open(raptor_instance)
        assert result == True

    def test_openValidData_stdout(self):
        """test_openValidData_stdout: test the opening of the log file with valid data."""
        import filter_metadatalog
        obj = self.mocker.patch(filter_metadatalog.SBSScanlogMetadata)
        obj.initialize(mocker.ANY)
        self.mocker.count(0, 0)
        self.mocker.replay()
        
        raptor_instance = Raptor()
        raptor_instance.defaultSetUp()
        raptor_instance.logFileName = None
        filter_mLog = filter_metadatalog.FilterMetadataLog()
        result = filter_mLog.open(raptor_instance)
        assert result == True

