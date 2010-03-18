#============================================================================ 
#Name        : raptor.py 
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


import os
import fileutils

def getSBSHome():
    """ Retrieve the SBS_HOME location based on the raptor
        application location.
    """
    if "SBS_HOME" in os.environ:
        return os.environ["SBS_HOME"]
    if os.path.sep == '\\': 
        raptor_cmd = fileutils.which("sbs.bat")
    else:
        raptor_cmd = fileutils.which("sbs")
    if raptor_cmd:
        return os.path.dirname(os.path.dirname(raptor_cmd))
    return None
    
