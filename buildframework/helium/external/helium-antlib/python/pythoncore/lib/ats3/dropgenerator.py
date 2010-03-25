# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : dropgenerator.py 
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

""" Generate test drop zip file for ATS3"""

# pylint: disable-msg=W0142,R0912,R0201,R0915,R0913,R0904
# pylint: disable-msg=C0302
# pylint: disable-msg=W0404,W0603

#W0142 => * and ** were used
#C0302 => Too many lines
#R* removed when refactored
#W => use of global statement

import codecs
from  xml.parsers.expat import ExpatError

from xml.etree import ElementTree as et
import pkg_resources
from path import path # pylint: disable-msg=F0401
import logging
import os
import re
import zipfile
import amara
import atsconfigparser

# pylint: disable-msg=W0404
from ntpath import sep as atssep
import ntpath as atspath

import jinja2 # pylint: disable-msg=F0401

_logger = logging.getLogger('ats')

# Shortcuts
E = et.Element
SE = et.SubElement

CTC_PATHS_LIST = []

class Ats3TestDropGenerator(object):
    """
    Generate test drop zip file for ATS3.

    Generates drom zip files file from a TestPlan instance. The main
    responsibility of this class is to serialize the plan into a valid XML
    file and build a zip file for the drop.
    
    Creates one <set> for each component's tests.

    Stif harness, normal operation
    ------------------------------
    
    - create logging dir for stif             makedir (to C:\logs\TestFramework)
    - install data files                      install (to E:\testing\data)
    - install configuration (.cfg) files      "       (to E:\testing\conf)
    - install testmodule (.dll) files         "       (to C:\sys\bin)
    - install engine ini (testframework.ini)  "       (to C:\testframework)
    - execute cases from the engine ini       run-cases
    - fetch logs                              fetch-log

    Stif harness, SIS package installation
    --------------------------------------
    
    - like above but with data and config files replaced by sis files
    - install sis to the device               install-software

    """

    STIF_LOG_DIR = r"c:" + os.sep + "logs" + os.sep + "testframework"
    TEF_LOG_DIR = r"c:" + os.sep + "logs" + os.sep + "testexecute"
    MTF_LOG_DIR = r"c:" + os.sep + "logs" + os.sep + "testresults"
    STIFUNIT_LOG_DIR = r"c:" + os.sep + "logs" + os.sep + "testframework"
    EUNIT_LOG_DIR = r"c:" + os.sep + "Shared" + os.sep + "EUnit" + os.sep + "logs"
    #QT_LOG_DIR = r"c:" + os.sep + "private" + os.sep + "Qt" + os.sep + "logs"
    QT_LOG_DIR = r"c:" + os.sep + "shared" + os.sep + "EUnit" + os.sep + "logs"
    CTC_LOG_DIR = r"c:" + os.sep + "data" + os.sep + "ctc"

    def __init__(self):
        self.drop_path_root = path("ATS3Drop")
        self.drop_path = None
        self.defaults = {}

    def generate(self, test_plan, output_file, config_file=None):
        """Generate a test drop file."""
        xml = self.generate_xml(test_plan)
        
        if config_file:
            xmltext = et.tostring(xml.getroot(), "ISO-8859-1")
            xmltext = atsconfigparser.converttestxml(config_file, xmltext)
            xml = et.ElementTree(et.XML(xmltext))
            
        return self.generate_drop(test_plan, xml, output_file)

    def generate_drop(self, test_plan, xml, output_file):
        """Generate test drop zip file."""
        zfile = zipfile.ZipFile(output_file, "w", zipfile.ZIP_DEFLATED)
        try:
            for drop_file, src_file in self.drop_files(test_plan):
                _logger.info("   + Adding: %s" % src_file.strip())
                try:
                    zfile.write(src_file.strip(), drop_file.encode('utf-8'))
                except OSError, expr:
                    _logger.error(expr)
            doc = amara.parse(et.tostring(xml.getroot(), "ISO-8859-1"))
            _logger.debug("XML output: %s\n" % doc.xml(indent=u"yes", encoding="ISO-8859-1"))
            zfile.writestr("test.xml", doc.xml(indent="yes", encoding="ISO-8859-1"))
        finally:
            zfile.close()

        return zfile

    def generate_xml(self, test_plan):
        """Generate test drop XML."""
        self.defaults = {"enabled": "true", 
                         "passrate": "100", 
                         "significant": "false"}
        root = E("test")
        root.append(et.XML("<name>%(testrun_name)s</name>" % test_plan))
        if test_plan["diamonds_build_url"]:
            root.append(
                et.XML("<buildid>%(diamonds_build_url)s</buildid>" % test_plan))
        generate_target(test_plan, root)
        root.append(self.generate_plan(test_plan))
        for post_action in generate_post_actions(test_plan):
            root.append(post_action)
        root.append(self.generate_files(test_plan))
        etree = et.ElementTree(root)
        return etree
            
    def generate_plan(self, test_plan):
        """Generate the test <plan> with multiple <set>s."""
        plan = E("plan", name="%s Plan" % test_plan["testrun_name"],
                 harness=test_plan["harness"], **self.defaults)
        session = SE(plan, "session", name="session", harness=test_plan["harness"], **self.defaults)

        if not test_plan.custom_dir is None:
            insert_custom_file(session, test_plan.custom_dir.joinpath("preset_custom.xml"))
        
        # One set for each component.
        for setd in test_plan.sets:
            self.drop_path = self.drop_path_root.joinpath(setd["name"])
            elem = SE(session, "set", name=setd["name"]+"-"+setd["component_path"], harness=setd["test_harness"], **self.defaults)
            SE(SE(elem, "target"), "device", rank="master", alias="DEFAULT_%s" % setd["test_harness"])
             
            if not test_plan.custom_dir is None:
                insert_custom_file(elem, test_plan.custom_dir.joinpath("precase_custom.xml"))
        
            case = SE(elem, "case", name="%s case" % setd["name"],
                      harness=setd["test_harness"], **self.defaults)
            self.generate_steps(setd, case, test_plan)
            if not test_plan.custom_dir is None:
                insert_custom_file(elem, test_plan.custom_dir.joinpath("postcase_custom.xml"))

        if not test_plan.custom_dir is None:
            insert_custom_file(session, test_plan.custom_dir.joinpath("postset_custom.xml"))

        return plan

    def generate_steps_logdir(self, setd, case):
        """generates STIF log dir."""
        
        _qt_test_ = self.check_qt_harness(setd)
        if _qt_test_:
            step = SE(case, "step", name="Create QT log dir", harness=setd["test_harness"], **self.defaults)
        else:
            step = SE(case, "step", name="Create %s log dir" % setd["test_harness"], harness=setd["test_harness"], **self.defaults)
        SE(step, "command").text = "makedir"
        if setd["test_harness"] == "STIF":
            SE(SE(step, "params"), "param", dir=self.STIF_LOG_DIR)
        if setd["test_harness"] == "GENERIC":
            if self.check_mtf_harness(setd):
                SE(SE(step, "params"), "param", dir=self.MTF_LOG_DIR)
            else:
                SE(SE(step, "params"), "param", dir=self.TEF_LOG_DIR)
        elif setd["test_harness"] == "EUNIT":
            if _qt_test_:
                SE(SE(step, "params"), "param", dir=self.QT_LOG_DIR)
            else: 
                SE(SE(step, "params"), "param", dir=self.EUNIT_LOG_DIR)
                
        elif setd["test_harness"] == "STIFUNIT":
            SE(SE(step, "params"), "param", dir=self.STIFUNIT_LOG_DIR)
            
        if setd.has_key("sis_files") and setd["sis_files"]:
            setd = dict(setd, src_dst=[]) # Added to pass the Sis tests, if removed - gives KeyError
            for sis_file in setd["sis_files"]:
                self.generate_install_step(case, "sis", sis_file.name, "sis", 
                                           r"c:" + os.sep + "testframework", setd["test_harness"])
        else:
            if setd["src_dst"] != []:
                self.generate_install_step(case, "", "", 
                                               "", r"", setd["test_harness"], setd["src_dst"])
            else:
                # Data file install.
                for data_file in setd["data_files"]:                                
                    self.generate_install_step(case, "data", data_file.name, "data", 
                                               r"e:\testing\data", setd["test_harness"])

                # Configuration file install.
                for conf_file in setd["config_files"]:
                    self.generate_install_step(case, "conf", conf_file.name, "conf", 
                                               r"e:\testing\conf", setd["test_harness"])

                # Test module install.
                for test_file in setd["testmodule_files"]:
                    self.generate_install_step(case, "testmodule", test_file.name, 
                                               "testmodules", r"c:\sys\bin", setd["test_harness"]) 
        return setd

    def generate_steps_engineini(self, setd, case):
        """Engine ini install ( if one exists )"""
        if setd.has_key("sis_files") and setd["sis_files"]:
            self.generate_install_step(case, "engine_ini",
                                       setd["engine_ini_file"].name,
                                       "init",
                                       r"c:" + os.sep + "testframework", setd["test_harness"])
        else:
            if setd["src_dst"] == []:
                self.generate_install_step(case, "engine_ini",
                                       setd["engine_ini_file"].name,
                                       "init",
                                       r"c:" + os.sep + "testframework", setd["test_harness"])

    def generate_steps_sisfiles(self, setd, case, test_plan):
        """generating steps for sis files"""
        for sis_file in setd["sis_files"]:
            step = SE(case, "step", name="Install SIS to the device: %s" % \
                      sis_file.name, harness=setd["test_harness"], **self.defaults)
            SE(step, "command").text = "install-software"
            params = SE(step, "params")
            sis_name = path(r"c:" + os.sep + "testframework").joinpath(sis_file.name)
            for key, value in (("timeout", test_plan["test_timeout"]),
                               ("overWriteAllowed", "true"),
                               ("upgradeData", "true"),
                               ("downloadAllowed", "false"),
                               ("packageInfoAllowed", "true"),
                               ("untrustedAllowed", "true"),
                               ("ignoreOCSPWarnings", "true"),
                               ("userCapGranted", "true"),
                               ("optionalItemsAllowed", "true"),
                               ("killApp", "true"),
                               ("installDrive", "C"),
                               ("upgradeAllowed", "true"),
                               ("OCSP_Done", "true"),
                               ("sisPackageName", sis_name.normpath())):
                SE(params, "param").set(key, value)

    def generate_steps_tracestart(self, setd, case, pmds):
        """Tracing steps are added (Trace Start)"""
        step = SE(case, "step", 
                  name="Start tracing", harness=setd["test_harness"],
                  **self.defaults)
        SE(step, "command").text = "trace-start"
        params = SE(step, "params")
        if setd.has_key("trace_activation_files") and setd["trace_activation_files"]:
            #find out the group to activate
            trace_group = et.parse(setd["trace_activation_files"][0]).getroot().find("Configurations").find("TraceActivation").find("Configuration").get("Name")
            SE(params, "param", ta=self.drop_path.joinpath(r"trace_activation", setd["trace_activation_files"][0].name)) 
            SE(params, "param", tgrp=trace_group )                                            
        if setd.has_key("pmd_files") and setd["pmd_files"]:
            SE(params, "param", pmd=pmds.joinpath(setd["pmd_files"][0].name))
        SE(params, "param", log=setd["trace_path"])            
        SE(params, "param", timeout="60")
        elem = SE(params, "param")
        elem.set('date-format', "yyyyMMdd")
        elem = SE(params, "param")
        elem.set('time-format', "HHmmss")

    def generate_steps_createstep(self, setd, case, test_plan):
        """generates core steps for a single set"""
        if setd["test_harness"] == "STIF" or setd["test_harness"] == "STIFUNIT" or setd["test_harness"] == "GENERIC":
            if setd["src_dst"] == []:
                # Test case execution. If ini file exists, use that
                if setd["engine_ini_file"] != None:
                    step = SE(case, "step", 
                              name="Execute test: %s" % setd["engine_ini_file"].name, 
                              harness=setd["test_harness"], **self.defaults)
                    SE(step, "command").text = "run-cases"
                    params = SE(step, "params")
                    SE(params, "param", filter="*")
                    SE(params, "param", timeout=test_plan["test_timeout"])
                    ini_name = setd["engine_ini_file"].name
                    SE(params, "param", engineini=path(r"c:" + os.sep + "testframework") / ini_name)            
                    
                # if no inifile, but cfg files defined, use those
                elif setd["config_files"]!=[]:
                    for config_file in setd["config_files"]:
                        step = SE(case, "step", 
                                  name="Execute test: %s" % config_file.name, 
                                  harness=setd["test_harness"], **self.defaults)
                        SE(step, "command").text = "run-cases"
                        params = SE(step, "params")
                        SE(params, "param", module="TESTSCRIPTER")
                        elem = SE(params, "param" )
                        elem.set('testcase-file', path(r"e:\testing\conf") / config_file.name )
                        SE(params, "param", filter="*")
                        SE(params, "param", timeout=test_plan["test_timeout"])

                # if no ini or cfg files, use dll directly
                else:
                    for testmodule_file in setd["testmodule_files"]:
                        step = SE(case, "step", 
                                  name="Execute test: %s" %  testmodule_file.name, harness=setd["test_harness"], 
                                  **self.defaults)
                        SE(step, "command").text = "run-cases"
                        params = SE(step, "params")
                        SE(params, "param", module=testmodule_file.name)
                        SE(params, "param", filter="*")
                        SE(params, "param", timeout=test_plan["test_timeout"])
            elif setd["src_dst"] != []:
                self.generate_run_steps(case, setd, test_plan["test_timeout"], test_plan["eunitexerunner_flags"])
        elif setd["test_harness"] == "EUNIT":
            self.generate_run_steps(case, setd, test_plan["test_timeout"], test_plan["eunitexerunner_flags"])

    def generate_steps_tracestop(self, setd, case, pmds):
        """Tracing steps are added (Trace Stop)"""
        step = SE(case, "step", name="Stop tracing",
                  harness=setd["test_harness"], **self.defaults)        
        SE(step, "command").text = "trace-stop"
        params = SE(step, "params")
        SE(params, "param", timeout="60")

        step = SE(case, "step", name="Convert tracing",
                  harness=setd["test_harness"], **self.defaults)        
        SE(step, "command").text = "trace-convert"
        params = SE(step, "params")
        if setd.has_key("pmd_files") and setd["pmd_files"]:
            SE(params, "param", pmd=pmds.joinpath(setd["pmd_files"][0].name))
        SE(params, "param", log=setd["trace_path"])            
        SE(params, "param", timeout="60")
        elem = SE(params, "param")
        elem.set('date-format', "yyyyMMdd")
        elem = SE(params, "param")
        elem.set('time-format', "HHmmss")

    def generate_steps_ctcdata(self, setd, case, test_plan):
        """generates steps for installing CTC data"""
        global CTC_PATHS_LIST
        ctc_helium_path_list = []
        
        step = SE(case, "step", name="Save CTC data", harness=setd["test_harness"], **self.defaults)
        SE(step, "command").text = "execute"
        params = SE(step, "params")
        SE(params, "param", parameters="writelocal")
        SE(params, "param", file=path(r"z:\sys\bin\ctcman.exe"))
        step = SE(case, "step", name="Save CTC data", harness=setd["test_harness"], **self.defaults)
        SE(step, "command").text = "execute"
        params = SE(step, "params")
        SE(params, "param", parameters="writefile")
        SE(params, "param", file=path(r"z:\sys\bin\ctcman.exe"))
            
        if test_plan["ctc_run_process_params"].strip() != "":
            #preparing local-path for CTC step
            #getting '39865' as diamonds ID out of 'http://diamonds.nmp.nokia.com/diamonds/builds/39865/'
            if test_plan["diamonds_build_url"].rfind("/", 0):
                diamonds_id = test_plan["diamonds_build_url"].rsplit(r"/", 2)[1]
            else:
                diamonds_id = test_plan["diamonds_build_url"].rsplit(r"/", 1)[1]
            
            #separating network id and drop number from 10.11.3.2\share#ats\drop2.zip#3
            #'drop2' from the other part of the string conjuncted with a # sign
            ats_network = r"\\" + test_plan["ctc_run_process_params"].rsplit("#", 2)[0] #network host
            temp_drop_id = path(test_plan["ctc_run_process_params"].rsplit("#", 2)[1].rsplit(".", 1)[0]).normpath() #drop ID
            if atssep in temp_drop_id:
                drop_id = temp_drop_id.rsplit(atssep, 1)[1]
            else:
                drop_id = temp_drop_id

            ats_network_path = atspath.join(ats_network, "ctc_helium" , diamonds_id, drop_id, setd["name"], "ctcdata")
            ctc_helium_path_list.append(ats_network_path)
            
            step = SE(case, "step", name="Fetch CTC data for post commands execution", harness=setd["test_harness"], **self.defaults)
            SE(step, "command").text = "fetch-log"
            params = SE(step, "params")
            SE(params, "param", delete="false")
            elem = SE(params, "param")
            elem.set('local-path', ats_network_path)
            SE(params, "param", path=path(self.CTC_LOG_DIR).joinpath(r"ctcdata.txt"))

            CTC_PATHS_LIST += ctc_helium_path_list #creating list of ctcdata.txt files for runProcess postaction
        
        step = SE(case, "step", name="Fetch and clean CTC data", harness=setd["test_harness"], **self.defaults)
        SE(step, "command").text = "fetch-log"
        params = SE(step, "params")
        SE(params, "param", delete="true")
        SE(params, "param", path=path(self.CTC_LOG_DIR).joinpath(r"ctcdata.txt"))
        
    def generate_steps_logfetching(self, setd, case):
        """generates steps for fetching log file"""
        step = SE(case, "step", name="Fetch test module logs", harness=setd["test_harness"], **self.defaults)
        SE(step, "command").text = "fetch-log"
        params = SE(step, "params")
        SE(params, "param", type="text")
        SE(params, "param", delete="true")
        if setd["test_harness"] == "STIF":
            SE(params, "param", path=path(self.STIF_LOG_DIR).joinpath(r"*"))
        if setd["test_harness"] == "GENERIC":
            if self.check_mtf_harness(setd):
                SE(params, "param", path=path(self.MTF_LOG_DIR).joinpath(r"*"))
            else:
                SE(params, "param", path=path(self.TEF_LOG_DIR).joinpath(r"*"))
        elif setd["test_harness"] == "STIFUNIT":
            SE(params, "param", path=path(self.STIFUNIT_LOG_DIR).joinpath(r"*"))
        elif setd["test_harness"] == "EUNIT":
            if self.check_qt_harness(setd):
                SE(params, "param", path=path(self.QT_LOG_DIR).joinpath(r"*"))
            else:
                SE(params, "param", path=path(self.EUNIT_LOG_DIR).joinpath(r"*"))

    
    def get_sorted_images(self, setd):
        """sort the images """
        sorted_images = []
        for image_file in setd["image_files"]:
            if 'core' in image_file.name:
                sorted_images.append(image_file.name)
        for image_file in setd["image_files"]:
            if 'rofs2' in image_file.name:
                sorted_images.append(image_file.name)
        for image_file in setd["image_files"]:
            if 'rofs3' in image_file.name:
                sorted_images.append(image_file.name)
        for image_file in setd["image_files"]:
            if 'core' not in image_file.name and 'rofs2' not in image_file.name and 'rofs3' not in image_file.name:
                sorted_images.append(image_file.name)
        if "rofs" in sorted_images[0]:
            return setd["image_files"]
        return sorted_images
    
    def generate_steps(self, setd, case, test_plan):
        """Generate the test plan <step>s."""
        # Flash images.
        images = self.drop_path_root.joinpath("images")
        pmds = self.drop_path_root.joinpath("pmds")
        
        sorted_images = self.get_sorted_images(setd)
        for image_file in sorted_images:
            flash = SE(case, "flash", images=images.joinpath(image_file))
            flash.set("target-alias", "DEFAULT_%s" % setd["test_harness"])
            
        if setd['custom_dir']:
            insert_custom_file(case, os.path.join(setd['custom_dir'], "prestep_custom.xml"))

        if setd["ctc_enabled"] == "True":
            step = SE(case, "step", name="Create CTC log dir", harness=setd["test_harness"], **self.defaults)
            SE(step, "command").text = "makedir"
            params = SE(step, "params")
            SE(params, "param", dir=self.CTC_LOG_DIR)
            step = SE(case, "step", name="CTC start", harness=setd["test_harness"], **self.defaults)
            SE(step, "command").text = "execute"
            params = SE(step, "params")
            SE(params, "param", file=path(r"z:\sys\bin\ctcman.exe"))
            
        # STIF log dir.
        setd = self.generate_steps_logdir(setd, case)

        # Engine ini install ( if one exists )
        if setd["engine_ini_file"] != None:
            self.generate_steps_engineini(setd, case)
        
        #If sis files
        if setd.has_key("sis_files") and setd["sis_files"]:
            self.generate_steps_sisfiles(setd, case, test_plan)    

        # If tracing enabled, Start Tracing:
        if setd.has_key("trace_path") and setd["trace_path"] != "":
            self.generate_steps_tracestart(setd, case, pmds)

        #core steps of a step

        if setd['custom_dir']:
            insert_custom_file(case, os.path.join(setd['custom_dir'], "prerun_custom.xml"))
        self.generate_steps_createstep(setd, case, test_plan)

        if setd['custom_dir']:
            insert_custom_file(case, os.path.join(setd['custom_dir'], "postrun_custom.xml"))
        
        # If tracing enabled, Stop Tracing
        if setd.has_key("trace_path") and setd["trace_path"] != "":
            self.generate_steps_tracestop(setd, case, pmds)

        #install CTC data
        if setd["ctc_enabled"] == "True":
            self.generate_steps_ctcdata(setd, case, test_plan)
            
        # Log file fetching.
        self.generate_steps_logfetching(setd, case)

        if setd['custom_dir']:
            insert_custom_file(case, os.path.join(setd['custom_dir'], "poststep_custom.xml"))


    def generate_runsteps_tef(self, setd, case, src_dst, time_out):
        """generates runsteps for tef"""
        for file1 in src_dst:
            if 'testscript' in file1[2]:
                filename = file1[1]
                filename = filename[file1[1].rfind(os.sep)+1:]
                harness = "testexecute.exe"
                if file1[2] == "testscript:mtf":
                    harness = "testframework.exe"
                step = SE(case, "step", 
                              name="Execute test: %s" %  filename, harness=setd["test_harness"], 
                              **self.defaults)
                SE(step, "command").text = "execute"
                params = SE(step, "params")
                SE(params, "param", file=harness)
                SE(params, "param", parameters=file1[1])
                
                if file1[2] == "testscript:mtf":
                    SE(params, "param", {'result-file': self.MTF_LOG_DIR + os.sep + filename.replace('.script', '.htm')})
                else:
                    SE(params, "param", {'result-file': self.TEF_LOG_DIR + os.sep + filename.replace('.script', '.htm')})
                SE(params, "param", timeout=time_out)
                if file1[2] == "testscript:mtf":
                    SE(params, "param", parser="MTFResultParser")
                else:
                    SE(params, "param", parser="TEFTestResultParser")
            if file1[2] == 'testmodule:rtest':
                filename = file1[1]
                filename = filename[file1[1].rfind(os.sep)+1:]
                step = SE(case, "step", 
                              name="Execute test: %s" %  filename, harness=setd["test_harness"], 
                              **self.defaults)
                SE(step, "command").text = "execute"
                params = SE(step, "params")
                SE(params, "param", file=file1[1])
                SE(params, "param", {'result-file': self.TEF_LOG_DIR + os.sep + filename.replace(filename.split(".")[-1], 'htm')})
                SE(params, "param", timeout=time_out)
                SE(params, "param", parser="RTestResultParser")
    
    def generate_runsteps_stif(self, setd, case, src_dst, time_out):
        """generates runsteps for stif"""
        ini = cfg = dll = has_tf_ini = False
        ini_file = None
        cfg_files = dll_files = []

        for tf_ini in src_dst:
            if "testframework.ini" in tf_ini[1].lower():
                has_tf_ini = True
        
        for file1 in src_dst:
                
            if "testframework.ini" in file1[1].lower() and file1[2] == "engine_ini" and has_tf_ini:
                ini = True
                ini_file = file1
                
            elif file1[2] == "engine_ini" and not has_tf_ini:
                pipe_ini = open(file1[0], 'r')
                if "[engine_defaults]" in str(pipe_ini.readlines()).lower():
                    ini = True
                    ini_file = file1
            elif file1[2] == "conf":
                if not ini:
                    cfg = True
                    cfg_files.append(file1)
            elif file1[2] == "testmodule":
                if not cfg and not ini:
                    dll = True
                    dll_files.append(file1)
        if ini:
            filename = ini_file[1]
            filename = filename[ini_file[1].rfind(os.sep)+1:]
            step = SE(case, "step",
                      name="Execute test: %s" % filename, 
                      harness=setd["test_harness"], **self.defaults)
            SE(step, "command").text = "run-cases"
            params = SE(step, "params")
            SE(params, "param", filter="*")
            SE(params, "param", timeout=time_out)
            SE(params, "param", engineini=ini_file[1]) 
        elif cfg:
            for conf_file in cfg_files:
                if ".dll" in conf_file[1].lower():
                    continue
                filename = conf_file[1]
                filename = filename[conf_file[1].rfind(os.sep)+1:]
                step = SE(case, "step", 
                              name="Execute test: %s" % filename, 
                              harness=setd["test_harness"], **self.defaults)
                SE(step, "command").text = "run-cases"
                params = SE(step, "params")
                SE(params, "param", module="TESTSCRIPTER")
                elem = SE(params, "param" )
                elem.set('testcase-file', conf_file[1] )
                SE(params, "param", filter="*")
                SE(params, "param", timeout=time_out)
        elif dll:
            for dll_file in dll_files:
                filename = dll_file[1]
                filename = filename[dll_file[1].rfind(os.sep)+1:]
                step = SE(case, "step", 
                              name="Execute test: %s" %  filename, harness=setd["test_harness"], 
                              **self.defaults)
                SE(step, "command").text = "run-cases"
                params = SE(step, "params")
                SE(params, "param", module=filename)
                SE(params, "param", filter="*")
                SE(params, "param", timeout=time_out)

    def generate_runsteps_eunit(self, setd, case, src_dst, time_out, eunit_flags):
        """generates runsteps for eunit"""

        for sdst in src_dst:
            if "." in sdst[1]:
                fileextension = sdst[1].rsplit(".")[1].lower()
            filename = sdst[1]
            filename = filename[filename.rfind(os.sep)+1:]
            if fileextension == "dll" or fileextension == "exe":
                re_dll = re.compile(r'[.]+%s' % fileextension, re.IGNORECASE)
                no_dll = re_dll.sub('', filename)
                no_dll_xml = ''.join([no_dll, u'_log.xml'])


            
            #for EUnit or other executables
            if sdst[2] == "testmodule":
                eunit_exe = "EUNITEXERUNNER.EXE"
                if re_dll.search(filename):                    
                    step = SE(case, "step", name = "Execute test: %s" % filename, harness=setd["test_harness"],
                              **self.defaults)
                    SE(step, "command").text = "execute"
                    params = SE(step, "params")
                    SE(params, "param", file=path(r"z:" + os.sep + "sys" + os.sep + "bin") / eunit_exe)
                    elem = SE(params, "param")
                    elem.set('result-file', path(self.EUNIT_LOG_DIR) / no_dll_xml)
                    SE(params, "param", parameters="%s /F %s /l xml %s" % (eunit_flags, no_dll, filename))
                    SE(params, "param", timeout=time_out)
            
            #for QtTest.lib executables
            elif sdst[2] == "testmodule:qt":
                step = SE(case, "step", name = "Execute Qt-test: %s" % filename, harness=setd["test_harness"],
                          **self.defaults)
                SE(step, "command").text = "execute"
                params = SE(step, "params")
                SE(params, "param", file=path(sdst[1]))
                SE(params, "param", parameters=r"-lightxml -o %s\%s" % (path(self.QT_LOG_DIR),  no_dll_xml))
                elem = SE(params, "param")
                elem.set('result-file', path(self.QT_LOG_DIR) / no_dll_xml)
                SE(params, "param", parser="QTestResultParser")
                elem = SE(params, "param")
                elem.set('delete-result',"true")
                SE(params, "param", async="false")
                SE(params, "param", timeout=time_out)

                

    def generate_run_steps(self, case, setd, time_out, eunit_flags):
        """Generates run-steps"""
        src_dst = setd["src_dst"]
              
        if setd["test_harness"] == "STIF":
            self.generate_runsteps_stif(setd, case, src_dst, time_out)
        if setd["test_harness"] == "GENERIC":
            self.generate_runsteps_tef(setd, case, src_dst, time_out)
        if setd["test_harness"] == "STIFUNIT":
            self.generate_runsteps_stif(setd, case, src_dst, time_out)
            
        if setd["test_harness"] == "EUNIT":
            self.generate_runsteps_eunit(setd, case, src_dst, time_out, eunit_flags)

    def generate_install_step(self, case, step_type, filename, src_dir, 
                              dst_dir, case_harness, src_dst=None):
        """Generate install <step>."""
        if src_dst == None or src_dst == []:
            src_dst = []
            step = SE(case, "step", name="Install %s: %s" % (step_type, filename), 
                      harness=case_harness, **self.defaults)
            SE(step, "command").text = "install"
            params = SE(step, "params")
            SE(params, "param", src=self.drop_path.joinpath(src_dir, filename))
            SE(params, "param", dst=path(dst_dir).joinpath(filename))
        else:
            for sdst in src_dst:
                dst = sdst[1]
                type_ = sdst[2]
                if "testmodule" in type_ or ".dll" in dst:
                    src_dir = dst.replace(":","")
                    src_dir = path(src_dir[:src_dir.rfind(os.sep)])
                    step_type = type_
                    filename = dst[dst.rfind(os.sep)+1:]
                    step = SE(case, "step", name="Install %s: %s" % (step_type, filename), 
                              harness=case_harness, **self.defaults)
                    SE(step, "command").text = "install"
                    params = SE(step, "params")
                    SE(params, "param", src=self.drop_path.joinpath(src_dir, filename))
                    SE(params, "param", dst=path(dst))
            for sdst in src_dst:
                dst = sdst[1]
                type_ = sdst[2]
                if "testmodule" not in type_ and ".dll" not in dst:
                    src_dir = dst.replace(":","")
                    src_dir = path(src_dir[:src_dir.rfind(os.sep)])
                    step_type = type_
                    filename = dst[dst.rfind(os.sep)+1:]
                    step = SE(case, "step", name="Install %s: %s" % (step_type, filename), 
                              harness=case_harness, **self.defaults)
                    SE(step, "command").text = "install"
                    params = SE(step, "params")
                    SE(params, "param", src=self.drop_path.joinpath(src_dir, filename))
                    SE(params, "param", dst=path(dst))

    def drop_files(self, test_plan):
        """Yield a list of drop files."""
        drop_set = set()
        drop_files = []
        pkg_files = []
        for setd in test_plan.sets:
            drop_path = self.drop_path_root.joinpath(setd["name"])
            if setd.has_key("sis_files") and setd["sis_files"]:
                if setd.has_key("pmd_files") and setd["pmd_files"]:
                    drop_files = ((drop_path.parent, "images", setd["image_files"]),
                                  (drop_path.parent, "pmds", setd["pmd_files"]),
                                  (drop_path, "sis", setd["sis_files"]),
                                  (drop_path, "init", [setd["engine_ini_file"]]),
                                  (drop_path, "trace_init", setd["trace_activation_files"]))
                else:
                    drop_files = ((drop_path.parent, "images", setd["image_files"]),
                                  (drop_path, "sis", setd["sis_files"]),
                                  (drop_path, "init", [setd["engine_ini_file"]]))
            elif setd["src_dst"] == []:
                if setd.has_key("pmd_files") and setd["pmd_files"]:
                    drop_files = ((drop_path.parent, "images", setd["image_files"]),
                                  (drop_path.parent, "pmds", setd["pmd_files"]),
                                  (drop_path, "data", setd["data_files"]),
                                  (drop_path, "conf", setd["config_files"]),
                                  (drop_path, "testmodules", setd["testmodule_files"]),
                                  (drop_path, "init", [setd["engine_ini_file"]]),
                                  (drop_path, "trace_init", setd["trace_activation_files"]))
                else:
                    drop_files = ((drop_path.parent, "images", setd["image_files"]),
                                  (drop_path, "data", setd["data_files"]),
                                  (drop_path, "conf", setd["config_files"]),
                                  (drop_path, "testmodules", setd["testmodule_files"]),
                                  (drop_path, "init", [setd["engine_ini_file"]]))
            elif setd["src_dst"] != []:
                for x_temp in setd["src_dst"]:
                    src = x_temp[0]
                    dst = x_temp[1]
                    dst2 = dst.replace(":","")
                    pkg_files.append((drop_path, dst2, src))
                if setd.has_key("pmd_files") and setd["pmd_files"]:
                    drop_files = ((drop_path.parent, "images", setd["image_files"]),
                                  (drop_path.parent, "pmds", setd["pmd_files"]),
                                  (drop_path, "trace_init", setd["trace_activation_files"]))
                else:
                    drop_files = ((drop_path.parent, "images", setd["image_files"]),)
            for drop_dir, sub_dir, files in drop_files:
                for file_path in files:
                    if file_path != None:
                        drop_file = drop_dir.joinpath(sub_dir, file_path.name)
                        drop_file = drop_file.normpath()
                        if drop_file not in drop_set:
                            drop_set.add(drop_file)
                            yield (drop_file, file_path.normpath())
            for drop_dir, sub_dir, files in pkg_files:
                drop_file = drop_dir.joinpath(sub_dir.replace('\\', os.sep))
                drop_file = drop_file.normpath()
                file_path = path(files)
                if drop_file not in drop_set:
                    drop_set.add(drop_file)
                    yield (drop_file, file_path.normpath())

    def generate_files(self, test_plan):
        """Generate the <files> section."""
        files_elem = E("files")
        for drop_file, _ in self.drop_files(test_plan):
            SE(files_elem, "file").text = drop_file
        return files_elem
        
    def check_mtf_harness(self, _setd_):
        """check the testscript.mtf file is present"""
        for _srcdst_ in _setd_['src_dst']:
            if _srcdst_[2] == "testscript:mtf":
                return True
        return False

    def check_qt_harness(self, _setd_):
        """ check the QT harness is OK """
        _setd_ = _setd_
        is_qt_test = False
        if _setd_.has_key("sis_files"):
            _dict_key_ = "sis_files"
        else:
            _dict_key_ = "src_dst"
            
        for _srcdst_ in _setd_[_dict_key_]:
            if "testmodule:qt" == _srcdst_[2]:
                is_qt_test = True
        return is_qt_test 

