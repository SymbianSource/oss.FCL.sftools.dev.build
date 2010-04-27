#============================================================================ 
#Name        : quality.py 
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
Symbian log based analyser.

 * Internal export parser
 * Duplicate generation parser (relying on abld -what)

Policy validation.
"""

import symbian.log
import re
import os
import csv
import fileutils
import pathaddition.match
import logging

#logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger("integration.quality")

class InternalExportParser(symbian.log.Parser):
    """ This class extends the Symbian log parser class and implement
        an "abld -what" analyser which detects file generated/exported inside
        the source tree.
    """
    def __init__(self, _file):
        """The constructor """
        symbian.log.Parser.__init__(self, _file)
        self.__match_what = re.compile("abld(\.bat)?(\s+.*)*\s+-(check)?w(hat)?", re.I)
        self.internalexports = {}
        
    def task(self, name, _cmd, _dir, content):
        """ Analyse task log. """
        if self.__match_what.match(_cmd) != None:
            for line in content.splitlines():
                if line.startswith(os.path.sep) \
                    and not os.path.normpath(line.strip().lower()).startswith(os.path.sep+"epoc32"+os.path.sep) \
                    and os.path.splitext(line.strip().lower())[1] != '':
                    if name not in self.internalexports:
                        self.internalexports[name] = []
                    self.internalexports[name].append(line)


class AbldWhatParser(symbian.log.Parser):
    """ This class extends the Symbian log parser class and implement
        an "abld -what" analyser which sort the generated files by component. 
    """
    def __init__(self, _file):
        """The constructor """
        symbian.log.Parser.__init__(self, _file)
        self.__match_what = re.compile(r"abld(\.bat)?(\s+.*)*\s+-(check)?w(hat)?", re.I)
        self.__match_cmaker_what = re.compile(r"cmaker(\.cmd)?(\s+.*)*\s+ACTION=what", re.I)
        self.files_per_component = {}
        self.components_per_file = {}
        
    def task(self, name, _cmd, _dir, content):
        """ Analyse task log. """
        if _cmd != None and self.__match_what.match(_cmd) != None:
            for line in content.splitlines():
                line = line.strip()
                if not os.path.normpath(line).startswith(os.path.sep):
                    continue
                # component per file
                if line.lower() not in self.components_per_file:
                    self.components_per_file[line.lower()] = []
                if name not in self.components_per_file[line.lower()]:
                    self.components_per_file[line.lower()].append(name)

                # file per components
                if name not in self.files_per_component:
                    self.files_per_component[name] = []
                self.files_per_component[name].append(line)
        elif _cmd != None and self.__match_cmaker_what.match(_cmd) != None:
            for line in content.splitlines():
                line = line.strip()
                if not line.startswith('"'):
                    continue
                if not line.endswith('"'):
                    continue
                line = os.path.normpath(line.strip('"')).lower()
                # component per file
                if line not in self.components_per_file:
                    self.components_per_file[line] = []
                if name not in self.components_per_file[line]:
                    self.components_per_file[line].append(name)
            
                # file per components
                if name not in self.files_per_component:
                    self.files_per_component[name] = []
                self.files_per_component[name].append(line)


class PolicyValidator(object):
    """ Validate policy files on a hierarchy. """    
    def __init__(self, policyfiles=None, csvfile=None, ignoreroot=False):
        """The constructor """
        if policyfiles is None:
            policyfiles = ['distribution.policy.s60']
        self._policyfiles = policyfiles
        self._ids = None
        self._ignoreroot = ignoreroot

    def load_policy_ids(self, csvfile):
        """ Load the icds from the CSV file.
            report format by generating array: ['unknownstatus', value, description]
        """
        self._ids = {}
        reader = csv.reader(open(csvfile, "rU"))
        for row in reader:            
            if len(row)>=3 and re.match(r"^\s*\d+\s*$", row[0]): 
                self._ids[row[0]] = row
                if row[1].lower() != "yes" and row[1].lower() != "no" and row[1].lower() != "bin":
                    yield ["unknownstatus", row[0], row[2]]

    def validate_content(self, filename):
        """  Validating the policy file content. If it cannot be decoded, 
            it reports an 'invalidencoding'.            
            Case 'notinidlist': value is not defined under the id list.
        """
        value = None
        try:
            value = fileutils.read_policy_content(filename)
        except Exception:
            yield ["invalidencoding", filename, None]
        if value is not None:                        
            if self._ids != None:
                if value not in self._ids:
                    yield ["notinidlist", filename, value]
    
    def find_policy(self, path):
        """ find the policy file under path using filenames under the list. """
        for filename in self._policyfiles:
            if os.sep != '\\':
                for f in os.listdir(path):
                    if f.lower() == filename.lower():
                        return os.path.join(path, f)
            if os.path.exists(os.path.join(path, filename)):
                return os.path.join(path, filename)
        return None

    def validate(self, path):
        """ Return a list couple [errortype, location, policy].
            errortype: missing, invalidencoding, notinidlist .
            missing: location is a directory.
            otherwise the doggie policy file.
        """
        path = os.path.normpath(path)
        for dirpath, _, _ in os.walk(path):
            # skipping the root
            if dirpath == path and self._ignoreroot:
                continue
            # skip .svn and .hg dirs
            if pathaddition.match.ant_match(dirpath, "**/.svn/**"):
                continue
            if pathaddition.match.ant_match(dirpath, "**/.hg/**"):
                continue
            # Skipping j2me content. Shouln't this be done differently?
            if pathaddition.match.ant_match(dirpath, "**/j2me/**"):
                continue
            filename = self.find_policy(dirpath)
            if filename != None:
                for result in self.validate_content(filename):
                    yield result
            else:
                # report an error is the directory has no DP file
                # and any files underneith.
                for item in os.listdir(dirpath):
                    if os.path.isfile(os.path.join(dirpath, item)):
                        yield ['missing', dirpath, None]
                        break

