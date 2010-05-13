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
# Filter class for doing --what and --check operations
#

import os
import sys
import re
import filter_interface

class FilterWhat(filter_interface.Filter):

	def __init__(self):
		super(filter_interface.Filter,self).__init__()
		self.path_prefix_to_strip = None
		self.path_prefix_to_add_on = None
		self.check = False
	
	def print_file(self, line, start, end):
		"Ensure DOS slashes on Windows"
		
		"""Use chars between enclosing tags ("<>", "''", etc)
				start = opening tag, so the line we need
				actually starts at 'start + 1' """

		abs_filename = line[(start + 1):end]
		filename = abs_filename

		# Adjust drive letters for case insensitivity on windows

		path_prefix_to_strip = self.path_prefix_to_strip
		if "win" in self.buildparameters.platform:
			filename = filename[0].upper()+filename[1:]
			filename = filename.replace("/","\\")

		if path_prefix_to_strip:
			if "win" in self.buildparameters.platform:
				path_prefix_to_strip = path_prefix_to_strip[0].upper()+path_prefix_to_strip[1:].replace("/","\\")
			if filename.startswith(path_prefix_to_strip):
				filename = filename[len(path_prefix_to_strip):]
			if self.path_prefix_to_add_on != None:
				filename = self.path_prefix_to_add_on + filename
			
		if self.check:
			if not os.path.isfile(abs_filename):
				print "MISSING:", filename
				self.ok = False
		else:
			self.outfile.write(filename+"\n")

		self.prints += 1

	def start_bldinf(self, bldinf):
		pass

	def end_bldinf(self):
		pass
		

	def open(self, build_parameters):
		"initialise"
		

		self.buildparameters = build_parameters
		if build_parameters.doCheck:
			self.check = True
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
		
		"Regex for targets"
		self.target_regex = re.compile("^<(build|stringtable|resource|bitmap)>.*")
			
		"Regex for exports"
		self.export_regex = re.compile("^<export destination.*")
		
		"Regex for zip exports"
		self.zip_export_regex = re.compile("^<member>.*")

		"Regex for determining bld.inf name"
		self.whatlog_regex = re.compile("^<whatlog *bldinf='(?P<bldinf>[^']*)'.*")
		self.current_bldinf = ''
		
		self.prints = 0
		self.ok = True		
		return self.ok
	
	def write(self, text):
		"process some log text"
		
		for line in text.splitlines():
			line = line.rstrip()
			
			# we are normally the ONLY filter running so we have to pass on
			# any errors and warnings that emerge
			#
			if line.startswith("<error"):
				sys.stderr.write(self.formatError(line))
				self.ok = False
				continue
			if line.startswith("<warning"):
				sys.stderr.write(self.formatWarning(line))
				continue
				
			if not line in self.repetitions:
				self.repetitions[line] = 0
				
			if self.repetitions[line] == 0:
					
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

			"work out what the 'current' bldinf file is"
			m = self.whatlog_regex.match(line)
			if m:
				bi = m.groupdict()['bldinf']
				if self.current_bldinf != bi:
					if self.current_bldinf != '':
						self.end_bldinf()
					self.current_bldinf = bi
					if bi != '':
						self.start_bldinf(bi)
							
					
						
			self.repetitions[line] += 1
				
		return self.ok
	
	def summary(self):
		if self.prints == 0:
			if self.what:
				message = "no WHAT information found"
			else:
				message = "no CHECK information found"
				
			sys.stderr.write(self.formatError(message))
			self.ok = False
		return self.ok
		
	def close(self):
		if self.outfile_close:
			self.outfile.close()
		return self.ok
						
	
