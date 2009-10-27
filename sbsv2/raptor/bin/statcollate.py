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
# statcollate
#

"""
	Produce output for a graphing program or spreadsheet from
	the statistic logs produced by buildstats.py from Raptor logs.
	e.g. by analysing several logs we can see how
	"number of successful compiles" improves over time.
"""

import sys
from optparse import OptionParser
import os
import xml.dom.minidom
from stat import *

namespace = "http://symbian.com/2007/xml/build/raptor/stats"

class StatsFail(Exception):
	pass

def pullStats(statnames, file):
	"""Load a Statistics document and pull stats for a graph"""

	# try to read and parse the XML file
	try:
	    dom = xml.dom.minidom.parse(file)

	except Exception,e: # a whole bag of exceptions can be raised here
		print "pullStats: %s" % str(e)
		raise StatsFail

	# <build> is always the root element
	stats = dom.documentElement
	objects = []
	build = stats.childNodes[1]
	
	# create a Data Model object from each sub-element
	output = {}
	output['date'] = build.getAttribute('date')
	#print "statnames %s\n" % str(statnames)   #test
	for child in build.childNodes:
	    if child.namespaceURI == namespace \
        and child.nodeType == child.ELEMENT_NODE \
        and child.hasAttributes():
                #print "child node %s\n" % child.getAttribute('name')   #test
                name = child.getAttribute('name')
                if name in statnames:
                    #print "1"  #test
                    output[name] = child.getAttribute('count')

	return output

statnames = ['postlink success', 'compile success', 'compile fail']

## Command Line Interface ################################################

parser = OptionParser(prog = "statgraph",
        usage = "%prog [-h | options] [<statsfile>] [[<statsfile>] ...]")

(options, args) = parser.parse_args()

statfilename = "stdin"

table = sys.stdout
print >> table, 'Date,',  # add 'Date' in front of names

comma=""
for name in statnames:
    print >> table, comma+name, #! this order is not the order in dictionary
    comma=', '
    #print 'test,',  #test

print >> table, ""

if len(args) > 0:
    for statfilename in args:
        sys.__stderr__.write("Loading %s\n" % statfilename)
        file = open(statfilename, "r")
        try:
            stats = pullStats(statnames, file)
        except StatsFail,e:
            sys.__stderr__.write("Can't process file %s\n" % statfilename)
            sys.exit(1)
        #print stats.items()  # test
        file.close()
        
	comma=""
        print >> table, stats['date'] + ",",
        for name in statnames:
            print >> table, comma+stats[name],
    	    comma=', '
            #print 'test,',  # test
        print >> table, ""

else:
    sys.stderr.write("No files specified")
    #pullStats(statnames,sys.stdin)