def generate_target(test_plan, root):
    """Generate targets"""
    harness = test_plan["harness"]
    if harness == "MULTI_HARNESS":
        input_targets(test_plan, root, ["STIF", "EUNIT"])
    elif harness == "STIF":
        input_targets(test_plan, root, ["STIF"])
    elif harness == "EUNIT":
        input_targets(test_plan, root, ["EUNIT"])
    elif harness == "STIFUNIT":
        input_targets(test_plan, root, ["STIFUNIT"])
    elif harness == "GENERIC":
        input_targets(test_plan, root, ["GENERIC"])
                
def input_targets(test_plan, root, harness_type):
    """Append target(s) into the XML"""
    target = E("target")
    for har in harness_type:
        device = SE(target, "device", rank="none", alias="DEFAULT_%s" % har)
        SE(device, "property", name="HARNESS", value=har)
        SE(device, "property", name="TYPE", value=test_plan["device_type"])
        if test_plan["device_hwid"] != "":
            SE(device, "property", name="HWID", value=test_plan["device_hwid"])
        if test_plan["trace_enabled"] != "":
            if test_plan["trace_enabled"].lower() == "true":
                SE(device, "property", name="TRACE_ENABLED", value=test_plan["trace_enabled"])
    root.append(target)


def insert_custom_file(xmltree, filename):
    """
    Inserts into the given XML tree the given customization file
    Broken input XML inserts a comment to the XML tree
    """
    try:
        custom_action_file = codecs.open(filename, "r", "iso-8859-15")
        loop = ''
        cust = unicode(custom_action_file.read(1))
        try:
            # try to read the file  and addcharacter by character until the 
            # elementtree is happy and then reset the loop and continue until the file is 
            # completely processed. Known issue: file ending in comment will cause a warning.
            while cust:
                if loop != '' :
                  # if we have something left from the previous try
                    cust = loop + cust
