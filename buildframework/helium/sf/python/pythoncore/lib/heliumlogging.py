#============================================================================ 
#Name        : heliumlogging.py 
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
import logging
import logging.config
if os.environ.has_key("HELIUM_CACHE_DIR"):
    logconf = os.path.join(os.environ['HELIUM_CACHE_DIR'], "logging." + os.environ['PID'] + ".conf")
else:
    logconf = os.path.join(os.getcwd(), "logging.conf")

if os.path.exists(logconf):
    logging.config.fileConfig(logconf)