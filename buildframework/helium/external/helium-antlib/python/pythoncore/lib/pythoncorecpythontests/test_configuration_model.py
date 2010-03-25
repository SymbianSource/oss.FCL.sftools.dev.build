#============================================================================ 
#Name        : test_configuration_model.py 
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

import logging
import os
import unittest
import nose

import configuration
import configuration_model


logger = logging.getLogger('test.configuration_model')
#logging.basicConfig(level=logging.DEBUG)

class GroupDefTest(unittest.TestCase):
    """ Check config model groups are correctly defined. """
    
    def setUp(self):
        """ Create model. """
        self.model = configuration_model.DataModel(os.environ['TEST_DATA'] + '/data/data_model_test.xml')
        
    def test_init_model(self):
        """ Test groups can be created. """
        assert len(self.model.properties.keys()) == 3
        assert len(self.model.groups.keys()) == 1
        
        prop1 = self.model.properties['test.property.1']
        assert prop1.description == 'Test property one.'
        
        prop2 = self.model.properties['test.property.2']
        assert prop2.description == 'Test property two.'
        
        assert self.model.groups['testGroup'] != None

    def test_property_not_in_model(self):
        """ Property not in model is identified. """
        data = {'missing.property': 'foobar', 'test.property.1': '1'}
        config = configuration.Configuration(data)
        items = self.model.validate_config(config)
        
        assert len(items) == 2
        assert isinstance(items[0], configuration_model.MissingFromDataModelItem)
    
    def test_required_property_in_group_not_defined(self):
        """ Required property in a group missing from config is identified. """
        config = configuration.Configuration({'test.property.1': '1', 'test.property.3': '3'})
        items = self.model.validate_config(config)
        
        assert len(items) == 1
        assert isinstance(items[0], configuration_model.UndefinedRequiredInGroupItem)
 
        
class MissingFromDataModelItemTest(unittest.TestCase):
    """ Item class operations. """
    def test_create(self):
        """ Basic validation item usage. """
        item = configuration_model.MissingFromDataModelItem('test.property')
        self.assert_(str(item) == 'Property not in data model: test.property')
        item.log(logger)
        
        
class DataModelTest(unittest.TestCase):
    """ Checks Data Model is properly defined """
    
    def setUp(self):
        """ Create model. """
        self.model = configuration_model.DataModel(os.environ['TEST_DATA'] + '/data/data_model_validation_test.xml')    
       
    def test_init_model(self):
        """ Test groups can be created. """
        assert len(self.model.properties.keys()) == 3
        assert len(self.model.groups.keys()) == 1
        
        prop1 = self.model.properties['test.property.1']
        assert prop1.type == 'string'
        assert prop1.description == 'Test property one.'
        
        prop2 = self.model.properties['test.property.2']
        assert prop2.type == 'string'
        assert prop2.description == 'Test property two.'
        
        assert self.model.groups['testGroup'] != None
        
        
class DataModelPropertyTest(unittest.TestCase):
    """ Checks Data Model that an exception is thrown if properties are not properly defined """
    
    @nose.tools.raises(Exception)
    def setUp(self):
        """ Create model. """
        self.model = configuration_model.DataModel(os.environ['TEST_DATA'] + '/data/data_model_validation__property_test.xml')
        
        
class DataModelGroupTest(unittest.TestCase):
    """ Checks Data Model that an exception is thrown if there is a required property in groups is missing"""
    
    @nose.tools.raises(Exception)
    def setUp(self):
        """ Create model. """
        self.model = configuration_model.DataModel(os.environ['TEST_DATA'] + '/data/data_model_validation_group_test.xml')
        
             