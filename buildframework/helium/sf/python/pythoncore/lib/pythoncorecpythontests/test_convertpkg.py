#============================================================================ 
#Name        : test_ant.py 
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

""" convertpkg.py module tests. """

import tempfile
import os

def test_convertpkg():
    import convertpkg
    tmpdir = tempfile.mkdtemp()
    
    (f_desc, pkgfile) = tempfile.mkstemp()
    f_file = os.fdopen(f_desc, 'w')
    f_file.write(r'"/sf/a.script"-"c:\a.script"' + '\n')
    f_file.close()
    
    convertpkg.convertpkg(pkgfile, tmpdir, 'tef')
    
    assert os.path.exists(os.path.join(tmpdir, 'bld.inf'))
    assert os.path.exists(os.path.join(tmpdir, '1', 'group', 'test.mmp'))
    