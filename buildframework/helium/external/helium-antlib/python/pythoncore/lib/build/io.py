#============================================================================ 
#Name        : io.py 
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

""" IO classes for handling build-related objects, e.g. log files.
"""

import logging
import re
import symbian.log


_logger = logging.getLogger('build.io')


class AbldLogWhatReader(symbian.log.Parser):
    """ Reader that parses a Symbian build log and extracts abld -what sections.
    
    This reader will return, using the iterator protocol, tuples containing:
    * Unit name.
    * List of binaries for that unit.
    
    """
    def __init__(self, logpath):
        symbian.log.Parser.__init__(self, open(logpath, 'r'))
        self.__match_what = re.compile("abld(\.bat)?(\s+.*)*\s+-w(hat)?", re.I)        
        self._releasable = {}      
        self.parse()

    def __iter__(self):
        keys = self._releasable.keys()
        keys.sort()
        for key in keys:
            yield (key, self._releasable[key])
    
    def task(self, name, cmdline, path, output):
        """ Scans abld what build jobs to extract the list of releasable. """
        _logger.debug("%s, %s, %s, %s" % (name, cmdline, path, output))
        if self.__match_what.match(cmdline) == None:
            return
        
        if name not in self._releasable:
            self._releasable[name] = []
        for line in output.splitlines():
            line = line.strip()
            if line.startswith("\\") or line.startswith("/"):  
                self._releasable[name].append(line)

                    
class RombuildLogBinarySizeReader(object):
    """ Reader that parses a Symbian ROM build log and extracts binary sizes.
    
    This reader will return, using the iterator protocol, tuples containing:
    * Binary name.
    * Size of binary.\t(\d+)
    """
    rom_binary_size_regex = re.compile(r'(\\epoc32[\w\\\.]+)\t(\d+)')
    rofs_binary_size_regex = re.compile(r"ile '([\w\\\.]+)' size: (\w+)")
    image_type_regex = re.compile(r'[._]([^._]+)\.log')
    
    def __init__(self, logpath):
        """ Initialisation. 
        
        :param logpath: The path to the Symbian log file.
        """
        self._logpath = logpath
        
    def __iter__(self):
        """ Implement the iterator protocol. """
        loghandle = open(self._logpath, 'r')
        
        # Find the ROM image type
        type_match = self.image_type_regex.search(self._logpath)
        image_type = type_match.group(1)
        if image_type == 'rom' or image_type.startswith('rofs'):
            # Extract the binary and size info 
            for line in loghandle:
                if image_type == 'rom':
                    match = self.rom_binary_size_regex.match(line)
                    if match != None:
                        # Number is in decimal
                        size = int(match.group(2))
                        yield (match.group(1), size, image_type)
                elif image_type.startswith('rofs'):
                    match = self.rofs_binary_size_regex.search(line)
                    if match != None:
                        # Number is in hexidecimal
                        size = int(match.group(2), 16)
                        yield (match.group(1), size, image_type)
        else:
            _logger.error('ROM type not matched')
    
            
            
        
        
        
                    