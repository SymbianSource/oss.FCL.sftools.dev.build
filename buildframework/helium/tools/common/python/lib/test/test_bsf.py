#============================================================================ 
#Name        : test_bsf.py 
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

""" Some test cases for BSF file handling.
"""

import logging
import os
import unittest

import bsf


# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('test.bsf')


class BSFTest(unittest.TestCase):
    """ Implementation of BSF test cases. """
    
    def test_bsf(self):
        """ Testing all methods from bsf class.
        """
        bsfs = bsf.read_all(os.path.join(os.environ['HELIUM_HOME'],'tests/data/bsf'))
        assert len(bsfs.keys()) == 9, "Could not find 9 bsf files."
        assert bsfs['product'] is not  None, "Could not find product."
        assert bsfs['product'].is_variant() == True, "'product' should be a variant"
        assert bsfs['product'].is_virtual_variant() == False, "'product' should not be a virtual variant"
        assert bsfs['variant'].is_virtual_variant() == True, "'variant' should be a virtual variant"
        assert bsfs['variant'].customize() == "armv5", "'variant' should customize armv5."
        assert bsfs['product'].customize() == "platform", "'product' should customize armv5."
        assert bsfs['variant'].compile_with_parent() == True, "'variant' should be compile with its parent."
        assert bsfs['product'].compile_with_parent() == False, "'product' should not be compile with its parent."


 