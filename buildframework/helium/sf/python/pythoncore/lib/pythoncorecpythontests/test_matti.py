# -*- coding: latin-1 -*-

#============================================================================ 
#Name        : test_matti.py 
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

# pylint: disable-msg=E1101

import logging
logging.getLogger().setLevel(logging.ERROR)
import os
#import shutil
from path import path
import ats3.aste
import ats3.matti.MattiDrops
#from lxml import objectify
#from lxml import etree
import tempfile

TEST_FILE_NAME = 'test.xml'
ZIP_FILE_NAME = os.path.join(tempfile.mkdtemp(), 'MATTIDrop.zip')

class Bunch(object):
    """do something with the paramerters passed to it"""    
    def __init__(self, **kwargs): 
        self.__dict__.update(kwargs)
    

def equal_xml(result, expect):
    """Check the equality of the given XML snippets. """
#    logging.info(" expect %s" % expect)
#    xml1 = objectify.fromstring(expect)
#    expect1 = etree.tostring(xml1)
#    logging.info(" expect1 %s" % expect1)
#    logging.info(" expect2 -------------%s" % expect2)
#            
#    xml2 = objectify.fromstring(result)
#    result2 = etree.tostring(xml2)        
#    self.assertEquals(expect1, result1)
#
#    if xml1.tag != xml2.tag:
#        return False
#    if xml1.attrib != xml2.attrib:
#        return False
#    if xml1.text:
#        if not xml2.text:
#            return False
#    if xml2.text:
#        if not xml1.text:
#            return False
#    if xml1.text and xml2.text and xml1.text.strip() != xml2.text.strip():
#        return False
#    if xml1.tail is not None and xml2.tail is not None:
#        if xml1.tail.strip() != xml2.tail.strip():
#            return False
#    elif xml1.tail != xml2.tail:
#        return False
#    children1 = list(xml1.getchildren())
#    children2 = list(xml2.getchildren())
#    if len(children1) != len(children2):
#        return False
#    for child1, child2 in zip(children1, children2):
#        return equal_xml(child1, child2)
#    return True
    if expect:
        return result   


def setup_module():
    """ stuff to do before running the tests """
    pass    
    
def teardown_module():
    """ stuff to do after running the tests """
    if os.path.exists(TEST_FILE_NAME):
        os.remove(TEST_FILE_NAME)
    if os.path.exists(ZIP_FILE_NAME):
        os.remove(ZIP_FILE_NAME)
    
    
