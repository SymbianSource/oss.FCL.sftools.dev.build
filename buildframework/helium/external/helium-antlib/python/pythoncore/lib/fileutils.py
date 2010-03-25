#============================================================================ 
#Name        : fileutils.py 
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
File manipulation related functionalities:
 * Filescanner
 * rmtree (fixed version)
 * move (fixed version)
"""
import codecs
import locale
import logging
import os
import re
import sys
import shutil
import hashlib
import subprocess
import string

import pathaddition.match
import stat

if os.name == 'nt':
    import win32api

LOGGER = logging.getLogger('fileutils')
LOGGER_LOCK = logging.getLogger('fileutils.lock')
#LOGGER.addHandler(logging.FileHandler('default.log'))
#logging.basicConfig(level=logging.DEBUG)
#LOGGER.setLevel(logging.DEBUG)

class AbstractScanner(object):
    """ This class implements all the required infrastructure for filescanning. """

    def __init__(self):
        """ Initialization. """
        self.includes = []
        self.excludes = []
        self.includes_files = []
        self.excludes_files = []
        self.selectors = []
        self.filetypes = []

    def add_include(self, include):
        """ Adds an include path to the scanner. """
        if include.endswith('/') or include.endswith('\\'):
            include = include + '**'

        self.includes.append(include)

    def add_exclude(self, exclude):
        """ Adds an exclude path to the scanner. """
        if exclude.endswith('/') or exclude.endswith('\\'):
            exclude = exclude + '**'

        self.excludes.append(exclude)
        
    def add_exclude_file(self, exclude):
        """ Adds an exclude file to the scanner. """
        self.excludes_files.append(exclude)
    
    def add_selector(self, selector):
        """ Add selector to the scanner. """
        self.selectors.append(selector)
        
    def add_filetype(self, filetype):
        """ Adds a filetype selection to the scanner. """
        self.filetypes.append(filetype)

    def is_included(self, path):
        """ Returns if path is included by the scanner. """
        LOGGER.debug("is_included: path = " + path)
        if path.replace('\\', '/') in self.includes_files or path in self.includes_files:
            return True
        for inc in self.includes:
            if self.match(path, inc):
                LOGGER.debug("Included: " + path + " by " + inc)
                return True
        return False

    def is_excluded(self, path):
        """ Returns if path is excluded by the scanner. """
        LOGGER.debug("is_excluded: path = " + path)
        if path.replace('\\', '/') in self.excludes_files or path in self.excludes_files:
            return True
        for ex in self.excludes:
            if self.match(path, ex):
                LOGGER.debug("Excluded: " + path + " by " + ex)
                return True
        return False
    
    def is_selected(self, path):
        """ Returns if path is selected by all selectors in the scanner. """
        LOGGER.debug("is_selected: path = " + path)
        for selector in self.selectors:
            if not selector.is_selected(path):
                return False
        LOGGER.debug("Selected: " + path)
        return True

    def is_filetype(self, path):
        """ Test if a file matches one filetype. """
        if len(self.filetypes) == 0:
            return True
        LOGGER.debug("is_filetype: path = " + path)
        for filetype in self.filetypes:
            if self.match(path, filetype):
                LOGGER.debug("Filetype: " + path + " by " + filetype)
                return True
        return False

    def match(self, filename, pattern):
        """ Is filename matching pattern? """
        return pathaddition.match.ant_match(filename, pattern, casesensitive=(os.sep != '\\'))

    def test_path(self, root, relpath):
        """ Test if a path matches filetype, include, exclude, and selection process."""
        return self.is_filetype(relpath) and self.is_included(relpath) \
                         and not self.is_excluded(relpath) and \
                         self.is_selected(os.path.join(root, relpath))

    def __str__(self):
        """ Returns a string representing this instance. """
        content = []
        for inc in self.includes:
            content.append('include:' + os.path.normpath(inc))
        for ex in self.excludes:
            content.append('exclude:' + os.path.normpath(ex))
        return ';'.join(content)

    def __repr__(self):
        """ Returns a string representing this instance. """
        return self.__str__()

    def scan(self):
        """ Abstract method which much be overriden to implement the scanning process. """
        raise Exception("scan method must be overriden")


class FileScanner(AbstractScanner):
    """Scans the filesystem for files that match the selection paths.

    The scanner is configured with a root directory. Any number of include
    and exclude paths can be added. The scan() method is a generator that
    returns matching files one at a time when called as an iterator.

    This is a revisited implementation of the filescanner. It now relies on
    the module pathaddition.match that implements a Ant-like regular expression matcher.
    
    Rules:
    - Includes and excludes should not start with *
    - Includes and excludes should not have wildcard searches ending with ** (e.g. wildcard**)
    
    Supported includes and excludes:
    - filename.txt
    - filename.*
    - dir/
    - dir/*
    - dir/**    
    """
    def __init__(self, root_dir):
        """ Initialization. """
        AbstractScanner.__init__(self)
        self.root_dir = os.path.normpath(root_dir)
        if not self.root_dir.endswith(os.sep):
            self.root_dir = self.root_dir + os.sep
        # Add 1 so the final path separator is removed
        #self.root_dirLength = len(self.root_dir) + 1

    def scan(self):
        """ Scans the files required to zip"""
        #paths_cache = []
        
        excludescopy = self.excludes[:]
        for f in excludescopy:
            if os.path.exists(os.path.normpath(os.path.join(self.root_dir, f))):
                self.excludes_files.append(f)
                self.excludes.remove(f)
        
        includescopy = self.includes[:]
        for f in includescopy:
            if os.path.exists(os.path.normpath(os.path.join(self.root_dir, f))):
                self.includes_files.append(f)
                self.includes.remove(f)
        
        LOGGER.debug('Scanning sub-root directories')
        for root_dir in self.find_subroots():
            for dirpath, subdirs, files in os.walk(unicode(root_dir)):
                # Let's save the len before it's getting modified.
                subdirsLen = len(subdirs)
                subroot = dirpath[len(self.root_dir):]

                dirs_to_remove = []
                for subdir in subdirs:
                    if self.is_excluded(os.path.join(subroot, subdir)):
                        dirs_to_remove.append(subdir)
                
                for dir_remove in dirs_to_remove:
                    subdirs.remove(dir_remove)
                
                LOGGER.debug('Scanning directory: ' + dirpath)
                for file_ in files:
                    path = os.path.join(subroot, file_)
                    if self.is_filetype(path) and self.is_included(path) and \
                        self.is_selected(os.path.join(dirpath, file_)) and not self.is_excluded(path):
                        ret_path = os.path.join(dirpath, file_)
                        yield ret_path
            
                LOGGER.debug('Checking for empty directory: ' + dirpath)
                # Check for including empty directories
                if self.is_included(subroot) and not self.is_excluded(subroot):
                    if len(files) == 0 and subdirsLen == 0:
                        LOGGER.debug('Including empty dir: ' + dirpath)
                        yield dirpath
                    

    def find_subroots(self):
        """Finds all the subdirectory roots based on the include paths.

        Often large archive operations define a number of archives from the root
        of the drive. Walking the tree from the root is very time-consuming, so
        selecting more specific subdirectory roots improves performance.
        """
        def splitpath(path):
            """ Returns the splitted path"""
            return path.split(os.sep)

        root_dirs = []
        
        # Look for includes that start with wildcards.
        subdirs_not_usable = False
        for inc in self.includes + self.includes_files:
            first_path_segment = splitpath(os.path.normpath(inc))[0]
            if first_path_segment.find('*') != -1:
                subdirs_not_usable = True
                
        # Parse all includes for sub-roots
        if not subdirs_not_usable:
            for inc in self.includes + self.includes_files:
                include = None
                LOGGER.debug("===> inc %s" % inc)
                contains_globs = False                
                for pathcomp in splitpath(os.path.normpath(inc)):
                    if pathcomp.find('*') != -1:
                        contains_globs = True
                        break
                    else:
                        if include == None:
                            include = pathcomp
                        else:
                            include = os.path.join(include, pathcomp)
                if not contains_globs:
                    include = os.path.dirname(include) 
    
                LOGGER.debug("include %s" % include)
                if include != None:
                    root_dir = os.path.normpath(os.path.join(self.root_dir, include))
                    is_new_root = True
                    for root in root_dirs[:]:
                        if destinsrc(root, root_dir):
                            LOGGER.debug("root contains include, skip it")
                            is_new_root = False
                            break
                        if destinsrc(root_dir, root):
                            LOGGER.debug("include contains root, so remove root")
                            root_dirs.remove(root)
                    if is_new_root:
                        root_dirs.append(root_dir)    

        if len(root_dirs) == 0:
            root_dirs = [os.path.normpath(self.root_dir)]
        LOGGER.debug('Roots = ' + str(root_dirs))
        return root_dirs

    def __str__(self):
        return os.path.normpath(self.root_dir) + ';' + AbstractScanner.__str__(self) 

    def __repr__(self):
        return self.__str__()

        
def move(src, dst):
    """Recursively move a file or directory to another location.

    If the destination is on our current filesystem, then simply use
    rename.  Otherwise, copy src to the dst and then remove src.
    A lot more could be done here...  A look at a mv.c shows a lot of
    the issues this implementation glosses over.

    """
    try:
        os.rename(src, dst)
    except OSError:
        if os.path.isdir(src):
            if destinsrc(src, dst):
                raise Exception, "Cannot move a directory '%s' into itself '%s'." % (src, dst)
            shutil.copytree(src, dst, symlinks=True)
            rmtree(src)
        else:
            shutil.copy2(src, dst)
            os.unlink(src)

def rmtree(rootdir):
    """ Catch shutil.rmtree failures on Windows when files are read-only. Thanks Google!""" 
    if sys.platform == 'win32':
        rootdir = os.path.normpath(rootdir)
        if not os.path.isabs(rootdir):
            rootdir = os.path.join(os.path.abspath('.'), rootdir)
        if not rootdir.startswith('\\\\'):
            rootdir = u"\\\\?\\" + rootdir

    def cb_handle_error(fcn, path, excinfo):
        """ Error handler, removing readonly and deleting the file. """
        os.chmod(path, 0666)
        if os.path.isdir(path):
            rmdir(path)
        elif os.path.isfile(path):
            remove(path)
        else:
            fcn(path)
    
    if 'java' in sys.platform:
        import java.io
        import org.apache.commons.io.FileUtils
        f = java.io.File(rootdir)
        org.apache.commons.io.FileUtils.deleteDirectory(f)
    else:
        return shutil.rmtree(rootdir, onerror=cb_handle_error)

def destinsrc(src, dst):
    """ Fixed version of destinscr, that doesn't match dst with same root name."""
    if os.sep == '\\':
        src = src.lower()
        dst = dst.lower()
    src = os.path.abspath(src)
    dst = os.path.abspath(dst)
    if not src.endswith(os.path.sep):
        src += os.path.sep
    if not dst.endswith(os.path.sep):
        dst += os.path.sep
    return dst.startswith(src)


def which(executable):
    """ Search for executable in the PATH."""
    pathlist = os.environ['PATH'].split(os.pathsep)
    for folder in pathlist:
        filename = os.path.join(folder, executable)
        try:
            status = os.stat(filename)
        except os.error:
            continue
        # Check if the path is a regular file
        if stat.S_ISREG(status[stat.ST_MODE]):
            mode = stat.S_IMODE(status[stat.ST_MODE])
            if mode & 0111:
                return os.path.normpath(filename)
    return None


def read_policy_content(filename):
    """ Read the policy number from the policy file.
        strict allows to activate the new policy scanning.
    """
    value = None
    error = ""
    try:
        LOGGER.debug('Opening policy file: ' + filename)
        policy_data = load_policy_content(filename)            
        match = re.match(r'^((?:\d+)|(?:0842[0-9a-zA-Z]{3}))\s*$', policy_data, re.M|re.DOTALL)
        if match != None:
            value = match.group(1)
        else:
            error = "Content of '%s' doesn't match r'^\d+|0842[0-9a-zA-Z]{3}\s*$'." % filename
    except Exception, exc:
        error = str(exc)
    if value is not None:
        return value
    # worse case....
    raise Exception(error)  

def load_policy_content(filename):
    """ Testing policy content loading. """
    data = ''
    try:
        fileh = codecs.open(filename, 'r', 'ascii')
        data = fileh.read()
    except:
        raise Exception("Error loading '%s' as an ASCII file." % filename)
    finally:
        fileh.close()
    return data

ENCODING_MATRIX = {
   codecs.BOM_UTF8: 'utf_8',
   codecs.BOM_UTF16: 'utf_16',
   codecs.BOM_UTF16_BE: 'utf_16_be',
   codecs.BOM_UTF16_LE: 'utf_16_le',
}

def guess_encoding(data):
    """Given a byte string, guess the encoding.

    First it tries for UTF8/UTF16 BOM.

    Next it tries the standard 'UTF8', 'ISO-8859-1', and 'cp1252' encodings,
    Plus several gathered from locale information.

    The calling program *must* first call locale.setlocale(locale.LC_ALL, '')

    If successful it returns (decoded_unicode, successful_encoding)
    If unsuccessful it raises a ``UnicodeError``.

    This was taken from http://www.voidspace.org.uk/python/articles/guessing_encoding.shtml
    """
    for bom, enc in ENCODING_MATRIX.items():
        if data.startswith(bom):
            return data.decode(enc), enc
    encodings = ['ascii', 'UTF-8']
    successful_encoding = None
    try:
        encodings.append(locale.getlocale()[1])
    except (AttributeError, IndexError):
        pass
    try:
        encodings.append(locale.getdefaultlocale()[1])
    except (AttributeError, IndexError):
        pass
    # latin-1
    encodings.append('ISO8859-1')
    encodings.append('cp1252')
    for enc in encodings:
        if not enc:
            continue
        try:
            decoded = unicode(data, enc)
            successful_encoding = enc
            break
        except (UnicodeError, LookupError):
            pass
    if successful_encoding is None:
        raise UnicodeError('Unable to decode input data. Tried the'
                           ' following encodings: %s.' %
                           ', '.join([repr(enc) for enc in encodings if enc]))
    else:
        if successful_encoding == 'ascii':
            # our default ascii encoding
            successful_encoding = 'ISO8859-1'
        return (decoded, successful_encoding)
        
def getmd5(fullpath, chunk_size=2**16):
    """ returns the md5 value"""
    file_handle = open(fullpath, "rb")
    md5 = hashlib.md5()
    while 1:
        chunk = file_handle.read(chunk_size)
        if not chunk:
            break
        md5.update(chunk)
    file_handle.close()
    return md5.hexdigest()

def read_symbian_policy_content(filename):
    """ Read the policy category from the policy file. """
    value = None
    error = ""
    try:
        LOGGER.debug('Opening symbian policy file: ' + filename)
        try:
            fileh = codecs.open(filename, 'r', 'ascii')
        except:
            raise Exception("Error loading '%s' as an ASCII file." % filename)        
        for line in fileh:
            match = re.match(r'^Category\s+([A-Z])\s*$', line, re.M|re.DOTALL)
            if match != None:
                value = match.group(1)
                fileh.close()
                return value
        fileh.close()
        if match == None:
            error = "Content of '%s' doesn't match r'^Category\s+([A-Z])\s*$'." % filename
    except Exception, exc:
        error = str(exc)
    if value is not None:
        return value
    # worse case....
    raise Exception(error)


class LockFailedException(Exception):
    pass

if os.name == 'nt':
    import win32file
    import win32con
    import winerror
    import time
    import win32netcon
    import win32wnet
    
    class Lock:
        """ This object implement file locking for windows. """
        
        def __init__(self, filename):
            LOGGER_LOCK.debug("__init__")
            self._filename = filename
            self.fd = None

        def lock(self, wait=False):
            LOGGER_LOCK.debug("lock")
            # Open the file
            if self.fd == None:
                self.fd = open(self._filename, "w+")
            wfd = win32file._get_osfhandle(self.fd.fileno())
            if not wait:
                try:
                    win32file.LockFile(wfd, 0, 0, 0xffff, 0)
                except:
                    raise LockFailedException()
            else:    
                while True:
                    try:
                        win32file.LockFile(wfd, 0, 0, 0xffff, 0)
                        break
                    except win32file.error, exc:
                        if exc[0] != winerror.ERROR_LOCK_VIOLATION:
                            raise exc
                    LOGGER_LOCK.debug("waiting")
                    time.sleep(1)
                    
        def unlock(self):
            LOGGER_LOCK.debug("unlock")
            if self.fd == None:
                LOGGER_LOCK.debug("already unlocked")
                return
            wfd = win32file._get_osfhandle(self.fd.fileno())
            try:
                # pylint: disable-msg=E1101
                win32file.UnlockFile(wfd, 0 , 0, 0xffff, 0)
                self.fd.close()
                self.fd = None
            except win32file.error, exc:
                if exc[0] != 158:
                    raise
            
            
        def __del__(self):
            LOGGER_LOCK.debug("__del__")
            self.unlock()

    def rmdir(path):
        """ Catch os.rmdir failures on Windows when path is too long (more than 256 chars)."""
        path = win32api.GetShortPathName(path)        
        win32file.RemoveDirectory(path)

    def remove(filename):
        """ Catch os.rmdir failures on Windows when path is too long (more than 256 chars)."""
        filename = win32api.GetShortPathName(filename)
        filename = filename.lstrip("\\\\?\\")
        os.remove(filename)

    def mount(drive, unc, username=None, password=None, persistent=False):
        """ Windows helper function to map a network drive. """
        flags = 0
        if persistent:
            flags = win32netcon.CONNECT_UPDATE_PROFILE
        win32wnet.WNetAddConnection2(win32netcon.RESOURCETYPE_DISK, drive, unc, None, username, password, flags)


    def umount(drive):
        """ Windows helper function to map a network drive. """
        drive_type = win32file.GetDriveType(drive)
        if drive_type == win32con.DRIVE_REMOTE:
            win32wnet.WNetCancelConnection2(drive, win32netcon.CONNECT_UPDATE_PROFILE, 1)
        else:
            raise Exception("%s couldn't be umount." % drive)

else:
    def rmdir(path):
        return os.rmdir(path)

    def remove(path):
        return os.remove(path)

    class Lock:
        def __init__(self, filename):
            pass
        def lock(self, wait=False):
            pass
        def unlock(self):
            pass
            
if os.sep == '\\':
    def get_next_free_drive():
        """ Return the first free drive found else it raise an exception. """
        if os.name == 'nt':
            DRIVE_LABELS = sorted(list(set(string.ascii_uppercase) - set(win32api.GetLogicalDriveStrings())), reverse=True)
            if len(DRIVE_LABELS) != 0 :
                return DRIVE_LABELS[0] + ":"
            raise OSError("No free drive left.")        
        if 'java' in sys.platform:
            import java.io        
            used = []
            for x in java.io.File.listRoots():
                used.append(str(x).replace(':\\', ''))
            DRIVE_LABELS = sorted(list(set(string.ascii_uppercase) - set(used)), reverse=True)
            if len(DRIVE_LABELS) != 0 :
                return DRIVE_LABELS[0] + ":"
            raise OSError("No free drive left.")

    def subst(drive, path):
        """ Substing path as a drive. """
        path = os.path.normpath(path)
        p = subprocess.Popen("subst %s %s" % (drive, path),  shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        errmsg = p.communicate()[0]
        if p.returncode != 0:
            raise Exception("Error substing '%s' under '%s': %s" % (path, drive, errmsg))
    
    def unsubst(drive):
        """ Unsubsting the drive. """
        p = subprocess.Popen("subst /D %s" % (drive), shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        errmsg = p.communicate()[0]
        if p.returncode != 0:
            raise Exception("Error unsubsting '%s': %s" % (drive, errmsg))
    
    def getSubstedDrives():
        driveInformation = {}
        subStedDriveList = []
        p = subprocess.Popen("subst",  shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        subStedDriveList = re.split('\\n', p.communicate()[0])
        del subStedDriveList[len(subStedDriveList)-1]
        for path in subStedDriveList:        
            subStedDrivePath = []
            if(re.search(r'UNC', path) is not None):
                subStedDrivePath = re.split('=>', path)
                (drive_to_unsubst, root_dir_path) = os.path.splitdrive(os.path.normpath(subStedDrivePath[0]))
                uncPath = re.sub('UNC', r'\\', subStedDrivePath[1].strip())
                if(uncPath != subStedDrivePath[1].strip()):
                    driveInformation[drive_to_unsubst] = uncPath
            else:
                subStedDrivePath = re.split('=>', path)                
                (drive_to_unsubst, root_dir_path) = os.path.splitdrive(os.path.normpath(subStedDrivePath[0]))
                driveInformation[drive_to_unsubst] = os.path.normpath(subStedDrivePath[1].strip())
    
        return driveInformation

def touch(srcdir):
    """
    Recursively touches all the files in the source path mentioned.
    It does not touch the directories.
    """
    srcnames = os.listdir(srcdir)
    for name in srcnames:
        srcfname = os.path.join(srcdir, name)
        if os.path.isdir(srcfname):
            touch(srcfname)
        else:
            if os.path.exists(srcfname):
                os.utime(srcfname, None)