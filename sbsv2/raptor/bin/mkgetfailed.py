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

# The output is a filename followed by a number.  If the number is 0
# Then the prerequisites that file now exist.
# If > 0 then the prerequisites for that file could not be completed.

import sys
from  optparse import OptionParser
import re
import os
from stat import *

def genstats(file,showmissing):
	filecount = {}
	startre = re.compile("[\t ]*File `(?P<file>[^']*)' does not exist")
	endre = re.compile("[\t ]*Finished prerequisites of target file `(?P<file>[^']*)'\..*")
	for x in file.readlines():
		g = startre.match(x)
		if g is not None:
			filename = g.group('file')
			try:
				filecount[filename] += 1
			except KeyError:
				filecount[filename] = 1
		else:
			g = endre.match(x)
			if g is not None:
				filename = g.group('file')
				try:
					filecount[filename] -= 1
				except KeyError:
					filecount[filename] = 0
	
	for k in filecount:
		if showmissing:
			if filecount[k] > 0:
				print "%s: %i" % (k,filecount[k])
		else:
			print "%s: %i" % (k,filecount[k])


parser = OptionParser(prog = "matchmade",
	usage = "%prog [-h | options] logfile")

parser.add_option("-m", "--missing-prerequistes", default = False,
	 action="store_true", dest="missing", help="List those targets whose pre-requisites could not be found or made") 

(options, args) = parser.parse_args()

logname="stdin"
if len(args) > 0:
	logname=args[0]
	file = open(logname,"r")
else:
	file = sys.stdin

genstats(file,options.missing)

if file != sys.stdin:
	file.close()
