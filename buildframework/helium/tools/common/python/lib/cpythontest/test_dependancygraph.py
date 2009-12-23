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

_logger = logging.getLogger('test.dependancygraph')
logging.basicConfig(level=logging.INFO)

class DependancygraphTest(unittest.TestCase):
        
    def test_dependancygraph(self):
        (fd, filename) = tempfile.mkstemp()
        f = os.fdopen(fd, 'w')
        f.write('test')
        f.close()
        dependancygraph.createGraph(os.path.join(os.environ['HELIUM_HOME'], 'config/ivy/ivy.xml'), filename, os.path.join(os.environ['HELIUM_HOME'], 'external/python/lib'), os.path.join(os.environ['HELIUM_HOME'], 'extensions/nokia/external/python/lib'), False)