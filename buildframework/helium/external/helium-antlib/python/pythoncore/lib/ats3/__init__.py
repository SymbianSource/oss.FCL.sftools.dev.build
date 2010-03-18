# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : __init__.py 
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

"""ATS3 test drop generation."""

#W0142 => * and ** were used
#R*    => will be fixed while refactoring
#F0401 => pylint didn't find "path" module
#C0302 => Too many lines

from optparse import OptionParser
import ats3.testconfigurator as acp
import ats3.dropgenerator as adg
import logging
import os
import re

import ats3.parsers as parser

from path import path # pylint: disable-msg=F0401

_logger = logging.getLogger('ats')

class Configuration(object):
    """
    ATS3 drop generation configuration.
    """
    def __init__(self, opts, tsrc_paths):
        """
        Initialize from optparse configuration options.
        """
        self._opts = opts
        c_parser = parser.CppParser()
        temp_dict = {}
        pkg_parser = parser.PkgFileParser()
        
        # Customize some attributes from how optparse leaves them.
        self.build_drive = path(self._opts.build_drive)
        self.file_store = path(self._opts.file_store)
        self.flash_images = split_paths(self._opts.flash_images)
        self.sis_files = split_paths(self._opts.sis_files)
        self.config_file = self._opts.config
        self.obey_pkgfiles = to_bool(self._opts.obey_pkgfiles)
        self.specific_pkg = self._opts.specific_pkg
        if self.specific_pkg == '':
            self.specific_pkg = None
        self.tsrc_paths_dict = {}

        ats_nd = self._opts.ctc_run_process_params.strip()
        if ats_nd != "":
            ats_nd = ats_nd.split("#")[0].strip()
            if ats_nd == "":
                self._opts.ctc_run_process_params = ""
                _logger.warning("Property \'ats.ctc.host\' is not set. Code coverage measurement report(s) will not be created.")
                
        main_comps = []
                
        for tsrc in tsrc_paths:
            hrh = os.path.join(self.build_drive + os.sep, 'epoc32', 'include', 'feature_settings.hrh')
            if os.path.exists(hrh):
                temp_dict = c_parser.get_cpp_output(path(tsrc), "d", hrh)
            else:
                temp_dict = c_parser.get_cpp_output(path(tsrc), "d")
            for t_key, t_value in temp_dict.items():
                self.tsrc_paths_dict[t_key] = t_value
        
        #preparing a list of main components
        for main_component in self.tsrc_paths_dict.keys():
            if self.obey_pkgfiles == "True":
                if pkg_parser.get_pkg_files(main_component) != []:
                    main_comps.append(main_component)
            else:
                main_comps.append(main_component)    
                    
                    
        self.tsrc_paths = main_comps

    def __getattr__(self, attr):
        return getattr(self._opts, attr)
    
    def __str__(self):
        dump = "Configuration:\n"
        seen = set()
        for key, value in vars(self).items():
            if not key.startswith("_"):
                dump += "\t%s = %s\n" % (key, value)
                seen.add(key)
        for key, value in vars(self._opts).items():
            if key not in seen:
                dump += "\t%s = %s\n" % (key, value)
                seen.add(key)                
        return dump
    

