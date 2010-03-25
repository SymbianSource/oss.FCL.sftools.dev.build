#============================================================================ 
#Name        : preparation.py 
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

""" This package implements the new update work area functionality.

"""

import logging
import os
import shutil
import time
import xml.dom.minidom

import ccm
import ccm.extra
import fileutils

# Uncomment this line to enable logging in this module, or configure logging elsewhere
logging.basicConfig(level=logging.INFO)
_logger = logging.getLogger("preparation.ccmgetinput")


DEFAULT_THREADS = 1
THREADS_MIN_TOTAL = 1
THREADS_MAX_TOTAL = 10


def find(function, seq):
    """Return first item in sequence where f(item) == True."""
    for item in seq:
        if function(item): 
            return item
    return None


class PreparationAction(object):
    """ Implements an abstract preparation function. """
    
    def __init__(self, config, builder):
        self._config = config
        self._builder = builder

    def check(self):
        """ Checks if project is available in synergy. """
        self._check_object(self._config.name)
        
    def _check_object(self, fpn):
        """ Check if ccmobject exists in synergy database. """
        session = self.get_session()
        ccm_object = session.create(fpn)
        if ccm_object.exists():
            _logger.info("Checking '%s'...Ok" % fpn)
        else:
            _logger.info("Checking '%s'...Not Found!" % fpn)
            raise Exception("Could not find  object %s in the database." % fpn)

    def execute(self):
        """ This method needs to be override by child class.
        
        It should implement the action to achieve.
        """
        pass

    def get_session(self):
        """ Helper that retreive the session from the builder. Setting threads correctly. """
        if self._config.has_key('database'):
            return self._builder.session(self._config['database'], self.get_threads())
        if not self._config.has_key('host'):
            raise Exception("Database engine host configuration is not found")
        elif not self._config.has_key('dbpath'):
            raise Exception("Database path configuration is not found")
        else:
            return self._builder.session(None, self.get_threads(), self._config['host'], self._config['dbpath'])

    def get_threads(self):
        """ Returning the number of threads that should be used. """
        threads = self._config.get_int('threads', DEFAULT_THREADS)
        if threads < THREADS_MIN_TOTAL:
            threads = THREADS_MIN_TOTAL
        if threads > THREADS_MAX_TOTAL:
            threads = THREADS_MAX_TOTAL
        return threads


class PreparationSnapshot(PreparationAction):
    """ Implements a Snapshot preparation function. 
    
    Support the parallel snapshotter.
    """
    
    def __init__(self, config, builder):
        """ Initialization. """
        PreparationAction.__init__(self, config, builder)

    def execute(self):
        """ Method that implements snapshoting of the project into a folder. """        
        _logger.info("=== Stage=snapshot = %s" % self._config.name)
        _logger.info("++ Started at %s" % time.strftime("%H:%M:%S", time.localtime()))
        session = self.get_session()
        project = session.create(self._config.name)

        target_dir = os.path.normpath(os.path.join(self._config['dir'], project.name))
        _logger.info("Looking for snapshot under %s." % target_dir)
        if not self._check_version(project, target_dir):
            if not os.path.exists(target_dir):
                _logger.info("Creating '%s'." % target_dir)
                os.makedirs(target_dir)
            else:
                _logger.info("Project needs to be updated, so deleting '%s'." % target_dir)
                fileutils.rmtree(target_dir)
            
            try:
                _logger.info("Snapshotting project.")                
                if self.get_threads() == 1:                    
                    _logger.info(project.snapshot(target_dir, True))
                else:
                    _logger.info(ccm.extra.FastSnapshot(project, target_dir, self.get_threads()))
                                    
                # writing version file                
                _logger.info("Saving project version information.")
                versionfile = open(os.path.join(self._config['dir'], project.name, 'project.version'), "w+")
                versionfile.write(str(project))
                versionfile.close()                
            except Exception, exc:
                if isinstance(exc, ccm.extra.CCMExtraException):
                    for sexc in exc.subexceptions:
                        _logger.info(sexc)
                _logger.info("ERROR: snapshotting %s" % self._config.name)
                _logger.info(exc)
                raise exc
        else:
            _logger.info("Project snapshot is still up to date. Nothing to do.")

        _logger.info("++ Finished at %s" % time.strftime("%H:%M:%S", time.localtime()))
    
    def _check_version(self, project, targetdir):
        """ Check the version file for snaphot and identify if the project has to be snapshot or not.
            Returns True if the content of the file matches the project to snapshot (nothing to do).
            Returns falls either if the file is missing, or the content is different.
        """
        versionfile = os.path.join(targetdir, 'project.version')
        if (os.path.exists(versionfile)):
            file_ = open(versionfile, "r")
            projectname = file_.read().strip()
            file_.close()
            if (projectname == project.objectname):
                return True
        return False
    
    
