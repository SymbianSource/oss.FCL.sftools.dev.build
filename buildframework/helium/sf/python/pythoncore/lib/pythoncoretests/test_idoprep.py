#============================================================================ 
#Name        : test_idoprep.py
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
""" tests IDO preperation"""

import tempfile
import os
import logging
import unittest
import idoprep
import ido

_logger = logging.getLogger('test.idoprep')
logging.basicConfig(level=logging.INFO)

class IDOPrepTest(unittest.TestCase):
    """Verifiying idoprep module"""
    def setUp(self):
        """called before any of the tests are run"""
        self.server = os.path.join(os.environ['TEST_DATA'], "data/symrec/GRACE/")

    def test_get_s60_env_details_valid(self):
        """Verifiying get_s60_env_details(valid args) method"""
        (fileDes, cacheFilename) = tempfile.mkstemp()
        resultname = idoprep.get_s60_env_details(self.server, "service", "product", "release_1", "(?:_\\d{3})?", cacheFilename , 1 , None)
        os.close(fileDes)
        os.unlink(cacheFilename)
        assert resultname[0] is not None


    def test_get_s60_env_details_invalid(self):
        """Verifiying get_s60_env_details(invalid args) method"""
        (fileDes, cacheFilename) = tempfile.mkstemp()
        self.assertRaises(Exception, idoprep.get_s60_env_details, self.server, "service", "product", "dummy", "(?:_\\d{3})?", cacheFilename , None, None)
        os.close(fileDes)
        os.unlink(cacheFilename)


    def test_get_version_valid(self):
        """Verifiying get_version method"""
        (fileDes, cacheFilename) = tempfile.mkstemp()
        result = idoprep.get_s60_env_details(self.server, "service", "product", "release_1", "(?:_\\d{3})?", cacheFilename , None, None)
        versionFilename = os.path.join(tempfile.gettempdir(), "s60_version.txt")
        versionFile = open(versionFilename,'w')
        resultname = os.path.basename(result[0])
        versionFile.write(resultname)
        versionFile.close()
        version = idoprep.get_version(tempfile.gettempdir(), resultname)
        os.close(fileDes)
        os.unlink(cacheFilename)
        os.unlink(versionFilename)
        assert version.strip() == resultname

    def test_get_version_invalid(self):
        """Verifiying get_version(invalid args) method"""
        version = idoprep.get_version('','test')
        assert version is None

    def test_create_ado_mapping(self):
        """Verifiying create_ado_mapping method"""
        (sysdefFileDes, sysdefConfig) = tempfile.mkstemp()
        (adoFileDes, adoMappingFile) = tempfile.mkstemp()
        buildDrive = tempfile.gettempdir() 
        adoQualityDirs = None
        testSysdefFile = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad', 'layers.sysdef.xml')
        os.write(sysdefFileDes, testSysdefFile)
        os.close(sysdefFileDes)
        idoprep.create_ado_mapping(sysdefConfig, adoMappingFile, 'false', buildDrive, adoQualityDirs)
        os.unlink(sysdefConfig)
        os.close(adoFileDes)
        adoFile = open(adoMappingFile, 'r')
        adoMappingFileContents = adoFile.readlines()
        adoFile.close()
        os.unlink(adoMappingFile)
        assert len(adoMappingFileContents) >= 1