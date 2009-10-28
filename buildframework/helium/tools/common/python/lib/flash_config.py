#============================================================================ 
#Name        : flash_config.py 
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

""" This modules implements flash configuration writer.
"""
import logging
import os
import re
import rom
import types
import imaker


# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("flash_config")

class ImagePack:
    """ Local storage of image type
    """
    
    def __init__(self, config, type):
        """ init from config
        """
        config['image.type'] = '${image.type.temp}'
        self._type = type
        self._id = config[type + '.id']
        self._image_name = config[type + '.image.name']
        self._image_path = config[type + '.image.path']
        
    def set_config(self, config):
        """ Set the image type in a config
        """
        config[self._type + '.id'] = self._id
        config[self._type + '.image.name'] = self._image_name
        config[self._type + '.image.path'] = self._image_path 
        
    def __repr__(self):
        """ String representation the class
        """
        return self._id + " " + self._image_name + " " + self._image_path

class FlashConfigurationWriter:
    """ Builder that creates the flash configuration files
    """
    def __init__(self, configs, product):
        """ FlashConfigurationWriter init 
        """
        self._configs = configs
        self._product = product
        self._all_languagepacks = {} # pylint recomendation
        self._all_udas = {}
        self._all_mms = {}
        self._all_mcs = {}
        
    def _get_all_languagepacks(self):
        """ Collect all language packs and store them internally 
        """
        self._all_languagepacks = {}
        for config in self._configs.getConfigurations(self._product):
            if (config.type == "languagepack"):
                lp = ImagePack(config, 'languagepack')
                self._all_languagepacks[lp._id] = lp
    
    def _get_compatible_languagepacks(self, config):
        """ Get language packs compatible with a customer variant 
        """
        languagepack_list = []
        if config.has_key('compatible.languagepack'):
            lp_list = config['compatible.languagepack']
            if not isinstance(lp_list, types.ListType):
                lp_list = [lp_list]
            for lp_id in lp_list:
                if self._all_languagepacks.has_key(lp_id):
                    languagepack_list.append(self._all_languagepacks[lp_id])
                else:
                    print "Compatible languagepack " + str(lp_id) + " does not exists"
        else:
            languagepack_list = self._all_languagepacks.values()        
            
        return languagepack_list
        
    def _get_all_udas(self):
        """ Collect all udas and store them internally 
        """
        self._all_udas = {}
        for config in self._configs.getConfigurations(self._product):
            if (config.type == "uda"):
                lp = ImagePack(config, 'uda')
                self._all_udas[lp._id] = lp
                
    def _get_all_mms(self):
        """ Collect all mm's and store them internally 
        """
        self._all_mms = {}
        for config in self._configs.getConfigurations(self._product):
            if (config.type == "massmemory"):
                lp = ImagePack(config, 'massmemory')
                self._all_mms[lp._id] = lp
                
    def _get_all_mcs(self):
        """ Collect all mc's and store them internally 
        """
        self._all_mcs = {}
        for config in self._configs.getConfigurations(self._product):
            if (config.type == "memorycard"):
                lp = ImagePack(config, 'memorycard')
                self._all_mcs[lp._id] = lp
    
    def _get_compatible_udas(self, config):
        """ Get uda's compatible with a customer variant 
        """
        uda_list = []
        if config.has_key('compatible.uda'):
            lp_list = config['compatible.uda']
            if not isinstance(lp_list, types.ListType):
                lp_list = [lp_list]
            for lp_id in lp_list:
                if self._all_udas.has_key(lp_id):
                    uda_list.append(self._all_udas[lp_id])
                else:
                    print "Compatible uda " + str(lp_id) + " does not exists"
        else:
            return None
            
        return uda_list
        
    def _get_compatible_mms(self, config):
        """ Get mm's compatible with a customer variant 
        """
        mm_list = []
        if config.has_key('compatible.massmemory'):
            lp_list = config['compatible.massmemory']
            
            if not isinstance(lp_list, types.ListType):
                lp_list = [lp_list]
            for lp_id in lp_list:
                if self._all_mms.has_key(lp_id):
                    mm_list.append(self._all_mms[lp_id])
                else:
                    print "Compatible massmemory " + str(lp_id) + " does not exists"
        else:
            return None
            
        return mm_list
        
    def _get_compatible_mcs(self, config):
        """ Get mc's compatible with a customer variant 
        """
        mc_list = []
        if config.has_key('compatible.memorycard'):
            lp_list = config['compatible.memorycard']
            if not isinstance(lp_list, types.ListType):
                lp_list = [lp_list]
            for lp_id in lp_list:
                if self._all_mcs.has_key(lp_id):
                    mc_list.append(self._all_mcs[lp_id])
                else:
                    print "Compatible memorycard " + str(lp_id) + " does not exists"
        else:
            return None
            
        return mc_list
    
    def _write_file(self, config, romtype, uda, mm, mc):
        """ Write an xml flash configuration file 
        """
        
        #data = escapeddict.EscapedDict(config)
        template = rom.read_file_content(config['flash.config.template'])
        
        if not uda:
            #templatexml = amara.parse(template)
            
            #for image in templatexml.flash_config.image_set.image:
            #    if image.type == u'uda':
            #        templatexml.flash_config.image_set.xml_remove_child(image)
            
            #template = templatexml.xml(indent=u"yes")
            #needed to avoid customer complaints about empty lines
            #template = template.replace('\n\t\t\n', '\n')
            
            #workaround for makeupct, can't use real xml library
            template = re.sub(r".*<image type=\"uda\".*/>\n", '', template)
            
        if not mm:
            template = re.sub(r".*<image type=\"massmemory\".*/>\n", '', template)
        if not mc:
            template = re.sub(r".*<image type=\"memorycard\".*/>\n", '', template)
        
        if not os.path.exists(config['flash.config.publish.dir']):
            print "Creating " + config['flash.config.publish.dir']
            os.makedirs(config['flash.config.publish.dir'])
            
        fp = open(os.path.join(config['flash.config.publish.dir'], config['flash.config.name']), 'w')
        print "Writing file " + fp.name
        fp.write(rom.escape_string(template, config))
        fp.close()        
        
    def _append_to_makefile(self, config, romtype):
        template = rom.read_file_content(config['flash.config.makefile.template'])
        out = config.interpolate(template) + "\n"
        self._makefile_content += out + "\n"
        self._targets += rom.get_makefile_target(out) + " "

    def write(self):
        """ Go throught the config and creates the flash configuration files
        """
        
        # Pass #1: Store all language packs
        self._get_all_languagepacks()
        self._get_all_udas()
        self._get_all_mcs()
        self._get_all_mms()
        self._makefile_content = ""
        self._targets = "flash_config: "
        
        # Pass #2: Create all flash config files
        for config in self._configs.getConfigurations(self._product):
            if (config.type == "customer") or (config.type == "operator"):
                image_types = config['image.type']
                if not isinstance(config['image.type'], types.ListType):
                    image_types = [config['image.type']]
                
                for lp in self._get_compatible_languagepacks(config):
                    lp.set_config(config)
                    config['image.type.temp'] = '${image.type}'
                    
                    enable_uda = True
                    enable_mm = True
                    enable_mc = True
                    compatible_uda = self._get_compatible_udas(config)
                    compatible_mm = self._get_compatible_mms(config)
                    compatible_mc = self._get_compatible_mcs(config)
                    
                    if compatible_uda == None:
                        enable_uda = False
                        compatible_uda = [None]
                    if compatible_mm == None:
                        enable_mm = False
                        compatible_mm = [None]
                    if compatible_mc == None:
                        enable_mc = False
                        compatible_mc = [None]
                        
                    for uda in compatible_uda:
                        if uda:
                            uda.set_config(config)
                        for mm in compatible_mm:
                            if mm:
                                mm.set_config(config)
                            for mc in compatible_mc:
                                if mc:
                                    mc.set_config(config)
                                for romtype in image_types:
                                    config['image.type'] = romtype
                                    self._write_file(config, romtype, enable_uda, enable_mm, enable_mc)
                                    self._append_to_makefile(config, romtype)
        
        if self._makefile_content == "":
            logger.warning("No customer's or operator's found in rom config") 
        
        # Write makefile
        makefile_filename = "%s/mc_flash_config.mk" % imaker.get_product_dir(self._product)
        print "Writing makfile " + makefile_filename
        fp = open(makefile_filename, 'w')
        fp.write("include $(E32ROMCFG)/helium_features.mk\n")
        fp.write(self._makefile_content)
        fp.write(self._targets)
        fp.close()