#============================================================================ 
#Name        : test_compilation.py 
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

""" Unit test case for compilation.py """

import unittest
import compilation
import logging
import os
import sysdef.api
import tempfile
from shutil import rmtree

_logger = logging.getLogger('test.compilation')
logging.basicConfig(level=logging.INFO)

class CompilationTest(unittest.TestCase):
    
    def test_read_output_binaries_per_unit_with_empty_logs_list(self):
        """ Testing read_output_binaries_per_unit method with empty log list """
        sysdefpath = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'sysdefs', 'canonical_system_definition.xml')
        sysDef = sysdef.api.SystemDefinition(sysdefpath)
        bsl = compilation.BinarySizeLogger(sysDef)
        self.assertRaises(Exception, bsl.read_output_binaries_per_unit, "")

    def test_read_output_binaries_per_unit(self):
        """ Testing read_output_binaries_per_unit method """
        sysdefpath = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'sysdefs', 'canonical_system_definition.xml')
        sysDef = sysdef.api.SystemDefinition(sysdefpath)
        bsl = compilation.BinarySizeLogger(sysDef)
        loglist = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'logs', 'test_build.log')
        bsl.read_output_binaries_per_unit(loglist.split(';'))
        
    def test_read_binary_sizes_in_rom_output_logs_with_empty_logs_list(self):
        """ Testing read_binary_sizes_in_rom_output_logs method with empty log list """
        sysdefpath = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'sysdefs', 'canonical_system_definition.xml')
        sysDef = sysdef.api.SystemDefinition(sysdefpath)
        bsl = compilation.BinarySizeLogger(sysDef)
        self.assertRaises(Exception, bsl.read_binary_sizes_in_rom_output_logs, "")

    def test_read_binary_sizes_in_rom_output_logs(self):
        """ Testing read_binary_sizes_in_rom_output_logs method """
        sysdefpath = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'sysdefs', 'canonical_system_definition.xml')
        sysDef = sysdef.api.SystemDefinition(sysdefpath)
        bsl = compilation.BinarySizeLogger(sysDef)
        loglist = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'logs', 'test_build.log')
        bsl.read_output_binaries_per_unit(loglist.split(';'))
        romloglist = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'logs', 'test_rom.log')
        bsl.read_binary_sizes_in_rom_output_logs(romloglist.split(';'))
        
    def test_write2csvfile(self):
        """ Testing write2csvfile method """
        sysdefpath = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'sysdefs', 'canonical_system_definition.xml')
        sysDef = sysdef.api.SystemDefinition(sysdefpath)
        bsl = compilation.BinarySizeLogger(sysDef)
        tmpdir = tempfile.mkdtemp()
        output = os.path.join(tmpdir, 'test_flash_image_size_data.csv')
        sysdeflist = os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'sysdefs', 'build.sysdef.xml') + ", " + os.path.join(os.environ['TEST_DATA'], 'data', 'compile', 'sysdefs', 'layers.sysdef.xml')
        bsl.write2csvfile(output, sysdeflist.split(','))
        tempFile = open(output,'r')
        contents = tempFile.readlines()
        tempFile.close()
        rmtree(tmpdir)
        assert len(contents) > 0
