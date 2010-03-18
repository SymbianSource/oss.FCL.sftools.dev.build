#============================================================================ 
#Name        : test_fileutils.py 
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

""" Test fileutils module. """

import unittest
import logging
import os
import time
import sys
import fileutils
import archive

_logger = logging.getLogger('test.fileutils')


_test_file_paths = [
    'root_file1.txt',
    'root_file2.doc',
    'root_file3_no_extension',

    'dir1/file1.txt',
    'dir1/file2.doc',
    'dir1/file3_no_extension',
    'dir1/subdir1/subdir1_file.txt',
    'dir1/subdir2/subdir2_file_no_extension',
    'dir1/subdir3/',

    'dir2/',
    'dir3/subdir/',
    
    'wildcard1.txt',
    'wildcard2.doc',
    'wildcard3',
    'wildcard4/',
    'wildcard5/file.txt',
    
    'dir/emptysubdir1/',
    'dir/emptysubdir2/',
    'dir/emptysubdir3/',

    'emptydirerror/dir/',
    'emptydirerror/dir/emptysubdir/',
    'emptydirerror/dir/subdir/file.txt',
    
    u'test_unicode/test_\u00e9.txt',
    u'test_unicode/test_\u00e7.txt',
    u'test_unicode/test_\u00e4.txt',
    
    's60/Distribution.Policy.S60',
    's60/component_public/Distribution.Policy.S60',
    's60/component_public/component_public_file.txt',
    's60/component_private/Distribution.Policy.S60',
    's60/component_private/component_private_file.txt',
    's60/missing/to_be_removed_9999.txt',    
    's60/missing/subdir/Distribution.Policy.S60',
    's60/missing/subdir/not_to_be_removed_0.txt',    
    's60/missing/subdir/another_subdir/to_be_removed_9999.txt',    
    's60/UPPERCASE_MISSING/to_be_removed_9999.txt',
    's60/UPPERCASE_MISSING/subdir/Distribution.Policy.S60',
    's60/UPPERCASE_MISSING/subdir/not_to_be_removed_0.txt',
    's60/UPPERCASE_MISSING/subdir/another_subdir/to_be_removed_9999.txt',
    's60/not_in_cvs/Distribution.Policy.S60',
    'test_policies/1/Distribution.Policy.S60',
    'test_policies/2/Distribution.Policy.S60',
    'test_policies/3/Distribution.Policy.S60',
    'test_policies/4/Distribution.Policy.S60',
    'test_policies/5/Distribution.Policy.S60',
    'test_policies/6/Distribution.Policy.S60',
    'test_policies/7/Distribution.Policy.S60',
    'test_policies/8/Distribution.Policy.S60',
    'test_policies/9/Distribution.Policy.S60',
    'symbian/distribution.policy',
    'symbian/dir1/distribution.policy',
    'symbian/dir2/distribution.policy',
    'symbian/dir3/distribution.policy',
    'symbian/dir4/distribution.policy',
    'symbian/dir5/distribution.policy',
    's60src/src-a/distribution.policy',
    's60src/src-b/distribution.policy',
    's60src/src-c/distribution.policy',

    'sf/Distribution.Policy.S60',
    'sf/component_public/Distribution.Policy.S60',
    'sf/component_public/component_public_file.txt',
    'sf/component_epl/Distribution.Policy.S60',
    'sf/component_epl/component_epl_file.txt',
    'sf/component_sfl/Distribution.Policy.S60',
    'sf/component_sfl/component_sfl_file.txt',
    'sf/component_private/Distribution.Policy.S60',
    'sf/component_private/component_private_file.txt',
    'sf/missing/to_be_removed_9999.txt',
    'sf/missing/subdir/Distribution.Policy.S60',
    'sf/missing/subdir/to_be_removed_9999.txt',
    'sf/missing/subdir/subdir_nofiles/subdir_nofiles2/',    
    'sf/missing/subdir/subdir_nopolicy/',    
    'sf/missing/subdir/subdir_nopolicy/component_private_file.txt',
    'sf/UPPERCASE_MISSING/to_be_removed_9999.txt',
    'sf/UPPERCASE_MISSING/subdir/Distribution.Policy.S60',
    'sf/UPPERCASE_MISSING/subdir/to_be_removed_9999.txt',
    'sf/not_in_cvs/Distribution.Policy.S60',
    ]

