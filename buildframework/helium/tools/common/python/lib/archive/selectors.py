#============================================================================ 
#Name        : selectors.py 
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

import re
import os
import sys
import logging
import fileutils
import archive

# Getting logger for the module
logger = logging.getLogger("archive.selectors")


class DistributionPolicySelector:
    """ A selector that selects files based on other criteria.
    
    It is similar to the Ant file selector objects in design. This one selects files
    based on whether the root-most Distribution.Policy.S60 file matches the given value.
    """
    
    def __init__(self, policy_files, value, ignoremissingpolicyfiles=False):
        """ Initialization. """
        self._negate = False
        self.values = [v.strip() for v in value.split() if v.strip()!=""]
        self._policy_files = policy_files
        self._ignoremissingpolicyfiles = ignoremissingpolicyfiles

    def get_value_and_negate(self, value):
        if value.startswith('!'):
            return (value[1:], True)
        return (value, False)
        
    def is_selected(self, path):
        """ Determines if the path is selected by this selector. """
        current_dir = os.path.abspath(os.path.dirname(path))
        logger.debug('is_selected: current dir = ' + current_dir + '  ' + str(os.path.exists(current_dir)))
        result = False
        policy_file = None
        # finding the distribution policy from the filelist.
        for filename in self._policy_files:
            #slow method on case sensitive system
            if os.sep != '\\':
                for f in os.listdir(current_dir):
                    if f.lower() == filename.lower():
                        policy_file = os.path.join(current_dir, f)
                        break
            elif os.path.exists(os.path.join(current_dir, filename)):            
                policy_file = os.path.join(current_dir, filename)
                logger.debug('Using Policy file: ' + policy_file)
                break

        policy_value = None
        if policy_file is None:
            if not self._ignoremissingpolicyfiles:
                logger.error("POLICY_ERROR: Policy file not found under '%s' using names [%s]" % (current_dir, ", ".join(self._policy_files)))
            policy_value = archive.mappers.MISSING_POLICY
        else:
            try:
                policy_value = fileutils.read_policy_content(policy_file)
            except Exception:
                logger.warning('POLICY_ERROR: Exception thrown parsing policy file: ' + policy_file)
                policy_value = archive.mappers.MISSING_POLICY
        # loop through the possible values
        for value in self.values:
            (val, negate) = self.get_value_and_negate(value)
            logger.debug('Policy value: ' + str(policy_value) + '  ' + val)
            if (not negate and policy_value == val) or (negate and policy_value != val):
                return True
        return False


class SymbianPolicySelector:
    """ A selector that selects files based on other criteria.
    
    It is similar to the Ant file selector objects in design. This one selects files
    based on whether the root-most distribution.policy file matches the given value.
    """
    
    def __init__(self, policy_files, value):
        """ Initialization. """
        self._negate = False
        self.values = [v.strip() for v in value.split() if v.strip()!=""]
        self._policy_files = policy_files
               

    def get_value_and_negate(self, value):
        if value.startswith('!'):
            return (value[1:], True)
        return (value, False)
        
    def is_selected(self, path):
        """ Determines if the path is selected by this selector. """
        current_dir = os.path.abspath(os.path.dirname(path))
        logger.debug('is_selected: current dir = ' + current_dir + '  ' + str(os.path.exists(current_dir)))
        result = False
        policy_file = None
        # finding the distribution policy from the filelist.
        for filename in self._policy_files:
            if os.sep != '\\':
                for f in os.listdir(current_dir):
                    if f.lower() == filename.lower():
                        policy_file = os.path.join(current_dir, f)
                        logger.debug('Using Policy file: ' + policy_file)
                        break
            elif os.path.exists(os.path.join(current_dir, filename)):            
                policy_file = os.path.join(current_dir, filename)
                logger.debug('Using Policy file: ' + policy_file)
                break

        policy_value = None
        if policy_file is  None:
            logger.error("POLICY_ERROR: Policy file not found under '%s' using names [%s]" % (current_dir, ", ".join(self._policy_files)))
            policy_value = archive.mappers.MISSING_POLICY
        else:
            try:
                policy_value = fileutils.read_symbian_policy_content(policy_file)
            except Exception:
                logger.warning('POLICY_ERROR: Exception thrown parsing policy file: ' + policy_file)
                policy_value = archive.mappers.MISSING_POLICY
        # loop through the possible values
        for value in self.values:
            (val, negate) = self.get_value_and_negate(value)
            logger.debug('Policy value: ' + str(policy_value) + '  ' + val)
            if (not negate and policy_value == val) or (negate and policy_value != val):
                return True
        return False

SELECTORS = {'policy': lambda config: DistributionPolicySelector(config.get_list('policy.filenames', ['Distribution.Policy.S60']), config['policy.value']),
               'symbian.policy': lambda config: SymbianPolicySelector(config.get_list('policy.filenames', ['distribution.policy']), config['policy.value']),
             'distribution.policy.s60': lambda config: DistributionPolicySelector(['Distribution.Policy.S60'], config['distribution.policy.s60'], config['ignore.missing.policyfiles'] == 'true'),
             }

def get_selector(name, config):
    if not 'ignore.missing.policyfiles' in config:
        config['ignore.missing.policyfiles'] = 'false'
    return SELECTORS[name](config)
