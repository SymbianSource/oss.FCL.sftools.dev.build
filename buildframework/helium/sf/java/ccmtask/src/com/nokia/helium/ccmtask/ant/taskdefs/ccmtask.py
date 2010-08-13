#============================================================================ 
#Name        : ccmtask.py 
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
""" Script to process Ant <ccm> task commands. """

import ccm
import ccm.extra
import sys
import logging
import ant
import string

logging.basicConfig(level=logging.INFO)
antlogger = ant.AntHandler(java_ccmtask)
rlogger = logging.getLogger('')
# replacing default handler by Ant one.
if len(rlogger.handlers) > 0:
    rlogger.removeHandler(rlogger.handlers[0])
rlogger.addHandler(antlogger)
logging.getLogger("ccm").setLevel(logging.INFO)
logger = logging.getLogger("ccm.ant")
session = None

def execute_update(session, command):
    java_ccmtask.log(str('Updating project: ' + command.getProject()))
    project = session.create(command.getProject())
    project.update()

def execute_role(session, command):
    if not command.getRole():
        raise Exception("The 'role' attribute has not been defined.")
    java_ccmtask.log(str('Updating role: ' + command.getRole()))
    session.role = command.getRole()
    
def execute_synchronize(session, command):
    if not command.getProject():
        raise Exception("The 'project' attribute has not been defined.")
    java_ccmtask.log(str('Synchronizing project: ' + command.getProject()))
    java_ccmtask.log(str("Recursive: %s" % command.getRecursive()))
    project = session.create(command.getProject())
    project.sync(command.getRecursive())    
        
def execute_reconcile(session, command):
    if not command.getProject():
        raise Exception("The 'project' attribute has not been defined.")
    java_ccmtask.log(str('Reconciling project: ' + command.getProject()))
    project = session.create(command.getProject())
    project.reconcile()

def execute_snapshot(session, command):
    if not command.getProject():
        raise Exception("The 'project' attribute has not been defined.")
    if not command.getDir():
        raise Exception("The 'dir' attribute has not been defined.")
    java_ccmtask.log(str('Snapshot of project: ' + command.getProject() + ' to ' + command.getDir()))
    project = session.create(command.getProject())
    if command.getFast()== True:
        ccm.extra.FastSnapshot(project, command.getDir())        
    else:
        project.snapshot(command.getDir(), command.getRecursive())

def execute_changereleasetag(session, command):
    if not command.getFolder():
        raise Exception("The 'folder' attribute has not been defined.")
    if not command.getReleaseTag():
        raise Exception("The 'releaseTag' attribute has not been defined.")
    java_ccmtask.log(str('Changing release tag for all tasks in the folder : ' + command.getFolder() + ' as ' + command.getReleaseTag()))
    #Search all task from the folder    
    folder = session.create("Folder " + str(command.getFolder()))
    for task in folder.tasks:
        if task.release != str(command.getReleaseTag()):
            task.release = str(command.getReleaseTag())
            
def execute_checkout(session, command):
    if not command.getProject():
        raise Exception("The 'project' attribute has not been defined.")
    java_ccmtask.log(str('Checking out project: ' + command.getProject() + ' with release tag ' + command.getRelease()))
    project = session.create(command.getProject())
    if (command.getRelease()):
        if command.getWa():
            wa = command.getWa()
        else:
            wa = None
        if command.getRecursive():
            recursive = command.getRecursive()
        else:
            recursive = None
        if command.getRelative():
            relative = command.getRelative()
        else:
            relative = None
        if command.getVersion():
            version = command.getVersion()
        else:
            version = None
        if command.getPurpose():
            purpose = command.getPurpose()
        else:
            purpose = None
        project.checkout(session.create(command.getRelease()), version, purpose, recursive)

def execute_createreleasetag(session, command):
    java_ccmtask.log(str('creating a release tag'))
    if not command.getProject():
        raise Exception("The 'project' attribute has not been defined.")
    project = session.create(command.getProject())
    if (command.getNewTag()):
        new_release_tag = command.getNewTag();
        project.create_release_tag(command.getRelease(), new_release_tag)

def execute_deletereleasetag(session, command):
    java_ccmtask.log(str('deleting a release tag'))
    if not command.getProject():
        raise Exception("The 'project' attribute has not been defined.")
    project = session.create(command.getProject())
    if (command.getNewTag()):
        new_release_tag = command.getNewTag();
        project.delete_release_tag(command.getRelease(), new_release_tag)

