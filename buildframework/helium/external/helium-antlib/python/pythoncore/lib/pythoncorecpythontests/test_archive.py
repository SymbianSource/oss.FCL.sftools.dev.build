#============================================================================ 
#Name        : test_archive.py 
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
import amara
import unittest

import archive
import configuration
import logging
import fileutils
import xml.dom.minidom
import tempfile
import test_fileutils


_logger = logging.getLogger('test.archive')
    
    
root_test_dir = test_fileutils.root_test_dir

def setup_module():
    """ Creates some test data files for file-related testing. """
    test_fileutils.setup_module()
    
def teardown_module():
    """ Cleans up test data files for file-related testing. """
    test_fileutils.teardown_module()
    
    
class ArchivePreBuilderTest(unittest.TestCase):
    """Tests that an archive configuration file successfully creates an Ant exec file."""
    EXEC_FILE = "archive_create.ant.xml"

    def test_ant_exec(self):
        """Tests that an archive configuration file successfully creates an Ant exec file."""
        builder = configuration.NestedConfigurationBuilder(os.environ['TEST_DATA'] + '/data/archive_test_input.cfg.xml')
        archiveConfigSet = builder.getConfiguration()
        archivePreBuilder = archive.ArchivePreBuilder(archiveConfigSet, "config", index=0)
        buildFilePath = os.path.join(root_test_dir, r'archive_test.ant.xml')
        archivePreBuilder.write(buildFilePath)
        build_file = open(buildFilePath)
        build_file_content = build_file.read()
        _logger.debug(build_file_content)
        resultDoc = amara.parse(build_file_content)
        build_file.close()
        # The last target in the Ant file should be called 'all'. Other targets
        # are named stage1, stage2, etc.
        self.assert_(resultDoc.project.target[-1].name == 'all')
        os.remove(buildFilePath)
        


class LogicalArchiveTest(unittest.TestCase):
    """tests Logical Archive feature"""
