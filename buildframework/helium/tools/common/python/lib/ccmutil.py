#============================================================================ 
#Name        : ccmutil.py 
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

""" utility module related to ccm """

import nokia.nokiaccm
import configuration
import ccm.extra

def get_session(database, username, password, engine, dbpath):
    """ Returns a user session """
    session = None
    if database != None:
        session = nokia.nokiaccm.open_session(username, password, database=database)
    else:
        session = nokia.nokiaccm.open_session(username, password, engine, dbpath)
    return session    

def get_ccm_cache(ccm_cache_xml):
    cache = None
    if ccm_cache_xml is not None:
        cache = str(ccm_cache_xml)
    return cache
    
def get_ccm_project(session, deliveryfile, waroot):
    """ Returns top level ccm project """
    configBuilder = configuration.NestedConfigurationBuilder(open(deliveryfile, 'r'))
    configSet = configBuilder.getConfiguration()
    for config in configSet.getConfigurations():
        waroot = config['dir']
        print "Found wa for project %s" % waroot
    return ccm.extra.get_toplevel_project(session, waroot)
    


    