def execute_workarea(session, command):
    if not command.getProject():
        raise Exception("The 'project' attribute has not been defined.")
    java_ccmtask.log(str('Modifying work area for the project : ' + command.getProject()))
    project = session.create(command.getProject())
    if command.getMaintain():
        maintain = command.getMaintain()
    else:
        maintain = None
    if command.getRecursive():
        recursive = command.getRecursive()
    else:
        recursive = None
    if command.getRelative():
        relative = command.getRelative()
    else:
        relative = None
    if command.getPath():
        path = command.getPath()
    else:
        path = None
    if command.getPst():
        pst = command.getPst()
    else:
        pst = None
    if command.getWat():
        wat = command.getWat()
    else:
        wat = None
    project.work_area(maintain, recursive, relative, path, pst, wat)

def execute_addtask(session, command):
    if command.getFolder() != None:
        tasks = []        
        ccmfolder = session.create("Folder " + command.getFolder())
        role = find_folder_information(session, command)
        if role == "build_mgr":
            java_ccmtask.log("Changing role to %s" % role)
            session.role = "build_mgr"

        folder = session.create("Folder %s" % str(command.getFolder()))
        for task in folder.tasks:
            folder.remove(task)
        
        java_ccmtask.log("Adding task to folder %s" % ccmfolder)
        tasks.extend(map(lambda task: session.create("Task " + task.getName()), command.getTasks()))
        for task in tasks:
            ccmfolder.append(task)
    
def find_folder_information(session, command):
    cmdline = "folder -sh i " + command.getFolder()    
    result = session.execute(cmdline)
    result_array = str(result).split('\r')
    for ldata in result_array :        
        if ldata.find('Writable By:') > 0:
            wb,wd = ldata.split(':',1)
            if wd.lstrip() == "Build Manager":
                return "build_mgr"
            else:
                return "developer"

def execute_exists(session, command):
    fpn = None
    if command.getObject() != None:
        fpn = command.getObject()
    elif command.getFolder() != None:
		fpn = "Folder " + command.getFolder()
    elif command.getTask() != None:
		fpn = "Task " + command.getTask()

    if fpn == None:
        raise Exception("You need to define either a 'task'/'folder'/'object' attribute.")
    ccmo = session.create(fpn)
    if ccmo.exists():
        java_ccmtask.log("'%s' exists." % ccmo)
    else:
        raise Exception("Could not find '%s'." % ccmo)

def execute_close(session, command):
    java_ccmtask.log(str("Closing session %s." % str(session)))
    if hasattr(session, 'close_on_exit'):
        session.close_on_exit = True    
    session.close()
    
def referenceToObject(obj):
    if obj.isReference() == 1:
        ref = project.getReference(str(obj.getRefid().getRefId()))
        if ref == None:
            raise Exception("Could not find reference '%s'" % str(obj.getRefid().getRefId()))
        return ref
    else:
        return obj        
        
sessionIds = [] 
for session_set in java_ccmtask.getSessionSets():
    sessionIds.extend(map(lambda session: session.getAddr(), referenceToObject(session_set).getSessions()))

print "Session list: ", sessionIds
if len(sessionIds) > 0:
    sessionid = sessionIds.pop()
    session = ccm.Session(username=None, engine=None, dbpath=None, ccm_addr=sessionid, close_on_exit=False)
else:
    username = java_ccmtask.getUsername()
    password = java_ccmtask.getPassword()
    session = ccm.open_session(username=username, password=password)

if java_ccmtask.getVerbose() == 1:
    logging.getLogger("ccm").setLevel(logging.DEBUG)

#print dir(sys.modules['__main__'] )
ccm_commands = java_ccmtask.getCommands()
for command in ccm_commands:
    print "Running command '%s'" % command.getName()
    method_name = 'execute_' + command.getName()
    method = sys.modules['__main__'].__dict__[method_name]
    try:
        method(session, command)
    except Exception, e:
        if java_ccmtask.getVerbose() == 1:
            import traceback
            logger.error(traceback.print_exc(file=sys.stdout))
            if 'result' in e:
                logger.error(e.result)
        logger.error(e)
        raise e
