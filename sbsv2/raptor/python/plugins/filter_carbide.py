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
# Format Raptor verbose log output for the Carbide IDE
#


import os
import re
import sys
import raptor
import filter_interface
import filter_utils


class FilterCarbide(filter_interface.Filter):
	"""Carbide IDE filter
	Strips most verbose output leaving tools calls, tool output and formatted errors/warnings."""
	
	# ignore all general, benign, make output
	ignore = re.compile('(make(\.exe)?: Nothing to be done for \`.+\'|make(\.exe)?: \[.+\] Error \d+ \(ignored\)|.*make(.exe)?\[\d\]: (Entering|Leaving) directory \`.+\')')
	
	stdout = filter_utils.AutoFlushedStream(sys.stdout)
	stderr = filter_utils.AutoFlushedStream(sys.stderr)
	
	recipeFactory = filter_utils.RecipeFactory()
	
	def __init__(self):
		self.__errors = 0
		self.__warnings = 0
		self.__recipe = None

	def open(self, aRaptorInstance):
		return True
		
	def write(self, aLine):
		"""Process output on the fly and format appropriately for the Carbide IDE.
		Most verbose output is discarded leaving tools calls, tool output and formatted errors
		and warnings.
		Identified errors go to stderr so that they will be highlighted in the IDE console."""
		
		if FilterCarbide.ignore.match(aLine):
			return
		
		logHeader = filter_utils.logHeader.match(aLine)
		if logHeader:
			FilterCarbide.stdout.write("sbs version: " + logHeader.group("version")+"\n\n")
			return
		
		clean = filter_utils.clean.match(aLine)
		if clean:
			for file in clean.group("removals").split():
				FilterCarbide.stdout.write("clean: " + file + "\n")
			return
		
		exports = filter_utils.exports.match(aLine)
		if exports:
			FilterCarbide.stdout.write("export: " + exports.group("source") + " to " + exports.group("destination") + "\n")
			return
		
		
		if self.__recipe:
			self.__recipe.addLine(aLine)
			
			if self.__recipe.isComplete():
				for call in self.__recipe.getCalls():
					FilterCarbide.stdout.write(call + "\n")				
		else:		
			logTag = filter_utils.logTag.match(aLine)
			if logTag:
				tagName = logTag.group("name")			
				if tagName == "recipe":
					if self.__recipe:
						self.__recipe.addLine(aLine)
					else:
						self.__recipe = FilterCarbide.recipeFactory.newRecipe(aLine)						
				elif tagName == "error":
					self.__errors += 1
					FilterCarbide.stderr.write("Error: " + filter_utils.logTag.sub("", aLine) + "\n")
				elif tagName == "warning":
					self.__warnings += 1
					FilterCarbide.stdout.write("Warning: " + filter_utils.logTag.sub("", aLine) + "\n")
				# we're not interested in any other tagged output
				return
			else:
				# Not a recipe, and not tagged output that we know about.
				# Output this anyway, just in case it's something important
				FilterCarbide.stdout.write(aLine)
		
		
		if self.__recipe and self.__recipe.isComplete():
			errors = 0
			warnings = 0			

			recipeOutput = self.__recipe.getOutput()
			recipeWarnings = self.__recipe.getWarnings()
			recipeErrors = self.__recipe.getErrors()

			if len(recipeOutput):
				FilterCarbide.stdout.writelines(recipeOutput)		
			if len(recipeWarnings):
				FilterCarbide.stdout.writelines(recipeWarnings)
				warnings += len(recipeWarnings)
			if len(recipeErrors):
				FilterCarbide.stderr.writelines(recipeErrors)
				errors += len(recipeErrors)

			# Per-recipe summary
			self.__errors += errors
			self.__warnings += warnings
			FilterCarbide.stdout.write("Errors: %d, (Total for build: %d)\n" % (errors, self.__errors))
			FilterCarbide.stdout.write("Warnings: %d, (Total for build: %d)\n\n" % (warnings, self.__warnings))
			self.__recipe = None

		return True
	
	def close(self):
		FilterCarbide.stdout.write("Overall Errors: %d\n" % self.__errors)
		FilterCarbide.stdout.write("Overall Warnings: %d\n\n" % self.__warnings)

		return (self.__errors == 0)
