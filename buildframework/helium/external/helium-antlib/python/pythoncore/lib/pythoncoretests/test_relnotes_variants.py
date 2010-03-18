#============================================================================ 
#Name        : test_relnotes_variants.py 
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

""" 
Testing release notes variant related functionalities.
"""

import relnotes.variants
import unittest
import os

class ParseInfoTest(unittest.TestCase):

    def test_parsing(self):
        filename = logfile = os.path.join(os.environ['TEST_DATA'], 'data', 'XX_rnd_rofs2_langpack_01_info.txt')
        data = relnotes.variants.parseInfo(filename)
        
        print data
        
        assert len(data) == 4
        assert data['name'] == 'langpack_01'
        assert data['default'] == 'English (01)'
        assert data['languages'] == ['English', 'French', 'German', 'Italian', 'Portuguese', 'Spanish']
        assert data['language.ids'] == ['01', '02', '03', '05', '13', '04']

        