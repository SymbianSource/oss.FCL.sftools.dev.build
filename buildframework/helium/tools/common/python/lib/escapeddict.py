#============================================================================ 
#Name        : escapeddict.py 
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

""" This class enables developer to use ${xxx} pattern in their dict and 
    get them replaced recursively.
"""
import re
import types
import UserDict


class _CustomArray(list):
    """ Internal class
    """
    def __str__(self):
        string = ""
        for elem in self:
            string += " "+elem
        return string


class EscapedDict(UserDict.UserDict):
    """ Implements a dictionary that escapes the key values recursively. """        
    
    def __init__(self, dict={}, failonerror=False):
        UserDict.UserDict.__init__(self, dict)
        self.__failonerror = failonerror
        
    def __getitem__(self, key):
        """ Overrides the usual __getitem__ to insert values of other keys referenced in this key's
        value. """
        if key in self.data:
            value = self.data[key]
            result = value
            if isinstance(value, types.ListType):
                result = _CustomArray()
                for elem in value:
                    (string, changes) = re.subn(r'\${(?P<name>[._a-zA-Z0-9]+)}', r'%(\g<name>)s', elem)
                    if changes > 0:
                        result.append(string % self)
                    else:
                        result.append(elem)
            else:
                (string, changes) = re.subn(r'\${(?P<name>[._a-zA-Z0-9]+)}', r'%(\g<name>)s', value)
                if changes > 0:
                    result = string % self
            return result
        elif not self.__failonerror:
            return "${%s}" % key
        raise KeyError("Could not find key '%s'" % key)
        


def escapeString(input_string, config):
    """ Escape a string recursively.
    
    :param input_string: the string to be escaped.
    :param config: a dictionnary containing the values to escape.
    :return: the escaped string.
    """
    data = EscapedDict(config)
    match = re.search(r'\${(?P<name>[._a-zA-Z0-9]+)}', input_string)
    if match != None:
        for property_name in match.groups():
            property_value = data[property_name]
            property_value = re.sub(r'\\', r'\\\\', property_value)
            input_string = re.sub('\${' + property_name + '}', property_value, input_string)
    return input_string

        
