# -*- coding: latin-1 -*-

#============================================================================ 
#Name        : test_matti2.py 
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

""" Testing MATTI framework. """

# pylint: disable=E1101

import logging
logging.getLogger().setLevel(logging.INFO)
import os
#import shutil
from path import path
import ats3.matti2
import tempfile
import zipfile
import platform

TEST_PATH = None
TEST_FILES = {}
MATTI = None
OUTPUT = None
SISFILES = None
TOTAL_TESTS_COUNT = 3


class Bunch(object):
    """ Configuration object. Argument from constructor are converted into class attributes. """
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)
        
class SetUp(object):
    """ Setup the module. """
    
    def __init__(self):
        """ Setup test environment. """
        global TEST_PATH, MATTI, OUTPUT, SISFILES

        TEST_PATH = path(tempfile.mkdtemp())
        component = TEST_PATH
        component.joinpath("matti").makedirs()
        for path_parts in (("matti_testcases", "profile", "all.sip"),
                           ("matti_testcases", "profile", "bat.sip"),
                           ("matti_testcases", "profile", "fute.sip"),
                           ("matti_testcases", "hwdata", "paths.pkg"),
                           ("matti_testcases", "hwdata", "file1.txt"),
                           ("matti_testcases", "hwdata", "settings.ini"),
                           ("matti_testcases", "matti_parameters", "matti_parameters.xml"),
                           ("matti_testcases", "unit_test1.rb"),
                           ("matti_testcases", "unit_test2.rb"),
                           ("output", "images", "image1.fpsx"),
                           ("output", "images", "image2.fpsx"),
                           ("sisfiles", "abc.sis"),
                           ("sisfiles", "xyz.sis"),
                           ("output", "ats", "temp.txt")):
            filepath = component.joinpath(*path_parts)
            if not filepath.parent.exists():
                filepath.parent.makedirs()
            filepath.touch()
            TEST_FILES.setdefault(path_parts[1], []).append(filepath)
        
        OUTPUT = component.joinpath(r"output")
        MATTI = component.joinpath("matti_testcases")
        SISFILES = component.joinpath(r"sisfiles")
        
        if not filepath.parent.exists():
            filepath.parent.makedirs()
        filepath.touch()
        
        #mtc => matti_testcases
        mtc = component.joinpath("matti_testcases")
        mtc.joinpath("unit_test1.rb").write_text("unit_tests")
        mtc.joinpath("unit_test2.rb").write_text("unit_tests")
    
        # profiles
        profiles = component.joinpath("matti_testcases", "profile")
        profiles.joinpath("all.sip").write_text("sip profile")
        profiles.joinpath("bat.sip").write_text("sip profile")
        profiles.joinpath("fute.sip").write_text("sip profile")
        
        #hwdata => hardware data
        profiles = component.joinpath("matti_testcases", "hwdata")
        profiles.joinpath("file1.txt").write_text("data file")
        profiles.joinpath("settings.ini").write_text("settings initialization file")
        profiles.joinpath("paths.pkg").write_text(
            r"""
            ;Language - standard language definitions
            &EN
            
            ; standard SIS file header
            #{"BTEngTestApp"},(0x04DA27D5),1,0,0
            
            ;Supports Series 60 v 3.0
            (0x101F7961), 0, 0, 0, {"Series60ProductID"}
            
            ;Localized Vendor Name
            %{"BTEngTestApp"}
            
            ;Unique Vendor name
            :"Nokia"
            
            ; Files to copy
    
            "[PKG_LOC]\file1.txt"-"C:\Private\10202BE9\PERSISTS\file1.txt"
            "[PKG_LOC]\settings.ini"-"c:\sys\settings.ini"
            """.replace('\\', os.sep))


def teardown_module(test_run_count):
    """ stuff to do after running the tests """

    if test_run_count == 0:
        path(TEST_PATH).rmtree()  

