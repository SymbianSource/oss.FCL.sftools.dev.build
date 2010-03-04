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
# Compress the full Raptor log file using the BZip2 algorithm, maximum compression.
# 
#

import os
import sys
import raptor
import filter_interface
import bz2

class StringListCompressor(object):
	def __init__(self, complevel=5, filename="file.log.bz2"):
		self.compressor = bz2.BZ2Compressor(complevel)
		self.stringlist = []
		self.outputopenedok = False
		self.filename = filename
		try:
			self.fh = open(self.filename, "wb")
			self.outputopenedok = True
		except:
			self.outputopenedok = False
	
	def write(self, data):
		if self.outputopenedok:
			compresseddata = self.compressor.compress(data)
			self.fh.write(compresseddata)
	
	def __del__(self):
		if self.outputopenedok:
			compresseddata = self.compressor.flush()
			self.fh.write(compresseddata)
			self.fh.close()

class Bz2log(filter_interface.Filter):
	def __init__(self):
		self.__inRecipe = False
		self.compressor = None

	def open(self, raptor_instance):
		"""Open a log file for the various I/O methods to write to."""
		
		if raptor_instance.logFileName == None:
			self.out = sys.stdout # Default to stdout if no log file is given
		else:
			logname = str(raptor_instance.logFileName.path.replace("%TIME", raptor_instance.timestring))
			
			# Ensure that filename has the right extension; append ".bz2" if required
			if not logname.lower().endswith(".bz2"):
				logname += ".bz2"

			try:
				dirname = str(raptor_instance.logFileName.Dir())
				if dirname and not os.path.isdir(dirname):
					os.makedirs(dirname)
			except:
				self.formatError("cannot create directory %s", dirname)
				return False
			
			# Use highest compression level 9 which corresponds to a 900KB dictionary
			self.compressor = StringListCompressor(9, logname)
			if not self.compressor.outputopenedok:
				self.out = None
				self.formatError("failed to initialise compression routines." )
				return False
		return True
		
	def write(self, data):
		"""Write data compressed log"""
		if self.compressor:
			self.compressor.write(data)
		return True
	
	def close(self):
		"""Close the log file"""
		return True
