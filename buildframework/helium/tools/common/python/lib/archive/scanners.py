#============================================================================ 
#Name        : scanners.py 
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

""" Implementation of the available scanner for """

import os
import fileutils
import selectors
import logging
import codecs
import pathaddition

logger = logging.getLogger('archive.scanners')
logger_abld = logging.getLogger('archive.scanners.abld')
logging.basicConfig()
#logger_abld.setLevel(logging.DEBUG)

class Scanner(fileutils.AbstractScanner):
    """ Abstract class that represent and input source. """
    
    def __init__(self, config):
        fileutils.AbstractScanner.__init__(self)
        self._config = config
        self.setup()
        
    def setup(self):
        """ Setting up the scanner. """
        [self.add_include(inc) for inc in self._config.get_list('include', [])]
        [self.add_exclude(ex) for ex in self._config.get_list('exclude', [])]
        [self.add_exclude_file(ex) for ex in self._config.get_list('exclude_file', [])]
        [self.add_exclude_lst(filename) for filename in self._config.get_list('exclude.lst', [])]
        [self.add_filetype(filetype) for filetype in self._config.get_list('filetype', [])]
        [self.add_selector(selectors.get_selector(selector, self._config)) for selector in self._config.get_list('selector', [])]        
        # To support old features.
        # TODO: inform customers and remove.
        if 'distribution.policy.s60' in self._config:            
            self.add_selector(selectors.get_selector('distribution.policy.s60', self._config))
    
    def add_exclude_lst(self, filename):
        """ Adding excludes from exclude list. """
        if not os.path.exists(filename):
            raise Exception("Could not find '%s'." % filename)
        root_dir = os.path.normpath(self._config['root.dir'])
        flh = codecs.open(filename, 'r', 'utf-8')
        for line in flh:
            path = os.path.normpath(line.strip())
            if os.path.splitdrive(root_dir)[0] != "":
                path = os.path.join(os.path.splitdrive(root_dir)[0], path)
            if fileutils.destinsrc(root_dir, path):
                pathrel = pathaddition.relative.abs2rel(path, root_dir)
                logger.debug("pathrel: %s" % (pathrel))
                self.add_exclude(pathrel)
            else:
                logger.warning("path '%s' is not under '%s', ignoring." % (path, root_dir))
        flh.close()
        
    def scan(self):
        """ Generator method that scan the relevant input source.
            This method need to be overloaded by the specialized class.
            return fullpath name
        """
        raise  NotImplementedError()


class AbldWhatScanner(Scanner):
    """ Scanning the filesystem. """    
    
    def __init__(self, config):
        Scanner.__init__(self, config)
        self.root_dir = unicode(os.path.normpath(self._config['root.dir']))
        
    def scan(self):
        """
            Abld what commands.
            include property have not effect on the selection mechanism.
        """
        os.environ["SYMBIANBUILD_DEPENDENCYOFF"] = "1"
        for path in self._config.get_list('abld.exportpath', []):
            logger_abld.debug("abld.exportpath: %s" % path)
            if os.path.exists(os.path.join(self.root_dir, path, 'bld.inf')):
                os.chdir(os.path.join(self.root_dir, path))                
                os.popen('bldmake bldfiles -k')
                for result in self._scan_abld_what("abld export -what -k"):
                    yield result
        
        for path in self._config.get_list('abld.buildpath', []):
            logger_abld.debug("abld.buildpath: %s" % path)
            if os.path.exists(os.path.join(self.root_dir, path, 'bld.inf')):
                for type_ in self._config.get_list('abld.type', ['armv5']):
                    os.environ["EPOCROOT"] = self._config.get('abld.epocroot','\\')
                    os.environ["PATH"] = os.environ["EPOCROOT"] + "epoc32\\tools;" + os.environ["EPOCROOT"] + "epoc32\\gcc\\bin;" + os.environ["PATH"]
                    logger_abld.debug("abld.type: %s" % type_)
                    os.chdir(os.path.join(self.root_dir, path))
                    os.popen("bldmake bldfiles -k")
                    os.popen("abld makefile %s -k" % type_)
                    for result in self._scan_abld_what("abld build -what %s" % type_):
                        yield result
    
    def _run_cmd(self, cmd):
        """ Run command."""
        logger_abld.debug("command: %s" % cmd)
        process = os.popen(cmd)
        abld_output = process.read()
        err = process.close()
        return (err, abld_output)

    def _scan_abld_what(self, cmd):
        """ Abld what output parser."""
        (err, abld_output) = self._run_cmd(cmd)
        logger_abld.debug("abld_output: %s" % abld_output)
        for what_path in abld_output.split("\n"):
            what_path = what_path.strip()
            if (what_path.startswith('\\') or what_path.startswith('/')) and self.is_filetype(what_path) \
                and not self.is_excluded(what_path) and self.is_selected(what_path):
                if os.path.exists(what_path):
                    logger_abld.debug("adding: %s" % what_path)
                    yield what_path
                else:
                    logger.error("Could not find '%s'." % what_path)
    
    
class FileSystemScanner(fileutils.FileScanner, Scanner):
    """ Scanning the filesystem. """    
    
    def __init__(self, config):
        fileutils.FileScanner.__init__(self, unicode(os.path.normpath(config['root.dir'])))
        Scanner.__init__(self, config)
    
    def scan(self):
        """ 
            Implement the scanning of the filesystem.
            Actually delegate scanning of a directory to Filescanner.
        """
        for path in fileutils.FileScanner.scan(self):
            yield path


class InputFileScanner(fileutils.FileScanner, Scanner):
    """ Scanning the filesystem. """    
    
    def __init__(self, config):
        """ Initialisation. """
        fileutils.FileScanner.__init__(self, unicode(os.path.normpath(config['root.dir'])))
        Scanner.__init__(self, config)
    
    def scan(self):
        """
        ::
        
            <set name="scanners" value="input.file"/>
            <set name="root.dir" value="${build.drive}"/>
            <set name="input.files" value="file1.lst,file2.lst,file3.lst"/>
            <set name="exclude" value="epoc32/**/*.dll"/>
        """
        for input_file in self._config.get_list('input.files', []):
            logger.info("Include content from: %s" % input_file)
            handle = open(input_file, "r")
            for line in handle.readlines():
                path = os.path.join(self._config['root.dir'], line.strip())
                if os.path.exists(path):
                    if self.is_filetype(path) \
                        and not self.is_excluded(path) and self.is_selected(path):
                        yield path
                else:
                    logger.info("File not found: %s" % path)
            handle.close()
        
__scanners = {'default': FileSystemScanner,
              'input.file': InputFileScanner,
              'abld.what': AbldWhatScanner,
              }

def get_scanners(names, config):
    result = []
    for name in names:
        if name in __scanners:
            result.append(__scanners[name](config))
        else:
            raise Exception("ERROR: Could not find scanner '%s'." % name)
    return result
