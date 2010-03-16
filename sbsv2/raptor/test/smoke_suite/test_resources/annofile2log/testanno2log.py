#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Component description file
#


import sys
import os
sys.path.append(os.path.join(os.environ['SBS_HOME'],"python"))

from raptor_make import XMLEscapeLog
from raptor_make import AnnoFileParseOutput


retcode=0


annofile = sys.argv[1]

sys.stdout.write("<build>\n")
try:
	for l in XMLEscapeLog(AnnoFileParseOutput(annofile)):
		sys.stdout.write(l)

except Exception,e:
	sys.stderr.write("error: " + str(e) + "\n")
	retcode = 1
sys.stdout.write("</build>\n")

sys.exit(retcode)
