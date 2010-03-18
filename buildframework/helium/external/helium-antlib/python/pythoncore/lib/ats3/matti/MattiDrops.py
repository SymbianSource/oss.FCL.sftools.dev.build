# -*- encoding: latin-1 -*-

#============================================================================
#Name        : MattiDrops.py
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
#Description: Script for test drop generation and sending to execution to 
#ATS3-system
#===============================================================================

""" create the MATTI test drop file for use on the test server """
# pylint: disable-msg=R0902, R0903, R0912

import os
import re
import sys
import string
import zipfile
import logging 
from optparse import OptionParser
from xml.etree import ElementTree as et
from jinja2 import Environment, PackageLoader # pylint: disable-msg=F0401

# Shortcuts
E = et.Element
SE = et.SubElement

_logger = logging.getLogger('matti')

class Configuration(object):
    """
    ATS3 drop generation configuration.
    """
    
    def __init__(self, opts):
        """
        Initialize from optparse configuration options.
        """
        self._opts = opts
        
        # Customize some attributes from how optparse leaves them.
        self.build_drive = os.path.normpath(self._opts.build_drive)
        self.file_store = os.path.normpath(self._opts.file_store)
        self.matti_scripts = os.path.normpath(self._opts.matti_scripts)
        self.template_location = os.path.normpath(self._opts.template_loc)
        if self._opts.flash_images:
            self.flash_images = self._opts.flash_images.split(',')
        else:
            self.flash_images = []
        if not re.search(r'\A\s*?\Z', self._opts.sis_files):
            self.sis_files = self._opts.sis_files.split(',')
        else:
            self.sis_files = None
        self.step_list = []
        self.filelist = []
        self.image_list = []
        self.sis_list = []
        self.device_type = self._opts.device_type
        self.device_hwid = self._opts.device_hwid
        self.drop_file = self._opts.drop_file
        self.minimum_flash_images = self._opts.minimum_flash_images
        self.plan_name = self._opts.plan_name
        self.test_timeout = self._opts.test_timeout 
        self.diamonds_build_url = self._opts.diamonds_build_url
        self.testrun_name = self._opts.testrun_name    
        self.report_email = self._opts.report_email
        self.harness = self._opts.harness
        self.sis_enabled = False
        if self.sis_files:
            if len(self.sis_files) >= 1:
                self.sis_enabled = True
        
    
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
            
class MattiDrop(object):
    """
    ATS3 testdrop generation for MATTI tool
    """
    
    def __init__(self, config=None):
        self.configuration = config
        self.matti_cases = {}
        self.tmp_path = os.getcwd()
        self.files = []
        self.test_files = []
    
    def fetch_testfiles(self):
        """Needed flash files, sis-files and testscripts from given matti scripts -folder are added to file list."""
        tmp_case_list = []
