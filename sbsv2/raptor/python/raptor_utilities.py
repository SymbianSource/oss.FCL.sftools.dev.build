#
# Copyright (c) 2007-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# raptor_utilities module
# Useful wrapper functions and classes used in Raptor processing
#

import generic_path
import os.path
import re
import sys
import stat
import shutil

dosSlashRegEx = re.compile(r'\\')
unixSlashRegEx = re.compile(r'/')
dosDriveRegEx = re.compile("^([A-Za-z]{1}):")

def getOSPlatform():
	return sys.platform.lower()

def getOSFileSystem():
	if getOSPlatform().startswith("win"):
		return "cygwin"
	else:
		return "unix"

def convertToUnixSlash(aReference):
	return dosSlashRegEx.sub(r'/', aReference)

def convertToDOSSlash(aReference):
	return unixSlashRegEx.sub(r'\\', aReference)

def absPathFromPath(aPathRoot, aReference):
	pathRoot = convertToUnixSlash(aPathRoot)
	reference = convertToUnixSlash(aReference)
	
	if os.path.isabs(reference):
		reference = reference.lstrip(r'/')
	
	joined = os.path.join(pathRoot, reference)
	
	return os.path.abspath(joined)
   

def absPathFromFile(aFileRoot, aReference):
	pathRoot = os.path.dirname(aFileRoot)
	return absPathFromPath(pathRoot, aReference)

def sanitise(aPotentialFilename):
	"Take a string and return a version suitable for use as a filename."
	return re.sub("(\\\\|\/|:|;| )", "_", aPotentialFilename)

def resolveSymbianPath(aFileRoot, aReference, aMainType="", aSubType="", aEPOCROOT="$(EPOCROOT)"):
	""" Convert raw Symbian metadata path/file references into absolute makefile references, or list of references

	<drive>-prefix	: maps to an emulated drive depending on the following cases:
							(a) If the drive is C:, it maps to the *two* locations
								$(EPOCROOT)/epoc32/data/<drive>/<path> and
								$(EPOCROOT)/epoc32/winscw/<drive>/<path>
							(b) If the drive is A:, B:, or D: to Z:, it maps to the *three* locations
								$(EPOCROOT)/epoc32/data/<drive>/<path> and
								$(EPOCROOT)/epoc32/release/winscw/udeb/<drive>/<path> and
								$(EPOCROOT)/epoc32/release/winscw/urel/<drive>/<path>
	Absolute 		: true absolute if:
							(a) PRJ_*EXPORTS destination or DEFFILE location and
							(b) not starting with an 'epoc32'
						otherwise relative to $(EPOCROOT)
	Relative 		: relative to $(EPOCROOT)/epoc32/include if:
							(a) PRJ_EXPORTS destination and
							(b) not a :zip statement,
					  relative to $(EPOCROOT) if:
							(a) PRJ_(TEST)EXPORTS destination and
							(b) a :zip statement,
						otherwise relative to aFileRoot
	|-prefix 		: relative to aFileRoot
	+-prefix 		: relative to $(EPOCROOT)/epoc32"""
	
	# Both reference and fileroot can have backslashes - so convert them.
	reference = convertToUnixSlash(aReference)
	fileroot = convertToUnixSlash(aFileRoot)
	
	# Remove Trailing backslashes so that the expansions doesnt mess up the shell
	if reference.endswith('/') and len(reference) > 1:
		reference = reference.rstrip('/')

	emulatedDrive = dosDriveRegEx.match(reference)	
	if emulatedDrive:
		# Emulated drive C:/ Z:/ and the like
		# C: drive 
		if reference.lower().startswith("c"):
			resolvedPath = []
			resolvedPath.append(dosDriveRegEx.sub(aEPOCROOT+'/epoc32/data/'+emulatedDrive.group(1), reference))
			resolvedPath.append(dosDriveRegEx.sub(aEPOCROOT+'/epoc32/winscw/'+emulatedDrive.group(1), reference))
		else: # Other letters: A, B and D to Z
			resolvedPath = []
			resolvedPath.append(dosDriveRegEx.sub(aEPOCROOT+'/epoc32/data/'+emulatedDrive.group(1), reference))
			resolvedPath.append(dosDriveRegEx.sub(aEPOCROOT+'/epoc32/release/winscw/udeb/'+emulatedDrive.group(1), reference))
			resolvedPath.append(dosDriveRegEx.sub(aEPOCROOT+'/epoc32/release/winscw/urel/'+emulatedDrive.group(1), reference))
	elif os.path.isabs(reference):
		# Absolute
		if re.search("(DEFFILE|PRJ_(TEST)?EXPORTS)", aMainType, re.I) and not re.search("^\/epoc32\/", reference, re.I):
			# Ensures prepending of drive if on Windows
			resolvedPath = os.path.abspath(reference)
		else:
			resolvedPath = aEPOCROOT + reference
		
	elif reference.startswith("+"):
		# '+' prefix
		reference = reference.lstrip(r'+')
		resolvedPath = aEPOCROOT + '/epoc32'+reference
	elif reference.startswith("|"):
		# '|' prefix
		reference = reference.lstrip(r'|')
		resolvedPath = absPathFromFile(fileroot, reference)
	else:
		# Relative
		if aMainType == "PRJ_EXPORTS" and aSubType != ":zip":
			resolvedPath = aEPOCROOT + '/epoc32/include/'+reference
		elif aSubType == ":zip":
			resolvedPath = aEPOCROOT + '/' + reference
		else:
			resolvedPath = absPathFromFile(fileroot, aReference)
	
	if isinstance(resolvedPath, list):
		# In this case, this is a list of export destinations, 
		makefilePath = map(lambda x: str(generic_path.Path(x)), resolvedPath)
	else:
		makefilePath = str(generic_path.Path(resolvedPath))
	
	return makefilePath # Note this is either a list of strings, or a single string


