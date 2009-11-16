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
# oby2linux
#

"""
  Convert an OBY file into a form that rombuild on Linux can use.
  This involves converting paths etc.  In addition it finds those target
  files whose case may not match what exists on the filesystem
  (a build must have been completed).
 
  It also fills in those items that weren't built from a directory 
  containing a prebuild epoc32 dir.
"""


import sys
import os
import re

sys.path.append(os.environ['SBS_HOME']+'/python')
import generic_path

epocroot = os.environ['EPOCROOT']

try:
	romfillin_epocroot = os.environ['ROMFILLIN_EPOCROOT']
except:
	sys.stderr.write("Please set ROMFILLIN_EPOCROOT to a path with an epoc32 directory\n")
	sys.exit(1)

if not os.path.isdir(romfillin_epocroot+'/epoc32'):
	sys.stderr.write("Please set ROMFILLIN_EPOCROOT to a path with an epoc32 directory\n")
	sys.exit(1)

filestatement_re=re.compile("^(?P<pre>((((primary)|(secondary)|(extension)|(device)|(variant))(\[0x[0-9a-zA-Z]+\])?=)|((file)|(data)|(bootbinary))=))(?P<filename>\S+)(?P<tail>.*)$")

for line in sys.stdin.xreadlines():
	line = line.rstrip()
	m = filestatement_re.search(line)
	if m is not None:
		fname =  m.groupdict()['filename'].replace('\\','/').strip('"')
		filename = generic_path.Path(epocroot + fname)
		filefound = filename.FindCaseless()
		if filefound is not None:
			print m.groupdict()['pre'] + str(filefound) + m.groupdict()['tail']
			#print filefound
		else:
			fillinname = generic_path.Path(romfillin_epocroot+fname)
			filefound =  fillinname.FindCaseless()
			if filefound is not None:
				sys.stderr.write("filledinmissing: %s\n" % str(filefound))
				print m.groupdict()['pre'] + str(filefound) + m.groupdict()['tail']
				#print filefound
			else:
				sys.stderr.write("filenotfound: %s\n" % str(filename))
	else:
		print line

	

