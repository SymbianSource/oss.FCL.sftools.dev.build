# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : aste.py 
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

"""ASTE test drop generation."""

# pylint: disable-msg=R0201,R0903,R0902,W0142
#W0142 => * and ** were used
#R* removed during refactoring

from optparse import OptionParser
from xml.etree import ElementTree as et
import logging
import os
import re
import tempfile
import zipfile
import pkg_resources
from path import path # pylint: disable-msg=F0401
import amara
import ntpath as atspath
import jinja2 # pylint: disable-msg=F0401

_logger = logging.getLogger('ats3')

# Shortcuts
E = et.Element
SE = et.SubElement

class Configuration(object):
    """
    ASTE drop generation configuration.
    """
    
    def __init__(self, opts):
        """
        Initialize from optparse configuration options.
        """
        self._opts = opts
        # Customize some attributes from how optparse leaves them.
        self.build_drive = path(self._opts.build_drive)
        self.file_store = path(self._opts.file_store)
        self.flash_images = self.split_paths(self._opts.flash_images)
    
    def split_paths(self, arg, delim=","):
        """
        Split the string by delim, removing extra whitespace.
        """
        return [path(part.strip()) 
                for part in arg.split(delim) if part.strip()]
    
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
    

class AsteTestPlan(object):
    """
    Tells ASTE server what to test and how.
    
    The ASTE test plan from which the test.xml file can be written. The test
    plan requires TestAsset(s) to perform the tests
    """

    EMAIL_SUBJECT = (u"ATS3 report for §RUN_NAME§ §RUN_START_DATE§ "
                     u"§RUN_START_TIME§")
    REPORT_PATH = u"§RUN_NAME§\§RUN_START_DATE§_§RUN_START_TIME§"

    def __init__(self, config):
        self.diamonds_build_url = config.diamonds_build_url
        self.testrun_name = config.testrun_name
        self.harness = "ASTE"
        self.device_type = config.device_type
        self.test_type = config.test_type
        self.device_hwid = config.device_hwid
        self.plan_name = config.plan_name
        self.report_email = config.report_email
        self.file_store = config.file_store
        self.test_timeout = config.test_timeout
        self.testasset_location = config.testasset_location
        self.testasset_caseids = config.testasset_caseids
        self.software_version = config.software_version
        self.device_language = config.device_language
        self.software_release = config.software_release
        self.sets = []
        self.temp_directory = path(tempfile.mkdtemp())

    def insert_set(self, image_files=None, test_timeout=None, ):
        """
        Insert a test set into the test plan.
        """
        if image_files is None:
            image_files = []
        if test_timeout is None:
            test_timeout = []
        test_harness = self.harness
        setd = dict(name="set%d" % len(self.sets), image_files=image_files)
        setd = dict(setd, test_timeout=test_timeout, test_harness=test_harness)
        
        self.sets.append(setd)

    @property
    def post_actions(self):
        """ATS3 and ASTE post actions."""
        actions = []
        report_path = self.file_store.joinpath(self.REPORT_PATH)
        email_action = ("SendEmailAction", 
                        (("subject", self.EMAIL_SUBJECT),
                         ("type", "ATS3_REPORT"),
                         ("send-files", "true"),
                         ("to", self.report_email)))
        ats3_report = ("FileStoreAction", 
                       (("to-folder", report_path.joinpath("ATS3_REPORT")),
                        ("report-type", "ATS_REPORT"),
                        ("date-format", "yyyyMMdd"),
                        ("time-format", "HHmmss")))
        aste_report = ("FileStoreAction", 
                       (("to-folder", report_path.joinpath("ASTE_REPORT")),
                        ("report-type", "ASTE_REPORT"),
                        ("run-log", "true"),
                        ("date-format", "yyyyMMdd"),
                        ("time-format", "HHmmss")))

        diamonds_action = ("DiamondsAction", ())
        if self.report_email:
            actions.append(email_action)
        if self.file_store:
            actions.append(ats3_report)
            actions.append(aste_report)
        if self.diamonds_build_url:
            actions.append(diamonds_action)
        return actions               

    def __getitem__(self, key):
        return self.__dict__[key]