class Ats3TestPlan(object):
    """
    Tells ATS3 server what to test and how.
    
    The ATS3 test plan from which the test.xml file can be written. The test
    plan captures all the data related to a test run: flashing, installation
    of data files and configuration files, test cases, and the notifications.
    
    """
    EMAIL_SUBJECT = (u"ATS3 report for §RUN_NAME§ §RUN_START_DATE§ "
                     u"§RUN_START_TIME§")
    REPORT_PATH = u"§RUN_NAME§" + os.sep + u"§RUN_START_DATE§_§RUN_START_TIME§"

    def __init__(self, config):
        self.diamonds_build_url = config.diamonds_build_url
        self.ctc_run_process_params = config.ctc_run_process_params
        self.testrun_name = config.testrun_name
        self.harness = config.harness
        self.device_type = config.device_type
        self.device_hwid = config.device_hwid
        self.plan_name = config.plan_name
        self.report_email = config.report_email
        self.file_store = config.file_store
        self.test_timeout = config.test_timeout
        self.eunitexerunner_flags = config.eunitexerunner_flags
        self.sets = []
        self.src_dst = []
        self.pmd_files = []
        self.trace_activation_files = []
        self.trace_enabled = to_bool(config.trace_enabled)
        self.ctc_enabled = to_bool(config.ctc_enabled)
        self.multiset_enabled = to_bool(config.multiset_enabled)
        self.monsym_files = config.monsym_files
        self.component_path = ""
        self.custom_dir = None
    
    def insert_set(self, data_files=None, config_files=None, 
                   engine_ini_file=None,  image_files=None, sis_files=None,
                   testmodule_files=None, test_timeout=None,eunitexerunner_flags=None , test_harness=None,
                   src_dst=None, pmd_files=None, trace_activation_files=None, custom_dir=None, component_path=None):
        """
        Insert a test set into the test plan.
        """
        
        if not custom_dir is None:
            self.custom_dir = custom_dir
        if data_files is None:
            data_files = []
        if config_files is None:
            config_files = []
        if image_files is None:
            image_files = []
        if sis_files is None:
            sis_files = []
        if testmodule_files is None:
            testmodule_files = []
        if test_timeout is None:
            test_timeout = []
        if test_harness is None:
            test_harness = self.harness
        if src_dst is None:
            src_dst = []
        if pmd_files is None:
            pmd_files = []
        if trace_activation_files is None:
            trace_activation_files = []
        if component_path is None:
            component_path = self.component_path
            
        setd = dict(name="set%d" % len(self.sets),
                    image_files=image_files, engine_ini_file=engine_ini_file, ctc_enabled=self.ctc_enabled, component_path=component_path)
        
        setd = dict(setd, custom_dir=custom_dir)
        if sis_files:
            setd = dict(setd, sis_files=sis_files, test_timeout=test_timeout, eunitexerunner_flags=eunitexerunner_flags, test_harness=test_harness, )
        else:
            setd = dict(setd, data_files=data_files, config_files=config_files,
                        testmodule_files=testmodule_files, test_timeout=test_timeout, eunitexerunner_flags=eunitexerunner_flags, test_harness=test_harness,
                        src_dst=src_dst)
        if self.trace_enabled != "":
            if self.trace_enabled.lower() == "true":
                setd = dict(setd, pmd_files=pmd_files, 
                            trace_path=self.file_store.joinpath(self.REPORT_PATH, "traces", setd["name"], "tracelog.blx"),
                            trace_activation_files=trace_activation_files)
            else:
                setd = dict(setd, pmd_files=[], 
                            trace_path="",trace_activation_files=[])
        self.sets.append(setd)

    def set_plan_harness(self):
        """setting up test harness for a plan"""
        eunit = False
        stif = False
        stifunit = False
        for setd in self.sets:
            if setd["test_harness"] == "STIF":
                stif = True
            elif setd["test_harness"] == "EUNIT":
                eunit = True
            elif setd["test_harness"] == "STIFUNIT":
                stifunit = True
                
        if eunit and stif:
            self.harness = "MULTI_HARNESS"
        elif eunit:
            self.harness = "EUNIT"
        elif stif:
            self.harness = "STIF"
        elif stifunit:
            self.harness = "STIFUNIT"
        else:
            self.harness = "GENERIC"

    @property
    def post_actions(self):
        """ATS3 post actions."""
        actions = []
        temp_var = ""
        include_ctc_runprocess = False
        report_path = self.file_store.joinpath(self.REPORT_PATH)
        
        if self.ctc_enabled and adg.CTC_PATHS_LIST != [] and self.monsym_files != "" and not "${" in self.monsym_files:
            include_ctc_runprocess = True
            ctc_params = "--ctcdata_files="
            for cdl in adg.CTC_PATHS_LIST:
                ctc_params += cdl + '\\ctcdata.txt' + ";"
                temp_var = cdl
            
            drop_count = self.ctc_run_process_params.rsplit("#", 1)[1]
            temp_var = temp_var.split("ctc_helium"+os.sep)[1]
            diamonds_id = temp_var.split(os.sep)[0]
            drop_id = temp_var.split(os.sep)[1].split(os.sep)[0]
            drop_id = re.findall(".*drop(\d*)", drop_id.lower())[0] #extracting int part of drop name
           
            ctc_params += r" --monsym_files=" + self.monsym_files
            ctc_params += r" --diamonds_build_id=" + diamonds_id
            ctc_params += r" --drop_id=" + drop_id
            ctc_params += r" --total_amount_of_drops=" + drop_count
            
            runprocess_action = ("RunProcessAction", 
                            (("file", r"catsctc2html/catsctc2html.exe"), #this line will be executing on Windows machine.
                             ("parameters", ctc_params)))
            
            email_url = " CTC report can be found from: " + self.diamonds_build_url

            email_action = ("SendEmailAction", 
                            (("subject", self.EMAIL_SUBJECT),
                             ("type", "ATS3_REPORT"),
                             ("send-files", "true"),
                             ("additional-description", email_url),
                             ("to", self.report_email)))
        else:
            email_action = ("SendEmailAction", 
                            (("subject", self.EMAIL_SUBJECT),
                             ("type", "ATS3_REPORT"),
                             ("send-files", "true"),
                             ("to", self.report_email)))
        ats3_report = ("FileStoreAction", 
                       (("to-folder", report_path.joinpath("ATS3_REPORT")),
                        ("report-type", "ATS3_REPORT"),
                        ("date-format", "yyyyMMdd"),
                        ("time-format", "HHmmss")))
        stif_report = ("FileStoreAction", 
                       (("to-folder", report_path.joinpath("STIF_REPORT")),
                        ("report-type", "STIF_COMPONENT_REPORT_ALL_CASES"),
                        ("run-log", "true"),
                        ("date-format", "yyyyMMdd"),
                        ("time-format", "HHmmss")))
        eunit_report = ("FileStoreAction", 
                       (("to-folder", report_path.joinpath("EUNIT_REPORT")),
                        ("report-type", "EUNIT_COMPONENT_REPORT_ALL_CASES"),
                        ("run-log", "true"),
                        ("date-format", "yyyyMMdd"),
                        ("time-format", "HHmmss")))
        diamonds_action = ("DiamondsAction", ())

        
        if include_ctc_runprocess:
            actions.append(runprocess_action)
            
        if self.diamonds_build_url:
            actions.append(diamonds_action)
        if self.file_store:
            actions.append(ats3_report)
            if self.harness == "STIF":
                actions.append(stif_report)
            elif self.harness == "EUNIT":
                actions.append(eunit_report)
        if self.report_email:
            actions.append(email_action)
        return actions               

    def __getitem__(self, key):
        return self.__dict__[key]