_test_file_content = {
    's60/Distribution.Policy.S60': '0',
    's60/missing/subdir/Distribution.Policy.S60' : '0',
    's60/UPPERCASE_MISSING/subdir/Distribution.Policy.S60': '0',
    's60/component_public/Distribution.Policy.S60': '0',
    's60/component_private/Distribution.Policy.S60': '1\r\n',
    'test_policies/1/Distribution.Policy.S60': '\xFF\xFE\x30\x00\x0D\x00\x0D\x00\x0D\x00\x0A\x00',
    'test_policies/2/Distribution.Policy.S60': '\xEF\xBB\xBF\x30\x0D\x0D\x0A',
    'test_policies/3/Distribution.Policy.S60': '0 ; %version: 1 %',
    'test_policies/4/Distribution.Policy.S60': '10 ; %version: 1 %',
    'test_policies/5/Distribution.Policy.S60': '10ABC10',
    'test_policies/6/Distribution.Policy.S60': '10ABC10 ; %version: 1 %',
    'test_policies/7/Distribution.Policy.S60': '08421A2', # good
    'test_policies/8/Distribution.Policy.S60': '08421A2 ; %version: 1 %', # bad
    'test_policies/9/Distribution.Policy.S60': '1110A12', # bad
    's60/not_in_cvs/Distribution.Policy.S60': '77777',
    'symbian/distribution.policy': 'Category A',
    'symbian/dir1/distribution.policy': 'Category B',
    'symbian/dir2/distribution.policy': 'Line one \r\nAnother one \r\nCategory C',
    'symbian/dir3/distribution.policy': 'Line one \r\nAnother one \r\nAnother one \r\nCategory D',
    'symbian/dir4/distribution.policy': 'Line one \r\nAnother one \r\nNo Category',
    'symbian/dir5/distribution.policy': 'Line one \r\nAnother one \r\nagain no category',
    's60src/src-a/distribution.policy': 'Category A',
    's60src/src-b/distribution.policy': 'Category B',
    's60src/src-c/distribution.policy': 'Category C',
    'sf/Distribution.Policy.S60': '0',
    'sf/missing/subdir/Distribution.Policy.S60' : '0',
    'sf/UPPERCASE_MISSING/subdir/Distribution.Policy.S60': '0',
    'sf/component_public/Distribution.Policy.S60': '0',
    'sf/component_sfl/Distribution.Policy.S60': '3',
    'sf/component_epl/Distribution.Policy.S60': '7',
    'sf/component_private/Distribution.Policy.S60': '1',
    }
    
""" Used by test_archive. """
root_test_dir = "build/_test_" + str(time.strftime("%H.%M.%S"))
    
def _testpath(subpath):
    """ Normalised path for test paths. """
    return os.path.normpath(os.path.join(root_test_dir, subpath))
    
def setup_module():
    """ Setup files test config. 
    
    This creates a number of empty files in a temporary directory structure
    for testing various file selection and archiving operations.
    """
    #print 'setup_module()'
    #print _test_file_content.keys()
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
    

