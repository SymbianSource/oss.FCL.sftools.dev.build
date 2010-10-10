#============================================================================ 
#Name        : test_quality.py 
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

"""Test the archive.py module."""

from __future__ import with_statement
import os
import unittest
import logging
import fileutils
import pythoncorecpythontests.test_fileutils
import integration.quality

_logger = logging.getLogger('test.quality')
    
    
root_test_dir = pythoncorecpythontests.test_fileutils.root_test_dir

def setup_module():
    """ Creates some test data files for file-related testing. """
    pythoncorecpythontests.test_fileutils.setup_module()
    
def teardown_module():
    """ Cleans up test data files for file-related testing. """
    pythoncorecpythontests.test_fileutils.teardown_module()
    
    
class QualityTest(unittest.TestCase):
    
    def test_epl_validate_content(self):
        """Tests loading policy ID's from CSV file for EPL"""
        pattern = "distribution.policy.s60,distribution.policy,distribution.policy.pp"
        ignoreroot = False
        excludes = ".static_wa,_ccmwaid.inf"
        validator = integration.quality.PolicyValidator(pattern, ignoreroot=ignoreroot, excludes=excludes)
        
        validator.epl_load_policy_ids(os.path.join(os.environ['TEST_DATA'], 'data/distribution.policy.extended_for_sf.id_status.csv'))
        
        assert validator.epl_validate_content(os.path.join(os.environ['TEST_DATA'], 'data/distribution.policy.S60')) == True
        assert validator.epl_validate_content(os.path.join(os.environ['TEST_DATA'], 'data/Invalid_distribution.policy.S60')) == False

if __name__ == "__main__":
    unittest.main()
