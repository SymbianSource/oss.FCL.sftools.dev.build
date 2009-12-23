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

_logger = logging.getLogger('test.ido')
logging.basicConfig(level=logging.INFO)

class IDOTest(unittest.TestCase):
        
    def test_ido(self):
        ido.is_in_interval(1, '01:02', 2, '02:03')