class FileScannerTest(unittest.TestCase):
    """ Test FileScanner class. """
    def test_1_scanner_paths(self):
        """1) String representation of a constructed FileScanner is correct."""
        scanner = fileutils.FileScanner(_testpath('test'))
        scanner.add_include('python/')
        # new implementation of the scanner doesn't convert modify the pattern strings...
        expected_result = _testpath('test') + ';include:' + os.path.normpath('python/**')
        assert str(scanner) == expected_result

    def test_2_include_1(self):
        """Files from root are included, no subdirs."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir1/*')
        testpaths = [_testpath('dir1/file1.txt'),
                     _testpath('dir1/file2.doc'),
                     _testpath('dir1/file3_no_extension'),
                     _testpath('dir1/subdir3')]
        result = []
        for path in scanner.scan():
            result.append(path)
        _logger.debug(result)
        
        # sorting the resuts
        testpaths.sort()
        result.sort()
        
        print result
        print testpaths
        assert result == testpaths
        
    def test_include_single_file(self):
        """A single file from root is included."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir1/file1.txt')
        testpaths = [_testpath('dir1/file1.txt')]
        result = []
        for path in scanner.scan():
            result.append(path)
        _logger.debug(result)
        
        print result
        print testpaths
        assert result == testpaths
        
    def test_include_single_file_and_glob_path(self):
        """A single file from root and a glob path are included."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir1/file1.txt')
        scanner.add_include('s60/component_public/')
        testpaths = [_testpath(u'dir1/file1.txt'),
                     _testpath(u's60/component_public/Distribution.Policy.S60'),
                     _testpath(u's60/component_public/component_public_file.txt'),]
        result = []
        for path in scanner.scan():
            result.append(path)
        
        if sys.platform == "win32":
            testpaths = [s.lower() for s in testpaths]
            result = [s.lower() for s in result]
        result.sort()
        testpaths.sort()
        print result
        print testpaths
        assert result == testpaths

    def test_3_include_2(self):
        """Files and subdirs are included."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir1/**')
        testpaths = [_testpath('dir1/file1.txt'),
                     _testpath('dir1/file2.doc'),
                     _testpath('dir1/file3_no_extension'),
                     _testpath('dir1/subdir1/subdir1_file.txt'),
                     _testpath('dir1/subdir2/subdir2_file_no_extension'),
                     _testpath('dir1/subdir3')]
        result = []
        for path in scanner.scan():
            result.append(path)
        _logger.debug(result)
        result.sort()
        testpaths.sort()
        print result
        print testpaths
        assert result == testpaths

    def test_4_include_3(self):
        """Wildcard includes in root."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('wild*')
        testpaths = [_testpath('wildcard1.txt'),
                     _testpath('wildcard2.doc'),
                     _testpath('wildcard3'),
                     _testpath('wildcard4')]
        result = []
        for path in scanner.scan():
            result.append(path)
        _logger.debug(result)
        result.sort()
        testpaths.sort()        
        print result
        print testpaths
        assert result == testpaths

    def test_5_include_4(self):
        """Include empty dirs."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir2/')
        scanner.add_include('dir3/**')
        testpaths = [_testpath('dir2'),
                     _testpath('dir3/subdir')]
        result = []
        for path in scanner.scan():
            result.append(path)
        _logger.debug(result)
        result.sort()
        testpaths.sort()        
        print result
        print testpaths
        assert result == testpaths

    def test_6_include_exclude_1(self):
        """Wildcard excludes."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('root*')
        scanner.add_include('wild*')
        scanner.add_exclude('root_*')
        testpaths = [_testpath('wildcard1.txt'),
                     _testpath('wildcard2.doc'),
                     _testpath('wildcard3'),
                     _testpath('wildcard4')]
        result = []
        for path in scanner.scan():
            result.append(path)
        _logger.debug(result)
        result.sort()
        testpaths.sort()
        
        print result
        print testpaths
        assert result == testpaths

    def test_7_include_exclude_2(self):
        """Directory can be excluded."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir1/')
        scanner.add_exclude('dir1/subdir1/')
        scanner.add_exclude('dir1/subdir2/')
        result = []
        [result.append(path) for path in scanner.scan()]
        testpaths = [_testpath('dir1/file1.txt'),
                     _testpath('dir1/file2.doc'),
                     _testpath('dir1/file3_no_extension'),
                     _testpath('dir1/subdir3')]                   
        result.sort()
        testpaths.sort()
        
        print result
        print testpaths
        assert result == testpaths
        
    def test_8_include_exclude_3(self):
        """Wildcard exclude."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir1/')
        scanner.add_exclude('**/*.doc')
        scanner.add_exclude('**/*.txt')
        result = []
        testpaths = [_testpath('dir1/file3_no_extension'),
                     _testpath('dir1/subdir2/subdir2_file_no_extension'),
                     _testpath('dir1/subdir3')]                   
        [result.append(path) for path in scanner.scan()]
        result.sort()
        testpaths.sort()
        
        print result
        print testpaths
        assert result == testpaths

    def test_case_sensitivity(self):
        """ Test if returned list has correct case. """
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('s60/UPPERCASE_MISSING/')
        result = []
        testpaths = [_testpath('s60/UPPERCASE_MISSING/to_be_removed_9999.txt'),
                     _testpath('s60/UPPERCASE_MISSING/subdir/Distribution.Policy.S60'),
                     _testpath('s60/UPPERCASE_MISSING/subdir/not_to_be_removed_0.txt'),
                     _testpath('s60/UPPERCASE_MISSING/subdir/another_subdir/to_be_removed_9999.txt')
                     ]                   
        [result.append(path) for path in scanner.scan()]
        
        testpaths.sort()
        result.sort()
        print result
        print testpaths
        assert result == testpaths


    def test_emptydir(self):
        """Empty dir."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir/emptysubdir1/')
        result = []
        testpaths = [_testpath('dir/emptysubdir1')]                   
        [result.append(path) for path in scanner.scan()]
        
        result.sort()
        testpaths.sort()

        print result
        print testpaths
        assert result == testpaths

    def test_emptydir_subdir(self):
        """ Empty dir (with excluded subdirs). """
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('emptydirerror/dir/')
        scanner.add_exclude('emptydirerror/dir/subdir/')
        scanner.add_exclude('emptydirerror/dir/emptysubdir/')
        result = []
        testpaths = []                   
        [result.append(path) for path in scanner.scan()]
        
        result.sort()
        testpaths.sort()

        print result
        print testpaths
        assert result == testpaths
        
    def test_emptydirs(self):
        """Empty dirs."""
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir/')
        scanner.add_exclude('dir/emptysubdir3/')
        result = []
        testpaths = [_testpath('dir/emptysubdir1'),
                     _testpath('dir/emptysubdir2')]                   
        [result.append(path) for path in scanner.scan()]
        
        print result
        print testpaths
        assert result == testpaths
        
    def test_distribution_policy_include(self):
        """ Distribution policy files can determine file selection - include. """
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('s60/component_public/')
        selector = archive.selectors.DistributionPolicySelector(['Distribution.policy.s60'], '0')
        scanner.add_selector(selector)
        
        result = []
        [result.append(path) for path in scanner.scan()]
        testpaths = [_testpath('s60/component_public/component_public_file.txt'),
                     _testpath('s60/component_public/distribution.policy.s60')]                   
        
        result = [s.lower() for s in result]
        result.sort()
        testpaths.sort()
        print result
        print testpaths
        assert result == testpaths
        
        
    def test_distribution_policy_exclude(self):
        """ Distribution policy files can determine file selection - exclude. """
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('s60/component_private/')
        selector = archive.selectors.DistributionPolicySelector(['Distribution.policy.s60'], '0')
        scanner.add_selector(selector)
        
        result = []
        [result.append(path) for path in scanner.scan()]
        testpaths = []                   
        
        assert result == testpaths
        
        
    def test_symbian_distribution_policy_cat_a(self):
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('s60src/src-a/')
        selector = archive.selectors.SymbianPolicySelector(['distribution.policy'], 'A')
        scanner.add_selector(selector)
                
        result = []
        [result.append(path) for path in scanner.scan()]
        testpaths = [_testpath('s60src/src-a/distribution.policy')] 
 
        assert result == testpaths
        
    def test_symbian_distribution_policy_cat_b(self):        
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('s60src/src-b/')
        selector = archive.selectors.SymbianPolicySelector(['distribution.policy'], 'B')
        scanner.add_selector(selector)
                       
        result = []
        [result.append(path) for path in scanner.scan()]
        testpaths = [_testpath('s60src/src-b/distribution.policy')] 
              
        assert result == testpaths     
        
    def test_symbian_distribution_policy_cat_not_a_not_b(self):        
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('s60src/src-c/')
        selector = archive.selectors.SymbianPolicySelector(['distribution.policy'], '!A,!B')
        scanner.add_selector(selector)
                       
        result = []
        [result.append(path) for path in scanner.scan()]
                  
        testpaths = [_testpath('s60src/src-c/distribution.policy')] 
        
        assert result == testpaths     
    
        
    def test_find_subroots(self):
        """ Testing the find_subroots method. """
        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir/emptysubdir1')
        scanner.add_include('dir/**/dir')
        scanner.add_include('foo/**/dir')
        scanner.add_include('bar/subdir/dir1/**')
        scanner.add_include('bar/subdir/dir2/**')
        scanner.add_include('bar/subdir/dir3/x/**')
        scanner.add_include('bar/subdir/dir3/**')
        result = scanner.find_subroots()
        _logger.debug(result)
        print result              
        assert result == [_testpath('dir'), _testpath('foo'), 
                          _testpath('bar/subdir/dir1'), 
                          _testpath('bar/subdir/dir2'), 
                          _testpath('bar/subdir/dir3')]

        scanner = fileutils.FileScanner(_testpath(''))
        scanner.add_include('dir/emptysubdir1')
        scanner.add_include('**/dir')
        scanner.add_include('foo/**/dir')
        result = scanner.find_subroots()
        _logger.debug(result)              
        assert result == [_testpath('')]


    def test_load_policy_content(self):
        try:
            fileutils.load_policy_content(_testpath('test_policies/1/Distribution.Policy.S60'))
            assert "Should fail while loading 'test_policies/1/Distribution.Policy.S60'."
        except:
            pass
        
        try:
            fileutils.load_policy_content(_testpath('s60/Distribution.Policy.S60'))
        except:
            assert "Should not fail while loading 's60/Distribution.Policy.S60'."


    def assert_policy_file(self, filename, value=None, exception=False):
        if exception:
            try:
                fileutils.read_policy_content(filename)
                assert "Should fail while loading '%s'." % filename
            except:
                pass
        else:
            assert fileutils.read_policy_content(filename) == value
    def assert_symbian_policy_file(self, filename, value=None, exception=False):
        if exception:
            try:
                fileutils.read_symbian_policy_content(filename)
                assert "Should fail while loading '%s'." % filename
            except:
                pass
        else:
            assert fileutils.read_symbian_policy_content(filename) == value
        
    def test_read_policy_content_strict(self):
        """ Test policy content using strict rules. """

        self.assert_policy_file(_testpath('s60/Distribution.Policy.S60'), value='0')
        self.assert_policy_file(_testpath('s60/component_private/Distribution.Policy.S60'), value='1')
        self.assert_policy_file(_testpath('test_policies/1/Distribution.Policy.S60'), exception=True)
        self.assert_policy_file(_testpath('test_policies/2/Distribution.Policy.S60'), exception=True)
        self.assert_policy_file(_testpath('test_policies/3/Distribution.Policy.S60'), exception=True)
        self.assert_policy_file(_testpath('test_policies/4/Distribution.Policy.S60'), exception=True)
        self.assert_policy_file(_testpath('test_policies/5/Distribution.Policy.S60'), exception=True)
        self.assert_policy_file(_testpath('test_policies/6/Distribution.Policy.S60'), exception=True)

    def test_read_policy_content_strict_focalid(self):
        """ Testing Focal ID support. """
        self.assert_policy_file(_testpath('test_policies/7/Distribution.Policy.S60'), value='08421A2')
        self.assert_policy_file(_testpath('test_policies/8/Distribution.Policy.S60'), exception=True)
        self.assert_policy_file(_testpath('test_policies/9/Distribution.Policy.S60'), exception=True)

    def test_read_symbian_policy_content_strict(self):
        """ Test symbian policy content using strict rules. """

        self.assert_symbian_policy_file(_testpath('symbian/distribution.policy'), value='A')
        self.assert_symbian_policy_file(_testpath('symbian/dir1/distribution.policy'), value='B')
        self.assert_symbian_policy_file(_testpath('symbian/dir2/distribution.policy'), value='C')
        self.assert_symbian_policy_file(_testpath('symbian/dir3/distribution.policy'), value='D')
        self.assert_symbian_policy_file(_testpath('symbian/dir4/distribution.policy'), exception=True)
        self.assert_symbian_policy_file(_testpath('symbian/dir5/distribution.policy'), exception=True)

