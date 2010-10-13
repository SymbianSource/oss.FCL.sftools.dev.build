#============================================================================ 
#Name        : test_sphinx_ext.py 
#Part of     : Helium 

#Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

""" Test sphinx_ext module. """
import re

import logging
import os
import time
import unittest
import sys
import mocker
import sphinx_ext

_logger = logging.getLogger('test.sphinx_ext')
random_number = 10

class SphinxTest(mocker.MockerTestCase):
    """ Class for testing sphinx_ext module """
    def __init__(self, methodName="runTest"):
        mocker.MockerTestCase.__init__(self, methodName)
        
    def setUp(self):
        # some dummy input
        self.inlineDocument = r'<document source="C:\helium-working\helium\build\temp\doc\api\helium\macros_list.rst"><section ids="macros-list" names="macros\ list"><title>Macros list</title></section></document>'
        sphinx_ext.exit_with_failure = 0
        sphinx_ext.database_path = os.path.join(os.environ['TEST_DATA'], "data", "test_database.xml")
        
    def test_handle_hlm_role_callback(self):
        """ Check roles and description unit."""
        obj = _MockApp()
        sphinx_ext.setup(obj)
        assert 'hlm-t' in obj.dict.keys()
        assert 'hlm-p' in obj.dict.keys()
        assert 'hlm-m' in obj.dict.keys()
        assert sphinx_ext.handle_hlm_role == obj.dict['hlm-t']
        assert sphinx_ext.handle_hlm_role == obj.dict['hlm-p']
        assert sphinx_ext.handle_hlm_role == obj.dict['hlm-m']
        assert ['property', 'ant-prop', 'pair: %s; property'] in obj.descUnit
        assert ['target', 'ant-target', 'pair: %s; target'] in obj.descUnit  
     
    def test_handle_hlm_role_target(self):
        """ Check target to build the link """
        obj = self.mocker.mock(count=False)
        mocker.expect(obj.document).result(self.inlineDocument) 
        self.mocker.replay()              
        response = sphinx_ext.handle_hlm_role('hlm-t' , "", 'cmaker-install', random_number, obj)
        assert "../../api/helium/project-compile.cmaker.html#cmaker-install" in response[0][0].children[0].attributes['refuri']
        
    def test_handle_hlm_role_property(self):
        """ Check property to build the link """
        obj = self.mocker.mock(count=False)
        mocker.expect(obj.document).result(self.inlineDocument) 
        self.mocker.replay()              
        response = sphinx_ext.handle_hlm_role('hlm-p' , "", 'cmaker-export', random_number, obj)
        assert "../../api/helium/project-compile.cmaker.html#cmaker-export" in response[0][0].children[0].attributes['refuri']
        
        
    def test_handle_hlm_role_macro(self):
        """ Check macro to build the link """
        obj = self.mocker.mock(count=False)
        mocker.expect(obj.document).result(self.inlineDocument) 
        self.mocker.replay()              
        response = sphinx_ext.handle_hlm_role('hlm-m' , "", 'cmaker-export', random_number, obj)
        assert "../../api/helium/project-compile.cmaker.html#cmaker-export" in response[0][0].children[0].attributes['refuri']
        
    def test_handle_hlm_role_missing_api(self):
        """ Check for failure when there are missing api's """
        error = ""
        line = ""
        obj = self.mocker.mock(count=False)
        mocker.expect(obj.document).result(self.inlineDocument) 
        mocker.expect(obj.reporter.error('Missing API doc for "cmaker-clean".', line=random_number)).result('Missing API doc for "cmaker-clean".') 
        self.mocker.replay()
        sphinx_ext.handle_hlm_role('hlm-t' , "", 'cmaker-clean', random_number, obj)
        
    def test_handle_hlm_role_missing_field_value(self):
        """ Check for failure when there are missing fields for api's """
        error = ""
        line = ""
        obj = self.mocker.mock(count=False)
        mocker.expect(obj.document).result(self.inlineDocument) 
        mocker.expect(obj.reporter.error('Field value cannot be found for API field: "cmaker-export[summary]".', line=random_number)).result('Field value cannot be found for API field: "cmaker-export[summary]".') 
        self.mocker.replay()
        sphinx_ext.handle_hlm_role('hlm-t' , "", 'cmaker-export[summary]', random_number, obj)
        
    def test_handle_hlm_role_valid_field_value(self):
        """ Check when there is '[' present """
        obj = self.mocker.mock(count=False)
        mocker.expect(obj.document).result(self.inlineDocument)
        self.mocker.replay()
        response = sphinx_ext.handle_hlm_role('hlm-t' , "", 'cmaker-export[location]', random_number, obj)
        assert r"C:\Helium_svn\helium\tools\compile\cmaker.ant.xml:87:" in response[0][0].data
       
class _MockApp:

    def __init__(self):
        self.dict = {}
        self.descUnit = []
        
    def add_role(self, role, ref):
        self.dict[role] = ref
        
    def add_description_unit(self, text1, text2, text3):
        self.descUnit.append([text1, text2, text3])