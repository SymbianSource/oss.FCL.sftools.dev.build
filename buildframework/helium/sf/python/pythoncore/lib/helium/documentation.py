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

import amara

class APIDeltaWriter(object):
    """ Creates an XML delta of the Helium API between releases. """
    def __init__(self, old_database, new_database):
        """ Initialisation. """
        self.old_database = old_database
        self.new_database = new_database
        
    def write(self, path):
        """ Write the API delta information to an XML file. """
        root = amara.create_document('apiChanges')
        
        old_db = amara.parse(self.old_database)
        new_db = amara.parse(self.new_database)        
        
        old_macro_names = set([str(macro.name) for macro in old_db.xml_xpath('/antDatabase/project/macro')])
        new_macro_names = set([str(macro.name) for macro in new_db.xml_xpath('/antDatabase/project/macro')])
        
        old_target_names = set([str(target.name) for target in old_db.xml_xpath('/antDatabase/project/target')])
        new_target_names = set([str(target.name) for target in new_db.xml_xpath('/antDatabase/project/target')])
        new_target_names_public = set([str(target.name) for target in new_db.xml_xpath("/antDatabase/project/target[scope='public']")])
        
        old_property_names = set([str(property_.name) for property_ in old_db.xml_xpath('/antDatabase/project/property')])
        new_property_names = set([str(property_.name) for property_ in new_db.xml_xpath('/antDatabase/project/property')])
        new_property_names_public = set([str(property_.name) for property_ in new_db.xml_xpath("/antDatabase/project/property[scope='public']")])
        
        old_project_names = set([str(project.name) for project in old_db.xml_xpath('/antDatabase/project')])
        new_project_names = set([str(project.name) for project in new_db.xml_xpath('/antDatabase/project')])
        
        dict_old_taskdef_names  = {}
        dict_new_taskdef_names  = {}
        for taskdef in old_db.xml_xpath('/antDatabase/project/taskdef'):
            dict_old_taskdef_names[taskdef.name] = taskdef.name
        for taskdef in new_db.xml_xpath('/antDatabase/project/taskdef'):
            dict_new_taskdef_names[taskdef.name] = taskdef.name

        projects_removed = old_project_names.difference(new_project_names)
        for project in projects_removed:
            root.xml_append(root.xml_create_element('project', attributes={'state': 'removed'}, content=project))
        projects_added = new_project_names.difference(old_project_names)
        for project in projects_added:
            root.xml_append(root.xml_create_element('project', attributes={'state': 'added'}, content=project))
        
        propertys_removed = old_property_names.difference(new_property_names)
        for property_ in propertys_removed:
            root.xml_append(root.xml_create_element('property', attributes={'state': 'removed'}, content=property_))
        propertys_added = new_property_names.difference(old_property_names)
        for property_ in propertys_added:
            if property_ in new_property_names_public or new_property_names_public == set([]):
                root.xml_append(root.xml_create_element('property', attributes={'state': 'added'}, content=property_))
                    
        macros_removed = old_macro_names.difference(new_macro_names)
        for macro in macros_removed:
            root.xml_append(root.xml_create_element('macro', attributes={'state': 'removed'}, content=macro))
        macros_added = new_macro_names.difference(old_macro_names)
        for macro in macros_added:
            root.xml_append(root.xml_create_element('macro', attributes={'state': 'added'}, content=macro))
        targets_removed = old_target_names.difference(new_target_names)
        
        for target in targets_removed:
            root.xml_append(root.xml_create_element('target', attributes={'state': 'removed'}, content=target))
        targets_added = new_target_names.difference(old_target_names)
        for target in targets_added:
            if target in new_target_names_public or new_target_names_public == set([]):
                root.xml_append(root.xml_create_element('target', attributes={'state': 'added'}, content=target))

        taskdefs_removed = set(dict_old_taskdef_names.keys()) - set(dict_new_taskdef_names.keys()) 
        for taskdefKey in taskdefs_removed:
            taskdef_element = root.xml_create_element('taskdef', attributes={'state': 'removed'}, content=str(taskdefKey))
            root.xml_append(taskdef_element)
            taskdef_element.classname = dict_old_taskdef_names[taskdefKey]
        taskdefs_added = set(dict_new_taskdef_names.keys()) - set(dict_old_taskdef_names.keys())
        for taskdefKey in taskdefs_added:
            taskdef_element = root.xml_create_element('taskdef', attributes={'state': 'added'}, content=str(taskdefKey))
            root.xml_append(taskdef_element)
            taskdef_element.classname = dict_new_taskdef_names[taskdefKey]
            
        f = open(path, 'w')
        root.xml(indent=True, out=f)
        f.close()
        
        
        
        