#
# Copyright (c) 2008-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Filter class for copying files in serial in python. This
# is important in cluster builds where file copying is 
# very inefficient.  
# The one-to-many <finalcopy> tag is searched for and copy
# instructions are built up in a hash table.
# <finalcopy source='sourcefilename'>destfilename1 destfilename2 . . . .destfilenameN</copy>
# destinations must be full filenames not directories.
#
# This filter monitors build progress
# via the <progress> tags and flushes copies as build 
# stages end (e.g. after resource so resources are ready for the next stage)
# 

import os
import sys
import tempfile
import filter_interface
import shutil
import generic_path
import stat
from raptor_utilities import copyfile

class FilterCopyFile(filter_interface.Filter):
	
	def open(self, params):
		"initialise"
		
		self.ok = True

		self.files = {}
		
		return self.ok
	
	
	def write(self, text):
		"process some log text"
		
		for line in text.splitlines():
			if line.startswith("<finalcopy"):
				source_start = line.find("source='")
				source = line[source_start+8:line.find("'", source_start+8)]
				destinations = line[line.find(">",source_start)+1:line.find("</finalcopy>")].split(" ")

				if source in self.files:
					self.files[source].update(destinations)
				else:
					self.files[source] = set(destinations)
			elif line.startswith("<progress:end object_type='makefile' task='build'"):
				self.flushcopies() # perform copies at end of each invocation of the make engine
						   # to ensure dependencies are in place for the next one.
				
		return self.ok
	
	
	def summary(self):
		"finish off"
		self.flushcopies()
		return self.ok

	def flushcopies(self):
		for source in self.files.keys():
			for dest in self.files[source]:
				try:
					copyfile(source, dest)
				except IOError, e:
					print "<error>%s</error>" % str(e)
		self.files = {}
		


	def close(self):
		"nop"
		

		return self.ok

# the end				

