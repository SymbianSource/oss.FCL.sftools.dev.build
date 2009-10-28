#============================================================================ 
#Name        : rom.py 
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

""" This modules implements rombuilders.
"""
import logging
import os
import sys
import shutil
import types
from version import Version
import re
import escapeddict
import imaker

# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("rom")


def get_abstract_parents(config):
    """ Create from a config element a list of parent
        that are abstract (not buildable).
    """
    result = []
    while (config.parent != None):
        if config.parent.abstract != None:
            result.append(config.parent)
        config = config.parent
    return result

def read_file_content(filename):
    """ Read the whole file content.
    """
    ftr = open(filename, "r")
    content = ftr.read()
    ftr.close()
    return content

def escape_string(string, config):
    """ Escape a string recursively.
    """
    #data = escapeddict.EscapedDict(config)
    #string = re.sub(r'\${(?P<name>[._a-zA-Z0-9]+)}', r'%(\g<name>)s', string)
    #return string % data
    return config.interpolate(string)

def get_makefile_target(text):
    """ Retrieve the target name of a step
    """
    result = re.search(r"^(?P<target>.+?)\s*:", text, re.M)
    if (result != None):
        return result.groupdict()['target']
    raise Exception("Could'nt determine target name")

def remove_duplicates(array):
    """ Remove dusplicates values from an array. """
    elements = {}
    for element in array: elements[element] = element
    return elements.keys()

def get_product_path_bsf(product):
    """ Get product path using the BSF. """
    import bsf
    # read product hierarchy
    bsfs = bsf.read_all()
    return bsfs[product].get_path()
    
def get_product_path_var(product):
    """ Get product path using the new tool. """
    return imaker.get_product_dir(product)

class IMakerRomBuilder:
    """ Configuration Builder for iMaker tool.
        This tool generate a makefile.
    """
    
    def __init__(self, config, product, usevar=False):
        self._config = config
        self._product = product

    def process_my_traces(self, config):
        """ Generates a mytraces.txt file under \epoc32 based on the <mytraces/>
            XML sub-elements defined for the image.
        """
        sys.stdout.flush()
        if config.has_key('mytraces.binaries') and len(str(config['mytraces.binaries'])) > 0:
            mytracestxt = escape_string(config['mytraces.file'], config)
            logger.debug("Writing %s file" % mytracestxt)
            binaries = config['mytraces.binaries']
            traces_file = open(mytracestxt, 'w')
            for binary in binaries:
                traces_file.write(str(binary) + "\n")
            traces_file.close()

    def build(self):
        """ Generate the makefile from xml configuration.
            That method should be splitted....it's to long!!!
        """
        configs = self._config.getConfigurations(self._product)
        if (len(configs) > 0):
            
            # creating additional targets
            targets = {}
            
            master_filename = configs[0]['main.makefile.template']
            
            outputfilename = os.path.basename(master_filename)
            if configs[0].has_key('output.makefile.filename'):
                outputfilename = configs[0]['output.makefile.filename']
            
            filename = "%s/%s" % (get_product_path_var(self._product), outputfilename)
            output = open(filename, "w+")
            output.write("# DO NOT EDIT - FILE AUTOMATICALLY GENERATED\n")
            output.write("# HELIUM variant configuration tool (C) Nokia - 2007\n\n")
            mkdefine = '__' + re.sub(r'[^\w]', '_', os.path.basename(outputfilename)).upper() + '__'
            output.write("ifndef %s\n" % mkdefine)
            output.write("%s := 1\n\n" % mkdefine)
            master_template = read_file_content(master_filename)
            output.write(configs[0].interpolate(master_template) + "\n")
                        
            for config in configs:
                # generating traces
                #self.process_my_traces(config)
                                                 
                
                if config.type == None:
                    raise Exception("Type not defined for configuration '%s'" % config.name)
                
                # generate makefile targets from templates
                if config.has_key("%s.makefile.template" % config.type):
                    template = read_file_content(config["%s.makefile.template" % config.type])
                    image_types = config['image.type']
                    if not isinstance(config['image.type'], types.ListType):
                        image_types = [config['image.type']]
                    for romtype in image_types:
                        config['image.type'] = romtype
                        out = config.interpolate(str(template))
                        output.write(out+"\n")
                        subtargets = [get_makefile_target(out)]
                        for parent in get_abstract_parents(config):
                            if not targets.has_key(parent.name):
                                targets[parent.name] = {}
                                targets[parent.name]['parent'] = parent
                                targets[parent.name]['subtargets'] = []
                            targets[parent.name]['subtargets'].extend(subtargets)
                            targets[parent.name]['subtargets'] = remove_duplicates(targets[parent.name]['subtargets'])
                            subtargets = [parent.name]
                    config['image.type'] = image_types
                else:
                    # Do not raise error anymore when template is not found. 
                    print "WARNING: Could not find template for %s (%s)" % (config.name,"%s.makefile.template" % config.type)
                    #raise Exception("Could not find template for %s (%s)" % (config.name,"%s.makefile.template" % config.type))
               
                    
            output.write("###############################################################################\n")
            output.write("# Generated group target\n")
            output.write("###############################################################################\n\n")
            for target in targets.keys():
                if targets[target]['parent']['build.parallel'] == 'true':
                    output.write("%s: %s\n\n" % (target, " ".join(targets[target]['subtargets'])))
                    output.write("%s-dryrun:\n" % target)
                    output.write("\t@$(CALL_TARGET) -n %s\n\n" % target)
                else:
                    output.write("%s-dryrun:\n" % target)
                    for subtarget in targets[target]['subtargets']:
                        output.write("\t@$(CALL_TARGET) -n %s\n" % subtarget)
                    output.write("\n")
                    output.write("%s:\n" % target)
                    output.write("\t@echo === %s started\n" % target)
                    for subtarget in targets[target]['subtargets']:
                        output.write("\t$(CALL_TARGET) %s\n" % subtarget)
                    output.write("\t@echo === %s finished\n" % target)
                    output.write("\n")
            output.write("\nendif # %s\n" % mkdefine)
            output.close()
            print "File %s has been generated." % filename
        else:
            raise Exception("Could not find configuration: '%s'" % self._product)


