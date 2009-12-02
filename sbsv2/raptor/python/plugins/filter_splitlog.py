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
# Filter class for filtering XML logs and generate reports
# Will ultimately do everything that scanlog does
#

import errno
import os
import sys
import raptor
import filter_interface

class FilterSplitlog(filter_interface.Filter):

	def open(self, raptor_instance):
		"""Open a log file for the various I/O methods to write to."""

		self.raptor = raptor_instance
		self.logFileName = self.raptor.logFileName
		# insert the time into the log file name
		if self.logFileName:
			self.logFileName.path = self.logFileName.path.replace("%TIME",
					self.raptor.timestring)
	
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
				self.out = open(str(self.logFileName), "w")
			except:
				self.out = None
				sys.stderr.write("%s : error: cannot write log %s\n" %\
					(raptor.name, self.logFileName.GetShellPath()))
				return False
			
			# Add extra streams for splitting logfile
			self.log = str(self.logFileName)
			self.index = self.log.rfind(".")
			# If there is no dot, append to the end
			if self.index < 0:
				self.index = len(self.log)
			self.streams = [self.out]
			
			# Append this list for extra files
			stream_list = ["clean", "whatlog", "recipe"]
				
			for stream in stream_list:
				
				path = self.log[:self.index] + "." + stream + \
						self.log[self.index:]
				try:
					handle = open(path, "w")
					self.streams.append(handle)
				except:
					self.streams.append(self.out)
					sys.stderr.write("%s : error: cannot write log %s\n" %\
							(str(raptor.name), path))
			# self.out = self.streams[0]
			self.clean = self.streams[1]
			self.whatlog = self.streams[2]
			self.recipe = self.streams[3]
			self.block = self.out
			
		else:
			# Change output stream to stdout and override 'write' function
			self.out = sys.stdout
			def stdout_write(text):
				self.out.write(text)
				return True
			self.write = stdout_write
			
		return True


	def write(self, text):
		"""Write text into relevant log file"""
		
		for textLine in text.splitlines():
			textLine = textLine + '\n'
			if textLine.startswith("<?xml ") or textLine.startswith("<buildlog ") \
					or textLine.startswith("</buildlog"):
				for stream in self.streams:
					stream.write(textLine)
			# Split 'CLEAN' output into clean file
			elif textLine.startswith("<clean"):
				if self.block != self.out:
					sys.stderr.write("%s : error: invalid xml. <clean> tag found " \
							+ "before previous block closed %s\n" %\
							(raptor.name, self.logFileName))
				self.block = self.clean
				self.block.write(textLine)
				
			# Split 'WHATLOG' output into whatlog file
			elif textLine.startswith("<whatlog"):
				if self.block != self.out:
					sys.stderr.write("%s : error: invalid xml. <whatlog> tag " + \
							"found before previous block closed\n" %\
							(raptor.name, self.logFileName.GetShellPath()))
				self.block = self.whatlog
				self.block.write(textLine)
				
			# Split 'RECIPE' output into recipe file
			elif textLine.startswith("<recipe"):
				if self.block != self.out:
					sys.stderr.write("%s : error: invalid xml. <recipe> tag " + \
							"found before previous block closed %s\n" %\
							(raptor.name, self.logFileName.GetShellPath()))
				self.block = self.recipe
				self.block.write(textLine)
				
			# End of block found. Reset block to standard logfile
			elif textLine.startswith("</clean>") or textLine.startswith("</whatlog>") \
				or textLine.startswith("</recipe>"):
				self.block.write(textLine)
				self.block = self.out
			
		# Everything else goes to logfile associated with current block
			else:
				self.block.write(textLine)
		return True


	def summary(self):
		"""Write Summary"""
		if self.logFileName and not self.raptor.quiet:
			sys.stdout.write("sbs: build log in %s\n" % self.logFileName)
		return True


	def close(self):
		"""Close the log file(s)"""

		try:
			self.out.close
			for stream in self.streams:
				stream.close()
			return True
		except:
			self.out = None
		return False