#        tmp_image_list = []
        os.chdir(os.path.normpath(self.configuration.matti_scripts))
        try:
            for path, _, names in os.walk(os.getcwd()):
                for name in names:
                    if re.search(r'.*?[.]rb\Z', name):
                        tmp_case_list.append((os.path.normpath(os.path.join(path, name)), os.path.join("ats3", "matti", "script", name)))
            if tmp_case_list:
                for tmp_case in tmp_case_list:
                    self.configuration.step_list.append(dict(path=os.path.join("&#x00A7;TEST_RUN_ROOT&#x00A7;", str(tmp_case[1])), name="Test case"))
            if self.configuration.flash_images:
                for image in self.configuration.flash_images:
                    tmp = string.rsplit(image, os.sep)
                    image_name = tmp[len(tmp)-1] 
                    self.configuration.image_list.append(os.path.join("ATS3Drop", "images", image_name))
            if self.configuration.sis_files:
                for sis in self.configuration.sis_files:
                    tmp = string.rsplit(sis, os.sep)
                    sis_name = tmp[len(tmp)-1] 
                    self.configuration.sis_list.append(dict(path=os.path.join("ATS3Drop", "sis", sis_name), dest=sis_name))
        except KeyError, error:
            _logger.error("Error in file reading / fetching!")
            sys.stderr.write(error)
        if tmp_case_list:
            for tmp_case in tmp_case_list:
                self.configuration.filelist.append(tmp_case[1])
            return tmp_case_list
        else:
            _logger.error("No test cases/files available!")
            return None
    
    
    def create_testxml(self):
        """This method will use Jinja2 template engine for test.xml creation"""
        os.chdir(self.tmp_path)
        env = Environment(loader=PackageLoader('ats3.matti', 'template'))
        if os.path.isfile(self.configuration.template_location):
            template = env.from_string(open(self.configuration.template_location).read())
            xml_file = open("test.xml", 'w')
            xml_file.write(template.render(configuration=self.configuration))
            xml_file.close()
        else:
            _logger.error("No template file found")
                
    def create_testdrop(self, output_file=None, file_list=None):
        """Creates testdrop zip-file to given location."""
        #env = Environment(loader=PackageLoader('MattiDrops', 'template'))
        os.chdir(self.tmp_path)
        if output_file and file_list:
            zfile = zipfile.ZipFile(output_file, "w", zipfile.ZIP_DEFLATED)
            try:
                _logger.info("Adding files to testdrop:")
                for src_file, drop_file in file_list:
                    _logger.info("   + Adding: %s" % src_file.strip())
                    if os.path.isfile(src_file):
                        zfile.write(str(src_file.strip()), str(drop_file))
                    else:
                        _logger.error("invalid test file name supplied %s " % drop_file)
                if self.configuration.flash_images:
                    for image in self.configuration.flash_images:
                        tmp = string.rsplit(image, os.sep)
                        image_name = tmp[len(tmp)-1] 
                        _logger.info("   + Adding: %s" % image_name)
                        if  os.path.isfile(image):
                            zfile.write(image, os.path.join("ATS3Drop", "images", image_name))
                        else:
                            _logger.error("invalid flash file name supplied %s " % image_name)
                if self.configuration.sis_enabled:
                    if self.configuration.sis_files:
                        for sis in self.configuration.sis_files:
                            tmp = string.rsplit(sis, os.sep)
                            sis_name = tmp[len(tmp)-1] 
                            _logger.info("   + Adding: %s" % sis_name)
                            if os.path.isfile(sis):
                                zfile.write(sis, os.path.join("ATS3Drop", "sis", sis_name))
                            else:
                                _logger.error("invalid sis file name supplied %s " % sis_name)
                zfile.write(os.path.normpath(os.path.join(os.getcwd(),"test.xml")), "test.xml")
            finally:
                _logger.info("Testdrop created! %s" % output_file)            	   
                zfile.close()
            return zfile
    
def create_drop(configuration):
    """Testdrop creation"""
    if configuration:
        m_drop = MattiDrop(configuration)
        m_drop.fetch_testfiles()
        m_drop.create_testxml()
        return m_drop.create_testdrop(configuration.drop_file, m_drop.fetch_testfiles())
    else:
        _logger.error("No configuration available for test drop creation")        
        
def main():
    """Main entry point."""    
    cli = OptionParser(usage="%prog [options] TSRC1 [TSRC2 [TSRC3 ...]]")
    cli.add_option("--build-drive", help="Build area root drive", default='X:')
    cli.add_option("--matti-scripts", help="Path to the directory where the MATTI test scripts are saved.", default="")
    cli.add_option("--flash-images", help="Flash image files as a list",
                   default="")
    cli.add_option("--report-email", help="Email notification receivers", 
                   default="")
    cli.add_option("--harness", help="Test harness (default: %default)",
                   default="unknown")
    cli.add_option("--file-store", help="Destination path for reports.",
                   default="")
    cli.add_option("--testrun-name", help="Name of the test run", 
                   default="run")
    cli.add_option("--device-type", help="Device type (e.g. 'PRODUCT')", 
                   default="unknown")
    cli.add_option("--device-hwid", help="Device hwid", 
                   default="")
    cli.add_option("--diamonds-build-url", help="Diamonds build url")
    cli.add_option("--drop-file", help="Name for the final drop zip file",
                   default="")
    cli.add_option("--minimum-flash-images", help="Minimum amount of flash images",
                   default=2)    
    cli.add_option("--plan-name", help="Name of the test plan", 
                   default="plan")
    cli.add_option("--sis-files", help="Sis files as a list",
                   default="")
    cli.add_option("--template-loc", help="location of template file",
                   default="..\template")
    cli.add_option("--test-timeout", help="Test execution timeout value (default: %default)",
                   default="60")
    cli.add_option("--verbose", help="Increase output verbosity", 
                   action="store_true", default=True)
    opts, _ = cli.parse_args()

    if opts.verbose:
        _logger.setLevel(logging.DEBUG)
        logging.basicConfig(level=logging.DEBUG)
    config = Configuration(opts)
    create_drop(config)
    

if __name__ == "__main__":
    main()