class AsteTestDropGenerator(object):
    """
    Generate test drop zip file for ATS3.

    Generates drop zip files file from a TestPlan instance. The main
    responsibility of this class is to serialize the plan into a valid XML
    file and build a zip file for the drop.
    
    Creates one <set> for ASTE tests.

    ASTE harness, normal operation
    ------------------------------
    
    - create logging dir for aste             makedir (to C:\logs\TestFramework)
    - execute asset from the testasset.zip    execute-asset
    - fetch logs                              fetch-log

    """

    ASTE_LOG_DIR = r"c:\logs\testframework"

    def __init__(self):
        self.drop_path_root = path("ATS3Drop")
        self.drop_path = None
        self.defaults = {}

    def generate(self, test_plan, output_file):
        """Generate a test drop file."""
        xml = self.generate_xml(test_plan)
        return self.generate_drop(test_plan, xml, output_file)

    def generate_drop(self, test_plan, xml, output_file):
        """Generate test drop zip file."""
        zfile = zipfile.ZipFile(output_file, "w", zipfile.ZIP_DEFLATED)
        try:
            for drop_file, src_file in self.drop_files(test_plan):
                _logger.info("   + Adding: %s" % src_file.strip())
                zfile.write(src_file.strip(), drop_file.encode('utf-8'))
            doc = amara.parse(et.tostring(xml.getroot()))
            _logger.debug("XML output: %s" % doc.xml(indent=u"yes"))
            zfile.writestr("test.xml", doc.xml(indent="yes"))
        finally:
            zfile.close()
        return zfile

    def generate_xml(self, test_plan):
        """Generate test drop XML."""
        self.defaults = {"enabled": "true", 
                         "passrate": "100", 
                         "significant": "false",
                         "harness": "%s" % test_plan["harness"]} 
        root = E("test")
        root.append(et.XML("<name>%(testrun_name)s</name>" % test_plan))
        if test_plan["diamonds_build_url"]:
            root.append(
                et.XML("<buildid>%(diamonds_build_url)s</buildid>" % test_plan))
        self.generate_target(test_plan, root)
        root.append(self.generate_plan(test_plan))
        for post_action in self.generate_post_actions(test_plan):
            root.append(post_action)
        root.append(self.generate_files(test_plan))
        etree = et.ElementTree(root)
        return etree

    def generate_target(self, test_plan, root):
        """Append target(s) into the XML"""
        target = E("target")
        device = SE(target, "device", rank="none", alias="DEFAULT")
        SE(device, "property", name="harness", value=test_plan["harness"])
        SE(device, "property", name="hardware", value=test_plan["device_type"])
        SE(device, "setting", name="softwareVersion", value=test_plan["software_version"])
        SE(device, "setting", name="softwareRelease", value=test_plan["software_release"])
        SE(device, "setting", name="language", value=test_plan["device_language"])
        
        if test_plan["device_hwid"] != "":
            SE(device, "property", name="HWID", value=test_plan["device_hwid"])
        root.append(target)
                    
    def generate_plan(self, test_plan):
        """Generate the test <plan> with multiple <set>s."""
        plan = E("plan", name="Plan %s %s" % (test_plan["test_type"], test_plan["device_type"]), **self.defaults)
        session = SE(plan, "session", name="session", **self.defaults)
        # One set for each component.
        for setd in test_plan.sets:
            self.drop_path = self.drop_path_root.joinpath(setd["name"])
            elem = SE(session, "set", name=setd["name"], **self.defaults)
            SE(SE(elem, "target"), "device", rank="master", alias="DEFAULT")
            case = SE(elem, "case", name="%s case" % setd["name"], **self.defaults)
            self.generate_steps(setd, case, test_plan)
        return plan

    def generate_steps(self, setd, case, test_plan):
        """Generate the test plan <step>s."""
        # Flash images.
        images = self.drop_path_root.joinpath("images")
        for image_file in setd["image_files"]:
            flash = SE(case, "flash", images=images.joinpath(image_file.name))
            flash.set("target-alias", "DEFAULT")

        # If tracing enabled:
        self.generate_execute_asset_steps(case, test_plan)

    def generate_execute_asset_steps(self, case, test_plan):
        """Executes steps for TestAsset"""
        time_out = test_plan["test_timeout"]
        step = SE(case, "step", 
                      name="Execute asset zip step" , **self.defaults)
        SE(step, "command").text = "execute-asset"
        params = SE(step, "params")
        SE(params, "param", repeat="1")        
        elem = SE(params, "param")
        elem.set("asset-source", path(r"ATS3Drop" + os.sep + "TestAssets" + os.sep + "TestAsset.zip"))
        elem = SE(params, "param")
        elem.set("testcase-ids", test_plan["testasset_caseids"])
        SE(params, "param", timeout=time_out)


    def generate_post_actions(self, test_plan):
        """Generate post actions."""
        actions = []
        for action_type, parameters in test_plan.post_actions:
            action = E("postAction")
            SE(action, "type").text = action_type
            params = SE(action, "params")
            for name, value in parameters:
                SE(params, "param", name=name, value=value)
            actions.append(action)
        return actions

    def generate_testasset_zip(self, test_plan, output_file=None):
        """Generate TestAsset.zip for the ASTE server"""
        filename = test_plan["temp_directory"].joinpath(r"TestAsset.zip")
        if output_file != None:
            filename = output_file
        testasset_location = path(test_plan["testasset_location"])
        if re.search(r"[.]zip", testasset_location):
            return testasset_location
        else:
            zfile = zipfile.ZipFile(filename, "w", zipfile.ZIP_DEFLATED)
            try:
                for file_ in list(testasset_location.walkfiles()):
                    file_mod = file_.replace(testasset_location, "")
                    zfile.write(file_, file_mod.encode('utf-8'))
            finally:
                zfile.close()
            return filename
            
    def drop_files(self, test_plan):
        """Yield a list of drop files."""
        drop_set = set()
        drop_files = []
        zip_file = path(self.generate_testasset_zip(test_plan)) ##check here, I changed the variable name from "zipfile" to "zip_file"
        for setd in test_plan.sets:
            drop_path = self.drop_path_root.joinpath(setd["name"])
            drop_files = ((drop_path.parent, "images", setd["image_files"]),
                          (drop_path.parent, "TestAssets", [zip_file]))
            for drop_dir, sub_dir, files in drop_files:
                for file_path in files:
                    if file_path != None:
                        drop_file = drop_dir.joinpath(sub_dir, file_path.name)
                        drop_file = drop_file.normpath()
                        if drop_file not in drop_set:
                            drop_set.add(drop_file)
                            yield (drop_file, file_path.normpath())
           

    def generate_files(self, test_plan):
        """Generate the <files> section."""
        files_elem = E("files")
        for drop_file, _ in self.drop_files(test_plan):
            SE(files_elem, "file").text = drop_file
        return files_elem


