#============================================================================ 
#Name        : model.py 
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

""" Models the concepts and objects that exist in a software build. """

import logging
import re
import os
import amara
import ccm
import configuration
from xmlhelper import recursive_node_scan
import symrec

# Uncomment this line to enable logging in this module, or configure logging elsewhere
_logger = logging.getLogger("bom")
#_logger.setLevel(logging.DEBUG)
logging.basicConfig(level=logging.DEBUG)


class SessionCreator(object):
    """ Session Creator object. """
    def __init__(self, username=None, password=None, provider=None):
        """ Init the SessionCreator object."""
        self.__provider = provider
        self.__username = username
        self.__password = password
    
    def session(self, database):
        """ Get a session for a database. If no session exists just create a new one."""
        _logger.info("Creating session for %s" % database)
        return self.__provider.get(username=self.__username, password=self.__password, database=database)
        
    def close(self):
        self.__provider = None


class BOM(object):
    """ The Bill of Materials for a build. """
    def __init__(self, config):
        """ Initialization.
        
        :param config: The build configuration properties.
        :param ccm_project: The Synergy project used for reading the BOM.
        """
        self.config = config
        self.build = ""
        self._projects = []
        self._icd_icfs = []
        self._flags = []
        
        self._capture_icd_icfs()
        self._capture_flags()
        
    def _capture_icd_icfs(self):
        prep_xml_path = self.config['prep.xml']
        if prep_xml_path is not None and os.path.exists(prep_xml_path):
            prep_doc = amara.parse(open(prep_xml_path,'r'))
            if hasattr(prep_doc.prepSpec, u'source'):
                for source in prep_doc.prepSpec.source:
                    if hasattr(source, u'unzipicds'):
                        for  unzipicds in source.unzipicds:
                            if hasattr(unzipicds, u'location'):
                                for location in unzipicds.location:
                                    excludes = []
                                    excluded = False
                                    if hasattr(location, 'exclude'):
                                        for exclude in location.exclude:
                                            _logger.debug('Exclude added: %s' % str(exclude.name))
                                            excludes.append(str(exclude.name))                                
                                            excluded = False
                                    path = str(location.name)                                    
                                    if os.path.exists(path):
                                        files = os.listdir(str(location.name))
                                        for file_ in files:
                                            for exclude in excludes:
                                                if file_.endswith(exclude):
                                                    excluded = True
                                            if file_.endswith('.zip') and not excluded:
                                                self._icd_icfs.append(file_)
                                                self._icd_icfs.sort(key=str)
        
    def _capture_flags(self):
        pass
        
    def _getprojects(self):
        return self._projects
        
    projects = property(_getprojects)
    
    def all_baselines(self):
        baselines = {}
        for project in self._projects:
            for baseline, baseline_attrs in project.baselines.iteritems():
                baselines[baseline] = baseline_attrs
        return baselines
    
    def all_tasks(self):
        tasks = []
        for project in self._projects:
            tasks.extend(project.all_tasks())
        tasks.sort(key=str)
        return tasks
            
    def __str__(self):
        return str(self._projects)

class SimpleProject(object):
    def __init__(self, tasks):
        self.tasks = tasks
        self.folders = []

class SimpleBOM(BOM):
    def __init__(self, config, bomxml):
        BOM.__init__(self, config)
        self._baselines = {}
        bom = amara.parse(open(bomxml))
        for p in bom.bom.content.project:
            tasks = []
            self._baselines[str(p.baseline)] = {}
            for t in p.task:
                tasks.append(str(t.id) + ': ' + str(t.synopsis))
            self._projects.append(SimpleProject(tasks))
    
    def all_baselines(self):
        return self._baselines

class SynergyBOM(BOM):
    def __init__(self, config, ccm_project=None, username=None, password=None, provider=None):
        BOM.__init__(self, config)
        self._sessioncreator = SessionCreator(username=username, password=password, provider=provider)
        self.ccm_project = ccm_project
        if self.ccm_project != None: 
            self._projects = [Project(ccm_project, config)]
        self._capture_projects()
            
    def __find_project(self, project, config):
        if (os.path.exists(os.path.join(config['dir'], project.name, "project.version"))):
            return project
        
        path = os.path.join(config['dir'], project.name, project.name)
        if (not os.path.exists(path)):
            return project
        try:
            result = project.session.get_workarea_info(path)
            return result['project']           
        except ccm.CCMException:            
            return project
            
    def _capture_projects(self):
        # grab data from new format of delivery.xml
        configBuilder = configuration.NestedConfigurationBuilder(open(self.config['delivery'], 'r'))
        for config in configBuilder.getConfiguration().getConfigurations():            
            _logger.debug('Importing project %s from delivery config.' % str(config.name))            
            ccm_project = self._sessioncreator.session(config['database']).create(config.name)
            project = Project(self.__find_project(ccm_project, config), config)
            self._projects.append(project)
        
    def close(self):
        self._sessioncreator.close()


