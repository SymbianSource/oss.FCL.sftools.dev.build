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
        """database"""
        _logger.info("running database from MockResultSession")
        return self._database
    
    def execute(self, cmdline, result=None):
        """execute the class"""
        if result == None:
            result = ccm.Result(self)
        if self._behave.has_key(cmdline):
            result.statuserrors = 0  
            result.output = self._behave[cmdline]
        else:
            result.status = -1  
        return result

class MockOpener(object):
    """ An Opener which provides a mock session """
    def __init__(self):
        self.failOnNewOpen = False
    
# pylint: disable-msg=W0613
#need disable msg to prevent pylint warning as this is emulating the real method.
    def __call__(self, username=None, password=None, engine=None, dbpath=None, database=None, reuse=True):
        assert self.failOnNewOpen == False, "This method should not be called again."
        if database != "fakedb":
            raise ccm.CCMException("Invalid database")
        return MockResultSession()
# pylint: enable-msg=W0613

class SessionProviderTest(unittest.TestCase):
    """ Testing Results parsers. """
    def test_get_valid_db(self):
        """ Test the opening of a valid database. """
        prov = ccm.extra.SessionProvider(opener=MockOpener())
        dbase = prov.get(database="fakedb")
        assert dbase is not None

    def test_get_invalid_db(self):
        """ Test the opening of an invalid database. """
        prov = ccm.extra.SessionProvider(opener=MockOpener())
        try:
            dbase = prov.get(database="invaliddb")
            assert False, "Should raise Exception when giving unexisting dbase.'"
        except Exception, exc:
            _logger.info(exc)



class CachedSessionProviderTest(unittest.TestCase):
    """ Testing Results parsers. """
    session_cache = os.path.join(tempfile.mkdtemp(), 'session_cache.xml')
    
    def setUp(self):
        """called before any of the test methods are run"""
        if not os.path.exists(os.path.dirname(self.session_cache)):
            os.makedirs(os.path.dirname(self.session_cache))
        if os.path.exists(self.session_cache):
            os.remove(self.session_cache)
    
    def tearDown(self):
        """called after all the tests are run to tidy up """
        if os.path.exists(self.session_cache):
            os.remove(self.session_cache)
    
    def test_get_valid_db(self):
        """ Test the opening of a valid database (cached). """
        prov = ccm.extra.CachedSessionProvider(opener=MockOpener())
        dbase = prov.get(database="fakedb")
        assert dbase is not None

    def test_get_invalid_db(self):
        """ Test the opening of an invalid database (cached). """
        prov = ccm.extra.CachedSessionProvider(opener=MockOpener())
        try:
            dbase = prov.get(database="invaliddb")
            assert False, "Should raise Exception when giving unexisting dbase.'"
        except Exception, exc:
            _logger.info(exc)
        
    def test_open_session_twice(self):
        """ Open session then free it then open it again... """
        opener = MockOpener()
        prov = ccm.extra.CachedSessionProvider(opener=opener)
        dbase = prov.get(database="fakedb")
        assert dbase is not None
        dbase.close()
        opener.failOnNewOpen = True
        db2 = prov.get(database="fakedb")
        assert db2 is not None
        
    def test_write_cache(self):
        """write to the cache"""
        prov = ccm.extra.CachedSessionProvider(opener=MockOpener(), cache=self.session_cache)
        dbase = prov.get(database="fakedb")
        assert dbase is not None
        del dbase
        prov.save()
        assert os.path.exists(self.session_cache), "Cache file %s is missing." % self.session_cache
        
    def test_write_and_load_cache(self):
        """write to and load the cache"""
        # patching the default implementation
        def always_true(_, d_base=None):
            """always true return 1"""
            d_base = True       #done to prevent pylint warning
            return d_base
        ccm.session_exists = always_true
        
        prov = ccm.extra.CachedSessionProvider(opener=MockOpener(), cache=self.session_cache)
        dbase = prov.get(database="fakedb")
        assert dbase is not None
        del dbase
        prov.close()
        assert os.path.exists(self.session_cache), "Cache file %s is missing." % self.session_cache
        
        opener = MockOpener()
        opener.failOnNewOpen = True
        prov = ccm.extra.CachedSessionProvider(opener=opener, cache=self.session_cache)
        assert 'fakedb' in prov.cacheFree
        assert len(prov.cacheFree['fakedb']) == 1
