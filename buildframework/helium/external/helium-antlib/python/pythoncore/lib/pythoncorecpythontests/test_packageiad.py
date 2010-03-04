#============================================================================ 
#Name        : test_packageiad.py 
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

""" Test cases for packageiad.

"""
import sys
import os
import xml.dom.minidom
import logging


logger = logging.getLogger('test.packageiad')
logging.basicConfig(level=logging.INFO)


def setup_module():
    """ Creates some test data files for file-related testing. """
    
    
def teardown_module():
    """ Cleans up test data files for file-related testing. """
    if os.path.exists('testPackage.zip') and os.path.isfile('testPackage.zip'): 
        os.remove('testPackage.zip')

    
#def test_package_main(self):
    """ Test the package IAD class.
    
    iad = __import__('packageiad')
    sysdef = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad', 'layers.sysdef.xml')
    sysdefconfigs = "developer_mc_4032"
    builddrive = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad')
    result = iad.main(sysdef, sysdefconfigs, builddrive) """

#def test_package_processSisDir(self):
    """ Test the packageiad test_package_processSisDir method.
    
    iad = __import__('packageiad')
    packager = iad.IADPackager()    #init the packager
    builddrive = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad')
    buildDirs = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad', 'sis\\')
    packager.processSisDir(buildDirs, builddrive + "\\epoc32\\tools\\makesis.exe") """
    
def test_createPackage():
    """ test the create package method """
    #load up the python file
    
    iad = __import__('packageiad')
    packager = iad.IADPackager()    #init the packager
    topDir = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad', 'sis')
    packageName = 'testPackage'
    currentDir = os.getcwd()
    packager.createPackage(topDir, packageName)
    if not os.path.exists('testPackage.zip') and not os.path.isfile('testPackage.zip'):
        logger.info("testPackage.zip file not created")
        assert (os.path.exists('testPackage.zip') and os.path.isfile('testPackage.zip'))
    os.chdir(currentDir)
    
def test_getLayers():
    """ test getLayers in packageIAD """
    
    iad = __import__('packageiad')
    sysdefFile = os.path.join(os.environ['TEST_DATA'], 'data', 'packageiad', 'layers.sysdef.xml')
    sysdef = xml.dom.minidom.parse (sysdefFile)
    configurations = sysdef.getElementsByTagName ("configuration")
    layers = sysdef.getElementsByTagName ("layer")

    bldDirs = []
    
    packager = iad.IADPackager()
    
    for configuration in configurations :
        packager.getLayer (configuration, layers, bldDirs)
