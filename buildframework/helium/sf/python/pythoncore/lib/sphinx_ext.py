#============================================================================ 
#Name        : sphinx_ext.py 
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
""" aids to creating the API documentation"""
import os
import re

from docutils import nodes, utils
from docutils.parsers.rst import directives

import amara

treecache = None

def handle_hlm_role(role, rawtext, text, lineno, inliner,
                       options=None, content=None):
    """ Process a custom Helium ReStructuredText role to link to a target, property or macro. """
    if options == None:
        options = {}
    if content == None:
        content = []
    full_path_match = re.search(r"<document source=\"(.*?)\"", str(inliner.document))
    full_path = full_path_match.group(1)
    path_segment = full_path[full_path.index('\\doc\\') + 5:]
    dir_levels = path_segment.count('\\')
    (parent_type, parent_name) = get_root_element_name(text)
    messages = []
#    f = open('docs.log', 'a')
    if parent_type != None and parent_name != None:
        href_text = text.replace('.', '-').lower()
#        f.write(href_text + "\n")
        api_path_segment = 'api/helium/' + parent_type + '-' + parent_name  + '.html#' + href_text
        relative_path = ('../' * dir_levels) + api_path_segment
        api_doc_path = os.path.abspath(os.path.join(os.getcwd() + '/build/doc', api_path_segment))
        node = nodes.reference(text, utils.unescape(text), refuri=relative_path, **options)
#        f.write(str(node) + "\n")
        node = nodes.literal(text, '', node, **options)
    else:
        messages.append(inliner.reporter.error(('Missing API doc for "%s".' % text), line=lineno))
        node = nodes.literal(text, utils.unescape(text))
#    f.close()
    return [node], messages

def get_root_element_name(text):
    global treecache
    if treecache == None:
        database_path = os.path.abspath(os.path.join(os.getcwd() + '/build', 'public_database.xml'))
        f = open(database_path)
        tree = amara.parse(f)
        
        treecache = {}
        for project in tree.antDatabase.project:
            for x in project.xml_children:
                if hasattr(x, 'name'):
                    treecache[str(x.name)] = str(project.name)
                    
    if text in treecache:
        return ('project', treecache[text])
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

    
    
    