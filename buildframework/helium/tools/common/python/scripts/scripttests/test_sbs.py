#============================================================================ 
#Name        : test_sbs.py 
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
"""Tests Raptor (SBS) log creation/scanning """
import unittest
import logging
import sys
import os
import tempfile

_logger = logging.getLogger('test.sbs')
logging.basicConfig(level=logging.INFO)

class SBSTest(unittest.TestCase):
    """SBSTest: tests for raptor log creation"""
        
    def setUp(self):
        """setUp: setup any params or variable required by all tests later"""
        sys.path.append(os.path.join(os.environ['HELIUM_HOME'], 'tools/common/python/scripts'))
        
    def test_sbs(self):
        """test_sbs: test SBSScanlogMetadata """
        #import filter_metadatalog
        import sbsscanlogmetadata
        sbs = sbsscanlogmetadata.SBSScanlogMetadata()
        (_, filename) = tempfile.mkstemp()
        sbs.open(filename)
        sbs.write(open(os.path.join(os.environ['TEST_DATA'], 'data/scanlog/all_regex_type.log')).read())
        sbs.close()