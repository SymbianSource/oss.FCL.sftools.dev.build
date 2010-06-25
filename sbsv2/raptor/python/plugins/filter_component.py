#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Filter class to print log entries for a selected component
#

import filter_interface
import sys

class FilterComp(filter_interface.FilterSAX):
	
	def __init__(self, params = []):
		"""parameters to this filter are the path of the bld.inf and some flags.
		
		The bld.inf path can be a substring of the path to match. For example,
		"email" will match an element with bldinf="y:/src/email/group/bld.inf".
		
		No flags are supported yet; this is for future expansion.
			
		If no parameters are passed then nothing is printed."""
		self.bldinf = ""
		self.flags = ""
		
		if len(params) > 0:
			self.bldinf = params[0]
			
		if len(params) > 1:
			self.flags = params[1]
		
		super(FilterComp, self).__init__()
		
	def startDocument(self):
		# mark when we are inside an element with bldinf="the selected one"
		self.inside = False
		# and count nested elements so we can toggle off at the end.
		self.nesting = 0
	
	def printElementStart(self, name, attributes):
		sys.stdout.write("<" + name)
		for att,val in attributes.items():
			sys.stdout.write(" " + att + "='" + val + "'")
		sys.stdout.write(">")
		
	def startElement(self, name, attributes):
		if self.inside:
			self.nesting += 1
			self.printElementStart(name, attributes)
			return
		
		if self.bldinf:
			try:
				if self.bldinf in attributes["bldinf"]:
					self.inside = True
					self.nesting = 1
					self.printElementStart(name, attributes)
			except KeyError:
				pass
			
	def characters(self, char):
		if self.inside:
			sys.stdout.write(char)
		
	def endElement(self, name):
		if self.inside:
			sys.stdout.write("</" + name + ">")
			
		self.nesting -= 1
		
		if self.nesting == 0:
			self.inside = False
			print
	
	def endDocument(self):
		pass
	
	def error(self, exception):
		print filter_interface.Filter.formatError("FilterComp:" + str(exception))
		
	def fatalError(self, exception):
		print filter_interface.Filter.formatError("FilterComp:" + str(exception))
		
	def warning(self, exception):
		print filter_interface.Filter.formatWarning("FilterComp:" + str(exception))
	
# the end
