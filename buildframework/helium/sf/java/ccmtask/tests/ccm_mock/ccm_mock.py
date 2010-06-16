#============================================================================ 
#Name        : ccmtask.py 
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
import sys

if len(sys.argv) == 4 and sys.argv[1] == 'set' and sys.argv[2] == 'role':
    sys.exit(0)
elif len(sys.argv) == 2 and sys.argv[1] == 'status':
    print """Sessions for user wbernard:

Command Interface @ FAKESESSION:9999:192.168.0.1 (current session)
Database: /path/to/db/database

Current project could not be identified.
"""
elif len(sys.argv) == 6 and sys.argv[1] == 'folder':
    print "Added 1 task to " + sys.argv[5]

sys.exit(0)