##    def setup(self):
##        """Test setup."""
#        builder = configuration.NestedConfigurationBuilder(os.environ['TEST_DATA'] + '/data/archive_test.cfg.xml')
#        self.archiveConfigSet = builder.getConfiguration()
#        self.config = self.archiveConfigSet.getConfigurations()[0]
#        self.archivePreBuilder = archive.ArchivePreBuilder(self.archiveConfigSet)

    def test_manifest_files(self):
        """ A LogicalArchive can create a correct manifest. """
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 'manifest_test',
                  'include': 'dir1/*.txt',
                  'archive.tool': '7za'
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        builder.build_manifest(config)

        expectedPaths = [os.path.normpath('dir1/file1.txt')]

        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/manifest_test_includefile.txt')

        with open(includeFilePath) as f:
            content = f.readlines()
        print content
        print expectedPaths
        content = [s.strip().lower() for s in content]
        self.assert_(content == expectedPaths)
    
    def test_empty_manifest_file(self):
        """ A LogicalArchive can handle empty manifest. """
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 'manifest_test',
                  'include': 'nothing',
                  'archive.tool': '7za'
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        builder.build_manifest(config)

        expectedPaths = []

        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/manifest_test_includefile.txt')

        with open(includeFilePath) as f:
            content = f.readlines()
        print content
        print expectedPaths
        content = [s.strip().lower() for s in content]
        self.assert_(content == expectedPaths)

    def test_manifest_files_with_exclude_list(self):
        """ A LogicalArchive can create a correct manifest. """
        excludelst = os.path.join(root_test_dir, 'exclude.lst')
        flh = open(excludelst, 'w+')
        flh.write("/epoc32/tools/variant/variant.cfg\n")
        flh.write("\\epoc32\\tools\\abld.pl\n")
        flh.write(os.path.join(root_test_dir, 'dir1', 'file1.txt') + "\n")
        flh.write(os.path.join(root_test_dir, 'dir1/subdir1/subdir1_file.txt') + "\n")
        flh.close()
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 'manifest_test',
                  'include': 'dir1/**',
                  'exclude.lst': excludelst,
                  'archive.tool': '7za'
                }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        builder.build_manifest(config)

        expectedPaths = [os.path.normpath('dir1/file2.doc'),
                         os.path.normpath('dir1/file3_no_extension'),
                         os.path.normpath('dir1/subdir2/subdir2_file_no_extension'),
                         os.path.normpath('dir1/subdir3/'),
                         ]
        expectedPaths.sort()
        
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/manifest_test_includefile.txt')

        with open(includeFilePath) as f:
            content = f.readlines()
        print content
        print expectedPaths
        content = [s.strip().lower() for s in content]
        content.sort()
        self.assert_(content == expectedPaths)

    def test_manifest_files_with_exclude_list_abs_nodrive(self):
        """ A LogicalArchive can create a correct manifest with external list and drive. """
        rtd = os.path.splitdrive(os.path.abspath(root_test_dir))[1]
        excludelst = os.path.join(root_test_dir, 'exclude.lst')
        flh = open(excludelst, 'w+')
        flh.write("/epoc32/tools/variant/variant.cfg\n")
        flh.write("\\epoc32\\tools\\abld.pl\n")
        flh.write(os.path.join(rtd, 'dir1', 'file1.txt') + "\n")
        flh.write(os.path.join(rtd, 'dir1/subdir1/subdir1_file.txt') + "\n")
        flh.close()
        configDict = {'root.dir': os.path.abspath(root_test_dir),
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 'manifest_test',
                  'include': 'dir1/**',
                  'exclude.lst': excludelst,
                  'archive.tool': '7za'
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        builder.build_manifest(config)

        expectedPaths = [os.path.normpath('dir1/file2.doc'),
                         os.path.normpath('dir1/file3_no_extension'),
                         os.path.normpath('dir1/subdir2/subdir2_file_no_extension'),
                         os.path.normpath('dir1/subdir3/'),
                         ]
        expectedPaths.sort()
        
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/manifest_test_includefile.txt')

        with open(includeFilePath) as f:
            content = f.readlines()
        if os.sep == '\\':
            content = [s.strip().lower() for s in content]
        else:
            content = [s.strip() for s in content]
        content.sort()
        print content
        print expectedPaths
        self.assert_(content == expectedPaths)

    
    def test_distribution_policy_config(self):
        """ tests the distribution policy files configuration"""
        expected_paths = [os.path.normpath('s60/component_public/component_public_file.txt'),
                         os.path.normpath('s60/component_public/Distribution.Policy.S60'),
                         os.path.normpath('s60/Distribution.Policy.S60'),
                         os.path.normpath('s60/missing/subdir/Distribution.Policy.S60'),
                         os.path.normpath('s60/missing/subdir/not_to_be_removed_0.txt'),
                         os.path.normpath('s60/UPPERCASE_MISSING/subdir/Distribution.Policy.S60'),
                         os.path.normpath('s60/UPPERCASE_MISSING/subdir/not_to_be_removed_0.txt'),]
        if os.sep == '\\':
            for i in range(len(expected_paths)):
                expected_paths[i] = expected_paths[i].lower()
        self.do_distribution_policy_config(expected_paths, policy='0')
         
        expected_paths = [os.path.normpath('s60/component_private/component_private_file.txt'),
                         os.path.normpath('s60/component_private/Distribution.Policy.S60'),]
        if os.sep == '\\':
            for i in range(len(expected_paths)):
                expected_paths[i] = expected_paths[i].lower()
        self.do_distribution_policy_config(expected_paths, policy='1')

        expected_paths = [os.path.normpath('s60/missing/subdir/another_subdir/to_be_removed_9999.txt'),
                          os.path.normpath('s60/missing/to_be_removed_9999.txt'),
                          os.path.normpath('s60/UPPERCASE_MISSING/subdir/another_subdir/to_be_removed_9999.txt'),
                          os.path.normpath('s60/UPPERCASE_MISSING/to_be_removed_9999.txt')]
        if os.sep == '\\':
            for i in range(len(expected_paths)):
                expected_paths[i] = expected_paths[i].lower()
        self.do_distribution_policy_config(expected_paths, policy=archive.mappers.MISSING_POLICY)
        
    def do_distribution_policy_config(self, expected_paths, policy):
        """ . """
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 's60_policy_test',
                  'include': 's60/',
                  'distribution.policy.s60': policy,
                  'selectors': 'policy',
                  'archive.tool': '7za'
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        builder.build_manifest(config)
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/s60_policy_test_includefile.txt')
        
        with open(includeFilePath) as f:
            content = f.readlines()
        if os.sep == '\\':
            content = [s.strip().lower() for s in content]
        else:
            content = [s.strip() for s in content]
        content.sort()

        print content
        if os.sep == '\\':
            expected_paths = [s.strip().lower() for s in expected_paths]
        else:
            expected_paths = [s.strip() for s in expected_paths]
        expected_paths.sort()
        print expected_paths
        assert content == expected_paths
        
    def test_split_manifest_file_unicode(self):
        """ A LogicalArchive can split a manifest correctly. """
        configDict = {'root.dir': os.path.abspath(root_test_dir),
                  'temp.build.dir': os.path.abspath(os.path.join(root_test_dir, 'temp_build_files')),
                  'archives.dir': os.path.abspath(root_test_dir),
                  'name': 'manifest_test_unicode',
                  'max.files.per.archive': '1',
                  'include': 'test_unicode/',
                  'archive.tool': '7za'
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        manifest_file_path = builder.build_manifest(config)        
        builder.manifest_to_commands(config, manifest_file_path)
        
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/manifest_test_unicode_includefile.txt')
        includeFilePath1 = os.path.join(root_test_dir, 'temp_build_files/manifest_test_unicode_part01.txt')
        includeFilePath2 = os.path.join(root_test_dir, 'temp_build_files/manifest_test_unicode_part02.txt')
        includeFilePath3 = os.path.join(root_test_dir, 'temp_build_files/manifest_test_unicode_part03.txt')

        with open(includeFilePath) as f:
            content = f.readlines()
        with open(includeFilePath1) as f:
            content1 = f.readlines()
        with open(includeFilePath2) as f:
            content2 = f.readlines()
        with open(includeFilePath3) as f:
            content3 = f.readlines()
        print "content: ", content
        print "content1: ", content1
        print "content2: ", content2
        print "content3: ", content2
        content = [s.strip() for s in content]
        self.assert_(len(content) == 3)
        self.assert_(len(content1) == 1)
        self.assert_(len(content2) == 1)
        self.assert_(len(content3) == 1)

    def test_distribution_policy_mapper_config(self):
        """ Testing the policy mapper. """
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 's60_policy_mapper_test',
                  'include': 's60/',
                  'archive.tool': '7za',
                  'policy.zip2zip': 'true',
                  'mapper': 'policy',
                  'policy.csv': os.path.join(os.environ['TEST_DATA'], 'data/distribution.policy.id_status.csv'),
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        manifest_file_path = builder.build_manifest(config)
        cmds = builder.manifest_to_commands(config, manifest_file_path)

        
        expected_paths = ['s60' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           's60' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           's60' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'Distribution.Policy.S60',                           
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',
                           's60' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'not_in_cvs' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths)):
                expected_paths[i] = expected_paths[i].lower()
        expected_paths0 = ['s60' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           's60' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',]
        if os.sep == '\\':
            for i in range(len(expected_paths0)):
                expected_paths0[i] = expected_paths0[i].lower()
        expected_paths1 = ['s60' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           's60' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60']
        if os.sep == '\\':
            for i in range(len(expected_paths1)):
                expected_paths1[i] = expected_paths1[i].lower()
        expected_paths9999 = ['s60' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',
                              's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt',
                              's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                              's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt']
        if os.sep == '\\':
            for i in range(len(expected_paths9999)):
                expected_paths9999[i] = expected_paths9999[i].lower()
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_includefile.txt')
        includeFilePath0 = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_0.txt')
        includeFilePath1 = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_1.txt')
        includeFilePath9999 = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_9999.txt')
        includeFilePathInternal = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test.internal.txt')
        
        content = self.__read_manifest(includeFilePath)
        expected_paths.sort()
        print "Content"
        print content
        print "Expected"
        print expected_paths
        assert content == expected_paths

        content = self.__read_manifest(includeFilePath0)
        expected_paths0.sort()
        print content
        print expected_paths0
        assert content == expected_paths0

        content = self.__read_manifest(includeFilePath1)
        expected_paths1.sort()
        print content
        print expected_paths1
        assert content == expected_paths1
        
        content = self.__read_manifest(includeFilePath9999)
        expected_paths9999.sort()
        print content
        print expected_paths9999
        assert content == expected_paths9999

        assert os.path.exists(includeFilePathInternal) == True
        print "Commands : ", cmds
        assert len(cmds) == 3


    def test_distribution_policy_mapper_config_no_zip2zip(self):
        """ Testing the policy mapper. """
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 's60_policy_mapper_test_noz2z',
                  'include': 's60/',
                  'archive.tool': '7za',
                  'policy.zip2zip': 'false',
                  'mapper': 'policy'
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        manifest_file_path = builder.build_manifest(config)
        cmds = builder.manifest_to_commands(config, manifest_file_path)

        
        expected_paths = ['s60' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           's60' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           's60' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'Distribution.Policy.S60',                           
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',
                           's60' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'not_in_cvs' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths)):
                expected_paths[i] = expected_paths[i].lower()
        expected_paths0 = ['s60' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           's60' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',]
        if os.sep == '\\':
            for i in range(len(expected_paths0)):
                expected_paths0[i] = expected_paths0[i].lower()
        expected_paths1 = ['s60' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           's60' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60']
        if os.sep == '\\':
            for i in range(len(expected_paths1)):
                expected_paths1[i] = expected_paths1[i].lower()
        expected_paths9999 = ['s60' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',
                              's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt',
                              's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                              's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt']
        if os.sep == '\\':
            for i in range(len(expected_paths9999)):
                expected_paths9999[i] = expected_paths9999[i].lower()

        expected_paths.sort()
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_includefile.txt')
        includeFilePath0 = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_0.txt')
        includeFilePath1 = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_1.txt')
        includeFilePath9999 = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_9999.txt')
        includeFilePathInternal = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_noz2z.internal.txt')
        
        content = self.__read_manifest(includeFilePath)
        expected_paths.sort()
        print content
        print expected_paths
        assert content == expected_paths

        content = self.__read_manifest(includeFilePath0)
        expected_paths0.sort()
        print content
        print expected_paths0
        assert content == expected_paths0

        content = self.__read_manifest(includeFilePath1)
        expected_paths1.sort()
        print content
        print expected_paths1
        assert content == expected_paths1
        
        content = self.__read_manifest(includeFilePath9999)
        expected_paths9999.sort()
        print content
        print expected_paths9999
        assert content == expected_paths9999

        assert os.path.exists(includeFilePathInternal) == False
        print "Commands : ", cmds
        assert len(cmds) == 1


    def test_distribution_policy_mapper_remover_config(self):
        """ Testing the policy remover mapper. """
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 's60_policy_mapper_test',
                  'include': 's60/',
                  'policy.root.dir': os.path.join(root_test_dir, 's60'),
                  'archive.tool': '7za',
                  'mapper': 'policy.remover',
                  'policy.zip2zip': 'true',
                  'policy.csv': os.path.join(os.environ['TEST_DATA'], 'data/distribution.policy.id_status.csv'),
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        manifest_file_path = builder.build_manifest(config)
        cmds = builder.manifest_to_commands(config, manifest_file_path)
        
        expected_paths = ['s60' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           's60' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           's60' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',                           
                           's60' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',                           
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'another_subdir' + os.sep + 'to_be_removed_9999.txt',                           
                           's60' + os.sep + 'not_in_cvs' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths)):
                expected_paths[i] = expected_paths[i].lower()
        expected_paths.sort()
        expected_paths0 = ['s60' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           's60' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt',                           
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           's60' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'not_to_be_removed_0.txt']
        if os.sep == '\\':
            for i in range(len(expected_paths0)):
                expected_paths0[i] = expected_paths0[i].lower()
        expected_paths1 = ['s60' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           's60' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60']
        if os.sep == '\\':
            for i in range(len(expected_paths1)):
                expected_paths1[i] = expected_paths1[i].lower()
        expected_paths1.sort()
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_includefile.txt')
        includeFilePath0 = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_0.txt')
        includeFilePath1 = os.path.join(root_test_dir, 'temp_build_files/s60_policy_mapper_test_1.txt')
        
        content = self.__read_manifest(includeFilePath)
        expected_paths.sort()
        print content
        print expected_paths
        assert content == expected_paths

        content = self.__read_manifest(includeFilePath0)
        expected_paths0.sort()
        print content
        print expected_paths0
        assert content == expected_paths0

        content = self.__read_manifest(includeFilePath1)
        expected_paths1.sort()
        print content
        print expected_paths1
        assert content == expected_paths1

        print cmds        
        assert len(cmds[3]) == 7


    def test_distribution_policy_mapper_sf_remover_config(self):
        """ Testing the policy SFL remover mapper. """
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 'sf_policy_sf_mapper_test',
                  'include': 'sf/',
                  'policy.root.dir': os.path.join(root_test_dir, 'sf'),
                  'archive.tool': '7za',
                  'mapper': 'sfl.policy.remover',
                  'policy.zip2zip': 'false',
                  'policy.csv': os.path.join(os.environ['TEST_DATA'], 'data/distribution.policy.extended_for_sf.id_status.csv'),
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        manifest_file_path = builder.build_manifest(config)
        cmds = builder.manifest_to_commands(config, manifest_file_path)
        
        expected_paths = ['sf' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           'sf' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           'sf' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'to_be_removed_9999.txt',                           
                           'sf' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'subdir_nofiles' + os.sep + 'subdir_nofiles2',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'subdir_nopolicy' + os.sep + 'component_private_file.txt',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'not_in_cvs' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'component_sfl' + os.sep + 'component_sfl_file.txt',
                           'sf' + os.sep + 'component_sfl' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'component_epl' + os.sep + 'component_epl_file.txt',
                           'sf' + os.sep + 'component_epl' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths)):
                expected_paths[i] = expected_paths[i].lower()
        expected_paths0 = ['sf' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           'sf' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'to_be_removed_9999.txt']
        if os.sep == '\\':
            for i in range(len(expected_paths0)):
                expected_paths0[i] = expected_paths0[i].lower()
        expected_paths1 = ['sf' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           'sf' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60']
        if os.sep == '\\':
            for i in range(len(expected_paths1)):
                expected_paths1[i] = expected_paths1[i].lower()
        expected_paths3 = ['sf' + os.sep + 'component_sfl' + os.sep + 'component_sfl_file.txt',
                           'sf' + os.sep + 'component_sfl' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths3)):
                expected_paths3[i] = expected_paths3[i].lower()
        expected_paths7 = ['sf' + os.sep + 'component_epl' + os.sep + 'component_epl_file.txt',
                           'sf' + os.sep + 'component_epl' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths7)):
                expected_paths7[i] = expected_paths7[i].lower()
        expected_paths9 = ['sf' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'subdir_nofiles' + os.sep + 'subdir_nofiles2',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'subdir_nopolicy' + os.sep + 'component_private_file.txt',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'not_in_cvs' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths9)):
                expected_paths9[i] = expected_paths9[i].lower()
 
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/sf_policy_sf_mapper_test_includefile.txt')
        includeFilePath0 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_sf_mapper_test_0.txt')
        includeFilePath1 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_sf_mapper_test_1.txt')
        includeFilePath3 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_sf_mapper_test_3.txt')
        includeFilePath7 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_sf_mapper_test_7.txt')
        includeFilePath9 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_sf_mapper_test_9999.txt')
        
        
        content = self.__read_manifest(includeFilePath)
        expected_paths.sort()
        print content
        print expected_paths
        assert content == expected_paths

        content = self.__read_manifest(includeFilePath0)
        expected_paths0.sort()
        print content
        print expected_paths0
        assert content == expected_paths0

        content = self.__read_manifest(includeFilePath1)
        expected_paths1.sort()
        print content
        print expected_paths1
        assert content == expected_paths1

        content = self.__read_manifest(includeFilePath3)
        expected_paths3.sort()
        print content
        print expected_paths3
        assert content == expected_paths3

        content = self.__read_manifest(includeFilePath7)
        expected_paths7.sort()
        print content
        print expected_paths7
        assert content == expected_paths7

        content = self.__read_manifest(includeFilePath9)
        expected_paths9.sort()
        print content
        print expected_paths9
        assert content == expected_paths9
        
        # checking the number of command generated
        assert len(cmds) == 2, "Must only have 2 steps in the archiving (archiving, removing)."
        assert len(cmds[0]) == 5, "Must only have 5 output files."
        print len(cmds[1])
        for cmd in cmds[1]:
            print cmd
        assert len(cmds[1]) == len(expected_paths)-len(expected_paths3), "Remore must be equal to len(expected_paths) - len(expected_paths3)"

    def test_distribution_policy_mapper_epl_remover_config(self):
        """ Testing the policy EPL remover mapper. """
        configDict = {'root.dir': root_test_dir,
                  'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                  'archives.dir': root_test_dir,
                  'name': 'sf_policy_epl_mapper_test',
                  'include': 'sf/',
                  'policy.root.dir': os.path.join(root_test_dir, 'sf'),
                  'archive.tool': '7za',
                  'mapper': 'epl.policy.remover',
                  'policy.zip2zip': 'false',
                  'policy.csv': os.path.join(os.environ['TEST_DATA'], 'data/distribution.policy.extended_for_sf.id_status.csv'),
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        manifest_file_path = builder.build_manifest(config)
        cmds = builder.manifest_to_commands(config, manifest_file_path)
        
        expected_paths = ['sf' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           'sf' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           'sf' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'subdir_nofiles' + os.sep + 'subdir_nofiles2',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'subdir_nopolicy' + os.sep + 'component_private_file.txt',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'not_in_cvs' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'component_sfl' + os.sep + 'component_sfl_file.txt',
                           'sf' + os.sep + 'component_sfl' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'component_epl' + os.sep + 'component_epl_file.txt',
                           'sf' + os.sep + 'component_epl' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths)):
                expected_paths[i] = expected_paths[i].lower()
        expected_paths0 = ['sf' + os.sep + 'component_public' + os.sep + 'component_public_file.txt',
                           'sf' + os.sep + 'component_public' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'Distribution.Policy.S60',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'subdir' + os.sep + 'to_be_removed_9999.txt',]
        if os.sep == '\\':
            for i in range(len(expected_paths0)):
                expected_paths0[i] = expected_paths0[i].lower()
        expected_paths1 = ['sf' + os.sep + 'component_private' + os.sep + 'component_private_file.txt',
                           'sf' + os.sep + 'component_private' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths1)):
                expected_paths1[i] = expected_paths1[i].lower()
        expected_paths3 = ['sf' + os.sep + 'component_sfl' + os.sep + 'component_sfl_file.txt',
                           'sf' + os.sep + 'component_sfl' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths3)):
                expected_paths3[i] = expected_paths3[i].lower()
        expected_paths7 = ['sf' + os.sep + 'component_epl' + os.sep + 'component_epl_file.txt',
                           'sf' + os.sep + 'component_epl' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths7)):
                expected_paths7[i] = expected_paths7[i].lower()
        expected_paths9 = ['sf' + os.sep + 'missing' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'subdir_nofiles' + os.sep + 'subdir_nofiles2',
                           'sf' + os.sep + 'missing' + os.sep + 'subdir' + os.sep + 'subdir_nopolicy' + os.sep + 'component_private_file.txt',
                           'sf' + os.sep + 'UPPERCASE_MISSING' + os.sep + 'to_be_removed_9999.txt',
                           'sf' + os.sep + 'not_in_cvs' + os.sep + 'Distribution.Policy.S60',]
        if os.sep == '\\':
            for i in range(len(expected_paths9)):
                expected_paths9[i] = expected_paths9[i].lower()

        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/sf_policy_epl_mapper_test_includefile.txt')
        includeFilePath0 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_epl_mapper_test_0.txt')
        includeFilePath1 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_epl_mapper_test_1.txt')
        includeFilePath3 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_epl_mapper_test_3.txt')
        includeFilePath7 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_epl_mapper_test_7.txt')
        includeFilePath9 = os.path.join(root_test_dir, 'temp_build_files/sf_policy_epl_mapper_test_9999.txt')
        
        
        content = self.__read_manifest(includeFilePath)
        expected_paths.sort()
        print content
        print expected_paths
        assert content == expected_paths

        content = self.__read_manifest(includeFilePath0)
        expected_paths0.sort()
        print content
        print expected_paths0
        assert content == expected_paths0

        content = self.__read_manifest(includeFilePath1)
        expected_paths1.sort()
        print content
        print expected_paths1
        assert content == expected_paths1

        content = self.__read_manifest(includeFilePath3)
        expected_paths3.sort()
        print content
        print expected_paths3
        assert content == expected_paths3

        content = self.__read_manifest(includeFilePath7)
        expected_paths7.sort()
        print content
        print expected_paths7
        assert content == expected_paths7

        content = self.__read_manifest(includeFilePath9)
        expected_paths9.sort()
        print content
        print expected_paths9
        assert content == expected_paths9
        
        # checking the number of command generated
        assert len(cmds) == 2, "Must only have 2 steps in the archiving (archiving, removing)."
        assert len(cmds[0]) == 5, "Must only have 5 output files."
        assert len(cmds[1]) == len(expected_paths)-len(expected_paths3), "Remore must be equal to len(expected_paths) - len(expected_paths3)"




    def __read_manifest(self, manifest):
        """ read the file and sort"""
        with open(manifest) as f:
            content = f.readlines()
        if os.sep == '\\':
            content = [s.strip().lower() for s in content]
        else:
            content = [s.strip() for s in content]
        content.sort()
        return content
        

    def test_split_manifest_file(self):
        """ A LogicalArchive can split a manifest correctly. """
        configDict = {'root.dir': os.path.abspath(root_test_dir),
                  'temp.build.dir': os.path.abspath(os.path.join(root_test_dir, 'temp_build_files')),
                  'archives.dir': os.path.abspath(root_test_dir),
                  'name': 'manifest_test',
                  'max.files.per.archive': '1',
                  'include': 'dir/',
                  'exclude': 'dir/emptysubdir3',
                  'archive.tool': '7za'
                 }
        config = configuration.Configuration(configDict)

        builder = archive.ArchivePreBuilder(configuration.ConfigurationSet([config]), "config", index=0)
        manifest_file_path = builder.build_manifest(config)
        builder.manifest_to_commands(config, manifest_file_path)

        expectedPaths = ['dir' + os.sep + 'emptysubdir1','dir' + os.sep + 'emptysubdir2']
        expectedPaths1 = ['dir' + os.sep + 'emptysubdir1\n']
        expectedPaths2 = ['dir' + os.sep + 'emptysubdir2\n']
        
        includeFilePath = os.path.join(root_test_dir, 'temp_build_files/manifest_test_includefile.txt')
        includeFilePath1 = os.path.join(root_test_dir, 'temp_build_files/manifest_test_part01.txt')
        includeFilePath2 = os.path.join(root_test_dir, 'temp_build_files/manifest_test_part02.txt')

        with open(includeFilePath) as f:
            content = f.readlines()
        with open(includeFilePath1) as f:
            content1 = f.readlines()
        with open(includeFilePath2) as f:
            content2 = f.readlines()
        print "content: ", content
        print "content1: ", content1
        print "content2: ", content2
        print "expectedPaths: ", expectedPaths
        print "expectedPaths1: ", expectedPaths1
        print "expectedPaths2: ", expectedPaths2
        content = [s.strip().lower() for s in content]
        self.assert_(content == expectedPaths)
        self.assert_(content1 == expectedPaths1)
        self.assert_(content2 == expectedPaths2)

