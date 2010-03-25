#============================================================================ 
#Name        : test_sis.py 
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

""" Test sis module. """

import logging
import unittest
import tempfile
import os
from lxml import etree

import configuration
import sis

_logger = logging.getLogger('test.sis')


class ArchivePreBuilderTest(unittest.TestCase):
    """ Tests for sis module. """
    
    def test_sis_v1(self):
        """ V1 config format. """
        data = {'name': 'foo',
                'path': 'bar'}
        tree = self._setup_test_case(data)
        assert tree.xpath("/project/target[@name='stage1']/parallel/*/arg/@line")[0] == '-v foo.pkg foo.sis'
        
    def test_sis_v2(self):
        """ V2 config format. """
        data = {'input': 'foo.pkg'}
        tree = self._setup_test_case(data)
        assert tree.xpath("/project/target[@name='stage1']/parallel/*/arg/@line")[0] == '-v foo.pkg foo.sis'

    def test_sis_v2_1(self):
        """ V2 config format for sisx. """
        data = {'input': 'foo.pkg', 'output': 'foo.sisx'}
        tree = self._setup_test_case(data)
        assert tree.xpath("/project/target[@name='stage1']/parallel/*/arg/@line")[0] == '-v foo.pkg foo.sis'
        assert tree.xpath("/project/target[@name='stage2']/parallel/*/arg/@line")[0] == '-v foo.sis foo.sisx cert1 key1'
        
    def _setup_test_case(self, additional_data):
        """ Setup test case based on varying inputs. """
        data = {'makesis.tool': 'makesis',
                'signsis.tool': 'signsis',
                'key': 'key1',
                'cert': 'cert1',
                'build.sisfiles.dir': 'dir'}
        data.update(additional_data)
        config = configuration.ConfigurationSet([configuration.Configuration(data)])
        sis_prebuilder = sis.SisPreBuilder(config)
        tmpfile = os.path.join(tempfile.mkdtemp(), 'test.xml')
        sis_prebuilder.write(tmpfile)
        tree = etree.parse(tmpfile)
        return tree
    





