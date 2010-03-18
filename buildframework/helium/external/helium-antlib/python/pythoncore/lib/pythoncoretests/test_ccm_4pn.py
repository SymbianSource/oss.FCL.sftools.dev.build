#============================================================================ 
#Name        : test_ccm_4pn.py 
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

""" Test cases for ccm python toolkit.

"""
import unittest
import sys
import ccm
import logging


logger = logging.getLogger('test.ccm')


class FourPartNameTest(unittest.TestCase):

    def testSimpleFourPartNameParsing(self):
        """Test the parsing of a simple four part name"""
        strfpn = "simple.test-myversion1:ascii:mydb#1"
        fpn = ccm.FourPartName(strfpn)
        assert fpn.name == "simple.test"
        assert fpn.version == "myversion1"
        assert fpn.type == "ascii"
        assert fpn.instance == "mydb#1"
        assert strfpn == str(fpn)
        assert strfpn == fpn.objectname

    def testSpacesFourPartNameParsing(self):
        """Test the parsing of a four part name that contains spaces"""
        strfpn = "simple test.ext - myversion1 :ascii:mydb#1"
        fpn = ccm.FourPartName(strfpn)
        assert fpn.name == "simple test.ext "
        assert fpn.version == " myversion1 "
        assert fpn.type == "ascii"
        assert fpn.instance == "mydb#1"
        assert strfpn == str(fpn)
        assert strfpn == fpn.objectname

    def testHyphenedFourPartNameParsing(self):
        """Test the parsing of a hyphened four part name"""
        strfpn = "simple-test.ext-myversion1:ascii:mydb#1"
        fpn = ccm.FourPartName(strfpn)
        assert fpn.name == "simple-test.ext"
        assert fpn.version == "myversion1"
        assert fpn.type == "ascii"
        assert fpn.instance == "mydb#1"
        assert strfpn == str(fpn)
        assert strfpn == fpn.objectname
   
    def testReleasedefParsing(self):
        """Test the parsing of a releasedef four part name"""
        strfpn = "myproject:myversion1:releasedef:mydb#1"
        fpn = ccm.FourPartName(strfpn)
        assert fpn.name == "myproject"
        assert fpn.version == "myversion1"
        assert fpn.type == "releasedef"
        assert fpn.instance == "mydb#1"
        assert strfpn == str(fpn)
        assert strfpn == fpn.objectname

    def testEquality(self):
        """Test equality and same familly function"""
        # testing different name
        fpn1 = ccm.FourPartName("simple.test-myversion1:ascii:mydb#1")
        fpn2 = ccm.FourPartName("simple.testx-myversion1:ascii:mydb#1")
        assert fpn1 != fpn2
        assert not fpn1.is_same_family(fpn2), "Should not be from the same family"
        # testing different version
        fpn2 = ccm.FourPartName("simple.test-myversion2:ascii:mydb#1")
        assert fpn1 != fpn2
        assert fpn1.is_same_family(fpn2), "Should be from the same family"
        # testing different type
        fpn2 = ccm.FourPartName("simple.test-myversion1:ascii2:mydb#1")
        assert fpn1 != fpn2
        assert not fpn1.is_same_family(fpn2), "Should not be from the same family"
        # testing different instance
        fpn2 = ccm.FourPartName("simple.test-myversion1:ascii:mydb#2")
        assert fpn1 != fpn2
        assert not fpn1.is_same_family(fpn2), "Should not be from the same family"

    def testConvert(self):
        # Test task displayname tranformation
        fpn = ccm.FourPartName("Task mydb#123")
        assert fpn.type == "task"
        # Test folder displayname tranformation
        fpn = ccm.FourPartName("Folder mydb#123")
        assert fpn.type == "folder"
        # Test Release tag displayname tranformation
        fpn = ccm.FourPartName("mc/integration")
        assert fpn.name == "mc"
        assert fpn.version == "integration"
        assert fpn.type == "releasedef"
        assert fpn.instance == "1"

        fpn = ccm.FourPartName("BTHID/3.2_2007_wk03")
        assert fpn.name == "BTHID"
        assert fpn.version == "3.2_2007_wk03"
        assert fpn.type == "releasedef"
        assert fpn.instance == "1"
        
        fpn = ccm.FourPartName("DRM_0.9")
        assert fpn.name == "none"
        assert fpn.version == "DRM_0.9"
        assert fpn.type == "releasedef"
        assert fpn.instance == "1"

        try:
            fpn = ccm.FourPartName("task mydb#123")
            assert False, "Should raise InvalidFourPartNameException when parsing'task mydb#123'"
        except ccm.InvalidFourPartNameException, e:
            pass

        try:
            fpn = ccm.FourPartName("folder mydb#123")
            assert False, "Should raise InvalidFourPartNameException when parsing'folder mydb#123'"
        except ccm.InvalidFourPartNameException, e:
            pass
            
            
class InvalidFourPartNameExceptionTest(unittest.TestCase):
    def testOutput(self):
        """ Test the exception shows the arguments. """
        ex = ccm.InvalidFourPartNameException('foo')
        assert str(ex) == 'foo'


if __name__ == "__main__":
    unittest.main()
