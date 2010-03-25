#============================================================================ 
#Name        : rom.py 
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

""" This modules implements rombuilders.
"""
import logging
import re

# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("rom")


def read_file_content(filename):
    """ Read the whole file content.
    """
    ftr = open(filename, "r")
    content = ftr.read()
    ftr.close()
    return content

def escape_string(string, config):
    """ Escape a string recursively.
    """
    #data = escapeddict.EscapedDict(config)
    #string = re.sub(r'\${(?P<name>[._a-zA-Z0-9]+)}', r'%(\g<name>)s', string)
    #return string % data
    return config.interpolate(string)

def get_makefile_target(text):
    """ Retrieve the target name of a step
    """
    result = re.search(r"^(?P<target>.+?)\s*:", text, re.M)
    if (result != None):
        return result.groupdict()['target']
    raise Exception("Could'nt determine target name")

    

