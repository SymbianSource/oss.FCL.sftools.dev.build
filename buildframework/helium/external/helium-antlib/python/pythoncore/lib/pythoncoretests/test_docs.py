#============================================================================ 
#Name        : test_docs.py 
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

""" Unit test case for docs.py """

import unittest
import docs
import logging
import amara
import os
import sys
from cStringIO import StringIO

_logger = logging.getLogger('test.docs')
logging.basicConfig(level=logging.INFO)

class DocsTest(unittest.TestCase):
    
    def test_find_python_dependencies(self):
        """ Verifying find_python_dependencies method """
        
        old_stdout = sys.stdout
        sys.stdout = mystdout = StringIO()
        
        setpath = os.path.join(os.environ['TEST_DATA'], 'data', 'docs', 'helium', 'tools')
        
        print "Searching under " + setpath

        dbPath = os.path.join(os.environ['TEST_DATA'], 'data', 'docs', 'database_test.xml')
        dbPath = 'file:///'+ dbPath.replace('\\', '/')
        dbPrj = amara.parse(dbPath)
        
        docs.find_python_dependencies(setpath, dbPath, dbPrj)
        
        sys.stdout = old_stdout
        assert mystdout.getvalue().find("Python module : ant") != -1
        


        
        



    