class TestLongPath(unittest.TestCase):

    long_path = os.path.join(root_test_dir, '01234567890123456789012345678901234567890123456789', 
                     '01234567890123456789012345678901234567890123456789', '01234567890123456789012345678901234567890123456789',
                     '01234567890123456789012345678901234567890123456789', '01234567890123456789012345678901234567890123456789')
    def setUp(self):
        self.mkdirs(os.path.join(self.long_path, r'dir1'))
        self.mkdirs(os.path.join(self.long_path, r'dir2'))
        if not '\\\\?\\' + os.path.abspath((os.path.join( self.long_path, r'foo.txt'))):
            import win32file
            win32file.CreateFileW('\\\\?\\' + os.path.abspath(os.path.join(self.long_path, r'foo.txt')), 0, 0, None, win32file.CREATE_NEW, 0, None)

    def mkdirs(self, path):
        if not os.path.isabs(path):
            path = os.path.join(os.path.abspath('.'), os.path.normpath(path))
        if not os.path.exists(os.path.dirname(path)):
            self.mkdirs(os.path.dirname(path))
        self.mkdir(path)

    def mkdir(self, path):
        if 'java' in sys.platform:
            import java.io
            f = java.io.File(path)
            if not f.exists():
                os.mkdir(path)
        elif not os.path.exists(path):
            if sys.platform == "win32":
                try:
                    import win32file
                    win32file.CreateDirectoryW('\\\\?\\' + path, None)
                except:
                    pass
            else:
                os.mkdir(path)

    def test_rmtree_long_path(self):
        fileutils.rmtree(root_test_dir)
        assert not os.path.exists(self.long_path)
        assert not os.path.exists(root_test_dir)

    def test_rmtree_long_path_unc_format(self):
        if sys.platform == "win32":
            fileutils.rmtree(u"\\\\?\\" + os.path.join(os.path.abspath('.'), root_test_dir))
            assert not os.path.exists(self.long_path)
            assert not os.path.exists(root_test_dir)
        
class DestInSrcTest(unittest.TestCase):
    
    def test_destinsrc(self):
        """ Verify that Z:/a/b/c/d is under Z:/a/b/c """
        src = r"Z:/a/b/c"
        dst = r"Z:/a/b/c/d"
        assert fileutils.destinsrc(src, dst) is True
    
    def test_destinsrc2(self):
        """ Verify that Z:/a/b/c/d is not under Z:/a/b/cc """
        src = r"Z:/a/b/cc"
        dst = r"Z:/a/b/c/d"
        assert fileutils.destinsrc(src, dst) is False

    def test_destinsrc_nt(self):
        """ Verify that Z:/a/b/c/d is under Z:/a/b/C """
        src = r"Z:/a/b/C"
        dst = r"Z:/a/b/c/d"
        if os.sep == '\\':
            assert fileutils.destinsrc(src, dst) is True
        else:
            assert fileutils.destinsrc(src, dst) is False

    def test_destinsrc2_nt(self):
        """ Verify that Z:/a/b/c/d is not under Z:/a/b/CC """
        if os.sep == '\\':
            src = r"Z:/a/b/CC"
            dst = r"Z:/a/b/c/d"
            assert fileutils.destinsrc(src, dst) is False
