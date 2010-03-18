#============================================================================ 
#Name        : configuration.py 
#Part of     : Helium 
#
#Partly Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
# 
#==============================================================================

"""Defines an interface for accessing configurations, typically for SW builds.

This interface is generally based on the Jakarta Commons Configuration API. A
configuration is a collection of properties. Builders create Configuration
objects from various source inputs.

"""


import copy
import logging
import re
import time
import types
import UserDict
import xml.dom.minidom



_logger = logging.getLogger('configuration')
logging.basicConfig(level=logging.INFO)

class Configuration(object, UserDict.DictMixin):
    """ Base Configuration object. """
    
    key_re = re.compile(r'\${(?P<name>[._a-zA-Z0-9]+)}', re.M)
    
    def __init__(self, data=None):
        """ Initialization. """
        #super(UserDict.DictMixin, self).__init__(data)
        self.name = None
        self.data = {}
        if data is not None:
            self.data.update(data)

    def __contains__(self, key):
        """ Check if a keys is defined in the dict. """
        return self.data.__contains__(key)
    
    def __getitem__(self, key, interpolate=True):
        """ Get an item from the configuration via dictionary interface. """
        if interpolate:
            return self.interpolate(self.data[key])
        return self.data[key]

    def __setitem__(self, key, item):
        """ Set an item from the configuration via dictionary interface. """
        self.data[key] = item

    def __delitem__(self, key):
        """ Remove an item from the configuration via dictionary interface. """
        del self.data[key]

    def keys(self):
        """ Get the list of item keys. """
        return self.data.keys()
    
    def has_key(self, key):
        """ Check if key exists. """
        return self.data.has_key(key)

    def match_name(self, name):
        """ See if the given name matches the name of this configuration. """
        return self.name == name

    def get(self, key, default_value):
        """ Get an item from the configuration. """
        try:
            return self.__getitem__(key)
        except KeyError:
            return default_value

    def get_list(self, key, default_value):
        """ Get a value as a list. """
        try:
            itemlist = self.__getitem__(key)
            if not isinstance(itemlist, types.ListType):
                itemlist = [itemlist]
            return itemlist
        except KeyError:
            return default_value
        
    def get_int(self, key, default_value):
        """ Get a value as an int. """
        try:
            value = self.__getitem__(key)
            return int(value)
        except KeyError:
            return default_value
        
    def get_boolean(self, key, default_value):
        """ Get a value as a boolean. """
        try:
            value = self.__getitem__(key)
            return value == "true" or value == "yes" or value == "1"
        except KeyError:
            return default_value
        
    def interpolate(self, value):
        """ Search for patterns of the form '${..}' and insert matching values. """
        if isinstance(value, types.ListType):
            value = [self.interpolate(elem) for elem in value]
        else:
            if isinstance(value, types.StringType) or \
               isinstance(value, types.UnicodeType) or \
               isinstance(value, types.ListType):
                for match in self.key_re.finditer(value):
                    for property_name in match.groups():
                        if self.has_key(property_name):
                            # See if interpolation may cause infinite recursion
                            raw_property_value = self.__getitem__(property_name, False)
                            #print 'raw_property_value: ' + raw_property_value
                            if raw_property_value == None:
                                raw_property_value = ''
                            if isinstance(raw_property_value, types.ListType):
                                for prop in raw_property_value:
                                    if re.search('\${' + property_name + '}', prop) != None:
                                        raise Exception("Key '%s' will cause recursive interpolation with value %s" % (property_name, raw_property_value))
                            else:
                                if re.search('\${' + property_name + '}', raw_property_value) != None:
                                    raise Exception("Key '%s' will cause recursive interpolation with value %s" % (property_name, raw_property_value))
                                    
                            # Get the property value
                            property_value = self.__getitem__(property_name)
                            if isinstance(property_value, types.ListType):
                                property_value = ",".join(property_value)
                            else:
                                property_value = re.sub(r'\\', r'\\\\', property_value, re.M)
                            value = re.sub('\${' + property_name + '}', property_value, value, re.M)
        return value
    
    def __str__(self):
        """ A string representation. """
        return self.__class__.__name__ + '[' + str(self.name) + ']'
        
    def __cmp__(self, other):
        """ Compare with another object. """
        return cmp(self.__str__, other.__str__)
       
       
