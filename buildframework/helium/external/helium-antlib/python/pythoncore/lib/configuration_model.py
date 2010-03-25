#============================================================================ 
#Name        : configuration_model.py 
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

import amara
import logging
import types
import copy

_logger = logging.getLogger('configurationmodel')
#logging.basicConfig(level=logging.DEBUG)
_handler = logging.StreamHandler()
_handler.setFormatter(logging.Formatter('%(levelname)s: %(message)s'))
_logger.addHandler(_handler)


class PropertyDef(object):
    """ The model definition of a property. """
    
    def __init__(self, property_node):
        """ Initialization. """
        if not hasattr(property_node, 'name'):
            raise Exception("Name is not defined for '" + str(property_node) + "'")
        if not hasattr(property_node, 'type'):
            raise Exception("Type is not defined for '" + str(property_node.name) + "'")
        if not hasattr(property_node, 'description'):
            raise Exception("Description is not defined for '" + str(property_node.name) + "'")
            
        self.name = str(property_node.name)
        self.editStatus = str(property_node.editStatus)
        self.type = str(property_node.type)
        self.description = str(property_node.description).strip()
        
        if len(self.description) == 0:
            _logger.log(logging.ERROR, "Description has no content for '" + str(property_node.name) + "'")
        
        if hasattr(property_node, 'deprecated'):
            self.deprecated = str(property_node.deprecated)
                        
    def __repr__(self):
        return self.name
        
    def __str__(self):
        return self.name
    
    
class GroupDef(object):
    """ The model definition of a group of properties. """
    def __init__(self, group_node):
        """ Initialization. """
        self.name = str(group_node.name)
        self.description = str(group_node.description)
        self.properties = {}
        self.propref = []
        for property_ in group_node.propertyRef:
            self.properties[str(property_)] = property_.usage
            
    def check_config(self, config, items):
        """ Checks that the set of properties in a group are properly defined. """
        defined_props = [p for p in self.properties.keys() if config.has_key(p)]
        if len(defined_props) > 0:
            required_props = [p for p in self.properties.keys() if self.properties[p] == 'required']
            required_not_defined_props = set(required_props).difference(set(defined_props))
            for undefined_property in required_not_defined_props:
                items.append(UndefinedRequiredInGroupItem((self.name, undefined_property)))
        
        
class DataModel(object):
    """ A model of the configuration properties. """
    def __init__(self, modelpath):
        """ Initialization. """
        doc = amara.parse(open(modelpath, 'r'))
        
        self.properties = {}
        self.required_props = []
        for property_ in doc.heliumDataModel.property:
            self.properties[str(property_.name)] = PropertyDef(property_)
                   
        self.nongroupedproperties = copy.copy(self.properties)
        self.groups = {}
        for group in doc.heliumDataModel.group:
            groupobj = GroupDef(group)
            self.groups[str(group.name)] = groupobj
            
            for prop in groupobj.properties:
                groupobj.propref.append(self.properties[prop])
                if prop in self.nongroupedproperties:
                    del self.nongroupedproperties[prop]
                    
            groupobj.propref.sort()
            
            required_props_in_group = [p for p in group.propertyRef if p.usage == 'required']
            
            for required_prop in required_props_in_group:
                self.required_props.append(required_prop)
                if not self.properties.has_key(str(required_prop)):
                    raise Exception("Required property " + str(required_prop) + " is not defined!")
        
    def validate_config(self, config):
        """ Validate the Ant configuration against the model. """
        items = []
        self._check_deprecated_properties(config, items)
        self._check_undefined_properties(config, items)
        self._check_undefined_properties_in_groups(config, items)
        self._check_type_validation(config, items)
        self._check_defined_properties_not_in_groups(config, items)
        return items
    
    def validate_config_at_startup(self, config):
        """ Validate the Ant configuration against the model at build startup. """
        items = []
        
        for p in self.required_props:
            if not config.has_key(str(p)):
                print "Required property " + str(p) + " is not defined!"
        
        return items
    
    def _check_deprecated_properties(self, config, items):
        """ Check that deprecated properties not being used. """
        deprecated_props = [p for p in self.properties.values() if hasattr(p, 'deprecated')]
        for deprecated_prop in deprecated_props:
            _logger.debug('Checking deprecated property: ' + str(deprecated_prop))
            if config.has_key(str(deprecated_prop)):
                items.append(UsingDeprecatedItem(deprecated_prop))
    
    def _check_undefined_properties(self, config, items):
        """ Check for any defined properties that are not in the model. """ 
        undefined_properties = [p for p in config.keys() if p not in self.properties]
        undefined_properties.sort()
        for undefined_property in undefined_properties:
            items.append(MissingFromDataModelItem(undefined_property))

    def _check_undefined_properties_in_groups(self, config, items):
        for group in self.groups.values():
            _logger.debug('Checking group: %s' % group.name)
            group.check_config(config, items)
    
    def _check_defined_properties_not_in_groups(self, config, items):
        gp = []
        for group in self.groups.values():
            gp = gp + group.properties.keys()
        for p in self.properties.values():
            if not str(p) in gp:
                raise Exception(str(p) + ' not in a group')
    
    def _check_type_validation(self, config, items):
        prop_string = [p for p in self.properties.values() if p.type == 'string']
        prop_integer = [p for p in self.properties.values() if p.type == 'integer']
        prop_boolean = [p for p in self.properties.values() if p.type == 'boolean']
        prop_flag = [p for p in self.properties.values() if p.type == 'flag']
        
        for prop in prop_integer:
            if config.has_key(str(prop)):
                if not config[str(prop)].isdigit():
                    items.append(WrongTypeItem(("integer", prop)))            
               
        for prop in prop_boolean:
            if config.has_key(str(prop)) :
                if not (config[str(prop)] == 'false' or 'true'):
                    items.append(WrongTypeItem(("boolean", prop)))
                    
        for prop in prop_string:
            if config.has_key(str(prop)):
                if len(config[str(prop)]) == 0:
                    items.append(WrongTypeItem(("string", prop)))

        
class Item(object):
    level = logging.INFO
    message = ''

    def __init__(self, values):
        """ Initialization. """
        self.values = values
    
    def log(self, logger):
        logger.log(self.level, str(self))
        
    def __str__(self):
        return self.message % self.values


class MissingFromDataModelItem(Item):
    level = logging.INFO
    message = 'Property not in data model: %s'

    
class UsingDeprecatedItem(Item):
    level = logging.WARNING
    message = 'Deprecated property used: %s'


class UndefinedRequiredInGroupItem(Item):
    level = logging.WARNING
    message = 'Required property in %s group is not defined: %s'

    
class WrongTypeItem(Item):
    level = logging.WARNING
    message = 'Invalid %s value: %s'