#============================================================================ 
#Name        : test_ctc.py 
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

import unittest
import ctc
import logging
import time
import os
import fileutils
import tempfile

_logger = logging.getLogger('test.configuration')
logging.basicConfig(level=logging.INFO)

root_test_dir = tempfile.mkdtemp()
_test_file_paths = [
                    "ctc/dir/component1/group/MON.SYM",
                    "ctc/dir/component2/group/",
                    "ctc/dir/component3/group/MON.SYM",
]

def _testpath(subpath):
    """ Normalised path for test paths. """
    return os.path.normpath(os.path.join(root_test_dir, subpath))

_test_file_content = {}

def setup_module():
    """ Setup files test config. 
    
    This creates a number of empty files in a temporary directory structure
    for testing various file selection and archiving operations.
    """
    for child_path in _test_file_paths:
        path = os.path.join(root_test_dir, child_path)
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

def teardown_module():
    """ Teardown test config. """
    if os.path.exists(root_test_dir):
        fileutils.rmtree(root_test_dir)
    

class MockUploader(ctc.MonSymFTPUploader):
    
    def _open(self):
        pass
    
    def _close(self):
        pass

    def _ftpmkdirs(self, dir):
        pass    
    
    def _send(self, src, dst):
        pass

class NestedConfigurationBuilderTest(unittest.TestCase):
        
    def test_uploader(self):
        paths = [   "ctc/dir/component1/group/MON.SYM",
                    "ctc/dir/component2/group/MON.SYM",
                    "ctc/dir/component3/group/MON.SYM",
                    ]
        uploader = MockUploader("server", [_testpath(p) for p in paths], "1234")
        result = uploader.upload()
        print result
        assert len(result) == 2
        assert result[0] == "ctc_helium/1234/mon_syms/1/MON.SYM"
        assert result[1] == "ctc_helium/1234/mon_syms/2/MON.SYM"
