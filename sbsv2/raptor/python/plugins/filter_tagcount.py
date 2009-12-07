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
# Example of a Filter class using the SAX parser base class
#

import filter_interface

class FilterTagCounter(filter_interface.FilterSAX):
	
	def startDocument(self):
		# for each element name count the number of occurences
		# and the amount of body text contained.
		self.names = []
		self.count = {}
		self.errors = 0
		self.fatals = 0
		self.warns = 0
		
	def startElement(self, name, attributes):
		if name == "buildlog":
			# print out the attributes of the "top" element
			print "version:"
			for a,v in attributes.items():
				print a, "=", v
		
		# push name onto the stack of names and increment the count
		self.names.append(name)
		if name in self.count:
			self.count[name][0] += 1
		else:
			self.count[name] = [1, 0]    # occurs, characters	
	
	def characters(self, char):
		# these are for the current element
		current = self.names[-1]
		self.count[current][1] += len(char)
		
	def endElement(self, name):
		# pop the name off the stack
		self.names.pop()
	
	def endDocument(self):
		# report
		print "\nsummary:"
		for name,nos in sorted(self.count.items()):
			print name, nos[0], nos[1]
			
		print "\nparsing:"
		print "errors =", self.errors
		print "fatals =", self.fatals
		print "warnings =", self.warns
	
	def error(self, exception):
		self.errors += 1
		
	def fatalError(self, exception):
		self.fatals += 1
		
	def warning(self, exception):
		self.warns += 1
	
# the end
