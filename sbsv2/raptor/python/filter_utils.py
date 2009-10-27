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
# Classes, methods and regex available for use in log filters
#


import re


# General log structure
logTag = re.compile('</?(?P<name>\?xml|buildlog|info|warning|error|recipe|whatlog|build|export|archive|member|bitmap|resource|stringtable|bmconvcmdfile)[>| ]')
logHeader = re.compile('<buildlog sbs_version=[\'|\"](?P<version>.+)[\'|\"] xmlns=[\'|\"](?P<xmlns>.+)[\'|\"] xmlns:xsi=[\'|\"](?P<xsdi>.+)[\'|\"] xsi:schemaLocation=[\'|\"](?P<schemaLocation>.+)[\'|\"]>')
clean = re.compile('.*<rm(dir)? (files|dirs)=[\'|\"](?P<removals>.+)[\'|\"] />')
exports = re.compile('<info>(Copied|Unzipped (?P<unpacked>\d+) files from) (?P<source>.+) to (?P<destination>.+)</info>')

# Tool errors and warnings
mwError = re.compile('(.+:\d+:(?! (note|warning):) .+|mw(ld|cc)sym2(.exe)?:(?! (note|warning):) .+ \'.+\' .+)')
mwWarning = re.compile('.+:\d+: warning: .+|mw(ld|cc)sym2(.exe)?: warning: .+')


class AutoFlushedStream(file):
	""" Wrapper for STDOUT/STDERR streams to ensure that a flush is performed
	after write methods.
	Use to avoid buffering when log output in real time is required."""
	
	def __init__(self, aStream):
		self.__stream = aStream
    
	def write(self, aText):
		self.__stream.write(aText)
		self.__stream.flush()

	def writelines(self, aTextList):
		self.__stream.writelines(aTextList)
		self.__stream.flush()


class RecipeFactory(object):
	"Factory class to ease creation of appropriately specialised Recipe objects."
	
	def newRecipe(self, aLine=None, aCustomIgnore=None):
		""" Creates objects of base type Recipe depending on the name
		of the recipe being processed."""
		
		name = ""
		header = None
		if aLine:
			header = Recipe.header.match(aLine)
		if header:
			name = header.group("name")	
		
		if name.startswith("win32"):
			return Win32Recipe(aLine, aCustomIgnore)
		else:
			return Recipe(aLine, aCustomIgnore)
	

