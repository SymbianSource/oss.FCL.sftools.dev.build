#============================================================================ 
#Name        : test_symrec.py 
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

""" ant.py module tests. """


import symrec
import logging
import os
from xml.dom.minidom import *
import amara

logger = logging.getLogger("test.symrec")
logging.basicConfig()
logger.setLevel(logging.DEBUG)

def test_symrec_creation():
    """ Test metadata generation functions. """
    metadata = symrec.ReleaseMetadata("release_metadata.xml",
                                   service="myservice",
                                   product="myproduct",
                                   release="myrelease")
    metadata.add_package(name="my_archive.zip")
    metadata.add_package(name="my_archive2.zip", filters=['foo', 'bar'])
    logger.debug(metadata.xml())
    print metadata.service
    assert metadata.service == "myservice"
    assert metadata.product == "myproduct"
    assert metadata.release == "myrelease"
    assert metadata.dependsof_service == None
    assert metadata.dependsof_product == None
    assert metadata.dependsof_release == None
    # Package validation
    assert metadata.keys() == ['my_archive.zip', 'my_archive2.zip']
    assert metadata['my_archive.zip'] == {'type': u'zip', 'extract': u'single', 'default': True, 'filters': [], 's60filter':[], 'md5checksum': None, 'size': None}
    assert metadata['my_archive2.zip'] == {'type': u'zip', 'extract': u'single', 'default': True, 'filters': ['foo', 'bar'], 's60filter': ['foo', 'bar'], 'md5checksum': None, 'size': None}

def test_symrec_loading():
    """ Test loading generated metadata. """
    filename = os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec", "generated_release_metadata.xml")    
    metadata = symrec.ReleaseMetadata(filename)
    assert metadata.dependsof_service == None
    assert metadata.dependsof_product == None
    assert metadata.dependsof_release == None
    print metadata.keys()
    assert metadata.keys() == [u's60_app_organizer_clock.zip', u's60_app_organizer_clock_binary.zip', u's60_mw_classicui_and_app_radio.zip', u's60_mw_classicui_and_app_radio_internal.zip']
    for name in metadata.keys():
        print metadata[name]
        assert metadata[name]['md5checksum'] == None
        assert metadata[name]['size'] == None
        assert metadata[name]['type'] == "zip"
                           
def test_symrec_update():
    """ Testing symrec MD5updater class. """
    filename = os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/GRACE", "service/product/release_1/release_metadata.xml")
    updatemd5 = symrec.MD5Updater(filename)
    updatemd5.update()
    print updatemd5['test1.zip']['md5checksum']
    print updatemd5['test2.zip']['md5checksum']
    assert updatemd5['test1.zip']['md5checksum'] == "29b6ddc0265958641949c15e5c16c580"
    assert updatemd5['test2.zip']['md5checksum'] == "433fd286bcf7e55be9d0e7e88f0cd84c"
    assert updatemd5['test1.zip']['size'] == "112"
    assert updatemd5['test2.zip']['size'] == "112"


def test_symrec_releaseinfo_modification():
    """ Testing symrec release information modifications. """
    filename = os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/GRACE", "service/product/release_1/release_metadata.xml")
    metadata = symrec.ReleaseMetadata(filename)
    metadata.service = "test_service"
    metadata.product = "test_product"
    metadata.release = "test_release"
    assert metadata.service == "test_service"
    assert metadata.product == "test_product"
    assert metadata.release == "test_release"
    
    metadata.dependsof_service = "test_service_dep"
    metadata.dependsof_product = "test_product_dep"
    metadata.dependsof_release = "test_release_dep"
    assert metadata.dependsof_service == "test_service_dep"
    assert metadata.dependsof_product == "test_product_dep"
    assert metadata.dependsof_release == "test_release_dep"

      