class PropertiesConfiguration(Configuration):
    """ A Configuration that parses a plain text properties file.
    
    This typically follows the java.util.Properties format.
    
    Note: This code is mostly based on this recipe
    http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/496795.
    Copyright (c) Anand Balachandran Pillai
    """
    def __init__(self, stream=None, data=None):
        Configuration.__init__(self, data)
        
        self.othercharre = re.compile(r'(?<!\\)(\s*\=)|(?<!\\)(\s*\:)')
        self.othercharre2 = re.compile(r'(\s*\=)|(\s*\:)')
        self.bspacere = re.compile(r'\\(?!\s$)')
        
        if stream is not None:
            self.load(stream)
        
#    def __str__(self):
#        s='{'
#        for key,value in self.data.items():
#            s = ''.join((s,key,'=',value,', '))
#
#        s=''.join((s[:-2],'}'))
#        return s

    def __parse(self, lines):
        """ Parse a list of lines and create
        an internal property dictionary """

        # Every line in the file must consist of either a comment
        # or a key-value pair. A key-value pair is a line consisting
        # of a key which is a combination of non-white space characters
        # The separator character between key-value pairs is a '=',
        # ':' or a whitespace character not including the newline.
        # If the '=' or ':' characters are found, in the line, even
        # keys containing whitespace chars are allowed.

        # A line with only a key according to the rules above is also
        # fine. In such case, the value is considered as the empty string.
        # In order to include characters '=' or ':' in a key or value,
        # they have to be properly escaped using the backslash character.

        # Some examples of valid key-value pairs:
        #
        # key     value
        # key=value
        # key:value
        # key     value1,value2,value3
        # key     value1,value2,value3 \
        #         value4, value5
        # key
        # This key= this value
        # key = value1 value2 value3
        
        # Any line that starts with a '#' is considerered a comment
        # and skipped. Also any trailing or preceding whitespaces
        # are removed from the key/value.
        
        # This is a line parser. It parses the
        # contents like by line.

        lineno = 0
        i = iter(lines)

        for line in i:
            lineno += 1
            line = line.strip()
            # Skip null lines
            if not line: continue
            # Skip lines which are comments
            if line[0] == '#': continue

            # Position of first separation char
            sepidx = -1
            # A flag for performing wspace re check
            #flag = 0
            # Check for valid space separation
            # First obtain the max index to which we
            # can search.
            m = self.othercharre.search(line)
            if m:
                first, last = m.span()
                start, end = 0, first
                #flag = 1
                wspacere = re.compile(r'(?<![\\\=\:])(\s)')        
            else:
                if self.othercharre2.search(line):
                    # Check if either '=' or ':' is present
                    # in the line. If they are then it means
                    # they are preceded by a backslash.
                    
                    # This means, we need to modify the
                    # wspacere a bit, not to look for
                    # : or = characters.
                    wspacere = re.compile(r'(?<![\\])(\s)')        
                start, end = 0, len(line)
                
            m2 = wspacere.search(line, start, end)
            if m2:
                # print 'Space match=>',line
                # Means we need to split by space.
                first, last = m2.span()
                sepidx = first
            elif m:
                # print 'Other match=>',line
                # No matching wspace char found, need
                # to split by either '=' or ':'
                first, last = m.span()
                sepidx = last - 1
                # print line[sepidx]
                
                
            # If the last character is a backslash
            # it has to be preceded by a space in which
            # case the next line is read as part of the
            # same property
            while line[-1] == '\\':
                # Read next line
                try:
                    nextline = i.next()
                    nextline = nextline.strip()
                    lineno += 1
                    # This line will become part of the value
                    line = line[:-1] + nextline
                except StopIteration:
                    break

            # Now split to key,value according to separation char
            if sepidx != -1:
                key, value = line[:sepidx], line[sepidx+1:]
            else:
                key, value = line,''

            self.processPair(key, value)
            
    def processPair(self, key, value):
        """ Process a (key, value) pair """

        oldkey = key
        oldvalue = value
        
        # Create key intelligently
        keyparts = self.bspacere.split(key)
        # print keyparts

        strippable = False
        lastpart = keyparts[-1]

        if lastpart.find('\\ ') != -1:
            keyparts[-1] = lastpart.replace('\\','')

        # If no backspace is found at the end, but empty
        # space is found, strip it
        elif lastpart and lastpart[-1] == ' ':
            strippable = True

        key = ''.join(keyparts)
        if strippable:
            key = key.strip()
            oldkey = oldkey.strip()
        
        oldvalue = self.unescape(oldvalue)
        value = self.unescape(value)
        
        self.data[key] = value.strip()

