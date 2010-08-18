#!/usr/bin/env python
#
# Copyright (c) 2007-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# display summary information about recipes from raptor logs
# e.g. total times and so on.

import time
import __future__




class RecipeStats(object):
	def __init__(self, name, count, time):
		self.name=name
		self.count=count
		self.time=time

	def add(self, duration):
		self.time += duration
		self.count += 1

class BuildStats(object):
	STAT_OK = 0


	def __init__(self):
		self.stats = {}
		self.failcount = 0
		self.failtime = 0.0
		self.failtypes = {}
		self.retryfails = 0
		self.hosts = {}
		
	def add(self, starttime, duration, name, status, host, phase):
		if status != BuildStats.STAT_OK:
			self.failcount += 1
			if name in self.failtypes:
				self.failtypes[name] += 1
			else:
				self.failtypes[name] = 1

			if status == 128:
				self.retryfails += 1
			return
			
		if name in self.stats:
			r = self.stats[name]
			r.add(duration)
		else:
			self.stats[name] = RecipeStats(name,1,duration)

		hp=host
		if hp in self.hosts:
			self.hosts[hp] += 1
		else:
			self.hosts[hp] = 1

	def recipe_csv(self):
		s = '"name", "time", "count"\n'
		l = sorted(self.stats.values(), key= lambda r: r.time, reverse=True)
		for r in l:
			s += '"%s",%s,%d\n' % (r.name, str(r.time), r.count)
		return s

	def hosts_csv(self):
		s='"host","recipecount"\n'
		hs = self.hosts
		for h in sorted(hs.keys()):
			s += '"%s",%d\n' % (h,hs[h])
		return s


import sys
import re
import os
from optparse import OptionParser # for parsing command line parameters

def main():
	recipe_re = re.compile(".*<recipe name='([^']+)'.*host='([^']+)'.*")
	time_re = re.compile(".*<time start='([0-9]+\.[0-9]+)' *elapsed='([0-9]+\.[0-9]+)'.*")
	status_re = re.compile(".*<status exit='(?P<exit>(ok|failed))'( *code='(?P<code>[0-9]+)')?.*")
	phase_re = re.compile(".*<info>Making.*?([^\.]+\.[^\.]+)</info>")

	parser = OptionParser(prog = "recipestats",
                                          usage = """%prog --help [-b] [-f <logfilename>]""")

	parser.add_option("-b","--buildhosts",action="store_true",dest="buildhosts_flag",
                                help="Lists which build hosts were active in each invocation of the build engine and how many recipes ran on each.", default = False)
	parser.add_option("-f","--logfile",action="store",dest="logfilename", help="Read from the file, not stdin", default = None)


	(options, stuff) = parser.parse_args(sys.argv[1:])

	if options.logfilename is None:
		f = sys.stdin
	else:
		f = open(options.logfilename,"r")

	st = BuildStats()


	alternating = 0
	start_time = 0.0

	phase=None
	for l in f:
		l2 = l.rstrip("\n\r")

		rm = recipe_re.match(l2)

		if rm is not None:
			(rname,host) = rm.groups()
			continue

		pm = phase_re.match(l2)

		if pm is not None:
			if phase is not None:
				if options.buildhosts_flag:
					print('"%s"\n' % phase)
					print(st.hosts_csv())
			st.hosts = {}	
			phase = pm.groups()[0]
			continue

		tm = time_re.match(l2)
		if tm is not None:
			try:
				s = float(tm.groups()[0])
				elapsed = float(tm.groups()[1])

				if start_time == 0.0:
					start_time = s

				s -= start_time

				continue
			except ValueError, e:
				raise Exception("Parse problem: float conversion on these groups: %s\n%s" %(str(tm.groups()), str(e)))
		else:
			if l2.find("<time") is not -1:
				raise Exception("unparsed timing status: %s\n"%l2)

		sm = status_re.match(l2)

		if sm is None:
			continue

		if sm.groupdict()['exit'] == 'ok':
			status = 0
		else:
			status = int(sm.groupdict()['code'])

		st.add(s, elapsed, rname, status, host, phase)

	if options.buildhosts_flag:
		print('"%s"\n' % phase)
		print(st.hosts_csv())
	else:
		print(st.recipe_csv())


if __name__ == '__main__': main()
