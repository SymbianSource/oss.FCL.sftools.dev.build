#============================================================================ 
#Name        : test_policy_validator.py 
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

"""Test the integration.quality module."""

import os
import unittest
import sys
import time
import shutil
import tempfile
import integration.quality
import logging

_logger = logging.getLogger('test.archive')
    
    
_test_file_paths = [
    's60/Distribution.Policy.S60',
    's60/ADO/Distribution.Policy.S60',
    's60/ADO/group/Distribution.Policy.S60',
    's60/ADO/internal/Distribution.Policy.S60',
    's60/ADO/internal/good/Distribution.Policy.S60',
    's60/ADO/internal/bad/Distribution.Policy.S60',
    's60/ADO/tsrc/Distribution.Policy.S60',
    's60/ADO/tsrc/group/Distribution.Policy.S60',
    's60/ADO/tsrc/private/Distribution.Policy.S60',
    's60/component_public/Distribution.Policy.S60',
    's60/component_public/component_public_file.txt',
    's60/component_private/Distribution.Policy.S60',
    's60/component_private/component_private_file.txt',    
    's60/missing/to_be_removed_9999.txt',
    's60/missing/subdir/Distribution.Policy.S60',
    's60/missing/subdir/to_be_removed_9999.txt',
    's60/invalid/Distribution.Policy.S60',
    's60/invalid/comment/Distribution.Policy.S60',
    's60/invalid/utf16/Distribution.Policy.S60',
    's60/invalid/letter/Distribution.Policy.S60',
    's60/new_rules/',
    's60/new_rules/subdir1/invalid.txt',
    's60/new_rules/subdir2/',
    ]

_test_file_content = {
    's60/Distribution.Policy.S60': '0',
    's60/missing/subdir/Distribution.Policy.S60' : '0',
    's60/component_public/Distribution.Policy.S60': '0',
    's60/component_private/Distribution.Policy.S60': '1',
    's60/ADO/Distribution.Policy.S60': '0',
    's60/ADO/group/Distribution.Policy.S60': '0',
    's60/ADO/internal/Distribution.Policy.S60': '1',
    's60/ADO/internal/good/Distribution.Policy.S60': '1',
    's60/ADO/internal/bad/Distribution.Policy.S60': '0',
    's60/ADO/tsrc/Distribution.Policy.S60': '950',
    's60/ADO/tsrc/group/Distribution.Policy.S60': '0',
    's60/ADO/tsrc/private/Distribution.Policy.S60': '0',
    's60/invalid/Distribution.Policy.S60': '0',
    's60/invalid/comment/Distribution.Policy.S60': '0 ; some comment',
    's60/invalid/utf16/Distribution.Policy.S60': '\xFF\xFE\x30\x00\x0D\x00\x0D\x00\x0D\x00\x0A\x00',
    's60/invalid/letter/Distribution.Policy.S60': '9A0',
    }
    
class PolicyValidatorTest(unittest.TestCase):
    EXEC_FILE = "archive_create.ant.xml"
    
    def _testpath(self, subpath):
        """ Normalised path for test paths. """
        return os.path.normpath(os.path.join(self.root_test_dir, subpath))

    def setUp(self):
        """ Setup files test config. 
        
        This creates a number of empty files in a temporary directory structure
        for testing various file selection and archiving operations.
        """
        #print 'setup_module()'
        #print _test_file_content.keys()
        self.root_test_dir = tempfile.mkdtemp()
        for child_path in _test_file_paths:
            path = os.path.join(self.root_test_dir, child_path)
            path_dir = path
            path_dir = os.path.dirname(path)
            
            if (not os.path.exists(path_dir)):
                _logger.debug('Creating dir:  ' + path_dir)
                os.makedirs(path_dir)
    
            if(not path.endswith('/') and not path.endswith('\\')):
                _logger.debug('Creating file: ' + path)
                handle = open(path, 'w')
                # Write any file content that is needed
                if _test_file_content.has_key(child_path):
                    handle.write(_test_file_content[child_path])
                handle.close()
    
    def tearDown(self):
        """ Teardown test config. """
        shutil.rmtree(self.root_test_dir)

    def test_policy_validator(self):
        """ Testing the policy validator behaviour. """
        validator = integration.quality.PolicyValidator()
        errors = [] 
        errors.extend(validator.validate(self._testpath('s60')))
        errors.sort()
        print errors
        assert len(errors) == 5

        
        # Invalid encoding: contains other stuff than policy id.
        assert errors[0][0] == "invalidencoding"
        assert errors[0][1].lower() == self._testpath('s60' + os.sep + 'invalid' + os.sep + 'comment' + os.sep + 'distribution.policy.s60').lower()
        assert errors[0][2] == None
        
        # Invalid encoding: ID contains a letter.
        assert errors[1][0] == "invalidencoding"
        assert errors[1][1].lower() == self._testpath('s60' + os.sep + 'invalid' + os.sep + 'letter' + os.sep + 'distribution.policy.s60').lower()
        assert errors[1][2] == None
        
        # Invalid encoding: not ascii.
        assert errors[2][0] == "invalidencoding"
        assert errors[2][1].lower() == self._testpath('s60' + os.sep + 'invalid' + os.sep + 'utf16' + os.sep + 'distribution.policy.s60').lower()
        assert errors[2][2] == None
        
        # Policy file is missing
        assert errors[3][0] == "missing"
        assert errors[3][1].lower() == self._testpath('s60' + os.sep + 'missing').lower()
        assert errors[3][2] == None

        # Policy file is missing
        assert errors[4][0] == "missing"
        assert errors[4][1].lower() == self._testpath('s60' + os.sep + 'new_rules' + os.sep + 'subdir1').lower()
        assert errors[4][2] == None
        
