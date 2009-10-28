#============================================================================ 
#Name        : test_gscm.py 
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

""" Test cases for gscm python wrapper.

"""

import logging
import sys
import unittest

import nokia.gscm


# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger('test.gscm')


class TestGSCM(unittest.TestCase):

    def test_get_db_path(self):
        """ Test the get_db_path function. """
        dbpath = nokia.gscm.get_db_path('fa1f5132')
        _logger.info("get_db_path('fa1f5132'): %s" % dbpath)
        assert dbpath == "/nokia/fa_nmp/groups/gscm/dbs/fa1f5132", "Wrong value returned!"
        
    def test_get_db_path2(self):
        """ Test the get_db_path function with unexistant database. """
        try:        
            _logger.info("get_db_path('not_valid_db'): %s" % nokia.gscm.get_db_path('not_valid_db'))
            assert False, "Should raise Exception when giving unexisting db.'"
        except Exception, exc:
            _logger.info(exc)

    def test_get_engine_host(self):
        """ Test the get_engine_host function. """
        engine = nokia.gscm.get_engine_host('fa1f5132')
        _logger.info("get_engine_host('fa1f5132'): %s" % engine)
        print engine
        assert engine == "facmsweh.europe.nokia.com" or "faccm" in engine, "Wrong value returned!"
        
    def test_get_engine_host2(self):
        """ Test the get_engine_host function with unexistant database. """
        try:        
            _logger.info("get_engine_host('not_valid_db'): %s" % nokia.gscm.get_engine_host('not_valid_db'))
            assert False, "Should raise Exception when giving unexisting db.'"
        except Exception, exc:
            _logger.info(exc)

    def test_get_router_address(self):
        """ Test the get_router_address function. """
        _logger.info("get_router_address('fa1f5132'): %s" % nokia.gscm.get_router_address('fa1f5132'))
        
    def test_get_router_address2(self):
        """ Test the get_router_address function with unexistant database. """
        try:        
            _logger.info("get_router_address('not_valid_db'): %s" % nokia.gscm.get_router_address('not_valid_db'))
            assert False, "Should raise Exception when giving unexisting db.'"
        except Exception, exc:
            _logger.info(exc)