class CheckRootDirValueTest(unittest.TestCase):
    """test root drive value"""
    def test_checkRootDirValue(self):
        """ Testing the root drive value. """
        configDict = {'root.dir': root_test_dir,
                'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                'archives.dir': root_test_dir,
                'name': 'regular_path_test',
                'include': 'dir1/*.txt',
                'archive.tool': '7za'
               }
        configDictUnc = {'root.dir': "\\\\server\\share\\dir",
                'temp.build.dir': os.path.join(root_test_dir, 'temp_build_files'),
                'archives.dir': root_test_dir,
                'name': 'unc_test',
                'include': 'dir1/*.txt',
                'archive.tool': '7za'
               }
        config = configuration.Configuration(configDict)
        configUnc = configuration.Configuration(configDictUnc)
        builder = MockedArchivePreBuilder(configuration.ConfigurationSet([config, configUnc]), "config", writerType='make', index=0)
        builder.rewriteXMLFile(os.path.join(os.environ['TEST_DATA'], 'data/zip_checkDrive_test.cfg.xml'), os.path.join(os.environ['TEST_DATA'], 'data/zip_checkDrive_test.cfg.xml.parsed'))
        (build_drive, _) = os.path.splitdrive(os.path.normpath(tempfile.gettempdir()))
        rootList = builder.checkRootDirValue(MockedConfigBuilder(), os.path.join(os.environ['TEST_DATA'], 'data/zip_checkDrive_test.cfg.xml.parsed'), build_drive, 'wvdo_sources')
        assert rootList is not None
        if os.sep == '\\':
            roots = builder.getCommonUncRoots(['\\\\server\\share\\dir', 
                                               '\\\\server\\share', 
                                               '\\\\server\\share1\\dir',
                                               '\\\\server2\\share\\somedir'])
            self.assert_(len(roots) == 3)
            self.assert_('\\\\server\\share\\' in roots)
            self.assert_('\\\\server\\share1\\' in roots)
            self.assert_('\\\\server2\\share\\' in roots)