class RomBuilder:
    """ Builder that create roms using makefpsx.
    """
    def __init__(self, configs):
        self.configs = configs

    def build(self):
        """ Go throught the config and build each roms.
        """
        for config in self.configs:
            for k in sorted(config.keys()):
                value = config[k]
                if isinstance(value, types.UnicodeType):
                    value = value.encode('ascii', 'ignore')
                print k + ': ' + str(value)
            image = Image(config)
            image.build()
            print '======================================'
            print

class Image:
    """ An Image object represents a ROM image, or .fpsx file.
    """

    def __init__(self, config):
        """ Initialise the Image object.
        """
        self.config = config

    def build(self):
        """ Main method that handles the whole sequence of building the rom and
            moving all related files to the correct location.
        """
        self._create_destination()
        self._process_cmt()
        self._write_version()
        self._process_my_traces()
        self._callrommake()
        self._clean_mytraces()
        self._move_image_files()
        print

    def _create_destination(self):
        """ Creates the destination directory of the ROM files if it does not exist.
        """
        dest = self.config['rom.output.dir']
        if not os.path.exists( dest ):
            os.makedirs( dest )

    def _process_cmt(self):
        """ Copies the CMT image under \epoc32 and to the destination directory of
            the ROM image, if the image will include the CMT.
        """
        # Check if a CMT is needed
        if self.config['image.nocmt'] != 'true':
            dest = self.config['rom.output.dir']
            logger.debug("Copying " + self.config['cmt'] + " to " + dest)
            shutil.copy( self.config['cmt'], dest )
            logger.debug("Copying " + self.config['cmt'] + " to " + self.config['rommake.cmt.path'])
            shutil.copy( self.config['cmt'], self.config['rommake.cmt.path'] )

    def _write_version(self):
        """ Generates the version text files that define the version of the ROM image.
            These are in UTF16 little endian (Symbian) format.
        """
        Version('sw', self.config).write()
        Version('langsw', self.config).write()
        Version('model', self.config).write()

    def _process_my_traces(self):
        """ Generates a mytraces.txt file under \epoc32 based on the <mytraces/>
            XML sub-elements defined for the image.
        """
        sys.stdout.flush()
        if self.config.has_key('mytraces.binaries'):
            logger.debug("Writing mytraces.txt file")
            binaries = self.config['mytraces.binaries']
            traces_file = open( str(self.config['rommake.mytraces.file']), 'w' )
            for binary in binaries:
                traces_file.write( str(binary) + "\n" )
            traces_file.close()
        else:
            self._clean_mytraces()

    def _callrommake(self):
        """ Calls the make_fpsx.cmd to build a ROM image.
        """
        logger.debug("Building rom image: " + str(self))
        sys.stdout.flush()

        args = [str(self.config['rommake.command']),
                '-hid',
                str(self.config['rommake.hwid']),
                '-p',
                str(self.config['rommake.product.name']),
                '-iby',
                str(self.config['image.iby']),
                '-type',
                str(self.config['image.type']),
                '-traces',
                '-verbose',
                '-target',
                self.config['rom.output.dir'],
                '-o' + str(self)]
        if 'rommake.args' in self.config:
            extra_args = str(self.config['rommake.args']).split( ' ' )
            args += extra_args
        logger.debug("with args: " + str(args))
        os.chdir(os.path.dirname(str(self.config['rommake.command'])))
        os.spawnv(os.P_WAIT, str(self.config['rommake.command']), args)

    def _clean_mytraces(self):
        logger.debug("Removing mytraces.txt file")
        if os.path.exists( str( self.config['rommake.mytraces.file'] ) ):
            os.remove( str( self.config['rommake.mytraces.file'] ) )
    
    def _move_image_files(self):
        os.chdir( self.config['rom.output.dir'] )
        if not( os.path.isdir('temp') ):
            os.mkdir( 'temp' )
        if not( os.path.isdir('logs') ):
            os.mkdir( 'logs' )
        if not( os.path.isdir('obys') ):
            os.mkdir( 'obys' )
        
        for element in os.listdir('.'):
            if( os.path.isfile(element) ):
                if( element.endswith('.img') or element.endswith('.bin') or element.endswith('.bb5') ):
                    shutil.move( element, 'temp' )
                if( element.endswith('.log') or element.endswith('.dir') or element.endswith('.symbol') ):
                    shutil.move( element, 'logs' )
                if( element.endswith('.oby') ):
                    shutil.move( element, 'obys' )

                
    # Returns the name of this ROM image
    def __str__(self):
        """ Returns the filename of the image file once copied to the
            \*_flash_images directory.
        """
        # Get the unique build ID for these ROM image names
        name = str(self.config['rom.id']) + '_' + self.config['image.type']

        # Add a flag if the ROM is textshell
        if self.config['image.ui'] == 'text':
            name += "_text"

        # Add a flag if the image does not a CMT
        if self.config['image.nocmt'] == 'true':
            name += "_nocmt"

        # Add any differentiating name extension if present3
        if self.config['image.name.extension'] != '':
            name += '_' + self.config['image.name.extension']

        return name
