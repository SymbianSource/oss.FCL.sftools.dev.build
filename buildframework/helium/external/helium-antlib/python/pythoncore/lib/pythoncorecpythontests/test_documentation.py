#============================================================================ 
#Name        : test_documentation.py
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

import tempfile
import os
import logging
import unittest
import sys
from helium.documentation import APIDeltaWriter

_logger = logging.getLogger('test.documentation')
logging.basicConfig(level=logging.INFO)

class DocumentationTest(unittest.TestCase):
    """Verifiying documentation module"""
    def test_APIDeltaWriter(self):
        (fileDes, tempFileName) = tempfile.mkstemp()
        old_db = os.path.join(os.environ['TEST_DATA'], 'data', 'docs', 'sample_old_db.xml') 
        new_db = os.path.join(os.environ['TEST_DATA'], 'data', 'docs', 'sample_new_db.xml') 
        writer = APIDeltaWriter(old_db, new_db)
        saveout = sys.stdout
        sys.stdout = sys.stderr
        writer.write(tempFileName)
        os.close(fileDes)
        sys.stdout = saveout
        tempFile = open(tempFileName, 'r')
        content = tempFile.readlines()
        tempFile.close()
        os.unlink(tempFileName)
        assert len(content) == 12
