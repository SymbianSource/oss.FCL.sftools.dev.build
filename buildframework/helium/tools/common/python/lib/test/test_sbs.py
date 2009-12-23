#============================================================================ 
#Name        : test_sbs.py 
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
import logging
import sys
import os
import tempfile

_logger = logging.getLogger('test.sbs')
logging.basicConfig(level=logging.INFO)

class SBSTest(unittest.TestCase):
        
    def setUp(self):
        sys.path.append(os.path.join(os.environ['HELIUM_HOME'], 'tools/common/python/scripts'))
        
    def test_sbs(self):
        #import filter_metadatalog
        import sbsscanlogmetadata
        sbs = sbsscanlogmetadata.SBSScanlogMetadata()
        (_, filename) = tempfile.mkstemp()
        sbs.open(filename)
        sbs.write(open(os.path.join(os.environ['HELIUM_HOME'], 'tests/data/scanlog/all_regex_type.log')).read())
        sbs.close()
        
    def test_sbsscanlog(self):
        import sbsscanlog
        filter = sbsscanlog.SBSScanlog()
        (_, filename) = tempfile.mkstemp()
        filter.open(filename)
        filter.write('hi')
        filter.summary()
        filter.close()