#                _logger.debug("what is cust  \n %s \n" % cust)
                try: 
                    xmltree.append(et.XML(cust.encode("ISO-8859-15")))
                except ExpatError, err:
#                    _logger.debug("Error %s in XML when prosessing file %s \n Line and column refer to section:\n%s\n" % ( err, filename, loop))
                    loop = cust
                else:
                # clear the loop variable 
                    loop = ''
                cust = unicode(custom_action_file.read(1))
        except Exception, err:
            _logger.error("Error %s in XML when prosessing %s\n" % ( err, filename))
            xmltree.append(et.Comment("Error in XML file when prosessing %s\n" % ( filename)))

        if loop != '' :
            # we should have used all the input and cleared loop variable
            _logger.warning("Issues in customization file %s in XML when prosessing issue %s \n Line and column refer to section:\n%s\n" % ( filename, err,  loop))

        custom_action_file.close()
    except IOError, err:
#        _logger.debug("This is for debugging only. Do not treat this as anything else. Anything is OK... The data: %s when prosessing %s\n" % (err, filename))
        pass
    else: 
        _logger.info("Included file %s" % ( filename))

def generate_post_actions(test_plan):
    """Generate post actions."""
    actions = []
    
    if not test_plan.custom_dir is None:
        insert_custom_file(actions, test_plan.custom_dir.joinpath("prepostaction.xml"))
    
    for action_type, parameters in test_plan.post_actions:
        action = E("postAction")
        SE(action, "type").text = action_type
        params = SE(action, "params")
        for name, value in parameters:
            SE(params, "param", name=name, value=value)
        actions.append(action)

    if not test_plan.custom_dir is None:
        insert_custom_file(actions, test_plan.custom_dir.joinpath("postpostaction.xml"))

    return actions


