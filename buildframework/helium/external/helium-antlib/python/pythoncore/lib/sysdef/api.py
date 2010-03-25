#============================================================================ 
#Name        : api.py 
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

""" System Definition file parser.

Priority are not handled yet.
Nested task unitlist are not handled properly yet.
    
How to use it::

    sdf = SystemDefinition(filename)
    for name in sdf.layers:
        print " + Units in layer %s" % name
        for unit in sdf.layers[name].units:
            print "     - " +  sdf.units[name].id

    for name in sdf.units:
        print sdf.units[name].id
    
"""

import logging
import os
import re
import sys
import types

from xmlhelper import node_scan, recursive_node_scan
from xml.dom import Node
import xml.dom.minidom

logging.basicConfig(level=logging.INFO)
_logger = logging.getLogger('sysdef.api')


def filter_out(config_filters, unit_filters):
    """ Function that determines if a unit should be included or not. 
        returns None => could be included, string reason.
    """

    def hasvalue(filter_list, value):
        """ Check if a filter list contains a particular value.
            It handles list's item negation using "!".
        """
        for list_value in filter_list:
            if list_value == value:
                return True
        return False
    for filter_ in unit_filters:
        if filter_.startswith("!"):
            if hasvalue(config_filters, filter_[1:]):
                return filter
        else:
            if not hasvalue(config_filters, filter_):
                return filter_
    return None


def extract_filter_list(filters):
    """ Convert a comma separated list of filters into a python list.
        The method will skip empty filters (empty strings).
    """
    result = []
    for filter_ in [filter_.strip() for filter_ in filters.split(",")]:
        if len(filter_) > 0:
            result.append(filter_)
    return result


class SysDefElement(object):
    """ A generic element of a System Definition. """
    def __init__(self, sysDef):
        """ Initialisation """
        self._sysDef = sysDef
        
    def _getname(self):
        """ Name getter method """
        return NotImplementedError()
        
    def get_id(self):
        """ Use name as default ID. """
        return getattr(self, 'name').lower()
    
    def __str__(self):
        return self.get_id()
        
        
