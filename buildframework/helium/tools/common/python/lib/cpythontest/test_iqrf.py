#============================================================================ 
#Name        : test_iqrf.py 
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

""" Test cases for iqrf module. """
import unittest
import os
import imaker.iqrf


class Test_iQRF(unittest.TestCase):
    """ Test for iQRF data access. """
    
    def test_file_parsing_5250(self):
        """ Testing if the iqrf module is able to load the 5250 configuration. """
        root = imaker.iqrf.load(os.path.join(os.environ['HELIUM_HOME'], "tests/data/iqrf/imaker_5250.xml"))        
        assert root.result != None
        assert len(root.result.targets) == 228
        assert len(root.result.interfaces) == 1
        assert len(root.result.configurations) == 6
        
        # testing a configurations
        assert root.result.configurations[0].name == "image_conf_product52.mk"
        assert root.result.configurations[0].filePath == r"\epoc32\rom\config\platform\product52\image_conf_product52.mk"
        assert len(root.result.configurations[0].targetrefs) == 38
        assert root.result.configurations[0].targetrefs[0].name == "all"
        
        # testing interfaces
        print "root.result.configurations[0].filePath: %s" % root.result.configurations[0].filePath
        assert len(root.result.interfaces[0].configurationElements) == 516
