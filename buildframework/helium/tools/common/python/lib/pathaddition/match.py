#============================================================================ 
#Name        : match.py 
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

""" This module provides support for Ant-style wildcards,
    which are not the same as regular expressions (which are documented in the re module).
"""
import os
import pathaddition.relative
import logging
import fnmatch
import re
import sys

_logger = logging.getLogger('path.match')
#logging.basicConfig()

# local regular expression cache.
_cache = {}

def ant_match(name, pattern, casesensitive=True):
    """Check if name matches pattern (Ant-style wildcards).
    """
    _logger.debug("ant_match: path='%s' pattern='%s'" % (name, pattern))
    if pattern.endswith('/') or pattern.endswith('\\'):
        pattern = pattern + '**'
        _logger.debug("ant_match: pattern ending with / or \ pattern='%s'" % (pattern))
    name = os.path.normpath(name)
    pattern = os.path.normpath(pattern)
    name = name.replace('/', os.sep)
    name = name.replace('\\', os.sep)
    pattern = pattern.replace('/', os.sep)
    pattern = pattern.replace('\\', os.sep)
    _logger.debug("ant_match:normpath: path='%s' pattern='%s'" % (name, pattern))
    
    if not _cache.has_key(pattern):
        res = translate(pattern)
        _logger.debug("ant_match: regexp=%s" % (res))
        if os.sep == '\\' or not casesensitive:
            _cache[pattern] = re.compile(res, re.I)
        else:
            _cache[pattern] = re.compile(res)
    return _cache[pattern].match(name) is not None


def translate(pat):
    """Translate a Ant-style PATTERN to a regular expression.

    There is no way to quote meta-characters.
    """

    i, n = 0, len(pat)
    res = ''
    while i < n:
        c = pat[i]
        i = i+1
        if c == '*':
            # identifying a **
            if i < len(pat) and pat[i] == '*':
                res = res + "(?:(?:^|%s)[^%s]+)*(?:^|%s|$)" % (os.sep.replace('\\','\\\\'), os.sep.replace('\\','\\\\'), os.sep.replace('\\','\\\\'))
                i = i+1
                # skipping next \ or / 
                if i < len(pat) and pat[i] == os.sep:
                    i = i+1
            else:
                res = res + '[^%s]*' % os.sep.replace('\\','\\\\')
        elif c == '?':
            res = res + '[^%s]*' % os.sep.replace('\\','\\\\')
        elif c == '[':
            j = i
            if j < n and pat[j] == '!':
                j = j+1
            if j < n and pat[j] == ']':
                j = j+1
            while j < n and pat[j] != ']':
                j = j+1
            if j >= n:
                res = res + '\\['
            else:
                stuff = pat[i:j].replace('\\','\\\\')
                i = j+1
                if stuff[0] == '!':
                    stuff = '^' + stuff[1:]
                elif stuff[0] == '^':
                    stuff = '\\' + stuff
                res = '%s[%s]' % (res, stuff)
        else:
            
            if c == os.sep and i+2 <= len(pat) and pat[i] == "*" and pat[i+1] == "*":
#                res = res + "?"
                pass
            else:
                res = res + re.escape(c)
    return res + "$"

