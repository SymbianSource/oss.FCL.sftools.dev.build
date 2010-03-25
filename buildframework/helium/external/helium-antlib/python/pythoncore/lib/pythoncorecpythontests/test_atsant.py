#============================================================================ 
#Name        : test_atsant.py 
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

""" atsant.py module tests. """

import os
import logging
_logger = logging.getLogger('test.atsant')

import atsant

def test_atsant():
    """test atsant and check 3 files in the file"""
    files = atsant.files_to_test(os.path.join(os.environ['TEST_DATA'], 'data/packageiad/layers.sysdef.xml'), None, None, 'z:')
    assert len(files) == 3