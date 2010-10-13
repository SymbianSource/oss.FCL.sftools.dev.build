#============================================================================ 
#Name        : test_packager_cli.py 
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
import unittestadditions
skipTest = False
try:
    import packager.cli
except ImportError:
    skipTest = True
import logging


#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('nokiatest.datasources')


class CliTest(unittest.TestCase):
    """ Verifying the datasource interface. """
    
    @unittestadditions.skip(skipTest)
    def test_cli(self):
        """ Check that --help-datasource works. """
        app = packager.cli.PackagerApp()
        ret = app.execute(['--help-datasource'])
        print ret
        assert ret == 0, "Return value for help must be 0."

        