class ExternalTool(object):
	""" Generic wrapper for an external tool
	
	Provides the basic means to wrap up a tool that is external to Raptor with a
	consistent interface for both invocation and the capture of output."""
	
	def __init__(self, aTool):
		self.__Tool = aTool
		self.__Output = []

	def call(self, aArgs):		
		print "RUNNNING: %s %s" %(self.__Tool, aArgs)
		(input, output) = os.popen2(self.__Tool + " " + aArgs)
		self.__Output = output.read()
		return output.close() 
	
	def getTool(self):
		return self.__Tool

	def getOutput(self):
		return self.__Output
		
	def getOutputLines(self):
		return self.__Output.split("\n")


class NullLog(object):
	""" If your class has these methods then it can act as a log """
	def Info(self, format, *extras):
		"Send an information message to the configured channel"
		return

	def ClockInfo(self):
		"Print a timestamp in seconds"
		return

	def Debug(self, format, *extras):
		"Send a debugging message to the configured channel"
		return

	def Warn(self, format, *extras):
		"Send a warning message to the configured channel"
		return

	def Error(self, format, *extras):
		"Send an error message to the configured channel"
		return

nulllog = NullLog()

def copyfile(_source, _destination):
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
			# preserve permissions
			shutil.copy(source_str, dest_str)
			return 
		# Destination file exists so we have to think about updating it
		sourceMTime = 0
		destMTime = 0
		sourceStat = 0
		try:
			sourceStat = os.stat(source_str)
			sourceMTime = sourceStat[stat.ST_MTIME]
		except OSError, e:
			message = "Source of copyfile does not exist:  " + str(source)
			raise IOError(message)
		try:
			destMTime = os.stat(dest_str)[stat.ST_MTIME]
		except OSError, e:
			pass # destination doesn't have to exist

		if destMTime == 0 or destMTime < sourceMTime:
			# remove old version
			#	- not having ownership prevents chmod
			#	- avoid clobbering the original if it is a hard link
			if os.path.exists(dest_str):
				os.unlink(dest_str)
			# preserve permissions
			shutil.copy(source_str, dest_str)

	except Exception,e:
		message = "Could not update " + dest_str + " from " + source_str + " : " + str(e)
		raise IOError(message)

	return 



## Commandline processing utilities ##

fullCommandOption = "--command"
miniCommandOption = "--co"  # update this if another "co" option is added

def read_command_file(filename, used):
	"""Read commandline options in from a file"""
	if filename in used:
		raise IOError("command file '%s' refers to itself" % filename)

	args = []
	try:
		file = open(filename, "r")
		for line in file.readlines():
			args.extend(line.split())
		file.close()
	except:
		raise IOError("couldn't read command file '%s'" % filename)

	# expand any command files in the options we just read.
	# making sure we don't get stuck in a loop.
	usedPlusThis = used[:]
	usedPlusThis.append(filename)
	return expand_command_options(args, usedPlusThis)

def expand_command_options(args, files = []):
	"""process commandline options to recursively expand command files (--command options) into a full list of options."""
	expanded = []
	previousWasOpt = False

	for a in args:
		if previousWasOpt: # then this one is the filename
			expanded.extend(read_command_file(a, files))
			previousWasOpt = False
			continue

		if a.startswith(miniCommandOption):
			if "=" in a: # then this is opt=filename
				opt = a.split("=")
				if fullCommandOption.startswith(opt[0]):
					expanded.extend(read_command_file(opt[1], files))
					continue
			else: # the next one is the filename
				if fullCommandOption.startswith(a):
					previousWasOpt = True
					continue

		expanded.append(a) # an ordinary arg, nothing to do with command files

	return expanded
