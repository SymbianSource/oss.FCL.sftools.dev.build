# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : test_parsers.py 
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

import os
import tempfile
import mocker
from path import path
import StringIO

import ats3.parsers
import ats3.testconfigurator

import logging
logging.getLogger().setLevel(logging.ERROR)

TSRC_DIR = None

def setup_module():
    """Setup the test environment. The testing of the test parser script requires spesific
    structure to be available with bld.inf files (with the content written into those)."""
    global TSRC_DIR
    TSRC_DIR = path(tempfile.mkdtemp()).normpath()
    test_component = TSRC_DIR
    for path_parts in (("tsrc", "group"),
                       ("tsrc", "tc1", "group"),
                       ("tsrc", "tc1", "data"),
                       ("tsrc", "tc1", "dependent_1", "group"),
                       ("tsrc", "tc1", "dependent_2", "group"),
                       ("tsrc", "tc1", "subtest", "group"),
                       ("tsrc", "tc1", "subtest", "data"),
                       ("tsrc", "tc1", "subtest", "if_test", "group"),
                       ("tsrc", "tc2", "group"),
                       ("tsrc", "tc2", "data"),
                       ("tsrc", "tc3", "group"),
                       ("tsrc", "tc3", "data"),
                       ("tmp", "macros"),
                       ):
        filepath = path.joinpath(test_component, *path_parts).normpath()
        if not filepath.exists():
            os.makedirs(filepath)
    
        
    tsrc = open(path.joinpath(TSRC_DIR, "tsrc", "group", "bld.inf"), 'w')
    tsrc.write(
            r"""
#include "../tc1/group/bld.inf"
#include "../tc2/group/bld.inf"
#include "../tc3/group/bld.inf" 

PRJ_TESTMMPFILES

            """)
    tsrc.close()
    
    tc1 = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "group", "bld.inf"), 'w')
    tc1.write(
            r"""
#include "../dependent_1/group/bld.inf"
#include "../dependent_2/group/bld.inf"
#include "../subtest/group/bld.inf"

PRJ_TESTMMPFILES
tc1.mmp

PRJ_MMPFILES
not_included.mmp
            """)
    tc1.close()
    
    tc1_mmp = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "group", "tc1.mmp"), 'w')
    tc1_mmp.write(
            r"""
TARGET          tc1.dll
TARGETTYPE      dll
LIBRARY         stiftestinterface.lib
LIBRARY         user.lib
            """)
    tc1_mmp.close()
    
    tc1_sub = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "subtest", "group", "bld.inf"), "w")
    tc1_sub.write(
            r"""
PRJ_TESTMMPFILES
sub_test.mmp    
#ifndef RD_TEST1
#include "../if_test/group/bld.inf"
#endif
            """)
    tc1_sub.close()
    tc1_sub_mmp = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "subtest", "group", "sub_test.mmp"), 'w')
    tc1_sub_mmp.write(
            r"""
TARGET          sub_test.dll
TARGETTYPE      dll
LIBRARY         stiftestinterface.lib
            """)
    tc1_sub_mmp.close()

    
    tc1_if = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "subtest", "if_test", "group", "bld.inf"), "w")
    tc1_if.write(
            r"""
PRJ_TESTMMPFILES
if_test.mmp
            """)
    tc1_if.close()
    tc1_if_mmp = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "subtest", "if_test", "group", "if_test.mmp"), 'w')
    tc1_if_mmp.write(
            r"""
TARGET          tc1_if.dll
TARGETTYPE      dll
LIBRARY         stifunit.lib
            """)
    tc1_if_mmp.close()

    tc1_dep1 = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "dependent_1", "group", "bld.inf"), "w")
    tc1_dep1.write(
            r"""
PRJ_TESTMMPFILES
dependent_1.mmp
onemore.mmp
            """)
    tc1_dep1.close()

    tc1_dep1_mmp = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "dependent_1", "group", "dependent_1.mmp"), 'w')
    tc1_dep1_mmp.write(
            r"""
TARGET          dependent_1.dll
TARGETTYPE      PLUGIN
            """)
    tc1_dep1_mmp.close()
        
    tc1_dep2 = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "dependent_2", "group", "bld.inf"), "w")
    tc1_dep2.write(
            r"""
PRJ_TESTMMPFILES
dependent_2.mmp
            """)
    tc1_dep2.close()
    
    tc1_dep2_mmp = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "dependent_2", "group", "dependent_2.mmp"), 'w')
    tc1_dep2_mmp.write(
            r"""
TARGET          dependent_2.dll
TARGETTYPE      PLUGIN
            """)
    tc1_dep2_mmp.close()
    
    tc1_pkg = open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "group", "tc1.pkg"), 'w')
    tc1_pkg.write(
                  r"""
;Language - standard language definitions
&EN

; standard SIS file header
#{"BTEngTestApp"},(0x04DA27D5),1,0,0

;Supports Series 60 v 3.0
(0x101F7961), 0, 0, 0, {"Series60ProductID"}

;Localized Vendor Name
%{"BTEngTestApp"}

;Unique Vendor name
:"Nokia"

; Files to copy
"..\data\file1.dll"-"c:\sys\bin\file1.dll"
"..\data\file1.txt"-"e:\sys\bin\file1.txt" , FF   ; FF stands for Normal file
"..\data\file2.mp3"-"e:\sys\bin\file2.mp3"
"..\data\TestFramework.ini"-"c:\sys\bin\TestFramework.ini"
;"..\xyz\TestFramework.ini"-"!:\sys\bin\TestFramework.ini" (commented line)
"../data/temp.ini"-"!:/sys/bin/temp.ini" , FF ; "something here"
"..\data\tc1.cfg"-"e:\sys\bin\tc1.cfg"
"..\data\tc1.sisx"-"e:\sys\bin\tc1.sisx"
"..\data\DUMP.xyz"-"e:\sys\bin\DUMP.xyz"

            
        """.replace('\\', os.sep))
    tc1_pkg.close()
    
    open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "data", "file1.dll"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "data", "file1.txt"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "data", "file2.mp3"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "data", "TestFramework.ini"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "data", "temp.ini"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc1", "data", "DUMP.xyz"), 'w').close()
    
    tc2 = open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "group", "bld.inf"), "w")
    tc2.write(
            r"""
PRJ_TESTMMPFILES
tc2.mmp
            """)
    tc2.close()
    tc2_mmp = open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "group", "tc2.mmp"), 'w')
    tc2_mmp.write(
            r"""
TARGET          tc2.dll
TARGETTYPE      dll
LIBRARY         EUnit.lib
            """)
    tc2_mmp.close()
    
    tc2_pkg = open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "group", "tc2.pkg"), 'w')
    tc2_pkg.write(
                  r"""
;Language - standard language definitions
&EN

; standard SIS file header
#{"BTEngTestApp"},(0x04DA27D5),1,0,0

;Supports Series 60 v 3.0
(0x101F7961), 0, 0, 0, {"Series60ProductID"}

;Localized Vendor Name
%{"BTEngTestApp"}

;Unique Vendor name
:"Nokia"

; Files to copy
"..\data\file1.dll"-"c:\sys\bin\file1.dll"
"..\data\file1.txt"-"e:\sys\bin\file1.txt"
"..\data\file2.mp3"-"e:\sys\bin\file2.mp3"
"..\data\TestFramework.ini"-"!:\sys\bin\TestFramework.ini" , FF   ; FF stands for Normal file
"..\data\tc2.cfg"-"!:\sys\bin\tc2.cfg"
        """.replace('\\', os.sep))
    tc2_pkg.close()
    
    open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "data", "file1.dll"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "data", "file1.txt"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "data", "file2.mp3"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "data", "TestFramework.ini"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "data", "tc2.cfg"), 'w').close()

    
    tc3 = open(path.joinpath(TSRC_DIR, "tsrc", "tc3", "group", "bld.inf"), "w")
    tc3.write(
            r"""
PRJ_TESTMMPFILES
tc3.mmp
            """)
    tc3.close()
    tc3_mmp = open(path.joinpath(TSRC_DIR, "tsrc", "tc3", "group", "tc3.mmp"), 'w')
    tc3_mmp.write(
            r"""
TARGET          tc3.dll
TARGETTYPE      dll
LIBRARY         EUnit.lib
            """)
    tc3_mmp.close()
    
    tc3_pkg = open(path.joinpath(TSRC_DIR, "tsrc", "tc2", "group", "tc2.pkg"), 'w')
    tc3_pkg.write(
                  r"""
;Language - standard language definitions
&EN

; standard SIS file header
#{"BTEngTestApp"},(0x04DA27D5),1,0,0

;Supports Series 60 v 3.0
(0x101F7961), 0, 0, 0, {"Series60ProductID"}

;Localized Vendor Name
%{"BTEngTestApp"}

;Unique Vendor name
:"Nokia"

; Files to copy
"..\data\file1.dll"-"c:\sys\bin\file1.dll"
"..\data\file1.txt"-"e:\sys\bin\file1.txt"
"..\data\file2.mp3"-"e:\sys\bin\file2.mp3" , FF   ; FF stands for Normal file
"..\data\TestFramework.ini"-"!:\sys\bin\TestFramework.ini"
"..\data\temp.ini"-"!:\sys\bin\temp.ini"
"..\data\tc2.cfg"-"!:\sys\bin\tc2.cfg"
        """.replace('\\', os.sep))
    tc3_pkg.close()
    
    open(path.joinpath(TSRC_DIR, "tsrc", "tc3", "data", "file1.dll"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc3", "data", "file1.txt"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc3", "data", "file2.mp3"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc3", "data", "TestFramework.ini"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc3", "data", "temp.ini"), 'w').close()
    open(path.joinpath(TSRC_DIR, "tsrc", "tc3", "data", "tc2.cfg"), 'w').close()
    
    macros = open(path.joinpath(TSRC_DIR, "tmp", "macros", "bldcodeline.hrh"), 'w')
    macros.write(
              r"""
#ifndef __BLDCODELINE_HRH
#define __BLDCODELINE_HRH

/** #RD_TEST */
#define RD_TEST1

/** #RD_TEST2 */
#define RD_TEST2

/** #RD_TEST3 */
#define RD_TEST3

#endif  // __BLDCODELINE_HRH

    """)
    macros.close()

    
