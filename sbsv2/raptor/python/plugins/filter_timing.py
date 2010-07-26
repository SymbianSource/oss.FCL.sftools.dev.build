#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Base Class for defining filter classes
# All filter classes that get defined should derive from this base class
#

import errno
import filter_interface
import os
import raptor
import raptor_timing
import sys

class FilterTiming(filter_interface.Filter):
	"""
		Writes a logfile containing the timings for each Raptor process
	"""
	
	def open(self, raptor_instance):
		"""
			Open a log file with the same name as the Raptor log file, with
					'.timings' appended. This will contain only 'progress'
					timing tags from the Raptor output
			Parameters:
				raptor_instance - Raptor
					Instance of Raptor. FilterList usually passes in a cut-down
							version of Raptor containing only a few attributes
		"""
		self.raptor = raptor_instance
		self.logFileName = self.raptor.logFileName
		# insert the time into the log file name
		if self.logFileName:
			self.path = (self.logFileName.path.replace("%TIME",
					self.raptor.timestring) + ".timings")
	
			try:
				dirname = str(self.raptor.logFileName.Dir())
				if dirname and not os.path.isdir(dirname):
					os.makedirs(dirname)
			except os.error, e:
				if e.errno != errno.EEXIST:
					sys.stderr.write("%s : error: cannot create directory " +
							"%s\n" % (raptor.name, dirname))
					return False
			try:
				self.out = open(str(self.path), "w")
			except:
				self.out = None
				sys.stderr.write("%s : error: cannot write log %s\n" %\
					(raptor.name, self.path))
				return False
		self.start_times = {}
		self.all_durations = []
		self.namespace_written = False
		self.open_written = False
		return True
				
				
	def write(self, text):
		"""
			Write out any tags with a 'progress_' tagName
		"""
		if "<progress:discovery " in text:
			self.out.write(text)
		elif "<progress:start " in text:
			attributes = raptor_timing.Timing.extract_values(source = text)
			self.start_times[(attributes["object_type"] + attributes["task"] +
					attributes["key"])] = attributes["time"]
		elif "<progress:end " in text:
			attributes = raptor_timing.Timing.extract_values(source = text)
			duration = (float(attributes["time"]) -
					float(self.start_times[(attributes["object_type"] +
					attributes["task"] + attributes["key"])]))
			self.out.write(raptor_timing.Timing.custom_string(tag = "duration",
					object_type = attributes["object_type"],
					task = attributes["task"], key = attributes["key"],
					time = duration))
			self.all_durations.append(duration)
		elif text.startswith("<?xml ") and not self.namespace_written:
			self.out.write(text)
			self.namespace_written = True
		elif text.startswith("<buildlog ") and not self.open_written:
			self.out.write(text)
			self.open_written = True
		return True	

			
	def summary(self):
		"""
			Print out extra timing info
		"""
		total_time = 0.0
		for duration in self.all_durations:
			total_time += duration
		self.out.write(raptor_timing.Timing.custom_string(tag = "duration",
				object_type = "all", task = "all", key = "all",
				time = total_time) + "</buildlog>\n")
	
	
	def close(self):
		"""
			Close the logfile
		"""
		try:
			self.out.close
			return True
		except:
			self.out = None
		return False
