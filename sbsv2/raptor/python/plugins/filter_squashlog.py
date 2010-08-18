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
# Squash a raptor log file by removing commands from successful recipes
#

import os
import sys
import raptor
import filter_interface

class FilterSquashlog(filter_interface.Filter):
	
	def __init__(self):
		self.__inRecipe = False

	def open(self, raptor_instance):
		"""Open a log file for the various I/O methods to write to."""
		
		if raptor_instance.logFileName == None:
			self.out = sys.stdout
		else:	
			try:
				dirname = str(raptor_instance.logFileName.Dir())
				if dirname and not os.path.isdir(dirname):
					os.makedirs(dirname)
			except:
				sys.stderr.write(str(raptor.name) + \
						": error: cannot create directory %s\n", dirname)
				return False
			
			try:
				logname = str(raptor_instance.logFileName)
				self.out = open(logname, "w")
			except:
				self.out = None
				sys.stderr.write(str(raptor.name) + \
						": error: cannot write log %s\n", \
						str(raptor_instance.logFileName))
				return False
		
		return True
		
	def write(self, line):
		"""Write text into a squashed log file by removing commands from successful recipes"""
		
		# escape % characters otherwise print will fail
		line = line.replace("%", "%%")
		
		# detect the start of a recipe
		if line.startswith("<recipe "):
			self.__inRecipe = True
			self.__recipeLines = [line]
			self.__squashRecipe = True
			return
		
		# detect the status report from a recipe
		if line.startswith("<status "):
			if not "exit='ok'" in line:
				# only squash ok recipes
				self.__squashRecipe = False
			self.__recipeLines.append(line)
			return
		
		# detect the end of a recipe
		if line.startswith("</recipe>"):
			# print the recipe
			if self.__squashRecipe:
				for text in self.__recipeLines:
					if not text.startswith("+"):
						self.out.write(text)
			else:
				for text in self.__recipeLines:
					self.out.write(text)
			
			self.out.write(line)
			self.__inRecipe = False
			return

		# remember the lines during a recipe
		if self.__inRecipe:
			self.__recipeLines.append(line)	
		else:
			# print all lines outside a recipe 
			self.out.write(line)
			
		return True
	
	def close(self):
		"""Close the log file"""
		
		try:
			self.out.close()
			return True
		except:
			self.out = None
		return False