def teardown_module():
    """ Cleanup environment after testing. """    
    def __init__():
        TSRC_DIR.rmtree()
        
        
#        list_of_paths = []
#        list_of_paths = path.walk(TSRC_DIR)
#        for file in list_of_paths[2]:
#            continue
#        for dir in list_of_paths[1]:
#            continue
        

class TestPkgFileParser(mocker.MockerTestCase):
    """Testing Package file parser"""
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)

    def setUp(self):
        """Setup for PkgFile parser"""
        self.pkg_file_path1 = os.path.normpath(os.path.join(TSRC_DIR, "tsrc", "tc1", "group"))
        self.pkg_file_path2 = os.path.normpath(os.path.join(TSRC_DIR, "tsrc", "tc2", "group"))
        self.pkg_file_path3 = os.path.normpath(os.path.join(TSRC_DIR, "tsrc", "tc3", "group"))
        self.tcp = ats3.parsers.PkgFileParser("tc1.pkg")        
        
        self.data_files = [
            (path(TSRC_DIR+r"" + os.sep + "tsrc" + os.sep + "tc1" + os.sep + "data" + os.sep + "file1.dll").normpath(), path(r"c:" + os.sep + "sys" + os.sep + "bin" + os.sep + "file1.dll").normpath(), "testmodule", 'tc1.pkg'),
            (path(TSRC_DIR+r"" + os.sep + "tsrc" + os.sep + "tc1" + os.sep + "data" + os.sep + "file1.txt").normpath(), path(r"e:" + os.sep + "sys" + os.sep + "bin" + os.sep + "file1.txt").normpath(), "data", 'tc1.pkg'),
            (path(TSRC_DIR+r"" + os.sep + "tsrc" + os.sep + "tc1" + os.sep + "data" + os.sep + "file2.mp3").normpath(), path(r"e:" + os.sep + "sys" + os.sep + "bin" + os.sep + "file2.mp3").normpath(), "data", 'tc1.pkg'),
            (path(TSRC_DIR+r"" + os.sep + "tsrc" + os.sep + "tc1" + os.sep + "data" + os.sep + "TestFramework.ini").normpath(), path(r"c:" + os.sep + "sys" + os.sep + "bin" + os.sep + "TestFramework.ini").normpath(), "engine_ini", 'tc1.pkg'),
            (path(TSRC_DIR+r"" + os.sep + "tsrc" + os.sep + "tc1" + os.sep + "data" + os.sep + "temp.ini").normpath(), path(r"c:" + os.sep + "sys" + os.sep + "bin" + os.sep + "temp.ini").normpath(), "engine_ini", 'tc1.pkg'),
            (path(TSRC_DIR+r"" + os.sep + "tsrc" + os.sep + "tc1" + os.sep + "data" + os.sep + "tc1.cfg").normpath(), path(r"e:" + os.sep + "sys" + os.sep + "bin" + os.sep + "tc1.cfg").normpath(), "conf", 'tc1.pkg'),
            (path(TSRC_DIR+r"" + os.sep + "tsrc" + os.sep + "tc1" + os.sep + "data" + os.sep + "tc1.sisx").normpath(), path(r"e:" + os.sep + "sys" + os.sep + "bin" + os.sep + "tc1.sisx").normpath(), "", 'tc1.pkg'),
            (path(TSRC_DIR+r"" + os.sep + "tsrc" + os.sep + "tc1" + os.sep + "data" + os.sep + "DUMP.xyz").normpath(), path(r"e:" + os.sep + "sys" + os.sep + "bin" + os.sep + "DUMP.xyz").normpath(), "data", 'tc1.pkg'),
            ]

    def test_get_pkg_files(self):
        """Test if pkg files are returned from a specified location"""
        assert self.tcp.get_pkg_files(self.pkg_file_path1, False) == ["tc1.pkg"]



    def test_parser_receives_path(self):      
        """Test if None is returned when a path to PKG file is incorrect"""
        assert self.tcp.get_data_files("string") == []
            
    def test_data_files_creation_without_exclude(self):
        """ Tests if PKG file parser creates data files list as expected without exclude"""
        assert self.tcp.get_data_files(self.pkg_file_path1, "d:") == self.data_files
        
    def test_data_files_creation_with_exclude(self):
        """ Tests if PKG file parser creates data files list as expected with exclude"""
        self.data_files.pop()
        assert self.tcp.get_data_files(self.pkg_file_path1, "d:", "\.xyz") == self.data_files

    def test_data_files_creation_without_drive_with_exclude(self):
        """ Tests if PKG file parser creates data files list as expected without drive with exclude"""
        
        self.data_files.pop()
        assert self.tcp.get_data_files(self.pkg_file_path1, "", "\.xyz") == self.data_files

    def test_data_files_creation_without_drive_without_exclude(self):
        """ Tests if PKG file parser creates data files list as expected without drive without exclude"""
        
        assert self.tcp.get_data_files(self.pkg_file_path1, "") == self.data_files
            