class AsteComponentParser(object):
    """
    Add information to the test_plan
    """
    def __init__(self, config):
        self.flash_images = [path(p) for p in config.flash_images]
        self.build_drive = config.build_drive
        self.test_timeout = config.test_timeout

    def insert_test_set(self, test_plan):
        """Parse flash images and creates inserts into 'sets'"""
        test_plan.insert_set(image_files=self.flash_images,
                             test_timeout=list(self.test_timeout))


class AsteTemplateTestDropGenerator(AsteTestDropGenerator):
    """ ASTE template Drop generator tester"""
    def getlogdir(self, setd):
        """ get the logger directory"""
        setd = setd  #just to fool pylint
        return self.ASTE_LOG_DIR
    
    def aslfiles(self, test_plan):
        """get the list of .asl files"""
        files = []
        
        testasset_location = path(test_plan["testasset_location"])
        for file_ in list(testasset_location.walkfiles()):
            if file_.endswith('.asl'):
                files.append(file_.replace(testasset_location + os.sep, ""))
        return files
    
    def generate_xml(self, test_plan):
        """ generate an XML file"""
        loader = jinja2.ChoiceLoader([jinja2.PackageLoader(__name__, 'templates')])
        env = jinja2.Environment(loader=loader)
        template = env.from_string(pkg_resources.resource_string(__name__, 'aste_template.xml'))# pylint: disable-msg=E1101
        
        xmltext = template.render(test_plan=test_plan, os=os, atspath=atspath, atsself=self).encode('ISO-8859-1')
        return et.ElementTree(et.XML(xmltext))

