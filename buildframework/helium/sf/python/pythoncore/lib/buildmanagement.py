#============================================================================ 
#Name        : buildmanagement.py 
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

""" BuildManagement module """

import logging
import types

import ccm
import configuration
import nokia.nokiaccm


# Uncomment this line to enable logging in this module, or configure logging elsewhere
logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger("buildmanagement")

def buildmanager(synergyhost, databasepath, configfile, specname):
    """ Buildmanager  """
    _logger.debug("Start buildmanger")
    session = None
    session = nokia.nokiaccm.open_session(engine=synergyhost, dbpath=databasepath)
    print ('session = %s', session)
    session.role = "build_mgr"
    configBuilder = configuration.NestedConfigurationBuilder(open(configfile, 'r'))
    configSet = configBuilder.getConfiguration()
    _logger.debug('Getting configuration: "' + specname + '" from: "' + configfile + '"')
    configs = configSet.getConfigurations(specname)
    for config in configs:
        for k in sorted(config.keys()):
            value = config[k]
            if isinstance(value, types.UnicodeType):
                value = value.encode('ascii', 'ignore')
            #_logger.debug( k + ': ' + str(value))
        _logger.debug(config['function.name'])
        result = eval(config['function.name'])(session, config)
        _logger.debug("got result:" + result) 
    _logger.debug('Finished parsing configs')
    session.close()
    del(session)

def add_approved_tasks(session, config):
    """ add approved tasks to be updated to project """
    _logger.debug("Start adding approved tasks")
    #this assumes there is only one folder in the reconfigure properties:
    if config['project.release.folder'] == "automatic":
        toplevelproject = ccm.Project(session, config['project.four.part.name'])
        releasefolders = toplevelproject.folders
        releasefolder = releasefolders[0]
        _logger.debug("Release folder found from rp is: " + releasefolder.name)
    else:
        releasefolder = ccm.Folder(session, config['project.release.folder'])

    folderlist = force_list(config['project.approval.folders'])

    for approvalfolderfpn in folderlist:
        approvalfolder = ccm.Folder(session, approvalfolderfpn)
        _logger.debug("Copying tasks from folder " + approvalfolder.name + ", to folder " + releasefolder.name)
        approvalfolder.copy(releasefolder)
        
    _logger.debug("Finished adding approved tasks")
    
def reconcile(session, config):
    """ reconcile """
    _logger.debug("Start reconciling: " + config['project.four.part.name'])
    toplevelproject = ccm.Project(session, config['project.four.part.name'])
    toplevelproject.reconcile(updatewa=True, recurse=True, consideruncontrolled=True, missingwafile=True, report=True)
    _logger.debug("Finished reconciling: " + config['project.four.part.name'])
    
def set_latest_baseline(session, config):
    """ Setting latest baseline """
    _logger.debug("Start updating the baseline of: " + config['project.name'])
    toplevelproject = ccm.Project(session, config['project.four.part.name'])
    latestbaseline = toplevelproject.get_latest_baseline(config['project.version.filter'], config['project.baseline.state'])
    _logger.debug("Using: " + latestbaseline)
    toplevelproject.set_baseline(latestbaseline, recurse=True)
    _logger.debug("Finished updating the baseline of: " + config['project.name'])

def reconfigure(session, config):
    """ recongifure """
    _logger.debug("Start reconfiguring: " + config['project.four.part.name'])
    toplevelproject = ccm.Project(session, config['project.four.part.name'])
    replacesubprojects = config.get_boolean('replace.subprojects', True)
    recursesubprojects = config.get_boolean('recurse.subprojects', True)
    updatekeepgoing = not config.get_boolean('update.failonerror', True)
    toplevelproject.update(recursesubprojects, replacesubprojects, updatekeepgoing)
    _logger.debug("Finished reconfiguring: " + config['project.four.part.name'])
    
def update_release_tags(session, config):
    """ update release tags """
    _logger.debug("Start updating release tags in folder: " + config['project.release.folder'])
    if config['project.release.folder'] == "automatic":
        toplevelproject = ccm.Project(session, config['project.four.part.name'])
        releasefolders = toplevelproject.folders
        releasefolder = releasefolders[0]
        _logger.debug("Release folder found from rp is: " + releasefolder.name)
    else:
        releasefolder = ccm.Folder(session, config['project.release.folder'])
    for task in releasefolder.tasks:
        if str(task.get_release_tag()).strip() == config['task.release.tag.from']:
            _logger.debug("Changing release tag of %s to %s" % (task.name, config['task.release.tag.to']))
            task.set_release_tag(config['task.release.tag.to'])
    _logger.debug("Finished updating release tags in folder: " + config['project.release.folder'])
    
def create_baseline(session, config):
    """ Create baseline """
    _logger.debug("Start creating the baseline(s): " + config['project.name'] + "-" + config['baseline.tag'])
    project = ccm.Project(session, config['project.four.part.name'])
    _logger.debug("Project: " + project.name)
    project.create_baseline(config['project.name'] + "-" + config['baseline.tag'], config['project.release.tag'], config['baseline.tag'], config['baseline.purpose'], config['baseline.state'])
    _logger.debug("Finished creating the baseline: " + config['project.name'] + "-" + config['baseline.tag'])

def force_list(myobject):
    """ force list of objects """
    if isinstance(myobject, list):
        return myobject
    else:
        return [myobject]