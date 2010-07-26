# -*- coding: latin-1 -*-

#============================================================================ 
#Name        : test_ats3_aste.py 
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

""" Testing ATS3 ASTE framework. """

# pylint: disable-msg=W0603,W0142,R0903,R0911,R0912,R0902,R0901,R0201
# pylint: disable-msg=E1101
#E1101 => Mocker shows mockery
#R* remove during refactoring

from cStringIO import StringIO
from xml.etree.ElementTree import fromstring
from xml.etree import ElementTree as et
import difflib
import logging
logging.getLogger().setLevel(logging.ERROR)
import re
import tempfile
import zipfile
import os

from path import path # pylint: disable-msg=F0401
import mocker # pylint: disable-msg=F0401

import ats3.aste

TEST_PATH = None
TEST_FILES = {}
TEST_ASSET_FILES = {}
TSRC = None
OUTPUT = None
TEST_ZIP_PATH = None

# Shortcuts
E = et.Element
SE = et.SubElement

_logger = logging.getLogger("test_ast3_aste")

class Bunch(object):
    """ handle the whole group of parameters input """
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)
    

def equal_xml(xml1, xml2):
    """Check the equality of the given XML snippets.
    
    Tag name equality:
    
    >>> equal_xml('<a/>', '<a/>')
    True
    >>> equal_xml('<a/>', '<b/>')
    False
    
    Attribute equality:
    
    >>> equal_xml('<a k="v"/>', '<a k="v"/>')
    True
    >>> equal_xml('<a k="v"/>', '<a k="w"/>')
    False
    
    Text content equality:
    
    >>> equal_xml('<a>v</a>', '<a>v</a>')
    True
    >>> equal_xml('<a>v</a>', '<a>w</a>')
    False
    >>> equal_xml('<a>v</a>', '<a></a>')
    False
    
    Text content equality when whitespace differs:
    >>> equal_xml('<a>v</a>', '<a>v </a>')
    True

    Equality of child elements:
    
    >>> equal_xml('<a><b><c k="v"/></b></a>', '<a><b><c k="v"/></b></a>')
    True
    >>> equal_xml('<a><b><c k="v"/></b></a>', '<a><b><c k="w"/></b></a>')
    False
    >>> equal_xml('<a><b><c k="v"/>v</b></a>', '<a><b><c k="v"/>w</b></a>')
    False
    >>> equal_xml('<a><b><c k="v"/>v</b></a>', '<a><b><c k="v"/>v </b></a>')
    True
    
    """
    if isinstance(xml1, basestring):
        xml1 = fromstring(xml1)
    if isinstance(xml2, basestring):
        xml2 = fromstring(xml2)
    if xml1.tag != xml2.tag:
        return False
    if xml1.attrib != xml2.attrib:
        return False
    if xml1.text:
        if not xml2.text:
            return False
    if xml2.text:
        if not xml1.text:
            return False
    if xml1.text and xml2.text and xml1.text.strip() != xml2.text.strip():
        return False
    if xml1.tail is not None and xml2.tail is not None:
        if xml1.tail.strip() != xml2.tail.strip():
            return False
    elif xml1.tail != xml2.tail:
        return False
    children1 = list(xml1.getchildren())
    children2 = list(xml2.getchildren())
    if len(children1) != len(children2):
        return False
    for child1, child2 in zip(children1, children2):
        return equal_xml(child1, child2)
    return True        


