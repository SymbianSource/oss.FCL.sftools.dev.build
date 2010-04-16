#!/usr/bin/env python
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

class BuildStats(object):
	STAT_OK = 0


	def __init__(self):
		self.stats = {}
		self.failcount = 0
		self.failtime = 0.0
		self.failtypes = {}
		self.retryfails = 0
		
	def add(self, starttime, duration, name, status):
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

	def recipe_csv(self):
		s = '"name", "time", "count"\n'
		l = sorted(self.stats.values(), key= lambda r: r.time, reverse=True)
		for r in l:
			s += '"%s",%s,%d\n' % (r.name, str(r.time), r.count)
		return s



import sys
import re

def main():

	f = sys.stdin
	st = BuildStats()

	recipe_re = re.compile(".*<recipe name='([^']+)'.*")
	time_re = re.compile(".*<time start='([0-9]+\.[0-9]+)' *elapsed='([0-9]+\.[0-9]+)'.*")
	status_re = re.compile(".*<status exit='(?P<exit>(ok|failed))'( *code='(?P<code>[0-9]+)')?.*")

	alternating = 0
	start_time = 0.0

	
	for l in f.xreadlines():
		l2 = l.rstrip("\n\r")
		rm = recipe_re.match(l2)

		if rm is not None:
			rname = rm.groups()[0]
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

		st.add(s, elapsed, rname, status)

	print(st.recipe_csv())


if __name__ == '__main__': main()