class Project(object):
    """ An SCM project.
    
    An input to the build area, typically copied from an SCM work area.
    """
    def __init__(self, ccm_project, config, action=None):
        """ Initialisation. """
        self._ccm_project = ccm_project
        self._baselines = {}
        #TODO : could querying release attribute return the ccm object? Or add a release attribute to Project
        # class
        release = self._ccm_project['release']
        _logger.debug("Project release: '%s'" % release)
        self._ccm_release = None
        if release != '':
            self._ccm_project.session.create(release)

        # capturing the frozen baseline.
        _logger.debug('Capture baselines')
        project_status = self._ccm_project['status']
        bproject = self._get_toplevel_baselines(self._ccm_project).pop()
        if bproject != None:        
            self._baselines[unicode(bproject)] = {u'overridden':u'true'}
            # This section finds the baselines of all of the checked out projects
            if project_status == "prep" or project_status == "working" or project_status == "shared":
                for subproject in self._ccm_project.subprojects:
                    overridden = u'false'
                    subprojbaseline = subproject.baseline
                    if config.has_key('subbaselines'):
                        for subbaseline in config['subbaselines']:
                            if str(subbaseline) == str(subprojbaseline):
                                overridden = u'true'
                    
                    if subprojbaseline != None:
                        self._baselines[unicode(subprojbaseline)] = {u'overridden': overridden}
            # When a project is a snapshot, the baselines are the projects themselves
            else:
                for subproject in bproject.subprojects:            
                    self._baselines[unicode(subproject)] = {u'overridden':u'false'}

        self._tasks = []
        self._folders = []
        
        # Get Synergy reconfigure properties for folders and tasks
        if action == None:
            self._import_baseline_config()
            # Get tasks from Synergy if using reconfigure template
            if config.get_boolean("use.reconfigure.template", False):
                self._tasks = self._ccm_project.tasks
                self._folders = self._ccm_project.folders
                        
        # Or get folders and tasks defined in configuration file
        elif action != None and action.nodeName == "checkout":
            if not config.get_boolean("use.reconfigure.template", False):
                for task_node in action.xml_xpath(u'./task[@id]'):
                    for task in [x.strip() for x in task_node.id.split(',')]:
                        self._tasks.append(ccm_project.session.create("Task %s" % task))
                for folder_node in action.xml_xpath(u'./folder[@id]'):
                    for folder in [x.strip() for x in folder_node.id.split(',')]:
                        self._folders.append(ccm_project.session.create("Folder %s" % folder))
            else:
                self._tasks = self._ccm_project.tasks
                self._folders = self._ccm_project.folders
            self._import_baseline_config()

    def _import_baseline_config(self):
        """ Import the baseline folders and tasks. """
        baselines = self._get_toplevel_baselines(self._ccm_project)
        baselines.pop()
        for baseline in baselines:
            for task in baseline.tasks:
                if task not in self._tasks:                     
                    self._tasks.append(task)
            for folder in baseline.folders:
                if folder not in self._folders:                     
                    self._folders.append(folder)
        
    def _get_toplevel_baselines(self, project):
        if project == None:
            return []
        project_status = project['status']
        if project_status == "prep" or project_status == "working" or project_status == "shared":
            result = [project]
            baseline = project.baseline
            if baseline != None:
                result.extend(self._get_toplevel_baselines(baseline))
            return result
        else:
            return [project]

    def _getbaselines(self):
        return self._baselines
        
    baselines = property(_getbaselines)
       
    def _getfolders(self):
        return self._folders
        
    folders = property(_getfolders)
    
    def all_tasks(self):
        """ Get all the tasks (individual and folder based). """
        tasks = [Task(ccm_task) for ccm_task in self._tasks]
        for folder in self._folders:
            [tasks.append(Task(ccm_task)) for ccm_task in folder.tasks]
        tasks.sort(key=str)
        return tasks
        
    def _gettasks(self):
        return [Task(ccm_task) for ccm_task in self._tasks]
        
    tasks = property(_gettasks)
        
    def _getsupplier(self):
        if self._ccm_release != None:
            component = self._ccm_release.component
            comparisons = {'MC': '^mc',
                           'S60': 'S60',
                           'SPP/NCP': '^spp_config|spp_psw|spp_tools|ncp_sw$',
                           'IBUSAL': '^IBUSAL'}
            for supplier, regexp in comparisons.iteritems():
                if re.search(regexp, component) != None:
                    return supplier
        return "Unknown"
        
    supplier = property(_getsupplier)
    
    def __repr__(self):
        """ Object representation. """
        return str(self._ccm_project)
        
    def __str__(self):
        """ String representation. """
        return str(self._ccm_project)