def encode_for_xml(unicode_data, encoding='ascii'):
    """
    Encode unicode_data for use as XML or HTML, with characters outside
    of the encoding converted to XML numeric character references.
    """
    try:
        return unicode_data.encode(encoding, 'xmlcharrefreplace')
    except ValueError:
        # ValueError is raised if there are unencodable chars in the
        # data and the 'xmlcharrefreplace' error handler is not found.
        # Pre-2.3 Python doesn't support the 'xmlcharrefreplace' error
        # handler, so we'll emulate it.
        return _xmlcharref_encode(unicode_data, encoding)

def _xmlcharref_encode(unicode_data, encoding):
    """Emulate Python 2.3's 'xmlcharrefreplace' encoding error handler."""
    chars = []
    # Step through the unicode_data string one character at a time in
    # order to catch unencodable characters:
    for char in unicode_data:
        try:
            chars.append(char.encode(encoding, 'strict'))
        except UnicodeError:
            chars.append('&#%i;' % ord(char))
    return ''.join(chars)


def create_drop(config):
    """Create a test drop."""
    _logger.debug("initialize test plan")
        
    test_plan = Ats3TestPlan(config)
    component_parser = acp.Ats3ComponentParser(config)
    
    for tsrc in config.tsrc_paths:
        lst_check_harness = []
        _logger.info("inspecting tsrc path: %s" % tsrc)
        #checking if there are components without harness
        for sub_component in config.tsrc_paths_dict[tsrc]['content'].keys():
            _harness_ = config.tsrc_paths_dict[tsrc]['content'][sub_component]['harness']
            if _harness_ != "":
                lst_check_harness.append(_harness_)

        #if component has harness then insert to test set 
        if len(lst_check_harness) > 0:
            component_parser.insert_test_set(test_plan, path(tsrc), config.tsrc_paths_dict)

    test_plan.set_plan_harness()


    #Checking if any non executable set exists
    #if yes, delete the set
    tesplan_counter = 0
    for plan_sets in test_plan.sets:
        tesplan_counter += 1
        exe_flag = False
        for srcanddst in plan_sets['src_dst']:
            _ext = srcanddst[0].rsplit(".")[1]
            #the list below are the files which are executable
            #if none exists, set is not executable
            for mat in ["dll", "ini", "cfg", "exe", "script"]:
                if mat == _ext.lower():
                    exe_flag = True
                    break
            if exe_flag: 
                break

        if not exe_flag: #the set does not have executable, deleting the set
            del test_plan.sets[tesplan_counter - 1]
        
    if config.ats4_enabled.lower() == 'true':
        generator = adg.Ats3TemplateTestDropGenerator()
    else:
        generator = adg.Ats3TestDropGenerator()
    _logger.info("generating drop file: %s" % config.drop_file)
    generator.generate(test_plan, output_file=config.drop_file, config_file=config.config_file)

