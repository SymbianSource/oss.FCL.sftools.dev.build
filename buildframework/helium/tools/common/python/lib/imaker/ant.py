#============================================================================ 
#Name        : ant.py 
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

"""
    iMaker related functionalities.
    * configuration introspection
    * target introspection 
"""
import os
import pathaddition.match
import re
import fileutils
import imaker.api

def ant_run(task, config, target, variables=None):
    """ Running iMaker under Ant. """
    if variables == None:
        variables = {}
    cmdline = "imaker"
    cmdline += " -f %s" % config
    cmdline += " %s" % target    
    for key in  variables.keys():
        cmdline += ' "%s=%s"' % (key, variables[key])
    # run imaker and log to Ant.
    task.log("Running %s" % cmdline)
    handle = os.popen(cmdline)
    for line in handle.read().splitlines():
        task.log(line)
    return handle.close()


def is_included(incs, target):
    """ Does target matches an include pattern. """
    for inc in incs:
        if inc.match(target):
            return True
    return False

def is_excluded(excs, target):
    """ Does target matches an exclude pattern. """
    for exc in excs:
        if exc.match(target):
            return True
    return False
        

def ant_task_configuration(project, task, elements, attributes):
    """ Implementation of the Ant task. """
    # assert attributes.get('property') != None, "'property' attribute is not defined."
    configIndex = 0
    if attributes.get('dir') != None:
        os.chdir(str(attributes.get('dir')))
    tdd = "[\n"
    if elements.get("imakerconfigurationset") is not None:
        if elements.get("imakerconfigurationset").size() == 0:
            task.log(str("No configuration defined."))
        for cid in range(elements.get("imakerconfigurationset").size()):
            configurationset = elements.get("imakerconfigurationset").get(int(cid))            
            if configurationset.isReference() == 1:
                task.log("Using configuration from reference '%s'." % str(configurationset.getRefid().getRefId()))
                ref = project.getReference(str(configurationset.getRefid().getRefId()))
                if ref == None:
                    raise Exception("Could not find reference '%s'" % str(configurationset.getRefid().getRefId()))
                configurationset = ref            
            for configuration in configurationset.getImakerConfiguration().toArray():
                configIndex += 1
                tdd += handle_configuration(project, task, elements, attributes, configuration, configIndex)
    else:
        task.log(str("No configuration defined."))
    tdd += "]\n"
    
    if attributes.get('property') != None:
        task.log("Setting property '%s'." % str(attributes.get('property')))
        project.setProperty(str(attributes.get('property')), str(tdd))
    if attributes.get('file') != None:
        task.log("Creating file '%s'." % str(attributes.get('file')))
        out = open(str(attributes.get('file')), "w")
        out.write(tdd)
        out.close()
        
def handle_configuration(project, task, elements, attributes, configuration,  configIndex):
    """ Convert a configuration into a TDD for future FMPP transformation. """
    includes = []
    excludes = []
    tincludes = []
    texcludes = []
    variables = {}
    
    for configs in configuration.getMakefileSet().toArray():
        incs = configs.getIncludePatterns(project)
        if incs is not None:
            for inc in incs:
                includes.append(str(inc))
        excs = configs.getExcludePatterns(project)
        if excs is not None:
            for exc in excs:
                excludes.append(str(exc))
    if len(includes)==0:
        task.log("WARNING: config %s has no makefile and hence not executed" % configIndex)
        
    
    for targets in configuration.getTargetSet().toArray():
        incs = targets.getIncludePatterns(project)
        if incs is not None:
            for inc in incs:
                tincludes.append(re.compile(str(inc)))
        excs = targets.getExcludePatterns(project)
        if excs is not None:
            for exc in excs:
                texcludes.append(re.compile(str(exc)))
    if len(tincludes) == 0:
        tincludes.append(re.compile(r".*"))
    
    # Reading the variables
    for variableset in configuration.getVariableSet().toArray():
        vector = variableset.getVariables()
        for variable in vector.toArray():
            variables[str(variable.getName())] = str(variable.getValue())

    configs = imaker.api.scan_configs(includes, excludes)
    targets = {}
    for config in configs:
        task.log("Configuration: %s" % config)
        if config not in targets:
            targets[config] = []
        for target in imaker.api.targets_for_config(config):
            if is_included(tincludes, target) and not is_excluded(texcludes, target)\
                    and target not in targets[config]:
                targets[config].append(target)

    task.log(str("Regional variation: %s" % configuration.getRegionalVariation()))
    if configuration.getRegionalVariation():
        task.log("Sorting target by region.")
        regiontargets = {}
        for config in targets.keys():
            task.log(" * %s:" % config)
            for target in targets[config]:
                region = imaker.api.get_variable('LANGPACK_REGION', target=target, config=config, default="western")                
                task.log("    - %s: %s" % (target, region))
                if not regiontargets.has_key(region):
                    regiontargets[region] = {}
                if not regiontargets[region].has_key(config):
                    regiontargets[region][config] = []
                regiontargets[region][config].append(target)                
            # sort by region
        tdd = ""
        for region in regiontargets.keys():
            tdd += region_switch_to_tdd(region)
            tdd += imaker_command_to_tdd(regiontargets[region], variables)
        return tdd

    # generating the TDD
    return imaker_command_to_tdd(targets, variables)


def region_switch_to_tdd(region):
    tdd = "{\n"
    tdd += "\t\"command\": \"switch_region\",\n"
    tdd += "\t\"region\": \"%s\",\n" % region
    tdd += "},\n"
    return tdd
    

def imaker_command_to_tdd(targets, variables):
    # generating the TDD
    tdd = "{\n"
    tdd += "\t\"command\": \"imaker\",\n"
    tdd += "\t\"config\": {\n"
    for config in targets.keys():
        tdd += "\t\t\"%s\": [\n" % config
        for target in targets[config]:
            tdd += "\t\t\t{\n"
            tdd += "\t\t\t\"target\": \"%s\",\n" % target
            tdd += "\t\t\t\"variables\": {\n"
            for varname in variables.keys():
                tdd += "\t\t\t\t\"%s\": \"%s\",\n" % (varname, variables[varname])  
            tdd += "\t\t\t\t},\n"
            tdd += "\t\t\t},\n"
        tdd += "\t\t],\n"
    tdd += "\t},\n"
    tdd += "},\n"
    return tdd
    
