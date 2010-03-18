#============================================================================ 
#Name        : test_session_provider.py 
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

""" Test cases for ccm python toolkit.

"""
import unittest
import sys
import ccm
import ccm.extra
import os
import logging
import tempfile

_logger = logging.getLogger('test.test_session_provider')
logging.basicConfig(level=logging.INFO)

class MockResultSession(ccm.AbstractSession):
    """ Fake session used to test Result"""
    def __init__(self, behave = {}, database="fakedb"):
        ccm.AbstractSession.__init__(self, None, None, None, None)
        self._behave = behave
        self._database = database
        self.dbpath = "/path/to/" + database
        self._session_addr = "LOCALHOST:127.0.0.1:1234"
    
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

class MockOpener(object):
    def __init__(self):
        self.failOnNewOpen = False
    
    def __call__(self, username=None, password=None, engine=None, dbpath=None, database=None, reuse=True):
        assert self.failOnNewOpen == False, "This method should not be called again."
        if database != "fakedb":
            raise ccm.CCMException("Invalid database")
        return MockResultSession()
    
class SessionProviderTest(unittest.TestCase):
    """ Testing Results parsers. """
    def test_get_valid_db(self):
        """ Test the opening of a valid database. """
        p = ccm.extra.SessionProvider(opener=MockOpener())
        db = p.get(database="fakedb")
        assert db is not None

    def test_get_invalid_db(self):
        """ Test the opening of an invalid database. """
        p = ccm.extra.SessionProvider(opener=MockOpener())
        try:            
            db = p.get(database="invaliddb")
            assert False, "Should raise Exception when giving unexisting db.'"
        except Exception, exc:
            _logger.info(exc)
        
        
        
class CachedSessionProviderTest(unittest.TestCase):
    """ Testing Results parsers. """
    session_cache = os.path.join(tempfile.mkdtemp(), 'session_cache.xml')
    
    def setUp(self):
        if not os.path.exists(os.path.dirname(self.session_cache)):
            os.makedirs(os.path.dirname(self.session_cache))
        if os.path.exists(self.session_cache):
            os.remove(self.session_cache)
    
    def tearDown(self):
        if os.path.exists(self.session_cache):
            os.remove(self.session_cache)
    
    def test_get_valid_db(self):
        """ Test the opening of a valid database (cached). """
        p = ccm.extra.CachedSessionProvider(opener=MockOpener())
        db = p.get(database="fakedb")
        assert db is not None

    def test_get_invalid_db(self):
        """ Test the opening of an invalid database (cached). """
        p = ccm.extra.CachedSessionProvider(opener=MockOpener())
        try:
            db = p.get(database="invaliddb")
            assert False, "Should raise Exception when giving unexisting db.'"
        except Exception, exc:
            _logger.info(exc)
        
    def test_open_session_twice(self):
        """ Open session then free it then open it again... """
        opener = MockOpener()
        p = ccm.extra.CachedSessionProvider(opener=opener)
        db = p.get(database="fakedb")
        assert db is not None
        db.close()
        opener.failOnNewOpen = True
        db2 = p.get(database="fakedb")
        assert db2 is not None
        
    def test_write_cache(self):
        p = ccm.extra.CachedSessionProvider(opener=MockOpener(), cache=self.session_cache)
        db = p.get(database="fakedb")
        assert db is not None
        del db
        p.save()
        assert os.path.exists(self.session_cache), "Cache file %s is missing." % self.session_cache
        
    def test_write_and_load_cache(self):
        
        # patching the default implementation
        def always_true(sid, db=None):
            return True
        ccm.session_exists = always_true
        
        p = ccm.extra.CachedSessionProvider(opener=MockOpener(), cache=self.session_cache)
        db = p.get(database="fakedb")
        assert db is not None
        del db
        p.close()
        assert os.path.exists(self.session_cache), "Cache file %s is missing." % self.session_cache
        
        opener = MockOpener()
        opener.failOnNewOpen = True
        p = ccm.extra.CachedSessionProvider(opener=opener, cache=self.session_cache)        
        assert 'fakedb' in p.cacheFree
        assert len(p.cacheFree['fakedb']) == 1
        
        
        