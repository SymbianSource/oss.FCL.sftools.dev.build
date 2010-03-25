# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : test_ats4.py 
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

""" Testing ats4 framework. """
# pylint: disable-msg=E1101, C0302, W0142, W0603, R0902,R0903,R0912,R0915
#E1101 => Mocker shows mockery
#C0302 => too many lines
#W0142 => used * or ** magic 
#W0603 => used global
#R* during refactoring

from cStringIO import StringIO
from xml.etree.ElementTree import fromstring
from xml.etree import ElementTree as et
import difflib
import logging
logging.getLogger().setLevel(logging.ERROR)
import tempfile
import zipfile
import os
import re
import subprocess

from path import path # pylint: disable-msg=F0401
import amara
import mocker # pylint: disable-msg=F0401

import ntpath

import ats3
import ats3.testconfigurator as atc
import ats3.dropgenerator as adg
import ats3.parsers as parser


TEST_PATH = None
TEST_FILES = {}
TSRC = None
OUTPUT = None

# Shortcuts
E = et.Element
SE = et.SubElement

class Bunch(object):
    """ Configuration object. Argument from constructor are converted into class attributes. """
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
    def __init__():
        check_instance(xml1, xml2)
    
    def check_instance(xml1, xml2):
        """if xml1 and xml2 are instances, converts to strings"""
        if isinstance(xml1, basestring):
            xml1 = fromstring(xml1)
        if isinstance(xml2, basestring):
            xml2 = fromstring(xml2)
        check_tags(xml1, xml2)

    def check_tags(xml1, xml2):
        """check xml tags and text equality"""
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

        produce_xml_children(xml1, xml2)

    def produce_xml_children(xml1, xml2):
        """checks if xml children are of same length and are equal?"""
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
    """ Setup test environment. """
    global TEST_PATH, TSRC, OUTPUT
    TEST_PATH = path(tempfile.mkdtemp())
    OUTPUT = TEST_PATH.joinpath(r"output")
    component = TEST_PATH
    component.joinpath("group").makedirs()
    for path_parts in (("tsrc", "group", "bld.inf"),
                       ("tsrc", "group", "test.pkg"),
                       ("tsrc", "testmodules", "file1.dll"),
                       ("tsrc", "testmodules", "file2.dll"),
                       ("tsrc", "data", "file1"),
                       ("tsrc", "data", "file2"),
                       ("tsrc", "data", "file3"),
                       ("tsrc", "data", "mmc", "file4"),
                       ("tsrc", "data", "c", "file5"),
                       ("tsrc", "conf", "file1.cfg"),
                       ("tsrc", "conf", "file2.cfg"),
                       ("tsrc", "init", "TestFramework.ini"),
                       ("tsrc", "custom", "prepostaction.xml"),
                       ("tsrc", "custom", "postpostaction.xml"),
                       # These do not have to be under 'tsrc':
                       ("tsrc", "output", "images", "file1.fpsx"),
                       ("tsrc", "output", "images", "file2.fpsx"),
                       ("tsrc", "sis", "file1.sisx"),
                       ("tsrc", "sis", "file2.sisx"),
                       ("tsrc", "sis", "file3.sisx"),
                       ("tsrc", "trace_init", "trace_activation_1.xml")):
        filepath = component.joinpath(*path_parts)
        if not filepath.parent.exists():
            filepath.parent.makedirs()
        filepath.touch()
        TEST_FILES.setdefault(path_parts[1], []).append(filepath)
    TSRC = component.joinpath("tsrc")
    filepath = OUTPUT.joinpath("pmd", "pmd_file.pmd")
    if not filepath.parent.exists():
        filepath.parent.makedirs()
    filepath.touch()
    TEST_FILES.setdefault("pmd_file", []).append(filepath)
    tracing = component.joinpath("tsrc", "trace_init")
    root = E('ConfigurationFile')
    confs = E("Configurations")
    trace_act = SE(confs, "TraceActivation")
    conf = SE(trace_act, "Configuration")
    conf.set('Name', 'MCU')
    mcu = SE(conf, "MCU")
    sett = SE(mcu, "settings")
    SE(sett, "timestamp")
    root.append(confs)
    ettree = et.ElementTree(root)
    doc = amara.parse(et.tostring(ettree.getroot()))
    handle = open(tracing.joinpath("trace_activation_1.xml"), "w")
    handle.write(doc.xml(indent="yes"))
    handle.close()