class Fix(object):
    """ A generic fix. """
    def __init__(self, description):
        """ Initialisation. """
        self._description = description
        
    def __str__(self):
        """ String representation. """
        return str(self._description)
        
        
class TSWError(Fix):
    """ A TSW database error. """
    regex = '([A-Z]{4}-[A-Z0-9]{6})'
    groupname = 'TSW Errors'

    def __init__(self, description):
        """ Initialisation. """
        Fix.__init__(self, description)


class PCPError(Fix):
    """ A PCP database error. """
    regex = '([A-Z]{2}-[0-9]{11})'
    groupname = 'PCP Errors'

    def __init__(self, description):
        """ Initialisation. """
        Fix.__init__(self, description)


class TAChange(Fix):
    """ A Type Approval change. """
    regex = '^_TA:(\s*)(.*?)(\s*)$'
    groupname = 'TA Changes'
    
    def __init__(self, description):
        """ Initialisation. """
        Fix.__init__(self, description)
        
        
class Task(object):
    """ A task or unit of change from the SCM system. """
    fix_types = [TSWError, PCPError, TAChange]
    
    def __init__(self, ccm_task):
        """ Initialisation. """
        self.ccm_task = ccm_task

    def __getitem__(self, name):
        """ Dictionary of tasks support. """
        return self.ccm_task[name]
            
    def has_fixed(self):
        """ Returns an object representing what this task fixed, if anything. """
        text = str(self.ccm_task)
        fix_object = None
        for fix_type in self.fix_types:
            match = re.search(fix_type.regex, str(self.ccm_task))
            if match != None:
                fix_object = fix_type(text)
                break
        return fix_object
        
    def __cmp__(self, other):
        """ Compare tasks based on their task number only. """
        self_task = str(self.ccm_task)
        other_task = str(other.ccm_task)
        return cmp(self_task[:self_task.find(':')], other_task[:other_task.find(':')])
        
    def __hash__(self):
        """ Hash support. """
        self_task = str(self.ccm_task)
        return hash(self_task[:self_task.find(':')])
    
    def __repr__(self):
        """ Object representation. """
        self_task = repr(self.ccm_task)
        return self_task[:self_task.find(':')]
        
    def __str__(self):
        """ String representation. """
        return str(self.ccm_task)
        
        
class ICD_ICF(object):
    """ A ICD or ICF patch zip file provided by Symbian. """
    pass


class Flag(object):
    """ A compilation flag. """
    pass
    

