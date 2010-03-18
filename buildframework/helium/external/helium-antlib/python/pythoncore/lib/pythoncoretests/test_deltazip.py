#============================================================================ 
#Name        : test_deltazip.py 
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

""" Unit tests for the delta zip tool.

"""

from __future__ import with_statement
import unittest
import delta_zip
import logging
import os
import sys
import tempfile

class DeltaZipTest( unittest.TestCase ):
    
    def setUp(self):
        self.cwd_backup = os.getcwd()
        self.logger = logging.getLogger('test.deltazip')
        self.root = os.environ['TEST_DATA']
        self.output = os.path.join(tempfile.gettempdir(), 'deltazip')
        self.output2 = os.path.join(tempfile.gettempdir(), 'deltazip2')
        
        logging.basicConfig(level=logging.INFO)

    def test_MD5SignatureBuilder(self):
        
        output = os.path.join(self.output2, 'md5_list.txt')
        md5output = os.path.join(self.output2, 'delta.md5')
        
        if os.path.exists(output):
            os.remove(output)
        
        sig = delta_zip.MD5SignatureBuilderEBS(self.root, 1, self.output2, '', output)
        sig.write_build_file()
        if sys.platform == 'win32':
            assert os.path.splitdrive(self.root)[0] + os.sep not in open(output).read()
        assert os.path.exists(output)
    def test_DeltaZipBuilder(self):
        if not os.path.exists(self.output):
            os.mkdir(self.output)
      
        md5output = os.path.join(self.output, 'delta.md5')
        oldmd5output = os.path.join(self.output, 'olddelta.md5')
      
        thisfile = os.path.abspath(__file__)
        md5string = """
Host:fasym014
Username:ssteiner
Date-Time:Fri Aug 17 08:47:40 2007
Version:0.02
Directory:z:\
FileList:z:\output/delta_zip\list_files.txt
Exclusion(s):
Inclusion(s):
----------------
%s TYPE=unknown format MD5=34dcda0d351c75e4942b55e1b2e2422f
        """ % thisfile
        

        tempoutput = open(md5output, 'w')
        tempoutput.write(md5string)
        tempoutput.close()
        
        md5string = """
Host:fasym014
Username:ssteiner
Date-Time:Fri Aug 17 08:47:40 2007
Version:0.02
Directory:z:\
FileList:z:\output/delta_zip\list_files.txt
Exclusion(s):
Inclusion(s):
----------------
%s TYPE=unknown format MD5=34dcda0d351c75e4942b55e1b2e2422g
        """ % thisfile
        
        tempoutput = open(oldmd5output, 'w')
        tempoutput.write(md5string)
        tempoutput.close()
        
        deltazipfile = os.path.join(self.output, 'delta.zip')
        deltaantfile = os.path.join(self.output, 'delta.ant.xml')
        deletefile = os.path.join(self.output, 'delta_zip_specialInstructions.xml')
        
      
        delta = delta_zip.DeltaZipBuilder(self.root, self.output, oldmd5output, md5output)
        delta.create_delta_zip(deltazipfile, deletefile, 1, deltaantfile)

    def test_changedFiles(self):
        dir1 = tempfile.mkdtemp()
        dir2 = tempfile.mkdtemp()
        
        with open(os.path.join(dir1, '1'), 'w') as f1:
            f1.write('Directory:%s\n' % self.root)
            f1.write('myfile1 TYPE=unknown format MD5=34dcda0d351c75e4942b55e1b2e2422g')
        with open(os.path.join(dir2, '2'), 'w') as f2:
            f2.write('Directory:%s\n' % self.root)
            f2.write('myfile1 TYPE=unknown format MD5=34dcda0d351c75e4542b55e1b2e2422g')
        
        assert delta_zip.changedFiles(dir1, dir2) == [os.path.join(self.root, 'myfile1')]

    def tearDown(self):
        """ Restore path """
        os.chdir(self.cwd_backup)