class PreparationCheckout(PreparationAction):
    """ Handle the checkout and update of project content. """
    def __init__(self, config, builder):
        """ Initialization. """
        PreparationAction.__init__(self, config, builder)
        self.__role = None

    def check(self):
        """ Checks if all synergy resources are available. """
        PreparationAction.check(self)
        if self._config.has_key('release'):
            self._check_object(str(self._config['release']))
        else:
            raise Exception("'release' property is not defined for %s" % self._config.name)

        for task in self.__get_tasks():
            self._check_object("Task %s" % task)
        for folder in self.__get_folders():
            self._check_object("Folder %s" % folder)
        
        for project in self.__get_subbaselines():
            self._check_object(project)
            
        # checking if the purpose exists
        if self._config.has_key('purpose'):
            session = self.get_session()
            purposes = session.purposes()
            if purposes.has_key(str(self._config['purpose'])):
                _logger.info("Checking purpose '%s'...Ok" % (self._config['purpose']))
            else:
                _logger.info("Checking purpose '%s'...Not Found!" % (self._config['purpose']))
                raise Exception("Could not find purpose %s in the database." % self._config['purpose'])
            
            role = session.role
            co_role = ccm.get_role_for_purpose(session, str(self._config['purpose']))
            _logger.info("Try to switch user to role: %s" % co_role)
            session.role = co_role
            session.role = role
            
    def execute(self):
        """ Creates a checkout of the project, or updates an existing checkout if one is found.
        
        The work area is maintained as part of this.
        """
        _logger.info("=== Stage=checkout = %s" % self._config.name)
        _logger.info("++ Started at %s" % time.strftime("%H:%M:%S", time.localtime()))
        session = self.get_session()
        project = session.create(self._config.name)
        
        session.home = self._config['dir']
        
        result = self.__find_project(project)
        # for testing: result = session.create("ppd_sw-fa1f5132#wbernard2:project:sa1spp#1")
        if (result != None):
            _logger.info("Project found: '%s'" % result)

            # setting up the project
            self.__setup_project(project, result)
        else:
            _logger.info("Checking out from '%s'." % project)
            
            purpose = None
            if self._config.has_key('purpose'):
                purpose = self._config['purpose']
                _logger.info("Using purpose: '%s'" % purpose)
                
            version = None
            if self._config.has_key('version'):
                version = self._config['version']
                _logger.info("Using version: '%s'" % version)

            try:
                self.__setRole(session)
                result = project.checkout(session.create(self._config['release']), version=version, purpose=purpose)
                ccm.log_result(result, ccm.CHECKOUT_LOG_RULES, _logger)
            except ccm.CCMException, exc:
                ccm.log_result(exc.result, ccm.CHECKOUT_LOG_RULES, _logger)
                raise exc
            finally:
                self.__restoreRole(session)
            _logger.info('Checkout complete')
            
            if result.project != None and result.project.exists():                
                _logger.info("Project checked out: '%s'" % result.project)
                
                try:
                    self.__setRole(session)
                    _logger.info("Maintaining the workarea...")
                    if self.get_threads() == 1:
                        output = result.project.work_area(True, True, True, self._config['dir'], result.project.name)
                    else:
                        output = ccm.extra.FastMaintainWorkArea(result.project, self._config['dir'], result.project.name, self.get_threads())
                    ccm.log_result(output, ccm.CHECKOUT_LOG_RULES, _logger)
                finally:
                    self.__restoreRole(session)
                self.__setup_project(project, result.project)
            else:
                raise Exception("Error checking out '%s'" % project)

        _logger.info("++ Finished at %s" % time.strftime("%H:%M:%S", time.localtime()))

    def __find_project(self, project):
        """ Private method. """
        if (os.path.exists(os.path.join(self._config['dir'], project.name, "project.version"))):
            _logger.info("Snapshot to checkout deleting '%s'." % os.path.join(self._config['dir'], project.name))
            fileutils.rmtree(os.path.join(self._config['dir'], project.name))
            return None
        
        path = os.path.join(self._config['dir'], project.name, project.name)
        try:
            result = project.session.get_workarea_info(path)
            if(result == None):
                fileutils.rmtree(path)
                return result
            return result['project']
        except ccm.CCMException:
            # Delete the project dir if found
            if os.path.exists(os.path.dirname(path)):
                fileutils.rmtree(os.path.dirname(path))
            return None

    def __setRole(self, session):
        """ Updating the role of a session. """
        self.__role = session.role
        if self._config.has_key('purpose'):
            co_role = ccm.get_role_for_purpose(session, self._config['purpose'])
            _logger.info("Switching user to role: %s" % co_role)
            session.role = co_role
            _logger.info("Switched user to role: %s" % session._get_role())

    
    def __restoreRole(self, session):
        """ Restoring to default user role. """
        if self.__role:
            _logger.info("Switching user to role: %s" % self.__role)

            session.role = self.__role
            self.__role = None
            _logger.info("Switched user to role: %s" % session._get_role())

            
    def __setup_project(self, project, coproject):
        """ Private method. """
        session = self.get_session()
        self.__setRole(session)
        
        newprojs = []
        if not self._config.get_boolean('use.reconfigure.template', False):
            _logger.info("Validating release")
            self.__set_release(coproject)
            _logger.info("Setting update properties to manual")
            coproject.set_update_method('manual', True)
            _logger.info("Setting the baseline to '%s'" % project)
            coproject.set_baseline(project, True)
            self.__set_subbaselines(coproject)
            _logger.info("Cleaning up update properties")
            self._clean_update_properties(coproject)
            _logger.info("Setting update properties.")
            self._set_tasks_and_folders(coproject)
            _logger.info("Applying update properties.")
            coproject.apply_update_properties(baseline=False)
        else:
            _logger.info("Validating release")
            self.__set_release(coproject)
                        
        replace_subprojects = True
        if not self._config.get_boolean('replace.subprojects', True):
            _logger.info("NOT replacing subprojects")
            replace_subprojects = False
        update_keepgoing = True
        if self._config.get_boolean('update.failonerror', False):
            _logger.info("The build will fail with update errors")
            update_keepgoing = False
        _logger.info("Updating...")
        result = coproject.update(True, replace_subprojects, update_keepgoing, result=ccm.UpdateResultSimple(coproject.session))
        
        if self._config.get_boolean('fix.missing.baselines', False) and replace_subprojects:
            newprojs = self.__fix_baseline(coproject)
            if len(newprojs) > 0:
                result = coproject.update(True, replace_subprojects, update_keepgoing, result=ccm.UpdateResultSimple(coproject.session))
                ccm.log_result(result, ccm.UPDATE_LOG_RULES, _logger)
                _logger.info("Detected additional projects into baseline - Maintaining the whole toplevel project again...")
                coproject.work_area(True, True)
            else:
                ccm.log_result(result, ccm.UPDATE_LOG_RULES, _logger)
        else:
            ccm.log_result(result, ccm.UPDATE_LOG_RULES, _logger)

        # Running sync
        self._sync(coproject)

        # Running check conflicts
        self._check_conflicts(coproject)
        
        self.__restoreRole(session)

    def _sync(self, coproject):
        """ Run the sync if the 'sync' property is defined to true in the 
            configuration
        """
        if self._config.get_boolean('sync', False):
            _logger.info("Synchronizing...")
            result = coproject.sync(True, True)
            ccm.log_result(result, ccm.SYNC_LOG_RULES, _logger)


    def __set_release(self, project):
        """ Update the release of the project hierarchy if required. """
        release = project.session.create(self._config['release'])
        _logger.info("Current release: '%s'" % project.release)
        _logger.info("Configuration release: '%s'" % release)
        if project.release != release:
            _logger.info("Updating release on the project hierarchy.")
            for subp in [project] + project.subprojects:
                subp.release = release
        
    def __fix_baseline(self, coproject):
        """ Check for project in a different status, then check them out. """
        newprojs = []
        _logger.info("Looking for new projects in the check out.")
        status = coproject['status']
        for subproj in coproject.subprojects:
            if subproj['status'] == status:
                continue           
            _logger.info("New project detected in the checkout '%s'" % subproj.objectname)
            purpose = None
            if self._config.has_key('purpose'):
                purpose = self._config['purpose']
                _logger.info("Using purpose: '%s'" % purpose)
                
            version = None
            if self._config.has_key('version'):
                version = self._config['version']
                _logger.info("Using version: '%s'" % version)

            result = subproj.checkout(subproj.session.create(self._config['release']), version=version, purpose=purpose, subprojects=False)
            _logger.info('Checkout complete')
            if result.project != None and result.project.exists():
                newcop = result.project
                newprojs.append(newcop)
                
                _logger.info("Setting is_relative to true")                    
                if "is_relative" in newcop.keys():
                    newcop["is_relative"] = "TRUE"
                else:
                    newcop.create_attribute("is_relative", "boolean", "TRUE")
                
                if not self._config.get_boolean('use.reconfigure.template', False):
                    newcop.set_update_method('manual', False)
                    
                    _logger.info("Setting the baseline to '%s'" % subproj)
                    newcop.set_baseline(subproj, True)
                                            
                    _logger.info("Cleaning up update properties")
                    self._clean_update_properties(newcop)
                    
                    _logger.info("Setting update properties.")
                    self._set_tasks_and_folders(newcop)
        return newprojs        

    def _check_conflicts(self, coproject):
        """ Private method. """
        conflictsobjects = self._config.get_boolean('show.conflicts.objects', False)
        
        if self._config.get_boolean('show.conflicts', False) or conflictsobjects:
            result = coproject.conflicts(True, not conflictsobjects)
            ccm.log_result(result, ccm.CONFLICTS_LOG_RULES, _logger)
