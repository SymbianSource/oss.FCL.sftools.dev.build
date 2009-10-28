#============================================================================ 
#Name        : new_delivery.py 
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

""" Helper to convert delivery.xml and prep.xml to VirtualBuildArea
    configuration file.
"""
from  xml.dom.minidom import getDOMImplementation
import amara
import ccm
import re
import os.path
import sys
import configuration

def cleanup_path(path):
    """ Returns path without any sequence of '/' and replacing '\' by '/' """
    return re.sub(r'/+', '/', re.sub(r'\\', '/', path))

class config_wrapper:
    """ wrapper object to access directly conf property. """
    def __init__(self, config):
        self.project = config.name
        self.dir = config['dir']

def generate_config(deliveryinput, prepinput):
    """ deliveryinput: path to delivery conf file (old format).
        prepinput: path to the prep conf file.
        Return XML Document object.
    """
    impl = getDOMImplementation()
    doc = getDOMImplementation().createDocument(None, "virtualBuildArea", None)
    vba = doc.getElementsByTagName("virtualBuildArea")[0]

    # Loading delivery content
    configBuilder = configuration.NestedConfigurationBuilder(open(deliveryinput, 'r'))
    deliveryConfigs = configBuilder.getConfiguration().getConfigurations()

    # loading prep file
    prep = amara.parse(open(prepinput, 'r'))
    # analysing preparation creation
    for source in prep.xml_xpath('/prepSpec/source'):
        basedir = cleanup_path(source.basedir)
        for copy in source.xml_xpath('./copy'):            
            src = cleanup_path(copy.name)
            for config in deliveryConfigs:
                p = config_wrapper(config)
                ccmp = ccm.FourPartName(p.project)                
                p_dir = cleanup_path(p.dir)
                #print "ccmp: %s" % ccmp
                #print "pdir: %s" % p_dir
                # looking for project_name/project_name pattern, and if dest doesn't exist
                if (re.match(r"%s/%s" % (ccmp.name, ccmp.name), src, re.I) is not None) and not hasattr(copy, 'dest'):
                    print "All object from root."
                    add = doc.createElementNS("", "add")
                    add.setAttributeNS("", "project", str(ccmp))                    
                    vba.appendChild(add)
                    objs = doc.createElementNS("", "objects")
                    objs.setAttributeNS("", "from", ccmp.name)
                    add.appendChild(objs)
                # looking for project_name/project_name pattern, and if dest exists
                elif (re.match(r"%s/%s" % (ccmp.name, ccmp.name), src, re.I) is not None) and hasattr(copy, 'dest'):
                    if os.path.basename(copy.dest).lower() == ccmp.name.lower():                        
                        add = doc.createElementNS("", "add")
                        add.setAttributeNS("", "project", str(ccmp))
                        add.setAttributeNS("", "to", cleanup_path('/' + os.path.dirname(copy.dest)))
                        vba.appendChild(add)
                    else:                        
                        add = doc.createElementNS("", "add")
                        add.setAttributeNS("", "project", str(ccmp))
                        add.setAttributeNS("", "to", cleanup_path('/' + copy.dest))
                        vba.appendChild(add)
                # for directory copy
                elif cleanup_path(basedir + "/" + src) == p_dir:
                    print "Adding to subdirectory"
                    print ccmp.name, basedir + "/" + src, p_dir
                    add = doc.createElementNS("", "add")
                    add.setAttributeNS("", "project", str(ccmp))                
                    if hasattr(copy, 'dest'):
                        add.setAttributeNS("", "to", cleanup_path('/' + copy.dest + '/' + ccmp.name))
                    else:
                        add.setAttributeNS("", "to", cleanup_path('/'+ ccmp.name))
                    vba.appendChild(add)
                elif p_dir.startswith(cleanup_path(basedir + "/" + src + '/')):
                    print "Adding to subdirectory"
                    delta = p_dir[len(cleanup_path(basedir)):]
                    add = doc.createElementNS("", "add")                    
                    add.setAttributeNS("", "project", str(ccmp))
                    if hasattr(copy, 'dest'):
                        add.setAttributeNS("", "to", cleanup_path('/' + os.path.dirname(copy.dest) + '/' + delta + '/' + ccmp.name))
                    else:
                        add.setAttributeNS("", "to", cleanup_path(delta + '/' + ccmp.name))
                    vba.appendChild(add)                        
    return doc