class Ats3TemplateTestDropGenerator(Ats3TestDropGenerator):
    """ATS3 template for test drop generator"""
    STIF_LOG_DIR = r"c:\logs\testframework"
    TEF_LOG_DIR = r"c:\logs\testexecute"
    MTF_LOG_DIR = r"c:\logs\testresults"
    STIFUNIT_LOG_DIR = r"c:\logs\testframework"
    EUNIT_LOG_DIR = r"c:\Shared\EUnit\logs"
    #QT_LOG_DIR = r"c:\private\Qt\logs"
    QT_LOG_DIR = r"c:\shared\EUnit\logs"
    CTC_LOG_DIR = r"c:\data\ctc"

    def stif_init_file(self, src_dst):
        """init the STIF format file"""
        has_tf_ini = False
        ini_file = None

        for tf_ini in src_dst:
            if "testframework.ini" in tf_ini[1].lower():
                has_tf_ini = True
        
        for file1 in src_dst:
            if "testframework.ini" in file1[1].lower() and file1[2] == "engine_ini" and has_tf_ini:
                ini_file = file1
            elif file1[2] == "engine_ini" and not has_tf_ini:
                pipe_ini = open(file1[0], 'r')
                if "[engine_defaults]" in str(pipe_ini.readlines()).lower():
                    ini_file = file1
        return ini_file

    def ctcnetworkpath(self, setd, test_plan):
        """CTC network path handling"""
        #preparing local-path for CTC step
        #getting '39865' as diamonds ID out of 'http://diamonds.nmp.nokia.com/diamonds/builds/39865/'
        if test_plan["diamonds_build_url"].rfind("/", 0):
            diamonds_id = test_plan["diamonds_build_url"].rsplit(r"/", 2)[1]
        else:
            diamonds_id = test_plan["diamonds_build_url"].rsplit(r"/", 1)[1]
        
        #separating network id and drop number from 10.11.3.2\share#ats\drop2.zip#3
        #'drop2' from the other part of the string conjuncted with a # sign
        ats_network = r"\\" + test_plan["ctc_run_process_params"].rsplit("#", 2)[0] #network host
        temp_drop_id = path(test_plan["ctc_run_process_params"].rsplit("#", 2)[1].rsplit(".", 1)[0]).normpath() #drop ID
        if atssep in temp_drop_id:
            drop_id = temp_drop_id.rsplit(atssep, 1)[1]
        else:
            drop_id = temp_drop_id

        return atspath.join(ats_network, "ctc_helium" , diamonds_id, drop_id, setd["name"], "ctcdata")

    def getlogdir(self, setd):
        """ find the logger directory"""
        if setd["test_harness"] == "STIF":
            return self.STIF_LOG_DIR
        elif setd["test_harness"] == "STIFUNIT":
            return self.STIFUNIT_LOG_DIR
        elif setd["test_harness"] == "GENERIC":
            if self.check_mtf_harness(setd):
                return self.MTF_LOG_DIR
            else:
                return self.TEF_LOG_DIR
        elif setd["test_harness"] == "EUNIT":
            if self.check_qt_harness(setd):
                return self.QT_LOG_DIR
            else:
                return self.EUNIT_LOG_DIR

    def generate_xml(self, test_plan):
        """generate the XML"""
        loader = jinja2.ChoiceLoader([jinja2.PackageLoader(__name__, 'templates'), jinja2.FileSystemLoader(test_plan.custom_dir)])
        env = jinja2.Environment(loader=loader)
        template = env.from_string(pkg_resources.resource_string(__name__, 'ats4_template.xml'))# pylint: disable-msg=E1101

        xmltext = template.render(test_plan=test_plan, os=os, atspath=atspath, atsself=self).encode('ISO-8859-1')
        return et.ElementTree(et.XML(xmltext))