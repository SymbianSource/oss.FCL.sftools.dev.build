#============================================================================ 
#Name        : test_preparation.py
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
""" Testing preparation module """  

import tempfile
from shutil import rmtree
import os
import logging
import unittest
import sys
import preparation
import ccm
import ccm.extra

_logger = logging.getLogger('test.preparation')
logging.basicConfig(level=logging.INFO)
_disable_is_relative = False
_disable_sub_projects = False

def _get_role_for_status(session, status): 
    """ Emulate get_role_for_status method for unit testing """
    pass

def _get_role_for_purpose(session, purpose): 
    """ Emulate get_role_for_purpose method for unit testing """
    pass

def _sessionPool(username, password, engine, dbpath, database, size, opener):
    """ Emulate ccm.SessionPool method for unit testing """
    return _emulateSession()

def _fastSnapshot(project, target_dir, threads): 
    """ Emulate ccm.extra.FastSnapshot method for unit testing """
    "Snapshot Created"

def _updateResultSimple(session): 
    """ Emulate ccm.UpdateResultSimple method for unit testing """
    pass

def _fastMaintainWorkArea(project, dir, projectname, threads): 
    """ Emulate ccm.extra.FastMaintainWorkArea method for unit testing """
    pass

def _is_same_family(self, project): 
    """ Emulate project.is_same_family method for unit testing """
    pass

def _checkoutException( self, session, version, purpose ): 
    """ Emulate project.checkout method for unit testing """
    raise ccm.CCMException('unit testing')

def _checkoutNone( self, session, version, purpose ): 
    """ Emulate project.checkout method for unit testing """
    return _checkout(True) 

def _get_workarea_info_exception(self, path):
    """ Emulate session.get_workarea_info method for unit testing """
    raise ccm.CCMException('unit testing')


