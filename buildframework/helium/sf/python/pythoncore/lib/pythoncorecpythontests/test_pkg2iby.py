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

""" pkg2iby.py module tests. """

import tempfile
import os

def test_pkg2iby():
    import pkg2iby
    tmpdir = tempfile.mkdtemp()
    os.makedirs(os.path.join(tmpdir, 'epoc32', 'rom', 'include'))
    os.makedirs(os.path.join(tmpdir, 'epoc32', 'data'))
    os.makedirs(os.path.join(tmpdir, 'sf'))
    
    open(os.path.join(tmpdir, 'a.exe'), 'w').close()
    open(os.path.join(tmpdir, 'a.dat'), 'w').close()
    open(os.path.join(tmpdir, 'sf', 'a.script'), 'w').close()
    
    (f_desc, filename) = tempfile.mkstemp()
    f_file = os.fdopen(f_desc, 'w')
    f_file.write(r'"/sf/a.script"-"c:\a.script"' + '\n')
    f_file.write(r'"/a.exe"-"c:\graphics\a.exe"' + '\n')
    f_file.write(r'"/a.dat"-"c:\graphics\a.dat"' + '\n')
    f_file.close()
    
    pkg2iby.generateromcontent(tmpdir, 'tef', [filename])
    assert os.path.exists(os.path.join(tmpdir, 'epoc32', 'data', 'atsautoexec.bat'))
    assert os.path.exists(os.path.join(tmpdir, 'epoc32', 'rom', 'include', 'atsauto.iby'))
    