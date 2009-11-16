#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# lightweight script to start raptor
#

import raptor
import sys
import os

profile_basename = None
if os.environ.has_key('SBS_PROFILE_BASENAME'):
	profile_basename = os.environ['SBS_PROFILE_BASENAME']
	import cProfile

#
# Main takes the command-line (ignoring argv[0] which is the name of
# this script) and returns the exit code.
#
try:	
	if profile_basename is not None:
		sys.exit(cProfile.run('raptor.Main(sys.argv[1:])',profile_basename))
	else:
		sys.exit(raptor.Main(sys.argv[1:]))
except KeyboardInterrupt:
	sys.stderr.write("ERROR: sbs: Terminated by control-c or break\n")
	sys.exit(255)
except ValueError, exc:
	sys.stderr.write("ERROR: sbs: %s" % str(exc))
	sys.exit(255)