class PreparationTest(unittest.TestCase):
    """Verifying preparation module"""
    def setUp(self):

        self._sessionPool_safe = ccm.SessionPool 
        self._getRoleForStatus_safe = ccm.get_role_for_status 
        self._getRolesForPurpose_safe = ccm.get_role_for_purpose 
        self._extraFastSnapshot_safe = ccm.extra.FastSnapshot 
        self._updateResultSimple_safe = ccm.UpdateResultSimple 
        self._extra_FastMaintainWorkArea_safe = ccm.extra.FastMaintainWorkArea 

        ccm.SessionPool = _sessionPool
        ccm.get_role_for_status = _get_role_for_status
        ccm.get_role_for_purpose = _get_role_for_purpose
        ccm.extra.FastSnapshot = _fastSnapshot
        ccm.UpdateResultSimple = _updateResultSimple
        ccm.extra.FastMaintainWorkArea = _fastMaintainWorkArea
        """Setup a temporary project directory for unit testing"""
        self.dirname = os.path.join(tempfile.gettempdir(), 'pyUnitTestHeliumProject')
        self.filename = os.path.join(self.dirname, 'project.version')
        if os.path.exists(self.dirname): 
            rmtree(self.dirname)

    def tearDown(self):
        """Remove the temporary project directory after unit testing complete """
        ccm.SessionPool = self._sessionPool_safe 
        ccm.get_role_for_status = self._getRoleForStatus_safe 
        ccm.get_role_for_purpose = self._getRolesForPurpose_safe 
        ccm.extra.FastSnapshot = self._extraFastSnapshot_safe 
        ccm.UpdateResultSimple = self._updateResultSimple_safe 
        ccm.extra.FastMaintainWorkArea = self._extra_FastMaintainWorkArea_safe 
        if os.path.exists(self.dirname): 
            rmtree(self.dirname)

    def test_find_valid(self):
        """Verifying find (valid args) method"""
        seq = range(2) 
        assert preparation.find(dummyFunction, seq) is not None

    def test_find_invalid(self):
        """Verifying find (invalid args) method"""
        seq = range(2, 5) 
        assert preparation.find(dummyFunction, seq) is None

    def test_prep_builder_sshot_check_valid_1(self):
        """Verifying check (valid args - snapshot with database) method"""
        builder = preparation.PreparationBuilder([_config('snapshot')], None, None, None)
        assert builder.check() is None

    def test_prep_builder_sshot_check_valid_2(self):
        """Verifying check (valid args - snapshot with host + dbpath) method"""
        confObj = _config('snapshot')
        del confObj['database']
        confObj['host'] = None
        confObj['dbpath'] = None
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        assert builder.check() is None

    def test_prep_builder_sshot_check_expn_1(self):
        """Verifying check (snapshot - exception 1) method"""
        confObj = _config('snapshot')
        del confObj['database']
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        self.assertRaises(Exception, builder.check)

    def test_prep_builder_sshot_check_expn_2(self):
        """Verifying check (snapshot - exception 2) method"""
        confObj = _config('snapshot')
        del confObj['database']
        confObj['host'] = None
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        self.assertRaises(Exception, builder.check)

    def test_prep_builder_sshot_check_expn_3(self):
        """Verifying check (snapshot - exception 3) method"""
        builder = preparation.PreparationBuilder([_config('snapshot')], None, None, None)
        safe = _project.exists
        _project.exists = lambda self: False
        self.assertRaises(Exception, builder.check)
        _project.exists = safe

    def test_prep_builder_sshot_gtcnt_valid_1(self):
        """Verifying get_content (valid args - snapshot - 1) method"""
        builder = preparation.PreparationBuilder([_config('snapshot')], None, None, None)
        builder.get_content()
        versionFile = open(self.filename, 'r')
        content = versionFile.readlines()
        versionFile.close()
        assert len(content) >= 1
            
    def test_prep_builder_sshot_gtcnt_valid_2(self):
        """Verifying get_content (valid args - snapshot - 2) method"""
        confObj = _config('snapshot')
        confObj['threads'] = 2 
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        builder.get_content()
        versionFile = open(self.filename, 'r')
        content = versionFile.readlines()
        versionFile.close()
        assert len(content) >= 1

    def test_prep_builder_sshot_gtcnt_expn_1(self):
        """Verifying get_content (exception - snapshot - 1) method"""
        os.makedirs(self.dirname)
        builder = preparation.PreparationBuilder([_config('snapshot')], None, None, None)
        self.assertRaises(Exception, builder.get_content)

    def test_prep_builder_ckt_check_valid(self):
        """Verifying check (valid args - checkout) method"""
        confObj = _config('checkout')
        confObj['tasks'] = [ 'x', 'y' , 'z']
        confObj['folders'] =  'x'
        confObj['subbaselines'] = [ 'x', 'y' , 'z']
        confObj['purpose'] = "samplePurpose"
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        assert builder.check() is None

    def test_prep_builder_ckt_check_expn_1(self):
        """Verifying check (exception - checkout - 1) method"""
        confObj = _config('checkout')
        del confObj['release']
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        self.assertRaises(Exception, builder.check)

    def test_prep_builder_ckt_check_expn_2(self):
        """Verifying check (exception - checkout - 2) method"""
        confObj = _config('checkout')
        confObj['folders'] = [ 'x', 'y' , 'z']
        confObj['purpose'] = "PurposeThatDoesnotExist"
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        self.assertRaises(Exception, builder.check)

    def test_prep_builder_ckt_gtcnt_valid_1(self):
        """Verifying get_content (valid args - checkout - 1) method"""
        confObj = _config('checkout')
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        result = builder.get_content() 
        assert result is None

    def test_prep_builder_ckt_gtcnt_valid_2(self):
        """Verifying get_content (valid args - checkout - 2) method"""
        if not os.path.exists(self.dirname): 
            os.makedirs(self.dirname)
        versionFile = open(self.filename , 'w+')
        versionFile.close()
        confObj = _config('checkout')
        confObj['purpose'] = "samplePurpose"
        confObj['version'] = "1"
        confObj['use.reconfigure.template'] = "true"
        confObj['threads'] = 2 
        global _disable_is_relative
        _disable_is_relative = True
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        result = builder.get_content() 
        _disable_is_relative = False
        assert result is None

    def test_prep_builder_ckt_gtcnt_valid_3(self):
        """Verifying get_content (valid args - checkout - 3) method"""
        if not os.path.exists(self.dirname): 
            os.makedirs(self.dirname)
        versionFile = open(self.filename , 'w+')
        versionFile.close()
        confObj = _config('checkout')
        confObj['purpose'] = "samplePurpose"
        confObj['version'] = "1"
        confObj['use.reconfigure.template'] = "true"
        confObj['fix.missing.baselines'] = "true"
        confObj['threads'] = 2 
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        global _disable_sub_projects 
        _disable_sub_projects = True
        result = builder.get_content() 
        _disable_sub_projects = False
        assert result is None

    def test_prep_builder_ckt_gtcnt_valid_4(self):
        """Verifying get_content (valid args - checkout - 4) method"""
        if not os.path.exists(self.dirname): 
            os.makedirs(self.dirname)
        versionFile = open(self.filename , 'w+')
        versionFile.close()
        confObj = _config('checkout')
        confObj['purpose'] = "samplePurpose"
        confObj['version'] = "1"
        confObj['sync'] = "true"
        confObj['replace.subprojects'] = "true"
        confObj['update.failonerror'] = "true"
        confObj['fix.missing.baselines'] = "true"
        confObj['show.conflict.objects'] = "true"
        confObj['show.conflicts'] = "true"
        confObj['subbaselines'] = [ 'x', 'y' , 'z']
        confObj['tasks'] = [ 'x', 'y' , 'z']
        confObj['folders'] = [ 'x', 'y' , 'z']
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        result = builder.get_content() 
        assert result is None


    def test_prep_builder_ckt_gtcnt_expn_1(self):
        """Verifying get_content (exception - checkout - 1) method"""
        if not os.path.exists(self.dirname): 
            os.makedirs(self.dirname)
        versionFile = open(self.filename , 'w+')
        versionFile.close()
        confObj = _config('checkout')
        confObj['purpose'] = "samplePurpose"
        confObj['version'] = "1"
        confObj['use.reconfigure.template'] = "true"
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        safe = _project.checkout 
        _project.checkout = _checkoutException
        self.assertRaises(ccm.CCMException, builder.get_content)
        _project.checkout  = safe

    def test_prep_builder_ckt_gtcnt_expn_2(self):
        """Verifying get_content (exception - checkout - 2) method"""
        if not os.path.exists(self.dirname): 
            os.makedirs(self.dirname)
        versionFile = open(self.filename , 'w+')
        versionFile.close()
        confObj = _config('checkout')
        confObj['purpose'] = "samplePurpose"
        confObj['version'] = "1"
        confObj['use.reconfigure.template'] = "true"
        safe = _project.checkout 
        _project.checkout = _checkoutNone
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        self.assertRaises(Exception, builder.get_content)
        _project.checkout  = safe

    def test_prep_builder_ckt_gtcnt_expn_3(self):
        """Verifying get_content (exception - checkout - 3) method"""
        if not os.path.exists(self.dirname): 
            os.makedirs(os.path.join(self.dirname, 'pyUnitTestHeliumProject'))
        confObj = _config('checkout')
        confObj['purpose'] = "samplePurpose"
        confObj['version'] = "1"
        confObj['use.reconfigure.template'] = "true"
        safe = _emulateSession.get_workarea_info 
        _emulateSession.get_workarea_info = _get_workarea_info_exception
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        result = builder.get_content() 
        _emulateSession.get_workarea_info  = safe
        assert result is None

    def test_prep_builder_ckt_gtcnt_expn_4(self):
        """Verifying get_content (expcetion - checkout - 4) method"""
        if not os.path.exists(self.dirname): 
            os.makedirs(self.dirname)
        versionFile = open(self.filename , 'w+')
        versionFile.close()
        confObj = _config('checkout')
        confObj['purpose'] = "samplePurpose"
        confObj['version'] = "1"
        confObj['sync'] = "true"
        confObj['fix.missing.baselines'] = "true"
        confObj['show.conflict.objects'] = "true"
        confObj['show.conflicts'] = "true"
        confObj['subbaselines'] = [ 'x', 'y' , 'z']
        safe = _subProject.is_same_family  
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        _subProject.is_same_family = _is_same_family
        self.assertRaises(Exception, builder.get_content)
        _subProject.is_same_family = safe

    def test_prep_builder_update_gtcnt_valid(self):
        """Verifying get_content (valid args - update) method"""
        confObj = _config('update')
        confObj['replace.subprojects'] = 'False'
        confObj['update.failonerror'] = 'true'
        builder = preparation.PreparationBuilder([confObj], None, None, None)
        result = builder.get_content()
        assert result is None

    def test_prep_action_execute(self):
        """Verifying execute method"""
        assert preparation.PreparationAction(None, None).execute() is None