#        # Check if an entry exists in pristine keys
#        if self._keymap.has_key(key):
#            oldkey = self._keymap.get(key)
#            self._origprops[oldkey] = oldvalue.strip()
#        else:
#            self._origprops[oldkey] = oldvalue.strip()
#            # Store entry in keymap
#            self._keymap[key] = oldkey
        
    def escape(self, value):

        # Java escapes the '=' and ':' in the value
        # string with backslashes in the store method.
        # So let us do the same.
        newvalue = value.replace(':','\:')
        newvalue = newvalue.replace('=','\=')

        return newvalue

    def unescape(self, value):

        # Reverse of escape
        newvalue = value.replace('\:',':')
        newvalue = newvalue.replace('\=','=')

        return newvalue    
        
    def load(self, stream):
        """ Load properties from an open file stream """
        
        # For the time being only accept file input streams
        if not(hasattr(stream, 'readlines') and callable(stream.readlines)):
            raise TypeError,'Argument should be a file object!'
        # Check for the opened mode
        if hasattr(stream, 'mode') and stream.mode != 'r':
            raise ValueError,'Stream should be opened in read-only mode!'

        try:
            lines = stream.readlines()
            self.__parse(lines)
        except IOError:
            raise

    def store(self, out):
        """ Serialize the properties back to a file. """

        if out.mode[0] != 'w':
            raise ValueError, 'Stream should be opened in write mode!'

        try:
            # Write timestamp
            out.write(''.join(('# ', time.strftime('%a %b %d %H:%M:%S %Z %Y', time.localtime()), '\n')))
            
            # Write properties from the  dictionary
            for key in self.data.keys():
                value = self.data[key]
                out.write(''.join((key, '=', self.escape(value), '\n')))
                
            out.close()
        except IOError, e:
            raise
            

class NestedConfiguration(Configuration):
    """ A nested configuration that may have a parent or child configurations. """
    def __init__(self):
        """ Initialization. """
        Configuration.__init__(self, None)
        self.parent = None
        self.type = None
        self.abstract = None

    def isBuildable(self):
        """ Is this a buildable configuration? """
        return self.abstract == None

    def _addPropertyValue(self, key, value, parseList=True):
        """Adds a property value to the configuration.

        If the property does not exist, it is added without modification.
        If there is already a single value matching the key, the value is replaced by a list
        containing the original and new values.
        If there is already a list, the new value is added to the list.

        The value is first processed in case it also represents a list of values,
        e.g. comma-separated values.
        """
        if parseList and value.find(',') != -1:
            value = value.split(',')
            # Remove all whitespace
            value = [v.strip() for v in value]

        if key in self.data:
            currentValue = self.data[key]

            # Make sure current value is a list
            if not isinstance(currentValue, types.ListType):
                currentValue = [currentValue]

            # Add new value(s)
            if isinstance(value, types.ListType):
                currentValue.extend(value)
            else:
                currentValue.append(value)
            self.data[key] = currentValue
        else:
            self.data[key] = value

    def __getitem__(self, key, interpolate=True):
        """ Get an item. """
        #print "__getitem__(%s, %s)" % (self.name, key)
        if self.data.has_key(key):
            value = super(NestedConfiguration, self).__getitem__(key, False)
            if interpolate:
                return self.interpolate(value)
            return value
        elif self.parent != None:
            value = self.parent.__getitem__(key, False)
            if interpolate:
                return self.interpolate(value)
            return value
        raise KeyError('Cannot find key: ' + key)

    def __setitem__(self, key, item):
        """ Set the value of an item. """
        self.data[key] = item

    def __delitem__(self, key):
        """ Remove an item. """
        del self.data[key]

    def __contains__(self, key):
        """ Check if a keys is defined in the dict. """
        if self.data.__contains__(key):
            return True 
        elif self.parent:
            return self.parent.__contains__(key)
        return False
            
    def keys(self):
        """ Get the list of item keys. """
        myKeys = self.data.keys()
        if self.parent != None:
            parentKeys = self.parent.keys()
            for key in parentKeys:
                if not key in myKeys:
                    myKeys.append(key)
        return myKeys
        
    def has_key(self, key):
        """ Check if key exists. """
        if self.data.has_key(key):
            return True
        if self.parent != None:
            return self.parent.has_key(key)
        return False

    def match_name(self, name):
        """ See if the configuration name matches the argument. """
        if self.name == name:
            return True
        if self.parent != None:
            return self.parent.match_name(name)
        return False


