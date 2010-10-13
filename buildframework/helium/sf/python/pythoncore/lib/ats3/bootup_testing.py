# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : bootup_testing.py 
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

"""Bootup test drop generation."""

#W0142 => * and ** were used
#R* removed during refactoring

from optparse import OptionParser
from xml.etree import ElementTree as et
import logging
import os
import re
import tempfile
import zipfile
import pkg_resources # pylint: disable-msg=F0401
from path import path # pylint: disable-msg=F0401
import amara
import ntpath as atspath
import jinja2 # pylint: disable-msg=F0401
import ats3.parsers as parser

_logger = logging.getLogger('bootup-testing')

# Shortcuts
E = et.Element
SE = et.SubElement

class Configuration(object):
    """
    Bootup test drop generation configuration.
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
    

class BootupTestPlan(object):
    """
    Tells ATS server that images have to be tested if they can start the device.
    """

    def __init__(self, config):
        self.pkg_parser = parser.PkgFileParser()
        self.file_store = config.file_store
        self.build_drive = config.build_drive

    def insert_execution_block(self, block_count=1, image_files=None):
        """
        Insert task and flash files into the execution block
        """
        if image_files is None:
            image_files = []

        exe_dict = dict(name="exe%d" % block_count, image_files=image_files)

        return exe_dict        


    def __getitem__(self, key):
        return self.__dict__[key]



class BootupTestDropGenerator(object):
    """
    Generate test drop zip file for Bootup testing.

    The main responsibility of this class is to create testdrop and 
    test.xml file.
    
    """

    def __init__(self):
        self.drop_path_root = path("BootupDrop")
        self.drop_path = None
        self.defaults = {}

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
            _logger.info("Testdrop for bootup testing created successfully!")
            zfile.close()

    def generate_xml(self, xml_dict, template_loc):
        """ generate an XML file"""
        template_loc = path(template_loc).normpath()
        loader = jinja2.ChoiceLoader([jinja2.PackageLoader(__name__, 'templates')])
        env = jinja2.Environment(loader=loader)
        if template_loc is None or not ".xml" in template_loc.lower():
            template = env.from_string(pkg_resources.resource_string(__name__, 'bootup_testing_template.xml'))# pylint: disable-msg=E1101
        else:
            template = env.from_string(open(template_loc).read())# pylint: disable-msg=E1101
            
        xmltext = template.render(xml_dict=xml_dict, os=os, atspath=atspath, atsself=self).encode('ISO-8859-1')
        #print xmltext
        return et.ElementTree(et.XML(xmltext))


    def drop_files(self, xml_dict):
        """Yield a list of drop files."""
        
        drop_set = set()
        drop_files = []
        #Adding test asset, there's an execution block for every test asset
        for execution_block in xml_dict["execution_blocks"]:
            drop_dir = path(execution_block["name"])
            drop_files = execution_block["image_files"]
            for file_path in drop_files:
                if file_path != None:
                    #Adding image files to the top level,                         
                    drop_file = drop_dir.joinpath("images", file_path.name)
            
                    drop_file = drop_file.normpath()
                    if drop_file not in drop_set:
                        drop_set.add(drop_file)
                        yield (drop_file, file_path.normpath())        


class ComponentParser(object):
    """
    Add information to the XML dictionary
    """
    def __init__(self, config):
        self.flash_images = [path(p) for p in config.flash_images]
        self.build_drive = config.build_drive
        self.diamonds_build_url = config.diamonds_build_url
        self.testrun_name = config.testrun_name
        self.alias_name = config.alias_name
        self.device_type = config.device_type
        self.report_email = config.report_email
        self.email_format = config.email_format
        self.email_subject = config.email_subject

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
        """Parse flash images """
        execution_block_list = []
        test_plan = BootupTestPlan(config)
        block_count = 1
        self.flash_images = self.get_sorted_images(self.flash_images)
        execution_block_list.append(test_plan.insert_execution_block(block_count, self.flash_images))


        self.xml_dict = dict(self.xml_dict,  execution_blocks=execution_block_list)

    def insert_post_data(self):
        """
        Creates a dictionary for the data after
        the <execution> block ends. Or, Postaction data
        """
        self.xml_dict = dict(self.xml_dict, report_email=self.report_email)
        self.xml_dict = dict(self.xml_dict, email_format=self.email_format)
        self.xml_dict = dict(self.xml_dict, email_subject=self.email_subject)
            
        return self.xml_dict

    def get_sorted_images(self, image_files):
        """sort the images """
        sorted_images = []
        for image_file in image_files:
            if 'core' in image_file.name:
                sorted_images.append(image_file)
        for image_file in image_files:
            if 'rofs2' in image_file.name:
                sorted_images.append(image_file)
        for image_file in image_files:
            if 'rofs3' in image_file.name:
                sorted_images.append(image_file)
        for image_file in image_files:
            if 'udaerase' in image_file.name:
                sorted_images.append(image_file)
        for image_file in image_files:
            if 'core' not in image_file.name and 'rofs2' not in image_file.name and 'rofs3' not in image_file.name and 'udaerase' not in image_file.name.lower():
                sorted_images.append(image_file)
        if len(sorted_images) > 0 and "rofs" in sorted_images[0]:
            return image_files
        return sorted_images

def create_drop(config):
    """Create a test drop."""
    xml_dict = {}
        
    _logger.debug("initialize configuration dictionary")
    drop_parser = ComponentParser(config)
    
    #Inserting data for test run and global through out the dictionary
    drop_parser.insert_pre_data()
    
    #for every asset path there should be a
    #separate execution block
    drop_parser.create_execution_block(config) 

    #Inserting reporting and email data (post actions)
    xml_dict = drop_parser.insert_post_data()
    

#    print "-------------------------------------------------"
#    keys = xml_dict
#    for key in xml_dict.keys():
#        if key == "execution_blocks":
#            for exe in xml_dict[key]:
#                print key, "->"
#                print exe['name']
#                print exe['image_files']
#                for file1 in exe['image_files']:
#                    print file1
#
#        else:
#            print key, "->", xml_dict[key]
#        
#    print xml_dict['diamonds_build_url']
#    print xml_dict['testrun_name']
#    print xml_dict['email_format']
#    print xml_dict['email_subject']
#    
#    print "-------------------------------------------------"


    
    generator = BootupTestDropGenerator()
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
    cli.add_option("--drop-file", help="Name for the final drop zip file", default="ATSBootupDrop.zip")

    cli.add_option("--minimum-flash-images", help="Minimum amount of flash images", default=2)
    cli.add_option("--flash-images", help="Paths to the flash image files", default="")

    cli.add_option("--template-loc", help="Custom template location", default="")

    cli.add_option("--file-store", help="Destination path for reports.", default="")
    cli.add_option("--report-email", help="Email notification receivers",  default="")
    cli.add_option("--testrun-name", help="Name of the test run", default="bootup_test")
    cli.add_option("--alias-name", help="Name of the alias", default="alias")
    cli.add_option("--device-type", help="Device type (e.g. 'PRODUCT')", default="unknown")    
    cli.add_option("--diamonds-build-url", help="Diamonds build url")         
    cli.add_option("--email-format", help="Format of an email", default="")
    cli.add_option("--email-subject", help="Subject of an email", default="Bootup Testing")
    cli.add_option("--verbose", help="Increase output verbosity", action="store_true", default=False)

    opts, _ = cli.parse_args()

    ats4_enabled = to_bool(opts.ats4_enabled)
    
    if ats4_enabled == "False":
        cli.error("Bootup test executes on ATS4. Set property 'ats4.enabled'")
    
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