def dummyFunction(item):
    """Emulating a callback method"""
    if item in range(2):
        return True
    return None

class _config():
    """Emulating configuration class"""
    def __init__(self, type):
        self.database = 'test'
        self.type = type
        self.name = 'test'
        self.data = {'database': 'test'}
        self.data['dir'] = tempfile.gettempdir()
        self.data['release'] = None
        self.threads = 1

    def get_int(self, key, default_value):
        """ Get a value as an int. """
        try:
            value = self.__getitem__(key)
            return int(value)
        except KeyError:
            return default_value
        
    def get_boolean(self, key, default_value):
        """ Get a value as a boolean. """
        try:
            value = self.__getitem__(key)
            return value == "true" or value == "yes" or value == "1" 
        except KeyError:
            return default_value

    def has_key(self, key):
        """ Check if key exists. """
        return self.data.has_key(key)

    def __getitem__(self, key):
        """ Get an item from the configuration via dictionary interface. """
        return self.data[key]                

    def __setitem__(self, key, value):
        """ Set an item from the configuration via dictionary interface. """
        self.data[key] = value               

    def __delitem__(self, key):
        """ Remove an item from the configuration via dictionary interface. """
        del self.data[key]                


class _emulateSession():
    """Emulating session class"""
    def __init__(self):
        self.size = 1
        self.role = 'developer'
        self.data = {'samplePurpose': None }

    def __getitem__(self, key):
        """ Get an item from the configuration via dictionary interface. """
        return self.data[key]                

    def __setitem__(self, key, value):
        """ Set an item from the configuration via dictionary interface. """
        self.data[key] = value               

    def __delitem__(self, key):
        """ Remove an item from the configuration via dictionary interface. """
        del self.data[key]                

    def _get_role(self):
        """Emulating session._get_role method"""
        pass

    def has_key(self, key):
        """ Check if key exists. """
        return self.data.has_key(key)

    def create(self, fpn):
        """Emulating session.create method"""
        return _project()

    def purposes(self):
        """Emulating session.purposes method"""
        return self

    def get_workarea_info(self, path):   
        """Emulating session.get_workarea_info method"""
        return _getWorkAreaInfo()

