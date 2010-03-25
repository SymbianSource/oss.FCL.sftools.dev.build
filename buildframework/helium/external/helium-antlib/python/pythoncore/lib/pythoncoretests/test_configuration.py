#============================================================================ 
#Name        : test_configuration.py 
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
import StringIO
import unittest
import os
import tempfile
import sys
import configuration

_logger = logging.getLogger('test.configuration')
logging.basicConfig(level=logging.INFO)

class NestedConfigurationBuilderTest(unittest.TestCase):
    def setUp(self):
        """ Setup. """
        config_file = open(os.path.join(os.environ['TEST_DATA'], 'data/config_test.cfg.xml'), 'r')
        self._builder = configuration.NestedConfigurationBuilder(config_file)
        
    def test_config_parsing(self):
        """A basic configuration can be parsed."""
        config_set = self._builder.getConfiguration()
        configs = config_set.getConfigurations()
        
        assert len(configs) == 10
        for config in configs:
            print
            for k in config.keys():
                print k + ': ' + str(config[k])

        assert configs[0]['A'] == 'foo'
        assert configs[0]['B'] == 'child -> foo'
        assert configs[0]['C'] == 'missing value test ${does_not_exist}'
        assert configs[0]['node.content'].strip() == 'This is the value!'
        assert configs[1]['A'] == 'foo'
        assert configs[1]['B'] == 'parent: foo'
        assert configs[1]['C'] == ['one', 'two']
        assert 'C' in configs[1]
        assert 'Z' not in configs[1]

        configs = config_set.getConfigurations('spec.with.type')
        assert len(configs) == 1
        assert configs[0].type == 'test.type', "config.type must match 'test.type'."
        
        configs = config_set.getConfigurations(type='test.type')
        assert len(configs) == 2
        assert configs[0].type == 'test.type', "config.type must match 'test.type'."

        configs = config_set.getConfigurations(name='test_spec', type='test.type')
        assert len(configs) == 2
        assert configs[0].type == 'test.type', "config.type must match 'test.type'."
        
    def test_append(self):
        """A child value can be appended to a parent value."""
        configs = self._builder.getConfigurations()
        config = configs[4]
        assert config['A'] == ['foo', 'bar']
        
    def test_parent_interpolated_by_child(self):
        """ A child value can be interpolated into a parent template. """
        configs = self._builder.getConfigurations()
        parent_config = configs[5]
        child_config = configs[6]
        assert parent_config['template'] == 'value -> from parent'
        assert child_config['template'] == 'value -> from child'
     
    def test_property_escaping(self):
        """ Property values can be escaped in the values of other properties. """
        config_text = """
<build>
    <config name="test_spec">
        <set name="A" value="foo"/>
        <set name="B" value="A = ${A}"/>
    </config>
</build>"""

        builder = configuration.NestedConfigurationBuilder(StringIO.StringIO(config_text))
        config = builder.getConfiguration().getConfigurations()[0]
        print config['B']
        #assert configs[1]['C'] == ['one', 'two']

    def test_any_root_element(self):
        """ Any root element name can be used. """
        config_text = """
<someConfigData>
    <config name="test_spec">
        <set name="A" value="foo"/>
    </config>
</someConfigData>"""

        builder = configuration.NestedConfigurationBuilder(StringIO.StringIO(config_text))
        config = builder.getConfiguration().getConfigurations()[0]
        assert config['A'] == 'foo'

    def test_list_templating(self):
        """ Testing list templating. """
        configs = self._builder.getConfigurations('test_list_config1')
        # should return only one config.
        assert len(configs) == 1
        
        _logger.debug(configs[0].get_list('include', []))
        result = configs[0].get_list('include', [])
        result.sort()
        print result
        assert len(result) == 3
        assert result == [u'bar1_config1', u'bar2_config1', u'foo_config1']        

    def test_list_templating2(self):
        """ Testing list templating 2. """
        configs = self._builder.getConfigurations('test_list_config2')
        # should return only one config.
        assert len(configs) == 1
        
        _logger.debug(configs[0].get_list('include', []))
        result = configs[0].get_list('include', [])
        result.sort()
        print result
        assert len(result) == 3
        assert result == [u'bar1_config2', u'bar2_config2', u'foo_config2']        
        

    def test_append_list(self):
        """ Testing if append handles the list correctly..."""
        config_text = """
<build>
<config name="prebuild_zip" abstract="true">
   <set name="exclude" value="**/_ccmwaid.inf" />
   <set name="exclude" value="build/**" />
   <set name="exclude" value="config/**" />
   <set name="exclude" value="ncp_sw/**" />
   <set name="exclude" value="ppd_sw/**" />
   <set name="exclude" value="psw/**" />
   <set name="exclude" value="tools/**" />
   <set name="include" value="foo/**" />
   <config>
    <set name="root.dir" value="X:/rootdir" />
    <set name="name" value="PF5250_200832_internal_code" />
    <set name="include" value="**/internal/**" />
    <set name="grace.filters" value="tsrc" />
    <set name="grace.default" value="false" />
   </config>
   <config>
    <set name="root.dir" value="X:/rootdir" />
    <set name="name" value="PF5250_200832_doc" />
    <append name="include" value="**/doc/**" />
    <set name="include" value="**/docs/**" />
    <append name="exclude" value="**/internal/**" />                            <!-- set changed to append -->
    <set name="grace.filters" value="tsrc" />
    <set name="grace.default" value="false" />
   </config>
  </config>
</build>
"""        
        builder = configuration.NestedConfigurationBuilder(StringIO.StringIO(config_text))
        configs = builder.getConfigurations()
        config = configs[1]
        print config['exclude']
        print config['include']
        exclude_match = [u'**/_ccmwaid.inf', u'build/**', u'config/**',
                                          u'ncp_sw/**', u'ppd_sw/**', u'psw/**', u'tools/**',
                                          u'**/internal/**']
        exclude_result = config['exclude']
        exclude_match.sort()
        exclude_result.sort()
        assert len(config['include']) == 3
        assert exclude_result == exclude_match

        config = configs[0]
        assert config['include'] == '**/internal/**'
        assert len(config['exclude']) == 7
        
    def test_writeToXML(self):
        """ To write the configurations into XML file. """
        config_text = """
<build>
    <config name="test_spec">
        <set name="A" value="foo"/>
        <set name="B" value="A = ${A}"/>
        <config name="test_spec_1">
            <set name="A" value="foo"/>
            <set name="B" value="A = ${A}"/>        
        </config>
        <config name="test_spec_2">
            <set name="A" value="foo"/>
            <set name="B" value="A = ${A}"/>
            <config name="test_spec_3">
                <set name="A" value="foo"/>
                <set name="B" value="A = ${A}"/>        
            </config>        
        </config>        
    </config>
</build>"""    
        
        builder = configuration.NestedConfigurationBuilder(StringIO.StringIO(config_text))
        configSet = builder.getConfiguration()
        configs = configSet.getConfigurations('test_spec_1')
        (out, outputFile) = tempfile.mkstemp('.tmp', 'zip_test')
        builder.writeToXML(outputFile, configs, 'test_spec_1')
        
        builder = configuration.NestedConfigurationBuilder(open(outputFile), 'r')
        configSet = builder.getConfiguration()
        configs = configSet.getConfigurations('test_spec_1')
        config = configs[0]
        assert config['A'] == 'foo'
        
        builder = configuration.NestedConfigurationBuilder(StringIO.StringIO(config_text))
        configSet = builder.getConfiguration()
        configs = configSet.getConfigurations('test_spec')
        (out, outputFile) = tempfile.mkstemp('.tmp', 'zip_test')
        builder.writeToXML(outputFile, configs )
        
        builder = configuration.NestedConfigurationBuilder(open(outputFile), 'r')
        configSet = builder.getConfiguration()
        configs = configSet.getConfigurations('test_spec')
        config = configs[0]
        assert config['B'] == 'A = foo'
        
        

        
