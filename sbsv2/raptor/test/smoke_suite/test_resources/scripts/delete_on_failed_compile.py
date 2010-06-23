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
# delete_on_failed_compile.py
# This is a test module for verifying the delete on failed compile 
# work around for RVCT 2.2. It creates a dummy object file and 
# exits with an error code which should result in object files being deleted.
# It takes the same arguments as armcc, but ignores them all apart from -o.
#

import sys
import os
import re

# Parse for -o argument.
objectfile_re = re.compile(".*-o\s(\S*\.(o|pre))\s.*", re.I)
res = objectfile_re.match(" ".join(sys.argv[1:]))

if res:
	objectpath = res.group(1)
	print "Found object file %s" % objectpath
	objectdirectory = os.path.dirname(objectpath)
	
	# Make the directory if it doesn't exist
	if not os.path.isdir(objectdirectory):
		try:
			os.makedirs(objectdirectory)
		except:
			print "Not making directory %s" % objectdirectory
	
	# Try to write something to the .o file
	try:
		fh = open(objectpath, "w")
		fh.write("Fake object file for delete on failed compile test\n")
		fh.close()
	except Exception as error:
		print "Failed to created object file %s; error was: %s" % (objectfile, str(error))
else:
	print "Failed to determine object filename. Commandline used was: %s" % " ".join(sys.argv[1:])

# Always exit with an error
print "Exiting with non-zero exit code." 
sys.exit(1)

