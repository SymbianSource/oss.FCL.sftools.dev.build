#============================================================================ 
#Name        : searchnextdrive.py 
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
    Script that prints the next free drive on the current system.
    If none available it returns "Error: No free drive!". 
    win32 only!
"""
import string
from win32api import GetLogicalDriveStrings

DRIVE_LABELS = sorted(list(set(string.ascii_uppercase) - set(GetLogicalDriveStrings())), reverse=True)
if len(DRIVE_LABELS) != 0 :
    print DRIVE_LABELS[0] + ":"
else:
    print "Error: No free drive!"
        