class _getWorkAreaInfo():
    """Emulating work area info """
    def __init__(self):
        self.data = {'project': _project()}

    def __getitem__(self, key):
        """ Get an item from the configuration via dictionary interface. """
        return self.data[key]    

class _project():
    """Emulating project class"""
    def __init__(self):
        global _disable_sub_projects
        global _disable_is_relative
        self.name = 'pyUnitTestHeliumProject'
        self.objectname = '1'
        self.data = {'status':None} 
        self.data['project'] =  _subProject()
        if _disable_is_relative:
            self.data['is_relative'] =  None
        self.data['release'] =  None
        self.release = None
        self.subprojects = []
        if not _disable_sub_projects:
            self.subprojects.extend([ _subProject(), _subProject()])
        self.session = _emulateSession()
        self.tasks =  [ 'x' , 'y', 'z' ]
        self.folders = [ 'x' , 'y', 'z' ]

    def __getitem__(self, key):
        """ Get an item from the configuration via dictionary interface. """
        return self.data[key]    

    def __setitem__(self, key, value):
        """ Set an item from the configuration via dictionary interface. """
        self.data[key] = value               

    def keys(self):
        """ Get the list of item keys. """
        return self.data.keys()

    def exists(self):
        """Emulating project.exists method"""
        return True                

    def snapshot(self, target_dir, status):
        """Emulating project.snapshot method"""
        print "Snapshot created"

    def update(self, status, replace_subprojects, update_keepgoing, result): 
        """Emulating project.update method"""
        pass

    def work_area(self, boolean1, boolean2, boolean3 = None, dir=None, projectname=None ):
        """Emulating project.work_area method"""
        pass

    def conflict(self, boolean, conflictsobjects):
        """Emulating project.conflict method"""
        pass

    def checkout(self, session, version, purpose):
        """Emulating project.checkout method"""
        return  _checkout()

    def set_update_method(self, mode, boolean):
        """Emulating project.set_update_method method"""
        pass

    def set_baseline(self, project, boolean):
        """Emulating project.set_baseline method"""
        pass

    def remove_task(self, task):
        """Emulating project.remove_task method"""
        pass

    def remove_folder(self, folder):
        """Emulating project.remove_folder method"""
        pass

    def apply_update_properties(self, baseline): 
        """Emulating project.apply_update_properties method"""
        pass

    def create_attribute(self, is_relative, boolean1, boolean2):
        """Emulating project.create_attribute method"""
        pass

    def sync(self, boolean1, boolean2):
        """Emulating project.sync method"""
        pass

    def conflicts(self, boolean1, boolean2):
        """Emulating project.conflicts method"""
        pass

    def add_task(self, project):
        """Emulating project.add_task method"""
        pass

    def add_folder(self, project):
        """Emulating project.add_folder method"""
        pass

class _checkout():
    """Emulating checkout project """
    def __init__(self, noProject=None):
        if noProject:
            self.project = None
        else:
            self.project = _project()

class _subProject():
    """Emulating sub project """
    def __init__(self):
        self.name = 'pyUnitTestHeliumProject'
        self.objectname = '1'
        self.data = {'status':'test'} 
        self.session = _emulateSession()

    def __getitem__(self, key):
        """ Get an item from the configuration via dictionary interface. """
        return self.data[key]    

    def keys(self):
        """ Get the list of item keys. """
        return self.data.keys()

    def exists(self):
        """Emulating sub project.exists """
        return True                

    def checkout(self, session, version, purpose, subprojects=None):
        """Emulating sub project.checkout """
        return  _checkout()

    def is_same_family(self, project):
        """Emulating sub project.is_same_family """
        return True

    def set_baseline(self, subbaseline, boolean1):
        """Emulating sub project.set_baseline """
        pass
