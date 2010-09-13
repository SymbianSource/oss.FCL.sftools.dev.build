#============================================================================ 
#Name        : test_escapeddict.py 
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
"""test escaped dict """

# pylint: disable=R0201

import logging
import unittest

import escapeddict


_logger = logging.getLogger('test.escapeddict')


class EscapedDictTest(unittest.TestCase):
    """ Acceptance tests for escapeddict.py """
    def test_escape(self):
        """test escape"""
        testdict = escapeddict.EscapedDict({'key1': 'value1', 'key2': 'value2 ${key1}'})
        for key in testdict.keys():
            _logger.info(testdict[key])
        assert testdict['key1'] == 'value1'
        assert testdict['key2'] == 'value2 value1'
        
    def test_escape_no_value_present(self):
        """test escape no value present"""
        testdict = escapeddict.EscapedDict({'key1': 'value1', 'key2': 'value2 ${key_not_present} ${key1}'})
        for key in testdict.keys():
            print testdict[key]
        assert testdict['key1'] == 'value1'
        assert testdict['key2'] == 'value2 ${key_not_present} value1'
        
    def test_escape_value_as_list(self):
        """test escape value as list"""
        testdict = escapeddict.EscapedDict({'key1': 'value1', 'key2': ['value2', '${key1}']})
        for key in testdict.keys():
            print testdict[key]
        assert testdict['key1'] == 'value1'
        assert testdict['key2'] == ['value2', 'value1']