class PropertiesConfigurationTest(unittest.TestCase):
    """ Test plain text configuration files. """
    def test_text_config(self):
        """ Basic text properties can be read. """
        config = configuration.PropertiesConfiguration(open(os.path.join(os.environ['TEST_DATA'], 'data/ant_config_test.txt'), 'r'))
        
        assert config['text.a'] == 'text.value.A'
        assert config['text.b'] == 'text.value.B'

    def test_text_config_store(self):
        """ Basic text properties can be read. """
        config = configuration.PropertiesConfiguration(open(os.path.join(os.environ['TEST_DATA'], 'data/ant_config_test.txt'), 'r'))

        config['foo'] = "bar"
        (fd, filename) = tempfile.mkstemp()
        f = os.fdopen(fd, 'w')
        config.store(f)
        config = configuration.PropertiesConfiguration(open(filename))
        
        assert config['text.a'] == 'text.value.A'
        assert config['text.b'] == 'text.value.B'
        assert config['foo'] == 'bar'
        
        
if 'java' not in sys.platform:
    class XMLConfigurationTest(unittest.TestCase):
        """ Test XML format configuration files. """
        
        def test_single_node_xml(self):
            """ Properties can be read from 1 level of XML sub-elements. """
            config = configuration.XMLConfiguration(open(os.path.join(os.environ['TEST_DATA'], 'data/ant_config_test.xml'), 'r'))
            
            assert config['foo'] == 'bar'
            assert config['interpolated'] == 'foo value = bar'
            
        def test_nested_node_xml(self):
            """ Properties can be read from multiple levels of XML sub-elements. """
            config = configuration.XMLConfiguration(open(os.path.join(os.environ['TEST_DATA'], 'data/ant_config_test.xml'), 'r'))
            
            assert config['xml.c'] == 'C'
            
        def test_xml_list(self):
            """ Multiple XML elements can be read as a list. """
            config = configuration.XMLConfiguration(open(os.path.join(os.environ['TEST_DATA'], 'data/ant_config_test.xml'), 'r'))
            
            assert config['array.value'] == 'one,two,three'
        