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

	Raptor log parsing utilities.

	Line-by-line based log reporting.
"""

import re


class LogItem(object):
	keep = False
	def __init__(self, name, pattern, keep=False, subpattern=None):
		self.name = name
		self.matcher = re.compile(pattern, re.I)
		self.count = 0

		if subpattern:
			self.subpattern = re.compile(subpattern,re.I)
		else:
			self.subpattern = None

		if keep and LogItem.keep:
			self.keep = {}
		else:
			self.keep = None

		self.subpatterncount = 0

	def xml(self):
		xml = "<logitem name='%s' count='%i' subpatterncount='%i' " % ( self.name, self.count,  self.subpatterncount)
		if self.keep == None:
			return xml + " />"

		xml += ">\n"

		index = self.keep.keys()
		index.sort(cmp=lambda y,x: self.keep[x] - self.keep[y])
		for i in index:
			xml += "<match count='" + str(self.keep[i]) +"'><![CDATA[\n" + i + "]]></match>\n"
		
		return xml + "</logitem>"

	def match(self, line):
		result = self.matcher.search(line)
		if result != None:
			if self.keep != None:
				try:
					self.keep[result.group()] += 1
				except:
					self.keep[result.group()] = 1
			if self.subpattern != None:
				self.subpatterncount += len(self.subpattern.findall(line))
				for i in self.subpattern.findall(line):
					print i
			self.count += 1

