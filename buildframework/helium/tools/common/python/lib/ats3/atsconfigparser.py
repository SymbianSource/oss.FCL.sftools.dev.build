#============================================================================ 
#Name        : atsconfigparser.py
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

import configuration
import amara

class TestXML:
    def __init__(self, testxml):
        self.testxml = testxml
        self.doc = amara.parse(testxml)

    def containsproperty(self, name, value):
        for p in self.doc.xml_xpath("//property"):
            if str(p.name) == name:
                return str(p.value) == value
        return False
    
    def containssetting(self, name, value):
        for p in self.doc.xml_xpath("//setting"):
            if str(p.name) == name:
                return str(p.value) == value
        return False
    
    def addorreplacesetting(self, name, value):
        changed = False
        for p in self.doc.xml_xpath("//setting"):
            if str(p.name) == name:
                p.value = value
                changed = True
        if not changed:
            for device in self.doc.test.target.device:
                device.xml_append(self.doc.xml_create_element(u"setting", attributes = {u'name': unicode(name), u'value': unicode(value)}))
        
    def containsattribute(self, name, value):
        for p in self.doc.xml_xpath("//*[@" + name + "]"):
            if p[name] == value:
                return True
        return False
        
    def replaceattribute(self, name, value):
        for p in self.doc.xml_xpath("//*[@" + name + "]"):
            p[name] = value
            
    def addorreplaceproperty(self, name, value):
        changed = False
        for p in self.doc.xml_xpath("//property"):
            if str(p.name) == name:
                p.value = value
                changed = True
        if not changed:
            for device in self.doc.test.target.device:
                device.xml_append(self.doc.xml_create_element(u"property", attributes = {u'name': unicode(name), u'value': unicode(value)}))


class ATSConfigParser:
    def __init__(self, specfilename):
        specfile = open(specfilename)
        builder = configuration.NestedConfigurationBuilder(specfile)
        self.configs = builder.getConfigurations("common")
    
    def properties(self):
        props = {}
        for config in self.configs:
            if (config.type == "properties"):
                for subconfig in config:
                    props[subconfig] = config[subconfig]
        return props
        
    def settings(self):
        settings = {}
        for config in self.configs:
            if (config.type == "settings"):
                for subconfig in config:
                    settings[subconfig] = config[subconfig]
        return settings

def converttestxml(specfilename, testxmldata):
    specfile = open(specfilename)
    
    builder = configuration.NestedConfigurationBuilder(specfile)
    configs = builder.getConfigurations("common")# + builder.getConfigurations("ats3")
    
    testxml = TestXML(testxmldata)
    
    for config in configs:
        if (config.type == "properties"):
            for subconfig in config:
                testxml.addorreplaceproperty(subconfig, config[subconfig])
        if (config.type == "conditional_properties"):
            check = config.name.split(',')
            if testxml.containsproperty(check[0], check[1]):
                for subconfig in config:
                    testxml.addorreplaceproperty(subconfig, config[subconfig])
        if (config.type == "settings"):
            for subconfig in config:
                testxml.addorreplacesetting(subconfig, config[subconfig])
        if (config.type == "conditional_settings"):
            check = config.name.split(',')
            if testxml.containssetting(check[0], check[1]):
                for subconfig in config:
                    testxml.addorreplacesetting(subconfig, config[subconfig])
        if (config.type == "attributes"):
            for subconfig in config:
                testxml.replaceattribute(subconfig, config[subconfig])
        if (config.type == "conditional_attributes"):
            check = config.name.split(',')
            if testxml.containsattribute(check[0], check[1]):
                for subconfig in config:
                    testxml.replaceattribute(subconfig, config[subconfig])
    
    return testxml.doc.xml(indent=u"yes")