class Specification(NestedConfiguration):
    """ Deprecated. This should be removed in future, it adds no value. """
    
    def __init__(self):
        """ Initialization. """
        NestedConfiguration.__init__(self)


class ConfigurationSet(Configuration):
    """A ConfigurationSet represents a set of configurations.

    Each configuration should be processed separately. This is matching
    the Raptor model where a single XML file can contain definitions
    of multiple specifications and configurations.

    It is however somewhat different from the Commons Configuration classes
    that combine configurations, e.g. CombinedConfiguration,
    CompositeConfiguration. These act to combine configurations in a way
    such that a single configuration interface is still presented to the
    client.
    """
    
    def __init__(self, configs):
        """ Initialization. """
        Configuration.__init__(self)
        self._configs = configs

    def getConfigurations(self, name=None, type=None):
        """ Return a list of configs that matches the name and type specified. 
        
        This can be queried multiple times to retrieve different named configurations.
        """
        result = []
        for c in self._configs:
            if ((name != None and c.match_name(name)) or name == None) and ((type != None and c.type == type) or type == None):
                result.append(c)        
        return result


class ConfigurationBuilder(object):
    """ Base class for builders that can create Configuration objects. """
    
    def getConfiguration(self):
        """Returns a Configuration object."""
        raise NotImplementedError