#        for project in result.keys():
#            for error in result[project]:
#                if 'object' in error:
#                    _logger.info("CONFLICTS: %s" % error['comment'])
#                else:
#                    _logger.info("CONFLICTS: %s" % error['comment'])
        
    @staticmethod
    def _clean_update_properties(project):
        """ Private method. """
        for task in project.tasks:
            project.remove_task(task)        
        for folder in project.folders:
            project.remove_folder(folder)

    @staticmethod
    def __find_subproject(subprojects, project):
        """ Private method. """
        for subproj in subprojects:
            if subproj.is_same_family(project):
                return subproj
        raise Exception("Error could not identify check out project for '%s'" % project)
    
    def __set_subbaselines(self, project):
        """ Private method. """
        if len(self.__get_subbaselines()) > 0:
            subprojects = project.subprojects
            for subbaseline in self.__get_subbaselines():
                subbaseline = project.session.create(subbaseline)
                subproj = self.__find_subproject(subprojects, subbaseline)
                _logger.info("Setting subproject '%s' baseline to '%s'" % (subproj, subbaseline))
                subproj.set_baseline(subbaseline, True)
    
    def __get_array(self, key):
        """ Private method. """
        result = []
        if (self._config.has_key(key)):
            if isinstance(self._config[key], type([])):                
                for value in self._config[key]:
                    value = value.strip()
                    if len(value) > 0:
                        result.append(value) 
            else:
                value = self._config[key].strip()
                if len(value) > 0:
                    result.append(value)
        return result

    def __get_subbaselines(self):
        """ Private method. """
        return self.__get_array('subbaselines')
    
    def __get_tasks(self):
        """ Private method. """
        return self.__get_array('tasks')

    def __get_folders(self):
        """ Private method. """
        return self.__get_array('folders')
    
    def _set_tasks_and_folders(self, project):
        """ Private method. """
        for task in self.__get_tasks():
            _logger.info("Adding task %s" % task)
            project.add_task(project.session.create("Task %s" % task))
        for folder in self.__get_folders():
            _logger.info("Adding folder %s" % folder)
            project.add_folder(project.session.create("Folder %s" % folder))

