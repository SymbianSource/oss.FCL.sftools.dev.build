#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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

# Python Script to create the vmap file for Binary Variation support in SBSv2

import sys
import os
import re
import subprocess
import tempfile
import traceback
from optparse import OptionParser

# the script will exit with 0 if there are no errors
global exitCode
exitCode = 0

# are we running on Windows?
onWindows = sys.platform.lower().startswith("win")

# error messages go to stderr
def error(format, *extras):
	sys.stderr.write("createvmap: error: " + (format % extras) + "\n")
	global exitCode
	exitCode = 1

# warning messages go to stderr
def warning(format, *extras):
	sys.stderr.write("createvmap: warning: " + (format % extras) + "\n")

# debug messages go to stderr
global printDebug
#
def debug(format, *extras):
	if printDebug:
		sys.stderr.write("createvmap: " + (format % extras) + "\n")
	
# Return a dictionary with the feature names and values from the preinclude file, by running cpp over the source
def getVmapMacros(aPreInclude, aPreprocessedFile=None, aCPP="cpp", aDefines="", aIncludes = ""):

	validmacros = {}
	# Run the pre-processor
	command = aCPP + " -include " + os.path.abspath(aPreInclude) + " -dU " + aDefines + aIncludes

	# Feed in the file to stdin, because we must set the stdin to something
	# other than the parent stdin anyway as that may not exist - for example
	# when using Talon.
	infile = open(aPreprocessedFile, "r")

	if onWindows:
		p = subprocess.Popen(command, bufsize=65535,
					                  stdin=infile,
					                  stdout=subprocess.PIPE,
					                  stderr=sys.stderr,
					                  universal_newlines=True)
	else:
		p = subprocess.Popen(command, bufsize=65535,
					                  stdin=infile,
					                  stdout=subprocess.PIPE,
					                  stderr=sys.stderr,
					                  close_fds=True, shell=True)
	stream = p.stdout

	# Parse the pre-processor output to look for -
	# lines "#define NAME VALUE" and "#undef NAME"
	defineRE = re.compile('^#define (?P<FEATURENAME>\w+)(\s+(?P<VALUE>\w+))?')
	undefRE = re.compile('^#undef (?P<FEATURENAME>\w+)')

	data = " "
	while data:
		data = stream.readline()

		definedmacro = defineRE.match(data)
		if definedmacro:
			name = definedmacro.group('FEATURENAME')
			value = definedmacro.group('VALUE')
			if value:
				validmacros[name] = value
			else:
				validmacros[name] = "defined"

		else:
			undefinedmacro = undefRE.match(data)
			if undefinedmacro:
				validmacros[undefinedmacro.group('FEATURENAME')] = "undefined"

	if p.wait() != 0:
		error("in command '%s'", command)
		
	infile.close()
	
	return validmacros

# Extract the features from a featurelist file
def getFeatures(aFeatureList):
	features = set()
	for f in aFeatureList:
		try:
			file = open(os.path.abspath(f),'r')
		
			for data in file.readlines():
				data = data.strip()
				features.add(data)
		
			file.close()
		
		except IOError:
			error("Feature list file %s not found", f)

	return sorted(list(features))
	
# Returns a dictionary of the features to be put in the vmap file
def getVariationFeatures(aFeatureList = [] ,aPreinclude = None,aPreprocessedFile = None,aCPP = "cpp",aDefines="",aIncludes = ""):
	
	variation_features = {'FEATURENAME':[],'VALUE':[]}
	macros = getVmapMacros(aPreinclude,aPreprocessedFile,aCPP,aDefines,aIncludes)
	
	# Co-relate the macros obtained from the pre-processor to the featurelist
	for f in aFeatureList:
		if f in macros:
			variation_features['FEATURENAME'].append(f)
			variation_features['VALUE'].append(macros[f])
	
	return variation_features

# Write to the vmap file, with the supplied dictionary containing the features
# The vmap path will be created if it doesn't exist
def createVmapFile(aMacroDictionary,aOutputfile):
	if not os.path.exists(os.path.dirname(aOutputfile)):
		os.makedirs(os.path.dirname(aOutputfile))
	try:
		vmapfile = open(aOutputfile,'w')
	except IOError:
		error("Cannot write to " + aOutputfile)
	i = 0
	while i < len(aMacroDictionary['FEATURENAME']):
		vmapfile.write(aMacroDictionary['FEATURENAME'][i]+"="+aMacroDictionary['VALUE'][i]+"\n")
		i += 1
	vmapfile.close()

def check_exists(thing, filenames):
	if not filenames:
		error("No %s specified", thing)
		return
	
	if not isinstance(filenames, list):
		# we just have a single string
		filenames = [filenames]
		
	for filename in filenames:
		if not os.path.exists(filename):
			error("The %s '%s' does not exist", thing, filename)
		