class TestPlanMatti():
    """ test MattiDrop.py """
    def __init__(self): 
        self.config = None
        self.tp_result = None
        
        (_, self.image1) = tempfile.mkstemp()
        (_, self.image2) = tempfile.mkstemp()
        (_, self.image3) = tempfile.mkstemp()
        (_, self.sis1) = tempfile.mkstemp()
        (_, self.sis2) = tempfile.mkstemp()
            
    def test_all_present(self):
        """ test mattiDrops.py with all parameters present and correct"""
        teardown_module()
        opts = Bunch(build_drive="z:", 
             matti_scripts=os.path.join(os.environ['TEST_DATA'], 'data/matti'),
             flash_images = '%s,%s,%s' % (self.image1, self.image2, self.image3),
             report_email="", harness="STIF", 
             file_store=path(), testrun_name="testrun",  
             device_type="product", device_hwid="5425", diamonds_build_url="", drop_file=ZIP_FILE_NAME, 
             minimum_flash_images="2", plan_name="matti_test_plan", 
             sis_files = '%s,%s' % (self.sis1, self.sis2),
             template_loc=os.path.join(os.path.dirname(__file__), '../ats3/matti/template/matti_demo.xml'), 
             test_timeout="60", verbose="false")
       
        self.config = ats3.matti.MattiDrops.Configuration(opts)
        self.tp_result = ats3.matti.MattiDrops.create_drop(self.config)
        assert os.path.exists(ZIP_FILE_NAME)
        assert os.path.exists(TEST_FILE_NAME)
        #shutil.copy(TEST_FILE_NAME, os.path.join(TMPDIR, 'test_all_present.xml'))
        #equal_xml(TEST_FILE_NAME, os.path.join(TMPDIR, 'test_all_present.xml'))
        
    def test_no_sis_or_flash_files(self):
        """test mattiDrops.py with no sis or flash files in the parameters"""
        teardown_module()
        opts = Bunch(build_drive="z:", 
             matti_scripts=os.path.join(os.environ['TEST_DATA'], 'data/matti'),
             flash_images = "",
             report_email="", harness="STIF", 
             file_store=path(), testrun_name="testrun",  
             device_type="product", device_hwid="5425", diamonds_build_url="", drop_file=ZIP_FILE_NAME, 
             minimum_flash_images="2", plan_name="matti_test_plan", 
             sis_files= "", 
             template_loc=os.path.join(os.path.dirname(__file__), '../ats3/matti/template/matti_demo.xml'), 
             test_timeout="60", verbose="true")
       
        self.config = ats3.matti.MattiDrops.Configuration(opts)
        self.tp_result = ats3.matti.MattiDrops.create_drop(self.config)
        assert os.path.exists(ZIP_FILE_NAME)
        assert os.path.exists(TEST_FILE_NAME)
        #shutil.copy(TEST_FILE_NAME, os.path.join(TMPDIR, 'test_no_sis_or_flash.xml'))
        #equal_xml(TEST_FILE_NAME, os.path.join(TMPDIR, 'test_no_sis_or_flash.xml'))


    def test_no_files(self):
        """ test mattiDtops.py with no filespresent at all"""
        teardown_module()
        opts = Bunch(build_drive="z:", 
             matti_scripts=tempfile.mkdtemp(), 
             flash_images = "",
             report_email="", harness="STIF", 
             file_store=path(), testrun_name="testrun",  
             device_type="product", device_hwid="5425", diamonds_build_url="", drop_file=ZIP_FILE_NAME, 
             minimum_flash_images="2", plan_name="matti_test_plan", 
             sis_files= "", 
             template_loc=os.path.join(os.path.dirname(__file__), '../ats3/matti/template/matti_demo.xml'), 
             test_timeout="60", verbose="true")
        self.config = ats3.matti.MattiDrops.Configuration(opts)
        self.tp_result = ats3.matti.MattiDrops.create_drop(self.config)
        assert not os.path.exists(ZIP_FILE_NAME)
        assert os.path.exists(TEST_FILE_NAME)
        #shutil.copy(TEST_FILE_NAME, os.path.join(TMPDIR, 'test_no_files.xml'))
        #equal_xml(TEST_FILE_NAME, os.path.join(TMPDIR, 'test_no_files.xml'))

    def test_no_params(self):
        """test MattiDrops.py with no parameters present at all"""
        teardown_module()
        opts = Bunch(build_drive="", 
             matti_scripts="", 
             flash_images = "",
             report_email="", harness="", 
             file_store="", testrun_name="",  
             device_type="", device_hwid="", diamonds_build_url="", drop_file="", 
             minimum_flash_images="", plan_name="", 
             sis_files= "", 
             template_loc="", 
             test_timeout="", verbose="true")
       
        self.config = ats3.matti.MattiDrops.Configuration(opts)
        self.tp_result = ats3.matti.MattiDrops.create_drop(self.config)
        assert not os.path.exists(ZIP_FILE_NAME)
        assert not os.path.exists(TEST_FILE_NAME)

    def test_some_not_present(self):
        """ test MattiDrops.py with an extra file not present in the dir"""
        teardown_module()
        opts = Bunch(build_drive="z:", 
             matti_scripts=os.path.join(os.environ['TEST_DATA'], 'data/matti'),
             flash_images = '%s,%s,%s' % (self.image1, self.image2, self.image3),
             report_email="", harness="STIF", 
             file_store=path(), testrun_name="testrun",  
             device_type="product", device_hwid="5425", diamonds_build_url="", drop_file=ZIP_FILE_NAME, 
             minimum_flash_images="2", plan_name="matti_test_plan", 
             sis_files = '%s,%s' % (self.sis1, self.sis2),
             template_loc=os.path.join(os.path.dirname(__file__), '../ats3/matti/template/matti_demo.xml'), 
             test_timeout="60", verbose="false")
       
        self.config = ats3.matti.MattiDrops.Configuration(opts)
        self.tp_result = ats3.matti.MattiDrops.create_drop(self.config)
        assert os.path.exists(ZIP_FILE_NAME)
        assert os.path.exists(TEST_FILE_NAME)
        #shutil.copy(TEST_FILE_NAME, os.path.join(TMPDIR, 'test_some_not_present.xml'))
        #equal_xml(TEST_FILE_NAME, os.path.join(TMPDIR, 'test_some_not_present.xml'))
