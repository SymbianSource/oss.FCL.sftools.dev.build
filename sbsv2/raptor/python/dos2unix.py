#
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# dos2unix - python version
# This module converts file from dos to unix i.e. replaces Dos/Windows EOL (CRLF) with Unix EOL (LF).
# example usage:
# dos2unix.py windowsFile.txt
#

import os
import re
import sys
import stat
#------------------------------------------------------------------------------
# Converts string from dos to unix i.e. replaces CRLF with LF as a line terminator (EOL)
#------------------------------------------------------------------------------
def convertDos2Unix(inputString):
    regExp = re.compile("\r\n|\n|\r")
    return regExp.sub("\n",inputString)

#------------------------------------------------------------------------------
# Validates input
#------------------------------------------------------------------------------
def validateInput(argv):
    if not(len(argv) > 1):
       print "Error No parameter given: fileName to convert."
       sys.exit();

#------------------------------------------------------------------------------
# Reads input file
#------------------------------------------------------------------------------
def readInputFile(fileName):
    inputFile = open(fileName, 'r')
    # read file content
    originalFileContent = inputFile.read()
    inputFile.close()
    return originalFileContent

#------------------------------------------------------------------------------
# Writes string to given file (in binary mode)
#------------------------------------------------------------------------------
def writeToBinaryFile(string,fileName):
    os.chmod(fileName, stat.S_IRWXU)
    outputFile = open(fileName, 'wb')
    outputFile.write(string)
    outputFile.close()

# Main script

#------------------------------------------------------------------------------
# Coverts dos/windows EOL to UNIX EOL (CRLF->LF) in given file
#------------------------------------------------------------------------------
def dos2unix(fileName):
    originalFileContent = readInputFile(fileName)
    convertedFileContent = convertDos2Unix(originalFileContent)
    writeToBinaryFile(convertedFileContent,fileName)