class BOMDeltaXMLWriter(object):
    def __init__(self, bom, bom_log):
        """ Initialisation. """
        self._bom = bom
        self._bom_log = bom_log
    
    def write(self, path):
        """ Write the BOM delta information to an XML file. """
        bom_log = amara.parse(open(self._bom_log, 'r'))
        doc = amara.create_document(u'bomDelta')
        # pylint: disable-msg=E1101
        doc.bomDelta.xml_append(doc.xml_create_element(u'buildFrom', content=unicode(bom_log.bom.build)))
        doc.bomDelta.xml_append(doc.xml_create_element(u'buildTo', content=unicode(self._bom.config['build.id'])))
        content_node = doc.xml_create_element(u'content')
        doc.bomDelta.xml_append(content_node)
        
        old_baselines = {}
        baselines = {}
        old_folders = {}
        folders = {}
        old_tasks = {}
        tasks = {}
        if hasattr(bom_log.bom.content, 'project'):
            for project in bom_log.bom.content.project:
                if hasattr(project, 'baseline'):
                    for baseline in project.baseline:
                        if not old_baselines.has_key(unicode(baseline)):
                            old_baselines[unicode(baseline)] = {}
                        if hasattr(baseline, 'xml_attributes'):
                            _logger.debug('baseline.xml_attributes: %s' % baseline.xml_attributes)
                            for attr_name, junk_tuple in sorted(baseline.xml_attributes.iteritems()):
                                _logger.debug('attr_name: %s' % attr_name)
                                old_baselines[unicode(baseline)][unicode(attr_name)] = unicode(getattr(baseline, attr_name))
                if hasattr(project, 'folder'):
                    for folder in project.folder:
                        if hasattr(folder, 'name'):
                            for name in folder.name:
                                folder_name = unicode(name)
                                _logger.debug('folder_name: %s' % folder_name)
                            if not old_folders.has_key(unicode(folder_name)):
                                old_folders[unicode(folder_name)] = {}
                            if hasattr(name, 'xml_attributes'):
                                for attr_name, junk_tuple in sorted(name.xml_attributes.iteritems()):
                                    _logger.debug('attr_name: %s' % attr_name)
                                    old_folders[unicode(folder_name)][unicode(attr_name)] = unicode(getattr(name, attr_name))
        for task in recursive_node_scan(bom_log.bom.content, u'task'):
            _logger.debug('task: %s' % task)
            _logger.debug('task: %s' % task.id)
            _logger.debug('task: %s' % task.synopsis)
            task_id = u"%s: %s" % (task.id, task.synopsis)
            if not old_tasks.has_key(task_id):
                old_tasks[task_id] = {}
            if hasattr(task, 'xml_attributes'):
                for attr_name, junk_tuple in sorted(task.xml_attributes.iteritems()):
                    _logger.debug('attr_name: %s' % attr_name)
                    old_tasks[task_id][unicode(attr_name)] = unicode(getattr(task, attr_name))
        for project in self._bom.projects:
            for folder in project.folders:
                folders[unicode(folder.instance + "#" + folder.name + ": " + folder.description)] = {u'overridden':u'true'}
                for task in folder.tasks:
                    _logger.debug("task_bom:'%s'" % unicode(task))
                    tasks[unicode(task)] = {u'overridden':u'false'}
            for task in project.tasks:
                _logger.debug("task_bom:'%s'" % unicode(task))
                tasks[unicode(task)] = {u'overridden':u'true'}

        baselines = self._bom.all_baselines()

        self._write_items_with_attributes(content_node, u'baseline', baselines, old_baselines)
        self._write_items_with_attributes(content_node, u'folder', folders, old_folders)
        self._write_items_with_attributes(content_node, u'task', tasks, old_tasks)
        
        out = open(path, 'w')
        doc.xml(out, indent='yes')
        out.close()
        
    
    def validate_delta_bom_contents(self, delta_bom_log, bom_log, old_bom_log):
        """ To validate delta bom contents with current bom and old bom. """
        delta_bom_log = amara.parse(open(delta_bom_log, 'r'))
        bom_log = amara.parse(open(bom_log, 'r'))
        old_bom_log = amara.parse(open(old_bom_log, 'r'))
        bom_contents_are_valid = None
        if hasattr(delta_bom_log.bomDelta.content, 'folder'):
            for delta_foder in delta_bom_log.bomDelta.content.folder:
                if(getattr(delta_foder, 'status'))=='added':
                    for bom_foder in bom_log.bom.content.project.folder:
                        if(unicode(getattr(bom_foder, 'name')) == unicode(delta_foder)):
                            bom_contents_are_valid = True
                        else:
                            bom_contents_are_valid = False
                if(getattr(delta_foder, 'status'))=='deleted':
                    for old_bom_foder in old_bom_log.bom.content.project.folder:
                        if(unicode(getattr(old_bom_foder, 'name')) == unicode(delta_foder)):
                            bom_contents_are_valid = True
                        else:
                            bom_contents_are_valid = False
                        
        if hasattr(delta_bom_log.bomDelta.content, 'task'):
            for delta_task in delta_bom_log.bomDelta.content.task:
                if(getattr(delta_task, 'status'))=='added':
                    for bom_task in recursive_node_scan(bom_log.bom.content, u'task'):
                        bom_task_id = u"%s: %s" % (bom_task.id, bom_task.synopsis)
                        if(bom_task_id == unicode(delta_task)):
                            bom_contents_are_valid = True
                        else:
                            bom_contents_are_valid = False
                if(getattr(delta_task, 'status'))=='deleted':
                    for old_bom_task in recursive_node_scan(old_bom_log.bom.content, u'task'):
                        old_bom_task_id = u"%s: %s" % (old_bom_task.id, old_bom_task.synopsis)
                        if(old_bom_task_id == unicode(delta_task)):
                            bom_contents_are_valid = True
                        else:
                            bom_contents_are_valid = False
        return bom_contents_are_valid
     
    def _write_items(self, node, item_name, items, older_items):
        items = frozenset(items)
        older_items = frozenset(older_items)
        
        items_added = list(items.difference(older_items))
        items_added.sort()
        for item in items_added:
            node.xml_append(node.xml_create_element(item_name, \
                            attributes={u'status': u'added'}, content=unicode(item)))
            
        items_deleted = list(older_items.difference(items))
        items_deleted.sort()
        for item in items_deleted:
            node.xml_append(node.xml_create_element(item_name, \
                            attributes={u'status': u'deleted'}, content=unicode(item)))

    # This method takes dictionaries as input to pass along attributes
    def _write_items_with_attributes(self, node, item_name, items, older_items):
        fr_items = frozenset(items)
        fr_older_items = frozenset(older_items)
        
        items_added = list(fr_items.difference(fr_older_items))
        items_added.sort()
        for item in items_added:
            item_attributes = {u'status': u'added'}
            for attr_name, attr_value in sorted(items[item].iteritems()):
                _logger.debug('item: %s' % item)
                _logger.debug('attr_name: %s' % attr_name)
                _logger.debug('attr_value: %s' % attr_value)
                item_attributes[attr_name] = attr_value
            node.xml_append(node.xml_create_element(item_name, \
                            attributes=item_attributes, content=unicode(item)))
            
        items_deleted = list(fr_older_items.difference(fr_items))
        items_deleted.sort()
        for item in items_deleted:
            item_attributes = {u'status': u'deleted'}
            for attr_name, attr_value in sorted(older_items[item].iteritems()):
                _logger.debug('item: %s' % item)
                _logger.debug('attr_name: %s' % attr_name)
                _logger.debug('attr_value: %s' % attr_value)
                item_attributes[attr_name] = attr_value
            node.xml_append(node.xml_create_element(item_name, \
                            attributes=item_attributes, content=unicode(item)))

            