class TestCppParser(mocker.MockerTestCase):
    """Testing CPP parser"""
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)

    def setUp(self):
        self.bld_path = os.path.normpath(os.path.join(TSRC_DIR, "tsrc", "group"))
        self.bld_path_comp1 = os.path.normpath(os.path.join(TSRC_DIR, "tsrc", "tc1", "group"))
        self.tcp = ats3.parsers.CppParser()
        upper_bld_path = os.path.dirname(self.bld_path)
        
        self.dependent_paths_dictionary = {(os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/subtest/if_test/group"))): {'content': {(os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/subtest/if_test/group"))): {'pkg_files': [], 'mmp_files': ['if_test.mmp'], 'harness': 'STIFUNIT', 'type': ''}}},
                                            (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc2//group"))): {'content': {(os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc2/group"))): {'pkg_files': ['tc2.pkg'], 'mmp_files': ['tc2.mmp'], 'harness': 'EUNIT', 'type': 'executable'}}}, 
                                            (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc3/group"))): {'content': {(os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc3/group"))): {'pkg_files':[], 'mmp_files': ['tc3.mmp'], 'harness': 'EUNIT', 'type': 'executable'}}},
                                            (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group"))): {'content': {(os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/subtest/group"))): {'pkg_files': [], 'mmp_files': ['sub_test.mmp'], 'harness': 'STIF', 'type': 'executable'}, 
                                                                                                                                (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/dependent_1/group"))): {'pkg_files': [], 'mmp_files': ['dependent_1.mmp', 'onemore.mmp'], 'harness': "", 'type':''}, 
                                                                                                                                (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/dependent_2/group"))): {'pkg_files': [], 'mmp_files': ['dependent_2.mmp'], 'harness': "", 'type': 'dependent'}, 
                                                                                                                                (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group"))): {'pkg_files': ['tc1.pkg'], 'mmp_files': ['tc1.mmp'],'harness': 'STIF', 'type': 'executable'}}}} 
        
        self.extended_path_list = [(os.path.normpath(upper_bld_path), upper_bld_path),
                           (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group")), upper_bld_path),
                           (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group/../dependent_1/group")), os.path.normpath(os.path.join(upper_bld_path, "../tc1/group"))),
                           (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group/../dependent_2/group")), os.path.normpath(os.path.join(upper_bld_path, "../tc1/group"))),
                           (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group/../subtest/group")), os.path.normpath(os.path.join(upper_bld_path, "../tc1/group"))),
                           (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group/../subtest/group/../if_test/group")), os.path.normpath(os.path.join(upper_bld_path, "../tc1/group/../subtest/group"))),
                           (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc2/group")), upper_bld_path),
                           (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc3/group")), upper_bld_path),
                           (os.path.normpath(os.path.join(upper_bld_path, "../tsrc/group/group")), upper_bld_path),
                           ]
        self.path_list = [os.path.normpath(os.path.join(upper_bld_path, "group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group/../dependent_1/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group/../dependent_2/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group/../subtest/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc1/group/../subtest/group/../if_test/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc2/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tsrc/tc3/group")),
                           ]
        self.path_list_without_undefined = [os.path.normpath(upper_bld_path),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc1/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc1/group/../dependent_1/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc1/group/../dependent_2/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc1/group/../subtest/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc2/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc3/group")),
                           ]
        self.cpp_output = ['# 1 "bld.inf"', 
                           '# 1 "../tc1/group/bld.inf" 1', 
                           '# 1 "../tc1/group/../dependent_1/group/bld.inf" 1', 
                           '# 4 "../tc1/group/bld.inf" 2', 
                           '# 1 "../tc1/group/../dependent_2/group/bld.inf" 1', 
                           '# 5 "../tc1/group/bld.inf" 2', 
                           '# 1 "../tc1/group/../subtest/group/bld.inf" 1', 
                           '# 1 "../tc1/group/../subtest/group/../if_test/group/bld.inf" 1', 
                           '# 4 "../tc1/group/../subtest/group/bld.inf" 2', 
                           '# 6 "../tc1/group/bld.inf" 2', 
                           '# 3 "bld.inf" 2', 
                           '# 1 "../tc2/group/bld.inf" 1', 
                           '# 4 "bld.inf" 2', 
                           '# 1 "../tc3/group/bld.inf" 1', 
                           '# 5 "bld.inf" 2']
        
        
         
    def test_pathlist_output(self):
        """Test get_cpp_output-method using "n" -parameter"""
        assert self.path_list.sort() == self.tcp.get_cpp_output(self.bld_path, "n").sort()
        
    def test_extended_pathlist_output(self):
        """Test get_cpp_output-method using "e" -parameter"""
        assert self.extended_path_list.sort() == self.tcp.get_cpp_output(self.bld_path, "e").sort()

    def test_dictionary_pathlist_output(self):
        """Test get_cpp_output-method using "d" -parameter (dependent paths)"""
        output = """# 1 "bld.inf"

# 1 "../tc1/group/bld.inf" 1

# 1 "../tc1/group/../dependent_1/group/bld.inf" 1

PRJ_TESTMMPFILES
dependent_1.mmp
onemore.mmp
            
# 2 "../tc1/group/bld.inf" 2

# 1 "../tc1/group/../dependent_2/group/bld.inf" 1

PRJ_TESTMMPFILES
dependent_2.mmp
            
# 3 "../tc1/group/bld.inf" 2

# 1 "../tc1/group/../subtest/group/bld.inf" 1

PRJ_TESTMMPFILES
sub_test.mmp    

# 1 "../tc1/group/../subtest/group/../if_test/group/bld.inf" 1

PRJ_TESTMMPFILES
if_test.mmp
            
# 5 "../tc1/group/../subtest/group/bld.inf" 2


            
# 4 "../tc1/group/bld.inf" 2


PRJ_TESTMMPFILES
tc1.mmp

PRJ_MMPFILES
not_included.mmp
            
# 2 "bld.inf" 2

# 1 "../tc2/group/bld.inf" 1

PRJ_TESTMMPFILES
tc2.mmp
            
# 3 "bld.inf" 2

# 1 "../tc3/group/bld.inf" 1

PRJ_TESTMMPFILES
tc3.mmp
            
# 4 "bld.inf" 2


PRJ_TESTMMPFILES

            
"""
        
        result = self.tcp.create_dependency_dictionary(StringIO.StringIO(output), self.bld_path)
        print "INPUT :", self.dependent_paths_dictionary
        print "OUTPUT:", result 

        assert self.dependent_paths_dictionary == result
        
    def test_conditional_cpp_parsing(self):
        """Test functionality of cpp parser when removing conditionals"""
        assert self.path_list_without_undefined.sort() == self.tcp.get_cpp_output(bld_path=self.bld_path, output_parameter="n", imacros=os.path.normpath(os.path.join(TSRC_DIR, "tmp", "macros", "bldcodeline.hrh"))).sort()

class TestBldFileParser(mocker.MockerTestCase):
    """Testing BldFileParser Class"""
    
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
    
    def setUp(self):
        """Setup for BldFile parser"""

        self.bld_path = path.joinpath(TSRC_DIR, "tsrc", "group", "bld.inf").normpath()
        upper_bld_path = self.bld_path.dirname()
        self.tcp = ats3.parsers.BldFileParser()
        
        self.test_mmp_files = [
                               ['tc1.mmp'], 
                               ['dependent_1.mmp', 'onemore.mmp'], 
                               ['dependent_2.mmp'], 
                               ['sub_test.mmp'], 
                               ['if_test.mmp'], 
                               ['tc2.mmp'], 
                               ["tc3.mmp"],
                               ]

        self.path_list = [path.joinpath(upper_bld_path, "../tc1/group").normpath(),
                           path.joinpath(upper_bld_path, "../tc1/group/../dependent_1/group").normpath(),
                           path.joinpath(upper_bld_path, "../tc1/group/../dependent_2/group").normpath(),
                           path.joinpath(upper_bld_path, "../tc1/group/../subtest/group").normpath(),
                           path.joinpath(upper_bld_path, "../tc1/group/../subtest/group/../if_test/group").normpath(),
                           path.joinpath(upper_bld_path, "../tc2/group").normpath(),
                           path.joinpath(upper_bld_path, "../tc3/group").normpath(),
                           ]


    def test_testmmp_files_with_full_path(self):
        """Test if mmp file is returned with its full path"""
        self.mmp_file_path = [path.joinpath(TSRC_DIR, "tsrc", "tc1", "group", "tc1.mmp").normpath()]
        assert self.tcp.get_test_mmp_files(os.path.normpath(os.path.join(self.path_list[0], "bld.inf"))) == self.mmp_file_path
        
        

    def test_testmmp_files(self):
        """Tests if test mmp files are included"""
        self.lst_test_mmp = []
        
        for p in self.path_list:
            self.lst_test_mmp.append(self.tcp.get_test_mmp_files(os.path.normpath(os.path.join(p, "bld.inf")), False))

        assert self.lst_test_mmp == self.test_mmp_files
        
    def test_ignore_comments(self):
        """ Test if comments are ignored correctly. """
        for input_, output in [
            ("abc.mmp /* apuva.mmp */ xyz.mmp", ("abc.mmp xyz.mmp")),
            ("abc.mmp /* apuva.mmp */", ("abc.mmp")),
            ("/* apuva.mmp */", ""),
            ("  // apuva.mmp", ""),
            ("   apuva.mmp", "apuva.mmp"),
            ("xyz.mmp // apuva.mmp", "xyz.mmp"),
            ("abc.mmp /* apuva.mmp */ xyz.mmp //rst.mmp", ("abc.mmp xyz.mmp")),
            ]:
            assert self.tcp.ignore_comments_from_input(input_) == output
        
    def test_broken_path(self):
        """Tests if 'None' is returned when path is broken"""
        upper_bld_path = os.path.dirname(self.bld_path)
        assert self.tcp.get_test_mmp_files(os.path.normpath(os.path.join(upper_bld_path, "../tc99/group"))) == None
    
    def test_empty_parameter(self):
        """Tests if 'None' is returned when bld file path is empty"""
        upper_bld_path = os.path.dirname(self.bld_path)
        assert self.tcp.get_test_mmp_files("") == None

    
class TestMmpFileParser(mocker.MockerTestCase):
    """Testing MmpFileParser Class"""
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
        
    def setUp(self):
        self.bld_path = os.path.normpath(os.path.join(TSRC_DIR, "tsrc", "group", "bld.inf"))
        upper_bld_path = os.path.dirname(self.bld_path)
        self.tcp = ats3.parsers.MmpFileParser()
        self.tc1_type = "dll"
        self.tc1_name = "tc1.dll"
        self.tc1_dll_type = "executable"
        self.tc1_harness = "STIF"
        self.tc1_libraries = ['stiftestinterface.lib', 'user.lib']
        self.tc1_all = (self.tc1_name, self.tc1_type, self.tc1_libraries, self.tc1_harness)
        self.tc1_no_harness = (self.tc1_name, self.tc1_type, self.tc1_libraries)
        self.tc1_name_type = (self.tc1_name, self.tc1_type) 
        self.tc1_iftest_harness = "STIFUNIT"
        self.tc1_iftest_name = "tc1_if.dll"
        self.tc1_iftest_type = "dll"
        
        self.test_mmp_files = [['tc1.mmp'], ['dependent_1.mmp', 'onemore.mmp'], ['dependent_2.mmp'], ['sub_test.mmp'], ['if_test.mmp'], 
                               ['tc2.mmp'], ["tc3.mmp"]]

        self.path_list = [os.path.normpath(os.path.join(upper_bld_path, "../tc1/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc1/group/../dependent_1/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc1/group/../dependent_2/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc1/group/../subtest/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc1/group/../subtest/group/../if_test/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc2/group")),
                           os.path.normpath(os.path.join(upper_bld_path, "../tc3/group")),
                           ]
    
    def test_get_dlltype(self):
        """Test if get_filetype returns right type for given mmp"""
        assert self.tc1_dll_type == self.tcp.get_dll_type(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp'))) 
    
    def test_get_target_filename(self):
        """Test if get_filename returns right name for dll for given mmp"""
        assert self.tc1_name == self.tcp.get_target_filename(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')))
    
    def test_get_libraries(self):
        """Test if get_harness returns right harness for given mmp"""
        assert self.tc1_libraries == self.tcp.get_libraries(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')))
    
    def test_get_harness(self):
        """Test if get_harness returns right harness for given mmp"""
        assert self.tc1_harness == self.tcp.get_harness(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')))
    
    def test_read_information_method(self):
        """Test if read_information_from_mmp returns wanted output for given parameter and mmp-file"""
        assert self.tc1_all == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')), 0)
        assert self.tc1_no_harness == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')), 1)
        assert self.tc1_name_type == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')), 2)
        assert self.tc1_name == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')), 3)
        assert self.tc1_type == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')), 4) 
        assert self.tc1_libraries == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')), 5)
        assert self.tc1_harness == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')), 6)
        assert self.tc1_iftest_name == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[4], 'if_test.mmp')), 3)
        assert self.tc1_iftest_type == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[4], 'if_test.mmp')), 4) 
        assert self.tc1_iftest_harness == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[4], 'if_test.mmp')), 6)
        assert self.tc1_dll_type == self.tcp.read_information_from_mmp(os.path.normpath(os.path.join(self.path_list[0], 'tc1.mmp')), 7)
        
class TestParsers(mocker.MockerTestCase):
    """Testing Parsers functionality"""
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
        
    def setUp(self):
        pass
