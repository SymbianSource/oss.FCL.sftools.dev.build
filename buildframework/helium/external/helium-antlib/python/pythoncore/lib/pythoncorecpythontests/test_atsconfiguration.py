# -*- encoding: latin-1 -*-

#============================================================================ 
#Name    : test_ATSconfiguration.py 
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

""" Testing the ATS configuration file """

import logging
import StringIO

import configuration
import ats3.parsers

_logger = logging.getLogger('test.atsconfiguration')
logging.basicConfig(level=logging.INFO)



def test_ATS_element():
    """ ATS elements can be used in configuration. """
    config_text = """
<ATSConfigData>
    <config name="properties">
    <set name="PA" value="foo"/>
    </config>
    <config name="attributes">
    <set name="attrs" value="foo"/>
    <set name="AB" value="100"/>
    <set name="AC" value="101"/>
    </config>
</ATSConfigData>"""

    builder = configuration.NestedConfigurationBuilder(StringIO.StringIO(config_text))
    config = builder.getConfiguration().getConfigurations()
    assert config[0]['PA'] == 'foo'
    assert config[1]['AB'] == '100'



def test_ATS_config_attirbutes():
    """ ATS elements can be used attributes only. """
    config_text = """
<ATSConfigData>
    <config name="attributes">
    <set name="attrs" value="foo"/>
    <set name="AB" value="100"/>
    <set name="AC" value="101"/>
    </config>
</ATSConfigData>"""
    (params, attrs) = ats3.parsers.split_config_to_attributes_and_properties(StringIO.StringIO(config_text))

    print attrs
    print params
    assert params ==  {}
    assert attrs ==  {u'attrs': u'foo', u'AC': u'101', u'AB': u'100'}

def test_ATS_config_properties():
    """ ATS elements can be used properties only. """
    config_text = """
<ATSConfigData>
    <config name="noattributes">
    <set name="attrs" value="foo"/>
    <set name="AB" value="100"/>
    <set name="AC" value="101"/>
    </config>
    <config name="properties">
    <set name="HW" value="foo"/>
    </config>
</ATSConfigData>"""
    (params, attrs) = ats3.parsers.split_config_to_attributes_and_properties(StringIO.StringIO(config_text))

    print attrs
    print params
    assert params ==  {u'HW': u'foo' }
    assert attrs ==  { }


def test_ATS_element3():
    """ All alements can be used and several times. """
    config_text = """
<ATSConfigData>
    <config name="attributes">
    <set name="attrs" value="foo"/>
    <set name="AB" value="100"/>
    <set name="AC" value="101"/>
    </config>
    <config name="properties">
    <set name="PA" value="foo"/>
    </config>
    <config name="properties">
    <set name="HW" value="bar"/>
    </config>
</ATSConfigData>"""
    	
    (params, attrs) = ats3.parsers.split_config_to_attributes_and_properties(StringIO.StringIO(config_text))

    print attrs
    print params
    assert params ==  {u'PA': u'foo' , u'HW': u'bar'}
    assert attrs ==  {u'attrs': u'foo', u'AC': u'101', u'AB': u'100'}



