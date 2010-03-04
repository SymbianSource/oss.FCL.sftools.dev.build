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

import unittest
import dependancygraph
import logging
import tempfile
import os
import sys

_logger = logging.getLogger('test.dependancygraph')
logging.basicConfig(level=logging.INFO)

class DependancygraphTest(unittest.TestCase):
        
    def test_dependancygraph(self):
        (fd, filename) = tempfile.mkstemp()
        f = os.fdopen(fd, 'w')
        f.write('test')
        f.close()
        path1 = None
        path2 = None
        for p in sys.path:
            for x in [p, os.path.join(p, '..')]:
                if os.path.exists(x) and os.path.isdir(x):
                    for egg in os.listdir(x):
                        if egg.endswith('.egg'):
                            if path1 == None:
                                path1 = x
                            if path1 and path1 != x:
                                path2 = x
        dependancygraph.createGraph(os.path.join(os.environ['TEST_DATA'], 'data', 'ivy.xml'), filename, path1, path2, False)