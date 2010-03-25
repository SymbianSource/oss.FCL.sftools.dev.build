#============================================================================ 
#Name        : test_sysdef.py 
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

""" Test cases for the sysdef module. """

import logging
import sys
import unittest
import os
import sysdef.api
import StringIO

# Uncomment this line to enable logging in this module, or configure logging elsewhere
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('test.sysdef')

class SysdefTest(unittest.TestCase):
    """ Testing sydef module. """
    
    def test_basic_parsing(self):
        """ A System Definition file can be parsed and information extracted. """
        sysDef = sysdef.api.SystemDefinition(os.path.join(os.environ['TEST_DATA'], 'data', 'sysdef2make', 'SDF.xml'))
        assert len(sysDef.configurations) == 4
        assert len(sysDef.layers) == 1
        assert len(sysDef.unitlists) == 1
        
        # UnitList
        assert sysDef.unitlists['unitlist1'].name == 'unitlist1'
        assert len(sysDef.unitlists['unitlist1'].units) == 3
        
        # Layer
        assert sysDef.layers['layer1'].name == 'layer1'
        assert len(sysDef.layers['layer1'].units) == 3

        # Configs
        assert sysDef.configurations['config1'].name == 'config1'
        assert len(sysDef.configurations['config1'].tasks) == 12

