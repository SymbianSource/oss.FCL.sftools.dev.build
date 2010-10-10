# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : tdriver.py 
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

"""TDriver test drop generation."""


#W0142 => * and ** were used
#R* removed during refactoring

from optparse import OptionParser
from xml.etree import ElementTree as et
import pkg_resources
from path import path # pylint: disable=F0401
import logging
import os
import re
import tempfile
import zipfile
import amara
import ntpath as atspath
import jinja2 # pylint: disable=F0401
import ats3.parsers

_logger = logging.getLogger('tdriver')

# Shortcuts
E = et.Element
SE = et.SubElement

class Configuration(object):
    """
    TDriver drop generation configuration.
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
        self.tdriver_sis_files = self.split_paths(self._opts.tdriver_sis_files)
        self.test_assets = self.split_paths(self._opts.testasset_location)
        self.template_loc = path(self._opts.template_loc)
        
        
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
    

class TDriverTestPlan(object):
    """ Tells TDriver server what to test and how.
    
    The TDriver test plan from which the test.xml file can be written. The test
    plan requires TestAsset(s) to perform the tests
    """

    def __init__(self, config):
        self.pkg_parser = ats3.parsers.PkgFileParser()
        self.file_store = config.file_store
        self.tdriver_timeout = config.tdriver_timeout
        self.test_profiles = config.test_profiles
        self.tdrunner_enabled = to_bool(config.tdrunner_enabled)
        self.tdrunner_parameters = config.tdrunner_parameters
        self.test_profiles = config.test_profiles.strip().split(",")
        self.build_drive = config.build_drive
        self.tdriver_sis_files = ""
        self.install_files = []
        self.tdriver_task_files = None
        self.ctc_enabled = 'False'
        if hasattr(config, 'ctc_enabled'):
            self.ctc_enabled = to_bool(config.ctc_enabled)

    def insert_execution_block(self, block_count=1, image_files=None, tdriver_sis_files=None, test_asset_path=None, tdriver_parameters=None):
        """
        Insert TDriver tasks and test data files into execution block
        """
        self.tdriver_sis_files = tdriver_sis_files
        temp_sis_files = [] 
        if self.tdriver_sis_files != None:
            for sis_file in self.tdriver_sis_files:
                temp_sis_files.append(sis_file.split("#"))
        
        test_asset_path = test_asset_path
        if image_files is None:
            image_files = []

        exe_dict = dict(name="exe%d" % block_count, asset_path=test_asset_path, image_files=image_files, tdriver_sis_files=temp_sis_files, ctc_enabled=self.ctc_enabled)
        exe_dict = dict(exe_dict, test_timeout=self.tdriver_timeout)
        exe_dict = dict(exe_dict, tdriver_parameters=tdriver_parameters)
        exe_dict = dict(exe_dict, tdrunner_enabled=self.tdrunner_enabled.lower())
        exe_dict = dict(exe_dict, tdrunner_parameters=self.tdrunner_parameters)
        

        self.tdriver_task_files = self._create_tdriver_task_files_list(test_asset_path)
        exe_dict = dict(exe_dict, tdriver_task_files=self.tdriver_task_files)

        self.install_files = self.create_install_files_list(test_asset_path)
        exe_dict = dict(exe_dict, install_files=self.install_files)
        return exe_dict        

    def _create_tdriver_task_files_list(self, asset_path=None):
        """
        Creates list of files needed to include in TDriver execution tasks
        if tdrunner.enabled then 
            profiles (.sip files) are included
        else
            all ruby (.rb) files are included
        """

        profiles = []
        rb_files = []

        #If TDrunner engine is enabled (set to True)
        if self.tdrunner_enabled.lower() == "true":
            profile_path = path(os.path.join(asset_path, "profile"))
            if os.path.exists(profile_path):
                for profile_name in self.test_profiles: 
                    item = list(profile_path.walkfiles("%s.sip"%profile_name.lower().strip()))
                    if len(item) > 0:
                        #profiles.append(os.path.join(profile_path, item[0]))
                        profiles.append(asset_path.rsplit(os.sep, 1)[1] + "/" + "profile" + "/" + item[0].rsplit(os.sep, 1)[1])
                return profiles
            else:
                _logger.warning(profile_path + ' not found')
        else: #If TDruner engine is not enabled (set to False)
            if os.path.exists(asset_path):
                #returns list(asset_path.walkfiles("*.rb")):
                for item in list(asset_path.walkfiles("*.rb")):
                    rb_files.append(asset_path.rsplit(os.sep, 1)[1] + "/" + item.rsplit(os.sep, 1)[1])
                # Sorting the result, so we ensure they are always in similar order.
                rb_files.sort()
                return rb_files
            else:
                _logger.warning(asset_path + ' not found')

    def create_install_files_list(self, asset_path=None):
        """
        Collects all the .pkg files and extract data
        Creates  a list of src, dst files.
        """
        pkg_files = []
        if os.path.exists(asset_path):
            pkg_files =  list(asset_path.walkfiles("*.pkg"))
            return self.pkg_parser.get_data_files(pkg_files, self.build_drive)
        else:
            return None
         
    def __getitem__(self, key):
        return self.__dict__[key]



class TDriverTestDropGenerator(object):
    """
    Generate test drop zip file for TDriver.

    Generates drop zip files file from Test Assets. The main
    responsibility of this class is to create testdrop and test.xml
    file and build a zip file for the TDriver drop.
    
    """

    def __init__(self):
        self.drop_path_root = path("TDriverDrop")
        self.drop_path = None
        self.defaults = {}
        self.CTC_LOG_DIR = r"c:\data\ctc"

    def generate(self, xml_dict, output_file, template_loc=None):
        """Generate a test drop file."""
        xml = self.generate_xml(xml_dict, template_loc)
        return self.generate_drop(xml_dict, xml, output_file)

    def generate_drop(self, xml_dict, xml, output_file):
        """Generate test drop zip file."""

        zfile = zipfile.ZipFile(output_file, "w", zipfile.ZIP_DEFLATED)
        try:
            for drop_file, src_file in self.drop_files(xml_dict):

                _logger.info("   + Adding: %s" % src_file.strip())
                try:
                    zfile.write(src_file.strip(), drop_file.encode('utf-8'))
                except OSError, expr:
                    _logger.error(expr)
            doc = amara.parse(et.tostring(xml.getroot()))
            _logger.debug("XML output: %s" % doc.xml(indent=u"yes", encoding="ISO-8859-1"))
            zfile.writestr("test.xml", doc.xml(indent="yes", encoding="ISO-8859-1"))
        finally:
            _logger.info("TDriver testdrop created successfully!")
            zfile.close()

    def generate_xml(self, xml_dict, template_loc):
        """ generate an XML file"""
        template_loc = path(template_loc).normpath()
        loader = jinja2.ChoiceLoader([jinja2.PackageLoader(__package__, 'templates')])
        env = jinja2.Environment(loader=loader)
        if template_loc is None or not ".xml" in template_loc.lower():
            template = env.from_string(pkg_resources.resource_string(__name__, 'tdriver_template.xml'))# pylint: disable=E1101
        else:
            template = env.from_string(open(template_loc).read())# pylint: disable=E1101
            
        xmltext = template.render(xml_dict=xml_dict, test_plan=xml_dict, os=os, atspath=atspath, atsself=self).encode('ISO-8859-1')
        _logger.info(xmltext)
        return et.ElementTree(et.XML(xmltext))


    def generate_testasset_zip(self, xml_dict, output_file=None):
        """Generate TestAsset.zip for the TDriver server"""
        filename = xml_dict["temp_directory"].joinpath(r"TestAsset.zip")
        
        if output_file != None:
            filename = output_file
            
        for exe_block in xml_dict["execution_blocks"]:
            testasset_location = path(exe_block["asset_path"])

            zfile = zipfile.ZipFile(filename, "w", zipfile.ZIP_DEFLATED)
            try:
                for file_ in list(testasset_location.walkfiles()):
                    file_mod = file_.replace(testasset_location, "")
                    zfile.write(file_, file_mod.encode('utf-8'))
            finally:
                zfile.close()
        return filename
            
    def drop_files(self, xml_dict):
        """Yield a list of drop files."""
        
        drop_set = set()
        drop_files = []

        #Adding test asset, there's an execution block for every test asset
        for execution_block in xml_dict["execution_blocks"]:
            testasset_location = path(execution_block["asset_path"])
            asset_files = list(testasset_location.walkfiles())

            drop_path = path(execution_block["name"])
            
            drop_files = ((drop_path.parent, "images", execution_block["image_files"]),
                          (drop_path.parent,  "sisfiles", execution_block["tdriver_sis_files"]),
                          (drop_path.parent,  "tdriverparameters", execution_block["tdriver_parameters"]),
                          (drop_path.parent,  execution_block["name"], asset_files))
    
            for drop_dir, sub_dir, files in drop_files:
                for file_path in files:
                    if file_path != None:
                        
                        #Adding image files to the top level,                         
                        #Also adding tdriverparameters.xml file
                        if  sub_dir.lower() == "images" or sub_dir.lower() == "tdriverparameters":
                            drop_file = drop_dir.joinpath(sub_dir, file_path.name)
                        
                        #Adding sisfiles, installation of tdriver sisfiles is a bit different
                        #than normal sisfiles
                        elif sub_dir.lower() == "sisfiles":
                            drop_file = drop_dir.joinpath(sub_dir, path(file_path[0]).name)
                            file_path = path(file_path[0])
                                                    
                        #Adding test asset files                        
                        else:
                            temp_file = file_path.rsplit(os.sep, 1)[0]
                            replace_string = testasset_location.rsplit(os.sep, 1)[0]
                            drop_file = drop_dir.joinpath(sub_dir + "\\" + temp_file.replace(replace_string, ""), file_path.name)
                            
                        drop_file = drop_file.normpath()
                        if drop_file not in drop_set:
                            drop_set.add(drop_file)
                            yield (drop_file, file_path.normpath())        
       

class TDriverComponentParser(object):
    """
    Add information to the XML dictionary
    """
    def __init__(self, config):
        self.flash_images = [path(p) for p in config.flash_images]
        self.tdriver_parameters = [path(config.tdriver_parameters).normpath()]
        self.tdriver_sis_files = config.tdriver_sis_files
        self.build_drive = config.build_drive
        self.test_timeout = config.tdriver_timeout
        self.diamonds_build_url = config.diamonds_build_url
        self.testrun_name = config.testrun_name
        self.alias_name = config.alias_name
        self.device_type = config.device_type
        self.report_email = config.report_email
        self.email_format = config.email_format
        self.email_subject = config.email_subject
        self.file_store = config.file_store

        self.xml_dict = {}

        
    def insert_pre_data(self):
        """
        Creates a dictionary for the data before
        the <execution> block starts.
        """
        self.xml_dict = dict(self.xml_dict, temp_directory=path(tempfile.mkdtemp()))
        self.xml_dict = dict(self.xml_dict, diamonds_build_url=self.diamonds_build_url)
        self.xml_dict = dict(self.xml_dict, testrun_name=self.testrun_name)
        self.xml_dict = dict(self.xml_dict, alias_name=self.alias_name)
        self.xml_dict = dict(self.xml_dict, device_type=self.device_type)

    def create_execution_block(self, config):
        """Parse flash images and creates execution block for TDriver"""
        execution_block_list = []
        block_count = 0
        for test_asset in config.test_assets:
            if os.path.exists(test_asset):
                test_plan = TDriverTestPlan(config)
                block_count += 1
                execution_block_list.append(test_plan.insert_execution_block(block_count, self.flash_images, self.tdriver_sis_files, test_asset, self.tdriver_parameters))


        self.xml_dict = dict(self.xml_dict,  execution_blocks=execution_block_list)

    def insert_post_data(self):
        """
        Creates a dictionary for the data after
        the <execution> block ends. Or, Postaction data
        """
        self.xml_dict = dict(self.xml_dict, report_email=self.report_email)
        self.xml_dict = dict(self.xml_dict, email_format=self.email_format)
        self.xml_dict = dict(self.xml_dict, email_subject=self.email_subject)
        self.xml_dict = dict(self.xml_dict, report_location=self.file_store)
            
        return self.xml_dict
    
def create_drop(config):
    """Create a test drop."""
    xml_dict = {}
        
    _logger.debug("initialize TDriver dictionary")
    drop_parser = TDriverComponentParser(config)
    
    #Inserting data for test run and global through out the dictionary
    drop_parser.insert_pre_data()
    
    #for every asset path there should be a
    #separate execution block
    drop_parser.create_execution_block(config) 

    #Inserting reporting and email data (post actions)
    xml_dict = drop_parser.insert_post_data()    
    
    generator = TDriverTestDropGenerator()
    
    _logger.info("generating drop file: %s" % config.drop_file)
    generator.generate(xml_dict, output_file=config.drop_file, template_loc=config.template_loc)

def to_bool(param):
    """setting a true or false based on a param value"""
    param = str(param).lower()
    if "true" == param or "t" == param or "1" == param:
        return "True"
    else:
        return "False"

def main():
    """Main entry point."""    
    
    
    cli = OptionParser(usage="%prog [options] PATH1 [PATH2 [PATH3 ...]]")
    cli.add_option("--ats4-enabled", help="ATS4 enabled", default="True")
    cli.add_option("--build-drive", help="Build area root drive")
    cli.add_option("--drop-file", help="Name for the final drop zip file", default="TDriverDrop.zip")

    cli.add_option("--minimum-flash-images", help="Minimum amount of flash images", default=2)
    cli.add_option("--flash-images", help="Paths to the flash image files", default="")
    cli.add_option("--tdriver-sis-files", help="Sis files location", default="")

    cli.add_option("--testasset-location", help="TDriver test assets location", default="")
    cli.add_option("--template-loc", help="Custom template location", default="")
    cli.add_option("--tdrunner-enabled", help="Enabled or disabled TDrunner", default=True)
    cli.add_option("--test-profiles", help="Test profiles e.g. bat, fute", default="")
    cli.add_option("--tdriver-parameters", help="Location of xml file contains additional parameters for TDriver", default="")

    cli.add_option("--tdriver-timeout", help="Test execution timeout value (default: %default)", default="60")
    cli.add_option("--tdrunner-parameters", help="Additional TDrunner parameters for TDriver task", default="")
    cli.add_option("--file-store", help="Destination path for reports.", default="")
    cli.add_option("--report-email", help="Email notification receivers",  default="")
    cli.add_option("--testrun-name", help="Name of the test run", default="run")
    cli.add_option("--alias-name", help="Name of the alias", default="sut_s60")
    cli.add_option("--device-type", help="Device type (e.g. 'PRODUCT')", default="unknown")    
    cli.add_option("--diamonds-build-url", help="Diamonds build url")         
    cli.add_option("--email-format", help="Format of an email", default="")
    cli.add_option("--email-subject", help="Subject of an email", default="TDriver Testing")
    cli.add_option("--ctc-enabled", help="CTC enabled", default="False")

    cli.add_option("--verbose", help="Increase output verbosity", action="store_true", default=False)

    opts, _ = cli.parse_args()

    ats4_enabled = to_bool(opts.ats4_enabled)
    
    if ats4_enabled == "False":
        cli.error("TDriver tests execute on ATS4. Set property 'ats4.enabled'")
    
    if not opts.flash_images:
        cli.error("no flash image files given")
    if len(opts.flash_images.split(",")) < int(opts.minimum_flash_images):
        cli.error("Not enough flash files: %i defined, %i needed" % (len(opts.flash_images.split(",")), int(opts.minimum_flash_images) ))

    if opts.verbose:
        _logger.setLevel(logging.DEBUG)
        logging.basicConfig(level=logging.DEBUG)
    config = Configuration(opts)
    create_drop(config)

if __name__ == "__main__":
    main()
