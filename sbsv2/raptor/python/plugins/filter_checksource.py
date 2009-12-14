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
#

import raptor_utilities
import os
import re
import sys
import filter_interface
import xml.parsers.expat
import raptor
import generic_path
import tempfile

# This filter has not been tested on linux
if not raptor_utilities.getOSPlatform().startswith("linux"):
	
	# Compares the two paths, and reports the differences highlighted by a "^" character
	# Output Generated will be like this:
	# Reference in metadata -> C:/foo/bar/cat.cpp
	# 			               -------^-------^-- 
	# Reference in metadata -> C:/foo/Bar/cat.Cpp
	def reportcsdifference(path1, path2):
		
		same = "-"
		different = "^"
		space = ' '
		metadataString = 'Reference in metadata -> '
		ondiskString   = 'Actual case on disk   -> '
		
		sys.stderr.write(metadataString + path2 +"\n")
		separator = ""
		for i, e in enumerate(path1):
			try:
				if e != path2[i]:
					separator += different
				else:
					separator += same
			except IndexError:
				separator += '*'

		separator += different * (len(path1)-len(path2))
		
		sys.stderr.write(space*len(metadataString) + separator +"\n") # Print the separator in alignment with the metadataString
		sys.stderr.write(ondiskString + path1 + "\n")

	class FilterCheckSource(filter_interface.Filter):

		def open(self, raptor_instance):
			self.raptor = raptor_instance
			self.ok = True
			self.errors = 0
			self.checked = []
			self.check = raptor_instance.doCheck
			self.casechecker = CheckCase()
			
			# Expat Parser initialisation
			self.p = xml.parsers.expat.ParserCreate()
			self.p.StartElementHandler = self.startelement # Handles opening XML tags
			self.p.EndElementHandler = self.endelement # Handles closing XML tags
			self.p.CharacterDataHandler = self.chardata # Handles data between opening/closing tags
			
			# Regex initialisation
			self.rvctdependfinder = re.compile("--depend\s+(.*?d)(?:\s+|$)", re.IGNORECASE|re.DOTALL)
			self.cwdependfinder = re.compile("#'\s+(.*?\.dep)", re.IGNORECASE|re.DOTALL)
			
			# Data to be passed to case checkers
			self.currentmmp = ""
			self.currentbldinf = ""
			self.currentconfig = ""
			
			self.filestocheck = []
			
			# Need this flag for the chardata method that does not have the name of the
			# current XML element passed to it as a parameter.
			self.infiletag = False
			
			# Create a temporary file to record all dependency files. We can only parse those after 
			# make has finished running all the compile commands and by definition these
			# files should therefore exist.
			try:
				self.tmp = tempfile.TemporaryFile()
			except:
				sys.stderr.write("sbs: could not create temporary file for FilterClean\n")
				self.ok = False
			
			return self.ok

		def write(self, text):
			# Slightly nasty that we have to "ignore" exceptions, but the xml parser 
			# generates this when it encounters non-xml lines (like make: nothing to be done for 'export')
			try:
				self.p.Parse(text.rstrip())	
			except xml.parsers.expat.ExpatError:
				pass

			return self.ok

		def saveitem(self, path):
			"put path into a temporary file."
			try:
				self.tmp.write(path + "\n")
			except:
				sys.stderr.write("sbs: could not write temporary file in FilterCheckSource\n")
				self.ok = False

		def startelement(self, name, attrs):
			# Check the source code cpp files - obtained from the "source" 
			# attribute of compile and other tags 
			if 'source' in attrs.keys():
				if attrs['source'] != "":
					self.filestocheck.append(attrs['source'])
			
			# Record the current metadata files and config
			if name == "clean":
				self.currentmmp = attrs["mmp"]
				self.currentbldinf = attrs["bldinf"]
				self.currentconfig = attrs["config"]
			
			# Indicates we are in a <file> element
			if name == "file":
				# Need to use a flag to indicate that we are processing a file tag
				self.infiletag = True
		
		def chardata(self, data):
			# Strip quotes from data
			unquoteddata = data.strip("\"\'")
			
			# Use a flag to determine that we are processing a file tag since this method
			# doesn't receive the "name" argument that startelement/endelement
			if self.infiletag:
				self.filestocheck.append(unquoteddata)
				
				# Also write dependency file names to temp file to parse the 
				# contents of these at the end
				if unquoteddata.endswith(".d") or unquoteddata.endswith(".dep"):
					self.saveitem(unquoteddata)
			
			# RVCT depends files
			# Outside of file tags, chardata will be called on CDATA which contains
			# compiler calls, hence we parse these for the "--depend" option to extract
			# the .d file.
			if "--depend" in data:
				result =  self.rvctdependfinder.findall(data)
				for res in result:
					self.saveitem(res)
			
			# CW toolchain depends files
			# As for RVCT, chardata will be called on CDATA which contains compiler calls, 
			# hence we parse these for file names ending in .dep after the sequence #, ' and 
			# a space. The win32.flm munges the contents of these files around so we are really
			# interested in the .o.d files - these have the same path as the .dep files but 
			# with the extension changed to .o.d from .dep.
			if ".dep" in data:
				result = self.cwdependfinder.findall(data)
				for res in result:
					self.saveitem(res.replace(".dep", ".o.d"))
			
		def endelement(self, name):
			# Blank out the mmp, bldinf and config for next clean tag (in case it has any blanks)
			if name == "clean":
				self.currentmmp = ""
				self.currentbldinf = ""
				self.currentconfig = ""
			
			if name == "file":
				self.infiletag = False
			
			if len(self.filestocheck) > 0:
				# Check the found file(s)
				for filename in self.filestocheck:
					self.checksource(filename)
				
				# Reset list so as not to re-check already checked files
				self.filestocheck = []
				
		def close(self):			
			return self.ok

		def summary(self):
			
			depparser = DependenciesParser()
			dependenciesfileset = set() # Stores the files listed inside depdendency files
			deps = [] # Stores dependency (.d and .dep) files
			
			try:
				self.tmp.flush()	# write what is left in the buffer
				self.tmp.seek(0)	# rewind to the beginning
				
				for line in self.tmp.readlines():
					path = line.strip()
					
					# Only try to parse the file if it exists as a file, and if we haven't done so 
					# already (store the list of parsed files in the set "dependenciesfileset"
					if os.path.isfile(path) and not path in dependenciesfileset:
						dependenciesfileset.add(path)
						
						# Here we parse each dependency file and form a list of the prerequisites contained therein
						dependencyfilelines = depparser.readdepfilelines(path) # Read the lines
						dependencyfilestr = depparser.removelinecontinuation(dependencyfilelines) # Join them up
						dependencyfiles = depparser.getdependencies(dependencyfilestr) # Get prerequisites
						deps.extend(dependencyfiles) # Add to list
					else:
						sys.stdout.write("\t"  + path + " does not exist\n")
						
				self.tmp.close()	# This also deletes the temporary file
				
				# Make a set of the prerequisites listed in the dependency files
				# so we only check each one once
				depset = set(deps)
				deplistnodups = list(depset)
				
				# Do the check for each file 	
				for dep in deplistnodups:
					dep = os.path.abspath(dep).replace('\\', '/')
					self.checksource(dep)
					
			except Exception, e:
				sys.stderr.write("sbs: FilterCheckSource failed: %s\n" % str(e))
				
			if self.errors == 0:
				sys.stdout.write("No checksource errors found\n")
			else:
				sys.stdout.write("\n %d checksource errors found in the build\n" % self.errors)
			
		
		def checksource(self, path):
			normedpath = path.replace("\"", "") # Remove quoting
			
			if normedpath not in self.checked:
				self.checked.append(normedpath)
				try:
					realpath = self.casechecker.checkcase(normedpath)
				except IOError, e:
					# file does not exist so just return
					return
										
				if not realpath == normedpath and realpath != "":
					self.ok = False
					self.errors += 1
					sys.stderr.write("\nChecksource Failure:\n")
					reportcsdifference(realpath, normedpath)

	class CheckCase(object):
		"""Used to check the case of a given path matches the file system.  
		Caches previous lookups to reduce disk IO and improve performance"""
		
		def __init__(self):
			self.__dirsCache = {} # a hash containing the directory structure, in the same case as the file system
		
		def checkcase(self, path):
			"""Checks the path matches the file system"""
			
			path = os.path.abspath(path)
			path = path.replace('\\', '/')
			
			if not os.path.exists(path):
				raise IOError, path + " does not exist"
				
			parts = path.split('/')
			
			dirBeingChecked = parts.pop(0) + "/"
			
			cacheItem = self.__dirsCache
			
			for part in parts:
				if not self.checkkeyignorecase(cacheItem, part):

					dirItems = os.listdir(dirBeingChecked)
					
					found = False
					
					for dirItem in dirItems:
						if os.path.isdir(os.path.join(dirBeingChecked, dirItem)):
							if not cacheItem.has_key(dirItem):
								cacheItem[dirItem] = {}
							
							if not found:
								# Check if there is a dir match
								if re.search("^" + part + "$", dirItem, re.IGNORECASE):
									found = True
									
									cacheItem = cacheItem[dirItem]
									
									dirBeingChecked = os.path.join(dirBeingChecked, dirItem).replace('\\', '/')
						else:
							cacheItem[dirItem] = 1
					
							if not found:
								# Check if there is a dir match
								if re.search("^" + part + "$", dirItem, re.IGNORECASE):
									found = True
									
									return os.path.join(dirBeingChecked, dirItem).replace('\\', '/')                         
				
				else:
					if os.path.isdir(os.path.join(dirBeingChecked, part)):
						cacheItem = cacheItem[part]
				
					dirBeingChecked = os.path.join(dirBeingChecked, part).replace('\\', '/')
	
			return dirBeingChecked
	
		def checkkeyignorecase(self, dictionary, keyToFind):
			for key in dictionary.keys():
				if re.search("^" + keyToFind + "$", key, re.IGNORECASE):
					
					if not keyToFind == key:
						return False
					
					return True
			
			return False

	class DependenciesParser(object):
		
		def __init__(self):
			pass # Nop - nothing to do for init
		
		def readdepfilelines(self, dotdfile):
			""" Read the lines from a Make dependency file and return them as a list """
			lines = []
			try:
				fh = open(dotdfile, "r")
			except IOError, e:
				print "Error: Failed to open file \"%s\": %s" % (dotdfile, e.strerror)
			except Exception, e:
				print "Error: Unknown error: %s" % str(e)
			else:
				lines = fh.readlines()
				fh.close()
				
			return lines
		
		def removelinecontinuation(self, lineslist):
			""" Remove line continuation chararacters '\\' from the end of any lines in  
			the list that have them and return a string with lines joined together """
			str = " ".join(lineslist).replace('\\\n','')
			return str
		
		def getdependencies(self, dotdfilestring):
			""" Splits the multi-lined string dotdfilestring and performs a regexp
			match on files to the right of a : on each line """
			
			# Strip whitespace at the start of the string	
			lines = dotdfilestring.lstrip().split("\n")
			
			dependencyset = set() # Create a set to skip duplicates
			for line in lines:
				# Split on whitespace that is *not* preceeded by a \ - i.e. 
				# don't split on escaped spaces.
				lineparts = re.split("(?<!\\\\)\s+", line)
				
				# Drop element 0 as this will be the target of each rule
				lineparts = lineparts[1:]
				
				for linepart in lineparts:
					# Some of the line parts are empty, so skip those
					if linepart != "":
						dependencyset.add(linepart)
			
			# Create list to return from the initial set
			files = list(dependencyset)
			return files  
