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
# fixmeta
#

"""
  Correct bld.infs, mmps etc to the point where it can be read by the build system
  Currently it:
  	Corrects '\' in include statements to '/'

  Author: Tim Murphy, with a nod to Peter Harper's fixslashes.pl
"""

import sys
import os
import re
from  optparse import OptionParser


includeslash_re = re.compile('#include.*\\\\')
mmpfile_re = re.compile(".*\.mm[hp]$", re.I)
bldinf_re = re.compile(".*bld\.inf$", re.I)

def fixincludeslash(m):
	return m.group(0).replace('\\','/')
	

def checkconvert(dirname, filename):
	tofilename=dirname + "/" + filename+".converted"
	fromfilename = dirname + "/" + filename
	fromfile = open(fromfilename,"r")

	conversions = False
	fromtext = fromfile.read()
	(totext, subcount) = re.subn(includeslash_re, fixincludeslash, fromtext)

	if subcount != 0:
		print '"%s", %d backslash includes\n' % (fromfilename, subcount)
		tofile = open( tofilename,"w")
		tofile.write(totext)
		tofile.close()

	fromfile.close()
	if subcount != 0:
		os.rename(fromfilename,fromfilename+".wrongslash")
		os.rename(tofilename,fromfilename)
	
	

def visit(arg, dirname, names):
	#print "dir: %s\n" % (dirname)
	for f in names:
		m = mmpfile_re.match(f)
		b = bldinf_re.match(f)
		if m != None or b != None:
			#print "\t"+f
			checkconvert(dirname, f)

parser = OptionParser(prog = "fixmeta",
        usage = "%prog [-h | options] sourcepath containing files to be fixed.")

(options, args) = parser.parse_args()

if len(args) == 0:
	print "Need at least one argument: a path to the source which is to be fixed."
	sys.exit(-1)

print "Walking\n"
os.path.walk(args[0],visit,None)
