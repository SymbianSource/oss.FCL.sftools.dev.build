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

class FilterClean(filter_interface.Filter):
	
	def open(self, params):
		"initialise"
		
		targets = [x.lower() for x in params.targets]
		
		self.removeExports = ("cleanexport" in targets or "reallyclean" in targets)
		self.removeTargets = ("clean" in targets or "reallyclean" in targets)
		
		self.ok = True
		
		# create a temporary file to record all the exports and directories
		# in. We can only remove those after "make" has finished running all
		# the CLEAN targets.
		try:
			self.tmp = tempfile.TemporaryFile()
		except:
			sys.stderr.write("sbs: could not create temporary file for FilterClean\n")
			self.ok = False
		
		return self.ok
	
	
	def write(self, text):
		"process some log text"
		
		for line in text.splitlines():
		
			if self.removeTargets:
				if line.startswith("<file>"):
					self.doFile(line, "file")
				elif line.startswith("<build>"):
					self.doFile(line, "build")
				elif line.startswith("<resource>"):
					self.doFile(line, "resource")
				elif line.startswith("<bitmap>"):
					self.doFile(line, "bitmap")
				elif line.startswith("<stringtable>"):
					self.doFile(line, "stringtable")
						
			if self.removeExports:
				if line.startswith("<export "):
					self.doExport(line)
				elif line.startswith("<member>"):
					self.doFile(line, "member")
				elif line.startswith("<zipmarker>"):
					self.doFile(line, "zipmarker")
				
		return self.ok
	
	
	def summary(self):
		"finish off"
		
		# remove files, remembering directories
		dirs = set()
		
		try:
			self.tmp.flush()	# write what is left in the buffer
			self.tmp.seek(0)	# rewind to the beginning
			
			for line in self.tmp.readlines():
				path = line.strip()
				
				if os.path.isfile(path):
					self.removeFile(path)
				
				directory = os.path.dirname(path)
				if os.path.isdir(directory):
					dirs.add(directory)
					
			self.tmp.close()	# this also deletes the temporary file
		except Exception,e:
			sys.stderr.write("sbs: problem reading temporary file for FilterClean: %s\n" % str(e))
			self.ok = False
		
		# finally remove (empty) directories
		for dir in dirs:
			try:
				os.removedirs(dir)	# may fail if the directory has files in
			except:
				pass				# silently ignore all errors
				
		return self.ok


	def close(self):
		"nop"
		
		return self.ok
	
	
	def removeFile(self, path):
		try:
			os.unlink(path)
		except Exception, e:
			sys.stderr.write("sbs: could not remove " + path + "\n")
			sys.stderr.write(str(e) + "\n")
		
				
	def saveItem(self, path):
		"put path into a temporary file."
		try:
			self.tmp.write(path + "\n")
		except:
			sys.stderr.write("sbs: could not write temporary file in FilterClean\n")
			self.ok = False
	
			
	def doFile(self, line, tagname):
		"deal with <tagname>X</tagname>"
		
		first = len(tagname) + 2	# line is "<tagname>filename</tagname>
		last = -(first + 1)
		filename = line[first:last]                
		filename = filename.strip("\"\'")    # some names are quoted
		self.saveItem(filename)
				

	def doExport(self, line):
		"deal with <export destination='X' source='Y'/>"
		filename = line[21:line.find("'", 21)]
		self.saveItem(filename)


# the end				

