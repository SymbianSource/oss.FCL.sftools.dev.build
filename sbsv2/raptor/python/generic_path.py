#
# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# generic_path module
#

import os
import sys
import re
import types

# are we on windows, and if so what is the current drive letter
isWin = sys.platform.lower().startswith("win")
if isWin:
	drive = re.match('^([A-Za-z]:)',os.getcwd()).group(0)

# regex for "bare" drive letters	
driveRE = re.compile('^[A-Za-z]:$')

# Base class

class Path:
	"""This class represents a file path.
	
	A generic path object supports operations without needing to know
	about Windows and Linux differences. The standard str() function can
	obtain a string version of the path in Local format for use by
	platform-specific functions (file opening for example).
	
	We use forward slashes as path separators (even on Windows).
	
	For example,
	
		path1 = generic_path.Path("/foo")
		path2 = generic_path.Path("bar", "bing.bang")
		
		print str(path1.Append(path2))
		
	Prints /foo/bar/bing.bang		on Linux
	Prints c:/foo/bar/bing.bang		on Windows (if c is the current drive)
	""" 
		
	def __init__(self, *arguments):
		"""construct a path from a list of path elements"""
		
		if len(arguments) == 0:
			self.path = ""
			return
		
		list = []
		for i,arg in enumerate(arguments):
			if isWin:
				if i == 0:
					# If the first element starts with \ or / then we will
					# add the current drive letter to make a fully absolute path
					if arg.startswith("\\\\"):
						list.append(arg) # A UNC path - don't mess with it
					elif arg.startswith("\\") or arg.startswith("/"):
						list.append(drive + arg)
					# If the first element is a bare drive then dress it with a \
					# temporarily otherwise "join" will not work properly.
					elif driveRE.match(arg):
						list.append(arg + "\\")
					# nothing special about the first element
					else:
						list.append(arg)
				else:
					if arg.startswith("\\\\"):
						raise ValueError("non-initial path components must not start with \\\\ : %s" % arg)
					else:
						list.append(arg)
				if ";" in arg:
					raise ValueError("An individual windows Path may not contain ';' : %s" % arg)
			else:
				list.append(arg)
	
		self.path = os.path.join(*list)
		
		# normalise to avoid nastiness with dots and multiple separators
		# but do not normalise "" as it will become "."
		if self.path != "":
			self.path = os.path.normpath(self.path)
		
		# always use forward slashes as separators
		self.path = self.path.replace("\\", "/")
		
		# remove trailing slashes unless we are just /
		if self.path != "/":
			self.path = self.path.rstrip("/")
		
	def __str__(self):
		return self.path
	
	def GetNeutralStr(self):
		"""return the path as a string that could be included in other paths."""
		return self.path.replace(":","").replace("/","")

	def GetLocalString(self):
		"""return a string in the local file-system format.
		
		e.g. C:/tmp on Windows or /C/tmp on Linux"""
		return self.path
	
	def isAbsolute(self):
		"test whether this path is absolute or relative"
		# C: is an absolute directory
		return (os.path.isabs(self.path) or driveRE.match(self.path))
	
	def Absolute(self):
		"""return an object for the absolute version of this path.
		
		Prepends the current working directory to relative paths and
		the current drive (on Windows) to /something type paths."""
		# leave C: alone as abspath will stick the cwd on
		if driveRE.match(self.path):
			return Path(self.path)
		else:
			return Path(os.path.abspath(self.path))
	
	def Append(self, *arguments):
		"return an object with path elements added at the end of this path"
		return Join(*((self,) + arguments))
	
	def Prepend(self, *arguments):
		"return an object with path elements added at the start of this path"
		return Join(*(arguments + (self,)))
	
	def isDir(self):
		"test whether this path points to an existing directory"
		# C: is a directory
		return (os.path.isdir(self.path) or driveRE.match(self.path))
	
	def isFile(self):
		"test whether this path points to an existing file"
		return os.path.isfile(self.path)

	def Exists(self):
		"test whether this path exists in the filesystem"
		if driveRE.match(self.path):
			return os.path.exists(self.path + "/")
		else:
			return os.path.exists(self.path)
		
	def Dir(self):
		"return an object for the directory part of this path"
		if driveRE.match(self.path):
			return Path(self.path)
		else:
			return Path(os.path.dirname(self.path))

	def File(self):
		"return a string for the file part of this path"
		return os.path.basename(self.path)

	def Components(self):
		"""return a list of the components of this path."""
		return self.path.split('/')

	def FindCaseless(self):
		"""Given a path which may not be not correct in terms of case,
		search the filesystem to find the corresponding, correct path.
		paths are assumed to be absolute and normalised (which they
		should be in this class).

		Assumes that the path is more right than wrong, i.e. starts
		with the full path and tests for existence - then takes the
		last component off and check for that.

		This will be inefficient if used in cases where the file 
		has a high probability of not existing.
		"""

		if os.path.exists(self.path):
			return Path(self.path)

		unknown_elements = []
		tail = self.path
		head = None
		while tail != '': 
			if os.path.exists(tail):
				break
			else:
				(tail,head) = os.path.split(tail)
				#print "(head,tail) = (%s,%s)\n" % (head,tail)
				unknown_elements.append(head)

		if tail == None:
			result = ""
		else:
			result = tail

		# Now we know the bits that may be wrong so we can search for them
		unknown_elements.reverse()
		for item in unknown_elements:
			possible = os.path.join(result, item) 
			if os.path.exists(possible):
				result = possible
				continue # not finished yet - only this element is ok

			# Nope, we really do have to search for this component of the path
			possible = None
			if result:
				for file in os.listdir(result):
					if file.lower() == item.lower():
						possible = os.path.join(result,file)
						break # find first matching name (might not be right)
				if possible is None:
					result = "" 
					break # really couldn't find the file
				result = possible

		if result == "":
			return None

		return Path(result)

	def From(self,source):
		"""Returns the relative path from 'source' to here."""
		list1 = source.Absolute().Components()
		list2 = self.Absolute().Components()

		# on windows if the drives are different
		# then the relative path is the absolute one.
		if isWin and list1[0] != list2[0]:
			return self.Absolute()

		final_list = []
		for item in list1:
			if list2 != []:
				for widget in list2:
					if item == widget:
						list2.pop(0)
						break
					else:
						final_list.insert(0, "..")
						final_list.append(widget)
						list2.pop(0)
						break
			else:
				final_list.insert(0, "..")

		final_list.extend(list2)

		return Join(*final_list)

	def GetShellPath(self):
		"""Returns correct slashes according to os type as a string
		"""
		if isWin:
			if  "OSTYPE" in os.environ and os.environ['OSTYPE'] == "cygwin" :
				return self.path

			return self.path.replace("/", "\\")

		return self.path


# Module functions

def Join(*arguments):
	"""Concatenate the given list to make a generic path object. 
	
	This can accept both strings and Path objects, and join
	them "intelligently" to make a complete path."""
	list = []
	for arg in arguments:
		if isinstance(arg, Path):
			list.append(arg.path)
		else:
			list.append(arg)
		
	return Path(*list)

def CurrentDir():
	"return a Path object for the current working directory"
	return Path(os.getcwd())

def NormalisePathList(aList):
	"""Convert a list of strings into a list of Path objects"""
	return map(lambda x: Path(x), aList)

def Where(afile):
	"""Return the location of a file 'afile' in the system path.
	
	On windows, adds .exe onto the filename if it's not there. Returns the first location it found or None if it wasn't found.
	
	>>> Where("python")
	"/usr/bin/python"
	>>> Where("nonexistentfile")
	None
	"""
	location = None
	if sys.platform.startswith("win"):
		if not afile.lower().endswith(".exe"):
			afile += ".exe"
			
	for current_file in [os.path.join(loop_number,afile) for loop_number in
			     os.environ["PATH"].split(os.path.pathsep)]:
		if os.path.isfile(current_file):
			location = current_file
			break
	return location

# end of generic_path module
