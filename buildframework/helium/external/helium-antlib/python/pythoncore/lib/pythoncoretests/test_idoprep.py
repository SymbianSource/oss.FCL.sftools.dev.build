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

import tempfile
import os
import logging
import unittest
import idoprep
import sys
import ido

_logger = logging.getLogger('test.idoprep')
logging.basicConfig(level=logging.INFO)

class IDOPrepTest(unittest.TestCase):
    """Verifiying idoprep module"""
    def setUp(self):   
        self.server = os.path.join(os.environ['TEST_DATA'], "data/symrec/GRACE/")

    def test_validate_grace(self):
        """Verifiying validate(grace) method"""
        self.assertRaises(Exception, idoprep.validate, None, 'test', 'test', 'test')

    def test_validate_service(self):
        """Verifiying validate(service) method"""
        self.assertRaises(Exception, idoprep.validate, 'test', None, 'test', 'test')

    def test_validate_product(self):
        """Verifiying validate(product) method"""
        self.assertRaises(Exception, idoprep.validate, 'test', 'test', None, 'test')

    def test_validate_release(self):
        """Verifiying validate(release) method"""
        self.assertRaises(Exception, idoprep.validate, 'test', 'test', 'test', None) 

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
        (adoqtyFileDes, adoQualityMappingFile) = tempfile.mkstemp()
        buildDrive = tempfile.gettempdir() 
        adoQualityDirs = None
        testSysdefFile = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad', 'layers.sysdef.xml')
        os.write(sysdefFileDes, testSysdefFile)
        os.close(sysdefFileDes)
        idoprep.create_ado_mapping(sysdefConfig, adoMappingFile, adoQualityMappingFile, buildDrive, adoQualityDirs)
        os.unlink(sysdefConfig)                        
        os.close(adoFileDes)
        os.close(adoqtyFileDes)
        adoFile = open(adoMappingFile, 'r')
        adoMappingFileContents = adoFile.readlines()
        adoFile.close()
        adoQtyFile = open(adoQualityMappingFile, 'r')
        adoQualityMappingFileContents = adoQtyFile.readlines()
        adoQtyFile.close()
        os.unlink(adoMappingFile)                        
        os.unlink(adoQualityMappingFile)                        
        assert len(adoMappingFileContents) >= 1 and  len(adoQualityMappingFileContents) >= 1 

    def test_create_ado_mapping_adoqualitydirs(self):
        """Verifiying create_ado_mapping (with valid adoqualitydirs) method"""
        (sysdefFileDes, sysdefConfig) = tempfile.mkstemp()
        (adoFileDes, adoMappingFile) = tempfile.mkstemp()
        (adoqtyFileDes, adoQualityMappingFile) = tempfile.mkstemp()
        buildDrive = tempfile.gettempdir() 
        testSysdefFile = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad', 'layers.sysdef.xml')
        location = ido.get_sysdef_location(testSysdefFile)
        adoQualityDirs = (os.path.normpath(os.path.join(buildDrive, os.environ['EPOCROOT'], location))) 
        os.write(sysdefFileDes, testSysdefFile)
        os.close(sysdefFileDes)
        idoprep.create_ado_mapping(sysdefConfig, adoMappingFile, adoQualityMappingFile, buildDrive, adoQualityDirs)
        os.unlink(sysdefConfig)                        
        os.close(adoFileDes)
        os.close(adoqtyFileDes)
        adoFile = open(adoMappingFile, 'r')
        adoMappingFileContents = adoFile.readlines()
        adoFile.close()
        adoQtyFile = open(adoQualityMappingFile, 'r')
        adoQualityMappingFileContents = adoQtyFile.readlines()
        adoQtyFile.close()
        os.unlink(adoMappingFile)                        
        os.unlink(adoQualityMappingFile)                        
        assert len(adoMappingFileContents) >= 1 and  len(adoQualityMappingFileContents) >= 1 