def setup_module():
    """ setup any variables needed for the tests """
    global TEST_PATH, OUTPUT, TEST_ZIP_PATH
    TEST_PATH = path(tempfile.mkdtemp())
    OUTPUT = TEST_PATH.joinpath("TestAsset")
    TEST_ZIP_PATH = TEST_PATH.joinpath("test_zip")
    asset = TEST_PATH
    component = TEST_PATH
    component.joinpath("group").makedirs()
    for path_parts in (("output", "images", "file1.fpsx"),
                       ("output", "images", "file2.fpsx")):
        filename = component.joinpath(*path_parts)
        if not filename.parent.exists():
            filename.parent.makedirs()
        filename.touch()
        TEST_FILES.setdefault(path_parts[1], []).append(file)
    for path_parts in (("TestAsset", "Localisation", "S60", "localisation.txt"),
                       ("TestAsset", "TestCases", "TC_100_Test0", "file1.sis"),
                       ("TestAsset", "TestCases", "TC_100_Test0", "file2.tcf"),
                       ("TestAsset", "Tools", "TestCaseCreator", "test_creator.ini"),
                       ("TestAsset", "testdrop.xml"),):
        filename = asset.joinpath(*path_parts)
        if not filename.parent.exists():
            filename.parent.makedirs()
        filename.touch()
        TEST_ASSET_FILES.setdefault(path_parts[1], []).append(file)
    try:
        zip_component = TEST_ZIP_PATH
        filename = zip_component.joinpath("TestAsset.zip")
        if not filename.parent.exists():
            filename.parent.makedirs()
        filename.touch()
        zfile = zipfile.ZipFile(zip_component.joinpath("TestAsset.zip"), "w", zipfile.ZIP_DEFLATED)
        for p_temp in TEST_ASSET_FILES:
            print p_temp
            zfile.write(p_temp)
        zfile.close()
        TEST_ASSET_FILES.setdefault("ZIP", []).append(file)
    except OSError:
        print "Got except OSError. Continuing...\n"  
        
    
def teardown_module():
    """clean up after the tests are all run"""
    path(TEST_PATH).rmtree()
    
    
class TestTestPlan(mocker.MockerTestCase):
    """ the tests """
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
             
    def setUp(self):
        """ setup the data """
        opts = Bunch(testrun_name="testrun", harness="ASTE", 
                     device_type="product", plan_name="ats3_test_plan", diamonds_build_url="",
                     software_version="W810", software_release="SPP 51.32", device_language="English",
                     testasset_location=TEST_PATH.joinpath("TestAsset"), testasset_caseids="100",repeat="1", report_email="",
                     file_store=path(), test_timeout="60", device_hwid="5425", test_type="smoke")
        self.tp_temp = ats3.aste.AsteTestPlan(opts)
        self.image_files = TEST_FILES["images"]
        self.test_timeout = self.tp_temp["test_timeout"]
        self.device_hwid = self.tp_temp["device_hwid"]
        self.test_harness = self.tp_temp["harness"]
        self.device_language = self.tp_temp["device_language"]
        self.software_release = self.tp_temp["software_release"]
        self.software_version = self.tp_temp["software_version"]
        self.testasset_caseids = self.tp_temp["testasset_caseids"]
        self.testasset_location = self.tp_temp["testasset_location"]
        self.test_type = self.tp_temp["test_type"]
        
        if self.testasset_location != "":
            self.test_asset_testcases = [self.testasset_location.joinpath("TestCases", "TC_100_Test0", "file1.sis"), self.testasset_location.joinpath("TestCases", "TC_100_Test0", "file2.tcf")]
            self.test_asset_tools = [self.testasset_location.joinpath("Tools", "TestCaseCreator", "test_creator.ini")]
            self.test_asset_localisation = [self.testasset_location.joinpath("Localisation", "S60", "localisation.txt")]
            self.test_asset_testdrop = self.testasset_location.joinpath("testdrop.xml")
        else:
            self.test_asset_testcases = TEST_ASSET_FILES["TestCases"]
            self.test_asset_tools = TEST_ASSET_FILES["Tools"]
            self.test_asset_localisation = TEST_ASSET_FILES["Localisation"]
            self.test_asset_testdrop = TEST_ASSET_FILES["testdrop.xml"]

            
    def test_creation(self):
        """create the tests"""
        assert self.tp_temp["testrun_name"] == "testrun"
        assert self.tp_temp["harness"] == "ASTE"
        assert self.tp_temp["device_type"] == "product"
    
    def test_insert_set(self):
        """test insert set"""
        self.tp_temp.insert_set(image_files=self.image_files,
                           test_timeout=self.test_timeout)
        
        assert self.tp_temp.sets[0] == dict(name="set0",
                                       image_files=self.image_files,
                                       test_timeout=self.test_timeout,
                                       test_harness=self.test_harness)

    def test_post_actions_email(self):
        """ check email sent after tests"""
        assert not self.tp_temp.post_actions
        receiver = "joe.average@example.com"
        self.tp_temp.report_email = receiver
        assert len(self.tp_temp.post_actions) == 1
        action, items = self.tp_temp.post_actions[0]
        items = dict(items)
        assert action == "SendEmailAction"
        assert items["to"] == receiver
    
    def test_post_actions_ats3_report_only(self):
        """ test only createing report"""
        file_store = path("path/to/files")
        self.tp_temp.file_store = file_store
        self.tp_temp.harness = "EUNIT"
        assert len(self.tp_temp.post_actions) == 2
        action, items = self.tp_temp.post_actions[0]
        items = dict(items)
        assert action == "FileStoreAction"
        assert items["report-type"] == "ATS_REPORT"
        assert items["to-folder"].startswith(file_store)
        assert items["to-folder"].endswith("ATS3_REPORT")
    
    def test_post_actions_aste(self):
        """ test actions performed after aste test"""
        file_store = path("path/to/files")
        self.tp_temp.file_store = file_store
        assert len(self.tp_temp.post_actions) == 2
        action, items = self.tp_temp.post_actions[1]
        items = dict(items)
        assert action == "FileStoreAction"
        assert items["report-type"] == "ASTE_REPORT"
        assert items["to-folder"].startswith(file_store)
        assert items["to-folder"].endswith("ASTE_REPORT")
        
    def test_post_actions_diamonds(self):
        """test diamonds is posted to after the test"""
        self.tp_temp.diamonds_build_url = "http://diamonds.nmp.company.com/diamonds/builds/1234"
        assert len(self.tp_temp.post_actions) == 1
        action, items = self.tp_temp.post_actions[0]
        assert action == "DiamondsAction"
        assert not items


            
