#============================================================================ 
#Name        : freedisk.py 
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

""" Checks free space on the disk before the build starts.

The script is being called from the preparation.ant.xml file

"""

import getopt, sys


HELP_STRING = """
    -h or --help     : Displays help

    -d or --drive    : Requires a drive letter to be checked.
                     : E.g. -d C: (case insensitive; ':' is optional)
                     
    -s or --space    : Required space to compare with the drive for the free space"
                     : E.g. -s 2658 (an integer value in MB)
"""



def print_space_report(drive, space_required):
    """
    compares the required space with current free space on the provided drive
    """
    try:
        if sys.platform == "win32":
            import win32file # pylint: disable-msg=F0401
            free_bytes = win32file.GetDiskFreeSpaceEx(drive)[0]
        elif 'java' in sys.platform:
            import java.io # pylint: disable-msg=F0401
            free_bytes = java.io.File(drive).getFreeSpace()
        else:
            import os
            import statvfs
            # pylint: disable-msg=E1101
            stats = os.statvfs(drive)
            free_bytes = stats[statvfs.F_BSIZE] * stats[statvfs.F_BAVAIL]
            
    except Exception, err_type:
        print "ERROR: Either specified drive doesn't exist or an unknown error"
        print str(err_type)
        print HELP_STRING
        sys.exit(-2)

    free_space = free_bytes / (1024 * 1024)

    print "drive:", drive
    print "Required Space:", space_required
    print "Free Space:", free_space
    
    if space_required < free_space:
        print "Enough free space"
    else:
        print "Not enough free space, exiting"
        sys.exit(-1)

    
def main():
    """
    Gets and parse options and verifies the option values
    """
    try:
        opts = getopt.getopt(sys.argv[1:], "hs:d:", \
                                   ["space=", "drive=", "help"])[0]
    except getopt.GetoptError:
        # print help information and exit:
        print "ERROR: Couldn't parse the command line parameters."
        print HELP_STRING
        sys.exit(2)

    drive = None
    required_space = None

    for opt, attr in opts:

        if opt in ("-s", "--space"):
            required_space = int(attr)
            
        if opt in ("-d", "--drive"):
            drive = attr
            
        if opt in ("-h", "--help"):
            print HELP_STRING
            sys.exit()
    
    if required_space == None and drive == None:
        print "ERROR: No parameters are defined"
        print HELP_STRING
        sys.exit (-3)

    if required_space == None:
        print "ERROR: Required Disk Space parameter is not defined to" \
              "check space on the disk"
        print HELP_STRING
        sys.exit (-3)
        
    if drive == None:
        print "ERROR: Drive parameter is missing"
        print HELP_STRING
        sys.exit (-3)
    else:
        if sys.platform == "win32":
            if not ":" in drive:
                drive = drive + ":"

    print_space_report(drive, required_space)




if __name__ == '__main__':
    sys.exit(main())
