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
from fileutils import get_next_free_drive
def search_next_free_drive():
    """search for a free drive"""
    try:
        return get_next_free_drive()
    except OSError:
        return "Error: No free drive!"

if __name__ == "__main__":
    print search_next_free_drive()
