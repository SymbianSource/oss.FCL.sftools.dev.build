#============================================================================ 
#Name        : __init__.py 
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

""" CM/Synergy Python toolkit.

"""

import logging
import netrc
import os
import re
import subprocess
import sys
import threading

import fileutils
import nokia.gscm
import tempfile
import socket

# Uncomment this line to enable logging in this module, or configure logging elsewhere
_logger = logging.getLogger("ccm")
#logging.basicConfig(level=logging.DEBUG)


VALID_OBJECT_STATES = ('working', 'checkpoint', 'public', 'prep', 'integrate', 'sqa', 'test','released')
STATIC_OBJECT_STATES = ('integrate', 'sqa', 'test','released')
CCM_SESSION_LOCK = os.path.join(tempfile.gettempdir(), "ccm_session.lock")

def _execute(command, timeout=None):
    """ Runs a command and returns the result data. """
    targ = ""
    if timeout is not None:
        targ = "--timeout=%s" % timeout
    process = subprocess.Popen("python -m timeout_launcher %s -- %s" % (targ, command), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    stdout = process.communicate()[0]
    process.wait()
    _logger.debug(stdout)
    _logger.debug("Return code: %s" % process.returncode)
    return (stdout, process.returncode)
   
   
class CCMException(Exception):
    """ Base exception that should be raised by methods of this framework. """
    def __init__(self, reason, result = None):
        Exception.__init__(self, reason)
        self.result = result


class Result(object):
    """Class that abstracts ccm call result handling.
    
    Subclass it to implement a new generic output parser.
    """
    def __init__(self, session):
        self._session = session
        self.status = None
        self._output = None
        self._output_str = None
    
    def _setoutput(self, output):
        self._output = output
        
    def __setoutput(self, output):
        """ Internal function to allow overloading, you must override _setoutput.
        """
        # the output is automatically converted to ascii before any treatment 
        if isinstance(output, unicode):
            self._output_str = output.encode('ascii', 'replace')
        else:
            self._output_str = output.decode('ascii', 'ignore')
        _logger.debug("output ---->")
        for line in self._output_str.splitlines():
            _logger.debug(line)
        _logger.debug("<----")
        self._setoutput(self._output_str)
                
    def _getoutput(self):
        """ Returns the content of _output. """
        return self._output
        
    def __str__(self):
        """ Synergy output log. """
        return self._output_str.encode('ascii', 'replace')
        
    output = property(_getoutput, __setoutput)

class ResultWithError(Result):
	
    def __init__(self, session):
        Result.__init__(self, session)
        self._error = None
        self._error_str = None    

    def _seterror(self, error):
        self._error = error
        
    def __seterror(self, error):
        """ Internal function to allow overloading, you must override _seterror.
        """
        # the error output is automatically converted to ascii before any treatment 
        if isinstance(error, unicode):
            self._error_str = error.encode('ascii', 'replace')
        else:
            self._error_str = error.decode('ascii', 'ignore')
        _logger.debug("error ---->")
        for line in self._error_str.splitlines():
            _logger.debug(line)
        _logger.debug("<----")
        self._seterror(self._error_str)
                
    def _geterror(self):
        """ Returns the content of _output. """
        _logger.debug("_geterror")
        return self._error

    error = property(_geterror, __seterror)
    
class ProjectCheckoutResult(Result):
    """ Project checkout output parser. 
        Sets project to the created project or None if failed.
    """
    def __init__(self, session, project):
        Result.__init__(self, session)
        self.__project = project
        self.__result_project = None
    
    def _setoutput(self, output):
        """ Parsing the output of the checkout command. """
        self._output = output
        for line in output.splitlines():
            mresult = re.match(r"Saved work area options for project: '(.+)'", line, re.I)
            #(?P<name>.+)-(?P<version>.+?)(:(?P<type>\S+):(?P<instance>\S+))?
            if mresult != None:
                #self.__project.name + "-" + mo.groupdict()['version'] + ":" + self.__project.type + ":" + self.__project.instance
                self.__result_project = self._session.create(mresult.group(1))
                _logger.debug("ProjectCheckoutResult: project: '%s'" % self.__result_project)
                return

    def __get_result_project(self):
        """ return the checked out project. """
        return self.__result_project
    
    project = property(__get_result_project)


class ProjectPurposeResult(Result):
    """ Parses purpose query output. """
    def __init__(self, session):
        Result.__init__(self, session)

    def _setoutput(self, output):
        self._output = {}
        for line in output.splitlines():
            mresult = re.match(r"(?P<purpose>.+?)\s+(?P<member_status>\w+)\s+(?P<status>\w+)$", line)
            if mresult != None:
                data = mresult.groupdict()                
                if re.match(r'^\s+Purpose\s+Member$', data['purpose'], re.I) == None:
                    self._output[data['purpose'].strip()] = {'member_status' : data['member_status'].strip(),
                                                  'status' : data['status'].strip()
                                                  }

class ConflictsResult(Result):
    """ Parses purpose query output. """
    def __init__(self, session):
        Result.__init__(self, session)

    def _setoutput(self, output):
        self._output = {}
        project = None
                
        for line in output.splitlines():            
            mresult = re.match(r"Project:\s*(.+)\s*$", line)
            if mresult != None:
                project = self._session.create(mresult.group(1))
                self._output[project] = []
            mresult = re.match(r"^(.*)\s+(\w+#\d+)\s+(.+)$", line)
            if mresult != None and project != None:
                self._output[project].append({'object': self._session.create(mresult.group(1)),
                                              'task': self._session.create("Task %s" % mresult.group(2)),
                                              'comment': mresult.group(3)})
            mresult = re.match(r"^(\w+#\d+)\s+(.+)$", line)
            if mresult != None and project != None:
                self._output[project].append({'task': self._session.create("Task %s" % mresult.group(1)),
                                              'comment': mresult.group(2)})


class FinduseResult(Result):
    """ Parses finduse query output. """
    def __init__(self, ccm_object):
        Result.__init__(self, ccm_object.session)
        self.__object = ccm_object

    def _setoutput(self, output):
        self._output = []
        for line in output.splitlines():
            _logger.debug("FinduseResult: ---->%s<----" % line)
            _logger.debug("FinduseResult: ---->%s-%s<----" % (self.__object.name, self.__object.version))
            
            # MCNaviscroll\NaviAnim-username7@MCNaviscroll-username6            
            mresult = re.match(r"^\s*(?P<path>.+)[\\/]%s-%s@(?P<project>.+)" % (self.__object.name, self.__object.version), line, re.I)
            if mresult != None:
                data = mresult.groupdict()
                _logger.debug("FinduseResult: %s" % data)               
                project = self._session.create(data['project'])
                self._output.append({'path' : data['path'], 'project' : project})
        
        
class UpdateTemplateInformation(Result):
    """ Parse update template information output. """
    def __init__(self, session):
        Result.__init__(self, session)
    
    def _setoutput(self, output):
        """
Baseline Selection Mode: Latest Baseline Projects
Prep Allowed:            No
Versions Matching:       *abs.50*
Release Purposes:
Use by Default:          Yes
Modifiable in Database:  tr1s60
In Use For Release:      Yes
Folder Templates and Folders:
- Template assigned or completed tasks for %owner for release %release
- Template all completed tasks for release %release
- Folder   tr1s60#4844: All completed Xuikon/Xuikon_rel_X tasks
- Folder   tr1s60#4930: All tasks for release AppBaseDo_50        
        """
        self._output = {}
        for line in output.splitlines():
            rmo = re.match(r"^\s*(.+):\s*(.*)\s*", line)
            if rmo != None:
                if rmo.group(1) == "Baseline Selection Mode":
                    self._output['baseline_selection_mode'] = rmo.group(2) 
                elif rmo.group(1) == "Prep Allowed":
                    self._output['prep_allowed'] = (rmo.group(2) != "No") 
                elif rmo.group(1) == "Versions Matching":
                    self._output['version_matching'] = rmo.group(2) 
                elif rmo.group(1) == "Release Purposes":
                    self._output['release_purpose'] = rmo.group(2) 
                elif rmo.group(1) == "Use by Default":
                    self._output['default'] = (rmo.group(2) != "No") 
                elif rmo.group(1) == "Modifiable in Database":
                    self._output['modifiable_in_database'] = rmo.group(2).strip()
                elif rmo.group(1) == "In Use For Release":
                    self._output['in_use_for_release'] = (rmo.group(2) != "No") 
                

class UpdatePropertiesRefreshResult(Result):
    """ Parse update template refresh output. """
    def __init__(self, session):
        Result.__init__(self, session)

    def _setoutput(self, output):
        self._output = {'added': [], 'removed': []}
        match_added = re.compile(r"^Added the following tasks")
        match_removed = re.compile(r"^Removed the following tasks")
        match_task_new = re.compile(r"^\s+(Task \S+#\d+)")        
        section = None
                
        for line in output.splitlines():
            res = match_added.match(line)
            if res != None:
                section = 'added'
                continue
            res = match_removed.match(line)
            if res != None:
                section = 'removed'
                continue
            if section is not None:
                res = match_task_new.match(line)
                if res != None:
                    self._output[section].append(self._session.create(res.group(1)))
                    continue


class UpdateResultSimple(Result):
    """ Parse update output. """
    def __init__(self, session):
        Result.__init__(self, session)
        self._success = True

    def _setoutput(self, output):
        self._output = output
        match_failed = re.compile(r"(Update failed)")        
        for line in output.splitlines():
            res = match_failed.match(line)
            if res != None:                
                self._success = False
    
    @property
    def successful(self):
        return self._success
         
class UpdateResult(UpdateResultSimple):
    """ Parse update output. """
    def __init__(self, session):
        UpdateResultSimple.__init__(self, session)

    def _setoutput(self, output):
        self._output = {"tasks":[], "modifications": [], "errors": [], "warnings": []}
        match_object_update = re.compile(r"^\s+'(.*)'\s+replaces\s+'(.*)'\s+under\s+'(.*)'\.")
        match_object_new = re.compile(r"^\s+(?:Subproject\s+)?'(.*)'\s+is now bound under\s+'(.*)'\.")
        match_task_new = re.compile(r"^\s+(Task \S+#\d+)")
        match_no_candidate = re.compile(r"^\s+(.+) in project (.+) had no candidates")
        match_update_failure = re.compile(r"^\s+Failed to use selected object\s+(.+)\s+under directory\s+(.+)\s+in project\s+(.+)\s+:\s+(.+)")
        match_warning = re.compile(r"^Warning:(.*)")
        match_failed = re.compile(r"(Update failed)")
        
        # TODO: cleanup the parsing to do that in a more efficient way.
        for line in output.splitlines():
            _logger.info(line)
            res = match_object_update.match(line)
            if res != None:
                self._output['modifications'].append({ "new": self._session.create(res.group(1)),
                                      "old": self._session.create(res.group(2)),
                                      "project": self._session.create(res.group(3))
                                    })
                continue
            res = match_object_new.match(line)
            if res != None:                
                self._output['modifications'].append({ "new": self._session.create(res.group(1)),
                                      "old": None,
                                      "project": self._session.create(res.group(2))
                                    })
                continue
            res = match_task_new.match(line)
            if res != None:                
                self._output['tasks'].append(self._session.create(res.group(1)))
                continue
            res = match_no_candidate.match(line)
            if res != None:                
                self._output['errors'].append({'family': res.group(1),
                                               'project': self._session.create(res.group(2)),
                                               'comment': "had no candidates",
                                               'line': line,
                                               })
                continue
            res = match_update_failure.match(line)
            if res != None:                
                self._output['errors'].append({'family': res.group(1),
                                               'dir': self._session.create(res.group(2)),
                                               'project': self._session.create(res.group(3)),
                                               'comment': res.group(4),
                                               'line': line,
                                               })
                continue
            res = match_warning.match(line)            
            if res != None:                
                self._output['warnings'].append({'family': None,
                                               'project': None,
                                               'comment': res.group(1),
                                               'line': line,
                                               })
                continue
            res = match_failed.match(line)
            if res != None:
                self._success = False
                self._output['errors'].append({'Serious': res.group(1),
                                               })
                continue
                
            

class WorkAreaInfoResult(Result):
    """ Parse work area info output. """
    def __init__(self, session):
        Result.__init__(self, session)

    def _setoutput(self, output):
        """ Returns a dict with the following fields:
               * project: a ccm.Project instance
               * maintain: a boolean
               * copies: a boolean
               * relative: a boolean
               * time: a boolean
               * translate: a boolean
               * modify: a boolean
               * path: a string representing the project wa path
        """
        self._output = None
        for line in output.splitlines():
            mresult = re.match(r"(?P<project>.*)\s+(?P<maintain>TRUE|FALSE)\s+(?P<copies>TRUE|FALSE)\s+(?P<relative>TRUE|FALSE)\s+(?P<time>TRUE|FALSE)\s+(?P<translate>TRUE|FALSE)\s+(?P<modify>TRUE|FALSE)\s+'(?P<path>.*)'", line)            
            if mresult != None:
                data = mresult.groupdict()
                self._output = {'project': self._session.create(data['project']),
                                'maintain' : data['maintain'] == "TRUE",
                                'copies' : data['copies'] == "TRUE",
                                'relative' : data['relative'] == "TRUE",
                                'time' : data['time'] == "TRUE",
                                'translate' : data['translate'] == "TRUE",
                                'modify' : data['modify'] == "TRUE",
                                'path' : data['path']
                                }
                return


class CreateNewTaskResult(Result):
    
    def __init__(self, session):
        Result.__init__(self, session)

    def _setoutput(self, output):
        self._output = None
        for line in output.splitlines():
            mresult = re.match(r"Task\s+(?P<task>\S+\#\d+)\s+created\.", line)
            if mresult != None:
                self._output = self._session.create("Task " + mresult.groupdict()['task'])
                return
    
    
class AttributeNameListResult(Result):
    """ Class that abstract ccm call result handling.
        Subclass it to implement a new generic output parser.
    """
    def __init__(self, session):
        Result.__init__(self, session)
    
    def _setoutput(self, obj):
        def _create(arg):
            mresult = re.match(r"^\s*(?P<name>\w+)", arg.strip())
            if mresult != None:
                return mresult.groupdict()['name']
            return None
        self._output = [_create(line) for line in obj.strip().splitlines()]


class ObjectListResult(Result):
    """ Parses an object list Synergy output. """
    def __init__(self, session):
        Result.__init__(self, session)
    
    def _setoutput(self, obj):        
        self._output = []
        if re.match(r"^None|^No tasks|^Warning", obj, re.M) != None:
            return
        def _create(arg):
            arg = arg.strip()
            if arg != "":
                return self._session.create(arg)
            return None
        result = [_create(line) for line in obj.strip().splitlines()]
        for result_line in result:
            if result_line != None:
                self._output.append(result_line)

class DataMapperListResult(Result):
    """ Parses an object list Synergy output. """        
    
    dataconv = {'ccmobject': lambda x, y: x.create(y),
                'string': lambda x, y: y,
                'int': lambda x, y: int(y),
                'boolean': lambda x, y: (y.lower() == "true")}    
    
    def __init__(self, session, separator, keywords, datamodel):
        self._separator = separator
        self._keywords = keywords
        self._datamodel = datamodel
        Result.__init__(self, session)
    
    def format(self):
        formatted_keywords = ["%s%s%s%%%s" % (self._separator, x, self._separator, x) for x in self._keywords]
        return "".join(formatted_keywords) + self._separator
   
    def regex(self):
        regex_keywords = [r'%s%s%s(.*?)' % (self._separator, x, self._separator) for x in self._keywords]
        regex = r''.join(regex_keywords)
        regex = r"%s%s\s*\n" % (regex, self._separator)
        return re.compile(regex, re.MULTILINE | re.I | re.DOTALL | re.VERBOSE | re.U)
    
    def _setoutput(self, obj):
        self._output = []
        regex = self.regex()
        _logger.debug("Regex %s" % (regex.pattern))
        for match in regex.finditer(obj):
            _logger.debug("Found: %s" % (match))
            if match != None:
                output_line = {}
                for i in range(len(self._datamodel)):
                    _logger.debug("Found %d: %s" % (i, match.group(i + 1)))
                    model = self._datamodel[i]
                    output_line[self._keywords[i]] = self.dataconv[model](self._session, match.group(i + 1))
                    i += 1
                self._output.append(output_line)
                

class FolderCopyResult(Result):
    """ Parses a folder copy result """
    def __init__(self, session):
        Result.__init__(self, session)

    def _setoutput(self, output):
        self._output = None
        for line in output.splitlines():
            mo = re.match(r"appended to", line)
            if mo != None:
                self._output = self._session.create(line)
                return

CHECKOUT_LOG_RULES = [[r'^Derive failed for', logging.ERROR],
                      [r'^Serious:', logging.ERROR],
                      [r'^Warning: .* failed.', logging.ERROR],
                      [r'^Invalid work area', logging.ERROR],
                      [r'^WARNING:', logging.WARNING],
                      [r'^Warning:', logging.WARNING],]


UPDATE_LOG_RULES = [[r'^Update failed.', logging.ERROR],
                    [r'^Serious:', logging.ERROR],
                    [r'^\s+Failed to', logging.ERROR],
                    [r'^\d+ failures to', logging.ERROR],
                    [r"^Warning: This work area '.+' cannot be reused", logging.ERROR],
                    [r'^Rebind of .* failed', logging.ERROR],
                    [r'^Warning: .* failed.', logging.ERROR],
                    [r'^Skipping \'.*\'\.  You do not have permission to modify this project.', logging.ERROR],
                    [r'^Work area conflict exists for file', logging.ERROR],
                    [r'^Warning:  No candidates found for directory entry', logging.ERROR],
                    [r'^WARNING:', logging.WARNING],
                    [r'^Warning:', logging.WARNING],]

CONFLICTS_LOG_RULES = [[r'^\w+#\d+\s+Implicit', logging.WARNING],
                       [r'^(.*)\s+(\w+#\d+)\s+(.+)', logging.WARNING],
                       [r'.*Explicitly specified but not included', logging.WARNING],]

SYNC_LOG_RULES = [[r'^\s+0\s+Conflict\(s\) for project', logging.INFO],
                  [r'^\s+\d+\s+Conflict\(s\) for project', logging.ERROR],
                  [r'^Project \'.*\' does not maintain a workarea.', logging.ERROR],
                  [r'^Work area conflict exists for file', logging.ERROR],
                  [r'^Warning: Conflicts detected during synchronization. Check your logs.', logging.ERROR],
                  [r'^Warning:', logging.WARNING],]

def log_result(result, rules, logger=None):
    """ Rules it a list of tuple defining a regular expression and an log level. """
    if logger is None:
        logger = _logger
    crules = []
    if rules is not None:
        for rule in rules:
            crules.append([re.compile(rule[0]), rule[1]])
                
    for line in str(result).splitlines():
        for rule in crules:
            if rule[0].match(line) != None:
                logger.log(rule[1], line)
                break
        else:
            logger.info(line)
    
class AbstractSession(object):
    """An abstract Synergy session.

    Must be overridden to implement either a single session or
    multiple session handling.
    """
    def __init__(self, username, engine, dbpath, ccm_addr):
        self.username = username
        self.engine = engine
        self.dbpath = dbpath
        self._session_addr = ccm_addr
        # internal object list
        self.__ccm_objects = {}
    
    def addr(self):
        """ Returns the Synergy session id."""
        return self._session_addr
    
    def database(self):
        _logger.debug("AbstractSession: database")
        self.__find_dbpath()
        _logger.debug("AbstractSession: database: %s" % self.dbpath)
        return os.path.basename(self.dbpath)
    
    def __find_dbpath(self):
        """ retrieve the database path from current session status. """
        _logger.debug("AbstractSession: __find_dbpath")
        if (self.dbpath != None):            
            return
        result = self.execute("status")
        for match in re.finditer(r'(?:(?:Graphical)|(?:Command)) Interface\s+@\s+(?P<ccmaddr>\w+:\d+(?:\:\d+\.\d+\.\d+\.\d+)+)(?P<current_session>\s+\(current\s+session\))?\s*\nDatabase:\s*(?P<dbpath>\S+)', result.output, re.M | re.I):
            d = match.groupdict()
            if (d['current_session'] != None):
                _logger.debug("AbstractSession: __find_dbpath: Found dbpath: %s" % d['dbpath'])
                self.dbpath = d['dbpath']
        assert self.dbpath != None
    
    def execute(self, _, result=None):
        """ Abstract function that should implement the execution of ccm command
            line call.
        """
        return result

    def create(self, fpn):
        """ Object factory, this is the toolkit entry point to create objects from
            four part names. Objects are stored into a dictionary, so you have
            only one wrapper per synergy object.
        """
        result = re.search(r"^(?P<project>.+)-(?P<version>[^:]+?)$", fpn)
        if result != None:
            matches = result.groupdict()
            fpn = "%s-%s:project:%s#1" % (matches['project'], matches['version'], self.database())
        _logger.debug("session.create('%s')" % fpn)
        ofpn = FourPartName(fpn)
        if not self.__ccm_objects.has_key(str(fpn)):
            obj = None
            if ofpn.type == 'project':
                obj = Project(self, fpn)
            elif ofpn.type == 'dir':
                obj = Dir(self, fpn)
            elif ofpn.type == 'task':
                obj = Task(self, fpn)
            elif ofpn.type == 'folder':
                obj = Folder(self, fpn)
            elif ofpn.type == 'releasedef':
                obj = Releasedef(self, fpn)
            else:
                obj = File(self, fpn)
            self.__ccm_objects[str(fpn)] = obj
        return self.__ccm_objects[str(fpn)]

    def get_workarea_info(self, dir_):
        """ Return a dictionary containing workarea info from directory dir.
        """
        if (not os.path.exists(dir_)):
            raise CCMException("Error retrieving work_area info for the directory '%s' (doesn't exists)" % dir_)
        path = os.path.abspath(os.path.curdir)        
        path_ccmwaid = os.path.join(dir_,"_ccmwaid.inf");
        if(not os.path.exists(path_ccmwaid)):
            raise CCMException("No work area in '%s'" % dir_)
        os.chdir(dir_)
        result = self.execute("wa -show", WorkAreaInfoResult(self))
        os.chdir(path)
        if result.output == None:
            raise CCMException("Error retrieving work_area info for the directory '%s'" % dir_)
        return result.output

    def _get_role(self):
        result = self.execute("set role")
        return result.output.strip()
    
    def _set_role_internal(self, role):
        """ method to be override by child class else property accession is not working properly. """
        if  role == None or len(role) == 0:
            raise CCMException("You must provide a role.")
        result = self.execute("set role %s" % role)
        if re.match(r'^Warning:', result.output, re.M) != None:
            raise CCMException("Error switching to role %s: %s" %(role, result.output.strip()))

    def _set_role(self, role):
        self._set_role_internal(role)
        
    role = property(fget=_get_role, fset=_set_role)
    
    def _get_home(self):
        result = self.execute("set Home")
        return result.output.strip()
        
    def _set_home(self, home):
        if len(home) == 0 or home == None:
            raise CCMException("You must provide a home.")
        result = self.execute("set Home %s" % home)
        if re.match(r'^Warning:', result.output, re.M) != None:
            raise CCMException("Error switching to Home %s: %s" %(home, result.output.strip()))
    
    home = property(_get_home, _set_home)
    
    def close(self):
        pass
    
    def __str__(self):
        self.__find_dbpath()
        return self._session_addr + ':' + self.dbpath
        
    def __repr__(self):
        return self.__str__()
    
    def __del__(self):
        self.close()

    def purposes(self, role=None):
        """ Returns available purposes. """
        args = ""
        if role != None:
            args = "-role \"%s\"" % role
        result = self.execute("project_purpose -show %s" % args, ProjectPurposeResult(self))
        return result.output        

class Session(AbstractSession):
    """A Synergy session.
    """
    def __init__(self, username, engine, dbpath, ccm_addr, close_on_exit=True):
        AbstractSession.__init__(self, username, engine, dbpath, ccm_addr)
        self._execute_lock = threading.Lock()
        self.close_on_exit = close_on_exit

    @staticmethod
    def start(username, password, engine, dbpath, timeout=300):
        if username == None:
            raise CCMException('username is not valid')
        if password == None:
            raise CCMException('password is not valid')
        if CCM_BIN == None:
            raise CCMException("Could not find CM/Synergy executable in the path.")
        command = "%s start -m -q -nogui -n %s -pw %s -h %s -d %s" % \
                    (CCM_BIN, username, password, engine, dbpath)
        _logger.debug('Starting new session:' + command.replace(password, "***"))
        (result, status) = _execute(command, timeout=timeout)
        if status != 0:
            raise Exception("Error creating a session: result:\n%s\nCommand: %s" % (result, command.replace(password, "***")))
        session_addr = result.strip()
        _logger.debug(session_addr)
        if not re.match(r'[a-zA-Z0-9_-]+:\d+:\d+\.\d+\.\d+\.\d+(:\d+\.\d+\.\d+\.\d+)?', session_addr):
            raise Exception("Error creating a session: result:\n%s" % result)
        return Session(username, engine, dbpath, session_addr)        
            
    def execute(self, cmdline, result=None):
        """ Executes a Synergy CLI operation. """
        if self._session_addr == None:
            raise CCMException("No Synergy session running")        
        if CCM_BIN == None:
            raise CCMException("Could not find CM/Synergy executable in the path.")
        self._execute_lock.acquire()
        output = ""
        error = ""
        try:
            if result == None:
                result = Result(self)
            if os.sep == '\\':
                command = "set CCM_ADDR=" + self._session_addr + " && " + CCM_BIN + " %s" % cmdline
            else:
                command = "export CCM_ADDR=" + self._session_addr + " && " + CCM_BIN + " %s" % cmdline
            _logger.debug('Execute > ' + command)

            if hasattr(result, 'error'):
                process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                output = process.stdout.read()
                error = process.stderr.read()
                result.status = process.returncode
            else:
                process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                output = process.stdout.read()
                result.status = process.returncode
        finally:
            self._execute_lock.release()
        result.output = output.strip()
        if hasattr(result, 'error'):
            result.error = error.strip()
        return result

    def close(self):
        """ Closes this Synergy session if it was not previously running anyway. """
        _logger.debug("Closing session %s" % self._session_addr)
        if self._session_addr != None and self.close_on_exit:
            _logger.debug("Closing session %s" % self._session_addr)
            self._execute_lock.acquire()
            if os.sep == '\\':
                command = "set CCM_ADDR=" + self._session_addr + " && " + CCM_BIN + " stop"
            else:
                command = "export CCM_ADDR=" + self._session_addr + " && " + CCM_BIN + " stop"
            _logger.debug('Execute > ' + command)
            pipe = os.popen(command)
            pipe.close()
            self._session_addr = None
            self._execute_lock.release()
        elif self._session_addr != None and not self.close_on_exit:
            _logger.debug("Keeping session %s alive." % self._session_addr)


class SessionPool(AbstractSession):
    """ Session that transparently handled several subsession, to easily enable
        multithreaded application.
    """
    def __init__(self, username, password, engine, dbpath, database=None, size=4, opener=None):
        AbstractSession.__init__(self, username, engine, dbpath, None)
        self._opener = opener
        if self._opener is None:
            self._opener = open_session
        self._free_sessions = []
        self._used_sessions = []
        self._thread_sessions = {}
        self._pool_lock = threading.Condition()
        self._lock_pool = False
        self.__password = password
        self.__database = database        
        self.size = size
    
    def _set_size(self, size):
        """ Set the pool size """ 
        self._pool_lock.acquire()
        poolsize = len(self._free_sessions) + len(self._used_sessions)
        if  poolsize > size:
            to_be_remove = poolsize - size
            self._lock_pool = True
            while len(self._free_sessions) < to_be_remove:
                self._pool_lock.wait()            
            for _ in range(to_be_remove):
                self._free_sessions.pop().close()
            self._lock_pool = False
        else: 
            for _ in range(size - poolsize):
                self._free_sessions.append(self._opener(self.username, self.__password, self.engine, self.dbpath, self.__database, False))
        self._pool_lock.release()

    def _get_size(self):
        self._pool_lock.acquire()
        poolsize = len(self._free_sessions) + len(self._used_sessions)
        self._pool_lock.release()
        return poolsize

    size = property (_get_size, _set_size)
    
    def execute(self, cmdline, result=None):
        """ Executing a ccm command on a free session. """        
        _logger.debug("SessionPool:execute: %s %s" % (cmdline, type(result)))
        
        # waiting for a free session
        self._pool_lock.acquire()        
        
        # check for recursion, in that case reallocate the same session,
        if threading.currentThread() in self._thread_sessions:
            _logger.debug("Same thread, reusing allocation session.")
            # release the pool and reuse associated session
            self._pool_lock.release()
            return self._thread_sessions[threading.currentThread()].execute(cmdline, result)

        while len(self._free_sessions)==0 or self._lock_pool:
            self._pool_lock.wait()
        session = self._free_sessions.pop(0)
        self._used_sessions.append(session)
        self._thread_sessions[threading.currentThread()] = session
        self._pool_lock.release()
        
        # running command
        try:
            result = session.execute(cmdline, result)
        finally:
            # we can now release the session - anyway
            self._pool_lock.acquire()
            self._thread_sessions.pop(threading.currentThread())                
            self._used_sessions.remove(session)
            self._free_sessions.append(session)
            self._pool_lock.notifyAll()
            self._pool_lock.release()
        return result

    def close(self):
        """ Closing all subsessions. """
        _logger.debug("Closing session pool sub-sessions")
        self._lock_pool = True
        self._pool_lock.acquire()
        while len(self._used_sessions) > 0:
            _logger.debug("Waiting to free used sessions.")
            _logger.debug("Waiting to free used sessions. %s %s" % (len(self._used_sessions), len(self._free_sessions)))            
            _logger.debug(self._used_sessions)
            _logger.debug(self._free_sessions)            
            self._pool_lock.wait()
        _logger.debug("Closing all free session from the pool.")
        while len(self._free_sessions) > 0:
            self._free_sessions.pop().close()
        self._lock_pool = False
        self._pool_lock.notifyAll()
        self._pool_lock.release()
    
    def _set_role_internal(self, role):
        """ Set role on all subsessions. """
        self._lock_pool = True
        self._pool_lock.acquire()
        while len(self._used_sessions)!=0:
            self._pool_lock.wait()
            
        try:
            for session in self._free_sessions:
                session.role = session._set_role(role)
        finally:                
            self._lock_pool = False
            self._pool_lock.notifyAll()
            self._pool_lock.release()


class Query(object):
    """ This object wrap a synergy query, it takes a query as input as well as the
    attribute you want as output, and get them translated using the model configuration.
    e.g 
    Query(session, "type='task' and release='test/next'", ['objectname', 'task_synopsis'], ['ccmobject', 'string'])
    
    This will return a list of hash: [{'objectname': Task(xxx), 'task_synopsis': 'xxx'}, ...]
    """
    
    def __init__(self, session, query, keywords, model, cmd="query"):
        """ Initialize a Synergy query."""
        self._session = session
        self._query = query
        self._keywords = keywords
        self._model = model
        self._cmd = cmd
        
    def execute(self):
        """ Executing the query on the database. """
        mapper = DataMapperListResult(self._session, '@@@', self._keywords, self._model)        
        query = "%s %s -u -f \"%s\"" % (self._cmd, self._query, mapper.format())
        return self._session.execute(query, mapper)
        
    

class InvalidFourPartNameException(CCMException):
    """ Badly formed Synergy four-part name. """
    def __init__(self, fpn = ""):
        CCMException.__init__(self, fpn)


class FourPartName(object):
    """ This class handle four part name parsing and validation.
    """

    def __init__(self, ifpn):
        """ Create a FourPartName object based on a ifpn string.
        
        The string have to match the following patterns:
        - name-version:type:instance
        - name:version:releasedef:instance
        - Task database#id
        - Folder database#id
        
        Anything else is considered as old release string format.
            
        """
        _logger.debug("FourPartName: '%s'", ifpn)
        fpn = FourPartName.convert(ifpn)
        result = re.search(r"^(?P<name>.+)-(?P<version>.+?):(?P<type>\S+):(?P<instance>\S+)$", fpn)
        if result == None:
            result = re.search(r"^(?P<name>.+):(?P<version>.+?):(?P<type>releasedef):(?P<instance>\S+)$", fpn)            
            if result == None:
                raise InvalidFourPartNameException(fpn)
        # set all attributes
        self._name = result.groupdict()['name']
        self._version = result.groupdict()['version']
        self._type = result.groupdict()['type']
        self._instance = result.groupdict()['instance']    

    def __getname(self):
        """ Returns the name of the object. """
        return self._name
    
    def __getversion(self):
        """ Returns the version of the object. """
        return self._version
    
    def __gettype(self):
        """ Returns the type of the object. """
        return self._type
    
    def __getinstance(self):
        """ Returns the instance of the object. """
        return self._instance
    
    def __getobjectname(self):
        """ Returns the objectname of the object. """
        if (self.type == 'releasedef'):
            return "%s:%s:%s:%s" % (self.name, self.version, self.type, self.instance)
        return "%s-%s:%s:%s" % (self.name, self.version, self.type, self.instance)
    
    def __str__(self):
        """ Returns the string representation of the object. """
        return self.objectname
    
    def __repr__(self):
        """ Returns the string representation of the python object. """
        if (self.type == 'releasedef'):
            return "<%s:%s:%s:%s>" % (self.name, self.version, self.type, self.instance)
        return "<%s-%s:%s:%s>" % (self.name, self.version, self.type, self.instance)
    
    def is_same_family(self, ccmobject):
        """ Returns True if the ccmobject is part of the same family (=same name, type and instance) as self. """
        assert isinstance(ccmobject, FourPartName)
        return (self.name == ccmobject.name and self.type == ccmobject.type and self.instance == ccmobject.instance)
    
    def __getfamily(self):
        return "%s:%s:%s" % (self.name, self.type, self.instance)
    
    def __eq__(self, ccmobject):
        """ Returns True if object four parts name are identical. """
        if ccmobject == None:
            return False
        assert isinstance(ccmobject, FourPartName)
        return (self.name == ccmobject.name and self.version == ccmobject.version and self.type == ccmobject.type and self.instance == ccmobject.instance)
    
    def __ne__(self, ccmobject):
        """ Returns True if object four parts name are different. """
        if ccmobject == None:
            return True
        assert isinstance(ccmobject, FourPartName)
        return (self.name != ccmobject.name or self.version != ccmobject.version or self.type != ccmobject.type or self.instance != ccmobject.instance)
    
    @staticmethod
    def is_valid(fpn):
        """ Check if a given string represents a valid four part name.
        """        
        return (re.match(r"^(.+)-(.+?):(\S+):(\S+)|(.+):(.+?):releasedef:(\S+)$", fpn) != None)
    
    @staticmethod
    def convert(fpn):
        """ Update a CCM output string to a valid four part name. This is due to the inconsistent
             output of CM/Synergy CLI.
        """
        fpn = fpn.strip()
        if FourPartName.is_valid(fpn):
            return fpn
        result = re.search(r"^(?P<type>Task|Folder)\s+(?P<instance>\w+)#(?P<id>\d+)$", fpn)
        if result != None:
            matches = result.groupdict()
            if matches["type"] == "Task":
                return "task%s-1:task:%s" % (matches["id"], matches["instance"])
            elif matches["type"] == "Folder":
                return "%s-1:folder:%s" % (matches['id'], matches['instance'])
        else:
            result = re.search(r"^(?P<project>\S+)/(?P<version>\S+)$", fpn)
            if result != None:
                matches = result.groupdict()
                return "%s:%s:releasedef:1" % (matches['project'], matches['version'])        
            else:
                # Check the name doesn't contains any of the following character: " :-"
                result = re.search(r"^[^\s^:^-]+$", fpn)
                if result != None:
                    return "none:%s:releasedef:1" % (fpn)
        raise InvalidFourPartNameException(fpn)

    name = property (__getname)
    version = property (__getversion)
    type = property (__gettype)
    instance = property (__getinstance)
    objectname = property (__getobjectname)
    family = property(__getfamily)
                
                
class CCMObject(FourPartName):
    """ Base class for any Synergy object. """
               
    def __init__(self, session, fpn):
        FourPartName.__init__(self, fpn)
        self._session = session
    
    def _getsession(self):
        return self._session
    
    session = property(_getsession)
    
    def exists(self):
        """ Check if an the object exists in the database. """
        return (len(self._session.execute("query \"name='%s' and version='%s' and type='%s' and instance='%s'\" -u -f \"%%objectname\"" % (self.name, self.version, self.type, self.instance), ObjectListResult(self._session)).output) == 1)
    
    def __setitem__(self, name, value):
        project = ""
        if self.type == 'project':
            project = "-p"
        if value.endswith("\\"):
            value += "\\"
        result = self._session.execute("attribute -modify \"%s\" -v \"%s\" %s \"%s\"" % (name, value, project, self))
        if result.status != 0 and result.status != None:
            raise CCMException("Error modifying '%s' attribute. Result: '%s'" % (name, result.output), result)
        
    def __getitem__(self, name):
        """ Provides access to Synergy object attributes through the dictionary
        item interface.
        """
        result = self._session.execute("query \"name='%s' and version='%s' and type='%s' and instance='%s'\" -u -f \"%%%s\"" % (self.name, self.version, self.type, self.instance, name), ResultWithError(self._session))
        if result.status != 0 and result.status != None:
            raise CCMException("Error retrieving '%s' attribute. Result: '%s'" % (name, result.output), result)
        if len(result.error.strip()) > 0:
            raise CCMException("Error retrieving '%s' attribute. Reason: '%s'" % (name, result.error), result)
        if result.output.strip() == "<void>":
            return None
        return result.output.strip()
    
    def create_attribute(self, name, type_, value=None):
        if name in self.keys():
            raise CCMException("Attribute '%s' already exist." % (name))
        args = ""
        proj_arg = ""
        if value != None:
            args += " -value \"%s\"" % value
        if self.type == "project":
            proj_arg = "-p"
        result = self._session.execute("attribute -create \"%s\" -type \"%s\" %s %s \"%s\"" % (name, type_, args, proj_arg, self.objectname))
        if result.status != 0 and result.status != None:
            raise CCMException("Error creating '%s' attribute. Result: '%s'" % (name, result.output), result)
        
    def keys(self):
        """ The list of supported Synergy attributes. """
        result = self._session.execute("attribute -la \"%s\"" % self, AttributeNameListResult(self._session))
        return result.output
    
    def is_predecessor_of(self, o):
        result = self._session.execute("query \"is_predecessor_of('%s') and name='%s'and version='%s'and type='%s'and instance='%s'\" -u -f \"%%objectname\"" % (o, self.name, self.version, self.type, self.instance), ObjectListResult(self._session))        
        if len(result.output):
            return True
        return False
        
    def predecessors(self):
        result = self._session.execute("query \"is_predecessor_of('%s')\" -u -f \"%%objectname\"" % self, ObjectListResult(self._session))        
        return result.output

    def successors(self):
        result = self._session.execute("query \"is_successor_of('%s')\" -u -f \"%%objectname\"" % self, ObjectListResult(self._session))        
        return result.output

    def is_recursive_predecessor_of(self, o):
        result = self._session.execute("query \"has_predecessor('%s')\" -u -f \"%%objectname\"" % self, ObjectListResult(self._session))
        for s in result.output:
            if s == o:
                return True
        for s in result.output:
            if s.is_recursive_predecessor_of(o):
                return True
        return False

    def is_recursive_predecessor_of_fast(self, o):
        """ Fast implementation of the recursive is_predecessor_of method. """
        input_objects = [self]
        while len(input_objects) > 0:
            query = " or ".join(["has_predecessor('%s')" % x for x in input_objects])
            result = self._session.execute("query \"query\" -u -f \"%%objectname\"" % query, ObjectListResult(self._session))    
            for s in result.output:
                if s == o:
                    return True
        return False

    def is_recursive_sucessor_of(self, o):
        result = self._session.execute("query \"has_successor('%s')\" -u -f \"%%objectname\"" % self, ObjectListResult(self._session))
        for s in result.output:
            if s == o:
                return True
        for s in result.output:
            if s.is_recursive_sucessor_of(o):
                return True
        return False

    def is_recursive_successor_of_fast(self, o):
        """ Fast implementation of the recursive is_successor_of method. """
        input_objects = [self]
        while len(input_objects) > 0:
            query = " or ".join(["has_successor('%s')" % x for x in input_objects])
            result = self._session.execute("query \"query\" -u -f \"%%objectname\"" % query, ObjectListResult(self._session))    
            for s in result.output:
                if s == o:
                    return True
        return False
    
    def relate(self, ccm_object):
        result = self._session.execute("relate -name successor -from \"%s\" -to \"%s\"" % self, ccm_object, Result(self._session))
        if result.status != None and result.status != 0:
            raise CCMException("Error relating objects %s to %s\n%s" % (self, ccm_object, result.output))
        
    def finduse(self):
        """ Tries to find where an object is used. """
        result = self._session.execute("finduse \"%s\"" % self, FinduseResult(self))
        return result.output
    
    
class File(CCMObject):
    """ Wrapper for any Synergy file object """
    
    def __init__(self, session, fpn):
        CCMObject.__init__(self, session, fpn)
    
    def content(self):
        result = self._session.execute("cat \"%s\"" % self)
        return result.output
    
    def to_file(self, path):
        if os.path.exists(path):
            _logger.error("Error file %s already exists" % path)
        if not os.path.exists(os.path.dirname(path)):
            os.makedirs(os.path.dirname(path))
        # Content to file        
        result = self._session.execute("cat \"%s\" > \"%s\"" % (self, os.path.normpath(path)))
        if result.status != 0 and result.status != None:
            raise CCMException("Error retrieving content from object %s in %s (error status: %s)\n%s" % (self, path, result.status, result.output), result)
    
    def merge(self, ccm_object, task):
        assert ccm_object != None, "object must be defined."
        assert task != None, "task must be defined."
        assert task.type == "task", "task parameter must be of 'task' type."
        result = self._session.execute("merge -task %s \"%s\" \"%s\"" % (task['displayname'], self, ccm_object))
        
        validity = 0
        for line in result.output.splitlines():
            if re.match(r"Merge Source completed successfully\.", line):
                validity = 2
            elif re.match(r"Warning: Merge Source warning. \(overlaps during merge\)\.", line):
                validity = 1
            else:                
                result = re.match(r"Associated object\s+(?P<object>.+)\s+with task", line)
                if result != None:
                    return (self._session.create(result.groupdict()['object']), validity)
                    
        raise CCMException("Error during merge operation.\n" + result.output, result)

    def checkin(self, state, comment=None):
        if comment != None:
            comment = "-c \"%s\"" % comment
        else:
            comment = "-nc"
        result = self._session.execute("checkin -s \"%s\" %s \"%s\" " % (state, comment, self))
        for line in result.output.splitlines():
            _logger.debug(line)
            _logger.debug(r"Checked\s+in\s+'.+'\s+to\s+'%s'" % state)
            if re.match(r"Checked\s+in\s+'.+'\s+to\s+'%s'" % state, line) != None:
                return
        raise CCMException("Error checking in object %s,\n%s" % (self, result.output), result)
        

class Project(CCMObject):
    """ Wrapper class for Synergy project object. """
    
    def __init__(self, session, fpn):
        CCMObject.__init__(self, session, fpn)
        self._release = None
        self._baseline = None

    def _gettasks(self):
        result = self._session.execute("rp -show tasks \"%s\" -u -f \"%%objectname\"" % self, ObjectListResult(self._session))
        return result.output

    def add_task(self, task):
        """ Add a task to the update properties. """
        result = self._session.execute("up -add -task %s \"%s\"" % (task['displayname'], self.objectname))
        if result.status != None and result.status != 0:
            raise CCMException("Error adding task %s to project '%s'\n%s" % (task, self, result.output))
        
    def remove_task(self, task):
        """ Remove a task to the update properties. """
        result = self._session.execute("up -remove -task %s \"%s\"" % (task['displayname'], self.objectname))
        if result.status != None and result.status != 0:
            raise CCMException("Error removing task %s from project '%s'\n%s" % (task, self, result.output))

    def add_folder(self, folder):
        """ Add a folder to the update properties. """
        result = self._session.execute("up -add -folder %s \"%s\"" % (folder['displayname'], self.objectname))
        if result.status != None and result.status != 0:
            raise CCMException("Error adding folder %s to project '%s'\n%s" % (folder, self, result.output))
        
    def remove_folder(self, folder):
        """ Remove a folder to the update properties. """
        result = self._session.execute("up -remove -folder %s \"%s\"" % (folder['displayname'], self.objectname))
        if result.status != None and result.status != 0:
            raise CCMException("Error removing folder %s to project '%s'\n%s" % (folder, self, result.output))
    
    def _getfolders(self):
        """ Wrapper method to return the folder list from the update properties - please use the folders attribute to access it. """
        result = self._session.execute("up -show folders \"%s\" -u -f \"%%objectname\"" % self, ObjectListResult(self._session))
        return result.output
        
    def _getsubprojects(self):
        """ Wrapper method to return the subprojects list - please use the subprojects attribute to access it. """
        result = self._session.execute("query -t project \"recursive_is_member_of('%s', none)\" -u -f \"%%objectname\"" % self.objectname, ObjectListResult(self._session))
        return result.output
    
    def get_members(self, recursive=False, **kargs):
        query = "is_member_of('%s')" % self.objectname
        if recursive:
            query = "recursive_is_member_of('%s', none)" % self.objectname           
        for k in kargs.keys():
            query += " and %s='%s'" % (k, kargs[k])
        result = self._session.execute("query \"%s\" -u -f \"%%objectname\"" % query, ObjectListResult(self._session))
        return result.output
        
    def _getrelease(self):
        """ Get the release of the current object. Returns a Releasedef object. """
        self._release = Releasedef(self._session, self['release'])
        return self._release

    def _setrelease(self, release):
        """ Set the release of the current object. """
        self['release'] = release['displayname']
    
    def refresh(self):
        """ Refresh project update properties. """
        result = self._session.execute("up -refresh \"%s\"" % self.objectname, UpdatePropertiesRefreshResult(self._session))
        return result.output
    
    def _getbaseline(self):
        """ Get the baseline of the current project. """
        if self._baseline == None:
            result = self._session.execute("up -show baseline_project \"%s\" -f \"%%displayname\" -u" % self.objectname)
            if result.output.strip().endswith('does not have a baseline project.'):
                return None
            self._baseline = self._session.create(result.output)
        _logger.debug('baseline: %s' % self._baseline)
        return self._baseline
    
    def set_baseline(self, baseline, recurse=False):
        """ Set project baseline. raise a CCMException in case or error. """
        args = ""
        if recurse:
            args += " -r"
        self._baseline = None
        result = self._session.execute("up -mb \"%s\" %s \"%s\"" % (baseline, args, self.objectname))
        if result.status != None and result.status != 0:
            raise CCMException("Error setting basline of project '%s'\n%s" % (self.objectname, result.output))

    def set_update_method(self, name, recurse = False):
        """ Set the update method for the project (and subproject if recurse is True). """
        assert name != None, "name must not be None."
        assert len(name) > 0, "name must not be an empty string."
        args = "-ru %s" % name
        if recurse:
            args += " -r"
        result = self._session.execute("up %s \"%s\"" % (args, self))
        if result.status != None and result.status != 0:
            raise CCMException("Error setting reconfigure properties to %s for project '%s'\nStatus: %s\n%s" % (name, self.objectname, result.status, result.output))
   
    def apply_update_properties(self, baseline = True, tasks_and_folders = True, recurse=True):
        """ Apply update properties to subprojects. """
        args = ""
        if not baseline:
            args += "-no_baseline"
        if not tasks_and_folders:
            args += " -no_tasks_and_folders"
        if recurse:
            args += " -apply_to_subprojs"
        result = self._session.execute("rp %s \"%s\"" % (args, self.objectname))
        if result.status != None and result.status != 0:
            raise CCMException("Error applying update properties to subprojects for '%s'\n%s" % (self.objectname, result.output))
    
    def root_dir(self):
        """ Return the directory attached to a project. """
        result = self._session.execute("query \"is_child_of('%s','%s')\" -u -f \"%%objectname\"" % (self.objectname, self.objectname), ObjectListResult(self._session))
        return result.output[0]
    
    def snapshot(self, targetdir, recursive=False):
        """ Take a snapshot of the project. """
        assert targetdir != None, "targetdir must be defined."
        if recursive:
            recursive = "-recurse"
        else:
            recursive = ""
        result = self._session.execute("wa_snapshot -path \"%s\"  %s \"%s\"" % (os.path.normpath(targetdir), recursive, self.objectname))
        for line in result.output.splitlines():
            if re.match(r"^Creation of snapshot work area complete.|Copying to file system complete\.\s*$", line):
                return result.output
        raise CCMException("Error creation snapshot of %s,\n%s" % (self.objectname, result.output), result)
    
    def checkout(self, release, version=None, purpose=None, subprojects=True):
        """ Create a checkout of this project. 
        
        This will only checkout the project in Synergy. It does not create a work area.
        
        :param release: The Synergy release tag to use.
        :param version: The new version to use for the project. This is applied to all subprojects.
        :param purpose: The purpose of the checkout. Determines automatically the role from the purpose
         and switch it automatically (Could be any role from the DB).
        """    
        assert release != None, "Release object must be defined."
        if not release.exists():
            raise CCMException("Release '%s' must exist in the database." % release)
            
        args = ''
        if version != None:
            args += '-to "%s"' % version
        role = None
        if purpose:
            #save current role before changing
            role = self._session.role

            self._session.role = get_role_for_purpose(self._session, purpose)
            
            args += " -purpose \"%s\"" % purpose
        if subprojects:
            args += " -subprojects"
        result = self._session.execute("checkout -project \"%s\" -release \"%s\" -no_wa %s" \
                                  % (self, release['displayname'], args), ProjectCheckoutResult(self._session, self.objectname))
        if not role is  None:
            self._session.role = role
        if result.project == None:
            raise CCMException("Error checking out project %s,\n%s" % (self.objectname, result.output), result)
        return result
    
    def work_area(self, maintain, recursive=None, relative=None, path=None, pst=None, wat=False):
        """ Configure the work area. This allow to enable it or disable it, set the path, recursion... """
        args = ""
        if maintain:
            args += "-wa"
        else:
            args += "-nwa"
        # path
        if path != None:
            args += " -path \"%s\"" % path        
        # pst
        if pst != None:
            args += " -pst \"%s\"" % pst
        # relative
        if relative != None and relative:
            args += " -relative"
        elif relative != None and not relative:
            args += " -not_relative"
        # recursive
        if recursive != None and recursive:
            args += " -recurse"
        elif recursive != None and not recursive:
            args += " -no_recurse"        
        #wat            
        if wat:
            args += " -wat"
        result = self._session.execute("work_area -project \"%s\" %s" \
                                  % (self.objectname, args), Result(self._session))
        return result.output
        
    def update(self, recurse=True, replaceprojects=True, keepgoing=False, result=None):
        """ Update the project based on its reconfigure properties. """
        args = ""
        if recurse:
            args += " -r "
        if replaceprojects:
            args += " -rs "
        else:
            args += " -ks "
        if result == None:
            result = UpdateResult(self._session)
        result = self._session.execute("update %s -project %s" % (args, self.objectname), result)
        if not result.successful and not keepgoing:
            raise CCMException("Error updating %s" % (self.objectname), result)
        return result
    
    def reconcile(self, updatewa=True, recurse=True, consideruncontrolled=True, missingwafile=True, report=True):
        """ Reconcile the project to force the work area to match the database. """
        args = ""
        if updatewa:
            args += " -update_wa "
        if recurse:
            args += " -recurse "
        if consideruncontrolled:
            args += " -consider_uncontrolled "
        if missingwafile:
            args += " -missing_wa_file "
        if report:
            args += " -report reconcile.txt "
        result = self._session.execute("reconcile %s -project %s" % (args, self.objectname), Result(self._session))
        if re.search(r"There are no conflicts in the Work Area", result.output) == None and re.search(r"Reconcile completed", result.output) == None:
            raise CCMException("Error reconciling %s,\n%s" % (self.objectname, result.output), result)        
        return result.output

    def get_latest_baseline(self, filterstring="*", state="released"):
        result = self._session.execute("query -n %s -t project -f \"%%displayname\" -s %s -u -ns \"version smatch'%s'\"" % (self.name, state, filterstring))
        lines = result.output.splitlines()
        return lines[-1]

    def create_baseline(self, baseline_name, release, baseline_tag, purpose="System Testing", state="published_baseline"):
        result = self._session.execute("baseline -create %s -release %s -purpose \"%s\" -vt %s -project \"%s\" -state \"%s\"" % (baseline_name, release, purpose, baseline_tag, self.objectname, state))
        return result.output
    
    def sync(self, recurse=False, static=False):
        """ Synchronize project content. By default it is not been done recusively. (Not unittested)"""
        args = ""
        if recurse:
            args += " -recurse"
        if static:
            args += " -static"
        result = self._session.execute("sync %s -project \"%s\"" % (args, self.objectname))
        if result.status != None and result.status != 0:
            raise CCMException("Error during synchronization of %s: %s." % (self.objectname, result.output))
        return result.output

    def conflicts(self, recurse=False, tasks=False):
        args = "-noformat "
        if recurse:
            args += " -r"
        if tasks:
            args += " -t"
        
        result = self._session.execute("conflicts %s  \"%s\"" % (args, self.objectname), ConflictsResult(self._session))
        if result.status != None and result.status != 0:
            raise CCMException("Error during conflict detection of %s: %s." % (self.objectname, result))
        return result
    
    tasks = property(_gettasks)
    folders = property(_getfolders)
    subprojects = property(_getsubprojects)
    release = property(_getrelease, _setrelease)
    baseline = property(_getbaseline, set_baseline)


class Dir(CCMObject):
    """ Wrapper class for Synergy dir object """
    
    def __init__(self, session, fpn):
        CCMObject.__init__(self, session, fpn)

    def children(self, project):
        assert(project.type == 'project')
        result = self._session.execute("query \"is_child_of('%s','%s')\" -u -f \"%%objectname\"" % (self.objectname, project), ObjectListResult(self._session))
        return result.output
        

class Releasedef(CCMObject):
    """ Wrapper class for Synergy releasedef object """
    
    def __init__(self, session, fpn):
        CCMObject.__init__(self, session, fpn)
    
    def _getcomponent(self):
        return self.name
            
    component = property(_getcomponent)


class Folder(CCMObject):
    """ Wrapper class for Synergy folder object """
    
    def __init__(self, session, fpn):
        CCMObject.__init__(self, session, fpn)

    def _gettasks(self):
        """ Accessor for 'tasks' property. """
        result = self._session.execute("folder -show tasks \"%s\" -u -f \"%%objectname\"" % self.objectname, ObjectListResult(self._session))
        return result.output

    def _getobjects(self):
        result = self._session.execute("folder -show objects \"%s\" -u -f \"%%objectname\"" % self.objectname, ObjectListResult(self._session))
        return result.output

    def _getmode(self):
        """ Get the mode used by the folder. """
        result = self._session.execute("folder -show mode \"%s\"" % self.objectname)
        return result.output.strip()

    def _getquery(self):
        """ Get the query that populate the folder. """
        if self.mode.lower() == "query":
            result = self._session.execute("folder -show query \"%s\"" % self.objectname)
            return result.output.strip()
        else:
            raise CCMException("%s is not a query base folder." % (self.objectname))
    
    def _getdescription(self):
        """ Get the description associated with the folder. """
        r = self._session.execute("query -t folder -n %s -i %s -u -f \"%%description\"" % (self.name, self.instance))
        return r.output.strip()

    def remove(self, task):
        """ Remove task from this folder. """
        result = self._session.execute("folder -m \"%s\" -remove_task \"%s\"" % (self.objectname, task.objectname))
        if result.status != None and result.status != 0:
            raise CCMException("Error removing task %s from %s: %s." % (task.objectname, self.objectname, result.output))

    def update(self):
        result = self._session.execute("folder -m -update -f \"%%objectname\"" % self.objectname)
        if result.status != None and result.status != 0:
            raise CCMException("Error updating the folder content %s: %s." % (self.objectname, result.output))
        
    def append(self, task):
        """ Associate an object to a task """
        class AddTaskException(CCMException):
            def __init__(self, reason, task, result):
                CCMException.__init__(self, reason, result)
                self.task = task
        
        result = self._session.execute("folder -m -at \"%s\" \"%s\"" % (task.objectname, self.objectname))
        if re.search(r"(Added 1 task to)|(is already in folder)", result.output, re.M) is None:
            raise AddTaskException(result.output, result, task)
    
    def copy(self, existing_folder):
        """ Copy the contents of existing_folder into this folder.
        
        This appends to the destination folder by default.
        
        :param existing_folder: The destination Folder object.
        """
        result = self._session.execute("folder -copy %s -existing %s -append" % (self.objectname, existing_folder), FolderCopyResult(self._session))
        return result.output
        
    objects = property(_getobjects)
    tasks = property(_gettasks)
    mode = property(_getmode)
    query = property(_getquery)
    is_query_based = property(lambda x: x.mode.lower() == "query")
    description = property(_getdescription)


class Task(CCMObject):
    """ Wrapper class for Synergy task object """
    
    def __init__(self, session, fpn):
        CCMObject.__init__(self, session, fpn)
        self.__unicode_str_text = None

    def _getobjects(self):
        result = self._session.execute("task -show objects \"%s\" -u -f \"%%objectname\"" % self.objectname, ObjectListResult(self._session))
        return result.output
    
    def append(self, ccm_object):
        """ Associate an object to a task """
        class AddObjectException(CCMException):
            def __init__(self, comment, ccm_object):
                CCMException.__init__(self, comment)
                self.ccm_object = ccm_object
        
        result = self._session.execute("task -associate \"%s\" -object \"%s\"" % (self.objectname, ccm_object.objectname))
        if not re.match(r"Associated object .+ with task .*\.", result.output, re.M):
            raise AddObjectException(result.output)

    def assign(self, username):
        result = self._session.execute("task -modify \"%s\" -resolver %s" % (self.objectname, username))
        if not re.match(r"Changed resolver of task", result.output, re.M):
            raise CCMException("Error assigning task to user '%s',\n%s" % (username, result.output), result)
        
    def _getsynopsis(self):
        return self['task_synopsis']    
        
    @staticmethod
    def create(session, release_tag, synopsis=""):
        assert release_tag.type == "releasedef", "release_tag must be a CCM object wrapper of releasedef type"    
        result = session.execute("task -create -synopsis \"%s\" -release \"%s\"" % (synopsis, release_tag['displayname']), CreateNewTaskResult(session))
        return result.output
        
    objects = property(_getobjects)
    
    def __unicode__(self):
        # TODO: use optimised query that makes only 1 ccm query with suitable format
        if self.__unicode_str_text == None:
            self.__unicode_str_text = u'%s: %s' % (self['displayname'], self['task_synopsis'])
        return self.__unicode_str_text
        
    def __str__(self):
        return self.__unicode__().encode('ascii', 'replace')
    
    def get_release_tag(self):
        """ Get task release. Use release property!"""
        result = self._session.execute("attribute -show release \"%s\"" % (self.objectname), Result(self._session))
        return result.output
    
    def set_release_tag(self, release_tag):
        """ Set task release. Use release property!"""        
        result = self._session.execute("attribute -modify release -value \"%s\" \"%s\"" % (release_tag, self.objectname), Result(self._session))
        return result.output

    release = property(get_release_tag, set_release_tag)

class UpdateTemplate:
    """ Allow to access Update Template property using Release and Purpose. """
    def __init__(self, releasedef, purpose):
        assert(releasedef != None)
        assert(purpose != None)
        self._releasedef = releasedef
        self._purpose = purpose
        
    def objectname(self):
        """ Return the objectname representing this virtual object. """
        return "%s:%s" % (self._releasedef['displayname'], self._purpose)

    def baseline_projects(self):
        """ Query all projects for this UpdateTemplate. """
        result = self._releasedef.session.execute("ut -sh baseline_projects \"%s\"" % self.objectname(), ObjectListResult(self._releasedef.session))
        print result.output
        return result.output

    def information(self):
        """ Query all projects for this UpdateTemplate. """
        result = self._releasedef.session.execute("ut -sh information \"%s\"" % self.objectname(), UpdateTemplateInformation(self._releasedef.session))
        print result.output
        return result.output

    def baseline_selection_mode(self):
        """ The current Baseline selection mode """
        result = self._releasedef.session.execute("ut -sh bsm \"%s\"" % self.objectname())
        print result.output.strip()
        return result.output.strip()


def read_ccmwaid_info(filename):
    """ Read data from a ccmwaid file. This method is an helper to retreive a project from a physical location. """
    ccmwaid = open(filename, 'r')
    # first line: database
    dbpath = os.path.dirname(ccmwaid.readline().strip())
    database = os.path.basename(dbpath)
    # 2nd line should be a timestamp
    ccmwaid.readline().strip()
    # 3rd line is the objectname
    objectref = ccmwaid.readline().strip()
    ccmwaid.close()    
    return {'dbpath': dbpath, 'database': database, 'objectname': objectref}

def create_project_from_path(session, path):
    """ Uses the (_|.)ccmwaid.inf file to create a Project object. """
    ccmwaid = ".ccmwaid.inf"
    if os.name == 'nt':
        ccmwaid = "_ccmwaid.inf"
        
    if (not os.path.exists(path + "/" + ccmwaid)):
        return None    
    result = read_ccmwaid_info(path + "/" + ccmwaid)
    
    return session.create(result['objectname'])


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
    if CCM_BIN == None:
        raise CCMException("Could not find CM/Synergy executable in the path.")
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

    # last chance...
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
        _logger.debug('Querying for existing Synergy sessions')
        command = "%s status" % (CCM_BIN)
        pipe = os.popen(command, 'r')
        result = pipe.read()
        pipe.close()
        _logger.debug('ccm status result: ' + result)
        for match in re.finditer(r'(?P<ccmaddr>\w+:\d+:\d+.\d+.\d+.\d+(:\d+.\d+.\d+.\d+)?)(?P<current_session>\s+\(current\s+session\))?\nDatabase:\s*(?P<dbpath>\S+)', result, re.M):
            d = match.groupdict()
            _logger.debug(d['ccmaddr'])
            _logger.debug(socket.gethostname())
            _logger.debug(d['current_session'])
            if d['ccmaddr'].lower().startswith(socket.gethostname().lower()):
                # These session objects should not close the session on deletion,
                # because they did not initially create the session
                existing_session = Session(username, engine, d['dbpath'], d['ccmaddr'], close_on_exit=False)
                _logger.debug('Existing session found: %s' % existing_session)
                _sessions.append(existing_session)
        # looking for session using dbpath
        for session in _sessions:
            if session.dbpath == dbpath:
                return session
    else:
        # looking for router address using GSCM database
        router_address = None
        if database == None and dbpath != None:
            database = os.path.basename(dbpath)
        
        lock = fileutils.Lock(CCM_SESSION_LOCK)
        try:
            lock.lock(wait=True)
            # if we have the database name we can switch to the correct Synergy router
            if database != None:
                _logger.info('Getting router address.')
                router_address = nokia.gscm.get_router_address(database)
                if os.sep == '\\' and router_address != None:
                    routerfile = open(os.path.join(os.path.dirname(CCM_BIN), "../etc/_router.adr"), 'r')
                    current_router = routerfile.read().strip()
                    routerfile.close()
                    if current_router != router_address.strip():
                        _logger.info('Updating %s' % (os.path.normpath(os.path.join(os.path.dirname(CCM_BIN), "../etc/_router.adr"))))
                        routerfile = open(os.path.join(os.path.dirname(CCM_BIN), "../etc/_router.adr"), "w+")
                        routerfile.write("%s\n" % router_address)
                        routerfile.close()
        
            # If no existing sessions were available, start a new one
            _logger.info('Opening session.')
            new_session = Session.start(username, password, engine, dbpath)
            lock.unlock()
            return new_session
        finally:
            lock.unlock()
    raise CCMException("Cannot open session for user '%s'" % username)


def get_role_for_purpose(session, purpose):
    """  return role needed to modify project with checkout for purpose. """
    purposes = session.purposes()
    if purpose in purposes:
        if purposes[purpose]['status'] == 'prep':
            return 'build_mgr'
    else:
        raise CCMException("Could not find purpose '%s' in the database.\n Valid purpose are: %s." % (purpose, ','.join(purposes.keys())))
    return 'developer'

def get_role_for_status(session, status):
    """  return role needed to modify project with a specific status. """
    if status == 'prep':
        return 'build_mgr'
    elif status == 'shared':
        return 'developer'
    elif status == 'working':
        return 'developer'
    else:
        raise CCMException("Unknow status '%s'" % status)

def running_sessions(database=None):
    """ Return the list of synergy session currently available on the local machine.
        If database is given then it tries to update the router address.
    """
    _logger.debug('Querying for existing Synergy sessions')
    if CCM_BIN == None:
        raise CCMException("Could not find CM/Synergy executable in the path.")
    command = "%s status" % (CCM_BIN)

    lock = fileutils.Lock(CCM_SESSION_LOCK)
    result = ""
    output = []
    try:
        # if we have the database name we can switch to the correct Synergy router
        if database != None:
            lock.lock(wait=True)
            _logger.info('Updating router address.')
            router_address = nokia.gscm.get_router_address(database)
            if os.sep == '\\' and router_address != None:
                routerfile = open(os.path.join(os.path.dirname(CCM_BIN), "../etc/_router.adr"), 'r')
                current_router = routerfile.read().strip()
                routerfile.close()
                if current_router != router_address.strip():
                    _logger.info('Updating %s' % (os.path.normpath(os.path.join(os.path.dirname(CCM_BIN), "../etc/_router.adr"))))
                    routerfile = open(os.path.join(os.path.dirname(CCM_BIN), "../etc/_router.adr"), "w+")
                    routerfile.write("%s\n" % router_address)
                    routerfile.close()

        _logger.debug('Command: ' + command)
        (result, status) = _execute(command)
        if database != None:
            lock.unlock()
        if (status != 0):
            raise CCMException("Ccm status execution returned an error.")
        _logger.debug('ccm status result: ' + result)
        for match in re.finditer(r'Command Interface\s+@\s+(?P<ccmaddr>\w+:\d+:\d+.\d+.\d+.\d+(:\d+.\d+.\d+.\d+)*)(?P<current_session>\s+\(current\s+session\))?\s+Database:\s*(?P<dbpath>\S+)', result, re.M):
            data = match.groupdict()
            _logger.debug(data['ccmaddr'])
            _logger.debug(socket.gethostname())
            _logger.debug(data['current_session'])
            if data['ccmaddr'].lower().startswith(socket.gethostname().lower()):
                # These session objects should not close the session on deletion,
                # because they did not initially create the session
                existing_session = Session(None, None, data['dbpath'], data['ccmaddr'], close_on_exit=False)
                _logger.debug('Existing session found: %s' % existing_session)
                output.append(existing_session)                
    finally:
        if database != None:
            lock.unlock()        
    return  output

def session_exists(sessionid, database=None):
    for session in running_sessions(database=database):
        _logger.debug(session.addr() + "==" + sessionid + "?")
        if session.addr() == sessionid:
            return True
    return False

# The location of the ccm binary must be located to know where the _router.adr file is, to support
# switching databases.
CCM_BIN = fileutils.which("ccm")
if os.sep == '\\':
    CCM_BIN = fileutils.which("ccm.exe")
