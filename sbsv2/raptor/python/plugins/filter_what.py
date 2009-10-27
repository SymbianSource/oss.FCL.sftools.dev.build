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
# Filter class for doing --what and --check operations
#

import os
import sys
import re
import filter_interface

class FilterWhat(filter_interface.Filter):

	
	def print_file(self, line, start, end):
		"Ensure DOS slashes on Windows"
		
		"""Use chars between enclosing tags ("<>", "''", etc)
				start = opening tag, so the line we need
				actually starts at 'start + 1' """
		if "win" in self.buildparameters.platform:
			filename = line[(start + 1):end].replace("/","\\")
		else:
			filename = line[(start + 1):end]
			
		if self.check:
			if not os.path.isfile(filename):
				print "MISSING:", filename
				self.ok = False
		else:
			self.outfile.write(filename+"\n")


	def open(self, build_parameters):
		"initialise"
		
		self.buildparameters = build_parameters
		self.check = build_parameters.doCheck
		self.what = build_parameters.doWhat

		self.outfile = sys.stdout
		self.outfile_close = False

		if "FILTERWHAT_FILE" in os.environ:
			try:
				self.outfile = open(os.environ['FILTERWHAT_FILE'],"w+")
				self.outfile_close = True
			except Exception,e:
				raise Exception("The 'What Filter' could not open the output file specified in the FILTER_WHAT environment variable: " + os.environ['FILTERWHAT_FILE'])
		
		# repetitions is for tracking repeated lines in the output log
		# when --check and --what are called
		self.repetitions = {}
		
		"Regex for old what output"
		if "win" in self.buildparameters.platform:
			self.regex = re.compile("^[a-zA-Z]:\S+$")
		else:
			self.regex = re.compile("^/\S+$")
		
		"Regex for targets"
		self.target_regex = re.compile("^<(build|stringtable|resource|bitmap)>.*")
			
		"Regex for exports"
		self.export_regex = re.compile("^<export destination.*")
		
		"Regex for zip exports"
		self.zip_export_regex = re.compile("^<member>.*")
		
		self.ok = True		
		return self.ok
	
	def write(self, text):
		"process some log text"
		
		for line in text.splitlines():
			line = line.rstrip()
			
			if not line in self.repetitions:
				self.repetitions[line] = 0
				
			if self.repetitions[line] == 0:
				if self.regex.match(line) and (self.what or self.check):
					"Print the whole line"
					self.print_file(line, (-1), len(line))
					
				if self.target_regex.match(line):
					"Grab the filename between <build> and </build>" 
					start = line.find(">")
					end = line.rfind("<")
					
					self.print_file(line, start, end)
					
				elif self.export_regex.match(line):
					"Grab the filename between the first set of '' chars" 
					start = line.find("'")
					end = line.find("'", (start + 1))
					
					self.print_file(line, start, end)
						
				elif self.zip_export_regex.match(line):
					"Grab the filename between <member> and </member>" 
					start = line.find(">")
					end = line.rfind("<")
					
					self.print_file(line, start, end)
						
			self.repetitions[line] += 1
				
		return self.ok
	
	def close(self):
		if self.outfile_close:
			self.outfile.close()
		return self.ok
						
	
