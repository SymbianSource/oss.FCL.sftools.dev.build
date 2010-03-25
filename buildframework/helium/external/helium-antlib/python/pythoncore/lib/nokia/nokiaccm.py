#============================================================================ 
#Name        : nokiaccm.py 
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

""" Nokia specific interface to Synergy sessions. """

import logging
import netrc
import os
import os.path
import sys
import fileutils

import ccm
import nokia.gscm


# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger("nokia.nokiaccm")


def open_session(username=None, password=None, engine=None, dbpath=None, database=None, reuse=True):
    """Provides a Session object.
    
    Attempts to return a Session, based either on existing Synergy
    sessions or by creating a new one.
    
    - If a .netrc file can be found on the user's personal drive,
      that will be read to obtain Synergy login information if it 
      is defined there. This will be used to fill in any missing 
      parameters not passed in the call to open_session().
      
      The format of the .netrc file entries should be:
      
      machine synergy login USERNAME password foobar account DATABASE_PATH@SERVER
      
      If the details refer to a specific database, the machine can be the database name,
      instead of "synergy".
    - If an existing session is running that matches the supplied
      parameters, it will reuse that.
    
    """    
    # See if a .netrc file can be used
    if password == None or username == None or engine == None or dbpath == None:
        if os.sep == '\\':
            os.environ['HOME'] = "H:" + os.sep
        _logger.debug('Opening .netrc file')
        try:
            netrc_file = netrc.netrc()
            netrc_info = None
            # If settings for a specific database 
            if database != None:
                netrc_info = netrc_file.authenticators(database)            

            # if not found just try generic one
            if netrc_info == None:
                netrc_info = netrc_file.authenticators('synergy')
                
            if netrc_info != None:
                (n_username, n_account, n_password) = netrc_info
                if username == None:
                    username = n_username
                if password == None:
                    password = n_password
                if n_account != None:
                    (n_dbpath, n_engine) = n_account.split('@')
                    if dbpath == None and n_dbpath is not None:
                        _logger.info('Database path set using .netrc (%s)' % n_dbpath)
                        dbpath = n_dbpath
                    if engine == None and n_engine is not None:
                        _logger.info('Database engine set using .netrc (%s)' % n_engine)
                        engine = n_engine
        except IOError:
            _logger.debug('Error accessing .netrc file')

    # using environment username in case username is not defined.
    if username == None:
        username = os.environ['USERNAME']

    # looking for dbpath using GSCM database
    if dbpath == None and database != None:
        _logger.info('Database path set using the GSCM database.')
        dbpath = nokia.gscm.get_db_path(database)        

    # looking for engine host using GSCM database
    if engine == None and database != None:
        _logger.info('Database engine set using the GSCM database.')
        engine = nokia.gscm.get_engine_host(database)
            
    
    _sessions = []
    # See if any currently running sessions can be used, only if no password submitted, else use a brand new session!
    if password == None and reuse:
        current_sessions = ccm.running_sessions()
        for current_session in current_sessions:
            if current_session.dbpath == dbpath:
                return current_session
    else:
        if ccm.CCM_BIN == None:
            raise ccm.CCMException("Could not find CM/Synergy executable in the path.")
        # Looking for router address using GSCM database
        router_address = None
        if database == None and dbpath != None:
            database = os.path.basename(dbpath)

        lock = fileutils.Lock(ccm.CCM_SESSION_LOCK)
        try:
            lock.lock(wait=True)
            # if we have the database name we can switch to the correct Synergy router
            if database != None:
                router_address = nokia.gscm.get_router_address(database)
                if os.sep == '\\' and router_address != None:
                    routerfile = open(os.path.join(os.path.dirname(ccm.CCM_BIN), "../etc/_router.adr"), 'r')
                    current_router = routerfile.read().strip()
                    routerfile.close()
                    if current_router != router_address.strip():
                        _logger.info('Updating %s' % (os.path.normpath(os.path.join(os.path.dirname(ccm.CCM_BIN), "../etc/_router.adr"))))
                        routerfile = open(os.path.join(os.path.dirname(ccm.CCM_BIN), "../etc/_router.adr"), "w+")
                        routerfile.write("%s\n" % router_address)
                        routerfile.close()
        
            # If no existing sessions were available, start a new one
            new_session = ccm.Session.start(username, password, engine, dbpath)
            lock.unlock()
            return new_session
        finally:
            lock.unlock()
    raise ccm.CCMException("Cannot open session for user '%s'" % username)



