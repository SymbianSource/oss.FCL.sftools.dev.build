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
#

import sys
from  optparse import OptionParser
from raptorlog import *
import os
from stat import *
import time

def genstats(file, logitems, logdate):
	bytecount=0.0
	lastbytecount=0.0
	print """<?xml version="1.0" encoding="UTF-8"?>
       <stats xmlns="http://symbian.com/2007/xml/build/raptor/stats"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://symbian.com/2007/xml/build/raptor/stats http://symbian.com/2007/xml/build/raptor/stats1_0.xsd">
	"""

	if S_ISREG(os.stat(file.name)[ST_MODE]) > 0:
	 	totalbytes = os.stat(file.name)[ST_SIZE]+0.0
	else:
		totalbytes=0.0

	print "<build log='%s' size='%9.0f' date='%s'>" % (file.name,totalbytes,logdate)
	for l in file.xreadlines():
		if totalbytes > 0.0:
			bytecount += len(l)
			if (bytecount-lastbytecount)/totalbytes > 0.05:
				lastbytecount = bytecount
				sys.stderr.write("%3.0f %%" % ((bytecount/totalbytes)*100.0))

		for i in logitems:
			i.match(l)

	for i in logitems:
		print i.xml()+"\n"
		
	print "</build>"
	print "</stats>"



## Command Line Interface ####################################################

parser = OptionParser(prog = "buildstats",
	usage = "%prog [-h | options] [<file>]")

parser.add_option("-k", "--keep", default = False,
	 action="store_true", dest="keep", help="Retain matched log lines and display them.") 
parser.add_option("-d", "--logdate", default = None,
	 action="store", dest="logdate", help="Specify the date on which the log was started (yyyymmdd).") 

(options, args) = parser.parse_args()

logname="stdin"
if len(args) > 0:
	logname=args[0]
	file = open(logname,"r")
	if options.logdate != None:
		logdate = options.logdate
	else:
		logdate = time.strftime("%Y%m%d",time.localtime(os.stat(file.name)[ST_CTIME]))
else:
	file = sys.stdin
	logdate = time.strftime("%Y%m%d")


if options.keep != False:
	LogItem.keep = True



logitems = [ 
	LogItem("compile attempt", "<compile.*>"), 
	LogItem("compile success", "<buildstat [^<]*name='compile'[^<]*/>"), 
	LogItem("compile fail", "<buildstat [^<]*name='failed_compile'[^<]*/>"), 
	LogItem('link attempt','<link>'), 
	LogItem("link success", "<buildstat [^<]*name='link'[^<]*/>"), 
	LogItem("link fail", "<buildstat [^<]*name=.failed_link.[^<]*/>"), 
	LogItem('postlink attempt','<postlink.*>'), 
	LogItem("postlink success", "<buildstat [^<]*name=.postlink[^<]*/>"), 
	LogItem("postlink fail", "<buildstat [^<]*name=.failed_postlink.[^<]*/>"), 
	LogItem('flmcalls', '<flm'), 
	LogItem('e32 flmcalls', "<flm +name=[\"']e32abiv2[\"'].* type=[\"'](?!implib)"),
	#LogItem('mmp_processed', "<parsing[ \t]*file='.*\.[Mm][Mm][Pp]'.*>"),
	#LogItem('bldinf_processed', "Processing bld.inf:"),
	LogItem('armar','armar'),
	LogItem("failed stringtable export", "<buildstat [^<]*name=.failed_exportstringtableheader.[^<]*/>"), 
	LogItem("failed template extension makefile", "<buildstat [^<]*name=.failed_tem.[^<]*/>"), 
	LogItem("make error",'^make: \*\*\*.*$', True),
	LogItem("make no rule",'^make: \*\*\*.* No rule to make target.*$', True),
	LogItem("raptor error",'^ERROR: raptor:*$', True),
	LogItem("armcc/armcpp error",'^.*line [0-9]+:.*Error: *#[0-9]+.*$', True),
	LogItem("gcc/gcc-cpp error",'^[^ \t]+:[0-9]+:[0-9]+ .+:.+$', True),
	LogItem("armlink error",'^Error: *L[0-9A-F]+:.*$', True),
	LogItem("Resource File error",'[\t ]*Error:.*cannot open source input file.*\.[Rr][Ss][Gg]\".*$', True),
	LogItem("String Table error",'[\t ]*Error:.*cannot open source input file.*[Ss]tr[^ ]*\.h\".*$', True),
	LogItem("Armcc license fail",'^.*Error: C3397E: Cannot obtain license for Compiler.*'),
	LogItem("Armlink license fail",'^.*Error: ......: Cannot obtain license for .*ink.*')
	] 

genstats(file,logitems,logdate)

if file != sys.stdin:
	file.close()
