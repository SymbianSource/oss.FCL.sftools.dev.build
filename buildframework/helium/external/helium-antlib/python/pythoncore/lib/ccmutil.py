#============================================================================ 
#Name        : ccmutil.py 
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

""" utility module related to ccm """

import nokia.nokiaccm
import configuration
import ccm.extra

def get_session(database, username, password, engine, dbpath):
    """ Returns a user session """
    if database != None:
        return nokia.nokiaccm.open_session(username, password, database=database)
    else:
        return nokia.nokiaccm.open_session(username, password, engine, dbpath)
                

   