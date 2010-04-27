#============================================================================ 
#Name        : test_build_io.py 
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

""" Test the build.io module. """

import logging
import unittest
import os
import build.io


logger = logging.getLogger('test.build.io')


class AbldLogWhatReaderTest(unittest.TestCase):
    """ Test reading Symbian build logs for extracting abld -what sections. """
    
    def test_abld_what_parsing(self):
        """ Basic abld -what section parsing. """ 
        reader = build.io.AbldLogWhatReader(os.path.join(os.environ['TEST_DATA'], 'data/build/io/abld_what.log'))
        reader_iter = iter(reader)
        (component1, binaries1) = reader_iter.next()
        assert component1 == 'ibusal_chipset_product'
        assert binaries1 == [r'\epoc32\release\ARMV5\UDEB\_product_NaviScrollPdd.pdd',
                             r'\epoc32\release\ARMV5\UDEB\_product_NaviScrollPdd.pdd.map']
        
        (component2, binaries2) = reader_iter.next()
        assert component2 == 'ibusal_chipset_product2'
        assert binaries2 == [r'\epoc32\release\ARMV5\UDEB\_product2_accelerometerpdd.pdd',
                             r'\epoc32\release\ARMV5\UDEB\_product2_accelerometerpdd.pdd.map']

class RombuildLogBinarySizeReaderTest(unittest.TestCase):
    """ Test reading Symbian ROM build logs for extracting binaries and their sizes. """
    
    def test_rom_log_parsing(self):
        """ Basic ROM log binary size parsing. """ 
        reader = build.io.RombuildLogBinarySizeReader(os.path.join(os.environ['TEST_DATA'], 'data/build/io/test_rom.log'))
        reader_iter = iter(reader)
        (binary, size, rom_type) = reader_iter.next()
        assert binary == r'\epoc32\release\ARMV5\urel\__ekern.exe'
        assert size == 221788
        assert rom_type == 'rom'
        
        (binary, size, rom_type) = reader_iter.next()
        assert binary == r'\epoc32\release\ARMV5\urel\elocd.ldd'
        assert size == 15192
        assert rom_type == 'rom'
        
        (binary, size, rom_type) = reader_iter.next()
        assert binary == r'\epoc32\release\ARMV5\urel\__medint.pdd'
        assert size == 2320
        assert rom_type == 'rom'
        
    def test_rofs_log_parsing(self):
        """ Basic ROFS log binary size parsing. """ 
        reader = build.io.RombuildLogBinarySizeReader(os.path.join(os.environ['TEST_DATA'], 'data/build/io/test_rofs.log'))
        reader_iter = iter(reader)
        (binary, size, rom_type) = reader_iter.next()
        assert binary == r'\epoc32\data\Z\Resource\ICL\jpegcodec_extra.rsc'
        assert size == 202
        assert rom_type == 'rofs'
        
        (binary, size, rom_type) = reader_iter.next()
        assert binary == r'\epoc32\release\ARMV5\urel\jpegcodec.dll'
        assert size == 89728
        assert rom_type == 'rofs'
        