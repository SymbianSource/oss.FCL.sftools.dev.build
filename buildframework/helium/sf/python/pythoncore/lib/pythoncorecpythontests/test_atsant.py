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
import tempfile
import shutil
_logger = logging.getLogger('test.atsant')

import atsant

def test_atsant_multipledrop():
    """test atsant and check 3 files in the file"""
    files = atsant.files_to_test(os.path.join(os.environ['TEST_DATA'], 'data/packageiad/layers.sysdef.xml'), None, None, 'z:', 'false')
    assert len(files) == 3

def test_atsant_singledrop():
    """test atsant and check 1 files in the file"""
    files = atsant.files_to_test(os.path.join(os.environ['TEST_DATA'], 'data/packageiad/layers.sysdef.xml'), None, None, 'z:', 'true')
    assert len(files) == 1

def test_IConfigATS():
    """test I config ATS"""
    tmpdir = tempfile.mkdtemp()
    shutil.copy(os.path.join(os.environ['TEST_DATA'], 'data', 'example_corernd.iconfig.xml'), os.path.join(tmpdir, 'example_corernd.iconfig.xml'))
    open(os.path.join(tmpdir, 'RX-60_00_rnd.core.fpsx'), 'w').close()
    open(os.path.join(tmpdir, 'RX-60_00.01_rnd.rofs2.fpsx'), 'w').close()
    open(os.path.join(tmpdir, 'RX-60_00_rnd.rofs3.fpsx'), 'w').close()
    open(os.path.join(tmpdir, 'RX-60_00_rnd.udaerase.fpsx'), 'w').close()
    i_c = atsant.IConfigATS(tmpdir, '')
    i_c.findimages()