class NestedConfigurationBuilder(ConfigurationBuilder):
    """ Builder for building Configuration objects from nested configurations. """
    
    _constructors = {'spec':Specification, 'config':NestedConfiguration}

    def __init__(self, inputfile, configname=''):
        """ Initialization. """
        self.inputfile = inputfile
        self.configname = configname
        self._warn_on_deprecated_spec = False

    def getConfiguration(self):
        """ Returns a ConfigurationSet object.

        A ConfigurationSet represents a number of Configuration objects
        that all may need to be processed.
        """
        try:
            dom = xml.dom.minidom.parse(self.inputfile)
        except Exception, exc:
            raise Exception("XML file '%s' cannot be parsed properly: %s" % (self.inputfile, exc))

        # The root element is typically <build> but can be anything
        self.rootNode = dom.documentElement
        configs = []

        # Create a flat list of buildable configurations
        for child in self.rootNode.childNodes:
            if child.nodeType == xml.dom.Node.ELEMENT_NODE:
                _logger.debug('Parsing children')
                self.parseConfiguration(child, configs)

        # Add configuration references
        references = []
        for reference in self.getReferences():
            for conf in configs:
                if conf.match_name(reference[1]):
                    newConf = copy.deepcopy(conf)
                    newConf.name = reference[0]
                    references.append(newConf)

        configs = configs + references

        dom.unlink()
        _logger.debug('Set of configs: ' + str(configs))
        
        if self._warn_on_deprecated_spec:
            _logger.warning("Use of deprecated 'spec' element name in this configuration. Please rename to config")
        return ConfigurationSet(configs)

    def writeToXML(self, output, config_list, config_name=None):
        document = """
<build>
</build>"""        
        doc = xml.dom.minidom.parseString(document)
        docRootNode = doc.documentElement
        configNode = doc.createElement( 'config')
        docRootNode.appendChild(configNode)
        if config_name is not None:
            configNode.setAttribute( 'name', config_name)        
        configNode.setAttribute( 'abstract', 'true')

        for config in config_list:
            configSubNode = doc.createElement( 'config')
            configNode.appendChild(configSubNode)
            if config.name is not None:
                configSubNode.setAttribute( 'name', config.name)

            for key in config.keys():
                if type(config.__getitem__(key)) == types.ListType:
                    for i in range(len(config.__getitem__(key))):
                        setNode = doc.createElement( 'set')
                        configSubNode.appendChild(setNode)
                        setNode.setAttribute( 'name', key)
                        setNode.setAttribute( 'value', config.__getitem__(key)[i]) 
                else:
                    setNode = doc.createElement( 'set')
                    configSubNode.appendChild(setNode)
                    setNode.setAttribute( 'name', key)
                    setNode.setAttribute( 'value', config.__getitem__(key))
        out = open(output, 'w+')
        out.write(doc.toprettyxml())
        out.close()            


    def getConfigurations(self, name=None, type=None):
        """ Get a list of the individual configurations. 
        
        Once read a new builder must be opened to retrieve a differently filtered set of configurations.
        """
        config_set = self.getConfiguration()
        return config_set.getConfigurations(name, type)

    def getReferences(self):
        references = []
        for rootNode in self.rootNode.childNodes:
            if rootNode.nodeType == xml.dom.Node.ELEMENT_NODE:
                for child in rootNode.childNodes:
                    if child.nodeType == xml.dom.Node.ELEMENT_NODE:
                        for conf in child.childNodes:
                            if conf.nodeName == 'specRef':
                                for ref in conf.getAttribute('ref').split(','):
                                    if not ( child.getAttribute('abstract') and str(self.configname) == '' ):
                                        references.append([child.getAttribute('name'), ref])
        return references

    def parseConfiguration(self, configNode, configs, parentConfig=None):
        """ Parse an individual nested configuration. """
        # Create appropriate config object
        if configNode.nodeName == 'spec':
            self._warn_on_deprecated_spec = True
        constructor = self._constructors[configNode.nodeName]
        config = constructor()
        _logger.debug('Configuration created: ' + str(config))
        if parentConfig != None:
            config.parent = parentConfig
            #config.data.update(parentConfig.data)

        # Add any attribute properties
        for i in range(configNode.attributes.length):
            attribute = configNode.attributes.item(i)
            if hasattr(config, attribute.name):
                _logger.debug('Adding config attribute: ' + str(attribute.name))
                setattr(config, str(attribute.name), attribute.nodeValue)
            else:
                raise Exception('Invalid attribute for configuration: ' + attribute.name)

        # Process the config element's children
        configChildNodes = []

        for child in configNode.childNodes:
            if child.nodeType == xml.dom.Node.ELEMENT_NODE:
                # <append> directives should add to parent values. In
                # this case initially set the value to the parent value.
                if child.nodeName == 'append':
                    name = child.getAttribute('name')
                    if parentConfig != None and parentConfig.has_key(name):
                        parent_value = parentConfig.__getitem__(name, False)
                        if not isinstance(parent_value, types.ListType):
                            parent_value = [parent_value]
                        for value in parent_value:
                            config._addPropertyValue(name, value)

                if child.nodeName == 'set' or child.nodeName == 'append':
                    name = child.getAttribute('name')
                    if child.hasAttribute('value'):
                        value = child.getAttribute('value')
                        config._addPropertyValue(name, value)
                    elif child.hasChildNodes():
                        value = ""
                        for textchild in child.childNodes:
                            value += textchild.data
                        config._addPropertyValue(name, value, False)
                elif child.nodeName == 'specRef':
                    for ref in child.getAttribute('ref').split(','):
                        node = self.getNodeByReference(ref)
                        if not node:
                            raise Exception('Referenced spec not found: ' + ref)
                elif self._constructors.has_key(child.nodeName):
                    configChildNodes.append(child)
                else:
                    raise Exception('Bad configuration xml element: ' + child.nodeName)

        # Only save the buildable configurations
        if config.isBuildable():
            _logger.debug('Adding config to buildable set: ' + str(config))
            configs.append(config)
            
        for childConfigNode in configChildNodes:
            self.parseConfiguration(childConfigNode, configs, config)

    def getNodeByReference(self, refName):
        """ Find a node based on a reference to it. """
        for child in self.rootNode.childNodes:
            if child.nodeType == xml.dom.Node.ELEMENT_NODE:
                for conf in child.childNodes:
                    if conf.nodeName == 'spec':
                        if refName == conf.getAttribute('name'):
                            return conf


class HierarchicalConfiguration(Configuration):
    """ Represents hierarchical configurations such as XML documents. """
    
    def __init__(self):
        """ Initialization. """
        Configuration.__init__(self, None)
        self._root = None
        
    def __getitem__(self, key, interpolate=True):
        """ Get an item as a dict. """
        elements = self._root.xpath(_Key(key).to_xpath())
        values = [element.text for element in elements]
        value = ','.join(values)
        if interpolate:
            value = self.interpolate(value)
        return value
        
    def has_key(self, key):
        """ Check if key exists. """
        elements = self._root.xpath(_Key(key).to_xpath())
        if len(elements) > 0:
            return True
        return False
        
    
class _Key(object):
    """ A hierarchical configuration key. """
    
    def __init__(self, string):
        """ Initialization. """
        self.string = string
        
    def to_xpath(self):
        """ Convert the key to XPath syntax. """
        return self.string.replace('.', '/')
        
        
class XMLConfiguration(HierarchicalConfiguration):
    """ A XML-based hierarchical configuration. """
    
    def __init__(self, file_):
        """ Initialization. """
        from lxml import etree
        HierarchicalConfiguration.__init__(self)
        
        self._root = etree.parse(file_)
        
        
        