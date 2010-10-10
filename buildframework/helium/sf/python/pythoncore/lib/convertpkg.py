#============================================================================ 
#Name        : .py 
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
import sys
import os
from distutils import dir_util # pylint: disable-msg=E0611

def main():
    if len(sys.argv) < 3:
        print 'Usage: ' + sys.argv[0] + ' pkgsrc pkgdst test_type'
        sys.exit(1)
    convertpkg(sys.argv[1], sys.argv[2], sys.argv[3])

def convertpkg(srcs, dst, testtype):
    i = 1
    
    bldfile = open(os.path.join(dst, 'bld.inf'), 'w')
    
    for src in srcs.split(' '):
        bldfile.write('#include "' + str(i) + '/group/bld.inf"\n')
        srcfile = open(src)
        os.makedirs(os.path.join(dst, str(i), 'group'))
        dstfile = open(os.path.join(dst, str(i), 'group', os.path.basename(src)), 'w')
        for line in srcfile:
            if line.startswith('"') and not line.startswith('"\\') and not line.startswith('"/'):
                line = line.replace('"', '"' + os.path.dirname(src) + os.sep, 1)
            dstfile.write(line)
        srcfile.close()
        dstfile.close()
        
        customdir = os.path.join(os.path.dirname(src), 'custom')
        if os.path.exists(customdir):
            dir_util.copy_tree(customdir, os.path.join(dst, str(i), 'group', 'custom'))
        
        subbldfile = open(os.path.join(dst, str(i), 'group', 'bld.inf'), 'w')
        subbldfile.write('PRJ_TESTMMPFILES\n')
        subbldfile.write('test.mmp\n')
        subbldfile.close()
        
        submmpfile = open(os.path.join(dst, str(i), 'group', 'test.mmp'), 'w')
        submmpfile.write('TARGET        fake.exe\n')
        submmpfile.write('TARGETTYPE    exe\n')
        
        if testtype == 'tef':
            submmpfile.write('LIBRARY testexecuteutils.lib\n')
        elif testtype == 'mtf':
            submmpfile.write('LIBRARY testframeworkclient.lib\n')
        elif testtype == 'rtest':
            submmpfile.write('//rtest\n')
        elif testtype == 'stif':
            submmpfile.write('LIBRARY stiftestinterface.lib\n')
        elif testtype == 'sut':
            submmpfile.write('LIBRARY symbianunittestfw.lib\n')
        else:
            raise Exception('Test type unknown: ' + testtype)
        submmpfile.close()
        
        i += 1
        
    bldfile.close()
    
if __name__ == "__main__":
    main()