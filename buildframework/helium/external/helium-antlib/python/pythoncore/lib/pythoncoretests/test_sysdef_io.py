#============================================================================ 
#Name        : test_sysdef_io.py
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

from cStringIO import StringIO
import random
import tempfile
import os
import logging
import unittest
from sysdef.io import FlashImageSizeWriter

_logger = logging.getLogger('test.sysdef.io')
logging.basicConfig(level=logging.INFO)

class FlashImageSizeWriterTest(unittest.TestCase):
    """Verifiying sysdef/io module"""
        
    def test_write(self):
        """Verifiying write method"""
        (fileDes, filename) = tempfile.mkstemp()
        flashWriter = FlashImageSizeWriter(filename)
        oldOut = flashWriter._out
        flashWriter._out = duppedOut = StringIO()
        config_list = ("testconfig1","testconfig2")
        flashWriter.write(_sysdef(), config_list)
        flashWriter._out = oldOut  
        flashWriter.close()
        os.close(fileDes)
        os.unlink(filename)
        assert len(duppedOut.getvalue().splitlines()) == 9        

# dummy classes to emulate sysdef configuration
class _sysdef():
    """Emulate sysdef """
    def __init__(self):
        self.configurations = {"name1": _config("testconfig1"), "name2" : _config("testconfig2")}
class _config():
    """Emulate config"""
    def __init__(self, name):
        self.name = name
        self.units = (_unit(), _unit())
class _unit():
    """Emulate unit"""
    def __init__(self):
        self.name = "testUnit"
        self.binaries = (_binary(), _binary())
class _binary():
    """Emulate binary"""
    def __init__(self):
        self.name = "testBinary" 
        self.size = 10248
        self.rom_type = random.choice(("rom", "rofs1", "rofs2", "rofs3")) 
