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

""" This module defines helper functions to be used in python Ant tasks. """


import logging
import re
import os.path


def get_property(property_name):
    """ This function return None if a property has not been replaced by Ant. """
    if len(property_name) > 0 and (property_name.startswith('${') or property_name.startswith('@{')):
        return None
    return property_name


def get_previous_build_number(build_number):
    """ Determines the previous build number if possible. """
    match = re.match(r'(?P<bn_txt>\w[a-zA-Z0-9_.]*\.)?(?P<bn_num>\d+)', build_number)
    if match != None:
        bn_txt = match.group('bn_txt')
        bn_num = match.group('bn_num')
        try:
            bn_num_int = int(bn_num)
            if bn_num_int > 1:
                previous_bn_num_int = bn_num_int - 1
                previous_bn_num = str(previous_bn_num_int)
                if bn_num.startswith('0'):
                    previous_bn_num = previous_bn_num.rjust(len(bn_num), '0')
                previous_bn = previous_bn_num
                if bn_txt != None:
                    previous_bn = '%s%s' % (bn_txt, previous_bn_num)
                return previous_bn
        except ValueError:
            logging.warning('Parsing of Ant build number failed.')
    return ''
    
    
def get_next_build_number(build_number):
    """ Determines the next build number if possible. """
    match = re.match(r'(?P<bn_txt>\w[a-zA-Z0-9_.]*\.)?(?P<bn_num>\d+)', build_number)
    if match != None:
        bn_txt = match.group('bn_txt')
        bn_num = match.group('bn_num')
        try:
            bn_num_int = int(bn_num)
            previous_bn_num_int = bn_num_int + 1
            previous_bn_num = str(previous_bn_num_int).rjust(len(bn_num), '0')
            previous_bn = previous_bn_num
            if bn_txt != None:
                previous_bn = '%s%s' % (bn_txt, previous_bn_num)
            return previous_bn
        except ValueError:
            logging.warning('Parsing of Ant build number failed.')
    return ''

def get_filesets_content(project, task, elements):
    """ Extract all files selected by the filesets in a script's elements. """
    for eid in range(elements.get("fileset").size()):
        dirscanner = elements.get("fileset").get(int(eid)).getDirectoryScanner(project)
        dirscanner.scan()
        for jfilename in dirscanner.getIncludedFiles():
            filename = str(jfilename)
            task.log("Parsing %s" % filename)
            filename = os.path.join(str(dirscanner.getBasedir()), filename)


class AntHandler(logging.Handler):
    """ Implement a logger hanlder that prints error message using an Ant object.
        See Python documentation on how to use it.
        e.g:
        logging.getLogger("").addHandler(AntHandler(anttask))
        This line will redirect messages to Ant logging system.
    """
    def __init__(self, task, level=logging.NOTSET):
        logging.Handler.__init__(self, level)
        self._task = task
    
    def emit(self, record):
        """ Handle the record using Ant. """
        self._task.log(str(self.format(record)))
