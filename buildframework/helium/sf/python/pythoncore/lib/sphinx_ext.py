#============================================================================ 
#Name        : sphinx_ext.py 
#Part of     : Helium 
#
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
""" Custom Sphinx operations to help with Helium doc linking. """

import os
import re
import atexit

from docutils import nodes, utils
from docutils.parsers.rst import directives

import amara

tree = None
treecache = None
database_path = os.path.abspath(os.path.join(os.getcwd() + '/build', 'public_database.xml'))

# Error count for custom sphinx operations
exit_with_failure = 0 

def check_cached_database():
    """ Check the Ant database XML data is cached as needed. """
    global tree
    global treecache    
    
    if tree == None or treecache == None:
        f = open(database_path)
        tree = amara.parse(f)
    
        treecache = {}
        for project in tree.antDatabase.project:
            for x in project.xml_children:
                if hasattr(x, 'name'):
                    treecache[str(x.name)] = [str(project.name),'project']
        if hasattr(tree.antDatabase, "antlib"):
            for antlib in tree.antDatabase.antlib:
                for x in antlib.xml_children:
                    if hasattr(x, 'name'):
                        treecache[str(x.name)] = [str(antlib.name),'antlib']
        
def handle_hlm_role(role, _, text, lineno, inliner, options=None, content=None): # pylint: disable=W0613
    """ Process a custom Helium ReStructuredText role to link to a target, property or macro. """
    if options == None:
        options = {}
    if content == None:
        content = []
        
    # See if the role is used to embed a API element field
    if '[' in text:
        role_data = _embed_role_field(role, text, lineno, inliner)
    else:
        role_data = _build_link(text, lineno, inliner, options)
        
    return role_data
    
def _embed_role_field(role, text, lineno, inliner):
    """ Insert the contents of an element field. 
    
    These take the form of e.g. hlm-p:`build.drive[summary]`
    """
    messages = []
    node = nodes.Text('', '')
    
    field_match = re.search("(.*?)\[(.*?)\]", text)
    if field_match != None:
        element_name = field_match.group(1)
        field_name = field_match.group(2)
        if field_name != None and len(field_name) > 0:
            field_value = find_field_value(role, element_name, field_name)
            if field_value != None and len(field_value) > 0:
                node = nodes.Text(field_value, utils.unescape(field_value))
            else:
                messages.append(inliner.reporter.error(('Field value cannot be found for API field: "%s".' % text), line=lineno))
        else:
            messages.append(inliner.reporter.error(('Invalid field name for API value replacement: "%s".' % text), line=lineno))
        return [node], messages

def find_field_value(role, element_name, field_name):
    """ Gets the value of a field from an API element. """
    check_cached_database()
    
    field_value = None
    element = tree.xml_xpath('//' + roles[role] + "[name='" + element_name + "']")
    
    if element != None and len(element) == 1:
        field_value_list = element[0].xml_xpath(field_name)
        if field_value_list != None and len(field_value_list) == 1:
            field_value = str(field_value_list[0])
    return field_value
    

def _build_link(text, lineno, inliner, options):
    """ Build an HTML link to the API doc location for API element. """
    global exit_with_failure
    full_path_match = re.search(r"<document source=\"(.*?)\"", str(inliner.document))
    full_path = full_path_match.group(1)
    path_segment = full_path[full_path.index('\\doc\\') + 5:]
    dir_levels = path_segment.count('\\')
    (parent_type, parent_name) = get_root_element_name(text)
    messages = []
    
    # See if link can be built
    if parent_type != None and parent_name != None:
        href_text = text.replace('.', '-').lower()
        api_path_segment = 'api/helium/' + parent_type + '-' + parent_name  + '.html#' + href_text
        relative_path = ('../' * dir_levels) + api_path_segment
        api_doc_path = os.path.abspath(os.path.join(os.getcwd() + '/build/doc', api_path_segment))
        node = nodes.reference(text, utils.unescape(text), refuri=relative_path, **options)
        node = nodes.literal(text, '', node, **options)
    # Or just insert the basic property text
    else:
        messages.append(inliner.reporter.error(('Missing API doc for "%s".' % text), line=lineno))
        node = nodes.literal(text, utils.unescape(text))
        # Error occurred so record this in order to return the total number as a failure when exiting the program
        exit_with_failure += 1 
    return [node], messages

def get_root_element_name(text):
    check_cached_database()
    
    if text in treecache:
        return (treecache[text][1], treecache[text][0])
    return (None, None)

roles = {'hlm-t': 'target',
         'hlm-p': 'property',
         'hlm-m': 'macro',}


def setup(app):
    """ Register custom RST roles for linking Helium targets, properties and macros
    to the API documentation. """
    for role in roles.keys():
        app.add_role(role, handle_hlm_role)
    app.add_description_unit('property', 'ant-prop', 'pair: %s; property')
    app.add_description_unit('target', 'ant-target', 'pair: %s; target')

    
def check_for_failure():
    """ Check whether we need to exit the program with a failure due to one or more errors in a custom Sphinx operation. """
    if exit_with_failure:
        raise SystemExit("EXCEPTION: Found %d error(s) of type '(ERROR/3) Missing API doc for <property>'" % (exit_with_failure) )

# Register a cleanup routine to handle exit with failure
atexit.register(check_for_failure)

