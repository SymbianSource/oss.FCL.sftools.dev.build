#============================================================================ 
#Name        : relative.py 
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
    Additional path functionnality.
    abs2rel
    rel2abs
"""
import os
import os.path
import re

# matches http:// and ftp:// and mailto://
_protocolPattern = re.compile(r'^\w+://')

def isabs(string):
    """ 
    
    @return true if string is an absolute path or protocoladdress
    for addresses beginning in http:// or ftp:// or ldap:// - 
    they are considered "absolute" paths.
    """
    if _protocolPattern.match(string): 
        return True
    return os.path.isabs(string)

def rel2abs(path, base = None):
    """ converts a relative path to an absolute path.

    @param path the path to convert - if already absolute, is returned
    without conversion.
    @param base - optional. Defaults to the current directory.
    The base is intelligently concatenated to the given relative path.
    @return the relative path of path from base
    """
    if isabs(path):
        return path
    if base is None:
        base = os.curdir
    retval = os.path.join(base, path)
    return os.path.abspath(retval)
    

def pathsplit(p_spath, rest=None):
    """ Split path to pieces """
    if rest is None:
        rest = []
    (h_folder, t_file) = os.path.split(p_spath)
    if len(h_folder) < 1: 
        return [t_file]+rest
    if len(t_file) < 1: 
        return [h_folder]+rest
    return pathsplit(h_folder, [t_file]+rest)

def commonpath(l_1, l_2, common=None):
    """ return the common path"""
    if common is None:
        common = []
    if len(l_1) < 1:
        return (common, l_1, l_2)
    if len(l_2) < 1:
        return (common, l_1, l_2)
    if l_1[0] != l_2[0]:
        return (common, l_1, l_2)
    return commonpath(l_1[1:], l_2[1:], common+[l_1[0]])


def relpath(p_1, p_2):
    """relative path"""
    (_, l_1, l_2) = commonpath(pathsplit(p_1), pathsplit(p_2))
    p_path = []
    if len(l_1) > 0:
        p_path = [ '../' * len(l_1) ]
    p_path = p_path + l_2
    if len(p_path) is 0:
        return "."
    return os.path.join( *p_path )


def abs2rel(path, base = None):
    """ @return a relative path from base to path.
    
    base can be absolute, or relative to curdir, or defaults
    to curdir.
    """
    if _protocolPattern.match(path):
        return path
    if base is None:
        base = os.curdir
    base = rel2abs(base)
    path = rel2abs(path) # redundant - should already be absolute
    return relpath(base, path)


def commonprefix(paths):
    """ 
    Returns the common prefix base on the path components.
    """
    if len(paths) == 0:
        return ''
    if len(paths) == 1:
        return paths[0]

    def _commonprefix_internal(p_1, p_2):
        """common prefix internal"""
        c_path = commonpath(pathsplit(p_1), pathsplit(p_2))[0]
        if len(c_path) == 0:
            return ''
        return os.path.join(*c_path)
    common = _commonprefix_internal(paths[0], paths[1])
    for p_path in paths[2:]:
        common = _commonprefix_internal(common, p_path)
    return common
