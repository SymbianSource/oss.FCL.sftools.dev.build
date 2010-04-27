#============================================================================ 
#Name        : gscm.py 
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

""" Wrapper module that get CCM info using GSCM framework. """


import logging
import os
import subprocess
import pkg_resources
import tempfile

# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger("gscm")


def _execute(command):
    """ Runs a command and returns the result data. """
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output = process.stdout.read()
    process.poll()
    status = process.returncode
    return (output, status)


def __get_gscm_info(method, dbname):
    """ Generic method that call function 'method' on GSCM wrapper script. """
    (fd, filename) = tempfile.mkstemp()
    f = os.fdopen(fd, 'w')
    f.write(pkg_resources.resource_string(__name__, "get_gscm_info.pl"))# pylint: disable-msg=E1101
    f.close()
    command = "perl " + filename
    command += " %s %s" % (method, dbname)    
    _logger.debug("Running command: %s" % command)
    (output, status) = _execute(command)
    _logger.debug("Status: %s" % status)
    _logger.debug("Output: %s" % output)
    if status == 0 or status == None and not ("Can't locate" in output):
        return output.strip()
    if not 'HLM_SUBCON' in os.environ:
        raise Exception("Error retrieving get_db_path info for '%s' database.\nOUTPUT:%s" % (dbname, output.strip()))
    return None

def get_db_path(dbname):
    """ Returns the database path for dbname database. """
    _logger.debug("get_db_path: %s" % dbname)
    return __get_gscm_info('get_db_path', dbname)


def get_router_address(dbname):
    """ Returns the database router address for dbname database. """
    _logger.debug("get_router_address: %s" % dbname)
    return __get_gscm_info('get_router_address', dbname)


def get_engine_host(dbname):
    """ Returns the database engine host for dbname database. """
    _logger.debug("get_engine_host: %s" % dbname)
    return __get_gscm_info('get_engine_host', dbname)