class BOMXMLWriter(object):
    def __init__(self, bom):
        """ Initialisation. """
        self._bom = bom
        
    def write(self, path):
        """ Write the BOM information to an XML file. """
        doc = amara.create_document(u'bom')
        # pylint: disable-msg=E1101
        doc.bom.xml_append(doc.xml_create_element(u'build', content=unicode(self._bom.config['build.id'])))
        doc.bom.xml_append(doc.xml_create_element(u'content'))
        for project in self._bom.projects:
            project_node = doc.xml_create_element(u'project')
            project_node.xml_append(doc.xml_create_element(u'name', content=unicode(project)))
            project_node.xml_append(doc.xml_create_element(u'database', content=unicode(self._bom.config['ccm.database'])))
            doc.bom.content.xml_append(project_node)
            _logger.debug('baselines dictionary: %s' % project.baselines)
            for baseline, baseline_attrs in sorted(project.baselines.iteritems()):
                _logger.debug('baseline: %s' % baseline)
                _logger.debug('baseline_attrs: %s' % baseline_attrs)
                project_node.xml_append(doc.xml_create_element(u'baseline', content=unicode(baseline), attributes=baseline_attrs))
            for folder in project.folders:
                folder_node = doc.xml_create_element(u'folder')
                folder_node.xml_append(doc.xml_create_element(u'name', content=unicode(folder.instance + "#" + folder.name + ": " + folder.description), \
                            attributes={u'overridden':u'true'}))
                project_node.xml_append(folder_node)
                for task in folder.tasks:
                    task_node = doc.xml_create_element(u'task', attributes={u'overridden':u'false'})
                    task_node.xml_append(doc.xml_create_element(u'id', content=(unicode(task['displayname']))))
                    task_node.xml_append(doc.xml_create_element(u'synopsis', content=(unicode(task['task_synopsis']))))
                    task_node.xml_append(doc.xml_create_element(u'owner', content=(unicode(task['owner']))))
                    #task_node.xml_append(doc.xml_create_element(u'completed', content=(unicode(self.parse_status_log(task['status_log'])))))
                    folder_node.xml_append(task_node)
            for task in project.tasks:
                task_node = doc.xml_create_element(u'task', attributes={u'overridden':u'true'})
                task_node.xml_append(doc.xml_create_element(u'id', content=(unicode(task['displayname']))))
                task_node.xml_append(doc.xml_create_element(u'synopsis', content=(unicode(task['task_synopsis']))))
                task_node.xml_append(doc.xml_create_element(u'owner', content=(unicode(task['owner']))))
                #task_node.xml_append(doc.xml_create_element(u'completed', content=(unicode(self.parse_status_log(task['status_log'])))))
                project_node.xml_append(task_node)
                
                fix = task.has_fixed()
                if fix != None:
                    fix_node = doc.xml_create_element(u'fix', content=(unicode(task)), attributes = {u'type': unicode(fix.__class__.__name__)})
                    project_node.xml_append(fix_node)

        if self._bom._icd_icfs != []:
            # Add ICD info to BOM
            doc.bom.content.xml_append(doc.xml_create_element(u'input'))
    
            # Add default values to unused fields so icds are visible in the BOM
            empty_bom_str = u'N/A'
            empty_bom_tm = u'0'
            doc.bom.content.input.xml_append(doc.xml_create_element(u'name', content=(unicode(empty_bom_str))))
            doc.bom.content.input.xml_append(doc.xml_create_element(u'year', content=(unicode(empty_bom_tm))))
            doc.bom.content.input.xml_append(doc.xml_create_element(u'week', content=(unicode(empty_bom_tm))))
            doc.bom.content.input.xml_append(doc.xml_create_element(u'version', content=(unicode(empty_bom_str))))
    
            doc.bom.content.input.xml_append(doc.xml_create_element(u'icds'))

        # pylint: disable-msg=R0914
        for i, icd in enumerate(self._bom._icd_icfs):
            doc.bom.content.input.icds.xml_append(doc.xml_create_element(u'icd'))
            doc.bom.content.input.icds.icd[i].xml_append(doc.xml_create_element(u'name', content=(unicode(icd))))
        #If currentRelease.xml exists then send s60 <input> tag to diamonds
        current_release_xml_path = self._bom.config['currentRelease.xml']
        if current_release_xml_path is not None and os.path.exists(current_release_xml_path):
            metadata = symrec.ReleaseMetadata(current_release_xml_path)
            service = metadata.service
            product = metadata.product
            release = metadata.release
            # Get name, year, week and version from baseline configuration
            s60_input_node = doc.xml_create_element(u'input')
            s60_version = self._bom.config['s60_version']
            s60_release = self._bom.config['s60_release']
            if s60_version != None:
                s60_year = s60_version[0:4]
                s60_week = s60_version[4:]
            else:
                s60_year = u'0'
                s60_week = u'0'
                if s60_version == None:
                    res = re.match(r'(.*)_(\d{4})(\d{2})_(.*)', release)
                    if res != None:
                        s60_release = res.group(1) + '_' + res.group(4)
                        s60_year = res.group(2)
                        s60_week = res.group(3)
            s60_input_node.xml_append(doc.xml_create_element(u'name', content=(unicode("s60"))))
            s60_input_node.xml_append(doc.xml_create_element(u'year', content=(unicode(s60_year))))
            s60_input_node.xml_append(doc.xml_create_element(u'week', content=(unicode(s60_week))))
            s60_input_node.xml_append(doc.xml_create_element(u'version', content=(unicode(s60_release))))

            s60_input_source = s60_input_node.xml_create_element(u'source')
            s60_input_source.xml_append(doc.xml_create_element(u'type', content=(unicode("grace"))))
            s60_input_source.xml_append(doc.xml_create_element(u'service', content=(unicode(service))))
            s60_input_source.xml_append(doc.xml_create_element(u'product', content=(unicode(product))))
            s60_input_source.xml_append(doc.xml_create_element(u'release', content=(unicode(release))))
            s60_input_node.xml_append(s60_input_source)
            doc.bom.content.xml_append(s60_input_node)
        out = open(path, 'w')
        doc.xml(out, indent='yes')
        out.close()
        
    def parse_status_log(self, log):
        _log_array = log.split('\r')
        if(len(_log_array) == 3 and log.find('completed') > 0):
            _completed_line = _log_array[2]
            return _completed_line[:_completed_line.rfind(':')].strip()
        else:
            return u'None'