class MockedConfigBuilder:
    """."""
            
    def writeToXML(self, xml_file, configs, parse_xml_file):
        """writeToXML"""
        pass
    

class MockedArchivePreBuilder(archive.ArchivePreBuilder):
    """ ."""
    def substUncPath(self, _):
        """ subst the unc path"""
        if os.sep != '\\':
            return None
        return fileutils.get_next_free_drive()
          
    def unSubStituteDrives(self, drive):
        """ unsubstitute the drive"""
        pass
    
    def rewriteXMLFile(self, xml_file, parse_xml_file):
        """re-write XML file"""
        doc = xml.dom.minidom.parse(xml_file)
        out = open(parse_xml_file, 'w')
        doc.writexml(out, indent='')
        out.close()
            
  
class ZipArchiverTest(unittest.TestCase):

    def test_extension(self):
        t = archive.tools.SevenZipArchiver()
        self.assert_(t.extension() == ".zip")
    

#class ZipArchiverTest(unittest.TestCase):
#    def setUp(self):
#        archiveConfig = amara.parse(open(os.environ['TEST_DATA'] + '/data/zip_archive_test.cfg.xml'))
#        self.archivePreBuilder = archive.ArchivePreBuilder(archiveConfig)
#
#    def testZipArchiverCommand(self):
#        """Zip archiver creates correct command."""
#        archiver = archive.ZipArchiver(self.archivePreBuilder)
#        archiver._start_archive('foo')
#        archiver.end_archive()
#        commands = archiver.commandList.allCommands()
#        assert len(commands) == 1
#        command = commands[0]
#        assert command.executable() == 'zip.exe'
#        assert command.cmd() == '-R . c:\\temp\\foo.zip'
#
#    def testZipArchiverOperation(self):
#        """Zip archiver runs zip operation correctly."""
#        buildFilePath = self.archivePreBuilder.createArchiveBuildFile('zip_exec.ant.xml')
#        result = run(r'ant -f c:\temp\output\temp_build_files\zip_exec.ant.xml all -Dnumber.of.threads=1')
#        print result

def run( command ):
    """ run the code"""
    #print "Run command: " + command
    ( _, stdout ) = os.popen4( command )
    result = stdout.read()
    return result


if __name__ == "__main__":
    unittest.main()
