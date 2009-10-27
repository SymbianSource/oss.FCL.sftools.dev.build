#
# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: 
# raptor linux distribution creation module
# This module allow to crate raptor linux distribution archive (tar.gz) e.g. sbs_linux_dist.tar.gz
# Script extect the following command-line parameters:
# 1. Archive name
# 2. List of files/directories to include
# By default windows specific and source files are excluded.
# example including bin and python subdir:
# sbs_dist.py sbs_linux_dist.tar.gz bin python
#

import os
import re
import tarfile
import sys
import dos2unix

#------------------------------------------------------------------------------
# Create tar.gz archive including given files (fileName list and tarinfo list)
#------------------------------------------------------------------------------
def createTarGZ(tarName, fileList):
    tar = tarfile.open(tarName, "w|gz")
    for name in fileList:
        tar.add(name)
    return tar

#------------------------------------------------------------------------------
# Lists files in each of given directories
#------------------------------------------------------------------------------
def listFilesInDirs(paths):
    fileList = []
    for path in paths:
        fileList.extend(listFiles(path))
    return fileList

#------------------------------------------------------------------------------
# Lists files in given directory
#------------------------------------------------------------------------------
def listFiles(path):
    fileList = []
    for root, dirs, files in os.walk(path):
        for index in range(len(files)):
            fileList.append(root + "/" + files[index])
    return fileList

#------------------------------------------------------------------------------
# Excludes files matching "pattern" from given files list
#------------------------------------------------------------------------------
def excludeFiles(fileList, pattern):
    filteredFileList = []
    regExp = re.compile(pattern)
    for fileName in fileList:
        if not(regExp.match(fileName)):
           filteredFileList.append(fileName)
    return filteredFileList


#------------------------------------------------------------------------------
# Groups given paths as files or directories
#------------------------------------------------------------------------------
def groupFilesAndDirs(filesAndDirs):
    files = []
    dirs = []
    for name in filesAndDirs:
        if os.path.isdir(name):
             dirs.append(name)
        else:
             if os.path.isfile(name):
                files.append(name)
             else:
                  print "Warning: Neither a file nor a directory! Ignoring parameter - " + name
    return (files,dirs)

#------------------------------------------------------------------------------
# Prepares regular expression to exclude unnecessary files
#------------------------------------------------------------------------------
def prepareExcludedFilesRegExp():
    pathPrefixRegExp = ".*[\\\/]"
    filesRegExp = "((sbs)|(.*\.bat)|(.*\.pyc)|(.*\.cmd)|(.*\.exe)|(.*\.dll)|(sbs_dist.py)"
    filesRegExp = filesRegExp + "|(dos2unix.py)|(raptor_py2exe_setup.py)|(make)|(bash)|(bashbug))+"
    return "^" + pathPrefixRegExp + filesRegExp + "$"

#------------------------------------------------------------------------------
# Includes all files in fileList in given tar with altered executable permision (+X) for all
#------------------------------------------------------------------------------
def includeAsExecutable(tar, fileList):
    for f in fileList:
        tarinfo = tar.gettarinfo(f)
        # OR with 73 (001 001 001) - +X for all
        tarinfo.mode = tarinfo.mode | 73
        tar.addfile(tarinfo,file(f, "rb"))


#------------------------------------------------------------------------------
# Validate script parameters
#------------------------------------------------------------------------------
def validateParameters(tarFileName, filesToInclude):
    if not(len(tarFileName) > 0):
       print "Error: No archive name given."
       sys.exit()
    if not(len(filesToInclude) > 0):
       print "Error: No files/directories names to include in archive given."
       sys.exit()


tarFileName = sys.argv[1]
# files and directories
filesAndDirsToInclude = sys.argv[2:]

validateParameters(tarFileName, filesAndDirsToInclude)

(filesToInclude,dirsToInclude) = groupFilesAndDirs(filesAndDirsToInclude)

fileList = listFilesInDirs(dirsToInclude)
fileList.extend(filesToInclude)

filteredFileList = excludeFiles(fileList, prepareExcludedFilesRegExp())

dos2unix.dos2unix("bin/sbs")

tar = createTarGZ(tarFileName, filteredFileList)
fileToBeExecutableList = ["bin/sbs", "linux-i386/bin/make", "linux-i386/bin/bash", "linux-i386/bin/bashbug",
			  "bin/sbs_descramble"]
includeAsExecutable(tar, fileToBeExecutableList)
tar.close()

