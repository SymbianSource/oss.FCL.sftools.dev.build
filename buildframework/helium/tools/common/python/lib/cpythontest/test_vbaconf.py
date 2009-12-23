#============================================================================ 
#Name        : test_vbaconf.py 
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

""" Some test cases for VBA config generation.
"""
import unittest
import logging
import os
import vbaconf
import vbaconf.new_delivery
import amara

# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('test.vbaconf')


class TestVBAConf(unittest.TestCase):
    """ Implementation of VBA test cases. """
    
    def test_vba_conf_generation(self):
        """ Testing all methods from VBA config generation.
        """
        delivery = os.path.join(os.environ['HELIUM_HOME'],'tests/data/validate_overlay/delivery.xml.parsed')
        prep = os.path.join(os.environ['HELIUM_HOME'],'tests/data/validate_overlay/prep.xml.parsed')
        doc = vbaconf.generate_config(delivery, prep)
        
        logger.info(doc.toprettyxml())
        
        doc = amara.parse(str(doc.toprettyxml()))
        assert len(doc.xml_xpath("/virtualBuildArea/add")) == 24 
        
    def test_vba_conf_generation_new_delivery_format(self):
        """ Testing all methods from VBA config generation.
        """
        delivery = os.path.join(os.environ['HELIUM_HOME'],'tests/data/validate_overlay/new_delivery/delivery.xml.parsed')
        prep = os.path.join(os.environ['HELIUM_HOME'],'tests/data/validate_overlay/new_delivery/prep.xml.parsed')
        doc = vbaconf.new_delivery.generate_config(delivery, prep)
        
        logger.info(doc.toprettyxml())
        
        doc = amara.parse(str(doc.toprettyxml()))
        ##assert len(doc.xml_xpath("/virtualBuildArea/add")) == 24 
        
    def test_vba_conf_generation_new_api(self):
        """ Testing all methods from VBA config generation.
        """
        delivery = os.path.join(os.environ['HELIUM_HOME'],'tests/data/validate_overlay/delivery.xml.parsed')
        prep = os.path.join(os.environ['HELIUM_HOME'],'tests/data/validate_overlay/prep.xml.parsed')
        conv = vbaconf.ConfigConverter(delivery, prep)
        doc = conv.generate_config()
        
        logger.info(doc.toprettyxml())
        
        doc = amara.parse(str(doc.toprettyxml()))
        assert len(doc.xml_xpath("/virtualBuildArea/add")) == 24 

    def test_vba_conf_generation_new_api_new_delivery_format(self):
        """ Testing all methods from VBA config generation.
        """
        delivery = os.path.join(os.environ['HELIUM_HOME'],'tests/data/validate_overlay/new_delivery/delivery.xml.parsed')
        prep = os.path.join(os.environ['HELIUM_HOME'],'tests/data/validate_overlay/new_delivery/prep.xml.parsed')
        conv = vbaconf.ConfigConverterNewDelivery(delivery, prep)
        doc = conv.generate_config()
        
        logger.info(doc.toprettyxml())
        
        doc = amara.parse(str(doc.toprettyxml()))
        assert len(doc.xml_xpath("/virtualBuildArea/add")) == 24 

 