class Recipe(object):
	""" Recipe base class.
	Provides a means to get hold of recipe content in a generic way.
	Includes a basic understanding of errors and warnings - sub-classes can
	override output, error and warning methods to specialise."""
	
	# Flags to normalise client access, mapping directly to regex groups
	name		= "name"
	target		= "target"
	host		= "host"
	layer		= "layer"
	component	= "component"
	bldinf		= "bldinf"
	mmp			= "mmp"
	config		= "config"
	platform	= "platform"
	phase		= "phase"
	source		= "source"
	start		= "start"
	elapsed		= "elapsed"
	exit		= "exit"
	code		= "code"
	attempts	= "attempts"
	
	# Basic errors/warnings
	error = re.compile('Error: ')
	warning = re.compile('Warning: ')
	
	# Recipe metadata
	header  = re.compile('<recipe\s+name=[\'|\"](?P<name>.+)[\'|\"]\s+target=[\'|\"](?P<target>.+)[\'|\"]\s+host=[\'|\"](?P<host>.+)[\'|\"]\s+layer=[\'|\"](?P<layer>.*)[\'|\"]\s+component=[\'|\"](?P<component>.*)[\'|\"]\s+bldinf=[\'|\"](?P<bldinf>.+)[\'|\"]\s+mmp=[\'|\"](?P<mmp>.*)[\'|\"]\s+config=[\'|\"](?P<config>.+)[\'|\"]\s+platform=[\'|\"](?P<platform>.*)[\'|\"]\s+phase=[\'|\"](?P<phase>.+)[\'|\"]\s+source=[\'|\"](?P<source>.*)[\'|\"]\s*>')
	call    = re.compile('^\+ (?P<call>.+)$')
	status  = re.compile('\<status\s+exit=[\'|\"](?P<exit>(ok|failed|retry))[\'|\"](\s+code=[\'|\"](?P<code>\d+)[\'|\"])?\s+attempt=[\'|\"](?P<attempts>\d+)[\'|\"]\s*\/>')
	ignore  = re.compile('<!\[CDATA\[')
	time    = re.compile(']]><time\s+start=[\'|\"](?P<start>\d+\.\d+)[\'|\"]\s+elapsed=[\'|\"](?P<elapsed>\d+.\d+)[\'|\"]\s*/>$')
	footer  = re.compile('</recipe>$')
	
	
	def __init__(self, aLine=None, aCustomIgnore=None):
		"""
		@param aLine			Optional first line of a recipe (typically the recipe header)
		@param aCustomIgnore	Optional compiled regular expression object listing additional
								lines to be ignored in this recipe's output.
		"""				
		self.__customIgnore = aCustomIgnore	
		
		self.__detail = {
						Recipe.name		:"",
						Recipe.target	:"",
						Recipe.host		:"",
						Recipe.layer	:"",
						Recipe.component:"",
						Recipe.bldinf	:"",
						Recipe.mmp		:"",
						Recipe.config	:"",
						Recipe.platform	:"",
						Recipe.phase	:"",
						Recipe.source	:"",
						Recipe.start	:"",
						Recipe.elapsed	:0.0,
						Recipe.exit		:"",
						Recipe.code		:0,
						Recipe.attempts	:0
						}
		
		self.__calls = []
		self.__lines = []
		self.__complete = False
		
		if aLine:
			self.addLine(aLine)
	
	def isComplete(self):
		"""Signifies that the recipe footer has been reached, the
		recipe is complete and so is in a fit state to be queried."""
		return self.__complete

	def __storeDetail(self, aMatchObject):
		for key in aMatchObject.groupdict().keys():
			value = aMatchObject.group(key)
			if value:
				if (key in [Recipe.code,Recipe.attempts]):
					value = int(value)
				elif key == Recipe.elapsed:
					value = float(value)
				self.__detail[key] = value
	
	def addLine(self, aLine):
		"""Add a log line to an existing recipe object, processing anything
		that can be examined at this point in time directly."""
		if Recipe.ignore.match(aLine) or (self.__customIgnore and self.__customIgnore.match(aLine)):
			return

		header = Recipe.header.match(aLine)
		if header:
			self.__storeDetail(header)
			return
		
		call = Recipe.call.match(aLine)
		if call:
			self.__calls.append(call.group("call"))
			return
		
		time = Recipe.time.match(aLine)
		if time:
			self.__storeDetail(time)
			return
		
		status = Recipe.status.match(aLine)
		if status:
			self.__storeDetail(status)
			return
		
		if Recipe.footer.match(aLine):
			self.__complete = True
			return

		self.__lines.append(aLine)
	
	def getDetail(self, aItem):
		"""Retrieve attribute detail from recipe tags.
		Class data flags provide known items e.g. getDetail(Recipe.source)"""
		if self.__detail.has_key(aItem):
			return self.__detail[aItem]
		
	def getCalls(self):
		"Return a list of all '+' prefixed tool calls from this recipe."
		return self.__calls
	
	def isError(self, aLine):
		"""Convenience matcher for basic errors.
		Override in sub-classes to specialise."""
		return True if Recipe.error.match(aLine) else False
	
	def isWarning(self, aLine):
		"""Convenience matcher for basic warnings.
		Override in sub-classes to specialise."""
		return True if Recipe.warning.match(aLine) else False
	
	def getOutput(self):
		""""Return a list of all output that isn't an error or a warning.
		Override in sub-classes to specialise."""
		output = []
		for line in self.__lines:
			if not self.isError(line) and not self.isWarning(line):
				output.append(line)
		return output
	
	def getErrors(self):
		""""Return a list of all output identified as an error.
		Override in sub-classes to specialise."""
		errors = []
		for line in self.__lines:
			if self.isError(line):
				errors.append(line)
		return errors
	
	def getWarnings(self):
		""""Return a list of all output identified as a warning.
		Override in sub-classes to specialise."""
		warnings = []
		for line in self.__lines:
			if self.isWarning(line):
				warnings.append(line)
		return warnings
	
	def isSuccess(self):
		"Convenience method to get overall recipe status."
		return True if self.getDetail(Recipe.exit) == "ok" else False
	
	
class Win32Recipe(Recipe):
	"Win32 tailored recipe class."
	def isError(self, aLine):
		return True if mwError.match(aLine) else False
	
	def isWarning(self, aLine):
		return True if mwWarning.match(aLine) else False


	
