#============================================================================ 
#Name        : api.py 
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

""" This module is an helper to interface iMaker. """
import os
import re
import fileutils
import tempfile
import logging
import subprocess

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("imaker.api")

class IMakerConfigScanner(fileutils.AbstractScanner):
    """ Specialize the abstract filescanner to support detection of the configuration. """
    def scan(self):
        """ Implement scanning of relevant configuration. """
        p = subprocess.Popen("imaker help-config", shell=True, stdout=subprocess.PIPE)
        handle = p.communicate()[0]
        for line in handle.splitlines():
            line = line.strip()
            if line.startswith('/') and self.is_included(line) \
                and not self.is_excluded(line):
                yield line
        
def scan_configs(includes, excludes):
    """ Use iMaker to scan the available buildable configurations. """
    scanner = IMakerConfigScanner()
    for inc in includes:
        scanner.add_include(inc)
    for exc in excludes:
        scanner.add_exclude(exc)
    return [r for r in scanner.scan()]

def targets_for_config(config):
    """ Return the list of target supported by the provided configuration of iMaker. """
    cmd = "imaker -f %s help-target-*-list" % config
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    handle = p.communicate()[0]
    result = []
    for line in handle.splitlines():
        line = line.strip()
        if line == "" or line.startswith("Total duration"):
            continue
        result.append(line)
    return result


def get_product_dir(product):
    """ Return the PRODUCT_DIR variable from iMaker. """
    return get_variable("PRODUCT_DIR", product=product)

    
def get_variable(variable, target=None, product=None, config=None, default=None):
    """ Get variable value from iMaker. """
    cmdline = ""
    if product != None:
        cmdline = "-p%s" % product
    if config != None:
        cmdline += " -f %s" % config
    if target != None:
        cmdline += " %s" % target
    
    logdir = tempfile.mkdtemp()
    logger.info("imaker %s print-%s WORKDIR=%s" % (cmdline, variable, logdir))
    (_, handle, child_stderr) = os.popen3("imaker %s print-%s WORKDIR=%s" % (cmdline, variable, logdir))
    logger.info(child_stderr.read())
    result = []
    for line in handle.read().splitlines():
        line = line.strip()
        if line == "" or line.startswith("Total duration"):
            continue
        if variable in line:
            result.append(line)
    handle.close()
    result = re.match("%s\s*=\s*`(.*)'" % variable, "\n".join(result), re.DOTALL)
    if result != None:
        return result.group(1)
    assert (result != None)
    return default
