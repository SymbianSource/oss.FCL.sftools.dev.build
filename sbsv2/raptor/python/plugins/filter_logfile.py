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

class FilterLogfile(filter_interface.Filter):

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
					sys.stderr.write("%s : error: cannot create directory %s\n" % \
						(str(raptor.name), dirname))
					return False
			try:
				self.out = open(str(self.logFileName), "w")
			except:
				self.out = None
				sys.stderr.write("%s : error: cannot write log %s\n" %\
					(str(raptor.name), self.logFileName.GetShellPath()))
				return False
		else:
			self.out = sys.stdout

		return True

	def write(self, text):
		"""Write text into the log file"""

		self.out.write(text)
		return True

	def summary(self):
		"""Write Summary"""
		if self.logFileName and not self.raptor.quiet:
			sys.stdout.write("sbs: build log in %s\n" % str(self.logFileName))
		return False

	def close(self):
		"""Close the log file"""

		try:
			self.out.close()
			return True
		except:
			self.out = None
		return False
