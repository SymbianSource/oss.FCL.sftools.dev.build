#============================================================================ 
#Name        : test_buildmodel.py 
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

""" Test build.model module. """

import os
import sys
import unittest

import build.model
import configuration
import ccm
import amara

database = "to1tobet"

class BOMMockFolder:    
    def __init__(self, name, instance, description, tasks):
        self.name = name
        self.instance = instance
        self.description = description
        self.tasks = tasks
        
class BOMMockProject:
    def __init__(self, name):
        self.name = name
    
    def __str__(self):
        return self.name
    
    @property
    def tasks(self):
        return []
    
    @property
    def folders(self):
        return [BOMMockFolder('5856', 'tr1s60', "all completed tasks for release ABS_domain/abs.mcl for collaborative projects", [])] 
    
class BOMMock:
    
    def __init__(self):
        self.config = {}
        self.config['build.id'] = "mock"
    
    @property
    def projects(self):    
        return [BOMMockProject('ABS_domain-abs.mcl_200843:project:tr1s60#1')] 

    def all_baselines(self):
        return []

# Refactor required: See http://delivery.nmp.nokia.com/trac/helium/ticket/1517
class BOMTest(unittest.TestCase):
    """ Test BOM and related classes. """
    
# TODO - removed until non-Synergy dependent tests can be provided.

#    def test_bom_output(self):
#        """ Test basic BOM execution. Only new spec format will be covered!"""
#        try:
#            session = ccm.open_session(database=database)
#        except ccm.CCMException:
#            print "Skipping BOMTest test cases."
#            return
#            
#        project = session.create('helium-helium_0.1:project:vc1s60p1#1')
#        config_dict = {'delivery': 'tests/data/test_delivery.xml',
#                       'prep.xml': 'tests/data/test_prep.xml',
#                       'build.id': "test_0.0",
#                       'ccm.database': session.database()}
#        config = configuration.Configuration(config_dict)
#        bom = build.model.BOM_new_spec_config(config, project)
#        writer = build.model.BOMHTMLWriter(bom)
#        writer.write("bom2.html")
#        session.close()
#        os.remove("bom2.html")
#        os.remove("bom2.html.xml")

    def test_bom_delta(self):
        """ Testing BOM delta creation... """
        delta = build.model.BOMDeltaXMLWriter(BOMMock(), os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/build_model_bom.xml'))
        delta.write(os.path.join(os.environ['HELIUM_HOME'], 'build','delta.xml'))
        xml = amara.parse(open(os.path.join(os.environ['HELIUM_HOME'], 'build','delta.xml'), 'r'))
        assert xml.bomDelta[0].buildFrom[0] == "ido_raptor_mcl_abs_MCL.52.57"
        assert xml.bomDelta[0].buildTo[0] == "mock"

        print "baselines: ", len(xml.bomDelta.content.baseline)
        print "folders: ", len(xml.bomDelta.content.folder)
        print "tasks: ", len(xml.bomDelta.content.task)
        print "baseline[@overridden='false']:", len(xml.bomDelta.content.xml_xpath("baseline[@overridden='false']"))
        print "baseline[@overridden='true']: ", len(xml.bomDelta.content.xml_xpath("baseline[@overridden='true']"))
        print "folder[@status='deleted']: ", len(xml.bomDelta.content.xml_xpath("folder[@status='deleted']"))
        print "task[@status='deleted']: ", len(xml.bomDelta.content.xml_xpath("task[@status='deleted']"))

        assert len(xml.bomDelta.content.baseline) == 156
        assert len(xml.bomDelta.content.folder) == 1
        assert len(xml.bomDelta.content.task) == 1
        assert len(xml.bomDelta.content.xml_xpath("baseline[@overridden='false']")) == 155
        assert len(xml.bomDelta.content.xml_xpath("baseline[@overridden='true']")) == 1

        assert len(xml.bomDelta.content.xml_xpath("folder[@status='deleted']")) == 1

        assert len(xml.bomDelta.content.xml_xpath("task[@status='deleted']")) == 1
        
    def test_validate_bom_delta(self):
        """ Testing BOM delta validation... """
        bom_delta_validate = build.model.BOMDeltaXMLWriter((os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_102_bom.xml')), (os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_101_bom.xml')))
        delta_bom_content_validity = bom_delta_validate.validate_delta_bom_contents(os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_102_bom_delta.xml'), os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_102_bom.xml'), os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_101_bom.xml'))
        self.assertEqual(True, delta_bom_content_validity) 
        delta_bom_content_validity = bom_delta_validate.validate_delta_bom_contents(os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_104_bom_delta.xml'), os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_102_bom.xml'), os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_101_bom.xml'))
        self.assertEqual(False, delta_bom_content_validity) 
        delta_bom_content_validity = bom_delta_validate.validate_delta_bom_contents(os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_103_bom_delta.xml'), os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_103_bom.xml'), os.path.join(os.environ['HELIUM_HOME'], 'tests/data/bom/bom_validate_102_bom.xml'))
        self.assertEqual(None, delta_bom_content_validity) 
