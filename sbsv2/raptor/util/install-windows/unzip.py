# The MIT License
# Copyright (c) 2003 Doug Tolton
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#

""" unzip.py
    Version: 1.1

    Extract a zip file to the directory provided
    It first creates the directory structure to house the files
    then it extracts the files to it.

    Sample usage:
    Windows command line
    unzip.py -p 10 -z c:\testfile.zip -o c:\testoutput
    
    Linux command line
    unzip.py -p 10 -z /tmp/testfile.zip -o /tmp/testoutput

    Python class:
    import unzip
    un = unzip.unzip()
    un.extract(r'c:\testfile.zip', r'c:\testoutput') # Windows
    un.extract(r'/tmp/testfile.zip', '/tmp/testoutput') # Linux
    
    By Doug Tolton
    
    Taken from http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/252508
    
    Updated by Daniel Jacobs to be OS-neutral and more stable.
"""

import sys
import zipfile
import os
import os.path
import getopt
import errno

class unzip:
    def __init__(self, verbose = False, percent = 10):
        self.verbose = verbose
        self.percent = percent
        
    def extract(self, file, dir):
        """ Extract all the files in the zip file, "file" to the directory "dir" with full path names."""
        if not dir.endswith(':') and not os.path.exists(dir):
            self._makedir(dir)

        zf = zipfile.ZipFile(file)

        # create directory structure to house files
        self._createstructure(file, dir)

        num_files = len(zf.namelist())
        percent = self.percent
        divisions = 100 / percent
        perc = int(num_files / divisions)

        # extract files to directory structure
        for i, name in enumerate(zf.namelist()):

            if self.verbose == True:
                print "Extracting %s" % name
            elif perc > 0 and (i % perc) == 0 and i > 0:
                complete = int (i / perc) * percent
                print "%s%% complete" % complete

            if not name.endswith('/'):
                # Normalise the path so that it is correct for the current OS
                localdirname = os.path.normpath(os.path.join(dir, os.path.dirname(name)))
                
                # Ensure that the directory hierarchy that contains the files exists so that 
                # writing to the file is valid. Note: some zip tools omit directory information 
                # and this will cause problems when trying to write file to non-existent directories.
                self._makedir(localdirname)
                    
                # Write the file
                outfile = open(os.path.join(localdirname, os.path.basename(name)), 'wb')
                outfile.write(zf.read(name))
                outfile.flush()
                outfile.close()
        
        zf.close()


    def _createstructure(self, file, dir):
        self._makedirs(self._listdirs(file), dir)


    def _makedirs(self, directories, basedir):
        """ Create any directories that don't currently exist """
        for dir in directories:
            curdir = os.path.join(basedir, dir)
            # Normalise path for current OS.
            curdir = os.path.normpath(curdir)
            self._makedir(curdir) 
            
    
    def _makedir(self, directory):
        """ Create a directory "safely", catching the "file exists" exception if the 
        directory has been created by another process. Creates all parent directories
        recursively as requied. """
        if not os.path.exists(directory):
            # In multi-threaded uses, it is possible that this directory 
            # has been made in the meantime. Catch this exception.
            try:
                os.makedirs(directory)
            except OSError, aOSError:
                # If the OSError is that the file exists then we are OK - this
                # might occur in a multi-threaded or multi-process environment;
                # otherwise re-raise the exception since it's something else bad.
                if aOSError.errno != errno.EEXIST:
                    raise aOSError

    def _listdirs(self, file):
        """ Grabs all the directories in the zip structure
        This is necessary to create the structure before trying
        to extract the file to it. """
        zf = zipfile.ZipFile(file)

        dirs = []

        for name in zf.namelist():
            if name.endswith('/'):
                if self.verbose == True:
                    print "Directory \"" + name + "\" will be made."
                dirs.append(name)
        
        zf.close()
        return dirs

def usage():
    print """usage: unzip.py -z <zipfile> -o <targetdir>
    <zipfile> is the source zipfile to extract
    <targetdir> is the target destination

    -z zipfile to extract
    -o target location
    -p sets the percentage notification
    -v sets the extraction to verbose (overrides -p)

    long options also work:
    --verbose
    --percent=10
    --zipfile=<zipfile>
    --outdir=<targetdir>"""
    

def main():
    shortargs = 'vhp:z:o:'
    longargs = ['verbose', 'help', 'percent=', 'zipfile=', 'outdir=']

    unzipper = unzip()

    try:
        opts, args = getopt.getopt(sys.argv[1:], shortargs, longargs)
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    zipsource = ""
    zipdest = ""

    for o, a in opts:
        if o in ("-v", "--verbose"):
            unzipper.verbose = True
        if o in ("-p", "--percent"):
            if not unzipper.verbose == True:
                unzipper.percent = int(a)
        if o in ("-z", "--zipfile"):
            zipsource = a
        if o in ("-o", "--outdir"):
            zipdest = a
        if o in ("-h", "--help"):
            usage()
            sys.exit()

    if zipsource == "" or zipdest == "":
        usage()
        sys.exit()
            
    unzipper.extract(zipsource, zipdest)

if __name__ == '__main__': main()
