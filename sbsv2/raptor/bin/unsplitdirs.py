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
# unsplitdirs utility
# This utility converts a directory tree which may contain "splits" due to case inconsistencies into
# a combined form.  This is best illustrated as follows:
# epoc32/RELEASE/ARMV5/urel
# epoc32/Release/armv5/UREL
# epoc32/RELEASE/armv5/Urel
# are "healed by this script into:
# epoc32/RELEASE/ARMV5/urel  (i.e. the first occurrence.
#

#
# Files within these directories are maintained. i.e. it is possible to fix 
# a directory tree with files already left in it.
#
 

import os
import os.path
import re
import sys
import shutil
from  optparse import OptionParser

def mergetwo(firstdir, seconddir):
# Move files from firstdir into seconddir.  If firstdir and seconddir both have 
# a directory "X" then combines the contents of theses
	for d in os.listdir(firstdir):
		fileitem = os.path.join(firstdir,d)
		dest = os.path.join(seconddir,d)
		print "moving %s, %s to %s " % (d, fileitem, dest)
		if os.path.isdir(dest) and os.path.isdir(fileitem):
			mergetwo(fileitem, dest)
			try:
				os.rmdir(fileitem)
			except:
				print "\tfailed rmdir %s" % fileitem
		else:
			shutil.move(fileitem, dest)
	try:
		os.rmdir(firstdir)
	except:
		print "\tfailed rmdir %s" % firstdir
	
	

def visit(dirname, link = False):
# Find directories with names that differ only in case
	nameclash = {}
#	print "dir %s\n" %(dirname)
	for f in os.listdir(dirname):
		fullpath = os.path.join(dirname,f)
		if os.path.isdir(fullpath) and not os.path.islink(fullpath):
		#	print "\tmergeable %s" %(f)
			fl = f.lower()
			if nameclash.has_key(fl):
				mergetwo(fullpath, os.path.join(dirname, nameclash[fl]))
				if link:
					print "\tlinking %s <- %s" %(nameclash[fl], fullpath)
					os.symlink(nameclash[fl], fullpath)
			else:
				nameclash[fl] = f
		else:
			pass
		#	print "%s is not a dir\n" %(f)

	for d in nameclash.values():
	#	print "\tVisiting %s" %(d)
		visit(os.path.join(dirname, d))


dirname = sys.argv[1]

parser = OptionParser(prog = "unsplitdirs",
        usage = "%prog [-h | options] [<file>]")

parser.add_option("-l", "--link", default = False,
         action="store_true", dest="link", help="Turn mismatched-case directories into symbolic links e.g. if armv5 is the default then make the link ARMV5->armv5")

(options, args) = parser.parse_args()

logname="stdin"
if len(args) > 0:
        dirname = args[0]
else:
	dirname ='.'

visit(dirname, options.link)
