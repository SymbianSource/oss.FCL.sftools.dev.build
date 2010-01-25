#!/usr/bin/python

# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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

import re
import sys

# there are no options, so print help if any are passed
if len(sys.argv) > 1:
	print "usage:", sys.argv[0], "(The log data is read from stdin)"
	sys.exit(0)

whatlogRE = re.compile("<whatlog.*bldinf='([^']*)'")
exportRE = re.compile("<export destination='(.*)' source='(.*)'")

bldinf = "unknown"
sources = {}		# lookup from source to destination
destinations = {}	# lookup from destination to source

chains = 0
repeats = 0
conflicts = []

# read stdin a line at a time and soak up all the exports
line = " "
while line:
	line = sys.stdin.readline()

	whatlogMatch = whatlogRE.search(line)
	if whatlogMatch:
		bldinf = whatlogMatch.group(1).lower()
		continue

	exportMatch = exportRE.search(line)
	if exportMatch:
		destination = exportMatch.group(1).lower()
		source = exportMatch.group(2).lower()

		if destination in destinations:
			(otherSource, otherBldinf) = destinations[destination]
			
			# same source and destination but different bld.inf => repeat	
			if source == otherSource and bldinf != otherBldinf:
				# only interested in the number for now
				repeats += 1
				
			# different source but same destination => conflict
			if source != otherSource:
				conflict = (source, destination, bldinf, otherSource, otherBldinf)
				tcilfnoc = (otherSource, destination, otherBldinf, source, bldinf)
				
				if conflict in conflicts or tcilfnoc in conflicts:
					# seen this conflict before
					pass
				else:
					print "CONFLICT:", destination, \
						"FROM", source, \
						"IN", bldinf, \
						"AND FROM", otherSource, \
						"IN", otherBldinf
					conflicts.append(conflict)
		else:
			sources[source] = [destination, bldinf]
			destinations[destination] = [source, bldinf]

# now check for destinations which were also sources => chains
for destination in destinations:
	if destination in sources:
		(nextDestination, inf2) = sources[destination]
		(source, inf1) = destinations[destination]
		print "CHAIN:", source, \
			"TO", destination, \
			"IN", inf1, \
			"THEN TO", nextDestination, \
			"IN", inf2
		chains += 1
		
# print a summary
print "Total exports = ", len(destinations.keys())
print "Chained exports = ", chains
print "Repeated exports = ", repeats
print "Conflicting exports = ", len(conflicts)

# return the error code
if conflicts:
	sys.exit(1)
sys.exit(0)

