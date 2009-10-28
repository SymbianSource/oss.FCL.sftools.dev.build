#============================================================================ 
#Name        : conflict.py 
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

""" CCM conflict detection module. """


import threading

import ccm
import threadpool


def get_tasks_from_project(project):
    result = []
    for folder in project.folders:
        result.extend(get_tasks(folder))    
    result.extend(project.tasks)    
    return result


def get_tasks_information_from_project(project):
    result = []
    for folder in project.folders:
        result.extend(get_tasks_information(folder))    
    for task in project.tasks:
        query = ccm.Query(folder.session, "name= '%s'and version='%s' and type='%s'and instance='%s'" % (task.name, task.version, task.type, task.instance),
                          ['objectname', 'owner', 'task_synopsis', 'displayname'],
                          ['ccmobject', 'string', 'string', 'string'])
        result.extend(query.execute().output)
    return result


def get_tasks_information(folder):
    """ Get tasks from folder. If the folder is query based it uses the query to determine the list of task.
        But the folder contents itself remains untouch.
    """
    query = None
    if folder.is_query_based:
        query = ccm.Query(folder.session, "type='task' and " + folder.query,
                          ['objectname', 'owner', 'task_synopsis', 'displayname'],
                          ['ccmobject', 'string', 'string', 'string'])
    else:
        query = ccm.Query(folder.session, folder.objectname,
                          ['objectname', 'owner', 'task_synopsis', 'displayname'],
                          ['ccmobject', 'string', 'string', 'string'],
                          "folder -show tasks")        
    # executing the query
    return query.execute().output



def get_tasks(folder):
    """ Get tasks from folder. If the folder is query based it uses the query to determine the list of task.
        But the folder contents itself remains untouch.
    """
    if folder.is_query_based:
        r = folder.session.execute("query -u -t task \"%s\" -f \"%%objectname\"" % folder.query, ccm.ObjectListResult(folder.session))
        return r.output
    else:
        return folder.tasks


class ObjectAndTask:
    """ Wrapper object which link an object to a task. """
    def __init__(self, object, task):
        self.object = object
        self.task = task
        self.overridenby = []
    
    def has_successor_in_list(self, oatl):
        """ Has our object any successor in the list. """
        for oat in oatl:
            if self.object.__ne__(oat.object) and oat.object.is_recursive_successor_of_fast(self.object):
                self.overridenby.append(oat)
                return True
        return False
    
    def __repr__(self):
        return "<ObjectAndTask %s, %s>" % (self.object.objectname, self.task.objectname)


class TaskModel:
    """ Task wrapper object which contains objectandtask object. """
    
    def __init__ (self, task):
        """ Init from task object. """
        self.task = task
        self.objectandtasks = {}        
        for object in self.task.objects:
            self.objectandtasks[str(object)] = ObjectAndTask(object, task)

    def is_useless(self):
        """ Is the task containing any usable objects. """
        count = 0
        for object in self.objectandtasks.keys():
            oat = self.objectandtasks[object]
            if len(oat.overridenby) > 0:
                count += 1
        if len(self.objectandtasks.keys()) == 0 or count == len(self.objectandtasks.keys()):
            return True
        return False
                
    
def tasks_to_objectandtask(tasks):
    object_families = {}
    for task in tasks:
        for object in task.objects:
            if not object.family in object_families:
                object_families[object.family] = []
            object_families[object.family].append(ObjectAndTask(object, task))
    return object_families


def tasks_to_families_and_taskmodels(tasks, size=1):
    object_families = {}
    taskmodels = []
    lock = threading.Lock()

    def __work(task):
        tm = TaskModel(task)
        
        lock.acquire()
        taskmodels.append(tm)
        lock.release()
        
        for oatk in tm.objectandtasks.keys():
            oat = tm.objectandtasks[oatk]
            lock.acquire()
            if not oat.object.family in object_families:                
                object_families[oat.object.family] = []            
            object_families[oat.object.family].append(oat)
            lock.release()

    
    if size > 1:
        pool = threadpool.ThreadPool(size)
        for task in tasks:
            pool.addWork(__work, args=[task])
        pool.wait()
    else:
        for task in tasks:
            __work(task)
    
    return (object_families, taskmodels)


def check_task_conflicts(tasks, size=1):
    """ Validates objects a list of task.
        It returns a list of list of conflicting ObjectAndTask.
    """
    
    object_families, taskmodels = tasks_to_families_and_taskmodels(tasks, size)
    conflicts = []
    lock = threading.Lock()

    pool = threadpool.ThreadPool(size)

    def __work(family):
        result = []
        for oat in object_families[family]:
            if oat.has_successor_in_list(object_families[family]) == False:
                add = True
                for roat in result:
                    if roat.object == oat.object:
                        add = False
                        break
                if add: 
                    result.append(oat)
                     
        if len(result)>1:
            lock.acquire()
            conflicts.append(result)
            lock.release()

    for family in object_families.keys():        
        pool.addWork(__work, args=[family])
    
    pool.wait()
    
    return conflicts, taskmodels


class Conflict:
    def __init__(self, baseline, comment):
        self.baseline = baseline
        self._comment = comment

    def comment(self):
        return self._comment


class MultipleObjectInBaselineConflict(Conflict):
    def __init__(self, baseline, objectlist):
        Conflict.__init__(self, baseline, "")        
        self.objectlist = objectlist
        
    def comment(self):
        output = "Multiple objects from the same family found under the baseline (%s).\n" % self.baseline.objectname
        output += "\n".join(lambda x: x.objectname, self.objectlist)
        return output


class ObjectAndBaselineConflict(Conflict):
    def __init__(self, baseline, object, oat):
        Conflict.__init__(self, baseline, "")
        self.object = object
        self.oat = oat
    
    def comment(self):
        pass
    
    
class ObjectNotFoundInBaselineConflict(Conflict):
    def __init__(self, baseline, object):
        Conflict.__init__(self, baseline, "")
        self.object = object
    
    def comment(self):
        return "No object fom '%s' family found under the baseline." % self.object.family


def check_task_and_baseline_conflicts(tasks, baseline):
    """ Validates objects a list of task.
        It returns a list of list of conflicting ObjectAndTask.
    """
    
    object_families = tasks_to_objectandtask(tasks)
    conflicts = []

    for family in object_families:
        result = family[0].session.execute("query \"name='%s' and type='%s' and instance='%s'\" and recursive_is_member_of('%s', none) " % 
                                                        (family[0].name, family[0].type, family[0].instance, baseline.objectname),
                                                        ccm.ObjectListResult(family[0].session))
        if len(result.output) == 1:
            bo = result.output[0]
            potential_conflicts = []
            for oat in family:
                if bo.recursive_predecessor_of(oat.object):
                    potential_conflicts.append(ObjectAndBaselineConflict(baseline, bo, oat, "Conflict between baseline object and task object"))
            if len(family) == len(potential_conflicts):
                conflicts.extend(potential_conflicts)
        elif len(result.output) > 1:
            conflicts.append(MultipleObjectInBaselineConflict(baseline, result.output))
        else:
            conflicts.append(ObjectNotFoundInBaselineConflict(baseline, family[0]))