def split_paths(arg, delim=","):
    """
    Split the string by delim, removing extra whitespace.
    """
    return [path(part.strip()) 
            for part in arg.split(delim) if part.strip()]

def to_bool(param):
    """setting a true or false based on a param value"""
    param = str(param).lower()
    if "true" == param or "t" == param or "1" == param:
        return "True"
    else:
        return "False"

def main():
    """Main entry point."""
    cli = OptionParser(usage="%prog [options] TSRC1 [TSRC2 [TSRC3 ...]]")
    cli.add_option("--build-drive", help="Build area root drive")
    cli.add_option("--data-dir", help="Data directory name", action="append", 
                   default=[])
    cli.add_option("--device-type", help="Device type (e.g. 'PRODUCT')", 
                   default="unknown")
    cli.add_option("--device-hwid", help="Device hwid", 
                   default="")
    cli.add_option("--trace-enabled", help="Tracing enabled", default="False")
    cli.add_option("--ctc-enabled", help="CTC enabled", default="False")
    cli.add_option("--multiset-enabled", help="Multiset enabled", default="False")
    cli.add_option("--diamonds-build-url", help="Diamonds build url")
    cli.add_option("--ctc-run-process-params", help="ctc parameters include ctc host, drop id and total number of drops, separated by '#'")
    cli.add_option("--drop-file", help="Name for the final drop zip file",
                   default="ATS3Drop.zip")
    cli.add_option("--file-store", help="Destination path for reports.",
                   default="")
    cli.add_option("--flash-images", help="Paths to the flash image files",
                   default="")     
    cli.add_option("--minimum-flash-images", help="Minimum amount of flash images",
                   default=2)    
    cli.add_option("--harness", help="Test harness (default: %default)",
                   default="")
    cli.add_option("--report-email", help="Email notification receivers", 
                   default="")
    cli.add_option("--plan-name", help="Name of the test plan", 
                   default="plan")
    cli.add_option("--sis-files", help="Paths to the sis files",
                   default="")
    cli.add_option("--monsym-files", help="Paths to MON.sym files, for ctc useage",
                   default="")
    cli.add_option("--target-platform", help="Target platform (default: %default)",
                   default="armv5 urel")
    cli.add_option("--test-timeout", help="Test execution timeout value (default: %default)",
                   default="60")
    cli.add_option("--eunitexerunner-flags", help="Eunitexerunner flags",
                   default="")
    cli.add_option("--testrun-name", help="Name of the test run", 
                   default="run")
    cli.add_option("--config", help="Path to the config file",
                   default="")
    cli.add_option("--specific-pkg", help="Text in name of pkg files to use", default='')
    cli.add_option("--ats4-enabled", help="ATS4 enabled", default="False")
    cli.add_option("--obey-pkgfiles", help="If this option is True, then only test components having PKG file are executable and if the compnents don't have PKG files they will be ignored.", default="False")
    cli.add_option("--verbose", help="Increase output verbosity", 
                   action="store_true", default=False)
    
    opts, tsrc_paths = cli.parse_args()

    if not tsrc_paths:
        cli.error("no tsrc directories given")
    if not opts.flash_images:
        cli.error("no flash image files given")
    if not opts.build_drive:
        cli.error("no build drive given")      
    if len(opts.flash_images.split(",")) < int(opts.minimum_flash_images):
        cli.error("Not enough flash files: %i defined, %i needed" % (len(opts.flash_images.split(",")), int(opts.minimum_flash_images) ))

    if opts.verbose:
        _logger.setLevel(logging.DEBUG)
        logging.basicConfig(level=logging.DEBUG)
    
    config = Configuration(opts, tsrc_paths)
    create_drop(config)


if __name__ == "__main__":
    main()
