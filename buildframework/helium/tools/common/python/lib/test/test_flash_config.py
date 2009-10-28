#============================================================================ 
#Name        : test_flash_config.py 
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

""" Test flash_config.py module. """

import unittest
import configuration
import flash_config
import os

class FlashConfigTest(unittest.TestCase):
    
    def setUp(self):
        input_file = os.path.join(os.environ['HELIUM_HOME'], \
                                  'tests/data/flash_config/rom_image_config_test.xml')
        configBuilder = configuration.NestedConfigurationBuilder(open(input_file, 'r'))
        configSet = configBuilder.getConfiguration()
        self._configs = configSet.getConfigurations('product')
        self._writer = flash_config.FlashConfigurationWriter(configSet, 'product')
    
    def test_language_pack(self):
        """ Testing languagepack class. """
        for conf in self._configs:
            if conf.has_key('languagepack.id') and conf['languagepack.id'] == "01":
                lp = flash_config.ImagePack(conf, 'languagepack')
        
        assert lp != None
        
        assert lp._id == "01"
        assert lp._image_name == "RM-235_0.0728.3.0.1_${image.type.temp}_01"
        assert lp._image_path == "${image.type.temp}/language/01_variant_EURO1/"
        
    def test_get_all_languagepacks(self):
        """ Testing _get_all_languagepacks method. """
        self._writer._get_all_languagepacks()
        assert len(self._writer._all_languagepacks.keys()) == 4
        
    def test_get_compatible_languagepacks(self):
        """ Testing _get_compatible_languagepacks method. """
        self._writer._get_all_languagepacks()
        for config in self._configs:
            if (config.type == "customer"):
                customer_config = config
        
        assert customer_config != None
        # Only 2 valid compatible LPs. LP 03 is not a valid one b/c it is absent from rom_image_config_test.txt
        assert len(self._writer._get_compatible_languagepacks(customer_config)) == 2
        
    def test_write(self):
        """ Testing FlashConfigurationWriter method. """
        #self._writer.write()
        
        #Test the numbert of created files
        
        
        #Tes the content of one file
        