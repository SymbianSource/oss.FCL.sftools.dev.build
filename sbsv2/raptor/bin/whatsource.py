#
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
#

#!/bin/env python
# What source files did the build try to build?

import sys
import re
from  optparse import OptionParser
from raptorlog import *


def genstats(file, logitems):
	linecount=0
	print "<source>"
	for l in file.xreadlines():
		for i in logitems:
			i.match(l)
	print "</source>"


## Command Line Interface ####################################################

parser = OptionParser(prog = "whatsource",
	usage = "%prog [-h | options] logfile\nFind out what source files the compiler tried to build")

(options, args) = parser.parse_args()

logname="stdin"
if len(args) > 0:
	logname=args[0]
	file = open(logname,"r")
else:
	file = sys.stdin


compiler_invocations = [ 
	LogItem("armcc usage",'\+ .*armcc.*-c', True, '[A-Za-z0-9_/\-\.]+\.cpp'),
	] 

genstats(file, compiler_invocations)

if file != sys.stdin:
	file.close()
