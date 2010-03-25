#============================================================================ 
#Name        : test_symbian_raptor.py 
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
import logging
import os
import symbian.raptor

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('test.symbian.raptor')

class TestSymbianRaptor(unittest.TestCase):
    """ Test cases for Helium Symbian raptor module. """
    
    def test_raptor_installation_path(self):
        """ Test raptor installation when SBS_HOME is not set. """
        if "SBS_HOME" in os.environ: 
            del os.environ["SBS_HOME"]
        if os.path.sep == '\\':
            assert symbian.raptor.getSBSHome() != None


    def test_raptor_installation_path_home(self):
        """ Test raptor installation when SBS_HOME is set. """
        os.environ["SBS_HOME"] = r"c:/raptor"
        assert symbian.raptor.getSBSHome() == r"c:/raptor"

