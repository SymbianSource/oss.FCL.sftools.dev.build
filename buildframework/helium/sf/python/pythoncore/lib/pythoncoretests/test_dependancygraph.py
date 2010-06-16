#============================================================================ 
#Name        : test_dependancygraph.py 
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
"""test dependancy graph"""

import unittest
import dependancygraph
import logging
import tempfile
import os
import sys

_logger = logging.getLogger('test.dependancygraph')
logging.basicConfig(level=logging.INFO)

class DependancygraphTest(unittest.TestCase):
    """ Acceptance tests for dependancygraph.py """
    def test_dependancygraph(self):
        """test dependancy graph"""
        (f_d, filename) = tempfile.mkstemp()
        f_file = os.fdopen(f_d, 'w')
        f_file.write('test')
        f_file.close()
        path1 = None
        path2 = None
        for p_path in sys.path:
            for xxx in [p_path, os.path.join(p_path, '..')]:
                if os.path.exists(xxx) and os.path.isdir(xxx):
                    for egg in os.listdir(xxx):
                        if egg.endswith('.egg'):
                            if path1 == None:
                                path1 = xxx
                            if path1 and path1 != xxx:
                                path2 = xxx
        if path1 and path2:
            dependancygraph.createGraph(os.path.join(os.environ['TEST_DATA'], 'data', 'ivy.xml'), filename, path1, path2, False)