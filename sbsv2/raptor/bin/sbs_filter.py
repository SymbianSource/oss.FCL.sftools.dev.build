#!/usr/bin/python

# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Symbian Foundation License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
#

import os
import sys
import traceback

# intercept the -h option
if "-h" in sys.argv or "--help" in sys.argv:
	print "usage:", sys.argv[0], "[sbs options]"
	print "  The log data is read from stdin."
	print "  Type 'sbs -h' for a list of sbs options."
	sys.exit(0)
	
# get the absolute path to this script
script = os.path.abspath(sys.argv[0])

# add the Raptor python directory to the PYTHONPATH
sys.path.append(os.path.join(os.path.dirname(script), "..", "python"))

# now we should be able to find the raptor modules
import raptor
import pluginbox

# make sure that HOSTPLATFORM is set
if not "HOSTPLATFORM" in os.environ:
	sys.stderr.write("HOSTPLATFORM is not set ... try running gethost.sh\n")
	sys.exit(1)
	
if not "HOSTPLATFORM_DIR" in os.environ:
	sys.stderr.write("HOSTPLATFORM_DIR is not set ... try running gethost.sh\n")
	sys.exit(1)

# construct a Raptor object from our command-line (less the name of this script)
the_raptor = raptor.Raptor.CreateCommandlineAnalysis(sys.argv[1:])

# from Raptor.OpenLog()
try:
	# Find all the raptor plugins and put them into a pluginbox.
	if not the_raptor.systemPlugins.isAbsolute():
		the_raptor.systemPlugins = the_raptor.home.Append(the_raptor.systemPlugins)
		
	pbox = pluginbox.PluginBox(str(the_raptor.systemPlugins))
	raptor_params = raptor.BuildStats(the_raptor)

	# Open the requested plugins using the pluginbox
	the_raptor.out.open(raptor_params, the_raptor.filterList, pbox)
	
except Exception, e:
	sys.stderr.write("error: problem while creating filters %s\n" % str(e))
	traceback.print_exc()
	sys.exit(1)
		
# read stdin a line at a time and pass it to the Raptor object
try:
	line = " "
	while line:
		line = sys.stdin.readline()
		the_raptor.out.write(line)
except Exception,e:
	sys.stderr.write("error: problem while filtering: %s\n" % str(e))
	traceback.print_exc()
	sys.exit(1)


# Print the summary (this can't return errors)
the_raptor.out.summary()
	
if not the_raptor.out.close():
	the_raptor.errorCode = 2
	
# return the error code
sys.exit(the_raptor.errorCode)