#    tracing.writestr("trace_activation_1.xml", doc.xml(indent=u"yes"))
    group = component.joinpath("tsrc", "group")
    group.joinpath("bld.inf").write_text(
        r"""
        PRJ_TESTMMPFILES
        stif.mmp /* xyz.mmp */ abcd.mmp
        /*xyz.mmp*/
        eunit.mmp /* xyz.mmp */
        both.mmp
        ..\sub-component\group\sub-component.mmp
        """.replace('\\', os.sep))

    group.joinpath("test.pkg").write_text(
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
        "\tsrc\testmodules\file1.dll"-"c:\sys\bin\file1.dll"
        "\tsrc\testmodules\file2.dll"-"c:\sys\bin\file2.dll"
        "\tsrc\data\file1"-"e:\sys\bin\file1"
        "\tsrc\data\file2"-"e:\sys\bin\file2"
        "\tsrc\data\file3"-"e:\sys\bin\file3"
        "\tsrc\conf\file1.cfg"-"!:\sys\bin\file1.cfg"
        "\tsrc\conf\file2.cfg"-"!:\sys\bin\file2.cfg"
        "\tsrc\init\TestFramework.ini"-"!:\sys\bin\TestFramework.ini"
        "\tsrc\sis\file1.sisx"-"!:\sys\bin\file1.sisx"
        "\tsrc\sis\file2.sisx"-"!:\sys\bin\file2.sisx"
        """.replace('\\', os.sep))
    group.joinpath("stif.mmp").write_text("LIBRARY stiftestinterface.lib")
    group.joinpath("eunit.mmp").write_text("LIBRARY eunit.lib")
    group.joinpath("both.mmp").write_text("LIBRARY stiftestinterface.lib eunit.lib")
    init = component.joinpath("tsrc", "init")
    
    init.joinpath("TestFramework.ini").write_text(
        r"""
#     - Sets a device reset module's dll name(Reboot).
#        + If Nokia specific reset module is not available or it is not correct one
#          StifHWResetStub module may use as a template for user specific reset
#          module. 

[Engine_Defaults]

TestReportMode= FullReport        # Possible values are: 'Empty', 'Summary', 'Environment',
                                                               'TestCases' or 'FullReport'

CreateTestReport= YES            # Possible values: YES or NO

TestReportFilePath= C:\LOGS\TestFramework\
TestReportFileName= TestReport

TestReportFormat= TXT            # Possible values: TXT or HTML
        
        """)


def teardown_module():
    """ Cleanup environment after testing. """    
    def __init__():
        path(TEST_PATH).rmtree()

# CTC related functions    
def check_ctc_write(steps):
    """Checks if CTC data is written on the CTC log"""
    step = steps.next()
    assert step.findtext("./type") == "NonTestExecuteTask"
    params = step.findall("./parameters/parameter")
    assert params[0].get("value") == "writelocal"
    assert params[1].get("value") == path(r"z:\sys\bin\ctcman.exe")
    step = steps.next()
    assert step.findtext("./type") == "NonTestExecuteTask"
    params = step.findall("./parameters/parameter")
    assert params[0].get("value") == "writefile"
    assert params[1].get("value") == path(r"z:\sys\bin\ctcman.exe")

def check_ctc_log(steps, testtype=""):
    """Fetches CTC Log"""
    #For the ctcdata.txt to be published on the ATS network drive
    step = steps.next()
    assert step.findtext("./type") == "FileDownloadTask"
    params = step.findall("./parameters/parameter")
    #assert params[0].get("value") == "false"
    assert params[0].get("value") == path(r"c:\data\ctc\ctcdata.txt")
    if testtype == "withpkgfiles":
        assert params[1].get("value") == r"\\10.0.0.1\ctc_helium\builds\drop0\set1\ctcdata"
    else:
        assert params[1].get("value") == r"\\10.0.0.1\ctc_helium\builds\drop0\set0\ctcdata"
    
    #For the ctcdata.txt to be published on the build network drive
    step = steps.next()
    assert step.findtext("./type") == "FileDownloadTask"
    params = step.findall("./parameters/parameter")
    #assert params[0].get("value") == "true"
    assert params[0].get("value") == path(r"c:\data\ctc\ctcdata.txt")

def check_ctc_start(steps):
    """Checks if CTC starts in ATS"""
    step = steps.next()
    assert step.findtext("./type") == "CreateDirTask"
    params = step.findall("./parameters/parameter")
    assert params[0].get("value") == path(r"c:\data\ctc")
    step = steps.next()
    assert step.findtext("./type") == "NonTestExecuteTask"
    params = step.findall("./parameters/parameter")
    assert params[0].get("value") == path(r"z:\sys\bin\ctcman.exe")   

def check_fetch_logs(steps, harness="STIF"):
    """Checks fetching log directory is created"""
    step = steps.next()
    assert step.findtext("./type") == "FileDownloadTask"
    params = step.findall("./parameters/parameter")
    if harness == "STIF":
        assert params[0].get("value") == path(r"c:\logs\testframework\*")  
    else:
        assert params[0].get("value") == path(r"c:\Shared\EUnit\logs\*")

def check_diamonds_action(action):
    """ Testing Diamonds action. """
    assert action.findtext("./type") == "DiamondsAction"
    assert not action.findall("./parameters/parameter") 

def check_send_email_action(action, reportemail):
    """verifies if sening email option works"""
    assert action.findtext("./type") == "EmailAction"
    params = action.findall("./parameters/parameter")
    assert params[0].get("name") == "subject"
    #assert params[0].get("value") == "email subject"
    assert params[1].get("name") == "to"
    assert params[1].get("value") == reportemail
    
def check_ctc_run_process_action(action):
    """verifies if CTC run process action works"""
    #The parameters for this test are intended to execute on a windows machine
    assert action.findtext("./type") == "RunProcessAction"
    params = action.findall("./parameters/parameter")
    assert params[0].get("name") == "file"
    assert params[0].get("value") == "catsctc2html/catsctc2html.exe"
    assert params[1].get("name") == "parameters"
    assert params[1].get("value") == r"--ctcdata_files=\\10.0.0.1\ctc_helium\1234\drop0\set0\ctcdata --monsym_files=\\10.0.0.1\ctc_helium\1234\mon_syms\1\MON.sym --diamonds_build_id=1234 --drop_id=0 --total_amount_of_drops=1"

def check_ats_report_action(action, filestore):
    """verifies if sening ATS report option works"""
    assert action.findtext("./type") == "FileStoreAction"
    params = action.findall("./parameters/parameter")
    assert params[0].get("name") == "to-folder"
    assert params[0].get("value") == filestore
    assert params[1].get("name") == "report-type"
    assert params[1].get("value") == "ATS_REPORT"
    assert params[2].get("name") == "date-format"
    assert params[2].get("value") == "yyyyMMdd"
    assert params[3].get("name") == "time-format"
    assert params[3].get("value") == "HHmmss"

def check_stif_report_action(action, filestore):
    """verifies if sening STIF report option works"""
    assert action.findtext("./type") == "FileStoreAction"
    params = action.findall("./parameters/parameter")
    assert params[0].get("name") == "to-folder"
    assert params[0].get("value") == filestore
    assert params[1].get("name") == "report-type"
    assert params[1].get("value") == "STIF_COMPONENT_REPORT_ALL_CASES"
    assert params[2].get("name") == "run-log"
    assert params[2].get("value") == "true"
    assert params[3].get("name") == "date-format"
    assert params[3].get("value") == "yyyyMMdd"
    assert params[4].get("name") == "time-format"
    assert params[4].get("value") == "HHmmss"

def check_log_dir(steps):
    """ Test the log dir. """
    step = steps.next()
    assert step.findtext("./type") == "CreateDirTask"

def check_trace_start(steps, filestore):
    """Checks if tracing is started on the ATS"""
    step = steps.next()
    assert step.findtext("./type") == "trace-start"
    params = step.findall("./parameters/parameter")
    assert params[0].get("value") == path(r"ATS3Drop\set0\trace_activation\trace_activation_1.xml")
    assert params[1].get("value") == "MCU"
    assert params[2].get("value") == path(r"ATS3Drop\pmds\pmd_file.pmd")
    assert params[3].get("value") == filestore.joinpath("traces", "set0", "tracelog.blx")
    assert params[4].get("value") == "60"
    assert params[5].get("value") == "yyyyMMdd"
    assert params[6].get("value") == "HHmmss"
    
def check_trace_end_steps(steps, filestore):
    """ Test trace end step. """
    step = steps.next()
    assert step.findtext("./type") == "trace-stop"
    params = step.findall("./parameters/parameter")
    assert params[0].get("value") == "60"
    step = steps.next()
    assert step.findtext("./type") == "trace-convert"
    params = step.findall("./parameters/parameter")
    assert params[0].get("value") == path(r"ATS3Drop\pmds\pmd_file.pmd")
    assert params[1].get("value") == filestore.joinpath("traces", "set0", "tracelog.blx")
    assert params[2].get("value") == "60"
    assert params[3].get("value") == "yyyyMMdd"
    assert params[4].get("value") == "HHmmss"

class TestTestPlan(mocker.MockerTestCase):
    """Creates TestPlan mocker setup"""
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)  
          
    def setUp(self):
        """ Setup TestTestPlan testsuite. """
        opts = Bunch(testrun_name="testrun", harness="STIF", 
                     device_type="product", plan_name="ats3_test_plan",
                     diamonds_build_url="", report_email="", file_store=path(), test_timeout="60",
                     device_hwid="5425", trace_enabled="True", ctc_enabled="True", eunitexerunner_flags="/E S60AppEnv /R Off", 
                     multiset_enabled=False, ctc_run_process_params=r"10.0.0.1#x:\ats\drop0.zip#1", monsym_files="")
        self.atp = ats3.Ats3TestPlan(opts)
        self.config_files = TEST_FILES["conf"]
        self.data_files = TEST_FILES["data"]
        self.engine_ini_file = TEST_FILES["init"][0]
        self.image_files = TEST_FILES["output"]
        self.sis_files = TEST_FILES["sis"]
        self.testmodule_files = TEST_FILES["testmodules"]
        self.ctc_enabled = self.atp["ctc_enabled"]
        self.custom_dir = "CustomD"
        self.eunitexerunner_flags = self.atp["eunitexerunner_flags"]
        if self.atp["trace_enabled"].lower() == "true":
            self.trace_activation_files = TEST_FILES["trace_init"]    
            self.pmd_files = TEST_FILES["pmd_file"]
        else:
            self.trace_activation_files = []    
            self.pmd_files = []
        self.test_timeout = self.atp["test_timeout"]
        self.eunitexerunner_flags = self.atp["eunitexerunner_flags"]
        self.device_hwid = self.atp["device_hwid"]
        self.test_harness = self.atp["harness"]
        self.src_dst = [("" + os.sep + "tsrc" + os.sep + "testmodules" + os.sep + "file1.dll", "c:\sys\bin\file1.dll", "testmodule"),
            ("" + os.sep + "tsrc" + os.sep + "testmodules" + os.sep + "file2.dll", "c:\sys\bin\file2.dll", "testmodule"),
            ("" + os.sep + "tsrc" + os.sep + "data" + os.sep + "file1", "e:\sys\bin\file1", "data"),
            ("" + os.sep + "tsrc" + os.sep + "data" + os.sep + "file2", "e:\sys\bin\file2", "data"),
            ("" + os.sep + "tsrc" + os.sep + "data" + os.sep + "file3", "e:\sys\bin\file3", "data"),
            ("" + os.sep + "tsrc" + os.sep + "conf" + os.sep + "file1.cfg", "c:\sys\bin\file1.cfg", "conf"),
            ("" + os.sep + "tsrc" + os.sep + "conf" + os.sep + "file2.cfg", "c:\sys\bin\file2.cfg", "conf"),
            ("" + os.sep + "tsrc" + os.sep + "init" + os.sep + "TestFramework.ini", "c:\sys\bin\TestFramework.ini", "engine_ini"),
            ("" + os.sep + "tsrc" + os.sep + "sis" + os.sep + "file1.sisx", "c:\sys\bin\file1.sisx", ""),
            ("" + os.sep + "tsrc" + os.sep + "sis" + os.sep + "file2.sisx", "c:\sys\bin\file2.sisx", ""),]
        self.component_path = str(TEST_PATH.joinpath("tsrc", "group"))

    def test_creation(self):
        """ Testing creation. """        
        assert self.atp["testrun_name"] == "testrun"
        assert self.atp["harness"] == "STIF"
        assert self.atp["device_type"] == "product"
    
    def test_insert_set(self):
        """ Inserting a set of file. """        
        self.atp.insert_set(data_files=self.data_files,
                           config_files=self.config_files,
                           engine_ini_file=self.engine_ini_file,
                           image_files=self.image_files,
                           testmodule_files=self.testmodule_files,
                           test_timeout=self.test_timeout,
                           eunitexerunner_flags=self.eunitexerunner_flags,
                           pmd_files=self.pmd_files,                            
                           trace_activation_files=self.trace_activation_files,
                           component_path=self.component_path)
        self.atp.insert_set(image_files=self.image_files,                           
                           engine_ini_file=self.engine_ini_file,
                           sis_files=self.sis_files,
                           test_timeout=self.test_timeout,
                           eunitexerunner_flags=self.eunitexerunner_flags,
                           pmd_files=self.pmd_files,                            
                           trace_activation_files=self.trace_activation_files,
                           component_path=self.component_path)
        self.atp.insert_set(data_files=self.data_files,
                           config_files=self.config_files,
                           engine_ini_file=self.engine_ini_file,
                           image_files=self.image_files,
                           testmodule_files=self.testmodule_files,
                           test_timeout=self.test_timeout,
                           eunitexerunner_flags=self.eunitexerunner_flags,
                           src_dst=self.src_dst,
                           pmd_files=self.pmd_files,                            
                           trace_activation_files=self.trace_activation_files,
                           component_path=self.component_path)
        self.atp.insert_set(engine_ini_file=self.engine_ini_file,
                           test_timeout=self.test_timeout,
                           eunitexerunner_flags=self.eunitexerunner_flags,
                           image_files=self.image_files,
                           test_harness=self.test_harness,
                           src_dst=self.src_dst,
                           pmd_files=self.pmd_files,                            
                           trace_activation_files=self.trace_activation_files,
                           component_path=self.component_path)
        self.atp.insert_set(test_timeout=self.test_timeout,      
                           eunitexerunner_flags=self.eunitexerunner_flags,               
                           image_files=self.image_files,                        
                           test_harness=self.test_harness,                      
                           src_dst=self.src_dst,                                
                           pmd_files=self.pmd_files,                            
                           trace_activation_files=self.trace_activation_files,
                           component_path=self.component_path)  

        assert self.atp.sets[0] == dict(name="set0",
                                       data_files=self.data_files,
                                       config_files=self.config_files,
                                       engine_ini_file=self.engine_ini_file,
                                       image_files=self.image_files,
                                       testmodule_files=self.testmodule_files,
                                       test_timeout=self.test_timeout,
                                       eunitexerunner_flags=self.eunitexerunner_flags,
                                       test_harness=self.test_harness,
                                       src_dst=[],
                                       pmd_files=self.pmd_files,
                                       trace_path=self.atp.file_store.joinpath(u"§RUN_NAME§" + os.sep + u"§RUN_START_DATE§_§RUN_START_TIME§", "traces", "set0", "tracelog.blx"),
                                       trace_activation_files=self.trace_activation_files,
                                       ctc_enabled=self.atp["ctc_enabled"],
                                       custom_dir=None,
                                       component_path=self.component_path)
        assert self.atp.sets[1] == dict(name="set1",
                                       image_files=self.image_files,
                                       engine_ini_file=self.engine_ini_file,
                                       sis_files=self.sis_files,
                                       test_timeout=self.test_timeout,
                                       eunitexerunner_flags=self.eunitexerunner_flags,
                                       test_harness=self.test_harness,
                                       pmd_files=self.pmd_files,
                                       trace_path=self.atp.file_store.joinpath(u"§RUN_NAME§" + os.sep + u"§RUN_START_DATE§_§RUN_START_TIME§", "traces", "set1", "tracelog.blx"),
                                       trace_activation_files=self.trace_activation_files,
                                       ctc_enabled=self.atp["ctc_enabled"],
                                       custom_dir=None,
                                       component_path=self.component_path)

        assert self.atp.sets[2] == dict(name="set2",
                                       data_files=self.data_files,
                                       config_files=self.config_files,
                                       engine_ini_file=self.engine_ini_file,
                                       image_files=self.image_files,
                                       testmodule_files=self.testmodule_files,
                                       test_timeout=self.test_timeout,
                                       eunitexerunner_flags=self.eunitexerunner_flags,
                                       test_harness=self.test_harness,
                                       src_dst=self.src_dst,
                                       pmd_files=self.pmd_files,
                                       trace_path=self.atp.file_store.joinpath(u"§RUN_NAME§" + os.sep + u"§RUN_START_DATE§_§RUN_START_TIME§", "traces", "set2", "tracelog.blx"),
                                       trace_activation_files=self.trace_activation_files,
                                       ctc_enabled=self.atp["ctc_enabled"],
                                       custom_dir=None,
                                       component_path=self.component_path)
        assert self.atp.sets[3] == dict(name="set3",
                                       data_files=[],
                                       config_files=[],
                                       engine_ini_file=self.engine_ini_file,
                                       image_files=self.image_files,
                                       testmodule_files=[],
                                       test_timeout=self.test_timeout,
                                       eunitexerunner_flags=self.eunitexerunner_flags,
                                       test_harness=self.test_harness,
                                       src_dst=self.src_dst,
                                       pmd_files=self.pmd_files,
                                       trace_path=self.atp.file_store.joinpath(u"§RUN_NAME§" + os.sep + u"§RUN_START_DATE§_§RUN_START_TIME§", "traces", "set3", "tracelog.blx"),
                                       trace_activation_files=self.trace_activation_files,
                                       ctc_enabled=self.atp["ctc_enabled"],
                                       custom_dir=None,
                                       component_path=self.component_path)

        assert self.atp.sets[4] == dict(name="set4",
                                       data_files=[],
                                       config_files=[],
                                       engine_ini_file=None,
                                       image_files=self.image_files,
                                       testmodule_files=[],
                                       test_timeout=self.test_timeout,
                                       eunitexerunner_flags=self.eunitexerunner_flags,
                                       test_harness=self.test_harness,
                                       src_dst=self.src_dst,
                                       pmd_files=self.pmd_files,
                                       trace_path=self.atp.file_store.joinpath(u"§RUN_NAME§" + os.sep + u"§RUN_START_DATE§_§RUN_START_TIME§", "traces", "set4", "tracelog.blx"),
                                       trace_activation_files=self.trace_activation_files,
                                       ctc_enabled=self.atp["ctc_enabled"],
                                       custom_dir=None,
                                       component_path=self.component_path)
        
    def test_post_actions_email(self):
        """ Testing the send email post-action. """
        assert not self.atp.post_actions
        receiver = "joe.average@example.com"
        self.atp.report_email = receiver
        assert len(self.atp.post_actions) == 1
        _, items = self.atp.post_actions[0]
        items = dict(items)
        #assert action == "EmailAction"
        assert items["to"] == receiver
    
    def test_post_actions_ats4_report_only(self):
        """ Testing the ats4 report only post-action. """
        file_store = path("path/to/files")
        self.atp.file_store = file_store
        self.atp.harness = "EUNIT"
        assert len(self.atp.post_actions) == 2
        action, items = self.atp.post_actions[0]
        items = dict(items)
        assert action == "FileStoreAction"
        assert items["report-type"] == "ATS3_REPORT"
        assert items["to-folder"].startswith(file_store)
        assert items["to-folder"].endswith("ATS3_REPORT")
    
    def test_post_actions_stif(self):
        """ Testing STIF post-actions. """
        file_store = path("path/to/files")
        self.atp.file_store = file_store
        assert len(self.atp.post_actions) == 2
        action, items = self.atp.post_actions[1]
        items = dict(items)
        assert action == "FileStoreAction"
        assert items["report-type"] == "STIF_COMPONENT_REPORT_ALL_CASES"
        assert items["to-folder"].startswith(file_store)
        assert items["to-folder"].endswith("STIF_REPORT")
        
    def test_post_actions_diamonds(self):
        """ Testing Diamonds post-actions. """        
        self.atp.diamonds_build_url = "http://diamonds.nmp.company.com/diamonds/builds/1234"
        assert len(self.atp.post_actions) == 1
        action, items = self.atp.post_actions[0]
        assert action == "DiamondsAction"
        assert not items


class TestComponentParser(mocker.MockerTestCase):
    """ Testing the Ats3ComponentParser component parser. """
    
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
    
    def assert_paths(self, path1, path2):
        """ Checking the path. Validates that path1 and path2 are instance of path and they are equals. """
        if not isinstance(path1, path):
            path1 = path(path1)
        if not isinstance(path2, path):
            path2 = path(path2)            
        return self.assertEqual(path1.normpath(), path2.normpath())
    
    def setUp(self):
        """ Setting up TestComponentParser testsuite."""
        opts = Bunch(build_drive=path(TEST_PATH+os.sep), target_platform="target platform", eunitexerunner_flags="/E S60AppEnv /R Off",
                     data_dir=["data"], flash_images=[], sis_files=[], test_timeout="60", harness="STIF", trace_enabled="True", specific_pkg='')
        self.acp = atc.Ats3ComponentParser(opts)
        self.acp.tsrc_dir = TSRC
      
    def test_detect_dlls(self):
        """ Testing dlls detection. """
        open(os.path.join(TEST_PATH, 'lib1.dll'), 'w').close()
        os.makedirs(os.path.join(TEST_PATH, 'path', 'to', 'another'))
        open(os.path.join(TEST_PATH, 'path', 'to', 'another', 'library.dll'), 'w').close()
        open(os.path.join(TEST_PATH, 'lib2.dll'), 'w').close()
        
        # Setup mock objects.
        process = self.mocker.mock()
        process.communicate()
        self.mocker.result(["lib1.dll\npath/to/another/library.dll\nsome/other/file.txt\nlib2.dll\nlib3.dll\n"])
        obj = self.mocker.replace("subprocess.Popen")
        
        if os.environ.has_key("SBS_HOME"):
            obj("sbs --what -c target_platform.test", shell=True, stdout=subprocess.PIPE)
        else:
            obj("abld -w test build target platform", shell=True, stdout=subprocess.PIPE)
        self.mocker.result(process)
        
        self.mocker.replay()
        
        self.assertEqual([u"lib1.dll", u"library.dll", u"lib2.dll"],
                         [dll.name for dll in self.acp.tsrc_dll_files()])

    def test_harness(self):
        """ Detect test harness."""
        mmp_parser = parser.MmpFileParser()
        group = TSRC.joinpath("group")
        for harness, mmp in [
            ("STIF", group / "stif.mmp"),
            ("EUNIT", group / "eunit.mmp"),
            ("STIF", group / "both.mmp"),
            ]:
            self.assertEqual(harness, mmp_parser.get_harness(mmp))

class TestXMLGeneration(mocker.MockerTestCase):
    """Unit tests for the test.xml generation."""
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
        self.data_files = None
        self.config_files = None
        self.testmodule_files = None
        self.image_files = None
        self.engine_ini_file = None
        self.report_email = None
        self.file_store = None
        self.diamonds_build_url = None
        self.test_harness = None     
        self.src_dst = []
        self.trace_enabled = None
        self.pmd_files = None
        self.trace_activation_files = None
        self.ctc_enabled = None
        self.eunitexerunner_flags = None
        self.test_plan = None
        self.gen = None
        self.custom_dir = None
        self.diamonds_id = None
        self.ctc_run_process_params = None
        self.drop_count = None
        self.ctc_test_data = None
        self.ctc_network = None
        self.component_path = None
        self.drop_id = None

    def generate_xml(self, trace_enabled="False"):
        """ Generating the XML. """
        def files(*paths):
            """creating tsrc path list"""
            return [TEST_PATH.joinpath("tsrc", tpath) for tpath in paths]
        self.testmodule_files = files("testmodules/file1.dll", "testmodules/file2.dll")
        self.data_files = files("data/file1", "data/file2", "data/file3")
        self.config_files = files("conf/file1.cfg", "conf/file2.cfg")
        self.image_files = files("output/images/file1.fpsx", "output/images/file2.fpsx")
        self.engine_ini_file = files("init/TestFramework.ini")[0]
        self.report_email = "test.receiver@company.com"
        self.file_store = path(r"path/to/reports")
        self.diamonds_build_url = "http://diamonds.nmp.company.com/diamonds/builds/1234"
        self.test_harness = "STIF"        
        self.src_dst = []
        self.trace_enabled = trace_enabled
        self.pmd_files = TEST_FILES["pmd_file"]
        self.trace_activation_files = files("trace_init/trace_activation_1.xml")
        self.ctc_enabled = "True"
        self.eunitexerunner_flags = "/E S60AppEnv /R Off"
        self.custom_dir = "CustomB"
        self.component_path = str(TEST_PATH.joinpath("tsrc", "group"))
        self.ctc_run_process_params = r"10.0.0.1#x:\ats\drop0.zip#1"
        
        self.ctc_network = self.ctc_run_process_params.rsplit("#", 2)[0]
        self.drop_id = re.findall(".*drop(\d*).zip.*", self.ctc_run_process_params.lower())[0] #extracting int part of drop name
        self.drop_count = self.ctc_run_process_params.rsplit("#", 1)[1]
        self.diamonds_id = self.diamonds_build_url.rsplit(r"/", 1)[1]

        self.mocker.restore()
        test_plan = self.mocker.mock(count=False)
        mocker.expect(test_plan["testrun_name"]).result("test")
        mocker.expect(test_plan["harness"]).result("STIF")
        mocker.expect(test_plan["device_type"]).result("product")
        mocker.expect(test_plan["plan_name"]).result("test plan")
        mocker.expect(test_plan["diamonds_build_url"]).result(self.diamonds_build_url)
        mocker.expect(test_plan["test_timeout"]).result("60")
        mocker.expect(test_plan["eunitexerunner_flags"]).result("/E S60AppEnv /R Off")
        mocker.expect(test_plan["device_hwid"]).result("5425")
        mocker.expect(test_plan["custom_dir"]).result("custom")
        mocker.expect(test_plan.custom_dir).result(path(r"self.custom_dir"))
        mocker.expect(test_plan["report_email"]).result(self.report_email)
        mocker.expect(test_plan["ctc_run_process_params"]).result(self.ctc_run_process_params)
                
        if self.trace_enabled.lower() == "true":
            mocker.expect(test_plan["trace_enabled"]).result("True")
        else:
            mocker.expect(test_plan["trace_enabled"]).result("False")
        if self.trace_enabled == "False":
            mocker.expect(test_plan.sets).result([
                dict(name="set0", image_files=self.image_files, data_files=self.data_files,
                     config_files=self.config_files, testmodule_files=self.testmodule_files,
                     engine_ini_file=self.engine_ini_file, test_harness="STIF", src_dst=self.src_dst,
                     ctc_enabled=self.ctc_enabled, eunitexerunner_flags=self.eunitexerunner_flags,
                     custom_dir=self.custom_dir, component_path=self.component_path),
                dict(name="set1", image_files=self.image_files, data_files=self.data_files,
                     config_files=self.config_files, testmodule_files=self.testmodule_files,
                     engine_ini_file=self.engine_ini_file,test_harness="STIF", src_dst=self.src_dst,
                     ctc_enabled=self.ctc_enabled, eunitexerunner_flags=self.eunitexerunner_flags,
                     custom_dir=self.custom_dir, component_path=self.component_path),])
        elif self.trace_enabled == "True":
            mocker.expect(test_plan.sets).result([
                dict(name="set0", image_files=self.image_files, data_files=self.data_files,
                     config_files=self.config_files, testmodule_files=self.testmodule_files,
                     engine_ini_file=self.engine_ini_file, test_harness="STIF", src_dst=self.src_dst,
                     pmd_files=self.pmd_files, trace_activation_files=self.trace_activation_files,
                     trace_path=self.file_store.joinpath("traces", "set0", "tracelog.blx"),
                     ctc_enabled=self.ctc_enabled, eunitexerunner_flags=self.eunitexerunner_flags, component_path=self.component_path),
                dict(name="set1", image_files=self.image_files, data_files=self.data_files,
                     config_files=self.config_files, testmodule_files=self.testmodule_files,
                     engine_ini_file=self.engine_ini_file,test_harness="STIF", src_dst=self.src_dst,
                     pmd_files=self.pmd_files, trace_activation_files=self.trace_activation_files,
                     trace_path=self.file_store.joinpath("traces", "set1", "tracelog.blx"),
                     ctc_enabled=self.ctc_enabled, eunitexerunner_flags=self.eunitexerunner_flags, component_path=self.component_path),])

        ctc_file_name = "catsctc2html/catsctc2html.exe"
        ctc_data_path = str(os.path.normpath(r"\\%s\ctc_helium\%s\drop0\set0\ctcdata" % (self.ctc_network, self.diamonds_id)))
        mon_files = str(os.path.normpath(r"\\%s\ctc_helium\%s\mon_syms\1\MON.sym" % (self.ctc_network, self.diamonds_id)))
        self.ctc_test_data = [ctc_file_name, self.ctc_network, self.drop_id, self.drop_count, self.diamonds_id, ctc_data_path, mon_files] 

        mocker.expect(test_plan.post_actions).result([
            ("RunProcessAction", (("file", ctc_file_name ),
                                  ("parameters", r"--ctcdata_files=" + ctc_data_path + " --monsym_files=" + mon_files + " --diamonds_build_id=" + self.diamonds_id + " --drop_id=" + self.drop_id + " --total_amount_of_drops=" + self.drop_count ))),
            ("EmailAction", (("subject", "Release testing"),
                                 ("to", self.report_email))),
#            ("FileStoreAction", (("to-folder", self.file_store),
#                                 ("report-type", "ATS_REPORT"),
#                                 ("date-format", "yyyyMMdd"),
#                                 ("time-format", "HHmmss"))),
#            ("FileStoreAction", (("to-folder", self.file_store),
#                                 ("report-type", "STIF_COMPONENT_REPORT_ALL_CASES"),
#                                 ("run-log", "true"),
#                                 ("date-format", "yyyyMMdd"),
#                                 ("time-format", "HHmmss"))),
            ("DiamondsAction", ())])
        self.mocker.replay()
        self.test_plan = test_plan
        self.gen = adg.Ats3TemplateTestDropGenerator()
        return self.gen.generate_xml(test_plan)

    def test_basic_structure(self):
        """ Check that the overall test.xml structure is valid. """
        xml = self.generate_xml()
        # Check basics.
#        assert xml.find(".").tag == "test"
#        assert xml.find("./name").text == "test"
#        assert xml.find("./buildid").text == self.diamonds_build_url
#        assert xml.find("./target").tag
#        assert xml.find("./target/device").tag
#        harness, type_, device_hwid = xml.findall("./target/device/property")
#        assert harness.get("value") == "STIF"
#        assert type_.get("value") == "product"
#        assert device_hwid.get("value") == "5425"
#        
#        # Check generation of the test plan.
#        assert xml.find("./plan").get("name") == "test Plan"
#        assert xml.find("./plan/session").tag 
#        sets = xml.findall("./execution")
#        assert len(sets) == 2
#        assert sets[0].get("name") == "set0-"+str(TEST_PATH.joinpath("tsrc", "group"))
#        assert sets[0].find("./target/device").tag

    def test_set_structure(self):
        """ Check that a <set> element's structure is valid. """
        xml = self.generate_xml()
        tstset = xml.find("./execution")
        assert tstset.tag
        
    def test_case_flash_elems(self):
        """ Test case flash elems. """
        xml = self.generate_xml()
        found = False
        for case in xml.findall(".//task"):
            if case.find('type').text == 'FlashTask':
                found = True
                flashes = case.findall("./parameters/parameter")
                assert len(flashes) == len(self.image_files)
                for i, flash_file in enumerate(self.image_files):
                    assert flashes[i].get("name") == "image-" + str(i + 1)
                    assert flashes[i].get("value") == "ATS3Drop\\images\\" + flash_file.name
        assert found
        
    def test_case_steps(self):
        """ Test case steps. """
        xml = self.generate_xml()
        steps = iter(xml.findall(".//task"))
        steps.next() # Flash images
        check_ctc_start(steps)
        check_log_dir(steps)
        self.check_install_data(steps)
        self.check_install_configuration(steps)
        self.check_install_tmodules(steps)
        self.check_install_engine_ini(steps)
        self.check_run_cases(steps)
        check_ctc_write(steps)
        check_ctc_log(steps)
        check_fetch_logs(steps)

    def check_install_data(self, steps):
        """ Test install data. """
        for filename in self.data_files:
            step = steps.next()
            assert step.findtext("./type") == "FileUploadTask"
            params = step.findall("./parameters/parameter")            
            src = params[0].get("value")
            assert ntpath.basename(src) == ntpath.basename(filename)
            assert ntpath.dirname(src) == "ATS3Drop\\set0\\data"
            dst = params[1].get("value")
            assert ntpath.basename(dst) == ntpath.basename(filename)
            assert ntpath.dirname(dst) == r"e:\testing\data"
    
    def check_install_configuration(self, steps):
        """ Test install configuration. """
        for filepath in self.config_files:
            step = steps.next()
            assert step.findtext("./type") == "FileUploadTask"
            params = step.findall("./parameters/parameter")
            assert params[0].get("value") == "ATS3Drop\\set0\\conf\\" + ntpath.basename(filepath)
            assert params[1].get("value") == "e:\\testing\\conf\\" + ntpath.basename(filepath)

    def check_install_tmodules(self, steps):
        """ Test install tmodules. """
        for filepath in self.testmodule_files:
            step = steps.next()
            assert step.findtext("./type") == "FileUploadTask"
            params = step.findall("./parameters/parameter")
            assert params[0].get("value") == "ATS3Drop\\set0\\testmodules\\" + ntpath.basename(filepath)
            assert params[1].get("value") == "c:\\sys\\bin\\" + ntpath.basename(filepath)
    
    def check_install_engine_ini(self, steps):
        """ Test install engine ini. """
        filepath = self.engine_ini_file
        step = steps.next()
        assert step.findtext("./type") == "FileUploadTask"
        params = step.findall("./parameters/parameter")
        assert params[0].get("value") == "ATS3Drop\\set0\\init\\" + ntpath.basename(filepath)
        assert params[1].get("value") == "c:\\testframework\\" + ntpath.basename(filepath)
    
    def check_run_cases(self, steps):
        """ Test run cases. """
        step = steps.next()
        assert step.findtext("./type") == "StifRunCasesTask"
        params = step.findall("./parameters/parameter")
        assert params[0].get("value") == "*"
        assert params[1].get("value") == "60"
        assert params[2].get("value") == "c:\\testframework\\" + ntpath.basename(self.engine_ini_file)

    def test_steps_trace_enabled(self):
        """ Test steps trace enabled. """
        xml = self.generate_xml(trace_enabled="True")
        steps = iter(xml.findall(".//task"))
        steps.next() # Flash images
        check_ctc_start(steps)
        check_log_dir(steps)
        self.check_install_data(steps)
        self.check_install_configuration(steps)
        self.check_install_tmodules(steps)
        self.check_install_engine_ini(steps)
        #check_trace_start(steps, self.file_store)
        self.check_run_cases(steps)
        #check_trace_end_steps(steps, self.file_store)
        check_ctc_write(steps)
        check_ctc_log(steps)
        check_fetch_logs(steps) 
    
    def test_post_actions(self):
        """ Post actions are inserted into XML. """
        xml = self.generate_xml()        
        post_actions = xml.findall(".//action")
        check_ctc_run_process_action(post_actions[0])
        check_send_email_action(post_actions[1], self.report_email)
        #check_ats_report_action(post_actions[2], self.file_store)
        #check_stif_report_action(post_actions[3], self.file_store)
        check_diamonds_action(post_actions[2])
    
#    def test_files(self):
#        """ Testing files. """
#        xml = self.generate_xml()
#        files = iter(xml.findall("./files/file"))
#        assert files.next().text == r"ATS3Drop/images/file1.fpsx"
#        assert files.next().text == r"ATS3Drop/images/file2.fpsx"
#        assert files.next().text == r"ATS3Drop/set0/data/file1"
#        assert files.next().text == r"ATS3Drop/set0/data/file2"
#        assert files.next().text == r"ATS3Drop/set0/data/file3"
#        assert files.next().text == r"ATS3Drop/set0/conf/file1.cfg"
#        assert files.next().text == r"ATS3Drop/set0/conf/file2.cfg"
#        assert files.next().text == r"ATS3Drop/set0/testmodules/file1.dll"
#        assert files.next().text == r"ATS3Drop/set0/testmodules/file2.dll"
#        assert files.next().text == r"ATS3Drop/set0/init/TestFramework.ini"        
#        assert files.next().text == r"ATS3Drop/set1/data/file1"
#        assert files.next().text == r"ATS3Drop/set1/data/file2"
#        assert files.next().text == r"ATS3Drop/set1/data/file3"
#        assert files.next().text == r"ATS3Drop/set1/conf/file1.cfg"
#        assert files.next().text == r"ATS3Drop/set1/conf/file2.cfg"
#        assert files.next().text == r"ATS3Drop/set1/testmodules/file1.dll"
#        assert files.next().text == r"ATS3Drop/set1/testmodules/file2.dll"
#        assert files.next().text == r"ATS3Drop/set1/init/TestFramework.ini"        
#        self.assertRaises(StopIteration, files.next)
#        xml = self.generate_xml(trace_enabled="True")
#        files = iter(xml.findall("./files/file"))
#        assert files.next().text == r"ATS3Drop/images/file1.fpsx"
#        assert files.next().text == r"ATS3Drop/images/file2.fpsx"
#        assert files.next().text == r"ATS3Drop/pmds/pmd_file.pmd"
#        assert files.next().text == r"ATS3Drop/set0/data/file1"
#        assert files.next().text == r"ATS3Drop/set0/data/file2"
#        assert files.next().text == r"ATS3Drop/set0/data/file3"
#        assert files.next().text == r"ATS3Drop/set0/conf/file1.cfg"
#        assert files.next().text == r"ATS3Drop/set0/conf/file2.cfg"
#        assert files.next().text == r"ATS3Drop/set0/testmodules/file1.dll"
#        assert files.next().text == r"ATS3Drop/set0/testmodules/file2.dll"
#        assert files.next().text == r"ATS3Drop/set0/init/TestFramework.ini"
#        assert files.next().text == r"ATS3Drop/set0/trace_init/trace_activation_1.xml"
#        assert files.next().text == r"ATS3Drop/set1/data/file1"
#        assert files.next().text == r"ATS3Drop/set1/data/file2"
#        assert files.next().text == r"ATS3Drop/set1/data/file3"
#        assert files.next().text == r"ATS3Drop/set1/conf/file1.cfg"
#        assert files.next().text == r"ATS3Drop/set1/conf/file2.cfg"
#        assert files.next().text == r"ATS3Drop/set1/testmodules/file1.dll"
#        assert files.next().text == r"ATS3Drop/set1/testmodules/file2.dll"
#        assert files.next().text == r"ATS3Drop/set1/init/TestFramework.ini"
#        assert files.next().text == r"ATS3Drop/set1/trace_init/trace_activation_1.xml"        
#        self.assertRaises(StopIteration, files.next)
        
    def test_generate_drop(self):
        """ Manifest for ATS3Drop directory structure is generated. """
        xml = self.generate_xml()
        strbuffer = StringIO()
        
        self.gen.generate_drop(self.test_plan, xml, strbuffer)
        zfile = zipfile.ZipFile(strbuffer, "r")
        try:
            contents = sorted(path(tpath).normpath() for tpath in zfile.namelist())
            expected = sorted(path(tpath).normpath()
                           for tpath in [r"ATS3Drop" + os.sep + "set0" + os.sep + "conf" + os.sep + "file1.cfg",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "conf" + os.sep + "file2.cfg",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "data" + os.sep + "file1",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "data" + os.sep + "file2",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "data" + os.sep + "file3",
                                     r"ATS3Drop" + os.sep + "images" + os.sep + "file1.fpsx",
                                     r"ATS3Drop" + os.sep + "images" + os.sep + "file2.fpsx",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "init" + os.sep + "TestFramework.ini",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "testmodules" + os.sep + "file1.dll",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "testmodules" + os.sep + "file2.dll",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "conf" + os.sep + "file1.cfg",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "conf" + os.sep + "file2.cfg",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "data" + os.sep + "file1",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "data" + os.sep + "file2",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "data" + os.sep + "file3",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "init" + os.sep + "TestFramework.ini",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "testmodules" + os.sep + "file1.dll",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "testmodules" + os.sep + "file2.dll",
                                     r"test.xml"])
            diff = difflib.context_diff(expected, contents)
            assert contents == expected, "\n".join(diff)
        finally:
            zfile.close()

    def test_generate_drop_trace (self):
        "Manifest for ATS3Drop directory structure is generated when trace enabled."
        xml = self.generate_xml(trace_enabled="True")
        strbuffer = StringIO()
        
        self.gen.generate_drop(self.test_plan, xml, strbuffer)
        zfile = zipfile.ZipFile(strbuffer, "r")
        try:
            contents = sorted(path(tpath).normpath() for tpath in zfile.namelist())
            expected = sorted(path(tpath).normpath()
                           for tpath in [r"ATS3Drop" + os.sep + "set0" + os.sep + "conf" + os.sep + "file1.cfg",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "conf" + os.sep + "file2.cfg",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "data" + os.sep + "file1",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "data" + os.sep + "file2",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "data" + os.sep + "file3",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "trace_init" + os.sep + "trace_activation_1.xml",
                                     r"ATS3Drop" + os.sep + "images" + os.sep + "file1.fpsx",
                                     r"ATS3Drop" + os.sep + "images" + os.sep + "file2.fpsx",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "init" + os.sep + "TestFramework.ini",
                                     r"ATS3Drop" + os.sep + "pmds" + os.sep + "pmd_file.pmd",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "testmodules" + os.sep + "file1.dll",
                                     r"ATS3Drop" + os.sep + "set0" + os.sep + "testmodules" + os.sep + "file2.dll",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "conf" + os.sep + "file1.cfg",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "conf" + os.sep + "file2.cfg",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "data" + os.sep + "file1",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "data" + os.sep + "file2",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "data" + os.sep + "file3",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "trace_init" + os.sep + "trace_activation_1.xml",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "init" + os.sep + "TestFramework.ini",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "testmodules" + os.sep + "file1.dll",
                                     r"ATS3Drop" + os.sep + "set1" + os.sep + "testmodules" + os.sep + "file2.dll",
                                     r"test.xml"])
            diff = difflib.context_diff(expected, contents)
            assert contents == expected, "\n".join(diff)
        finally:
            zfile.close()


class TestXMLGenerationWithPKG(mocker.MockerTestCase):
    """
    Unit tests for the test.xml generation.
    """
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
        self.src_dst1 = []
        self.data_files = None
        self.config_files = None
        self.testmodule_files = None
        self.image_files = None
        self.engine_ini_file = None
        self.report_email = None
        self.file_store = None
        self.diamonds_build_url = None
        self.trace_enabled = None
        self.pmd_files = None
        self.trace_activation_files = None
        self.ctc_enabled = None
        self.eunitexerunner_flags = None
        self.test_plan = None
        self.gen = None
        self.src_dst0 = []
        self.custom_dir = None
        self.custom_files = None
        self.component_path = None
        self.ctc_run_process_params = None
        
    def generate_xml(self, harness, trace_enabled="False"):
        """Generates XML"""
        def files(*paths):
            """generates paths for the files"""
            return [TEST_PATH.joinpath("tsrc", tpath) for tpath in paths]

        self.src_dst1 = []
        self.data_files = files("data/file1", "data/file2", "data/file3")
        self.config_files = files("conf/file1.cfg", "conf/file2.cfg")
        self.testmodule_files = files("testmodules/file1.dll", "testmodules/file2.dll")
        self.image_files = files("output/images/file1.fpsx", "output/images/file2.fpsx")
        self.engine_ini_file = files("init/TestFramework.ini")[0]
        self.report_email = "test.receiver@company.com"
        self.file_store = path("path/to/reports")
        self.diamonds_build_url = "http://diamonds.nmp.company.com/diamonds/builds/1234"
        self.trace_enabled = trace_enabled
        self.pmd_files = TEST_FILES["pmd_file"]
        self.trace_activation_files = files("trace_init/trace_activation_1.xml")
        self.ctc_enabled = "True"
        self.eunitexerunner_flags = "/E S60AppEnv /R Off"
        self.custom_dir = "custom"
        self.custom_files = files("custom/postpostaction.xml", "custom/prepostaction.xml")
        self.component_path = str(TEST_PATH.joinpath("tsrc", "group"))
        self.ctc_run_process_params = r"10.0.0.1#x:\ats\drop0.zip#1"
        self.src_dst0 = [
            (TEST_PATH.joinpath(r"tsrc" + os.sep + "testmodules" + os.sep + "file1.dll"), path(r"c:\sys\bin\file1.dll"), "testmodule"),
            (TEST_PATH.joinpath(r"tsrc" + os.sep + "testmodules" + os.sep + "file2.dll"), path(r"c:\sys\bin\file2.dll"), "testmodule"),
            (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file1"), path(r"e:\sys\bin\file1"), "data"),
            (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file2"), path(r"e:\sys\bin\file2"), "data"),
            (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file3"), path(r"e:\sys\bin\file3"), "data"),]
        if harness == "STIF" or harness == "MULTI_HARNESS":
            harness0 = harness1 = "STIF"
            if "MULTI_HARNESS" in harness:
                harness1 = "EUNIT"
                self.src_dst1 = [
                    (TEST_PATH.joinpath(r"tsrc" + os.sep + "testmodules" + os.sep + "file1.dll"), path(r"c:\sys\bin\file1.dll"), "testmodule"),
                    (TEST_PATH.joinpath(r"tsrc" + os.sep + "testmodules" + os.sep + "file2.dll"), path(r"c:\sys\bin\file2.dll"), "testmodule"),
                    (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file1"), path(r"e:\sys\bin\file1"), "data"),
                    (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file2"), path(r"e:\sys\bin\file2"), "data"),
                    (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file3"), path(r"e:\sys\bin\file3"), "data"),] 
            self.src_dst0 = [
                (TEST_PATH.joinpath(r"tsrc" + os.sep + "testmodules" + os.sep + "file1.dll"), path(r"c:\sys\bin\file1.dll"), "testmodule"),
                (TEST_PATH.joinpath(r"tsrc" + os.sep + "testmodules" + os.sep + "file2.dll"), path(r"c:\sys\bin\file2.dll"), "testmodule"),
                (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file1"), path(r"e:\sys\bin\file1"), "data"),
                (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file2"), path(r"e:\sys\bin\file2"), "data"),
                (TEST_PATH.joinpath(r"tsrc" + os.sep + "data" + os.sep + "file3"), path(r"e:\sys\bin\file3"), "data"),
                (TEST_PATH.joinpath(r"tsrc" + os.sep + "conf" + os.sep + "file1.cfg"), path(r"c:\sys\bin\file1.cfg"), "conf"),
                (TEST_PATH.joinpath(r"tsrc" + os.sep + "conf" + os.sep + "file2.cfg"), path(r"c:\sys\bin\file2.cfg"), "conf"),
                (TEST_PATH.joinpath(r"tsrc" + os.sep + "init" + os.sep + "TestFramework.ini"), path(r"c:\sys\bin\TestFramework.ini"), "engine_ini"),]
            if "STIF" in harness:
                self.src_dst1 = self.src_dst0
            
        elif harness == "EUNIT":
            harness0 = harness1 = harness
            self.src_dst1 = self.src_dst0
            
        self.mocker.restore()
        test_plan = self.mocker.mock(count=False)
        mocker.expect(test_plan["testrun_name"]).result("test")
        mocker.expect(test_plan["harness"]).result(harness)
        mocker.expect(test_plan["device_type"]).result("product")
        mocker.expect(test_plan["plan_name"]).result("test plan")
        mocker.expect(test_plan["diamonds_build_url"]).result(self.diamonds_build_url)
        mocker.expect(test_plan["test_timeout"]).result("60")
        mocker.expect(test_plan["eunitexerunner_flags"]).result("/E S60AppEnv /R Off")
        mocker.expect(test_plan["eunitexerunner?flags"]).result(self.eunitexerunner_flags)
        mocker.expect(test_plan["device_hwid"]).result("5425")
        mocker.expect(test_plan["trace_enabled"]).result(self.trace_enabled)
        mocker.expect(test_plan["ctc_enabled"]).result(self.ctc_enabled)
        mocker.expect(test_plan["custom_dir"]).result("custom1A")
        mocker.expect(test_plan.custom_dir).result(path(r"self.custom_dir"))
        mocker.expect(test_plan["ctc_run_process_params"]).result(self.ctc_run_process_params)
        mocker.expect(test_plan["report_email"]).result(self.report_email)
        if self.trace_enabled == "False":
            mocker.expect(test_plan.sets).result([
                dict(name="set0", image_files=self.image_files, data_files=self.data_files,
                     config_files=self.config_files, testmodule_files=self.testmodule_files,
                     engine_ini_file=self.engine_ini_file, test_harness=harness0,src_dst=self.src_dst0,
                     ctc_enabled=self.ctc_enabled, eunitexerunner_flags=self.eunitexerunner_flags,
                     custom_dir = self.custom_dir, component_path=self.component_path),
                dict(name="set1", image_files=self.image_files, data_files=self.data_files,
                     config_files=self.config_files, testmodule_files=self.testmodule_files,
                     engine_ini_file=self.engine_ini_file, test_harness=harness1, src_dst=self.src_dst1,
                     ctc_enabled=self.ctc_enabled, eunitexerunner_flags=self.eunitexerunner_flags,
                     custom_dir = self.custom_dir, component_path=self.component_path),
            ])
        else:
            mocker.expect(test_plan.sets).result([
                dict(name="set0", image_files=self.image_files, data_files=self.data_files,
                     config_files=self.config_files, testmodule_files=self.testmodule_files,
                     engine_ini_file=self.engine_ini_file, test_harness=harness0, src_dst=self.src_dst0,
                     pmd_files=self.pmd_files, trace_activation_files=self.trace_activation_files,
                     trace_path=self.file_store.joinpath("traces", "set0", "tracelog.blx"),
                     ctc_enabled=self.ctc_enabled, eunitexerunner_flags=self.eunitexerunner_flags,
                     custom_dir = self.custom_dir, component_path=self.component_path),
                dict(name="set1", image_files=self.image_files, data_files=self.data_files,
                     config_files=self.config_files, testmodule_files=self.testmodule_files,
                     engine_ini_file=self.engine_ini_file, test_harness=harness1, src_dst=self.src_dst1,
                     pmd_files=self.pmd_files, trace_activation_files=self.trace_activation_files,
                     trace_path=self.file_store.joinpath("traces", "set1", "tracelog.blx"),
                     ctc_enabled=self.ctc_enabled, eunitexerunner_flags=self.eunitexerunner_flags,
                     custom_dir = self.custom_dir, component_path=self.component_path),])
        mocker.expect(test_plan.post_actions).result([
            ("EmailAction", (("subject", "Release testing"),
                                 ("to", self.report_email))),
#            ("FileStoreAction", (("to-folder", self.file_store),
#                                 ("report-type", "ATS_REPORT"),
#                                 ("date-format", "yyyyMMdd"),
#                                 ("time-format", "HHmmss"))),
#            ("FileStoreAction", (("to-folder", self.file_store),
#                                 ("report-type", "STIF_COMPONENT_REPORT_ALL_CASES"),
#                                 ("run-log", "true"),
#                                 ("date-format", "yyyyMMdd"),
#                                 ("time-format", "HHmmss"))),
            ("DiamondsAction", ())])

        self.mocker.replay()
        self.test_plan = test_plan
        
        self.gen = adg.Ats3TemplateTestDropGenerator()
        return self.gen.generate_xml(test_plan)
#        for thar in test_harness:
#            xml = self.generate_xml(thar)
#            # Check basics.
#            assert xml.find(".").tag == "test"
#            assert xml.find("./name").text == "test"
#            assert xml.find("./buildid").text == self.diamonds_build_url
#            assert xml.find("./target").tag
#            assert xml.find("./target/device").tag
#            if self.test_plan["harness"] == "MULTI_HARNESS":
#                harness_1, type_1, device_hwid_1, harness_2, type_2, device_hwid_2 = xml.findall("./target/device/property")
#            else:
#                harness_1, type_1, device_hwid_1 = xml.findall("./target/device/property")
#            
#            if self.test_plan["harness"] == "MULTI_HARNESS":
#                assert harness_1.get("value") == "STIF"
#                assert type_1.get("value") == "product"
#                assert device_hwid_1.get("value") == "5425"
#                assert harness_2.get("value") == "EUNIT"
#                assert type_2.get("value") == "product"
#                assert device_hwid_2.get("value") == "5425"
#            else:
#                assert harness_1.get("value") == thar
#                assert type_1.get("value") == "product"
#                assert device_hwid_1.get("value") == "5425"
#
#        # Check generation of the test plan.
#        assert xml.find("./plan").get("name") == "test Plan"
#        assert xml.find("./plan/session").tag 
#        sets = xml.findall("./execution")
#        assert len(sets) == 2
#        assert sets[0].get("name") == "set0-"+str(TEST_PATH.joinpath("tsrc", "group"))
#        assert sets[0].find("./target/device").tag
    
    def test_set_structure(self):
        """Check that a <set> element's structure is valid."""
        xml = self.generate_xml("STIF")
        tstset = xml.find("./execution")
        assert tstset.tag

    def test_case_flash_elems(self):
        """Checks flash target element in the test.xml file"""
        xml = self.generate_xml("STIF")
        found = False
        for case in xml.findall(".//task"):
            if case.find('type').text == 'FlashTask':
                found = True
                flashes = case.findall("./parameters/parameter")
                assert len(flashes) == len(self.image_files)
                for i, flash_file in enumerate(self.image_files):
                    assert flashes[i].get("name") == "image-" + str(i + 1)
                    assert flashes[i].get("value") == "ATS3Drop\\images\\" + flash_file.name
        assert found

    def test_case_steps(self):
        """Checks cases in steps in the test.xml file"""
        test_harness = ["STIF", "EUNIT", "MULTI_HARNESS"]
        for thar in test_harness:
            xml = self.generate_xml(thar)
            #print et.tostring(xml.getroot())
            steps = iter(xml.findall(".//task"))
            steps.next() # Flash images
            check_ctc_start(steps)
            check_log_dir(steps)
            if "MULTI_HARNESS" in thar:
                self.check_install_step(steps, "STIF")
                self.check_run_cases(steps, "STIF")
                check_ctc_write(steps)
                check_ctc_log(steps)
                check_fetch_logs(steps, "STIF")
                
                steps.next() # Flash images
                check_ctc_start(steps)
                check_log_dir(steps)
                self.check_install_step(steps, "EUNIT", set_count="1")
                self.check_run_cases(steps, "EUNIT")
                check_ctc_write(steps)
                check_ctc_log(steps, "withpkgfiles")
                check_fetch_logs(steps, "EUNIT")
            else:
                self.check_install_step(steps, thar)
                self.check_run_cases(steps, thar)
                check_ctc_write(steps)
                check_ctc_log(steps)
                check_fetch_logs(steps, thar)

    def check_install_step(self, steps, harness, set_count="0"):
        """Checks install steps in the test.xml file"""
        if harness == "MULTI_HARNESS":
            dst = [self.src_dst0, self.src_dst1]
        else:
            dst = [self.src_dst0]
        if set_count == "1":
            dst = [self.src_dst1]

        for dest in dst:
            for file1 in dest:
                step = steps.next()
                (drive, _) = ntpath.splitdrive(file1[1])
                filename = ntpath.basename(file1[1])
                letter = drive[0]
                #if "FileUploadTask" in step.get("type"):
                assert step.findtext("./type") == "FileUploadTask"
                params = step.findall("./parameters/parameter")            
                src = params[0].get("value")
                assert ntpath.basename(src) == filename
                assert ntpath.dirname(src) == "ATS3Drop\\set" + set_count + '\\' + letter + '\\' + "sys\\bin"
                dst = params[1].get("value")
                assert ntpath.basename(dst) == filename
                assert ntpath.dirname(dst) == drive + "\\sys\\bin"

    def check_run_cases(self, steps, harness="STIF"):
        """Checks run cases in the test.xml file"""
        step = steps.next()
        if harness == "STIF":
            _ = self.engine_ini_file 
            assert step.findtext("./type") == "StifRunCasesTask"
            params = step.findall("./parameters/parameter")
            assert params[0].get("value") == "*"
            assert params[1].get("value") == "60"
            assert params[2].get("value") == "c:\\sys\\bin\\" + ntpath.basename(self.engine_ini_file)
        elif harness == "EUNIT":
            _ = self.testmodule_files[0]
            assert step.findtext("./type") == "EUnitTask"
            params = step.findall("./parameters/parameter")
            assert params[0].get("value") == path(r"z:\sys\bin\EUNITEXERUNNER.EXE")
            assert params[1].get("value") == path(r"c:\Shared\EUnit\logs\file1_log.xml")
            assert params[2].get("value") == "/E S60AppEnv /R Off /F file1 /l xml file1.dll"
            assert params[3].get("value") == "60"
            step = steps.next()
            _ = self.testmodule_files[1]
            assert step.findtext("./type") == "EUnitTask"
            params = step.findall("./parameters/parameter")
            assert params[0].get("value") == path(r"z:\sys\bin\EUNITEXERUNNER.EXE")
            assert params[1].get("value") == path(r"c:\Shared\EUnit\logs\file2_log.xml")
            assert params[2].get("value") == "/E S60AppEnv /R Off /F file2 /l xml file2.dll"
            assert params[3].get("value") == "60"

    def test_steps_trace_enabled(self):
        """checks if traing is enabled"""
        test_harness = ["STIF"]
        for thar in test_harness:
            xml = self.generate_xml(thar, trace_enabled="True")
            steps = iter(xml.findall(".//task"))
            steps.next() # Flash images
            check_ctc_start(steps)
            check_log_dir(steps)
            self.check_install_step(steps, thar)
            #check_trace_start(steps, self.file_store)
            self.check_run_cases(steps)
            #check_trace_end_steps(steps, self.file_store)
            check_ctc_write(steps)
            check_ctc_log(steps)
            check_fetch_logs(steps)
        
    def test_post_actions(self):
        "Post actions are inserted into XML."
        xml = self.generate_xml("STIF")
        post_actions = xml.findall(".//action")
        check_send_email_action(post_actions[0], self.report_email)
        #check_ats_report_action(post_actions[1], self.file_store)
        #check_stif_report_action(post_actions[2], self.file_store)
        check_diamonds_action(post_actions[1])
#    def test_files(self):
#        """Tests if the files are created for mock"""
#        xml = self.generate_xml("STIF")
#        files = iter(xml.findall("./files/file"))
#        assert files.next().text == r"ATS3Drop/images/file1.fpsx"
#        assert files.next().text == r"ATS3Drop/images/file2.fpsx"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/file1.dll"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/file2.dll"
#        assert files.next().text == r"ATS3Drop/set0/e/sys/bin/file1"
#        assert files.next().text == r"ATS3Drop/set0/e/sys/bin/file2"
#        assert files.next().text == r"ATS3Drop/set0/e/sys/bin/file3"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/file1.cfg"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/file2.cfg"        
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/TestFramework.ini"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/file1.dll"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/file2.dll"
#        assert files.next().text == r"ATS3Drop/set1/e/sys/bin/file1"
#        assert files.next().text == r"ATS3Drop/set1/e/sys/bin/file2"
#        assert files.next().text == r"ATS3Drop/set1/e/sys/bin/file3"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/file1.cfg"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/file2.cfg"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/TestFramework.ini"
#        self.assertRaises(StopIteration, files.next)
#        xml = self.generate_xml(harness="STIF", trace_enabled="True")
#        files = iter(xml.findall("./files/file"))
#        assert files.next().text == r"ATS3Drop/images/file1.fpsx"
#        assert files.next().text == r"ATS3Drop/images/file2.fpsx"
#        assert files.next().text == r"ATS3Drop/pmds/pmd_file.pmd"
#        assert files.next().text == r"ATS3Drop/set0/trace_init/trace_activation_1.xml"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/file1.dll"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/file2.dll"
#        assert files.next().text == r"ATS3Drop/set0/e/sys/bin/file1"
#        assert files.next().text == r"ATS3Drop/set0/e/sys/bin/file2"
#        assert files.next().text == r"ATS3Drop/set0/e/sys/bin/file3"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/file1.cfg"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/file2.cfg"
#        assert files.next().text == r"ATS3Drop/set0/c/sys/bin/TestFramework.ini"
#        assert files.next().text == r"ATS3Drop/set1/trace_init/trace_activation_1.xml"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/file1.dll"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/file2.dll"
#        assert files.next().text == r"ATS3Drop/set1/e/sys/bin/file1"
#        assert files.next().text == r"ATS3Drop/set1/e/sys/bin/file2"
#        assert files.next().text == r"ATS3Drop/set1/e/sys/bin/file3"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/file1.cfg"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/file2.cfg"
#        assert files.next().text == r"ATS3Drop/set1/c/sys/bin/TestFramework.ini"
#
#        self.assertRaises(StopIteration, files.next)
    def test_generate_drop(self):
        """Manifest for ATS3Drop directory structure is generated."""
        xml = self.generate_xml("STIF")
        strbuffer = StringIO()
        self.gen.generate_drop(self.test_plan, xml, strbuffer)

        zfile = zipfile.ZipFile(strbuffer, "r")
        try:
            contents = sorted(tpath for tpath in zfile.namelist())
            expected = sorted(tpath
                           for tpath in [r"ATS3Drop/set0/c/sys/bin/file1.cfg",
                                     r"ATS3Drop/set0/c/sys/bin/file2.cfg",
                                     r"ATS3Drop/set0/e/sys/bin/file1",
                                     r"ATS3Drop/set0/e/sys/bin/file2",
                                     r"ATS3Drop/set0/e/sys/bin/file3",
                                     r"ATS3Drop/images/file1.fpsx",
                                     r"ATS3Drop/images/file2.fpsx",
                                     r"ATS3Drop/set0/c/sys/bin/TestFramework.ini",
                                     r"ATS3Drop/set0/c/sys/bin/file1.dll",
                                     r"ATS3Drop/set0/c/sys/bin/file2.dll",
                                     r"ATS3Drop/set1/c/sys/bin/file1.cfg",
                                     r"ATS3Drop/set1/c/sys/bin/file2.cfg",
                                     r"ATS3Drop/set1/e/sys/bin/file1",
                                     r"ATS3Drop/set1/e/sys/bin/file2",
                                     r"ATS3Drop/set1/e/sys/bin/file3",
                                     r"ATS3Drop/set1/c/sys/bin/TestFramework.ini",
                                     r"ATS3Drop/set1/c/sys/bin/file1.dll",
                                     r"ATS3Drop/set1/c/sys/bin/file2.dll",
                                     r"test.xml"])
            diff = difflib.context_diff(expected, contents)
            assert contents == expected, "\n".join(diff)
        finally:
            zfile.close()

    def test_generate_drop_trace_enabled(self):
        "Manifest for ATS3Drop directory structure is generated when trace enabled."
        xml = self.generate_xml(harness="STIF", trace_enabled="True")
        strbuffer = StringIO()
        
        self.gen.generate_drop(self.test_plan, xml, strbuffer)
        zfile = zipfile.ZipFile(strbuffer, "r")
        try:
            contents = sorted(tpath for tpath in zfile.namelist())
            expected = sorted(tpath
                           for tpath in [r"ATS3Drop/set0/c/sys/bin/file1.cfg",
                                     r"ATS3Drop/set0/c/sys/bin/file2.cfg",
                                     r"ATS3Drop/set0/e/sys/bin/file1",
                                     r"ATS3Drop/set0/e/sys/bin/file2",
                                     r"ATS3Drop/set0/e/sys/bin/file3",
                                     r"ATS3Drop/set0/trace_init/trace_activation_1.xml",
                                     r"ATS3Drop/images/file1.fpsx",
                                     r"ATS3Drop/images/file2.fpsx",
                                     r"ATS3Drop/pmds/pmd_file.pmd",
                                     r"ATS3Drop/set0/c/sys/bin/TestFramework.ini",
                                     r"ATS3Drop/set0/c/sys/bin/file1.dll",
                                     r"ATS3Drop/set0/c/sys/bin/file2.dll",
                                     r"ATS3Drop/set1/c/sys/bin/file1.cfg",
                                     r"ATS3Drop/set1/c/sys/bin/file2.cfg",
                                     r"ATS3Drop/set1/e/sys/bin/file1",
                                     r"ATS3Drop/set1/e/sys/bin/file2",
                                     r"ATS3Drop/set1/e/sys/bin/file3",
                                     r"ATS3Drop/set1/trace_init/trace_activation_1.xml",
                                     r"ATS3Drop/set1/c/sys/bin/TestFramework.ini",
                                     r"ATS3Drop/set1/c/sys/bin/file1.dll",
                                     r"ATS3Drop/set1/c/sys/bin/file2.dll",
                                     r"test.xml"])
            diff = difflib.context_diff(expected, contents)
            assert contents == expected, "\n".join(diff)
        finally:
            zfile.close()
            
class TestDropGenerationWithSis(mocker.MockerTestCase):
    """
    Unit tests for the test.xml generation with sis files.
    """
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
        self.sis_files = None
        self.image_files = None
        self.engine_ini_file = None
        self.report_email = None
        self.file_store = None
        self.diamonds_build_url = None
        self.harness = None
        self.test_plan = None
        self.gen = None
        self.src_dst = []
        self.component_path = None
        self.ctc_run_process_params = None

    def generate_xml(self):
        """Geberates XML if sis files"""
        def files(*paths):
            """generates paths for the files"""
            return [TEST_PATH.joinpath("tsrc", tpath) for tpath in paths]
        self.sis_files = files("sis/file1.sisx", "sis/file2.sisx", "sis/file3.sisx")
        self.image_files = files("output/images/file1.fpsx", "output/images/file2.fpsx")
        self.engine_ini_file = files("init/TestFramework.ini")[0]
        self.report_email = "test.receiver@company.com"
        self.file_store = path("path/to/reports")
        self.diamonds_build_url = "http://diamonds.nmp.company.com/diamonds/builds/1234"
        self.harness = "STIF"
        self.component_path = str(TEST_PATH.joinpath("tsrc", "group"))
        self.ctc_run_process_params = r"10.0.0.1#x:\ats\drop0.zip#1"
        
        test_plan = self.mocker.mock(count=False)
        mocker.expect(test_plan["testrun_name"]).result("test")
        mocker.expect(test_plan["harness"]).result("STIF")
        mocker.expect(test_plan["device_type"]).result("product")
        mocker.expect(test_plan["plan_name"]).result("test plan")
        mocker.expect(test_plan["diamonds_build_url"]).result(self.diamonds_build_url)
        mocker.expect(test_plan["test_timeout"]).result("60")
        mocker.expect(test_plan["device_hwid"]).result("5425")
        mocker.expect(test_plan["ctc_enabled"]).result("False")
        mocker.expect(test_plan["trace_enabled"]).result("False")
        mocker.expect(test_plan["custom_dir"]).result("CustomC")
        mocker.expect(test_plan.custom_dir).result(path(r"self.custom_dir"))
        mocker.expect(test_plan["ctc_run_process_params"]).result(self.ctc_run_process_params)
        mocker.expect(test_plan["report_email"]).result(self.report_email)
        mocker.expect(test_plan.sets).result([
            dict(name="set0", image_files=self.image_files, sis_files=self.sis_files,
                 engine_ini_file=self.engine_ini_file, test_harness=self.harness, ctc_enabled="False", component_path=self.component_path),])
        mocker.expect(test_plan.post_actions).result([])
        self.mocker.replay()
        self.test_plan = test_plan
        
        self.gen = adg.Ats3TemplateTestDropGenerator()
        return self.gen.generate_xml(test_plan)

    def test_case_steps(self):
        """Checks cases in steps in the test.xml file"""
        xml = self.generate_xml()
        steps = iter(xml.findall(".//task"))
        steps.next() # Flash images
        steps.next() # Stif log dir creation.
        self.check_install_sis_files(steps)
        steps.next() # Install engine ini.
        self.check_install_sis_to_device(steps)
        steps.next() # Run cases.
        steps.next() # Fetch logs.
        self.assertRaises(StopIteration, steps.next)

    def check_install_sis_files(self, steps):
        """Checks sis files install steps in the test.xml file"""
        for filename in self.sis_files:
            step = steps.next()
            assert step.findtext("./type") == "FileUploadTask"
            params = step.findall("./parameters/parameter")
            # TO DO: Should sis files be specified outside of the set?
            assert params[0].get("value") == "ATS3Drop\\set0\\sis\\" + ntpath.basename(filename)
            assert params[1].get("value") == "c:\\testframework\\" + ntpath.basename(filename)

    def check_install_sis_to_device(self, steps):
        """Checks sis files installation on the device"""
        for filename in self.sis_files:
            step = steps.next()
            assert step.findtext("./type") == "InstallSisTask"
            params = step.findall("./parameters/parameter")
            assert params[-1].get("value") == "c:\\testframework\\" + ntpath.basename(filename)