def create_drop(config):
    """Create a test drop."""    
    _logger.debug("initialize test plan")
    
    test_plan = AsteTestPlan(config)
    parser = AsteComponentParser(config)
    parser.insert_test_set(test_plan) ######check here if something goes wrong, removed ", path(tsrc)"
    if config.ats4_enabled.lower() == 'true':
        generator = AsteTemplateTestDropGenerator()
    else:
        generator = AsteTestDropGenerator()
    _logger.info("generating drop file: %s" % config.drop_file)
    generator.generate(test_plan, output_file=config.drop_file)


def main():
    """Main entry point."""    
    cli = OptionParser(usage="%prog [options] TSRC1 [TSRC2 [TSRC3 ...]]")
    cli.add_option("--build-drive", help="Build area root drive")
    cli.add_option("--device-type", help="Device type (e.g. 'PRODUCT')", 
                   default="unknown")
    cli.add_option("--device-hwid", help="Device hwid", 
                   default="")
    cli.add_option("--diamonds-build-url", help="Diamonds build url")
    cli.add_option("--drop-file", help="Name for the final drop zip file",
                   default="ATS3Drop.zip")
    cli.add_option("--file-store", help="Destination path for reports.",
                   default="")
    cli.add_option("--flash-images", help="Paths to the flash image files",
                   default="")     
    cli.add_option("--minimum-flash-images", help="Minimum amount of flash images",
                   default=2)
    cli.add_option("--report-email", help="Email notification receivers", 
                   default="")
    cli.add_option("--plan-name", help="Name of the test plan", 
                   default="plan")
    cli.add_option("--test-timeout", help="Test execution timeout value (default: %default)",
                   default="60")
    cli.add_option("--testrun-name", help="Name of the test run", 
                   default="run")
    cli.add_option("--testasset-location", help="Path to the ASTE test assets location",
                   default="")     
    cli.add_option("--testasset-caseids", help="Test case IDs to run",
                   default="")     
    cli.add_option("--software-version", help="Sofwtare version",
                   default="")     
    cli.add_option("--test-type", help="Sofwtare version",
                   default="smoke")     
    cli.add_option("--device-language", help="language name e.g. English",
                   default="English")     
    cli.add_option("--software-release", help="Software release or product name e.g. PPD 52.50",
                   default="")     
    cli.add_option("--ats4-enabled", help="ATS4 enabled", default="False")
    cli.add_option("--verbose", help="Increase output verbosity",
                   action="store_true", default=False)

    opts, _ = cli.parse_args()

    if not opts.flash_images:
        cli.error("no flash image files given")
    if len(opts.flash_images.split(",")) < int(opts.minimum_flash_images):
        cli.error("Not enough flash files: %i defined, %i needed" % (len(opts.flash_images.split(",")), int(opts.minimum_flash_images) ))

    if opts.verbose:
        _logger.setLevel(logging.DEBUG)
        logging.basicConfig(level=logging.DEBUG)
    _ = tempfile.mkdtemp()
    config = Configuration(opts)
    create_drop(config)

if __name__ == "__main__":
    main()
