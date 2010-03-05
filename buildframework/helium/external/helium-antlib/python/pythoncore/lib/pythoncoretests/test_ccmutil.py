#============================================================================ 
#Name        : test_ccmutil.py 
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

""" Unit test case for ccmutil.py """

import unittest
import ccmutil
import logging
import nokia.nokiaccm
import ccm
    
_logger = logging.getLogger('test.ccmutil')
logging.basicConfig(level=logging.INFO)

def open_session(username=None, password=None, engine=None, dbpath=None, database=None, reuse=True):
    return MockSession(None, username, password, engine, dbpath, database)

nokia.nokiaccm.open_session = open_session
    
class CcmUtilTest(unittest.TestCase):
    
    def test_get_session_with_database_set(self):
        """ Testing get_session method with database set"""
        session = None    
        database = 'testdb'
        username = 'username'
        password = 'password'
        engine = "ccm.engine.host"
        dbpath = "ccm.database.path"     
        try:
            session = ccmutil.get_session(database, username, password, engine, dbpath)
        except Exception, ex:
            print "Error creating session"
        assert session is None        
            
    def test_get_session_without_database_set(self):
        """ Testing get_session method without database set"""
        session = None    
        database = None
        username = 'username'
        password = 'password'
        engine = "ccm.engine.host"
        dbpath = "ccm.database.path"     
        try:
            session = ccmutil.get_session(database, username, password, engine, dbpath)
        except Exception, ex:
            print "Error creating session"            
        assert session is None        

    def test_get_session(self):
        """ Testing get_session method """
        session = ccmutil.get_session("fakedb", None, None, None, None)
        assert session is not None   
        
        
class MockSession(ccm.AbstractSession):
    """ Fake session used to test """
    def __init__(self, behave = {}, username=None, password=None, engine=None, dbpath=None, database=None):
        if database == "fakedb":
            self._behave = behave
            self._database = database
            self.dbpath = "/path/to/" + database
            self._session_addr = "LOCALHOST:127.0.0.1:1234"
        else:
            ccm.Session.start(username, password, engine, dbpath)
                
    def database(self):
        _logger.info("running database from MockResultSession")
        return self._database
    
    def execute(self, cmdline, result=None):
        if result == None:
            result = ccm.Result(self)        
        if self._behave.has_key(cmdline):
            result.statuserrors = 0  
            result.output = self._behave[cmdline]
        else:
            result.status = -1  
        return result