class Unit(SysDefElement):
    """ Abstract unit from SDF file. """
    def __init__(self, node, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.__xml = node
        self.binaries = []

    def __getid(self):
        """ Id getter. """
        return self.__xml.getAttribute('unitID')

    def _getname(self):
        """ Name getter. """
        if self.__xml.hasAttribute('name'):
            return self.__xml.getAttribute('name')
        if self.__xml.hasAttribute('bldFile'):
            return self.__xml.getAttribute('bldFile')
        return self.__xml.getAttribute('mrp')
    
    def __getpath(self):
        """ Path getter. """
        if self.__xml.hasAttribute('bldFile'):
            return os.path.join(os.path.sep, self.__xml.getAttribute('bldFile'))
        return os.path.join(os.sep, os.path.dirname(self.__xml.getAttribute('mrp')))
            
    def __getfilters(self):
        """ filter getter. """
        filters = []
        if self.__xml.hasAttribute('filter'):
            filters = extract_filter_list(self.__xml.getAttribute('filter'))
        return filters

    id = property(__getid)
    name = property(_getname)
    path = property(__getpath)
    filters = property(__getfilters)
    
    
class _UnitGroup(SysDefElement):
    """ A group of units. """
    def __init__(self, node, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self._xml = node
        self._units = []

    def __getname(self):
        """ Name getter method """
        return self._xml.getAttribute('name')

    def __getunits(self):
        """ Units getter method """
        return self._units

    name = property(__getname)
    units = property(__getunits)


class Layer(_UnitGroup):
    """ Abstract layer from SDF file. """    
    def __init__(self, node, sysDef):
        """ Initialisation """
        _UnitGroup.__init__(self, node, sysDef)
        self._modules = []
        self._module_count = 0
        for unitNode in recursive_node_scan(self._xml, 'unit'):
            unit = Unit(unitNode, self._sysDef)
            self._units.append(unit)
            self._sysDef.addElement(unit)

        for moduleNode in recursive_node_scan(self._xml, 'module') + recursive_node_scan(self._xml, 'collection'):
            module = Module(moduleNode, self._sysDef)
            self._modules.append(module)
            self._module_count += 1
            # Not added to the model.
            #self._sysDef.addElement(module) 
    
    def __getmodules(self):
        """ Module list accessor. """
        return self._modules

    def __getmodulescount(self):
        """ Module cound accessor. """
        return self._module_count
    
    modules = property(__getmodules)
    modules_count = property(__getmodulescount)
    
    
class Module(_UnitGroup):
    """ Abstract module from SDF file. """    
    def __init__(self, node, sysDef):
        """ Initialisation """
        _UnitGroup.__init__(self, node, sysDef)
        for unitNode in recursive_node_scan(self._xml, "unit"):
            unit = Unit(unitNode, self._sysDef)
            self._units.append(unit)


class UnitList(_UnitGroup):
    """ Abstract unitlist from SDF file. """
    def __init__(self, node, units, sysDef):
        """ Initialisation """
        _UnitGroup.__init__(self, node, sysDef)
        for unitRef in node_scan(self._xml, "unitRef"):
            try:
                self._units.append(units[unitRef.getAttribute('unit')])
            except KeyError, error:
                sys.stderr.write("ERROR: Could not find unit '%s'\n" % unitRef.getAttribute('unit') + str(error) + "\n")


class BuildLayer(SysDefElement):
    """ Abstract buildlayer. """
    def __init__(self, node, config, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.__xml = node
        self.config = config
        self.targetList = []
        if self.__xml.hasAttribute('targetList'):
            for tlname in re.split(r'\s+', self.__xml.getAttribute('targetList').strip()):
                for target in self._sysDef.targetlists[tlname].targets:
                    self.targetList.append(target)                
    
    def __getcommand(self):
        """ Command getter method. """
        return self.__xml.getAttribute('command')
    
    def __getunitParallel(self):
        """ Unit Parallel getter method (boolean). """
        return (self.__xml.getAttribute('unitParallel').upper() == "Y")

    command = property(__getcommand)
    unitParallel = property(__getunitParallel)
    
    
class Option(SysDefElement):
    """ Represents an option used in abld calls. """
    def __init__(self, node, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.__xml = node
    
    def __getname(self):
        """ Name getter method. """
        return self.__xml.getAttribute('name')
    
    def __getabldOption(self):
        """ Abld option getter method. """
        return self.__xml.getAttribute('abldOption')
    
    def __getenable(self):
        """ Unit Parallel getter method (boolean). """
        return (self.__xml.getAttribute('enable').upper() == 'Y')

    def __getfilteredOption(self):
        """ Filtered abld option getter method. """
        if not self.enable:
            return ''
        return self.abldOption
   
    name = property(__getname)
    abldOption = property(__getabldOption)
    enable = property(__getenable)
    filteredOption = property(__getfilteredOption)
    

class SpecialInstruction(SysDefElement):
    """ Reads special instruction command. """
    def __init__(self, node, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.__xml = node

    def __getname(self):
        """ Name getter method """
        return self.__xml.getAttribute('name')
    
    def __getcommand(self):
        """ Command getter method """
        return self.__xml.getAttribute('command')

    def __getpath(self):
        """ Path getter method """
        return self.__xml.getAttribute('cwd')
    
    name = property(__getname)
    command = property(__getcommand)
    path = property(__getpath)
    
    
class Task(SysDefElement):
    """ Abstract task node from SDF xml. """
    def __init__(self, node, config, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.__xml = node
        self._config = config
        self.__job = None

    def units(self):
        """ Process unit list from layers """
        result = []
        for ref in node_scan(self.__xml, "unitListRef"):
            units = []
            try:
                units = self._config.sdf.unitlists[ref.getAttribute('unitList')].units
                for unit in units:
                    reason = filter_out(self._config.filters, unit.filters)
                    if reason == None:
                        result.append(unit)
                    else:
                        sys.stderr.write("Filter-out: %s (%s)\n" % (unit.id, reason)) 
            except KeyError, error:
                sys.stderr.write("ERROR: Could not find unitList of layer %s\n" % error)
        return result
        
    def __getjob(self):
        """ Return the job contained inside the task. """
        for job in node_scan(self.__xml, r"buildLayer|specialInstructions"):
            if job.nodeName == 'specialInstructions':
                self.__job = SpecialInstruction(job, self._sysDef)
            elif job.nodeName == 'buildLayer':
                self.__job = BuildLayer(job, self._config, self._sysDef)
        return self.__job

    job = property(__getjob)


class Configuration(SysDefElement):
    """ Abstract configuration from SDF file. """
    def __init__(self, node, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.__xml = node
    
    def __getname(self):
        """ Name getter method """
        return self.__xml.getAttribute('name')    

    def __getfilters(self):
        """ Filters getter method. """
        filters = []
        if self.__xml.hasAttribute('filter'):
            filters = extract_filter_list(self.__xml.getAttribute('filter'))
        return filters  
    
    def __getlayerrefs(self):
        """ Layer's references getter method. """
        result = []
        for ref in node_scan(self.__xml, "layerRef"):
            try:
                result.append(self._sysDef.layers[ref.getAttribute('layerName')])
            except KeyError, error:
                sys.stderr.write("ERROR: Could not find layer '%s'\n" % error)
        return result
    
    def __getunitlistrefs(self):
        """ Unit list references getter method. """
        result = []
        for ref in node_scan(self.__xml, "unitListRef"):
            try:
                result.append(self._sysDef.unitlists[ref.getAttribute('unitList')])
            except KeyError, error:
                sys.stderr.write("ERROR: Could not find unitList %s\n" % error)
        return result
        
    def __getunits(self):
        """ Return unit from unitList or layer. """
        result = []            
        for ref in node_scan(self.__xml, "unitListRef|layerRef"):
            units = []
            try:
                if ref.nodeName == 'unitListRef':
                    units = self._sysDef.unitlists[ref.getAttribute('unitList')].units
                else:
                    units = self._sysDef.layers[ref.getAttribute('layerName')].units
                for unit in units:
                    reason = filter_out(self.filters, unit.filters)
                    if reason == None:
                        # Get the unit object from the cache if this is a string
                        # TODO - remove once unitlist returns list of Unit objects
                        if isinstance(unit, types.UnicodeType):
                            unit = self._sysDef[unit]
                        result.append(unit)
                    else:
                        sys.stderr.write("Filter-out: %s (%s)\n" % (unit.id, reason)) 
            except KeyError, error:
                sys.stderr.write("ERROR: Could not find unitList or layer %s\n" % error)
        return result
    
    def __gettasks(self):
        """ Tasks getter method. """
        result = []
        for task in node_scan(self.__xml, "task"):
            result.append(Task(task, self, self._sysDef))
        return result
    
    name = property(__getname)
    filters = property(__getfilters)    
    layerrefs = property(__getlayerrefs)
    unitlistrefs = property(__getunitlistrefs)
    units = property(__getunits)
    tasks = property(__gettasks)


class Target(SysDefElement):
    """ Abstract target from SDF file. """
    def __init__(self, node, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.__xml = node

    def __getname(self):
        """ Name getter method. """
        return self.__xml.getAttribute('name')    

    def __getabldTarget(self):
        """ Abld target getter method. """
        return self.__xml.getAttribute('abldTarget')

    name = property(__getname)
    abldTarget = property(__getabldTarget)


class TargetList(SysDefElement):
    """ Abstract targetlist from SDF file. """
    def __init__(self, node, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.__xml = node

    def __getname(self):
        """ Name getter method. """
        return self.__xml.getAttribute('name')    

    def __gettargets(self):
        """ Targets getter method. """
        result = []
        for target in re.split(r'\s+', self.__xml.getAttribute('target')):
            result.append(self._sysDef.targets[target.strip()])
        return result
        
    name = property(__getname)
    targets = property(__gettargets)    


class SystemDefinition(object):
    """ Logical representation of the System Definition.
    
    The System Definition is defined in terms of a system model and a
    build model. The default physical representation of this is the Symbian
    XML format. """
    def __init__(self, filename):
        """ Initialisation """
        self.__xml = xml.dom.minidom.parse(open(filename, "r"))
        self._cache = {}
        #TODO - why store these as hashes?
        self._units = {}
        self._layers = {}
        self._modules = {}
        self._unitlists = {}
        self._configurations = {}
        self._options = {}
        self._targets = {}
        self._targetlists = {}
        self.__parse()
    
    def __getunits(self):
        """ Units getter method. """
        return self._units
    
    def __getmodules(self):
        """ Modules getter method. """
        return self._modules

    def __getlayers(self):
        """ Layers getter method. """
        return self._layers
    
    def __getunitlists(self):
        """ Unit lists getter method. """
        return self._unitlists
    
    def __getoptions(self):
        """ Options getter method. """
        return self._options    
    
    def __getconfigurations(self):
        """ Configurations getter method. """
        return self._configurations

    def __gettargetlists(self):
        """ Targets lists getter method. """
        return self._targetlists

    def __gettargets(self):
        """ Targets getter method. """
        return self._targets
    
    units = property(__getunits)
    unitlists = property(__getunitlists)
    layers = property(__getlayers)
    options = property(__getoptions)
    configurations = property(__getconfigurations)
    targetlists = property(__gettargetlists)
    targets = property(__gettargets)
    modules = property(__getmodules)
    
    def __parse(self):
        for l in self.__xml.getElementsByTagName('layer'):
            layer = Layer(l, self)
            self.layers[layer.name] = layer
            self.addElement(layer)
            for unit in layer.units:
                self._units[unit.get_id()] = unit
            for mod in layer.modules:
                self._modules[mod.name] = mod
            
        for build in self.__xml.getElementsByTagName('build'):
            for ul in build.getElementsByTagName('unitList'):
                unitlist = UnitList(ul, self._units, self)
                self.unitlists[unitlist.name] = unitlist
                self.addElement(unitlist)

            for xml_config in build.getElementsByTagName('configuration'):
                config = Configuration(xml_config, self)
                self.configurations[config.name] = config
                self.addElement(config)

            for option_node in build.getElementsByTagName('option'):         
                option = Option(option_node, self)
                if option.name == 'SAVESPACE':
                    continue
                self.options[option.name] = option 
                self.addElement(option)

            for target_node in build.getElementsByTagName('target'):
                target = Target(target_node, self)
                self.targets[target.name] = target
                self.addElement(target)

            for targetlist_node in build.getElementsByTagName('targetList'):
                targetlist = TargetList(targetlist_node, self)
                self.targetlists[targetlist.name] = targetlist
                self.addElement(targetlist)
            
    def addElement(self, element):
        """ Adds SysDef element to cache. """
        #TODO - handle duplicate names of different types
        if not self._cache.has_key(element.get_id()):
            self._cache[element.get_id()] = element
            _logger.info('Adding SysDef element to cache: %s' % str(element))
        else:
            _logger.warning("Element already exists: %s" % element.name)
        
    def __getitem__(self, key):
        """ Item getter method. """
        return self._cache[key]
    
    def merge_binaries(self, binaries_reader):
        """ Merge binaries based on build log and system definition. """
        for (unit_name, binaries) in binaries_reader:
            unit_name = unit_name.lower()
            if self.units.has_key(unit_name):
                for bin in binaries:
                    #if bin.find('_stolon_ekern') != -1:
                    _logger.debug("Merging: %s" % bin)
                unit = self.units[unit_name]
                unit.binaries = [Binary(bin.lower(), self) for bin in binaries]
                for binary in unit.binaries:
                    self.addElement(binary)
                    _logger.info('Merging binary: %s' % str(binary))
            else:
                _logger.warning('Component found in the build log but not in sysdef: %s' % unit_name)
                
    def merge_binary_sizes(self, binary_sizes_reader):
        """ Merge binary size base on binary sizes input and system definition. """
        for (binary_name, size, rom_type) in binary_sizes_reader:
            #if binary_name.find('_stolon_ekern') != -1:
            
            binary_name = binary_name.lower()
            _logger.debug("Merging binary size: %s" % binary_name)
            if self._cache.has_key(binary_name):
                binary = self._cache[binary_name]
                binary.size = size
                binary.rom_type = rom_type
            else:
                _logger.warning('Binary found in the binary sizes input but not in the system definition: %s' % binary_name)
                

class Binary(SysDefElement):
    """ A binary file that may go into a ROM image. """
    
    def __init__(self, name, sysDef):
        """ Initialisation """
        SysDefElement.__init__(self, sysDef)
        self.name = name
        
    
          
          
          
                                 
#if __name__ == "__main__":
#    sdf = SystemDefinitionFile("Z:/output/build/canonical_system_definition.xml")
#    writer = MakeWriter2("Z:/output/build/makefile")
#    writer.write(sdf)
#    writer.close()
#    print sdf.toMakefile()

