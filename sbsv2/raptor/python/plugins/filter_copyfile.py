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
# Filter class for doing CLEAN, CLEANEXPORT and REALLYCLEAN efficiently.
#

import os
import sys
import tempfile
import filter_interface
import shutil
import generic_path
import stat

class FilterCopyFile(filter_interface.Filter):
	
	def open(self, params):
		"initialise"
		
		self.ok = True

		self.files = {}
		
		return self.ok
	
	
	def write(self, text):
		"process some log text"
		
		for line in text.splitlines():
			if line.startswith("<copy"):
				source_start=line.find("source='")
				source=line[source_start+8:line.find("'", source_start+8)]
				destinations = line[line.find(">",source_start)+1:line.find("</copy>")].split(" ")

				if source in self.files:
					self.files[source].update(destinations)
				else:
					self.files[source] = set(destinations)
				
				
		return self.ok
	
	
	def summary(self):
		"finish off"
		for source in self.files.keys():
			#print "<debug>self.files %s</debug>" % self.files[source]
			for dest in self.files[source]:
				self.copyfile(source, dest)
		
		return self.ok


	def close(self):
		"nop"
		

		return self.ok

	def copyfile(self, _source, _destination):
		"""Copy the source file to the destination file (create a directory
		   to copy into if it does not exist). Don't copy if the destination
		   file exists and has an equal or newer modification time."""
		source = generic_path.Path(str(_source).replace('%20',' '))
		destination = generic_path.Path(str(_destination).replace('%20',' '))
		dest_str = str(destination)
		source_str = str(source)

		try:


			destDir = destination.Dir()
			if not destDir.isDir():
				os.makedirs(str(destDir))
				shutil.copyfile(source_str, dest_str)
				return 

			# Destination file exists so we have to think about updating it
			sourceMTime = 0
			destMTime = 0
			sourceStat = 0
			try:
				sourceStat = os.stat(source_str)
				sourceMTime = sourceStat[stat.ST_MTIME]
				destMTime = os.stat(dest_str)[stat.ST_MTIME]
			except OSError, e:
				if sourceMTime == 0:
					message = "Source of copyfile does not exist:  " + str(source)
					print message

			if destMTime == 0 or destMTime < sourceMTime:
				if os.path.exists(dest_str):
					os.chmod(dest_str,stat.S_IREAD | stat.S_IWRITE)
				shutil.copyfile(source_str, dest_str)

				# Ensure that the destination file remains executable if the source was also:
				os.chmod(dest_str,sourceStat[stat.ST_MODE] | stat.S_IREAD | stat.S_IWRITE | stat.S_IWGRP ) 


		except Exception,e:
			message = "Could not export " + source_str + " to " + dest_str + " : " + str(e)

		return 
	
# the end				