# Main function, creates the vmap file
def main():

	try:
		global exitCode, printDebug
		
		# any exceptions make us traceback and exit

		parser = OptionParser(prog = "createvmap.py")
	
		parser.add_option("-c","--cpploc",action="store",dest="cpplocation",help="Full path of the preprocessor")
		parser.add_option("-d","--debug",action="store_true",default=False,dest="debug",help="Turn debug information on")
		parser.add_option("-D","--define",action="append",dest="defines",help="Macro definition")
		parser.add_option("-f","--featurelist",action="append",dest="featurelistfile",help="List of featureslist files")
		parser.add_option("-o","--output",action="store",dest="outputvmapfile",help="Output VMAP file name")
		parser.add_option("-p","--preinclude",action="store",dest="preinclude",help="Pre-include file ")
		parser.add_option("-s","--source",action="append",dest="sourcefiles",help="List of source files")
		parser.add_option("-u","--userinc",action="append",dest="user_include",help="User Include Folders")
		parser.add_option("-x","--systeminc",action="append",dest="system_include",help="System Include Folders")

		(options, leftover_args) = parser.parse_args(sys.argv[1:])

		if leftover_args:
			for invalids in leftover_args:
				warning("Unknown parameter '%s'" % invalids)
		
		printDebug = options.debug
		debug("Source Files     -> %s", options.sourcefiles)
		debug("Macro defines    -> %s", options.defines)
		debug("Features Files   -> %s", options.featurelistfile)
		debug("Pre-Include File -> %s", options.preinclude)
		debug("User Includes    -> %s", options.user_include)
		debug("System Includes  -> %s", options.system_include)
		debug("CPP Location     -> %s", options.cpplocation)
		debug("VMAP Output name -> %s", options.outputvmapfile)
			
		featurelist = []
		definelist = ""
		user_includeslist = ""
		system_includeslist = ""
		includeslist = ""

		# Some error checking code
		if not options.outputvmapfile:
			error("No output vmap file name supplied")
	
		# Source files must be supplied
		check_exists("source file", options.sourcefiles)
	
		# A valid preinclude file must be supplied
		check_exists("pre-include file", options.preinclude)
	
		# Some feature lists are required
		check_exists("feature list", options.featurelistfile)
	
		# A cpp tool is required
		check_exists("cpp tool", options.cpplocation)

		# if an essential option was missing then we should stop now
		if exitCode != 0:
			sys.exit(exitCode)
			
		# macro definitions
		if options.defines:
			for macro in options.defines:
				definelist += " -D" + macro.replace('__SBS__QUOTE__', '\\"')

		# Note that we have to use -isystem for user includes and system
		# includes to match what happens in the compiler. Long story.

		# Add each source directory as a user-include, so that our temporary
		# concatenated source file can find includes that were next to the
		# original source files.
		# Check that all the specified source files exist
		# and collect a set of all the source directories
		sourcedirs = set()
		for src in options.sourcefiles:
			sourcedirs.add(os.path.dirname(src))
			
		for srcdir in sourcedirs:
			user_includeslist += " -isystem " + srcdir

		# Convert the include list to a string to be passed to cpp
		if options.user_include:
			for userinc in options.user_include:
				user_includeslist += " -isystem " + userinc
		if options.system_include:
			for sysinc in options.system_include:
				system_includeslist += " -isystem " + sysinc
	
		includeslist = user_includeslist + system_includeslist

		# Get a list of all the features, from all the featurelist files
		featurelist = getFeatures(options.featurelistfile)

		# concatenate the source files together into a temporary file
		try:
			(tempfd, tempname) = tempfile.mkstemp()
			temp = os.fdopen(tempfd, "w")
			for src in options.sourcefiles:
				sfile = open(src, "r")
				for sline in sfile:
					temp.write(sline)
				sfile.close()
			temp.close()
		except Exception,e:
			error("Could not write source files into temporary file %s : %s" % (tempname, str(e)))
			return 1
		
		debug("Temporary file name : " + tempname)

		# extract the macros from the concatenated source files
		macro_dictionary = getVariationFeatures(featurelist,
		                                        options.preinclude,
								                tempname,
								                options.cpplocation,
								                definelist,
								                includeslist)
		debug("Macros extracted:") 
		for key,values in macro_dictionary.iteritems():
			debug(key + " " + str(values))

		# if there were no macros then the vmap file will be empty...
		if not macro_dictionary['FEATURENAME']:
			warning("No feature macros were found in the source")
			
		# Get rid of the temporary file
		try:
			os.remove(tempname)
		except:
			error("Could not delete temporary %s" % tempname) 

		createVmapFile(macro_dictionary, options.outputvmapfile)
		
		# exit with 0 if OK
		return exitCode

	except Exception,ex:
		traceback.print_exc()
		return 1

if __name__ == "__main__":
    sys.exit(main())