def test_release_validator():
    """ Testing release metadata xml validator. """
    validator = symrec.ValidateReleaseMetadata(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_1/release_metadata.xml"))
    assert validator.is_valid() == True

    validator = symrec.ValidateReleaseMetadata(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_2/release_metadata.xml"))
    assert validator.is_valid() == False

    validator = symrec.ValidateReleaseMetadata(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_1_001/release_metadata.xml"))
    assert validator.is_valid() == True
    
    validator = symrec.ValidateReleaseMetadata(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_1_001/release_metadata_1.xml"))
    assert validator.is_valid() == True

    validator = symrec.ValidateReleaseMetadata(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_1_002/release_metadata.xml"))
    assert validator.is_valid() == True
    
    validator = symrec.ValidateReleaseMetadata(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_5/release_metadata.xml"))
    assert validator.is_valid() == True
    validator = symrec.ValidateReleaseMetadata(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_6/release_metadata.xml"))
    assert validator.is_valid() == False
def test_xml_merge():
    """ Testing the merge of metadata files. """
    merger = symrec.MetadataMerger(os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/merge/main_metadata_1.xml"))
    merger.merge(os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/merge/main_metadata_2.xml"))
    merger.merge(os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/merge/main_metadata_3.xml"))
    logger.debug(merger.xml())
    output = open(os.path.join(os.environ['TEMP'], "release_data.xml"), "w+")
    output.write(merger.xml())
    output.close()
    
    metadata = symrec.ReleaseMetadata(os.path.join(os.environ['TEMP'], "release_data.xml"))
    logger.debug(metadata.keys())
    assert len(metadata.keys()) == 4
    assert metadata.keys() == [u'test1.zip', u'test2.zip', u'test3_1.zip', u'test3_2.zip']
    
    

def test_symrec_loading_sp_invalid():
    """ Test loading generated metadata. """
    filename = os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/GRACE/service/product/release_1_001", "release_metadata.xml")    
    metadata = symrec.ReleaseMetadata(filename)
    assert metadata.service == "service"
    assert metadata.product == "product"
    assert metadata.release == "release_1_001"
    assert metadata.dependsof_service == "service"
    assert metadata.dependsof_product == "product"
    assert metadata.dependsof_release == "release_1"
    assert metadata.keys() == [u'sp1.zip']

    validator = symrec.ValidateReleaseMetadata(filename)
    assert validator.is_valid() == True

def test_symrec_loading_sp_valid():
    """ Test loading generated metadata. """
    filename = os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/GRACE/service/product/release_1_001", "release_metadata_1.xml")    
    metadata = symrec.ReleaseMetadata(filename)
    assert metadata.service == "service"
    assert metadata.product == "product"
    assert metadata.release == "release_1_001"
    assert metadata.dependsof_service == "service"
    assert metadata.dependsof_product == "product"
    assert metadata.dependsof_release == "release_1"
    assert metadata.keys() == []    
    assert len(metadata.servicepacks) == 1
    assert metadata.servicepacks[0].name == u'SP1'
    assert metadata.servicepacks[0].files == [u'sp1.zip']
    assert metadata.servicepacks[0].instructions == [u'specialInstructions.xml']

    validator = symrec.ValidateReleaseMetadata(filename)
    assert validator.is_valid() == True


def test_symrec_to_tdd():
    filename = os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/GRACE/service/product/release_1_001", "release_metadata.xml")        
    logger.info(symrec.Metadata2TDD(filename).to_tdd())


def test_find_latest_metadata():
    assert symrec.find_latest_metadata(os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/override/none")) == None
    
    expected = os.path.normpath(os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/override/one", "release_metadata.xml"))
    filename = symrec.find_latest_metadata(os.path.dirname(expected))
    assert expected == filename, "Should be %s (%s)" % (expected, filename)

    expected = os.path.normpath(os.path.join(os.environ['HELIUM_HOME'], "tests/data/symrec/override/several", "release_metadata_2.xml"))
    filename = symrec.find_latest_metadata(os.path.dirname(expected))
    assert expected == filename, "Should be %s (%s)" % (expected, filename)


def test_cached_release_validator():
    """ Testing the cached release metadata xml validator. """
    
    cachefile = os.path.join(os.environ['HELIUM_HOME'], 'build', 'test_cache.txt')
    if not os.path.exists(os.path.dirname(cachefile)):
        os.makedirs(os.path.dirname(cachefile))
    if os.path.exists(cachefile):
        os.remove(cachefile)
    # 1st release
    validator = symrec.ValidateReleaseMetadataCached(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_2/release_metadata.xml"), cachefile)
    assert validator.is_valid() == False
    assert os.path.exists(cachefile), "Cache file has not been created"
    assert len(validator.load_cache()) == 1
    
    # 2nd release
    validator = symrec.ValidateReleaseMetadataCached(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_1/release_metadata.xml"), cachefile)
    assert validator.is_valid() == True
    assert os.path.exists(cachefile), "Cache file has not been created"
    assert len(validator.load_cache()) == 2

    # 3st release
    validator = symrec.ValidateReleaseMetadataCached(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_1_001/release_metadata_1.xml"), cachefile)
    assert validator.is_valid() == True
    assert os.path.exists(cachefile), "Cache file has not been created"
    print validator.load_cache()
    assert len(validator.load_cache()) == 3

    # testing 2nd release again
    validator = symrec.ValidateReleaseMetadataCached(os.path.join(os.environ['HELIUM_HOME'],
                                                            "tests/data/symrec/GRACE",
                                                            "service/product/release_1/release_metadata.xml"), cachefile)
    assert validator.is_valid() == True
    assert os.path.exists(cachefile), "Cache file has not been created"
    assert len(validator.load_cache()) == 3