class TestXMLGeneration(mocker.MockerTestCase):
    """
    Unit tests for the test.xml generation.
    """    

    def __init__(self, methodName="runTest"):
        self.image_files = None
        self.report_email = None
        self.diamonds_build_url = None
        self.test_harness = None
        self.file_store = None
        self.testasset_location = None
        self.test_plan = None
        self.gen = None
        mocker.MockerTestCase.__init__(self, methodName)
        
        
    def generate_xml(self):
        """create the XML"""
        def files(*paths):
            """get a list of files held in the temp path"""
            return [TEST_PATH.joinpath(p) for p in paths]
        self.image_files = files("output/images/file1.fpsx", "output/images/file2.fpsx")
        self.report_email = "test.receiver@company.com"
        self.diamonds_build_url = "http://diamonds.nmp.company.com/diamonds/builds/1234"
        self.test_harness = "ASTE"
        self.file_store = path(r"path/to/reports")
        self.testasset_location = OUTPUT
        
        self.mocker.restore()
        test_plan = self.mocker.mock(count=False)
        mocker.expect(test_plan["testrun_name"]).result("test")
        mocker.expect(test_plan["harness"]).result("ASTE")
        mocker.expect(test_plan["device_type"]).result("product")
        mocker.expect(test_plan["plan_name"]).result("test plan")
        mocker.expect(test_plan["diamonds_build_url"]).result(self.diamonds_build_url)
        mocker.expect(test_plan["test_timeout"]).result("60")
        mocker.expect(test_plan["device_hwid"]).result("5425")
        mocker.expect(test_plan["testasset_location"]).result(self.testasset_location)
        mocker.expect(test_plan["testasset_caseids"]).result("100")
        mocker.expect(test_plan["software_release"]).result("SPP 51.32")
        mocker.expect(test_plan["software_version"]).result("W810")
        mocker.expect(test_plan["device_language"]).result("English")
        mocker.expect(test_plan["test_type"]).result("smoke")
        mocker.expect(test_plan["temp_directory"]).result(TEST_PATH)
        mocker.expect(test_plan.sets).result([
            dict(name="set0", image_files=self.image_files, test_harness="ASTE")])
        mocker.expect(test_plan.post_actions).result([
            ("SendEmailAction", (("subject", "email subject"),
                                 ("type", "ATS3_REPORT"),
                                 ("send-files", "true"),
                                 ("to", self.report_email))),
            ("FileStoreAction", (("to-folder", self.file_store),
                                 ("report-type", "ATS_REPORT"),
                                 ("date-format", "yyyyMMdd"),
                                 ("time-format", "HHmmss"))),
            ("FileStoreAction", (("to-folder", self.file_store),
                                 ("report-type", "ASTE_REPORT"),
                                 ("run-log", "true"),
                                 ("date-format", "yyyyMMdd"),
                                 ("time-format", "HHmmss"))),
            ("DiamondsAction", ())
        ])
        
        self.mocker.replay()
        self.test_plan = test_plan
        
        self.gen = ats3.aste.AsteTestDropGenerator()
        return self.gen.generate_xml(test_plan)

    def test_basic_structure(self):
        """Check that the overall test.xml structure is valid."""
        xml = self.generate_xml()
        # Check basics.
        assert xml.find(".").tag == "test"
        assert xml.find("./name").text == "test"
        assert xml.find("./buildid").text == self.diamonds_build_url
        assert xml.find("./target").tag
        assert xml.find("./target/device").tag
        harness, hardware, device_hwid = xml.findall("./target/device/property")
        softwareVersion, softwareRelease, deviceLanguage = xml.findall("./target/device/setting")
        assert harness.get("value") == "ASTE"
        assert hardware.get("value") == "product"
        assert softwareVersion.get("value") == "W810"
        assert softwareRelease.get("value") == "SPP 51.32"
        assert deviceLanguage.get("value") == "English"
        assert device_hwid.get("value") == "5425"
        
        # Check generation of the test plan.
        assert xml.find("./plan").get("name") == "Plan smoke product"
        assert xml.find("./plan/session").tag 
        sets = xml.findall("./plan/session/set")
        assert len(sets) == 1
        assert sets[0].get("name") == "set0"
        assert sets[0].find("./target/device").tag
    
    def test_set_structure(self):
        """Check that a <set> element's structure is valid."""
        xml = self.generate_xml()
        tstset = xml.find("./plan/session/set")
        assert tstset.tag
        case = tstset.find("./case")
        assert case.tag
        assert case.get("name") == "set0 case"
        
    def test_case_flash_elems(self):
        """ test the flash files all added to case"""
        xml = self.generate_xml()
        case = xml.find("./plan/session/set/case")
        flashes = case.findall("./flash")
        assert len(flashes) == len(self.image_files)
        for i, flash_file in enumerate(self.image_files):
            assert flashes[i].get("target-alias") == "DEFAULT"
            assert flashes[i].get("images") == path(r"ATS3Drop" + os.sep + "images") / flash_file.name
    
    def test_steps(self):
        """ test the steps are executed as steps"""
        xml = self.generate_xml()
        steps = iter(xml.findall("./plan/session/set/case/step"))
        self.check_executeasset_step(steps)

    def check_executeasset_step(self, steps):
        """ perform the check"""
        step = steps.next()
        assert step.get("name") == "Execute asset zip step"
        assert step.findtext("./command") == "execute-asset"
        params = step.findall("./params/param")
        assert params[0].get("repeat") == "1"
        assert params[1].get("asset-source") == "ATS3Drop" + os.sep + "TestAssets" + os.sep + "TestAsset.zip"
        assert params[2].get("testcase-ids") == "100"

    def test_post_actions(self):
        """Post actions are inserted into XML."""
        xml = self.generate_xml()        
        post_actions = xml.findall("./postAction")
        self.check_send_email_action(post_actions[0])
        self.check_ats_report_action(post_actions[1])
        self.check_aste_report_action(post_actions[2])
        self.check_diamonds_action(post_actions[3])

    def check_send_email_action(self, action):
        """check the email is sent """
        assert action.findtext("./type") == "SendEmailAction"
        params = action.findall("./params/param")
        assert params[0].get("name") == "subject"
        assert params[0].get("value") == "email subject"
        assert params[1].get("name") == "type"
        assert params[1].get("value") == "ATS3_REPORT"
        assert params[2].get("name") == "send-files"
        assert params[2].get("value") == "true"
        assert params[3].get("name") == "to"
        assert params[3].get("value") == self.report_email

    def check_ats_report_action(self, action):
        """check the ats report is correct"""
        assert action.findtext("./type") == "FileStoreAction"
        params = action.findall("./params/param")
        assert params[0].get("name") == "to-folder"
        assert params[0].get("value") == self.file_store
        assert params[1].get("name") == "report-type"
        assert params[1].get("value") == "ATS_REPORT"
        assert params[2].get("name") == "date-format"
        assert params[2].get("value") == "yyyyMMdd"
        assert params[3].get("name") == "time-format"
        assert params[3].get("value") == "HHmmss"

    def check_aste_report_action(self, action):
        """ check the aste report is corect"""
        assert action.findtext("./type") == "FileStoreAction"
        params = action.findall("./params/param")
        assert params[0].get("name") == "to-folder"
        assert params[0].get("value") == self.file_store
        assert params[1].get("name") == "report-type"
        assert params[1].get("value") == "ASTE_REPORT"
        assert params[2].get("name") == "run-log"
        assert params[2].get("value") == "true"
        assert params[3].get("name") == "date-format"
        assert params[3].get("value") == "yyyyMMdd"
        assert params[4].get("name") == "time-format"
        assert params[4].get("value") == "HHmmss"
        
    def check_diamonds_action(self, action):
        """ check diamonds actions are correct"""
        assert action.findtext("./type") == "DiamondsAction"
        assert not action.findall("./params/param")
    
    def test_files(self):
        """ test the files are added to the drop """
        xml = self.generate_xml()
        files = iter(xml.findall("./files/file"))
        assert files.next().text == r"ATS3Drop" + os.sep + "images" + os.sep + "file1.fpsx"
        assert files.next().text == r"ATS3Drop" + os.sep + "images" + os.sep + "file2.fpsx"
        assert files.next().text == r"ATS3Drop" + os.sep + "TestAssets" + os.sep + "TestAsset.zip"
        self.assertRaises(StopIteration, files.next)
        
    def test_generate_testasset_zip(self):
        """ test the generated test asset is zipped"""
        self.generate_xml()
        if re.search(r"[.]zip", self.test_plan["testasset_location"]):
            pass
        else:
            strbuffer = StringIO()
            assert strbuffer == self.gen.generate_testasset_zip(self.test_plan, strbuffer)
            zfile = zipfile.ZipFile(strbuffer, "r")
            try:
                contents = sorted(path(p).normpath() for p in zfile.namelist())
                expected = sorted(path(p).normpath()
                               for p in [(r"Localisation" + os.sep + "S60" + os.sep + "localisation.txt"),
                                         (r"TestCases" + os.sep + "TC_100_Test0" + os.sep + "file1.sis"),
                                         (r"TestCases" + os.sep + "TC_100_Test0" + os.sep + "file2.tcf"),
                                         (r"Tools" + os.sep + "TestCaseCreator" + os.sep + "test_creator.ini"),
                                         (r"testdrop.xml")])
                diff = difflib.context_diff(expected, contents)
                assert contents == expected, "\n".join(diff)
            finally:
                zfile.close()
        
    def test_generate_drop(self):
        """Manifest for ATS3Drop directory structure is generated."""
        xml = self.generate_xml()
        strbuffer = StringIO()

        self.gen.generate_drop(self.test_plan, xml, strbuffer)
        zfile = zipfile.ZipFile(strbuffer, "r")
        try:
            contents = sorted(path(p).normpath() for p in zfile.namelist())
            expected = sorted(path(p).normpath()
                           for p in [r"ATS3Drop" + os.sep + "images" + os.sep + "file1.fpsx",
                                     r"ATS3Drop" + os.sep + "images" + os.sep + "file2.fpsx",
                                     r"ATS3Drop" + os.sep + "TestAssets" + os.sep + "TestAsset.zip",
                                     r"test.xml"])
            diff = difflib.context_diff(expected, contents)
            assert contents == expected, "\n".join(diff)
        finally:
            zfile.close()
