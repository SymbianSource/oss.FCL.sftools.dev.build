#============================================================================ 
#Name        : test_ccm_object.py 
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
    unitesting CCMObject functionality
"""

# pylint: disable-msg=R0201

import unittest
import ccm
import logging

# Uncomment this line to enable logging in this module, or configure logging elsewhere
logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger('test.ccm_objects')
#
#class CCMObjectTest(unittest.TestCase):
#    """ Module related to CCMObject (and related) function testing. """
#    
#    def setUp(self):
#        #vc1tltst
#        self.session = ccm.open_session(database = 'to1tobet')
#        if self.session is None:
#            _logger.error("Error creating connection.")
#            raise Exception("Couldn't open a session.")
#
#    def tearDown(self):
#        """ End of test: close opened synergy sessions. """
#        if self.session is not None:
#            self.session.close()
#            self.session = None
#        
#    def test_query(self):
#        """ Test simple synergy query that returns an object list. """
#        result = self.session.execute("query \"name='mc'and type='project' and status='released'\" /u /f \"%objectname\"", ccm.ObjectListResult(self.session))
#        for o in result.output:
#            assert o.type == 'project'
#            assert o['status'] == 'released'
#                    
#    def _test_checkout(self):
#        """ Test project checkout. """
#        project = self.session.create("mc-mc_4032_0728:project:vc1s60p1#1")
#        release = self.session.create("mc/next")
#        if not project.exists():
#           _logger.error("Project doesn't exists.")
#           return       
#        if not release.exists():           
#           _logger.error("Release doesn't exists.")
#           return
#           
#        coproject = project.checkout(release).project
#        assert coproject != None
#        assert coproject.name == project.name
#        assert coproject.type == project.type
#        assert coproject.instance == project.instance
#        try:
#            coproject2 = project.checkout(release, coproject.version).project
#            assert False, "Should fail as we are specifying an already existing version."
#        except Exception, e:
#            pass
#        
#

class MockResultSession(ccm.AbstractSession):
    """ Fake session used to test Result"""
    def __init__(self, behave = {}, database="fakedb"):
        ccm.AbstractSession.__init__(self, None, None, None, None)
        self._behave = behave
        self._database = database
    
    def database(self):
        """database """
        return self._database
    
    def execute(self, cmdline, result=None):
        """execute"""
        _logger.debug(cmdline)
        if result == None:
            result = ccm.Result(self)
        if self._behave.has_key(cmdline):
            result.status = 0  
            result.output = self._behave[cmdline]
        else:
            result.status = -1  
        return result

class CCMObjectTest(unittest.TestCase):
    """ Unit test case for CCMObject functionality """
    def test_get_baseline(self):
        """test get baseline"""
        behave = {'up -show baseline_project "foo-1.0:project:db#1" -f "%displayname" -u': """foo-1.0:project:db#1 does not have a baseline project.
""",
                  'up -show baseline_project "foo-2.0:project:db#1" -f "%displayname" -u': """foo-1.0:project:db#1
"""}
        session = MockResultSession(behave)
        objv1 = session.create('foo-1.0:project:db#1')
        assert objv1.baseline == None
        objv2 = session.create('foo-2.0:project:db#1')
        assert objv2.baseline == objv1


    def test_delete_project(self):
        """ Check project deletion """
        behave = {'delete  -project "project-1:project:db#1"': "Deleting object 'project-1:project:db#1'"}
        session = MockResultSession(behave)
        project = session.create('project-1:project:db#1')
        result = project.delete()        
        assert "Deleting object 'project-1:project:db#1'" in result.output

    def test_delete_project_scope(self):
        """ Check project deletion with custom scope """
        behave = {'delete  -scope "project_and_subproject_hierarchy" -project "project-1:project:db#1"': "Deleting object 'project-1:project:db#1'"}
        session = MockResultSession(behave)
        project = session.create('project-1:project:db#1')
        result = project.delete(scope='project_and_subproject_hierarchy')        
        assert "Deleting object 'project-1:project:db#1'" in result.output

    def test_delete_project_invalid_args(self):
        """ Check project synergy is failing in case of bad synergy parameters for delete """
        behave = {'delete  -project "project-1:project:db#1"': "Cannot use '-scope' option with '-r' option."}
        session = MockResultSession(behave)
        project = session.create('project-1:project:db#1')
        try:
            result = project.delete(recurse=True, scope='project_and_subproject_hierarchy')        
            assert False, "The delete method must fail in case of synergy failure"
        except:
            pass

    def test_delete_object(self):
        """ Check object deletion """
        behave = {'delete   "object-1:object:db#1"': "Deleting object 'object-1:object:db#1'"}
        session = MockResultSession(behave)
        obj = session.create('object-1:object:db#1')
        result = obj.delete()
        assert "Deleting object 'object-1:object:db#1'" in result.output

if __name__ == "__main__":
    unittest.main()
