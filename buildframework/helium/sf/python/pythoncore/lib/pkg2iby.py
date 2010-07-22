#============================================================================ 
#Name        : pkg2iby.py 
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
import ats3
import os

def main():
    if len(sys.argv) < 3:
        print 'Usage: ' + sys.argv[0] + ' builddrive tef pkg1 pkg2 ..'
        sys.exit(1)
    generateromcontent(sys.argv[1], sys.argv[2], sys.argv[3:])

def generateromcontent(drive, testtype, pkgs):
    ibyfilename = os.path.join(drive + os.sep, 'epoc32', 'rom', 'include', 'atsauto.iby')
    execfilename = os.path.join(drive + os.sep, 'epoc32', 'data', 'atsautoexec.bat')
    rtestexecfilename = os.path.join(drive + os.sep, 'epoc32', 'data', 'atsrtestexec.bat')
    dummyexecfilename = os.path.join(drive + os.sep, 'epoc32', 'data', 'dummy.bat')
    pkgfilesnames = []
    for p in pkgs:
        pkgfilesnames.append(os.path.join(drive + os.sep, p))
    pkg_parser = ats3.parsers.PkgFileParser(drive=drive)
    pkgfiles = pkg_parser.read_pkg_file(pkgfilesnames)
    
    writeautoexec = False
    
    myiby = open(ibyfilename, 'w')
    atsautoexec = open(execfilename, 'w')
    atsrtestexec = open(rtestexecfilename, 'w')
    dummyexec = open(dummyexecfilename, 'w')
    dummyexec.close()
    
    myiby.write("#ifndef __ATSAUTO_IBY__\n")
    myiby.write("#define __ATSAUTO_IBY__\n")
    
    atsautoexec.write(r'md c:\logs' + '\n')
    atsautoexec.write(r'md c:\logs\testresults' + '\n')
    atsautoexec.write(r'md c:\logs\testexecute' + '\n')
    
    for src, dst, filetype, _ in pkgfiles:
        (_, dst) = os.path.splitdrive(dst)
        dst_nodrive = 'atsdata' + dst
        dst = r'z:\atsdata' + dst
        myiby.write('data=' + src + ' ' + dst_nodrive + '\n')
        if 'testscript' in filetype and testtype == 'tef':
            atsautoexec.write('testexecute.exe ' + dst + '\n')
            atsautoexec.write('thindump -nop c:\\logs\\testexecute\\' + os.path.basename(dst.replace('.script', '.htm')) + '\n')
            writeautoexec = True
        if 'testscript' in filetype and testtype == 'mtf':
            atsautoexec.write('testframework.exe ' + dst + '\n')            
            atsautoexec.write('thindump -nop c:\\logs\\testresults\\' + os.path.basename(dst.replace('.script', '.htm')) + '\n')
            writeautoexec = True
        if '.exe' in dst and testtype == 'rtest':
            atsrtestexec.write(dst + '\n')
            writeautoexec = True
    if writeautoexec:
        myiby.write("#include <thindump.iby>\n")
        myiby.write(r'data=' + execfilename + ' autoexec.bat' + '\n')
        if testtype == 'rtest':
            atsautoexec.write(r'runtests \sys\bin\atsrtestexec.bat' + '\n')
            myiby.write(r'data=' + rtestexecfilename + r' \sys\bin\atsrtestexec.bat' + '\n')
            
        myiby.write(r'data=' + dummyexecfilename + r' z:\dummytest.txt' + '\n')
        atsautoexec.write(r'RUNTESTS z:\dummytest.txt -p')
    myiby.write("#endif\n")
    myiby.close()
    atsautoexec.close()
    atsrtestexec.close()
    
if __name__ == "__main__":
    main()