#============================================================================ 
#Name        : test_ido.py 
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
import ido
import logging
from datetime import datetime
from tempfile import mkstemp
import os

_logger = logging.getLogger('test.ido')
logging.basicConfig(level=logging.INFO)

class IDOTest(unittest.TestCase):
    """ Verifying ido.py """
        
    def test_ido(self):
        """ Verifying is_in_interval method """
        now = datetime.now()
        status = ido.is_in_interval(1, '00:00', 4, '12:00')

# commenting it temproarily, will have to add a correct assertion here
#        # in the odd week it should be True
#        if int(now.strftime("%W")).__mod__(2):
#            assert status == True
#        # in the even week it should be False
#        else :
#            assert status == False

    def test_ido_sysdef_valid(self):
        """ Verifying get_sysdef_location method with valid sysdef"""
        test_sysdef_file = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad', 'layers.sysdef.xml')
        location = ido.get_sysdef_location(test_sysdef_file); 
        assert location != None

    def test_ido_sysdef_invalid(self):
        """ Verifying get_sysdef_location method with invalid sysdef"""
        (fd, filename) = mkstemp()
        os.write(fd,'Test sysdef file')
        os.close(fd)
        location = ido.get_sysdef_location(filename); 
        os.unlink(filename)
        assert location == None