class PreparationUpdate(PreparationCheckout):
    """ Synergy project updater. """
    
    def __init__(self, config, builder):
        """ Initialization. """
        PreparationCheckout.__init__(self, config, builder)

    def check(self):
        """ Checks if all synergy resources are available. """
        PreparationAction.check(self)

        session = self.get_session()
        ccm_object = session.create(self._config.name)
        role = session.role
        co_role = ccm.get_role_for_status(session, ccm_object['status'])
        _logger.info("Try to switch user to role: %s" % co_role)
        session.role = co_role
        session.role = role

    def execute(self):
        """ Updating the mentioned project. """

        session = self.get_session()
        ccmproject = session.create(self._config.name)
        role = session.role

        status = ccmproject['status']
        co_role = ccm.get_role_for_status(session, status)
        session.role = co_role

        if not self._config.get_boolean('use.reconfigure.template', False):
            _logger.info("Setting update properties to manual")
            ccmproject.set_update_method('manual', True)
            _logger.info("Cleaning up update properties")
            self._clean_update_properties(ccmproject)
            _logger.info("Setting update properties.")
            self._set_tasks_and_folders(ccmproject)
            _logger.info("Applying update properties.")
            ccmproject.apply_update_properties(baseline=False)
        replace_subprojects = True
        if not self._config.get_boolean('replace.subprojects', True):
            _logger.info("NOT replacing subprojects")
            replace_subprojects = False
        update_keepgoing = True
        if self._config.get_boolean('update.failonerror', False):
            _logger.info("The build will fail with update errors")
            update_keepgoing = False

        _logger.info("Updating %s..." % ccmproject.objectname)
        result = ccmproject.update(True, replace_subprojects, update_keepgoing, result=ccm.UpdateResultSimple(ccmproject.session))
        ccm.log_result(result, ccm.UPDATE_LOG_RULES, _logger)
        
        self._sync(ccmproject)
        
        self._check_conflicts(ccmproject)
        
        session.role = role

