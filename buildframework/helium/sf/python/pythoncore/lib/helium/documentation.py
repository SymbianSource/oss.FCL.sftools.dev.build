#============================================================================ 
#Name        : documentation.py 
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

""" Helium API documentation processing. """

from lxml import etree


class APIDeltaWriter(object):
    """ Creates an XML delta of the Helium API between releases. """
    def __init__(self, old_database, new_database):
        """ Initialisation. """
        self.old_database = old_database
        self.new_database = new_database
        
    def write(self, path):
        """ Write the API delta information to an XML file. """
        root = etree.Element('apiChanges')
        
        old_db = etree.parse(self.old_database)
        new_db = etree.parse(self.new_database)
        
        
        old_macro_names = set([macro[0].text for macro in old_db.findall('/project/macro')])
        new_macro_names = set([macro[0].text for macro in new_db.findall('/project/macro')])
        
        old_target_names = set([target[0].text for target in old_db.findall('/project/target')])
        new_target_names = set([target[0].text for target in new_db.findall('/project/target')])
        
        old_property_names = set([property[0].text for property in old_db.findall('/project/property')])
        new_property_names = set([property[0].text for property in new_db.findall('/project/property')])
        
        old_project_names = set([project[0].text for project in old_db.findall('/project')])
        new_project_names = set([project[0].text for project in new_db.findall('/project')])
        
        dict_old_taskdef_names  = {}
        dict_new_taskdef_names  = {}
        for taskdef in old_db.findall('/project/taskdef'):
            dict_old_taskdef_names[taskdef[0].text] = taskdef[1].text
        for taskdef in new_db.findall('/project/taskdef'):
            dict_new_taskdef_names[taskdef[0].text] = taskdef[1].text

        projects_removed = old_project_names.difference(new_project_names)
        for project in projects_removed:
            project_element = etree.SubElement(root, 'project', attrib={'state': 'removed'})
            project_element.text = project
        projects_added = new_project_names.difference(old_project_names)
        for project in projects_added:
            project_element = etree.SubElement(root, 'project', attrib={'state': 'added'})
            project_element.text = project
        
        propertys_removed = old_property_names.difference(new_property_names)
        for property in propertys_removed:
            property_element = etree.SubElement(root, 'property', attrib={'state': 'removed'})
            property_element.text = property
        propertys_added = new_property_names.difference(old_property_names)
        for property in propertys_added:
            property_element = etree.SubElement(root, 'property', attrib={'state': 'added'})
            property_element.text = property
                    
        macros_removed = old_macro_names.difference(new_macro_names)
        for macro in macros_removed:
            macro_element = etree.SubElement(root, 'macro', attrib={'state': 'removed'})
            macro_element.text = macro
        macros_added = new_macro_names.difference(old_macro_names)
        for macro in macros_added:
            macro_element = etree.SubElement(root, 'macro', attrib={'state': 'added'})
            macro_element.text = macro
        targets_removed = old_target_names.difference(new_target_names)
        
        for target in targets_removed:
            target_element = etree.SubElement(root, 'target', attrib={'state': 'removed'})
            target_element.text = target
        targets_added = new_target_names.difference(old_target_names)
        for target in targets_added:
            target_element = etree.SubElement(root, 'target', attrib={'state': 'added'})
            target_element.text = target

        taskdefs_removed = set(dict_old_taskdef_names.keys()) - set(dict_new_taskdef_names.keys()) 
        for taskdefKey in taskdefs_removed:
            taskdef_element = etree.SubElement(root, 'taskdef', attrib={'state': 'removed'})
            taskdef_element.text = taskdefKey
            taskdef_element.attrib['classname'] =  dict_old_taskdef_names[taskdefKey]
        taskdefs_added = set(dict_new_taskdef_names.keys()) - set(dict_old_taskdef_names.keys())
        for taskdefKey in taskdefs_added:
            taskdef_element = etree.SubElement(root, 'taskdef', attrib={'state': 'added'})
            taskdef_element.text = taskdefKey
            taskdef_element.attrib['classname'] =  dict_new_taskdef_names[taskdefKey]
            
        etree.dump(root)
        tree = etree.ElementTree(root)
        tree.write(path, pretty_print=True)
        
        
        
        