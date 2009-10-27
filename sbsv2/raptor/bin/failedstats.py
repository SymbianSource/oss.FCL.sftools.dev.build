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
# Generate some useful statistics from a Raptor build log
# Work out what was specified to make but not built even if
# it was not mentioned in the make error output because some
# child's dependency was not satisfied.
# Needs raptor --tracking option to set make to use -debug=v
# An example bit of make output that can be analysed:
#

 File `fred.exe' does not exist.
  Considering target file `fred.in'.
   File `fred.in' does not exist.
    Considering target file `a.o'.
     File `a.o' does not exist.
      Considering target file `a.c'.
       Finished prerequisites of target file `a.c'.
      No need to remake target `a.c'.
      Pruning file `a.c'.
     Finished prerequisites of target file `a.o'.
    Must remake target `a.o'.
cc    -c -o a.o a.c
    Successfully remade target file `a.o'.
    Considering target file `b.o'.
     File `b.o' does not exist.
      Considering target file `b.c'.
       Finished prerequisites of target file `b.c'.
      No need to remake target `b.c'.
      Pruning file `b.c'.
     Finished prerequisites of target file `b.o'.
    Must remake target `b.o'.
cc    -c -o b.o b.c
    Successfully remade target file `b.o'.
   Finished prerequisites of target file `fred.in'.
  Must remake target `fred.in'.
  Successfully remade target file `fred.in'.
 Finished prerequisites of target file `fred.exe'.
Must remake target `fred.exe'.
Successfully remade target file `fred.exe'.
"""

"""
Considering target file `/var/local/net/smb/tmurphy/pf/mcloverlay/common/generic/COMMS-INFRAS/ESOCK/commsdataobjects/src/provinfoqueryset.cpp'.
         Finished prerequisites of target file `/var/local/net/smb/tmurphy/pf/mcloverlay/common/generic/COMMS-INFRAS/ESOC
K/commsdataobjects/src/provinfoqueryset.cpp'.
"""

# The output is a filename followed by a number.  If the number is 0
# Then the prerequisites that file now exist.
# If > 0 then the prerequisites for that file could not be completed.

import sys
from  optparse import OptionParser
import re
import os
from stat import *

def findfailed(file):
	""" Find unbuilt files and prioritise them.  
	    Higher numbers go to files that didn't fail because
	    of prerequisites.

	    Rationale: files that failed because their prerequisites
	    failed are worth knowing about but cannot themselves be addressed.
	"""
	filecount = {}
	extre = re.compile(".*\.(?P<ext>[^'\/\"]+)$", re.I)
	startre = re.compile("[\t ]*File `(?P<file>[^']*)\' does not exist.*", re.I)
	zerore = re.compile("[\t ]*Successfully remade target file `(?P<file>[^']*)'\..*", re.I)
	#endre = re.compile("[\t ]*Finished prerequisites of target file `(?P<file>[^']*)'\..*", re.I)
	endre = re.compile("[\t ]*Giving up on target file `(?P<file>[^']*)'\..*", re.I)

	for x in file.readlines():
		g = startre.match(x)
		if g is not None:
			filename = g.group('file').strip('"')
			eg = extre.match(filename)
			if eg is not None:
				filecount[filename] = [1, eg.group('ext')]
			else:
				filecount[filename] = [1, "none"]

		else:
			g = zerore.match(x)
			if g is not None:
				# Complete success - not interesting.
				filename = g.group('file').strip('"')
				if filename in filecount:
					del filecount[filename]
			else:
				g = endre.match(x)
				if g is not None:
					# did manage to make the prerequisites, perhaps not the file
					filename = g.group('file').strip('"')
					if filename in filecount:
						filecount[filename][0] = 2
	return filecount

def showtargets(targets,prereq):
	output=[]	
	for k in targets:
		l = "%s\t%i\t%s" % (targets[k][1], targets[k][0], k)
		if prereq:
			if targets[k][0] == 2:
				# There were missing pre-requisites
				output.append(l)
		else:
				output.append(l)
	output.sort()
	for o in output:
		sys.stdout.write("%s\n" % o)

def readmake(file):
	rule = re.compile("^[^ :$]*:[^=]", re.I)
	for x in file.readlines():
		g = startre.match(x)
		if g is not None:
			filename = g.group('file').strip('"')
			eg = extre.match(filename)
			if eg is not None:
				ext = eg.group('ext')
			else:
				ext = "none"



parser = OptionParser(prog = "matchmade",
	usage = "%prog [-h | options] [ -d make database filename ] logfile")

parser.add_option("-m", "--missing-prerequistes", default = False,
	 action="store_true", dest="missing", help="List those targets whose pre-requisites could not be found or made") 

parser.add_option("-d","--make-db",action="store",dest="makedb",
                                help="name of make database")

(options, args) = parser.parse_args()

logname="stdin"
if len(args) > 0:
        logname=args[0]
        file = open(logname,"r")
else:
        file = sys.stdin

showtargets(findfailed(file),options.missing)
#assistmake(file,options.missing)

if file != sys.stdin:
	file.close()