class PreparationBuilder(object):
    """ Creates an updated work area from a configuration. """
    def __init__(self, configs, username = None, password = None, cache=None):
        """ Initialization. """
        self._configs = configs
        self._sessions = {}
        self._actions = []
        self.__username = username
        self.__password = password
        self.__provider = ccm.extra.CachedSessionProvider(cache=cache)
        for config in self._configs:
            if config.type == "snapshot":
                self._actions.append(PreparationSnapshot(config, self))
            elif config.type == "checkout":
                self._actions.append(PreparationCheckout(config, self))        
            elif config.type == "update":
                self._actions.append(PreparationUpdate(config, self))
        
    def check(self):
        """ Check that all dependencies are there. """
        for action in self._actions:
            action.check()
    
    def get_content(self):
        """ Run the each action. """
        for action in self._actions:
            action.execute()

    def session(self, database, size=1, engine=None, dbpath=None):
        """ Handles pool rather that sessions. """
        assert size > 0, "The pool must contains at least one session!"
        if self.__provider is None:
            raise Exception("The builder has been closed.") 
        if not self._sessions.has_key(database):
            _logger.info("Get a session for %s" % database)
            session = ccm.SessionPool(self.__username, self.__password, engine, dbpath, database, size, opener=self.__provider.get)
            self._sessions[database] = session
            # be developer by default
            session.role = "developer"
        session = self._sessions[database]
        if session.size < size:
            _logger.info("Resizing the pool for database %s to %d" % (database, size))
            session.size = size
            # be developer by default
            session.role = "developer"
        return session
    
    def close(self):
        """ This is the preparation cleanup method.
            It closes all opened sessions.
        """
        _logger.debug("Closing sessions...")
        dbs = self._sessions.keys()
        while len(dbs) > 0:
            session = self._sessions.pop(dbs.pop())
            session.close()
        if self.__provider is not None:
            self.__provider.close()
            self.__provider = None
        
    
    def __del__(self):
        self.close()
            
        

