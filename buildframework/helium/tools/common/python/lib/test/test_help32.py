#============================================================================ 
#Name        : test_help32.py 
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

""" Test cases for the generation of help delivery IBY include file.

"""
import unittest
import sys
import imp
import os
import logging


# Uncomment this line to enable logging in this module, or configure logging elsewhere
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('test.help32')


class TestHelp32(unittest.TestCase):
    """ Test cases for S60 3.2 help deliveries handling. """
    
    def test_basket(self):
        """ Test the basket class. Basket class is a container that sort
            content for a root directory into common and language specific content.
        """
        sys.path.append(os.path.join(os.environ['HELIUM_HOME'],'tools/localisation/helps'))
        generate_iby = __import__('generate_iby_32')
        basket = generate_iby.Basket(os.path.join(os.environ['HELIUM_HOME'],'tests/data/help_delivery/Data'), excludes=['**/distribution.policy.S60'])
        print basket.common
        print basket.language
        assert len(basket.common) == 1
        assert len(basket.language['01']) == 2
        assert len(basket.language['02']) == 1
        assert not basket.language.has_key('03')
        
        
    def test_basket_with_tag(self):
        """ Test the basket class. Basket class is a container that sort
            content for a root directory into common and language specific content.
        """
        sys.path.append(os.path.join(os.environ['HELIUM_HOME'],'tools/localisation/helps'))
        generate_iby = __import__('generate_iby_32')
        basket = generate_iby.Basket(os.path.join(os.environ['HELIUM_HOME'],'tests/data/help_delivery/Data'), '_3g', excludes=['**/distribution.policy.S60'])
        print basket.common
        print basket.language
        assert len(basket.common) == 1
        assert len(basket.language['01']) == 2
        assert len(basket.language['02']) == 1
        assert basket.language.has_key('03')

        
    def test_basket_exclude(self):
        """ Testing the basket exclude list.
        """
        sys.path.append(os.path.join(os.environ['HELIUM_HOME'],'tools/localisation/helps'))
        generate_iby = __import__('generate_iby_32')
        basket = generate_iby.Basket(os.path.join(os.environ['HELIUM_HOME'],'tests/data/help_delivery/Data'), excludes=['**/subdir/**', '**/distribution.policy.S60'])
        print basket.common
        print basket.language
        assert len(basket.common) == 0
        assert not basket.language.has_key('01')
        assert not basket.language.has_key('02')
        assert not basket.language.has_key('03')
 