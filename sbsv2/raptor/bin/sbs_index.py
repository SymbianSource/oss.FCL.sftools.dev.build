#!/usr/bin/python

# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Symbian Foundation License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".

'''
Tie together a set of HTML build summaries by creating a single index page
which shows the total number of Errors, Warnings etc. across all the parts
of the build and links to the individual summaries.
'''

import os
import sys
import time

# get the absolute path to this script
script = os.path.abspath(sys.argv[0])
bindir = os.path.dirname(script)
# add the Raptor python and plugins directories to the PYTHONPATH
sys.path.append(os.path.join(bindir, "..", "python"))
sys.path.append(os.path.join(bindir, "..", "python", "plugins"))

if len(sys.argv) < 3:
	sys.stderr.write("""usage: %s input_dir1 [input_dir2...] output_index_file
	
The input directories are scanned recursively for totals.txt files and all
those found are added to the generated index.
""" % os.path.basename(script))
	sys.exit(1)

roots = []
for a in sys.argv[1:-1]:
	if os.path.isdir(a):
		roots.append(a)
	else:
		sys.stderr.write("warning: %s is not a directory\n" % a)

indexfile = sys.argv[-1]
indexdir = os.path.dirname(indexfile)
	
def findtotals(dirs, files):
	"recurse directories until we find a totals.txt file."
	sub = []
	for d in dirs:
		name = os.path.join(d, "totals.txt")
		if os.path.isfile(name):
			files.append(name)
		else:
			for s in os.listdir(d):
				dir = os.path.join(d,s)
				if os.path.isdir(dir):
					sub.append(dir)
	if sub:
		findtotals(sub, files)

totals = []
findtotals(roots, totals)
totals.sort()

# look for a style file we can link to
css = "style.css"
for t in totals:
	c = os.path.join(os.path.dirname(t),"style.css")
	if os.path.isfile(c):
		css = os.path.relpath(c, indexdir)
		break
	
# write the header of the index
import filter_html
try:
	index = open(indexfile, "w")
	index.write("""<html>
<head>
<title>Raptor Build Index</title>
<link type="text/css" rel="stylesheet" href="%s">
</head>
<body>
<h1>Raptor Build Index</h1>
<table>
<tr><th>build</th>""" % css)

	for i in filter_html.Records.TITLES:
		index.write('<th class="numbers">%s</th>' % i)
	index.write("</tr>")
except:
	sys.stderr.write("error: cannot write index file %s\n" % indexfile)
	sys.exit(1)
	
import csv
grandtotal = [0 for i in filter_html.Records.TITLES]

for t in totals:
	columns = []
	try:
		reader = csv.reader(open(t, "rb"))
		for row in reader:
			type = int(row[0])
			style = row[1]
			
			if style == 'time':
				count = float(row[2])
			else:
				count = int(row[2])
				
			if count == 0 or filter_html.Records.CLASSES[type] == style:
				grandtotal[type] += count
				columns.append((style,count))
			else:
				sys.stderr.write("warning: %s appears to be corrupt or out of date\n" % t)	
	except:
		sys.stderr.write("warning: %s could not be read\n" % t)

	if len(columns) == len(filter_html.Records.TITLES):
		try:
			linktext = os.path.dirname(t)
			linkname = os.path.relpath(os.path.join(linktext, "index.html"), indexdir)
			index.write('<tr><td class="name"><a href="%s">%s</a></td>' % (linkname, linktext))
			for (style, count) in columns:
				if style == 'time':
					n = time.strftime("%H:%M:%S", time.gmtime(count + 0.5))
				else:
					n = str(count)
				index.write('<td class="%s">%s</td>' % (style, n))
			index.write("</tr>")
		except:
			sys.stderr.write("error: cannot write index file %s\n" % indexfile)
			sys.exit(1)
	
# finish off
try:
	index.write('<tr><td>&nbsp;</td></tr><tr><td class="name">total</td>')
	for i, count in enumerate(grandtotal):
		style = filter_html.Records.CLASSES[i]
		if style == 'time':
			n = time.strftime("%H:%M:%S", time.gmtime(count + 0.5))
		else:
			n = str(count)
					
		if count == 0:
			index.write('<td class="zero">0</td>')
		else:
			index.write('<td class="%s">%s</td>' % (style, n))
	index.write("</tr></table>")
	index.write("</body></html>\n")
	index.close()

except:
	sys.stderr.write("error: cannot close index file %s\n" % indexfile)
	sys.exit(1)
			
sys.exit(0)