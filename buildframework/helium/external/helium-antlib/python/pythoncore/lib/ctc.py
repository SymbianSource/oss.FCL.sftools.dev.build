#============================================================================ 
#Name        : ctc.py 
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

import os
import ftplib


class MonSymFTPUploader:
    """ This class implement an uploader for MON.SYM file. """
    
    def __init__(self, server, paths, diamondsid):
        """ Upload the files discovered under the paths,
            and upload them under the FTP server.
        """
        self.server = server
        self.paths = paths
        self.diamondsid = diamondsid
        self.ftp = None
    
    def upload(self):
        self._open()
        """ Proceed to the upload. """
        monsyms = []
        i = 1
        for p in self.paths:
            if os.path.exists(p) and os.path.isfile(p):
                # ftp://1.2.3.4/ctc_helium/[diamonds_id]/mon_syms/2/mon.sym
                outputdir = "ctc_helium/%s/mon_syms/%d" % (self.diamondsid , i)
                output = outputdir + "/MON.SYM"
                self._ftpmkdirs(outputdir)
                print "Copying %s under %s" % (p, output)
                self._send(p, output)
                monsyms.append(output)
                i += 1
        self._close()
        return monsyms

    def _open(self):
        self.ftp = ftplib.FTP(self.server, 'anonymous', '')
    
    def _close(self):
        self.ftp.quit()

    def _ftpmkdirs(self, dir):
        pwd = self.ftp.pwd()
        for d in dir.split('/'):
            if len(d)!=0:
                try:
                    print "Creating %s under %s" % (d, self.ftp.pwd())
                    self.ftp.mkd(d)
                except ftplib.error_perm, exc:
                    pass
                self.ftp.cwd(d)
        self.ftp.cwd(pwd)
    
    def _send(self, src, dst):
        self.ftp.storbinary("STOR " + dst, open(src, "rb"), 1024)