class TestMattiTestPlan(SetUp):
    """ test MattiDrop.py """
    global OUTPUT, MATTI, SISFILES

    def __init__(self):
        """initialize Matti Tests"""
        SetUp.__init__(self)
        self.file_store = OUTPUT
        self.test_asset_path = MATTI
        self.matti_sis_files = r"%s/abc.sis#f:\data\abc.sis#c:\abc.sis, %s/xyz.sis#f:\data\abc.sis#f:\xyz.sis" % (SISFILES, SISFILES)
        self.build_drive = "j:"
        self.drop_file = path(r"%s/ats/ATSMattiDrop.zip" %OUTPUT).normpath()

        image_files = r"%s/images/image1.fpsx, %s/images/image2.fpsx " % (OUTPUT, OUTPUT)
        self.flash_images = image_files 

        self.template_loc = os.path.join(os.environ['TEST_DATA'], 'data/matti/matti_template.xml')
        self.template_loc = os.path.normpath(self.template_loc)
        self.matti_parameters = ""
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

    def test_xml_with_all_parameters(self):
        """ test Matti2.py with all parameters present and correct and sierra is enabled"""
        global TOTAL_TESTS_COUNT
        opts = Bunch(build_drive=self.build_drive,
                     drop_file=path(r"%s/ats/ATSMattiDrop1.zip" %OUTPUT).normpath(),
                     flash_images=self.flash_images,
                     matti_sis_files=self.matti_sis_files,
                     testasset_location=self.test_asset_path,
                     template_loc=self.template_loc,
                     sierra_enabled="True",
                     test_profiles="bat, fute",
                     matti_parameters="",
                     matti_timeout="1200",
                     sierra_parameters="--teardown",
                     file_store=self.file_store,
                     report_email="firstname.lastname@domain.com",
                     testrun_name="matti test run",
                     alias_name="alias",
                     device_type="new_device",
                     diamonds_build_url="http://diamonds.com/1234",
                     email_format="simplelogger",
                     email_subject="Matti test report",
                     verbode="false")

        self.config = ats3.matti2.Configuration(opts)
        ats3.matti2.create_drop(self.config)

        xml_loc = os.path.join(os.environ['TEST_DATA'], 'data/matti/test_all_present.xml')
        stored_xml = self.read_xml(xml_loc, False).strip()
        drop_loc = os.path.join(OUTPUT, 'ats/ATSMattiDrop1.zip')
        generated_xml = self.read_xml(drop_loc, True).strip()

        if platform.system().lower() == "linux":
            assert stored_xml.replace('\r', '') in generated_xml
        else:
            assert stored_xml in generated_xml
            
        TOTAL_TESTS_COUNT -= 1
        teardown_module(TOTAL_TESTS_COUNT)

    def test_xml_if_sierra_is_not_enabled(self):
        """ test Matti2.py with all parameters present and correct and sierra is not enabled (or false)"""
        global TOTAL_TESTS_COUNT
        opts = Bunch(build_drive=self.build_drive,
                     drop_file=path(r"%s/ats/ATSMattiDrop2.zip" %OUTPUT).normpath(),
                     flash_images=self.flash_images,
                     matti_sis_files=self.matti_sis_files,
                     testasset_location=self.test_asset_path,
                     template_loc=self.template_loc,
                     sierra_enabled="False",
                     test_profiles="bat, fute",
                     matti_parameters="",
                     matti_timeout="1200",
                     sierra_parameters="--teardown",
                     file_store=self.file_store,
                     report_email="firstname.lastname@domain.com",
                     testrun_name="matti test run",
                     alias_name="alias",
                     device_type="new_device",
                     diamonds_build_url="http://diamonds.com/1234",
                     email_format="simplelogger",
                     email_subject="Matti test report",
                     verbode="false")

        self.config = ats3.matti2.Configuration(opts)
        ats3.matti2.create_drop(self.config)

        xml_loc = os.path.join(os.environ['TEST_DATA'], 'data/matti/test_all_present_sierra_disabled.xml')
        stored_xml = self.read_xml(xml_loc, False).strip()
        drop_loc = os.path.join(OUTPUT, 'ats/ATSMattiDrop2.zip')
        generated_xml = self.read_xml(drop_loc, True).strip()

        if platform.system().lower() == "linux":
            assert stored_xml.replace('\r', '') in generated_xml
        else:
            assert stored_xml in generated_xml
        
        TOTAL_TESTS_COUNT -= 1
        teardown_module(TOTAL_TESTS_COUNT)

    def test_xml_if_sierra_is_enabled_template_location_is_missing(self):
        """ test Matti2.py with all parameters present and correct and if sierra is enabled but template location is used as default one"""
        global TOTAL_TESTS_COUNT
        opts = Bunch(build_drive=self.build_drive,
                     drop_file=path(r"%s/ats/ATSMattiDrop3.zip" %OUTPUT).normpath(),
                     flash_images=self.flash_images,
                     matti_sis_files=self.matti_sis_files,
                     testasset_location=self.test_asset_path,
                     template_loc="",
                     sierra_enabled="True",
                     test_profiles="bat, fute",
                     matti_parameters="",
                     matti_timeout="1200",
                     sierra_parameters="--teardown",
                     file_store=self.file_store,
                     report_email="firstname.lastname@domain.com",
                     testrun_name="matti test run",
                     alias_name="alias",
                     device_type="new_device",
                     diamonds_build_url="http://diamonds.com/1234",
                     email_format="simplelogger",
                     email_subject="Matti test report",
                     verbode="false")
        
        self.config = ats3.matti2.Configuration(opts)
        ats3.matti2.create_drop(self.config)

        xml_loc = os.path.join(os.environ['TEST_DATA'], 'data/matti/test_all_present.xml')
        stored_xml = self.read_xml(xml_loc, False).strip()
        drop_loc = os.path.join(OUTPUT, 'ats/ATSMattiDrop3.zip')
        generated_xml = self.read_xml(drop_loc, True).strip()

        if platform.system().lower() == "linux":
            assert stored_xml.replace('\r', '') in generated_xml
        else:
            assert stored_xml in generated_xml
        
        TOTAL_TESTS_COUNT -= 1
        teardown_module(TOTAL_TESTS_COUNT)        
        
        
        
        
        