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
protocolPattern = re.compile(r'^\w+://')

def isabs(string):
    """ 
    
    @return true if string is an absolute path or protocoladdress
    for addresses beginning in http:// or ftp:// or ldap:// - 
    they are considered "absolute" paths.
    """
    if protocolPattern.match(string): 
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
    

def pathsplit(p, rest=None):
    """ Split path to pieces """
    if rest is None:
        rest = []
    (h, t) = os.path.split(p)
    if len(h) < 1: 
        return [t]+rest
    if len(t) < 1: 
        return [h]+rest
    return pathsplit(h, [t]+rest)

def commonpath(l1, l2, common=None):
    """ return the common path"""
    if common is None:
        common = []
    if len(l1) < 1:
        return (common, l1, l2)
    if len(l2) < 1:
        return (common, l1, l2)
    if l1[0] != l2[0]:
        return (common, l1, l2)
    return commonpath(l1[1:], l2[1:], common+[l1[0]])


def relpath(p1, p2):
    (common, l1, l2) = commonpath(pathsplit(p1), pathsplit(p2))
    p = []
    if len(l1) > 0:
        p = [ '../' * len(l1) ]
    p = p + l2
    if len(p) is 0:
        return "."
    return os.path.join( *p )
    
    
def abs2rel(path, base = None):
    """ @return a relative path from base to path.
    
    base can be absolute, or relative to curdir, or defaults
    to curdir.
    """
    if protocolPattern.match(path):
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

    def _commonprefix_internal(p1, p2):
        c = commonpath(pathsplit(p1), pathsplit(p2))[0]
        if len(c) == 0:
            return ''
        return os.path.join(*c)
    common = _commonprefix_internal(paths[0], paths[1])
    for p in paths[2:]:
        common = _commonprefix_internal(common, p)
    return common

    