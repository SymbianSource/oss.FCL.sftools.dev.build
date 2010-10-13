# -*- coding: latin-1 -*-

#============================================================================ 
#Name        : test_bootup_testing.py 
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

""" Testing Bootup tests framework. """

# pylint: disable=E1101

import logging
logging.getLogger().setLevel(logging.INFO)
import os
#import shutil
from path import path
import ats3.bootup_testing
import tempfile
import zipfile
import platform

TEST_PATH = None
TEST_FILES = {}
OUTPUT = None
TOTAL_TESTS_COUNT = 3


class Bunch(object):
    """ Configuration object. Argument from constructor are converted into class attributes. """
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)
        
class SetUp(object):
    """ Setup the module. """
    
    def __init__(self):
        """ Setup test environment. """
        global TEST_PATH, OUTPUT

        TEST_PATH = path(tempfile.mkdtemp())
        component = TEST_PATH
        component.joinpath("ats_build_drive").makedirs()
        for path_parts in (("output", "images", "image1.fpsx"),
                           ("output", "images", "image2.fpsx"),
                           ("output", "ats", "temp.txt")):
            filepath = component.joinpath(*path_parts)
            if not filepath.parent.exists():
                filepath.parent.makedirs()
            filepath.touch()
            TEST_FILES.setdefault(path_parts[1], []).append(filepath)
        
        OUTPUT = component.joinpath(r"output")
        
        if not filepath.parent.exists():
            filepath.parent.makedirs()
        filepath.touch()


def teardown_module(test_run_count):
    """ stuff to do after running the tests """

    if test_run_count == 0:
        path(TEST_PATH).rmtree()  

class TestBootupTestPlan(SetUp):
    """ test BootupTestDrop.py """

    def __init__(self):
        """initialize bootup Tests"""
        SetUp.__init__(self)
        self.file_store = OUTPUT
        self.build_drive = "j:"
        self.drop_file = path(r"%s/ats/ATSBootupDrop.zip" %OUTPUT).normpath()

        image_files = r"%s/images/image1.fpsx, %s/images/image2.fpsx " % (OUTPUT, OUTPUT)
        self.flash_images = image_files 
        self.config = None

    def read_xml(self, file_location, zip_file=False):
        """reads test.xml file if a path is given"""

        xml_text = ""
        file_location = path(file_location)
        if zip_file:
            if zipfile.is_zipfile(file_location):
                myzip = zipfile.ZipFile(file_location, 'r')
                xml_text = myzip.read('test.xml')
                myzip.close()

        else:
            hnd = open(file_location, 'r')
            for line in hnd.readlines():
                xml_text = xml_text + line

        return xml_text

    def test_xml_file(self):
        """ test bootup_testing.py generates correct test.xml file"""
        global TOTAL_TESTS_COUNT
        opts = Bunch(build_drive=self.build_drive,
                     drop_file=path(r"%s/ats/ATSBootupDrop.zip" %OUTPUT).normpath(),
                     flash_images=self.flash_images,
                     template_loc="",
                     file_store=self.file_store,
                     report_email="firstname.lastname@domain.com",
                     testrun_name="Bootup test run",
                     alias_name="alias",
                     device_type="new_device",
                     diamonds_build_url="http://diamonds.com/1234",
                     email_format="simplelogger",
                     email_subject="Bootup test report",
                     verbose="false")

        self.config = ats3.bootup_testing.Configuration(opts)
        ats3.bootup_testing.create_drop(self.config)

        xml_loc = os.path.join(os.environ['TEST_DATA'], 'data/bootup_testing/test_bootup.xml')
        stored_xml = self.read_xml(xml_loc, False).strip()
        drop_loc = os.path.join(OUTPUT, 'ats/ATSBootupDrop.zip')
        generated_xml = self.read_xml(drop_loc, True).strip()

        if platform.system().lower() == "linux":
            assert stored_xml.replace('\r', '') in generated_xml
        else:
            assert stored_xml in generated_xml
            
        TOTAL_TESTS_COUNT -= 1
        teardown_module(TOTAL_TESTS_COUNT)

        
        
        
        