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
# Minimise the dependencies in a C preprocessor dependency file to
# those that CPP could not find.  Then add in an assumption about 
# where to find them.  Output is assumed to be relevant to only one target
# even if multiple dep files are analysed.
#

import sys
from  optparse import OptionParser
import os
import re

class NoTargetException(Exception):
	pass

def depcrunch(file,extensions,assume):
	target_pattern = r"^\s*(\S+):\s+"
	target_re = re.compile(target_pattern)
	extension_pattern = "[ \t]([^\/\\ \t]+\.(" + "|".join(["("+ t + ")" for t in extensions]) + "))\\b"
	extension_re = re.compile(extension_pattern)

	target = None

	deps = []

	for l in file.xreadlines():
		l = l.replace("\\","/").rstrip("\n\r")

		if not target:
			t = target_re.match(l)
			if t:
				target = t.groups()[0]
		
		m = extension_re.match(l)
		if m:
			deps.append(m.groups()[0])

	if not target:
		raise NoTargetException()

	if len(deps) > 0:
		print "%s: \\" % target
		for d in deps[:-1]:
			print " %s \\" % (assume + "/" + d)
		print " %s " % (assume + "/" + deps[-1])




## Command Line Interface ####################################################

parser = OptionParser(prog = "depcrunch",
	usage = "%prog [-h | options] [<depfile>]")

parser.add_option("-e", "--extensions", 
	 action="store", dest="extensions", type='string', help="comma separated list of file extensions of missing files to keep in the crunched dep file.") 

parser.add_option("-a", "--assume", 
	 action="store", dest="assume", type='string', help="when cpp reports missing dependencies, assume that they are in this directory") 

(options, args) = parser.parse_args()


if not options.extensions:
	parser.error("you must specify a comma-separated list of file extensions with the -t option.")
	sys.exit(1)

if not options.assume:
	parser.error("you must specify an 'assumed directory' for correcting missing dependencies with the -a option.")
	sys.exit(1)

depfilename="stdin"
if len(args) > 0:
	depfilename=args[0]
	file = open(depfilename,"r")
else:
	file = sys.stdin
try:
	depcrunch(file,options.extensions.split(","), options.assume)
except NoTargetException,e:
	sys.stderr.write("Target name not found in dependency file");
	sys.exit(2)
	

if file != sys.stdin:
	file.close()

sys.exit(0)
