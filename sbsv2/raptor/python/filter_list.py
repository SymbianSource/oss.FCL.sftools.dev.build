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
# Class to control array of defined logging filters
# This class will act as a switch, controlling the list of filters iteratively
#

import os
import sys
import raptor
import filter_interface
import pluginbox
import traceback

class FilterWriteException(Exception):
	def __init__(self, value):
		self.parameter = value
	def __str__(self):
		return repr(self.parameter)

class BootstrapFilter(filter_interface.Filter):
	def __init__(self):
		self.out = sys.stdout

	"""Use this until the CLI has supplied some real filters"""
	def open(self, raptor_instance):
		"""Set output to stdout for the various I/O methods to write to."""
		self.raptor = raptor_instance
		return True
		
	def write(self, text):
		"""Write errors and warnings to stdout"""
		
		if text.startswith("<error>"):
			start = text.find(">")
			end = text.rfind("<")
			self.out.write(str(raptor.name) + ": error: %s\n" \
					% text[(start + 1):end])
		elif text.startswith("<warning"):
			start = text.find(">")
			end = text.rfind("<")
			self.out.write(str(raptor.name) + ": warning: %s\n" \
					% text[(start + 1):end])
		elif "error" in text or "warning" in text:
			self.out.write(text)
		return True

	def summary(self):
		"""Write Summary"""
		return False
	
	def close(self):
		"""Nothing to do for stdout"""
		return True



class FilterList(filter_interface.Filter):

	def __init__(self):
		self.out = [BootstrapFilter()]
		self.filters = []
		self.pbox = None

	def open(self, raptor_instance, filternames, pbox):
		"""
			Call open function on each filter using raptor parameters provided
			Returns: Boolean: Have the functions succeeded in opening the files?
		"""
		# Find all the filter plugins
		self.pbox = pbox
		possiblefilters = self.pbox.classesof(filter_interface.Filter)
		unfound = []
		self.filters = []
		for f in filternames:
			unfound.append(f) # unfound unless we find it
			for pl in possiblefilters:
				if pl.__name__.upper() == f.upper():
					self.filters.append(pl())
					unfound = unfound[:-1]
		if unfound != []:
			raise ValueError("requested filters not found: %s \
			\nAvailable filters are: %s" % (str(unfound), self.format_output_list(possiblefilters)))

		if self.filters == []:
			self.out = [BootstrapFilter()]
		else:
			self.out=[]
			for filter in self.filters:
				if filter.open(raptor_instance):
					self.out.append(filter)
				else:
					sys.stderr.write(str(raptor.name) + \
							": error: Cannot open filter: %s\n" % str(filter))
					ok = False
					
			if self.out == []:
				sys.stderr.write(str(raptor.name) + \
						": warning: All filters failed to open. " + \
						"Defaulting to 'stdout'\n")
				self.out = [BootstrapFilter()]

	def write(self, text):
		"""
			Iterate through each filter, calling their write function
		"""

		if text is None:
			return

		badfilters = []
		for filter in self.out:
			try:
				filter.write(text)
			except Exception,e:
				traceback.print_exc(file=sys.stdout)
				sys.stdout.write("Called from: \n")
				traceback.print_stack(file=sys.stdout)
				sys.stdout.write("\n")
				badfilters.append(filter)

		if len(badfilters) > 0:
			for f in badfilters:
				self.out.remove(f) # dump the filter in case it causes repeated exceptions
				sys.stdout.write("Removed filter %s because it generated an exception\n" % type(f))

			if len(self.out) == 0:
				sys.stdout.write("Falling back to bootstrap filter\n")
				self.out = [BootstrapFilter()] # Try to fall back to something in the worst case

	def summary(self):
		"""
			Run the summaries of all filters (prior to log end)
		"""
		for filter in self.out:
			filter.summary()

	def close(self):
		"""
			Iterate through each filter, calling their close function
			Returns True if all the filters close properly
		"""
		returnVal = True
		
		for filter in self.out:
			if (filter != sys.stdout) and (filter != sys.stderr):
				returnVal = returnVal and filter.close()
		
		return returnVal

	def format_output_list(self, possiblefilters):
		"""
			formats available filters
		"""
		filters_formatted = ""
		for pl in possiblefilters:
			filters_formatted += "\n  " + pl.__name__
		return filters_formatted
		
