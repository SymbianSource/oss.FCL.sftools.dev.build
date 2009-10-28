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

import unittest
import delta_zip
import logging
import os

class DeltaZipTest( unittest.TestCase ):
    
    def setUp(self):
        self.cwd_backup = os.getcwd()
        self.helium_home = os.environ["HELIUM_HOME"]
        self.logger = logging.getLogger('test.deltazip')
        self.root = os.path.join(self.helium_home, r'tools\common\python\lib')
        self.output = os.path.join(os.environ['TEMP'], 'deltazip')
        self.output2 = os.path.join(os.environ['TEMP'], 'deltazip2')
        
        logging.basicConfig(level=logging.INFO)

    def test_MD5SignatureBuilder(self):
        
        output = os.path.join(self.output2, 'md5_list.txt')
        md5output = os.path.join(self.output2, 'delta.md5')
        
        if os.path.exists(output):
            os.remove(output)
        
        sig = delta_zip.MD5SignatureBuilderEBS(self.root, 1, self.output2, '', output)
        sig.write_build_file()
        
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

    def tearDown(self):
        """ Restore path """
        os.chdir(self.cwd_backup)