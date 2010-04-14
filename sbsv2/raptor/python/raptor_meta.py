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
# This module includes classes that process bld.inf and .mmp files to
# generate Raptor build specifications
#

import copy
import re
import os.path
import shutil
import stat
import hashlib
import base64

import raptor
import raptor_data
import raptor_utilities
import raptor_xml
import generic_path
import subprocess
import zipfile
from xml.sax.saxutils import escape
from mmpparser import *

import time


PiggyBackedBuildPlatforms = {'ARMV5':['GCCXML']}

PlatformDefaultDefFileDir = {'WINSCW':'bwins',
				  'ARMV5' :'eabi',
				  'ARMV5SMP' :'eabi',
				  'GCCXML':'eabi',
				  'ARMV6':'eabi',
				  'ARMV7' : 'eabi',
				  'ARMV7SMP' : 'eabi'}

def getVariantCfgDetail(aEPOCROOT, aVariantCfgFile):
	"""Obtain pertinent build related detail from the Symbian variant.cfg file.

	This variant.cfg file, usually located relative to $(EPOCROOT), contains:
	(1) The $(EPOCROOT) relative location of the primary .hrh file used to configure the specific OS variant build
	(2) A flag determining whether ARMV5 represents an ABIV1 or ABIV2 build (currently unused by Raptor)."""

	variantCfgDetails = {}
	variantCfgFile = None

	try:
		variantCfgFile = open(str(aVariantCfgFile))
	except IOError, (number, message):
		raise MetaDataError("Could not read variant configuration file "+str(aVariantCfgFile)+" ("+message+")")

	for line in variantCfgFile.readlines():
		if re.search('^(\s$|\s*#)', line):
			continue
		# Note that this detection of the .hrh file matches the command line build i.e. ".hrh" somewhere
		# in the specified line
		elif re.search('\.hrh', line, re.I):
			variantHrh = line.strip()
			if variantHrh.startswith('\\') or variantHrh.startswith('/'):
				variantHrh = variantHrh[1:]
			variantHrh = aEPOCROOT.Append(variantHrh)
			variantCfgDetails['VARIANT_HRH'] = variantHrh
		else:
			lineContent = line.split()

			if len(lineContent) == 1:
				variantCfgDetails[lineContent.pop(0)] = 1
			else:
				variantCfgDetails[lineContent.pop(0)] = lineContent

	variantCfgFile.close()

	if not variantCfgDetails.has_key('VARIANT_HRH'):
		raise MetaDataError("No variant file specified in "+str(aVariantCfgFile))
	if not variantHrh.isFile():
		raise MetaDataError("Variant file "+str(variantHrh)+" does not exist")

	return variantCfgDetails

def getOsVerFromKifXml(aPathToKifXml):
	"""Obtain the OS version from the kif.xml file located at $EPOCROOT/epoc32/data/kif.xml.

	If successful, the function returns a string such as "v95" to indicate 9.5; None is
	returned if for any reason the function cannot determine the OS version."""

	releaseTagName = "ki:release"
	osVersion = None

	import xml.dom.minidom

	try:
		# Parsed document object
		kifDom = xml.dom.minidom.parse(str(aPathToKifXml))

		# elements - the elements whose names are releaseTagName
		elements = kifDom.getElementsByTagName(releaseTagName)

		# There should be exactly one of the elements whose name is releaseTagName
		# If more than one, osVersion is left as None, since the version should be
		# unique to the kif.xml file
		if len(elements) == 1:
			osVersionTemp = elements[0].getAttribute("version")
			osVersion = "v" + osVersionTemp.replace(".", "")

		kifDom.unlink() # Clean up

	except:
		# There's no documentation on which exceptions are raised by these functions.
		# We catch everything and assume any exception means there was a failure to
		# determine OS version. None is returned, and the code will fall back
		# to looking at the buildinfo.txt file.
		pass

	return osVersion

def getOsVerFromBuildInfoTxt(aPathToBuildInfoTxt):
	"""Obtain the OS version from the buildinfo.txt file located at $EPOCROOT/epoc32/data/buildinfo.txt.

	If successful, the function returns a string such as "v95" to indicate 9.5; None is
	returned if for any reason the function cannot determine the OS version.

	The file $EPOCROOT/epoc32/data/buildinfo.txt is presumed to exist. The client code should
	handle existance/non-existance."""

	pathToBuildInfoTxt = str(aPathToBuildInfoTxt) # String form version of path to buildinfo.txt

	# Open the file for reading; throw an exception if it could not be read - note that
	# it should exist at this point.
	try:
		buildInfoTxt = open(pathToBuildInfoTxt)
	except IOError, (number, message):
		raise MetaDataError("Could not read buildinfo.txt file at" + pathToBuildInfoTxt + ": (" + message + ")")

	# Example buildinfo.txt contents:
	#
	# DeviceFamily               100
	# DeviceFamilyRev            0x900
	# ManufacturerSoftwareBuild  M08765_Symbian_OS_v9.5
	#
	# Regexp to match the line containing the OS version
	# Need to match things like M08765_Symbian_OS_v9.5 and M08765_Symbian_OS_vFuture
	# So for the version, match everything except whitespace after v. Whitespace
	# signifies the end of the regexp.
	osVersionMatcher = re.compile('.*_Symbian_OS_v([^\s]*)', re.I)
	osVersion = None

	# Search for a regexp match over all the times in the file
	# Note: if two or more lines match the search pattern then
	# the latest match will overwrite the osVersion string.
	for line in buildInfoTxt:
		matchResult = osVersionMatcher.match(line)
		if matchResult:
			result = matchResult.groups()
			osVersion = "v" +  str(reduce(lambda x, y: x + y, result))
			osVersion = osVersion.replace(".", "")

	buildInfoTxt.close() # Clean-up

	return osVersion

def getBuildableBldInfBuildPlatforms(aBldInfBuildPlatforms,
									aDefaultOSBuildPlatforms,
									aBaseDefaultOSBuildPlatforms,
									aBaseUserDefaultOSBuildPlatforms):
	"""Obtain a set of build platform names supported by a bld.inf file

	Build platform deduction is based on both the contents of the PRJ_PLATFORMS section of
	a bld.inf file together with a hard-coded set of default build platforms supported by
	the build system itself."""

	expandedBldInfBuildPlatforms = []
	removePlatforms = set()

	for bldInfBuildPlatform in aBldInfBuildPlatforms:
		if bldInfBuildPlatform.upper() == "DEFAULT":
			expandedBldInfBuildPlatforms.extend(aDefaultOSBuildPlatforms.split())
		elif bldInfBuildPlatform.upper() == "BASEDEFAULT":
			expandedBldInfBuildPlatforms.extend(aBaseDefaultOSBuildPlatforms.split())
		elif bldInfBuildPlatform.upper() == "BASEUSERDEFAULT":
			expandedBldInfBuildPlatforms.extend(aBaseUserDefaultOSBuildPlatforms.split())
		elif bldInfBuildPlatform.startswith("-"):
			removePlatforms.add(bldInfBuildPlatform.lstrip("-").upper())
		else:
			expandedBldInfBuildPlatforms.append(bldInfBuildPlatform.upper())

	if len(expandedBldInfBuildPlatforms) == 0:
		expandedBldInfBuildPlatforms.extend(aDefaultOSBuildPlatforms.split())

	# make a set of platforms that can be built
	buildableBldInfBuildPlatforms = set(expandedBldInfBuildPlatforms)

	# Add platforms that are buildable by virtue of the presence of another
	for piggyBackedPlatform in PiggyBackedBuildPlatforms:
		if piggyBackedPlatform in buildableBldInfBuildPlatforms:
			buildableBldInfBuildPlatforms.update(PiggyBackedBuildPlatforms.get(piggyBackedPlatform))

	# Remove platforms that were negated
	buildableBldInfBuildPlatforms -= removePlatforms

	return buildableBldInfBuildPlatforms


def getPreProcessorCommentDetail (aPreProcessorComment):
	"""Takes a preprocessor comment and returns an array containing the filename and linenumber detail."""

	commentDetail = []
	commentMatch = re.search('# (?P<LINENUMBER>\d+) "(?P<FILENAME>.*)"', aPreProcessorComment)

	if commentMatch:
		filename = commentMatch.group('FILENAME')
		filename = os.path.abspath(filename)
		filename = re.sub(r'\\\\', r'\\', filename)
		filename = re.sub(r'//', r'/', filename)
		filename = generic_path.Path(filename)
		linenumber = int (commentMatch.group('LINENUMBER'))

		commentDetail.append(filename)
		commentDetail.append(linenumber)

	return commentDetail


def getSpecName(aFileRoot, fullPath=False):
	"""Returns a build spec name: this is the file root (full path
	or simple file name) made safe for use as a file name."""

	if fullPath:
		specName = str(aFileRoot).replace("/","_")
		specName = specName.replace(":","")
	else:
		specName = aFileRoot.File()

	return specName.lower()


# Classes

class MetaDataError(Exception):
	"""Fatal error wrapper, to be thrown directly back to whatever is calling."""

	def __init__(self, aText):
		self.Text = aText
	def __str__(self):
		return repr(self.Text)


class PreProcessedLine(str):
	"""Custom string class that accepts filename and line number information from
	a preprocessed context."""

	def __new__(cls, value, *args, **keywargs):
		return str.__new__(cls, value)

	def __init__(self, value, aFilename, aLineNumber):
		self.filename = aFilename
		self.lineNumber = aLineNumber

	def getFilename (self):
		return self.filename

	def getLineNumber (self):
		return self.lineNumber

class PreProcessor(raptor_utilities.ExternalTool):
	"""Preprocessor wrapper suitable for Symbian metadata file processing."""

	def __init__(self, aPreProcessor,
				 aStaticOptions,
				 aIncludeOption,
				 aMacroOption,
				 aPreIncludeOption,
				 aRaptor):
		raptor_utilities.ExternalTool.__init__(self, aPreProcessor)
		self.__StaticOptions = aStaticOptions
		self.__IncludeOption = aIncludeOption
		self.__MacroOption = aMacroOption
		self.__PreIncludeOption = aPreIncludeOption

		self.filename = ""
		self.__Macros = []
		self.__IncludePaths = []
		self.__PreIncludeFile = ""
		self.raptor = aRaptor

	def call(self, aArgs, sourcefilename):
		""" Override call so that we can do our own error handling."""
		tool = self._ExternalTool__Tool
		commandline = tool + " " + aArgs + " " + str(sourcefilename)
		try:
			# the actual call differs between Windows and Unix
			if raptor_utilities.getOSFileSystem() == "unix":
				p = subprocess.Popen(commandline, \
									 shell=True, bufsize=65535, \
									 stdin=subprocess.PIPE, \
									 stdout=subprocess.PIPE, \
									 stderr=subprocess.PIPE, \
									 close_fds=True)
			else:
				p = subprocess.Popen(commandline, \
									 bufsize=65535, \
									 stdin=subprocess.PIPE, \
									 stdout=subprocess.PIPE, \
									 stderr=subprocess.PIPE, \
									 universal_newlines=True)

			# run the command and wait for all the output
			(self._ExternalTool__Output, errors) = p.communicate()

			if self.raptor.debugOutput:
				self.raptor.Debug("Preprocessing Start %s", str(sourcefilename))
				self.raptor.Debug("Output:\n%s", self._ExternalTool__Output)
				self.raptor.Debug("Errors:\n%s", errors)
				self.raptor.Debug("Preprocessing End %s", str(sourcefilename))

			incRE = re.compile("In file included from")
			fromRE = re.compile(r"\s+from")
			warningRE = re.compile("warning:|pasting.+token|from.+:")
			remarkRE = re.compile("no newline at end of file|does not give a valid preprocessing token")

			actualErr = False
			if errors != "":
				for error in errors.splitlines():
					if incRE.search(error) or fromRE.search(error):
						continue
					if not remarkRE.search(error):
						if warningRE.search(error):
							self.raptor.Warn("%s: %s", tool, error)
						else:
							self.raptor.Error("%s: %s", tool, error)
							actualErr = True
			if actualErr:
				raise MetaDataError("Errors in %s" % str(sourcefilename))

		except Exception,e:
			raise MetaDataError("Preprocessor exception: '%s' : in command : '%s'" % (str(e), commandline))

		return 0	# all OK

	def setMacros(self, aMacros):
		self.__Macros = aMacros

	def addMacro(self, aMacro):
		self.__Macros.append(aMacro)

	def addMacros(self, aMacros):
		self.__Macros.extend(aMacros)

	def getMacros(self):
		return self.__Macros


	def addIncludePath(self, aIncludePath):
		p = str(aIncludePath)
		if p == "":
			self.raptor.Warn("attempt to set an empty preprocessor include path for %s" % str(self.filename))
		else:
			self.__IncludePaths.append(p)

	def addIncludePaths(self, aIncludePaths):
		for path in aIncludePaths:
			self.addIncludePath(path)

	def setIncludePaths(self, aIncludePaths):
		self.__IncludePaths = []
		self.addIncludePaths(aIncludePaths)

	def setPreIncludeFile(self, aPreIncludeFile):
		self.__PreIncludeFile = aPreIncludeFile

	def preprocess(self):
		preProcessorCall = self.__constructPreProcessorCall()
		returnValue = self.call(preProcessorCall, self.filename)

		return self.getOutput()

	def __constructPreProcessorCall(self):

		call = self.__StaticOptions

		if self.__PreIncludeFile:
			call += " " + self.__PreIncludeOption
			call += " " + str(self.__PreIncludeFile)

		for macro in self.__Macros:
			call += " " + self.__MacroOption + macro

		for includePath in self.__IncludePaths:
			call += " " + self.__IncludeOption
			call += " " + str(includePath)

		return call


class MetaDataFile(object):
	"""A generic representation of a Symbian metadata file

	Symbian metadata files are subject to preprocessing, primarily with macros based
	on the selected build platform.  This class provides a generic means of wrapping
	up the preprocessing of such files."""

	def __init__(self, aFilename, gnucpp, depfiles, aRootLocation=None, log=None):
		"""
		@param aFilename	An MMP, bld.inf or other preprocessable build spec file
		@param aDefaultPlatform  Default preprocessed version of this file
		@param aCPP 		location of GNU CPP
		@param depfiles     	list to add dependency file tuples to
		@param aRootLocation    where the file is 
		@param log 		A class with Debug(<string>), Info(<string>) and Error(<string>) methods
		"""
		self.filename = aFilename
		self.__RootLocation = aRootLocation
		# Dictionary with key of build platform and a text string of processed output as values
		self.__PreProcessedContent = {}
		self.log = log
		self.depfiles = depfiles

		self.__gnucpp = gnucpp
		if gnucpp is None:
			raise ValueError('gnucpp must be set')

	def depspath(self, platform):
	   """ Where does dependency information go relative to platform's SBS_BUILD_DIR?
	       Subclasses should redefine this
	   """
	   return str(platform['SBS_BUILD_DIR']) + "/" + str(self.__RootLocation) + "." + platform['key_md5'] + ".d"

	def getContent(self, aBuildPlatform):

		key = aBuildPlatform['key']

		config_macros = []

		adepfilename = self.depspath(aBuildPlatform)
		generateDepsOptions = ""
		if adepfilename:

			if raptor_utilities.getOSPlatform().startswith("win"):
				metatarget = "$(PARSETARGET)"
			else:
				metatarget = "'$(PARSETARGET)'"
			generateDepsOptions = "-MD -MF%s -MT%s" % (adepfilename, metatarget)
			self.depfiles.append((adepfilename, metatarget))
			try:
				os.makedirs(os.path.dirname(adepfilename))
			except Exception, e:
				self.log.Debug("Couldn't make bldinf outputpath for dependency generation")

		config_macros = (aBuildPlatform['PLATMACROS']).split()

		if not key in self.__PreProcessedContent:

			preProcessor = PreProcessor(self.__gnucpp, '-undef -nostdinc ' + generateDepsOptions + ' ',
										'-I', '-D', '-include', self.log)
			preProcessor.filename = self.filename

			# always have the current directory on the include path
			preProcessor.addIncludePath('.')

			# the SYSTEMINCLUDE directories defined in the build config
			# should be on the include path. This is added mainly to support
			# Feature Variation as SYSTEMINCLUDE is usually empty at this point.
			systemIncludes = aBuildPlatform['SYSTEMINCLUDE']
			if systemIncludes:
				preProcessor.addIncludePaths(systemIncludes.split())

			preInclude = aBuildPlatform['VARIANT_HRH']

			# for non-Feature Variant builds, the directory containing the HRH should
			# be on the include path
			if not aBuildPlatform['ISFEATUREVARIANT']:
				preProcessor.addIncludePath(preInclude.Dir())

			# and EPOCROOT/epoc32/include
			preProcessor.addIncludePath(aBuildPlatform['EPOCROOT'].Append('epoc32/include'))

			# and the directory containing the bld.inf file
			if self.__RootLocation is not None and str(self.__RootLocation) != "":
				preProcessor.addIncludePath(self.__RootLocation)

			# and the directory containing the file we are processing
			preProcessor.addIncludePath(self.filename.Dir())

			# there is always a pre-include file
			preProcessor.setPreIncludeFile(preInclude)

			macros = ["SBSV2"]

			if config_macros:
				macros.extend(config_macros)

			if macros:
				for macro in macros:
					preProcessor.addMacro(macro + "=_____" +macro)

			# extra "raw" macros that do not need protecting
			preProcessor.addMacro("__GNUC__=3")

			preProcessorOutput = preProcessor.preprocess()

			# Resurrect preprocessing replacements
			pattern = r'([\\|/]| |) ?_____(('+macros[0]+')'
			for macro in macros[1:]:
				pattern += r'|('+macro+r')'

			pattern += r'\s*)'
			# Work on all Macros in one substitution.
			text = re.sub(pattern, r"\1\2", preProcessorOutput)
			text = re.sub(r"\n[\t ]*", r"\n", text)

			self.__PreProcessedContent[key] = text

		return self.__PreProcessedContent[key]

class MMPFile(MetaDataFile):
	"""A generic representation of a Symbian metadata file

	Symbian metadata files are subject to preprocessing, primarily with macros based
	on the selected build platform.  This class provides a generic means of wrapping
	up the preprocessing of such files."""

	def __init__(self, aFilename, gnucpp, bldinf, depfiles, log=None):
		"""
		@param aFilename	An MMP, bld.inf or other preprocessable build spec file
		@param gnucpp 		location of GNU CPP
		@param bldinf		the bld.inf file this mmp was specified in
		@param depfiles         list to fill with mmp dependency files
		@param log 		A class with Debug(<string>), Info(<string>) and Error(<string>) methods
		"""
		super(MMPFile, self).__init__(aFilename, gnucpp, depfiles, str(bldinf.filename.Dir()),  log)
		self.__bldinf = bldinf
		self.depfiles = depfiles

		self.__gnucpp = gnucpp
		if gnucpp is None:
			raise ValueError('gnucpp must be set')

	def depspath(self, platform):
	   """ Where does dependency information go relative to platform's SBS_BUILD_DIR?
	       Subclasses should redefine this
	   """
	   return self.__bldinf.outputpath(platform) + "/" + self.filename.File() + '.' + platform['key_md5'] + ".d"

class Export(object):
	"""Single processed PRJ_EXPORTS or PRJ_TESTEXPORTS entry from a bld.inf file"""

	def getPossiblyQuotedStrings(cls,spec):
		""" 	Split a string based on whitespace
			but keep double quoted substrings together.
		"""
		inquotes=False
		intokengap=False
		sourcedest=[]
		word = 0
		for c in spec:
			if c == '"':
				if inquotes:
					inquotes = False
					word += 1
					intokengap = True
				else:
					inquotes = True
					intokengap = False
				pass
			elif c == ' ' or c == '\t':
				if inquotes:
					if len(sourcedest) == word:
						sourcedest.append(c)
					else:
						sourcedest[word] += c
				else:
					if intokengap:
						# gobble unquoted spaces
						pass
					else:
						word += 1
						intokengap=True
				pass
			else:
				intokengap = False
				if len(sourcedest) == word:
					sourcedest.append(c)
				else:
					sourcedest[word] += c

		return sourcedest

	getPossiblyQuotedStrings = classmethod(getPossiblyQuotedStrings)


	def __init__(self, aBldInfFile, aExportsLine, aType):
		"""
		Rules from the OS library for convenience:

		For PRJ_TESTEXPORTS
		source_file_1 [destination_file]
		source_file_n [destination_file]
		If the source file is listed with a relative path, the path will
	 	  be considered relative to the directory containing the bld.inf file.
		If a destination file is not specified, the source file will be copied
		  to the directory containing the bld.inf file.
		If a relative path is specified with the destination file, the path
		  will be considered relative to directory containing the bld.inf file.

		For PRJ_EXPORTS
		source_file_1 [destination_file]
		source_file_n [destination_file]
		:zip zip_file [destination_path]

		Note that:
		If a source file is listed with a relative path, the path will be
		considered relative to the directory containing the bld.inf file.

		If a destination file is not specified, the source file will be copied
		to epoc32\include\.

		If a destination file is specified with the relative path, the path will
		be considered relative to directory epoc32\include\.

		If a destination begins with a drive letter, then the file is copied to
		epoc32\data\<drive_letter>\<path>. For example,

			mydata.dat e:\appdata\mydata.dat
			copies mydata.dat to epoc32\data\e\appdata\mydata.dat.
			You can use any driveletter between A and Z.

		A line can start with the preface :zip. This instructs the build tools
		to unzip the specified zip file to the specified destination path. If a
		destination path is not specified, the source file will be unzipped in
		the root directory.


		"""

		# Work out what action is required - unzip or copy?
		action = "copy"
		typematch = re.match(r'^\s*(?P<type>:zip\s+)?(?P<spec>[^\s].*[^\s])\s*$',aExportsLine, re.I)

		spec = typematch.group('spec')
		if spec == None:
			raise ValueError('must specify at least a source file for an export')

		if typematch.group('type') is not None:
			action = "unzip"

		# Split the spec into source and destination but take care
		# to allow filenames with quoted strings.
		exportEntries = Export.getPossiblyQuotedStrings(spec)

		# Get the source path as specified by the bld.inf
		source_spec = exportEntries.pop(0).replace(' ','%20')

		# Resolve the source file
		sourcepath = generic_path.Path(raptor_utilities.resolveSymbianPath(str(aBldInfFile), source_spec))

		# Find it if the case of the filename is wrong:
		# Carry on even if we don't find it
		foundfile = sourcepath.FindCaseless()
		if foundfile != None:
			source = str(foundfile).replace(' ','%20')
		else:
			source = str(sourcepath).replace(' ','%20')


		# Get the destination path as specified by the bld.inf
		if len(exportEntries) > 0:
			dest_spec = exportEntries.pop(0).replace(' ','%20')
		else:
			dest_spec = None
		# Destination list - list of destinations. For the WINSCW resource building stage,
		# files exported to the emulated drives and there are several locations, for example,
		# PRJ_[TEST]EXPORTS
		# 1234ABCD.SPD		z:/private/10009876/policy/1234ABCD.spd
		# needs to end up copied in
		# epoc32/data/z/private/10009876/policy/1234ABCD.spd *and* in
		# epoc32/release/winscw/udeb/z/private/10009876/policy/1234ABCD.spd *and* in
		# epoc32/release/winscw/urel/z/private/10009876/policy/1234ABCD.spd
		dest_list = []

		# Resolve the destination if one is specified
		if dest_spec:
			# check for troublesome characters
			if ':' in dest_spec and not re.search('^[a-z]:', dest_spec, re.I):
				raise ValueError("invalid filename " + dest_spec)

			dest_spec = dest_spec.replace(' ','%20')
			aSubType=""
			if action == "unzip":
				aSubType=":zip"
				dest_spec = dest_spec.rstrip("\\/")

			# Get the export destination(s) - note this can be a list of strings or just a string.
			dest_list = raptor_utilities.resolveSymbianPath(str(aBldInfFile), dest_spec, aType, aSubType)

			def process_dest(aDest):
				if dest_spec.endswith('/') or  dest_spec.endswith('\\'):
					m = generic_path.Path(source)
					aDest += '/'+m.File()
				return aDest

			if isinstance(dest_list, list):
				# Process each file in the list
				dest_list = map(process_dest, dest_list)
			else:
				# Process the single destination
				dest_list = process_dest(dest_list)

		else:
			# No destination was specified so we assume an appropriate one

			dest_filename=generic_path.Path(source).File()

			if aType == "PRJ_EXPORTS":
				if action == "copy":
					destination = '$(EPOCROOT)/epoc32/include/'+dest_filename
				elif action == "unzip":
					destination = '$(EPOCROOT)'
			elif aType == "PRJ_TESTEXPORTS":
				d = aBldInfFile.Dir()
				if action == "copy":
					destination = str(d.Append(dest_filename))
				elif action == "unzip":
					destination = "$(EPOCROOT)"
			else:
				raise ValueError("Export type should be 'PRJ_EXPORTS' or 'PRJ_TESTEXPORTS'. It was: "+str(aType))


		self.__Source = source
		if len(dest_list) > 0: # If the list has length > 0, this means there are several export destinations.
			self.__Destination = dest_list
		else: # Otherwise the list has length zero, so there is only a single export destination.
			self.__Destination = destination
		self.__Action = action

	def getSource(self):
		return self.__Source

	def getDestination(self):
		return self.__Destination # Note that this could be either a list, or a string, depending on the export destination

	def getAction(self):
		return self.__Action

class ExtensionmakefileEntry(object):
	def __init__(self, aGnuLine, aBldInfFile, tmp):

		self.__BldInfFile = aBldInfFile
		bldInfLocation = self.__BldInfFile.Dir()
		biloc = str(bldInfLocation)
		extInfLocation = tmp.filename.Dir()
		eiloc = str(extInfLocation)

		if eiloc is None or eiloc == "":
			eiloc="." # Someone building with a relative raptor path
		if biloc is None or biloc == "":
			biloc="." # Someone building with a relative raptor path

		self.__StandardVariables = {}
		# Relative step-down to the root - let's try ignoring this for now, as it
		# should amount to the same thing in a world where absolute paths are king
		self.__StandardVariables['TO_ROOT'] = ""
		# Top-level bld.inf location
		self.__StandardVariables['TO_BLDINF'] = biloc
		self.__StandardVariables['EXTENSION_ROOT'] = eiloc

		# Get the directory and filename from the full path containing the extension makefile
		self.__FullPath = generic_path.Join(eiloc,aGnuLine)
		self.__FullPath = self.__FullPath.GetLocalString()
		self.__Filename = os.path.split(self.__FullPath)[1]
		self.__Directory = os.path.split(self.__FullPath)[0]

	def getMakefileName(self):
		return self.__Filename

	def getMakeDirectory(self):
		return self.__Directory

	def getStandardVariables(self):
		return self.__StandardVariables

class Extension(object):
	"""Single processed PRJ_EXTENSIONS or PRJ_TESTEXTENSIONS START EXTENSIONS...END block
	from a bld.inf file"""

	def __init__(self, aBldInfFile, aStartLine, aOptionLines, aBuildPlatform, aRaptor):
		self.__BldInfFile = aBldInfFile
		self.__Options = {}
		self.interface = ""
		self.__Raptor = aRaptor

		makefile = ""
		makefileMatch = re.search(r'^\s*START EXTENSION\s+(?P<MAKEFILE>\S+)\s*(?P<NAMETAG>\S*)$', aStartLine, re.I)

		self.__RawMakefile = ""

		if (makefileMatch):
			self.__RawMakefile = makefileMatch.group('MAKEFILE')
			self.nametag = makefileMatch.group('NAMETAG').lower()

			# Ensure all \'s are translated into /'s if required
			self.interface = self.__RawMakefile
			self.interface = self.interface.replace("\\", "/").replace("/", ".")

		# To support standalone testing, '$(' prefixed TEMs  are assumed to  start with
		# a makefile variable and hence be fully located in FLM operation
		if self.__RawMakefile.startswith("$("):
			self.__Makefile = self.__RawMakefile + ".mk"
		else:
			self.__Makefile = '$(MAKEFILE_TEMPLATES)/' + self.__RawMakefile + ".mk"

		for optionLine in aOptionLines:
			optionMatch = re.search(r'^\s*(OPTION\s+)?(?P<VARIABLE>\S+)\s+(?P<VALUE>\S+.*)$',optionLine, re.I)
			if optionMatch:
				self.__Options[optionMatch.group('VARIABLE').upper()] = optionMatch.group('VALUE')

		bldInfLocation = self.__BldInfFile.Dir()

		biloc = str(bldInfLocation)
		if biloc is None or biloc == "":
			biloc="." # Someone building with a relative raptor path

		extInfLocation = aStartLine.filename.Dir()

		eiloc = str(extInfLocation)
		if eiloc is None or eiloc == "":
			eiloc="." # Someone building with a relative raptor path

		self.__StandardVariables = {}
		# Relative step-down to the root - let's try ignoring this for now, as it
		# should amount to the same thing in a world where absolute paths are king
		self.__StandardVariables['TO_ROOT'] = ""
		# Top-level bld.inf location
		self.__StandardVariables['TO_BLDINF'] = biloc
		# Location of bld.inf file containing the current EXTENSION block
		self.__StandardVariables['EXTENSION_ROOT'] = eiloc

		# If the interface exists, this means it's not a Template Extension Makefile so don't look for a .meta file for it;
		# so do nothing if it's not a template extension makefile
		try:
			self.__Raptor.cache.FindNamedInterface(str(self.interface), aBuildPlatform['CACHEID'])
		except KeyError: # This means that this Raptor doesn't have the interface self.interface, so we are in a TEM
			# Read extension meta file and get default options from it.  The use of TEM meta file is compulsory if TEM is used
			metaFilename = "%s/epoc32/tools/makefile_templates/%s.meta" % (aBuildPlatform['EPOCROOT'], self.__RawMakefile)
			metaFile = None
			try:
				metaFile = open(metaFilename, "r")
			except IOError, e:
				self.__warn("Extension: %s - cannot open Meta file: %s" % (self.__RawMakefile, metaFilename))

			if metaFile:
				for line in metaFile.readlines():
					defaultOptionMatch = re.search(r'^OPTION\s+(?P<VARIABLE>\S+)\s+(?P<VALUE>\S+.*)$',line, re.I)
					if defaultOptionMatch and defaultOptionMatch.group('VARIABLE').upper() not in self.__Options.keys():
						self.__Options[defaultOptionMatch.group('VARIABLE').upper()] = defaultOptionMatch.group('VALUE')

				metaFile.close()

	def __warn(self, format, *extras):
		if (self.__Raptor):
			self.__Raptor.Warn(format, *extras)

	def getIdentifier(self):
		return re.sub (r'\\|\/|\$|\(|\)', '_', self.__RawMakefile)

	def getMakefile(self):
		return self.__Makefile

	def getOptions(self):
		return self.__Options

	def getStandardVariables(self):
		return self.__StandardVariables

class MMPFileEntry(object):
	def __init__(self, aFilename, aTestOption, aARMOption):
		self.filename = aFilename
		self.testoption = aTestOption
		if aARMOption:
			self.armoption = True
		else:
			self.armoption = False


class BldInfFile(MetaDataFile):
	"""Representation of a Symbian bld.inf file"""

	def __init__(self, aFilename, gnucpp, depfiles, log=None):
		MetaDataFile.__init__(self, aFilename, gnucpp, depfiles, None, log)
		self.__Raptor = log
		self.testManual = 0
		self.testAuto = 0
	# Generic

	def getBuildPlatforms(self, aBuildPlatform):
		platformList = []

		for platformLine in self.__getSection(aBuildPlatform, 'PRJ_PLATFORMS'):
			for platformEntry in platformLine.split():
				platformList.append(platformEntry)

		return platformList

	# Build Platform Specific
	def getMMPList(self, aBuildPlatform, aType="PRJ_MMPFILES"):
		mmpFileList=[]
		gnuList = []
		makefileList = []
		extFound = False
		m = None

		hashValue = {'mmpFileList': [] , 'gnuList': [], 'makefileList' : []}

		for mmpFileEntry in self.__getSection(aBuildPlatform, aType):

			actualBldInfRoot = mmpFileEntry.getFilename()
			n = re.match('\s*(?P<makefiletype>(GNUMAKEFILE|N?MAKEFILE))\s+(?P<extmakefile>[^ ]+)\s*(support|manual)?\s*(?P<invalid>\S+.*)?\s*$',mmpFileEntry,re.I)
			if n:

				if (n.groupdict()['invalid']):
					self.log.Error("%s (%d) : invalid .mmp file qualifier \"%s\"", mmpFileEntry.filename, mmpFileEntry.getLineNumber(), n.groupdict()['invalid'])
				if raptor_utilities.getOSFileSystem() == "unix":
					self.log.Warn("NMAKEFILE/GNUMAKEFILE/MAKEFILE keywords not supported on Linux")
				else:
					extmakefilearg = n.groupdict()['extmakefile']
					bldInfDir = actualBldInfRoot.Dir()
					extmakefilename = bldInfDir.Append(extmakefilearg)
					extmakefile = ExtensionmakefileEntry(extmakefilearg, self.filename, mmpFileEntry)

					if (n.groupdict()['makefiletype']).upper() == "GNUMAKEFILE":
						gnuList.append(extmakefile)
					else:
						makefileList.append(extmakefile)
			else:
				# Currently there is only one possible option - build as arm.
				# For TESTMMPFILES, the supported options are support, tidy, ignore, manual and build as arm
				if aType.upper()=="PRJ_TESTMMPFILES":
					if re.match('\s*(?P<name>[^ ]+)\s*(?P<baa>build_as_arm)?\s*(?P<support>support)?\s*(?P<ignore>ignore)?\s*(?P<tidy>tidy)?\s*(?P<manual>manual)?\s*(?P<invalid>\S+.*)?\s*$', mmpFileEntry, re.I):
						m = re.match('\s*(?P<name>[^ ]+)\s*(?P<baa>build_as_arm)?\s*(?P<support>support)?\s*(?P<ignore>ignore)?\s*(?P<tidy>tidy)?\s*(?P<manual>manual)?\s*(?P<invalid>\S+.*)?\s*$', mmpFileEntry, re.I)
				else:
					if re.match('\s*(?P<name>[^ ]+)\s*(?P<baa>build_as_arm)?\s*(?P<invalid>\S+.*)?\s*$', mmpFileEntry, re.I):
						m = re.match('\s*(?P<name>[^ ]+)\s*(?P<baa>build_as_arm)?\s*(?P<invalid>\S+.*)?\s*$', mmpFileEntry, re.I)

			if m:
				if (m.groupdict()['invalid']):
					self.log.Error("%s (%d) : invalid .mmp file qualifier \"%s\"", mmpFileEntry.filename, mmpFileEntry.getLineNumber(), m.groupdict()['invalid'])

				mmpFileName = m.groupdict()['name']
				testmmpoption = "auto" # Setup tests to be automatic by default
				tokens = m.groupdict()
				for key,item in tokens.iteritems():
					if key=="manual" and item=="manual":
						testmmpoption = "manual"
					elif key=="support" and item=="support":
						testmmpoption = "support"
					elif key=="ignore" and item=="ignore":
						testmmpoption = "ignore"

				buildasarm = False
				if  m.groupdict()['baa']:
					if m.groupdict()['baa'].lower() == 'build_as_arm':
						buildasarm = True

				if not mmpFileName.lower().endswith('.mmp'):
					mmpFileName += '.mmp'
				bldInfDir = actualBldInfRoot.Dir()
				try:
					mmpFileName = bldInfDir.Append(mmpFileName)
					mmpfe = MMPFileEntry(mmpFileName, testmmpoption, buildasarm)
					mmpFileList.append(mmpfe)
				except ValueError, e:
					self.log.Error("invalid .mmp file name: %s" % str(e))

				m = None


		hashValue['mmpFileList'] = mmpFileList
		hashValue['gnuList'] = gnuList
		hashValue['makefileList'] = makefileList

		return hashValue

	# Return a list of gnumakefiles used in the bld.inf
	def getExtensionmakefileList(self, aBuildPlatform, aType="PRJ_MMPFILES",aString = ""):
		extMakefileList=[]
		m = None
		for extmakeFileEntry in self.__getSection(aBuildPlatform, aType):

			actualBldInfRoot = extmakeFileEntry.filename
			if aType.upper()=="PRJ_TESTMMPFILES":
				m = re.match('\s*GNUMAKEFILE\s+(?P<extmakefile>[^ ]+)\s*(?P<support>support)?\s*(?P<ignore>ignore)?\s*(?P<tidy>tidy)?\s*(?P<manual>manual)?\s*(?P<invalid>\S+.*)?\s*$',extmakeFileEntry,re.I)
			else:
				if aString == "gnumakefile":
					m = re.match('\s*GNUMAKEFILE\s+(?P<extmakefile>[^ ]+)\s*(?P<invalid>\S+.*)?\s*$',extmakeFileEntry,re.I)
				elif aString == "nmakefile":
					m = re.match('\s*NMAKEFILE\s+(?P<extmakefile>[^ ]+)\s*(?P<invalid>\S+.*)?\s*$',extmakeFileEntry,re.I)
				elif aString == "makefile":
					m = re.match('\s*MAKEFILE\s+(?P<extmakefile>[^ ]+)\s*(?P<invalid>\S+.*)?\s*$',extmakeFileEntry,re.I)
			if m:
				if (m.groupdict()['invalid']):
					self.log.Error("%s (%d) : invalid extension makefile qualifier \"%s\"", extmakeFileEntry.filename, extmakeFileEntry.getLineNumber(), m.groupdict()['invalid'])

				extmakefilearg = m.groupdict()['extmakefile']
				bldInfDir = actualBldInfRoot.Dir()
				extmakefilename = bldInfDir.Append(extmakefilearg)
				extmakefile = ExtensionmakefileEntry(extmakefilearg, self.filename, extmakeFileEntry)
				extMakefileList.append(extmakefile)
				m = None

		return extMakefileList

	def getTestExtensionmakefileList(self,aBuildPlatform,aString=""):
		return self.getExtensionmakefileList(aBuildPlatform,"PRJ_TESTMMPFILES",aString)

	def getTestMMPList(self, aBuildPlatform):
		return self.getMMPList(aBuildPlatform, "PRJ_TESTMMPFILES")

	def getRomTestType(self, aBuildPlatform):
		testMMPList = self.getTestMMPList(aBuildPlatform)
		for testMMPFileEntry in testMMPList['mmpFileList']:
			if aBuildPlatform["TESTCODE"]:
				# Calculate test type (manual or auto)
				if testMMPFileEntry.testoption == "manual":
					self.testManual += 1
				if not (testMMPFileEntry.testoption == "support" or testMMPFileEntry.testoption == "manual" or testMMPFileEntry.testoption == "ignore"):
					self.testAuto += 1
		if self.testManual and self.testAuto:
			return 'BOTH'
		elif self.testAuto:
			return 'AUTO'
		elif self.testManual:
			return 'MANUAL'
		else:
			return 'NONE'

	def getExports(self, aBuildPlatform, aType="PRJ_EXPORTS"):
		exportList = []

		for exportLine in self.__getSection(aBuildPlatform, aType):

			if not re.match(r'\S+', exportLine):
				continue

			try:
				exportList.append(Export(exportLine.getFilename(), exportLine, aType))
			except ValueError,e:
				self.log.Error(str(e))

		return exportList

	def getTestExports(self, aBuildPlatform):
		return self.getExports(aBuildPlatform, "PRJ_TESTEXPORTS")

	def getExtensions(self, aBuildPlatform, aType="PRJ_EXTENSIONS"):
		extensionObjects = []
		start = ""
		options = []

		for extensionLine in self.__getSection(aBuildPlatform, aType):
			if (re.search(r'^\s*START ',extensionLine, re.I)):
				start = extensionLine
			elif re.search(r'^\s*END\s*$',extensionLine, re.I):
				extensionObjects.append(Extension(self.filename, start, options, aBuildPlatform, self.__Raptor))
				start = ""
				options = []
			elif re.search(r'^\s*$',extensionLine, re.I):
				continue
			elif start:
				options.append(extensionLine)

		return extensionObjects

	def getTestExtensions(self, aBuildPlatform):
		return self.getExtensions(aBuildPlatform, "PRJ_TESTEXTENSIONS")

	def __getSection(self, aBuildPlatform, aSection):

		activeSection = False
		sectionContent = []
		lineContent = re.split(r'\n', self.getContent(aBuildPlatform));

		currentBldInfFile = self.filename
		currentLineNumber = 0

		for line in lineContent:
			if line.startswith("#"):
				commentDetail = getPreProcessorCommentDetail(line)
				currentBldInfFile = commentDetail[0]
				currentLineNumber = commentDetail[1]-1
				continue

			currentLineNumber += 1

			if not re.match(r'.*\S+', line):
				continue
			elif re.match(r'\s*' + aSection + r'\s*$', line, re.I):
				activeSection = True
			elif re.match(r'\s*PRJ_\w+\s*$', line, re.I):
				activeSection = False
			elif activeSection:
				sectionContent.append(PreProcessedLine(line, currentBldInfFile, currentLineNumber))

		return sectionContent

	@staticmethod
	def outputPathFragment(bldinfpath):
		"""Return a relative path that uniquely identifies this bldinf file
		   whilst being short so that it can be appended to epoc32/build.
		   The  build product of a particular bld.inf may be placed in here.
		   This affects its TEMs and its MMPs"""

		absroot_str = os.path.abspath(str(bldinfpath)).lower().replace("\\","/")

		uniqueid = hashlib.md5()
		uniqueid.update(absroot_str)

		specnamecomponents = (re.sub("^[A-Za-z]:", "", absroot_str)).split('/') # split, removing any drive identifier (if present)

		pathlist=[]
		while len(specnamecomponents) > 0:
			top = specnamecomponents.pop()
			if top.endswith('.inf'):
				continue
			elif top == 'group':
				continue
			else:
				pathlist = [top]
				break

		pathlist.append("c_"+uniqueid.hexdigest()[:16])
		return "/".join(pathlist)

	def outputpath(self, platform):
		""" The full path where product from this bldinf is created."""
		return str(platform['SBS_BUILD_DIR']) + "/" + BldInfFile.outputPathFragment(self.filename)

	def depspath(self, platform):
	   """ Where does dependency information go relative to platform's SBS_BUILD_DIR?
	       Subclasses should redefine this
	   """
	   return self.outputpath(platform) + "/bldinf." + platform['key_md5'] + ".d"



class MMPRaptorBackend(MMPBackend):
	"""A parser "backend" for the MMP language

	This is used to map recognised MMP syntax onto a buildspec """

	# Support priorities, with case-fixed mappings for use
	epoc32priorities = {
		'low':'Low',
		'background':'Background',
		'foreground':'Foreground',
		'high':'High',
		'windowserver':'WindowServer',
		'fileserver':'FileServer',
		'realtimeserver':'RealTimeServer',
		'supervisor':'SuperVisor'
		}

	# Known capability flags with associated bitwise operations
	supportedCapabilities = {
		'tcb':(1<<0),
		'commdd':(1<<1),
		'powermgmt':(1<<2),
		'multimediadd':(1<<3),
		'readdevicedata':(1<<4),
		'writedevicedata':(1<<5),
		'drm':(1<<6),
		'trustedui':(1<<7),
		'protserv':(1<<8),
		'diskadmin':(1<<9),
		'networkcontrol':(1<<10),
		'allfiles':(1<<11),
		'swevent':(1<<12),
		'networkservices':(1<<13),
		'localservices':(1<<14),
		'readuserdata':(1<<15),
		'writeuserdata':(1<<16),
		'location':(1<<17),
		'surroundingsdd':(1<<18),
		'userenvironment':(1<<19),
	# Old capability names have zero value
		'root':0,
		'mediadd':0,
		'readsystemdata':0,
		'writesystemdata':0,
		'sounddd':0,
		'uidd':0,
		'killanyprocess':0,
		'devman':0,
		'phonenetwork':0,
		'localnetwork':0
	  	}

	library_re = re.compile(r"^(?P<name>[^{]+?)(?P<version>{(?P<major>[0-9]+)\.(?P<minor>[0-9]+)})?(\.(lib|dso))?$",re.I)


	def __init__(self, aRaptor, aMmpfilename, aBldInfFilename):
		super(MMPRaptorBackend,self).__init__()
		self.platformblock = None
		self.__Raptor = aRaptor
		self.__debug("-----+++++ %s " % aMmpfilename)
		self.BuildVariant = raptor_data.Variant(name = "mmp")
		self.ApplyVariants = []
		self.ResourceVariants = []
		self.BitmapVariants = []
		self.StringTableVariants = []
		self.__bldInfFilename = aBldInfFilename
		self.__targettype = "UNKNOWN"
		self.__currentMmpFile = aMmpfilename
		self.__defFileRoot = self.__currentMmpFile
		self.__currentLineNumber = 0
		self.__sourcepath = raptor_utilities.resolveSymbianPath(self.__currentMmpFile, "")
		self.__userinclude = ""
		self.__systeminclude = ""
		self.__bitmapSourcepath = self.__sourcepath
		self.__current_resource = ""
		self.__resourceFiles = []
		self.__pageConflict = []
		self.__debuggable = ""
		self.__compressionKeyword = ""
		self.sources = []
		self.capabilities = []

		self.__TARGET = ""
		self.__TARGETEXT = ""
		self.deffile = ""
		self.__LINKAS = ""
		self.nostrictdef = False
		self.featureVariant = False

		self.__currentResourceVariant = None
		self.__currentStringTableVariant = None
		self.__explicitversion = False
		self.__versionhex = ""

		# "ALL" capability calculated based on the total capabilities currently supported
		allCapabilities = 0
		for supportedCapability in MMPRaptorBackend.supportedCapabilities.keys():
			allCapabilities = allCapabilities | MMPRaptorBackend.supportedCapabilities[supportedCapability]
		MMPRaptorBackend.supportedCapabilities['all'] = allCapabilities

	# Permit unit-testing output without a Raptor context
	def __debug(self, format, *extras):
		if (self.__Raptor):
			self.__Raptor.Debug(format, *extras)

	def __warn(self, format, *extras):
		if (self.__Raptor):
			self.__Raptor.Warn(format, *extras)

	def doPreProcessorComment(self,s,loc,toks):
		commentDetail = getPreProcessorCommentDetail(toks[0])
		self.__currentMmpFile = commentDetail[0].GetLocalString()
		self.__currentLineNumber = commentDetail[1]
		self.__debug("Current file %s, line number %s\n"  % (self.__currentMmpFile,str(self.__currentLineNumber)))
		return "OK"

	def doBlankLine(self,s,loc,toks):
		self.__currentLineNumber += 1

	def doStartPlatform(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug( "Start Platform block "+toks[0])
		self.platformblock = toks[0]
		return "OK"

	def doEndPlatform(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug( "Finalise platform " + self.platformblock)
		return "OK"

	def doSetSwitch(self,s,loc,toks):
		self.__currentLineNumber += 1
		prefix=""
		varname = toks[0].upper()

		# A bright spark made the optionname the same as
		# the env variable. One will override the other if we pass this
		# on to make.  Add a prefix to prevent the clash.
		if varname=='ARMINC':
			prefix="SET_"
			self.__debug( "Set switch "+toks[0]+" ON")
			self.BuildVariant.AddOperation(raptor_data.Set(prefix+varname, "1"))

		elif varname=='NOSTRICTDEF':
			self.nostrictdef = True
			self.__debug( "Set switch "+toks[0]+" ON")
			self.BuildVariant.AddOperation(raptor_data.Set(prefix+varname, "1"))

		elif varname == 'PAGED':
			self.BuildVariant.AddOperation(raptor_data.Set(varname, "1"))
			self.__debug( "Set switch PAGE ON")
			# PAGED is equivalent to PAGEDCODE
			self.BuildVariant.AddOperation(raptor_data.Set("PAGEDCODE_OPTION", "paged"))
			self.__debug( "Set switch PAGEDCODE ON")
			self.__pageConflict.append("PAGEDCODE")

		elif varname == 'UNPAGED':
			self.BuildVariant.AddOperation(raptor_data.Set("PAGED", "0"))
			self.__debug( "Set switch PAGED OFF")
			# UNPAGED is equivalent to UNPAGEDCODE *and* UNPAGEDDATA
			self.BuildVariant.AddOperation(raptor_data.Set("PAGEDCODE_OPTION", "unpaged"))
			self.__debug( "Set switch PAGEDCODE OFF")
			self.BuildVariant.AddOperation(raptor_data.Set("PAGEDDATA_OPTION", "unpaged"))
			self.__debug( "Set data PAGEDDATA OFF")
			self.__pageConflict.append("UNPAGEDCODE")
			self.__pageConflict.append("UNPAGEDDATA")

		elif varname == 'PAGEDCODE':
			self.BuildVariant.AddOperation(raptor_data.Set("PAGEDCODE_OPTION", "paged"))
			self.__debug( "Set switch " + varname + " ON")
			self.__pageConflict.append(varname)

		elif varname == 'PAGEDDATA':
			self.BuildVariant.AddOperation(raptor_data.Set("PAGEDDATA_OPTION", "paged"))
			self.__debug( "Set switch " + varname + " ON")
			self.__pageConflict.append(varname)

		elif varname == 'UNPAGEDCODE':
			self.BuildVariant.AddOperation(raptor_data.Set("PAGEDCODE_OPTION", "unpaged"))
			self.__debug( "Set switch " + varname + " ON")
			self.__pageConflict.append(varname)
			
		elif varname == 'UNPAGEDDATA':
			self.BuildVariant.AddOperation(raptor_data.Set("PAGEDDATA_OPTION", "unpaged"))
			self.__debug( "Set switch " + varname + " ON")
			self.__pageConflict.append(varname)

		elif varname == 'NOLINKTIMECODEGENERATION':
			self.BuildVariant.AddOperation(raptor_data.Set("LTCG",""))
			self.__debug( "Set switch " + varname + " OFF")
			
		elif varname == 'NOMULTIFILECOMPILATION':
			self.BuildVariant.AddOperation(raptor_data.Set("MULTIFILE_ENABLED",""))
			self.__debug( "Set switch " + varname + " OFF")

		elif varname == 'DEBUGGABLE':
			if self.__debuggable != "udeb":
				self.__debuggable = "udeb urel"
			else:
				self.__Raptor.Warn("DEBUGGABLE keyword ignored as DEBUGGABLE_UDEBONLY is already specified")
		
		elif varname == 'DEBUGGABLE_UDEBONLY':
			if self.__debuggable != "":
				self.__Raptor.Warn("DEBUGGABLE keyword has no effect as DEBUGGABLE or DEBUGGABLE_UDEBONLY is already set")
			self.__debuggable = "udeb"
		
		elif varname == 'FEATUREVARIANT':
			self.BuildVariant.AddOperation(raptor_data.Set(varname,"1"))
			self.featureVariant = True
		
		elif varname in ['COMPRESSTARGET', 'NOCOMPRESSTARGET', 'INFLATECOMPRESSTARGET', 'BYTEPAIRCOMPRESSTARGET']:
			self.resolveCompressionKeyword(varname)
		
		else:
			self.__debug( "Set switch "+toks[0]+" ON")
			self.BuildVariant.AddOperation(raptor_data.Set(prefix+varname, "1"))

		return "OK"

	def doAssignment(self,s,loc,toks):
		self.__currentLineNumber += 1
		varname = toks[0].upper()
		if varname=='TARGET':
			(self.__TARGET, self.__TARGETEXT) = os.path.splitext(toks[1])
			self.__TARGETEXT = self.__TARGETEXT.lstrip('.')

			self.BuildVariant.AddOperation(raptor_data.Set("REQUESTEDTARGETEXT", self.__TARGETEXT.lower()))

			lowercase_TARGET = self.__TARGET.lower()
			self.__debug("Set "+toks[0]+" to " + lowercase_TARGET)
			self.__debug("Set REQUESTEDTARGETEXT to " + self.__TARGETEXT.lower())

			self.BuildVariant.AddOperation(raptor_data.Set("TARGET", self.__TARGET))
			self.BuildVariant.AddOperation(raptor_data.Set("TARGET_lower", lowercase_TARGET))
			if  lowercase_TARGET !=  self.__TARGET:
				self.__debug("TARGET is not lowercase: '%s' - might cause BC problems." % self.__TARGET)
		elif varname=='TARGETTYPE':
			self.__debug("Set "+toks[0]+" to " + str(toks[1]))
			self.__targettype=toks[1]
			if  self.__targettype.lower() == "none":
				self.BuildVariant.AddOperation(raptor_data.Set("TARGET", ""))
				self.BuildVariant.AddOperation(raptor_data.Set("TARGET_lower",""))
				self.BuildVariant.AddOperation(raptor_data.Set("REQUESTEDTARGETEXT", ""))
			self.BuildVariant.AddOperation(raptor_data.Set(varname,toks[1].lower()))

		elif varname=='TARGETPATH':
			value = toks[1].lower().replace('\\','/')
			self.__debug("Set "+varname+" to " + value)
			self.BuildVariant.AddOperation(raptor_data.Set(varname, value))

		elif varname=='OPTION' or varname=='LINKEROPTION':
			self.__debug("Set "+toks[1]+varname+" to " + str(toks[2]))
			self.BuildVariant.AddOperation(raptor_data.Append(varname+"_"+toks[1].upper()," ".join(toks[2])))

			# Warn about OPTION ARMASM
			if "armasm" in toks[1].lower():
				self.__Raptor.Warn(varname+" ARMASM has no effect (use OPTION ARMCC).")

		elif varname=='OPTION_REPLACE':
			# Warn about OPTION_REPLACE ARMASM
			if "armasm" in toks[1].lower():
				self.__Raptor.Warn("OPTION_REPLACE ARMASM has no effect (use OPTION_REPLACE ARMCC).")
			else:
				args = " ".join(toks[2])

				searchReplacePairs = self.resolveOptionReplace(args)

				for searchReplacePair in searchReplacePairs:
					self.__debug("Append %s to OPTION_REPLACE_%s", searchReplacePair, toks[1].upper())
					self.BuildVariant.AddOperation(raptor_data.Append(varname+"_"+toks[1].upper(),searchReplacePair))

		elif varname=='SYSTEMINCLUDE' or varname=='USERINCLUDE':
			for path in toks[1]:
				resolved = raptor_utilities.resolveSymbianPath(self.__currentMmpFile, path)
				self.BuildVariant.AddOperation(raptor_data.Append(varname,resolved))

				if varname=='SYSTEMINCLUDE':
					self.__systeminclude += ' ' + resolved
					self.__debug("  %s = %s",varname, self.__systeminclude)
				else:
					self.__userinclude += ' ' + resolved
					self.__debug("  %s = %s",varname, self.__userinclude)

				self.__debug("Appending %s to %s",resolved, varname)

			self.__systeminclude = self.__systeminclude.strip()
			self.__systeminclude = self.__systeminclude.rstrip('\/')
			self.__userinclude = self.__userinclude.strip()
			self.__userinclude = self.__userinclude.rstrip('\/')

		elif varname=='EXPORTLIBRARY':
			# Remove extension from the EXPORTLIBRARY name
			libName = toks[1].rsplit(".", 1)[0]
			self.__debug("Set "+varname+" to " + libName)
			self.BuildVariant.AddOperation(raptor_data.Set(varname,"".join(libName)))

		elif varname=='CAPABILITY':
			for cap in toks[1]:
				cap = cap.lower()
				self.__debug("Setting  "+toks[0]+": " + cap)
				if not cap.startswith("-"):
					if not cap.startswith("+"):
						cap = "+" + cap	
				self.capabilities.append(cap)
		elif varname=='DEFFILE':
			self.__defFileRoot = self.__currentMmpFile
			self.deffile = toks[1]
		elif varname=='LINKAS':
			self.__debug("Set "+toks[0]+"  OPTION to " + str(toks[1]))
			self.__LINKAS = toks[1]
			self.BuildVariant.AddOperation(raptor_data.Set(varname, toks[1]))
		elif varname=='SECUREID' or varname=='VENDORID':
			hexoutput = MMPRaptorBackend.canonicalUID(toks[1])
			self.__debug("Set "+toks[0]+"  OPTION to " + hexoutput)
			self.BuildVariant.AddOperation(raptor_data.Set(varname, hexoutput))
		elif varname=='VERSION':
			if toks[-1] == "EXPLICIT":
				self.__explicitversion = True
				self.BuildVariant.AddOperation(raptor_data.Set("EXPLICITVERSION", "1"))

			vm = re.match(r'^(\d+)(\.(\d+))?$', toks[1])
			if vm is not None:
				version = vm.groups()
				# the major version number
				major = int(version[0],10)

				# add in the minor number
				minor = 0
				if version[1] is not None:
					minor = int(version[2],10)
				else:
					self.__Raptor.Warn("VERSION (%s) missing '.minor' in %s, using '.0'" % (toks[1],self.__currentMmpFile))

				self.__versionhex = "%04x%04x" % (major, minor)
				self.BuildVariant.AddOperation(raptor_data.Set(varname, "%d.%d" %(major, minor)))
				self.BuildVariant.AddOperation(raptor_data.Set(varname+"HEX", self.__versionhex))
				self.__debug("Set "+toks[0]+"  OPTION to " + toks[1])
				self.__debug("Set "+toks[0]+"HEX OPTION to " + "%04x%04x" % (major,minor))

			else:
				self.__Raptor.Warn("Invalid version supplied to VERSION (%s), using default value" % toks[1])

		elif varname=='EPOCHEAPSIZE':
			# Standardise on sending hex numbers to the FLMS.

			if toks[1].lower().startswith('0x'):
				min = long(toks[1],16)
			else:
				min = long(toks[1],10)

			if toks[2].lower().startswith('0x'):
				max = long(toks[2],16)
			else:
				max = long(toks[2],10)

			self.BuildVariant.AddOperation(raptor_data.Set(varname+"MIN", "%x" % min))
			self.__debug("Set "+varname+"MIN  OPTION to '%x' (hex)" % min )
			self.BuildVariant.AddOperation(raptor_data.Set(varname+"MAX", "%x" % max))
			self.__debug("Set "+varname+"MAX  OPTION to '%x' (hex)" % max )

			# Some toolchains require decimal versions of the min/max values, converted to KB and
			# rounded up to the next 1KB boundary
			min_dec_kb = (int(min) + 1023) / 1024
			max_dec_kb = (int(max) + 1023) / 1024
			self.BuildVariant.AddOperation(raptor_data.Set(varname+"MIN_DEC_KB", "%d" % min_dec_kb))
			self.__debug("Set "+varname+"MIN  OPTION KB to '%d' (dec)" % min_dec_kb )
			self.BuildVariant.AddOperation(raptor_data.Set(varname+"MAX_DEC_KB", "%d" % max_dec_kb))
			self.__debug("Set "+varname+"MAX  OPTION KB to '%d' (dec)" % max_dec_kb )

		elif varname=='EPOCSTACKSIZE':
			if toks[1].lower().startswith('0x'):
				stack = long(toks[1],16)
			else:
				stack = long(toks[1],10)
			self.BuildVariant.AddOperation(raptor_data.Set(varname, "%x" % stack))
			self.__debug("Set "+varname+"  OPTION to '%x' (hex)" % stack  )
		elif varname=='EPOCPROCESSPRIORITY':
			# low, background, foreground, high, windowserver, fileserver, realtimeserver or supervisor
			# These are case insensitive in metadata entries, but must be mapped to a static case pattern for use
			prio = toks[1].lower()

			# NOTE: Original validation here didn't actually work.  This has been corrected to provide an error, but probably needs re-examination.
			if not MMPRaptorBackend.epoc32priorities.has_key(prio):
				self.__Raptor.Error("Priority setting '%s' is not a valid priority - should be one of %s.", prio, MMPRaptorBackend.epoc32priorities.values())
			else:
				self.__debug("Set "+toks[0]+" to " +  MMPRaptorBackend.epoc32priorities[prio])
				self.BuildVariant.AddOperation(raptor_data.Set(varname,MMPRaptorBackend.epoc32priorities[prio]))
		elif varname=='ROMTARGET' or varname=='RAMTARGET':
			if len(toks) == 1:
				self.__debug("Set "+toks[0]+" to <none>" )
				self.BuildVariant.AddOperation(raptor_data.Set(varname,"<none>"))
			else:
				toks1 = str(toks[1]).replace("\\","/")
				if toks1.find(","):
					toks1 = re.sub("[,'\[\]]", "", toks1).replace("//","/")
				self.__debug("Set "+toks[0]+" to " + toks1)
				self.BuildVariant.AddOperation(raptor_data.Set(varname,toks1))
		elif varname=='APPLY':
			self.ApplyVariants.append(toks[1])
		else:
			self.__debug("Set "+toks[0]+" to " + str(toks[1]))
			self.BuildVariant.AddOperation(raptor_data.Set(varname,"".join(toks[1])))

			if varname=='LINKAS':
				self.__LINKAS = toks[1]

		return "OK"

	def doAppend(self,s,loc,toks):
		self.__currentLineNumber += 1
		"""MMP command
		"""
		name=toks[0].upper()
		if len(toks) == 1:
			# list can be empty e.g. MACRO _FRED_ when fred it defined in the HRH
			# causes us to see just "MACRO" in the input - it is valid to ignore this
			self.__debug("Empty append list for " + name)
			return "OK"
		self.__debug("Append to "+name+" the values: " +str(toks[1]))

		if name=='MACRO':
			name='MMPDEFS'
		elif name=='LANG':
			# don't break the environment variable
			name='LANGUAGES'

		for item in toks[1]:
			if name=='MMPDEFS':
				# Unquote any macros since the FLM does it anyhow
				if item.startswith('"') and item.endswith('"') \
				or item.startswith("'") and item.endswith("'"):
					item = item.strip("'\"")
			if name=='LIBRARY' or name=='DEBUGLIBRARY':
				im = MMPRaptorBackend.library_re.match(item)
				if not im:
					self.__error("LIBRARY: %s Seems to have an invalid name.\nExpected xxxx.lib or xxxx.dso\n where xxxx might be\n\tname or \n\tname(n,m) where n is a major version number and m is a minor version number\n" %item)
				d = im.groupdict()

				item = d['name']
				if d['version'] is not None:
					item += "{%04x%04x}" % (int(d['major']), int(d['minor']))
				item += ".dso"
			elif name=='STATICLIBRARY':
				# the FLM will decide on the ending appropriate to the platform
				item = re.sub(r"^(.*)\.[Ll][Ii][Bb]$",r"\1", item)
			elif name=="LANGUAGES":
				item = item.lower()
			elif (name=="WIN32_LIBRARY" and (item.startswith(".") or re.search(r'[\\|/]',item))) \
				or (name=="WIN32_RESOURCE"):
				# Relatively pathed win32 libraries, and all win32 resources, are resolved in relation
				# to the wrapper bld.inf file in which their .mmp file is specified.  This equates to
				# the current working directory in ABLD operation.
				item = raptor_utilities.resolveSymbianPath(self.__bldInfFilename, item)
				
			self.BuildVariant.AddOperation(raptor_data.Append(name,item," "))
			
			# maintain a debug library list, the same as LIBRARY but with DEBUGLIBRARY values
			# appended as they are encountered
			if name=='LIBRARY' or name=='DEBUGLIBRARY':
				self.BuildVariant.AddOperation(raptor_data.Append("LIBRARY_DEBUG",item," "))			

		return "OK"

	def canonicalUID(number):
		""" convert a UID string into an 8 digit hexadecimal string without leading 0x """
		if number.lower().startswith("0x"):
			n = int(number,16)
		else:
			n = int(number,10)

		return "%08x" % n

	canonicalUID = staticmethod(canonicalUID)

	def doUIDAssignment(self,s,loc,toks):
		"""A single UID command results in a number of spec variables"""
		self.__currentLineNumber += 1

		hexoutput = MMPRaptorBackend.canonicalUID(toks[1][0])
		self.__debug( "Set UID2 to %s" % hexoutput )
		self.BuildVariant.AddOperation(raptor_data.Set("UID2", hexoutput))

		if len(toks[1]) > 1:
			hexoutput = MMPRaptorBackend.canonicalUID(toks[1][1])
			self.__debug( "Set UID3 to %s" % hexoutput)
			self.BuildVariant.AddOperation(raptor_data.Set("UID3", hexoutput))

		self.__debug( "done set UID")
		return "OK"

	def doSourcePathAssignment(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__sourcepath = raptor_utilities.resolveSymbianPath(self.__currentMmpFile, toks[1])
		self.__debug( "Remembering self.sourcepath state:  "+str(toks[0])+" is now " + self.__sourcepath)
		self.__debug("selfcurrentMmpFile: " + self.__currentMmpFile)
		return "OK"


	def doSourceAssignment(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug( "Setting "+toks[0]+" to " + str(toks[1]))
		for file in toks[1]:
			# file is always relative to sourcepath but some MMP files
			# have items that begin with a slash...
			file = file.lstrip("/")
			source = generic_path.Join(self.__sourcepath, file)

			# If the SOURCEPATH itself begins with a '/', then dont look up the caseless version, since
			# we don't know at this time what $(EPOCROOT) will evaluate to.
			if source.GetLocalString().startswith('$(EPOCROOT)'):
				self.sources.append(str(source))	
				self.__debug("Append SOURCE " + str(source))

			else:
				foundsource = source.FindCaseless()
				if foundsource == None:
					# Hope that the file will be generated later
					self.__debug("Sourcefile not found: %s" % source)
					foundsource = source

				self.sources.append(str(foundsource))	
				self.__debug("Append SOURCE " + str(foundsource))


		self.__debug("		sourcepath: " + self.__sourcepath)
		return "OK"

	# Resource

	def doOldResourceAssignment(self,s,loc,toks):
		# Technically deprecated, but still used, so...
		self.__currentLineNumber += 1
		self.__debug("Processing old-style "+toks[0]+" "+str(toks[1]))

		sysRes = (toks[0].lower() == "systemresource")

		for rss in toks[1]:
			variant = raptor_data.Variant()

			source = generic_path.Join(self.__sourcepath, rss)
			variant.AddOperation(raptor_data.Set("SOURCE", str(source)))
			self.__resourceFiles.append(str(source))

			target = source.File().rsplit(".", 1)[0]	# remove the extension
			variant.AddOperation(raptor_data.Set("TARGET", target))
			variant.AddOperation(raptor_data.Set("TARGET_lower", target.lower()))

			header = target.lower() + ".rsg"			# filename policy
			variant.AddOperation(raptor_data.Set("HEADER", header))

			if sysRes:
				dsrtp = self.getDefaultSystemResourceTargetPath()
				variant.AddOperation(raptor_data.Set("TARGETPATH", dsrtp))

			self.ResourceVariants.append(variant)

		return "OK"

	def getDefaultSystemResourceTargetPath(self):
		# the default systemresource TARGETPATH value should come from the
		# configuration rather than being hard-coded here. Then again, this
		# should really be deprecated away into oblivion...
		return "system/data"


	def getDefaultResourceTargetPath(self, targettype):
		# the different default TARGETPATH values should come from the
		# configuration rather than being hard-coded here.
		if targettype in ["plugin", "plugin3"]:
			return "resource/plugins"
		if targettype == "pdl":
			return "resource/printers"
		return ""

	def resolveOptionReplace(self, content):
		"""
		Constructs search/replace pairs based on .mmp OPTION_REPLACE entries for use on tool command lines
		within FLMS.

		Depending on what's supplied to OPTION_REPLACE <TOOL>, the core part of the <TOOL> command line
		in the relevant FLM will have search and replace actions performed on it post-expansion (but pre-
		any OPTION <TOOL> additions).

		In terms of logic, we try to follow what ABLD does, as the current behaviour is undocumented.
		What happens is a little inconsistent, and best described by some generic examples:

			OPTION_REPLACE TOOL existing_option replacement_value

				Replace all instances of "option existing_value" with "option replacement_value"

			OPTION_REPLACE TOOL existing_option replacement_option

				Replace all instances of "existing_option" with "replacement_option".

			If "existing_option" is present in isolation then a removal is performed.

		Any values encountered that don't follow an option are ignored.
		Options are identified as being prefixed with either '-' or '--'.

		The front-end processes each OPTION_REPLACE entry and then appends one or more search/replace pairs
		to an OPTION_REPLACE_<TOOL> variable in the following format:

		     search<->replace
		"""
		# Note that, for compatibility reasons, the following is mostly a port to Python of the corresponding
		# ABLD Perl, and hence maintains ABLD's idiosyncrasies in what it achieves

		searchReplacePairs = []
		matches = re.findall("-{1,2}\S+\s*(?!-)\S*",content)

		if matches:
			# reverse so we can process as a stack whilst retaining original order
			matches.reverse()

			while (len(matches)):
				match = matches.pop()

				standaloneMatch = re.match('^(?P<option>\S+)\s+(?P<value>\S+)$', match)

				if (standaloneMatch):
					# Option listed standalone with a replacement value
					# Example:
					# 	OPTION_REPLACE ARMCC --cpu 6
					# Intention:
					# 	Replace instances of  "--cpu <something>" with "--cpu 6"

					# Substitute any existing "option <existing_value>" instances with a single word
					# "@@<existing_value>" for later replacement
					searchReplacePairs.append('%s <->@@' % standaloneMatch.group('option'))

					# Replace "@@<existing_value>" entries from above with "option <new_value>" entries
					# A pattern substitution is used to cover pre-existing values
					searchReplacePairs.append('@@%%<->%s %s' % (standaloneMatch.group('option'), standaloneMatch.group('value')))
				else:
					# Options specified in search/replace pairs with optional values
					# Example:
					#	OPTION_REPLACE ARMCC --O2 --O3
					# Intention:
					#	Replace instances of "--O2" with "--O3"

					# At this point we will be looking at just the search option - there may or may not
					# be a replacement to consider
					search = match
					replace = ""
					if len(matches):
						replace = matches.pop()

					searchReplacePairs.append('%s<->%s' % (search, replace))

			# Replace spaces to maintain word-based grouping in downstream makefile lists
			for i in range(0,len(searchReplacePairs)):
				searchReplacePairs[i] = searchReplacePairs[i].replace(' ','%20')

		return searchReplacePairs

	def doStartResource(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug("Start RESOURCE "+toks[1])

		self.__current_resource = generic_path.Path(self.__sourcepath, toks[1])
		self.__current_resource = str(self.__current_resource)

		self.__debug("sourcepath: " + self.__sourcepath)
		self.__debug("self.__current_resource source: " + toks[1])
		self.__debug("adjusted self.__current_resource source=" + self.__current_resource)

		self.__currentResourceVariant = raptor_data.Variant()
		self.__currentResourceVariant.AddOperation(raptor_data.Set("SOURCE", self.__current_resource))
		self.__resourceFiles.append(self.__current_resource)

		# The target name is the basename of the resource without the extension
		# e.g. "/fred/129ab34f.rss" would have a target name of "129ab34f"
		target = self.__current_resource.rsplit("/",1)[-1]
		target = target.rsplit(".",1)[0]
		self.__currentResourceVariant.AddOperation(raptor_data.Set("TARGET", target))
		self.__currentResourceVariant.AddOperation(raptor_data.Set("TARGET_lower", target.lower()))
		self.__headerspecified = False
		self.__headeronlyspecified = False
		self.__current_resource_header = target.lower() + ".rsg"

		return "OK"

	def doResourceAssignment(self,s,loc,toks):
		""" Assign variables for resource files """
		self.__currentLineNumber += 1
		varname = toks[0].upper() # the mmp keyword
		varvalue = "".join(toks[1])

		# Get rid of any .rsc extension because the build system
		# needs to have it stripped off to calculate other names
		# for other purposes and # we aren't going to make it
		# optional anyhow.
		if varname == "TARGET":
			target_withext = varvalue.rsplit("/\\",1)[-1]
			target = target_withext.rsplit(".",1)[0]
			self.__current_resource_header = target.lower() + ".rsg"
			self.__currentResourceVariant.AddOperation(raptor_data.Set("TARGET_lower", target.lower()))
			self.__debug("Set resource "+varname+" to " + target)
			self.__currentResourceVariant.AddOperation(raptor_data.Set(varname,target))
		if varname == "TARGETPATH":
			varvalue=varvalue.replace('\\','/')
			self.__debug("Set resource "+varname+" to " + varvalue)
			self.__currentResourceVariant.AddOperation(raptor_data.Set(varname,varvalue))
		else:
			self.__debug("Set resource "+varname+" to " + varvalue)
			self.__currentResourceVariant.AddOperation(raptor_data.Set(varname,varvalue))
		return "OK"

	def doResourceAppend(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug("Append resource to "+toks[0]+" the values: " +str(toks[1]))
		varname = toks[0].upper()

		# we cannot use LANG as it interferes with the environment
		if varname == "LANG":
			varname = "LANGUAGES"

		for item in toks[1]:
			if varname == "LANGUAGES":
				item = item.lower()
			self.__currentResourceVariant.AddOperation(raptor_data.Append(varname,item))
		return "OK"

	def doResourceSetSwitch(self,s,loc,toks):
		self.__currentLineNumber += 1
		name = toks[0].upper()

		if name == "HEADER":
			self.__headerspecified = True

		elif name == "HEADERONLY":
			self.__headeronlyspecified = True

		else:
			value = "1"
			self.__debug( "Set resource switch " + name + " " + value)
			self.__currentResourceVariant.AddOperation(raptor_data.Set(name, value))

		return "OK"

	def doEndResource(self,s,loc,toks):
		self.__currentLineNumber += 1

		# Header name can change, depening if there was a TARGET defined or not, so it must be appended at the end
		if self.__headerspecified:
			self.__debug("Set resource switch HEADER " + self.__current_resource_header)
			self.__currentResourceVariant.AddOperation(raptor_data.Set("HEADER", self.__current_resource_header))

		if self.__headeronlyspecified:
			self.__debug("Set resource switch HEADERONLY " + self.__current_resource_header)
			self.__currentResourceVariant.AddOperation(raptor_data.Set("HEADER", self.__current_resource_header))
			self.__currentResourceVariant.AddOperation(raptor_data.Set("HEADERONLY", "True"))

		self.__debug("End RESOURCE")
		self.ResourceVariants.append(self.__currentResourceVariant)
		self.__currentResourceVariant = None
		self.__current_resource = ""
		return "OK"

	# Bitmap

	def doStartBitmap(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug("Start BITMAP "+toks[1])

		self.__currentBitmapVariant = raptor_data.Variant(name = toks[1].replace('.','_'))
		# Use BMTARGET and BMTARGET_lower because that prevents
		# confusion with the TARGET and TARGET_lower of our parent MMP
		# when setting the OUTPUTPATH.  This in turn allows us to
		# not get tripped up by multiple mbms being generated with
		# the same name to the same directory.
		self.__currentBitmapVariant.AddOperation(raptor_data.Set("BMTARGET", toks[1]))
		self.__currentBitmapVariant.AddOperation(raptor_data.Set("BMTARGET_lower", toks[1].lower()))
		self.__currentBitmapVariant.AddOperation(raptor_data.Set("SOURCE", ""))
		return "OK"

	def doBitmapAssignment(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug("Set bitmap "+toks[0]+" to " + str(toks[1]))
		name = toks[0].upper()
		value = "".join(toks[1])
		if name == "TARGETPATH":
			value = value.replace('\\','/')

		self.__currentBitmapVariant.AddOperation(raptor_data.Set(name,value))
		return "OK"

	def doBitmapSourcePathAssignment(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug("Previous bitmap sourcepath:" + self.__bitmapSourcepath)
		self.__bitmapSourcepath = raptor_utilities.resolveSymbianPath(self.__currentMmpFile, toks[1])
		self.__debug("New bitmap sourcepath: " + self.__bitmapSourcepath)

	def doBitmapSourceAssignment(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug( "Setting "+toks[0]+" to " + str(toks[1]))
		# The first "source" is the colour depth for all the others.
		# The depth format is b[,m] where b is the bitmap depth and m is
		# the mask depth.
		# Valid values for b are: 1 2 4 8 c4 c8 c12 c16 c24 c32 c32a (?)
		# Valid values for m are: 1 8 (any number?)
		#
		# If m is specified then the bitmaps are in pairs: b0 m0 b1 m1...
		# If m is not specified then there are no masks, just bitmaps: b0 b1...
		colordepth = toks[1][0].lower()
		if "," in colordepth:
			(bitmapdepth, maskdepth) = colordepth.split(",")
		else:
			bitmapdepth = colordepth
			maskdepth = 0

		sources=""
		mask = False
		for file in toks[1][1:]:
			path = generic_path.Join(self.__bitmapSourcepath, file)
			if sources:
				sources += " "
			if mask:
				sources += "DEPTH=" + maskdepth + " FILE=" + str(path)
			else:
				sources += "DEPTH=" + bitmapdepth + " FILE=" + str(path)
			if maskdepth:
				mask = not mask
		self.__debug("sources: " + sources)
		self.__currentBitmapVariant.AddOperation(raptor_data.Append("SOURCE", sources))
		return "OK"

	def doBitmapSetSwitch(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug( "Set bitmap switch "+toks[0]+" ON")
		self.__currentBitmapVariant.AddOperation(raptor_data.Set(toks[0].upper(), "1"))
		return "OK"

	def doEndBitmap(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__bitmapSourcepath = self.__sourcepath
		self.BitmapVariants.append(self.__currentBitmapVariant)
		self.__currentBitmapVariant = None
		self.__debug("End BITMAP")
		return "OK"

	# Stringtable

	def doStartStringTable(self,s,loc,toks):
		self.__currentLineNumber += 1
		self.__debug( "Start STRINGTABLE "+toks[1])

		specstringtable = generic_path.Join(self.__sourcepath, toks[1])
		uniqname = specstringtable.File().replace('.','_') # corrected, filename only
		source = str(specstringtable.FindCaseless())

		self.__debug("sourcepath: " + self.__sourcepath)
		self.__debug("stringtable: " + toks[1])
		self.__debug("adjusted stringtable source=" + source)

		self.__currentStringTableVariant = raptor_data.Variant(name = uniqname)
		self.__currentStringTableVariant.AddOperation(raptor_data.Set("SOURCE", source))
		self.__currentStringTableVariant.AddOperation(raptor_data.Set("EXPORTPATH", ""))
		self.__stringtableExported = False

		# The target name by default is the name of the stringtable without the extension
		# e.g. the stringtable "/fred/http.st" would have a default target name of "http"
		stringtable_withext = specstringtable.File()
		self.__stringtable = stringtable_withext.rsplit(".",1)[0].lower()
		self.__currentStringTableVariant.AddOperation(raptor_data.Set("TARGET", self.__stringtable))

		self.__stringtableHeaderonlyspecified = False

		return "OK"

	def doStringTableAssignment(self,s,loc,toks):
		""" Assign variables for stringtables """
		self.__currentLineNumber += 1
		varname = toks[0].upper() # the mmp keyword
		varvalue = "".join(toks[1])

		# Get rid of any .rsc extension because the build system
		# needs to have it stripped off to calculate other names
		# for other purposes and # we aren't going to make it
		# optional anyhow.
		if varname == "EXPORTPATH":
			finalvalue = raptor_utilities.resolveSymbianPath(self.__currentMmpFile, varvalue)
			self.__stringtableExported = True
		else:
			finalvalue = varvalue

		self.__debug("Set stringtable "+varname+" to " + finalvalue)
		self.__currentStringTableVariant.AddOperation(raptor_data.Set(varname,finalvalue))
		return "OK"

	def doStringTableSetSwitch(self,s,loc,toks):
		self.__currentLineNumber += 1
		if toks[0].upper()== "HEADERONLY":
			self.__stringtableHeaderonlyspecified = True
			self.__debug( "Set stringtable switch "+toks[0]+" ON")
			self.__currentStringTableVariant.AddOperation(raptor_data.Set(toks[0].upper(), "1"))
		return "OK"

	def doEndStringTable(self,s,loc,toks):
		self.__currentLineNumber += 1

		if not self.__stringtableExported:
			# There was no EXPORTPATH specified for this stringtable
			# so for our other code to be able to reference it we
			# must add the path of the generated location to the userinclude path

			ipath = "$(OUTPUTPATH)"
			self.BuildVariant.AddOperation(raptor_data.Append("USERINCLUDE",ipath))
			self.__userinclude += ' ' + ipath
			self.__debug("  USERINCLUDE = %s", self.__userinclude)
			self.__userinclude.strip()

		self.StringTableVariants.append(self.__currentStringTableVariant)
		self.__currentStringTableVariant = None
		self.__debug("End STRINGTABLE")
		if not self.__stringtableHeaderonlyspecified:
			# Have to assume that this is where the cpp file will be.  This has to be maintained
			# in sync with the FLM's idea of where this file should be.  We need a better way.
			# Interfaces also need outputs that allow other interfaces to refer to their outputs
			# without having to "know" where they will be.
			self.sources.append('$(OUTPUTPATH)/' + self.__stringtable + '.cpp')
		return "OK"


	def doUnknownStatement(self,s,loc,toks):
		self.__warn("%s (%d) : Unrecognised Keyword %s", self.__currentMmpFile, self.__currentLineNumber, str(toks))
		self.__currentLineNumber += 1
		return "OK"


	def doUnknownBlock(self,s,loc,toks):
		self.__warn("%s (%d) : Unrecognised Block %s", self.__currentMmpFile, self.__currentLineNumber, str(toks))
		self.__currentLineNumber += 1
		return "OK"

	def doDeprecated(self,s,loc,toks):
		self.__debug( "Deprecated command " + str(toks))
		self.__warn("%s (%d) : %s is deprecated .mmp file syntax", self.__currentMmpFile, self.__currentLineNumber, str(toks))
		self.__currentLineNumber += 1
		return "OK"

	def doNothing(self):
		self.__currentLineNumber += 1
		return "OK"

	def finalise(self, aBuildPlatform):
		"""Post-processing of data that is only applicable in the context of a fully
		processed .mmp file."""
		resolvedDefFile = ""

		if self.__TARGET:
			defaultRootName = self.__TARGET
			if self.__TARGETEXT!="":
				defaultRootName += "." + self.__TARGETEXT

			# NOTE: Changing default .def file name based on the LINKAS argument is actually
			# a defect, but this follows the behaviour of the current build system.
			if (self.__LINKAS):
				defaultRootName = self.__LINKAS

			resolvedDefFile = self.resolveDefFile(defaultRootName, aBuildPlatform)
			self.__debug("Resolved def file:  %s" % resolvedDefFile )
			# We need to store this resolved deffile location for the FREEZE target
			self.BuildVariant.AddOperation(raptor_data.Set("RESOLVED_DEFFILE", resolvedDefFile))

		# If a deffile is specified, an FLM will put in a dependency.
		# If a deffile is specified then raptor_meta will guess a name but:
		#	1) If the guess is wrong then the FLM will complain "no rule to make ..."
		#	2) In some cases, e.g. plugin, 1) is not desirable as the presence of a def file
		#		is not a necessity.  In these cases the FLM needs to know if DEFFILE
		#		is a guess or not so it can decide if a dependency should be added.

		# We check that the def file exists and that it is non-zero (incredible
		# that this should be needed).

		deffile_keyword="1"
		if self.deffile == "":
			# If the user didn't specify a deffile name then
			# we must be guessing
			# Let's check if our guess actually corresponds to a
			# real file.  If it does then that confims the guess.
			#  If there's no file then we still need to pass make the name
			# so it can complain about there not being a DEF file
			# for this particular target type and fail to build this target.

			deffile_keyword=""
			try:
				findpath = generic_path.Path(resolvedDefFile)
				foundfile = findpath.FindCaseless()

				if foundfile == None:
					raise IOError("file not found")

				self.__debug("Found DEFFILE  " + foundfile.GetLocalString())
				rfstat = os.stat(foundfile.GetLocalString())

				mode = rfstat[stat.ST_MODE]
				if mode != None and stat.S_ISREG(mode) and rfstat[stat.ST_SIZE] > 0:
					resolvedDefFile = str(foundfile)
				else:
					resolvedDefFile=""
			except Exception,e:
				self.__debug("While Searching for an IMPLIED  DEFFILE: %s: %s" % (str(e),str(findpath)) )
				resolvedDefFile=""
		else:
			if not resolvedDefFile == "":
				try:
					findpath = generic_path.Path(resolvedDefFile)
					resolvedDefFile = str(findpath.FindCaseless())
					if resolvedDefFile=="None":
						raise IOError("file not found")
				except Exception,e:
					self.__warn("While Searching for a SPECIFIED DEFFILE: %s: %s" % (str(e),str(findpath)) )
					resolvedDefFile=""
			else:
				self.__warn("DEFFILE KEYWORD used (%s) but def file not resolved" % (self.deffile) )


		self.BuildVariant.AddOperation(raptor_data.Set("DEFFILE", resolvedDefFile))
		self.__debug("Set DEFFILE to " + resolvedDefFile)
		self.BuildVariant.AddOperation(raptor_data.Set("DEFFILEKEYWORD", deffile_keyword))
		self.__debug("Set DEFFILEKEYWORD to '%s'",deffile_keyword)

		# If target type is "implib" it must have a def file
		self.checkImplibDefFile(resolvedDefFile)

		# if this target type has a default TARGETPATH other than "" for
		# resources then we need to add that default to all resources which
		# do not explicitly set the TARGETPATH themselves.
		tp = self.getDefaultResourceTargetPath(self.getTargetType())
		if tp:
			for i,var in enumerate(self.ResourceVariants):
				# does this resource specify its own TARGETPATH?
				needTP = True
				for op in var.ops:
					if isinstance(op, raptor_data.Set) \
					and op.name == "TARGETPATH":
						needTP = False
						break
				if needTP:
					self.ResourceVariants[i].AddOperation(raptor_data.Set("TARGETPATH", tp))

		# some core build configurations need to know about the resource builds, and
		# some resource building configurations need knowledge of the core build
		for resourceFile in self.__resourceFiles:
			self.BuildVariant.AddOperation(raptor_data.Append("RESOURCEFILES", resourceFile))

		for i,var in enumerate(self.ResourceVariants):
			self.ResourceVariants[i].AddOperation(raptor_data.Set("MAIN_TARGET_lower", self.__TARGET.lower()))
			self.ResourceVariants[i].AddOperation(raptor_data.Set("MAIN_REQUESTEDTARGETEXT", self.__TARGETEXT.lower()))

		# Create Capability variable in one SET operation (more efficient than multiple appends)
		
		self.BuildVariant.AddOperation(raptor_data.Set("CAPABILITY","".join(self.capabilities)))

		# Resolve combined capabilities as hex flags, for configurations that require them
		capabilityFlag1 = 0
		capabilityFlag2 = 0			# Always 0

		for capability in self.capabilities:
			invert = 0

			if capability.startswith('-'):
				invert = 0xffffffff
			capability = capability[1:]

			if MMPRaptorBackend.supportedCapabilities.has_key(capability):
				capabilityFlag1 = capabilityFlag1 ^ invert
				capabilityFlag1 = capabilityFlag1 | MMPRaptorBackend.supportedCapabilities[capability]
				capabilityFlag1 = capabilityFlag1 ^ invert

		capabilityFlag1 = "%08xu" % capabilityFlag1
		capabilityFlag2 = "%08xu" % capabilityFlag2

		self.BuildVariant.AddOperation(raptor_data.Set("CAPABILITYFLAG1", capabilityFlag1))
		self.__debug ("Set CAPABILITYFLAG1 to " + capabilityFlag1)
		self.BuildVariant.AddOperation(raptor_data.Set("CAPABILITYFLAG2", capabilityFlag2))
		self.__debug ("Set CAPABILITYFLAG2 to " + capabilityFlag2)

		# For non-Feature Variant builds, the location of the product include hrh file is
		# appended to the SYSTEMINCLUDE list
		if not aBuildPlatform['ISFEATUREVARIANT']:
			productIncludePath = str(aBuildPlatform['VARIANT_HRH'].Dir())
			self.BuildVariant.AddOperation(raptor_data.Append("SYSTEMINCLUDE",productIncludePath))
			self.__debug("Appending product include location %s to SYSTEMINCLUDE",productIncludePath)

		# Specifying both a PAGED* and its opposite UNPAGED* keyword in a .mmp file
		# will generate a warning and the last keyword specified will take effect.
		self.__pageConflict.reverse()
		if "PAGEDCODE" in self.__pageConflict and "UNPAGEDCODE" in self.__pageConflict:
			for x in self.__pageConflict:
				if x == "PAGEDCODE" or x == "UNPAGEDCODE":
					self.__Raptor.Warn("Both PAGEDCODE and UNPAGEDCODE are specified. The last one %s will take effect" % x)
					if x == "PAGEDCODE":
						self.resolveCompressionKeyword("BYTEPAIRCOMPRESSTARGET")
					break
		elif "PAGEDCODE" in self.__pageConflict:
			self.resolveCompressionKeyword("BYTEPAIRCOMPRESSTARGET")
				
		if "PAGEDDATA" in self.__pageConflict and "UNPAGEDDATA" in self.__pageConflict:
			for x in self.__pageConflict:
				if x == "PAGEDDATA" or x == "UNPAGEDDATA":
					self.__Raptor.Warn("Both PAGEDDATA and UNPAGEDDATA are specified. The last one %s will take effect" % x)
					if x == "PAGEDDATA":
						self.resolveCompressionKeyword("BYTEPAIRCOMPRESSTARGET")
					break
		elif "PAGEDDATA" in self.__pageConflict:
			self.resolveCompressionKeyword("BYTEPAIRCOMPRESSTARGET")

		# Set Debuggable
		self.BuildVariant.AddOperation(raptor_data.Set("DEBUGGABLE", self.__debuggable))

		if self.__explicitversion:
			self.BuildVariant.AddOperation(raptor_data.Append("UNIQUETARGETPATH","$(TARGET_lower)_$(VERSIONHEX)_$(REQUESTEDTARGETEXT)",'/'))
		else:
			self.BuildVariant.AddOperation(raptor_data.Append("UNIQUETARGETPATH","$(TARGET_lower)_$(REQUESTEDTARGETEXT)",'/'))

		# Put the list of sourcefiles in with one Set operation - saves memory
		# and performance over using multiple Append operations.
		self.BuildVariant.AddOperation(raptor_data.Set("SOURCE",
						   " ".join(self.sources)))

	def getTargetType(self):
		"""Target type in lower case - the standard format"""
		return self.__targettype.lower()

	def resolveCompressionKeyword(self, aCompressionKeyword):
		"""If a compression keyword is set more than once either explicitly
		or implicitly a warning is given and the last one takes effect 
		"""
		if self.__compressionKeyword and self.__compressionKeyword != aCompressionKeyword:
			self.__Raptor.Warn("%s keyword in %s overrides earlier use of %s" % \
						(aCompressionKeyword, self.__currentMmpFile, self.__compressionKeyword))
			self.BuildVariant.AddOperation(raptor_data.Set(self.__compressionKeyword, ""))
			self.__debug( "Set switch " + self.__compressionKeyword + " OFF")
		self.BuildVariant.AddOperation(raptor_data.Set(aCompressionKeyword,"1"))
		self.__debug( "Set switch " + aCompressionKeyword + " ON")
		self.__compressionKeyword = aCompressionKeyword

	def checkImplibDefFile(self, defFile):
		"""Project with target type implib must have DEFFILE defined 
		explicitly or implicitly, otherwise it is an error
		""" 
		if self.getTargetType() == 'implib' and defFile == '':
			self.__Raptor.Error("No DEF File for IMPLIB target type in " + \
							self.__currentMmpFile, bldinf=self.__bldInfFilename)

	def resolveDefFile(self, aTARGET, aBuildPlatform):
		"""Returns a fully resolved DEFFILE entry depending on .mmp file location and TARGET, DEFFILE and NOSTRICTDEF
		entries in the .mmp file itself (where appropriate).
		Is able to deal with target names that have multiple '.' characters e.g. messageintercept.esockdebug.dll
		"""

		resolvedDefFile = ""
		platform = aBuildPlatform['PLATFORM']

		# Not having a default .def file directory is a pretty strong indicator that
		# .def files aren't supported for the particular platform
		if PlatformDefaultDefFileDir.has_key(platform):
			(targetname,targetext) = os.path.splitext(aTARGET)
			(defname,defext) = os.path.splitext(self.deffile)
			if defext=="":
				defext = ".def"

			# NOTE: WORKAROUND
			if len(targetext) > 4:
				targetname += defext

			if not self.deffile:
				resolvedDefFile = targetname
			else:
				if re.search('[\\|\/]$', self.deffile):
					# If DEFFILE is *solely* a path, signified by ending in a slash, then TARGET is the
					# basis for the default .def filename but with the specified path as prefix
					resolvedDefFile = self.deffile + targetname

				else:
					resolvedDefFile = defname

				resolvedDefFile = resolvedDefFile.replace('~', PlatformDefaultDefFileDir[platform])

			if resolvedDefFile:
				if not self.nostrictdef:
					resolvedDefFile += 'u'

				if self.__explicitversion:
					resolvedDefFile += '{' + self.__versionhex + '}'

				resolvedDefFile += defext


				# If a DEFFILE statement doesn't specify a path in any shape or form, prepend the default .def file
				# location based on the platform being built
				if not re.search('[\\\/]+', self.deffile):
					resolvedDefFile = '../'+PlatformDefaultDefFileDir[platform]+'/'+resolvedDefFile

				resolvedDefFile = raptor_utilities.resolveSymbianPath(self.__defFileRoot, resolvedDefFile, 'DEFFILE', "", str(aBuildPlatform['EPOCROOT']))

		return resolvedDefFile


def CheckedGet(self, key, default = None):
	"""extract a value from an self and raise an exception if None.

	An optional default can be set to replace a None value.

	This function belongs in the Evaluator class logically. But
	Evaluator doesn't know how to raise a Metadata error. Since
	being able to raise a metadata error is the whole point of
	the method, it makes sense to adapt the Evaluator class from
	raptor_meta for the use of everything inside raptor_meta.

	... so it will be added to the Evaluator class.
	"""

	value = self.Get(key)
	if value == None:
		if default == None:
			raise MetaDataError("configuration " + self.buildUnit.name +
							    " has no variable " + key)
		else:
			return default
	return value

raptor_data.Evaluator.CheckedGet = CheckedGet 


class MetaReader(object):
	"""Entry point class for Symbian metadata processing.

	Provides a means of integrating "traditional" Symbian metadata processing
	with the new Raptor build system."""

	filesplit_re = re.compile(r"^(?P<name>.*)\.(?P<ext>[^\.]*)$")

	def __init__(self, aRaptor, configsToBuild):
		self.__Raptor = aRaptor
		self.BuildPlatforms = []
		self.ExportPlatforms = []

		# Get the version of CPP that we are using
		metadata = self.__Raptor.cache.FindNamedVariant("meta")
		evaluator = self.__Raptor.GetEvaluator(None, raptor_data.BuildUnit(metadata.name, [metadata]) )
		self.__gnucpp = evaluator.CheckedGet("GNUCPP")
		self.__defaultplatforms = evaluator.CheckedGet("DEFAULT_PLATFORMS")
		self.__basedefaultplatforms = evaluator.CheckedGet("BASE_DEFAULT_PLATFORMS")
		self.__baseuserdefaultplatforms = evaluator.CheckedGet("BASE_USER_DEFAULT_PLATFORMS")

		# Only read each variant.cfg once
		variantCfgs = {}

		# Group the list of configurations into "build platforms".
		# A build platform is a set of configurations which share
		# the same metadata. In other words, a set of configurations
		# for which the bld.inf and MMP files pre-process to exactly
		# the same text.
		platforms = {}

		# Exports are not "platform dependent" but they are configuration
		# dependent because different configs can have different EPOCROOT
		# and VARIANT_HRH values. Each "build platform" has one associated
		# "export platform" but several "build platforms" can be associated
		# with the same "export platform".
		exports = {}
		
		# We sort configurations by name here.  This is solely to deal with situations
		# where macros linked to builds end up being used in preprocessor conditionals
		# within bld.inf files that then wrap exports under PRJ_EXPORTS statements.
		# Having exports that are conditional on these macros isn't supported, but
		# as there are areas of the source base that make this assumption, and
		# fail if emulator macros are used instead of arm ones, we ensure that arm
		# configurations come first when multiple configurations are active, and so are
		# used first for determining exports.
		sortedConfigsToBuild = sorted(configsToBuild,key=lambda config: config.name)

		self.__Raptor.Debug("MetaReader: sortedConfigsToBuild:  %s", [b.name for b in sortedConfigsToBuild])
		for buildConfig in sortedConfigsToBuild:
			# get everything we need to know about the configuration
			evaluator = self.__Raptor.GetEvaluator(None, buildConfig)

			detail = {}
			detail['PLATFORM'] = evaluator.CheckedGet("TRADITIONAL_PLATFORM")
			epocroot = evaluator.CheckedGet("EPOCROOT")
			detail['EPOCROOT'] = generic_path.Path(epocroot)

			sbs_build_dir = evaluator.CheckedGet("SBS_BUILD_DIR")
			detail['SBS_BUILD_DIR'] = generic_path.Path(sbs_build_dir)
			flm_export_dir = evaluator.CheckedGet("FLM_EXPORT_DIR")
			detail['FLM_EXPORT_DIR'] = generic_path.Path(flm_export_dir)
			detail['CACHEID'] = flm_export_dir
			if raptor_utilities.getOSPlatform().startswith("win"):
				detail['PLATMACROS'] = evaluator.CheckedGet("PLATMACROS.WINDOWS")
			else:
				detail['PLATMACROS'] = evaluator.CheckedGet("PLATMACROS.LINUX")

			# Apply OS variant provided we are not ignoring this
			if not self.__Raptor.ignoreOsDetection:
				self.__Raptor.Debug("Automatic OS detection enabled.")
				self.ApplyOSVariant(buildConfig, epocroot)
			else: # We are ignore OS versions so no detection required, so no variant will be applied
				self.__Raptor.Debug("Automatic OS detection disabled.")

			# is this a feature variant config or an ordinary variant
			fv = evaluator.Get("FEATUREVARIANTNAME")
			if fv:
				variantHdr = evaluator.CheckedGet("VARIANT_HRH")
				variantHRH = generic_path.Path(variantHdr)
				detail['ISFEATUREVARIANT'] = True
			else:
				variantCfg = evaluator.CheckedGet("VARIANT_CFG")
				variantCfg = generic_path.Path(variantCfg)
				if not variantCfg in variantCfgs:
					# get VARIANT_HRH from the variant.cfg file
					varCfg = getVariantCfgDetail(detail['EPOCROOT'], variantCfg)
					variantCfgs[variantCfg] = varCfg['VARIANT_HRH']
					# we expect to always build ABIv2
					if not 'ENABLE_ABIV2_MODE' in varCfg:
						self.__Raptor.Warn("missing flag ENABLE_ABIV2_MODE in %s file. ABIV1 builds are not supported.",
										   str(variantCfg))
				variantHRH = variantCfgs[variantCfg]
				detail['ISFEATUREVARIANT'] = False

			detail['VARIANT_HRH'] = variantHRH
			self.__Raptor.Info("'%s' uses variant hrh file '%s'", buildConfig.name, variantHRH)
			detail['SYSTEMINCLUDE'] = evaluator.CheckedGet("SYSTEMINCLUDE")


			# find all the interface names we need
			ifaceTypes = evaluator.CheckedGet("INTERFACE_TYPES")
			interfaces = ifaceTypes.split()

			for iface in interfaces:
				detail[iface] = evaluator.CheckedGet("INTERFACE." + iface)

			# not test code unless positively specified
			detail['TESTCODE'] = evaluator.CheckedGet("TESTCODE", "")

			# make a key that identifies this platform uniquely
			# - used to tell us whether we have done the pre-processing
			# we need already using another platform with compatible values.

			key = str(detail['VARIANT_HRH']) \
			 	+ str(detail['EPOCROOT']) \
		    	+ detail['SYSTEMINCLUDE'] \
		    	+ detail['PLATFORM'] \
		    	+ detail['PLATMACROS']

		    # Keep a short version of the key for use in filenames.
			uniq = hashlib.md5()
			uniq.update(key)

			detail['key'] = key
			detail['key_md5'] = "p_" + uniq.hexdigest()
			del uniq

			# compare this configuration to the ones we have already seen

			# Is this an unseen export platform?
			# concatenate all the values we care about in a fixed order
			# and use that as a signature for the exports.
			items = ['EPOCROOT', 'VARIANT_HRH', 'SYSTEMINCLUDE', 'TESTCODE', 'export']
			export = ""
			for i in  items:
				if i in detail:
					export += i + str(detail[i])

			if export in exports:
				# add this configuration to an existing export platform
				index = exports[export]
				self.ExportPlatforms[index]['configs'].append(buildConfig)
			else:
				# create a new export platform with this configuration
				exports[export] = len(self.ExportPlatforms)
				exp = copy.copy(detail)
				exp['PLATFORM'] = 'EXPORT'
				exp['configs']  = [buildConfig]
				self.ExportPlatforms.append(exp)

			# Is this an unseen build platform?
			# concatenate all the values we care about in a fixed order
			# and use that as a signature for the platform.
			items = ['PLATFORM', 'PLATMACROS', 'EPOCROOT', 'VARIANT_HRH', 'SYSTEMINCLUDE', 'TESTCODE']

			items.extend(interfaces)
			platform = ""
			for i in  items:
				if i in detail:
					platform += i + str(detail[i])

			if platform in platforms:
				# add this configuration to an existing build platform
				index = platforms[platform]
				self.BuildPlatforms[index]['configs'].append(buildConfig)
			else:
				# create a new build platform with this configuration
				platforms[platform] = len(self.BuildPlatforms)
				detail['configs'] = [buildConfig]
				self.BuildPlatforms.append(detail)

		# one platform is picked as the "default" for extracting things
		# that are supposedly platform independent (e.g. PRJ_PLATFORMS)
		self.defaultPlatform = self.ExportPlatforms[0]


	def ReadBldInfFiles(self, aComponentList, doexport, dobuild = True):
		"""Take a list of bld.inf files and return a list of build specs.

		The returned specification nodes will be suitable for all the build
		configurations under consideration (using Filter nodes where required).
		"""

		# we need a Filter node per export platform
		exportNodes = []
		for i,ep in enumerate(self.ExportPlatforms):
			filter = raptor_data.Filter(name = "export_" + str(i))

			# what configurations is this node active for?
			for config in ep['configs']:
				filter.AddConfigCondition(config.name)

			exportNodes.append(filter)

		# we need a Filter node per build platform
		platformNodes = []
		for i,bp in enumerate(self.BuildPlatforms):
			filter = raptor_data.Filter(name = "build_" + str(i))

			# what configurations is this node active for?
			for config in bp['configs']:
				filter.AddConfigCondition(config.name)

			# platform-wide data
			platformVar = raptor_data.Variant()
			platformVar.AddOperation(raptor_data.Set("PRODUCT_INCLUDE",
													 str(bp['VARIANT_HRH'])))

			filter.AddVariant(platformVar)
			platformNodes.append(filter)

		# check that each bld.inf exists and add a Specification node for it
		# to the nodes of the export and build platforms that it supports.
		for c in aComponentList:
			if c.bldinf_filename.isFile():
				self.__Raptor.Info("Processing %s", str(c.bldinf_filename))
				try:
					self.AddComponentNodes(c, exportNodes, platformNodes)

				except MetaDataError, e:
					self.__Raptor.Error(e.Text, bldinf=str(c.bldinf_filename))
					if not self.__Raptor.keepGoing:
						return []
			else:
				self.__Raptor.Error("build info file does not exist", bldinf=str(c.bldinf_filename))
				if not self.__Raptor.keepGoing:
					return []

		# now we have the top-level structure in place...
		#
		# <filter exports 1>
		#		<spec bld.inf 1 />
		#		<spec bld.inf 2 />
		#		<spec bld.inf N /> </filter>
		# <filter build 1>
		#		<spec bld.inf 1 />
		#		<spec bld.inf 2 />
		#		<spec bld.inf N /> </filter>
		# <filter build 2>
		#		<spec bld.inf 1 />
		#		<spec bld.inf 2 />
		#		<spec bld.inf N /> </filter>
		# <filter build 3>
		#		<spec bld.inf 1 />
		#		<spec bld.inf 2 />
		#		<spec bld.inf N /> </filter>
		#
		# assuming that every bld.inf builds for every platform and all
		# exports go to the same place. clearly, it is more likely that
		# some filters have less than N child nodes. in bigger builds there
		# will also be more than one export platform.

		# we now need to process the EXPORTS for all the bld.inf nodes
		# before we can do anything else (because raptor itself must do
		# some exports before the MMP files that include them can be
		# processed).
		if doexport:
			for i,p in enumerate(exportNodes):
				exportPlatform = self.ExportPlatforms[i]
				for s in p.GetChildSpecs():
					try:
						self.ProcessExports(s, exportPlatform)

					except MetaDataError, e:
						self.__Raptor.Error("%s",e.Text)
						if not self.__Raptor.keepGoing:
							return []
		else:
			self.__Raptor.Info("Not Processing Exports (--noexport enabled)")

		# this is a switch to return the function at this point if export
		# only option is specified in the run
		if dobuild is not True:
			self.__Raptor.Info("Processing Exports only")
			return[]

		# after exports are done we can look to see if there are any
		# new Interfaces which can be used for EXTENSIONS. Make sure
		# that we only load each cache once as some export platforms
		# may share a directory.
		doneID = {}
		for ep in self.ExportPlatforms:
			flmDir = ep["FLM_EXPORT_DIR"]
			cid = ep["CACHEID"]
			if flmDir.isDir() and not cid in doneID:
				self.__Raptor.cache.Load(flmDir, cid)
			doneID[cid] = True

		# finally we can process all the other parts of the bld.inf nodes.
		# Keep a list of the projects we were asked to build so that we can
		# tell at the end if there were any we didn't know about.
		self.projectList = list(self.__Raptor.projects)
		for i,p in enumerate(platformNodes):
			buildPlatform = self.BuildPlatforms[i]
			for s in p.GetChildSpecs():
				try:
					self.ProcessTEMs(s, buildPlatform)
					self.ProcessMMPs(s, buildPlatform)

				except MetaDataError, e:
					self.__Raptor.Error(e.Text)
					if not self.__Raptor.keepGoing:
						return []

		for badProj in self.projectList:
			self.__Raptor.Warn("Can't find project '%s' in any build info file", badProj)

		# everything is specified
		return exportNodes + platformNodes

	def ModuleName(self,aBldInfPath):
		"""Calculate the name of the ROM/emulator batch files that run the tests"""

		def LeftPortionOf(pth,sep):
			""" Internal function to return portion of str that is to the left of sep. 
			The split is case-insensitive."""
			length = len((pth.lower().split(sep.lower()))[0])
			return pth[0:length]
			
		modulePath = LeftPortionOf(LeftPortionOf(os.path.dirname(aBldInfPath), "group"), "ongoing")
		moduleName = os.path.basename(modulePath.strip("/"))
		
		# Ensure that ModuleName does not return blank, if the above calculation determines
		# that moduleName is blank
		if moduleName == "" or moduleName.endswith(":"):
			moduleName = "module"
		return moduleName


	def AddComponentNodes(self, component, exportNodes, platformNodes):	
		"""Add Specification nodes for a bld.inf to the appropriate platforms."""
		bldInfFile = BldInfFile(component.bldinf_filename, self.__gnucpp, component.depfiles, self.__Raptor)
		component.bldinf = bldInfFile 

		specName = getSpecName(component.bldinf_filename, fullPath=True)

		# exports are independent of build platform
		for i,ep in enumerate(self.ExportPlatforms):
			specNode = raptor_data.Specification(name = specName)

			# keep the BldInfFile object for later
			specNode.component = component

			# add some basic data in a component-wide variant
			var = raptor_data.Variant(name='component-wide')
			var.AddOperation(raptor_data.Set("COMPONENT_META", str(component.bldinf_filename)))
			var.AddOperation(raptor_data.Set("COMPONENT_NAME", component.componentname))
			var.AddOperation(raptor_data.Set("COMPONENT_LAYER", component.layername))
			specNode.AddVariant(var)

			# add this bld.inf Specification to the export platform
			exportNodes[i].AddChild(specNode)
			component.exportspecs.append(specNode)

		# get the relevant build platforms
		listedPlatforms = bldInfFile.getBuildPlatforms(self.defaultPlatform)
		platforms = getBuildableBldInfBuildPlatforms(listedPlatforms,
								self.__defaultplatforms,
								self.__basedefaultplatforms,
								self.__baseuserdefaultplatforms)


		outputDir = BldInfFile.outputPathFragment(component.bldinf_filename)

		# Calculate "module name"
		modulename = self.ModuleName(str(component.bldinf_filename))

		for i,bp in enumerate(self.BuildPlatforms):
			plat = bp['PLATFORM']
			if bp['PLATFORM'] in platforms:
				specNode = raptor_data.Specification(name = specName)

				# remember what component this spec node comes from for later
				specNode.component = component

				# add some basic data in a component-wide variant
				var = raptor_data.Variant(name='component-wide-settings-' + plat)
				var.AddOperation(raptor_data.Set("COMPONENT_META",str(component.bldinf_filename)))
				var.AddOperation(raptor_data.Set("COMPONENT_NAME", component.componentname))
				var.AddOperation(raptor_data.Set("COMPONENT_LAYER", component.layername))
				var.AddOperation(raptor_data.Set("MODULE", modulename))
				var.AddOperation(raptor_data.Append("OUTPUTPATHOFFSET", outputDir, '/'))
				var.AddOperation(raptor_data.Append("OUTPUTPATH", outputDir, '/'))
				var.AddOperation(raptor_data.Append("BLDINF_OUTPUTPATH",outputDir, '/'))

				var.AddOperation(raptor_data.Set("TEST_OPTION", component.bldinf.getRomTestType(bp)))
				specNode.AddVariant(var)

				# add this bld.inf Specification to the build platform
				platformNodes[i].AddChild(specNode)
				# also attach it into the component
				component.specs.append(specNode)

	def ProcessExports(self, componentNode, exportPlatform):
		"""Do the exports for a given platform and skeleton bld.inf node.

		This will actually perform exports as certain types of files (.mmh)
		are required to be in place before the rest of the bld.inf node
		(and parts of other bld.inf nodes) can be processed.

		[some MMP files #include exported .mmh files]
		"""
		if exportPlatform["TESTCODE"]:
			exports = componentNode.component.bldinf.getTestExports(exportPlatform)
		else:
			exports = componentNode.component.bldinf.getExports(exportPlatform)

		self.__Raptor.Debug("%i exports for %s",
							len(exports), str(componentNode.component.bldinf.filename))
		if exports:

			# each export is either a 'copy' or 'unzip'
			# maybe we should trap multiple exports to the same location here?
			epocroot = str(exportPlatform["EPOCROOT"])
			bldinf_filename = str(componentNode.component.bldinf.filename)
			exportwhatlog="<whatlog bldinf='%s' mmp='' config=''>\n" % bldinf_filename
			for export in exports:
				expSrc = export.getSource()
				expDstList = export.getDestination() # Might not be a list in all circumstances

				# make it a list if it isn't
				if not isinstance(expDstList, list):
					expDstList = [expDstList]

				fromFile = generic_path.Path(expSrc.replace("$(EPOCROOT)", epocroot))

				# For each destination in the destination list, add an export target, perform it if required.
				# This ensures that make knows the dependency situation but that the export is made
				# before any other part of the metadata requires it.  It also helps with the build
				# from clean situation where we can't use order only prerequisites.
				for expDst in expDstList:
					toFile = generic_path.Path(expDst.replace("$(EPOCROOT)", epocroot))
					try:
						if export.getAction() == "copy":
							# export the file
							exportwhatlog += self.CopyExport(fromFile, toFile, bldinf_filename)
						else:
							members = self.UnzipExport(fromFile, toFile,
									str(exportPlatform['SBS_BUILD_DIR']),
									bldinf_filename)
							
							exportwhatlog += ("<archive zipfile='" + str(fromFile) + "'>\n")
							if members != None:
								exportwhatlog += members
							exportwhatlog += "</archive>\n"
					except MetaDataError, e:
						if self.__Raptor.keepGoing:
							self.__Raptor.Error("%s",e.Text, bldinf=bldinf_filename)
						else:
							raise e
			exportwhatlog+="</whatlog>\n"
			self.__Raptor.PrintXML("%s",exportwhatlog)

	def CopyExport(self, _source, _destination, bldInfFile):
		"""Copy the source file to the destination file (create a directory
		   to copy into if it does not exist). Don't copy if the destination
		   file exists and has an equal or newer modification time."""
		source = generic_path.Path(str(_source).replace('%20',' '))
		destination = generic_path.Path(str(_destination).replace('%20',' '))
		dest_str = str(destination)
		source_str = str(source)

		exportwhatlog="<export destination='" + dest_str + "' source='" + \
				source_str + "'/>\n"

		try:


			destDir = destination.Dir()
			if not destDir.isDir():
				os.makedirs(str(destDir))
				shutil.copyfile(source_str, dest_str)
				return exportwhatlog

			sourceMTime = 0
			destMTime = 0
			sourceStat = 0
			try:
				sourceStat = os.stat(source_str)
				sourceMTime = sourceStat[stat.ST_MTIME]
				destMTime = os.stat(dest_str)[stat.ST_MTIME]
			except OSError, e:
				if sourceMTime == 0:
					message = "Source of export does not exist:  " + str(source)
					if not self.__Raptor.keepGoing:
						raise MetaDataError(message)
					else:
						self.__Raptor.Error(message, bldinf=bldInfFile)

			if destMTime == 0 or destMTime < sourceMTime:
				if os.path.exists(dest_str):
					os.chmod(dest_str,stat.S_IREAD | stat.S_IWRITE)
				shutil.copyfile(source_str, dest_str)

				# Ensure that the destination file remains executable if the source was also:
				os.chmod(dest_str,sourceStat[stat.ST_MODE] | stat.S_IREAD | stat.S_IWRITE | stat.S_IWGRP ) 
				self.__Raptor.Info("Copied %s to %s", source_str, dest_str)
			else:
				self.__Raptor.Info("Up-to-date: %s", dest_str)


		except Exception,e:
			message = "Could not export " + source_str + " to " + dest_str + " : " + str(e)
			if not self.__Raptor.keepGoing:
				raise MetaDataError(message)
			else:
				self.__Raptor.Error(message, bldinf=bldInfFile)

		return exportwhatlog


	def UnzipExport(self, _source, _destination, _sbs_build_dir, bldinf_filename):
		"""Unzip the source zipfile into the destination directory
		   but only if the markerfile does not already exist there
		   or it does exist but is older than the zipfile.
		   the markerfile is comprised of the name of the zipfile
		   with the ".zip" removed and ".unzipped" added.
		"""

		# Insert spaces into file if they are there
		source = str(_source).replace('%20',' ')
		destination = str(_destination).replace('%20',' ')
		sanitisedSource = raptor_utilities.sanitise(source)
		sanitisedDestination = raptor_utilities.sanitise(destination)

		destination = str(_destination).replace('%20',' ')
		exportwhatlog = ""


		try:
			if not _destination.isDir():
				os.makedirs(destination)

			# Form the directory to contain the unzipped marker files, and make the directory if require.
			markerfiledir = generic_path.Path(_sbs_build_dir)
			if not markerfiledir.isDir():
				os.makedirs(str(markerfiledir))

			# Form the marker file name and convert to Python string
			markerfilename = str(generic_path.Join(markerfiledir, sanitisedSource + sanitisedDestination + ".unzipped"))

			# Don't unzip if the marker file is already there or more uptodate
			sourceMTime = 0
			destMTime = 0
			try:
				sourceMTime = os.stat(source)[stat.ST_MTIME]
				destMTime = os.stat(markerfilename)[stat.ST_MTIME]
			except OSError, e:
				if sourceMTime == 0:
					raise MetaDataError("Source zip for export does not exist:  " + source)
			if destMTime != 0 and destMTime >= sourceMTime:
				# This file has already been unzipped. Print members then return
				exportzip = zipfile.ZipFile(source, 'r')
				files = exportzip.namelist()
				files.sort()

				for file in files:
					if not file.endswith('/'):
						expfilename = str(generic_path.Join(destination, file))
						exportwhatlog += "<member>" + escape(expfilename) + "</member>\n"

				self.__Raptor.PrintXML("<clean bldinf='" + bldinf_filename + "' mmp='' config=''>\n")
				self.__Raptor.PrintXML("<zipmarker>" + markerfilename + "</zipmarker>\n")
				self.__Raptor.PrintXML("</clean>\n")

				return exportwhatlog

			exportzip = zipfile.ZipFile(source, 'r')
			files = exportzip.namelist()
			files.sort()
			filecount = 0
			for file in files:
				expfilename = str(generic_path.Join(destination, file))
				if file.endswith('/'):
					try:
						os.makedirs(expfilename)
					except OSError, e:
						pass # errors to do with "already exists" are not interesting.
				else:
					try:
						os.makedirs(os.path.split(expfilename)[0])
					except OSError, e:
						pass # errors to do with "already exists" are not interesting.

					try:
						if os.path.exists(expfilename):
							os.chmod(expfilename,stat.S_IREAD | stat.S_IWRITE)
						expfile = open(expfilename, 'wb')
						expfile.write(exportzip.read(file))
						expfile.close()
						
						# Resurrect any file execution permissions present in the archived version
						if (exportzip.getinfo(file).external_attr >> 16L) & 0100:
							os.chmod(expfilename, stat.S_IMODE(os.stat(expfilename).st_mode) | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)						
						
						# Each file keeps its modified time the same as what it was before unzipping
						accesstime = time.time()
						datetime = exportzip.getinfo(file).date_time
						timeTuple=(int(datetime[0]), int(datetime[1]), int(datetime[2]), int(datetime[3]), \
									int(datetime[4]), int(datetime[5]), int(0), int(0), int(0))
						modifiedtime = time.mktime(timeTuple)
						os.utime(expfilename,(accesstime, modifiedtime))

						filecount += 1
						exportwhatlog+="<member>" + escape(expfilename) + "</member>\n"
					except IOError, e:
						message = "Could not unzip %s to %s: file %s: %s" %(source, destination, expfilename, str(e))
						if not self.__Raptor.keepGoing:
							raise MetaDataError(message)
						else:
							self.__Raptor.Error(message, bldinf=bldinf_filename)

			markerfile = open(markerfilename, 'wb+')
			markerfile.close()
			self.__Raptor.PrintXML("<clean bldinf='" + bldinf_filename + "' mmp='' config=''>\n")
			self.__Raptor.PrintXML("<zipmarker>" + markerfilename +	"</zipmarker>\n")
			self.__Raptor.PrintXML("</clean>\n")

		except IOError, e:
			self.__Raptor.Warn("Problem while unzipping export %s to %s: %s",source,destination,str(e))

		self.__Raptor.Info("Unzipped %d files from %s to %s", filecount, source, destination)
		return exportwhatlog

	def ProcessTEMs(self, componentNode, buildPlatform):
		"""Add Template Extension Makefile nodes for a given platform
		   to a skeleton bld.inf node.

		This happens after exports have been handled.
		"""
		if buildPlatform["ISFEATUREVARIANT"]:
			return	# feature variation does not run extensions at all
		
		if buildPlatform["TESTCODE"]:
			extensions = componentNode.component.bldinf.getTestExtensions(buildPlatform)
		else:
			extensions = componentNode.component.bldinf.getExtensions(buildPlatform)

		self.__Raptor.Debug("%i template extension makefiles for %s",
							len(extensions), str(componentNode.component.bldinf.filename))

		for i,extension in enumerate(extensions):
			if self.__Raptor.projects:
				if not extension.nametag in self.__Raptor.projects:
					self.__Raptor.Debug("Skipping %s", extension.getMakefile())
					continue
				elif extension.nametag in self.projectList:
					self.projectList.remove(extension.nametag)

			extensionSpec = raptor_data.Specification("extension" + str(i))

			interface = buildPlatform["extension"]
			customInterface = False

			# is there an FLM replacement for this extension?
			if extension.interface:
				try:
					interface = self.__Raptor.cache.FindNamedInterface(extension.interface, buildPlatform["CACHEID"])
					customInterface = True
				except KeyError:
					# no, there isn't an FLM
					pass

			extensionSpec.SetInterface(interface)

			var = raptor_data.Variant()
			var.AddOperation(raptor_data.Set("EPOCBLD", "$(OUTPUTPATH)"))
			var.AddOperation(raptor_data.Set("PLATFORM", buildPlatform["PLATFORM"]))
			var.AddOperation(raptor_data.Set("PLATFORM_PATH", buildPlatform["PLATFORM"].lower()))
			var.AddOperation(raptor_data.Set("CFG", "$(VARIANTTYPE)"))
			var.AddOperation(raptor_data.Set("CFG_PATH", "$(VARIANTTYPE)"))
			var.AddOperation(raptor_data.Set("GENERATEDCPP", "$(OUTPUTPATH)"))
			var.AddOperation(raptor_data.Set("TEMPLATE_EXTENSION_MAKEFILE", extension.getMakefile()))
			var.AddOperation(raptor_data.Set("TEMCOUNT", str(i)))

			# Extension inputs are added to the build spec.
			# '$'s are escaped so that they are not expanded by Raptor or
			# by Make in the call to the FLM
			# The Extension makefiles are supposed to expand them themselves
			# Path separators need not be parameterised anymore
			# as bash is the standard shell
			standardVariables = extension.getStandardVariables()
			for standardVariable in standardVariables.keys():
				self.__Raptor.Debug("Set %s=%s", standardVariable, standardVariables[standardVariable])
				value = standardVariables[standardVariable].replace('$(', '$$$$(')
				value = value.replace('$/', '/').replace('$;', ':')
				var.AddOperation(raptor_data.Set(standardVariable, value))

			# . . . as with the standard variables but the names and number
			# of options are not known in advance so we add them to
			# a "structure" that is self-describing
			var.AddOperation(raptor_data.Set("O._MEMBERS", ""))
			options = extension.getOptions()
			for option in options:
				self.__Raptor.Debug("Set %s=%s", option, options[option])
				value = options[option].replace('$(EPOCROOT)', '$(EPOCROOT)/')
				value = value.replace('$(', '$$$$(')
				value = value.replace('$/', '/').replace('$;', ':')
				value = value.replace('$/', '/').replace('$;', ':')

				if customInterface:
					var.AddOperation(raptor_data.Set(option, value))
				else:
					var.AddOperation(raptor_data.Append("O._MEMBERS", option))
					var.AddOperation(raptor_data.Set("O." + option, value))

			extensionSpec.AddVariant(var)
			componentNode.AddChild(extensionSpec)


	def ProcessMMPs(self, componentNode, buildPlatform):
		"""Add project nodes for a given platform to a skeleton bld.inf node.

		This happens after exports have been handled.
		"""
		gnuList = []
		makefileList = []


		component = componentNode.component


		if buildPlatform["TESTCODE"]:
			MMPList = component.bldinf.getTestMMPList(buildPlatform)
		else:
			MMPList = component.bldinf.getMMPList(buildPlatform)

		bldInfFile = component.bldinf.filename

		for mmpFileEntry in MMPList['mmpFileList']:
			component.AddMMP(mmpFileEntry.filename) # Tell the component another mmp is specified (for this platform)

			projectname = mmpFileEntry.filename.File().lower()

			if self.__Raptor.projects:
				if not projectname in self.__Raptor.projects:
					self.__Raptor.Debug("Skipping %s", str(mmpFileEntry.filename))
					continue
				elif projectname in self.projectList:
					self.projectList.remove(projectname)

			foundmmpfile = (mmpFileEntry.filename).FindCaseless()

			if foundmmpfile == None:
				self.__Raptor.Error("Can't find mmp file '%s'", str(mmpFileEntry.filename), bldinf=str(bldInfFile))
				continue

			mmpFile = MMPFile(foundmmpfile,
								   self.__gnucpp,
								   component.bldinf,
								   component.depfiles,
								   log = self.__Raptor)

			mmpFilename = mmpFile.filename

			self.__Raptor.Info("Processing %s for platform %s",
							   str(mmpFilename),
							   " + ".join([x.name for x in buildPlatform["configs"]]))

			# Run the Parser
			# The backend supplies the actions
			content = mmpFile.getContent(buildPlatform)
			backend = MMPRaptorBackend(self.__Raptor, str(mmpFilename), str(bldInfFile))
			parser  = MMPParser(backend)
			parseresult = None
			try:
				parseresult = parser.mmp.parseString(content)
			except ParseException,e:
				self.__Raptor.Debug(e) # basically ignore parse exceptions

			if (not parseresult) or (parseresult[0] != 'MMP'):
				self.__Raptor.Error("The MMP Parser didn't recognise the mmp file '%s'",
					                str(mmpFileEntry.filename), 
					                bldinf=str(bldInfFile))
				self.__Raptor.Debug(content)
				self.__Raptor.Debug("The parse result was %s", parseresult)
			else:
				backend.finalise(buildPlatform)

			# feature variation only processes FEATUREVARIANT binaries
			if buildPlatform["ISFEATUREVARIANT"] and not backend.featureVariant:
				continue
			
			# now build the specification tree
			mmpSpec = raptor_data.Specification(generic_path.Path(getSpecName(mmpFilename)))
			var = backend.BuildVariant

			var.AddOperation(raptor_data.Set("PROJECT_META", str(mmpFilename)))

			# If it is a TESTMMPFILE section, the FLM needs to know about it
			if buildPlatform["TESTCODE"] and (mmpFileEntry.testoption in
					["manual", "auto"]):

				var.AddOperation(raptor_data.Set("TESTPATH",
						mmpFileEntry.testoption.lower() + ".bat"))

			# The output path for objects, stringtables and bitmaps specified by
			# this MMP.  Adding in the requested target extension prevents build
			# "fouling" in cases where there are several mmp targets which only differ
			# by the requested extension. e.g. elocl.01 and elocl.18
			var.AddOperation(raptor_data.Append("OUTPUTPATH","$(UNIQUETARGETPATH)",'/'))

			# If the bld.inf entry for this MMP had the BUILD_AS_ARM option then
			# tell the FLM.
			if mmpFileEntry.armoption:
				var.AddOperation(raptor_data.Set("ALWAYS_BUILD_AS_ARM","1"))

			# what interface builds this node?
			try:
				interfaceName = buildPlatform[backend.getTargetType()]
				mmpSpec.SetInterface(interfaceName)
			except KeyError:
				self.__Raptor.Error("Unsupported target type '%s' in %s",
								    backend.getTargetType(),
								    str(mmpFileEntry.filename),
								    bldinf=str(bldInfFile))
				continue

			# Although not part of the MMP, some MMP-based build specs additionally require knowledge of their
			# container bld.inf exported headers
			for export in componentNode.component.bldinf.getExports(buildPlatform):
				destination = export.getDestination()
				if isinstance(destination, list):
					exportfile = str(destination[0])
				else:
					exportfile = str(destination)

				if re.search('\.h',exportfile,re.IGNORECASE):
					var.AddOperation(raptor_data.Append("EXPORTHEADERS", str(exportfile)))

			# now we have something worth adding to the component
			mmpSpec.AddVariant(var)
			componentNode.AddChild(mmpSpec)
			
			# if there are APPLY variants then add them to the mmpSpec too
			for applyVar in backend.ApplyVariants:
				try:
					mmpSpec.AddVariant(self.__Raptor.cache.FindNamedVariant(applyVar))
				except KeyError:
					self.__Raptor.Error("APPLY unknown variant '%s' in %s",
								        applyVar,
								        str(mmpFileEntry.filename),
								        bldinf=str(bldInfFile))

			# resources, stringtables and bitmaps are sub-nodes of this project
			# (do not add these for feature variant builds)
			
			if not buildPlatform["ISFEATUREVARIANT"]:
				# Buildspec for Resource files
				for i,rvar in enumerate(backend.ResourceVariants):
					resourceSpec = raptor_data.Specification('resource' + str(i))
					resourceSpec.SetInterface(buildPlatform['resource'])
					resourceSpec.AddVariant(rvar)
					mmpSpec.AddChild(resourceSpec)

				# Buildspec for String Tables
				for i,stvar in enumerate(backend.StringTableVariants):
					stringTableSpec = raptor_data.Specification('stringtable' + str(i))
					stringTableSpec.SetInterface(buildPlatform['stringtable'])
					stringTableSpec.AddVariant(stvar)
					mmpSpec.AddChild(stringTableSpec)

				# Buildspec for Bitmaps
				for i,bvar in enumerate(backend.BitmapVariants):
					bitmapSpec = raptor_data.Specification('bitmap' + str(i))
					bitmapSpec.SetInterface(buildPlatform['bitmap'])
					bitmapSpec.AddVariant(bvar)
					mmpSpec.AddChild(bitmapSpec)

		# feature variation does not run extensions at all
		# so return without considering .*MAKEFILE sections
		if buildPlatform["ISFEATUREVARIANT"]:
			return
			
		# Build spec for gnumakefile
		for g in MMPList['gnuList']:
			projectname = g.getMakefileName().lower()

			if self.__Raptor.projects:
				if not projectname in self.__Raptor.projects:
					self.__Raptor.Debug("Skipping %s", str(g.getMakefileName()))
					continue
				elif projectname in self.projectList:
					self.projectList.remove(projectname)

			self.__Raptor.Debug("%i gnumakefile extension makefiles for %s",
						len(gnuList), str(componentNode.component.bldinf.filename))
			var = raptor_data.Variant()
			gnuSpec = raptor_data.Specification("gnumakefile " + str(g.getMakefileName()))
			interface = buildPlatform["ext_makefile"]
			gnuSpec.SetInterface(interface)
			gnumakefilePath = raptor_utilities.resolveSymbianPath(str(bldInfFile), g.getMakefileName())
			var.AddOperation(raptor_data.Set("EPOCBLD", "$(OUTPUTPATH)"))
			var.AddOperation(raptor_data.Set("PLATFORM", buildPlatform["PLATFORM"]))
			var.AddOperation(raptor_data.Set("EXTMAKEFILENAME", g.getMakefileName()))
			var.AddOperation(raptor_data.Set("DIRECTORY",g.getMakeDirectory()))
			var.AddOperation(raptor_data.Set("CFG","$(VARIANTTYPE)"))
			standardVariables = g.getStandardVariables()
			for standardVariable in standardVariables.keys():
				self.__Raptor.Debug("Set %s=%s", standardVariable, standardVariables[standardVariable])
				value = standardVariables[standardVariable].replace('$(', '$$$$(')
				value = value.replace('$/', '/').replace('$;', ':')
				var.AddOperation(raptor_data.Set(standardVariable, value))
			gnuSpec.AddVariant(var)
			componentNode.AddChild(gnuSpec)

		# Build spec for makefile
		for m in MMPList['makefileList']:
			projectname = m.getMakefileName().lower()

			if self.__Raptor.projects:
				if not projectname in self.__Raptor.projects:
					self.__Raptor.Debug("Skipping %s", str(m.getMakefileName()))
					continue
				elif projectname in self.projectList:
					projectList.remove(projectname)

			self.__Raptor.Debug("%i makefile extension makefiles for %s",
						len(makefileList), str(componentNode.component.bldinf.filename))
			var = raptor_data.Variant()
			gnuSpec = raptor_data.Specification("makefile " + str(m.getMakefileName()))
			interface = buildPlatform["ext_makefile"]
			gnuSpec.SetInterface(interface)
			gnumakefilePath = raptor_utilities.resolveSymbianPath(str(bldInfFile), m.getMakefileName())
			var.AddOperation(raptor_data.Set("EPOCBLD", "$(OUTPUTPATH)"))
			var.AddOperation(raptor_data.Set("PLATFORM", buildPlatform["PLATFORM"]))
			var.AddOperation(raptor_data.Set("EXTMAKEFILENAME", m.getMakefileName()))
			var.AddOperation(raptor_data.Set("DIRECTORY",m.getMakeDirectory()))
			var.AddOperation(raptor_data.Set("CFG","$(VARIANTTYPE)"))
			var.AddOperation(raptor_data.Set("USENMAKE","1"))
			standardVariables = m.getStandardVariables()
			for standardVariable in standardVariables.keys():
				self.__Raptor.Debug("Set %s=%s", standardVariable, standardVariables[standardVariable])
				value = standardVariables[standardVariable].replace('$(', '$$$$(')
				value = value.replace('$/', '/').replace('$;', ':')
				var.AddOperation(raptor_data.Set(standardVariable, value))
			gnuSpec.AddVariant(var)
			componentNode.AddChild(gnuSpec)


	def ApplyOSVariant(self, aBuildUnit, aEpocroot):
		# Form path to kif.xml and path to buildinfo.txt
		kifXmlPath = generic_path.Join(aEpocroot, "epoc32", "data","kif.xml")
		buildInfoTxtPath = generic_path.Join(aEpocroot, "epoc32", "data","buildinfo.txt")

		# Start with osVersion being None. This variable is a string and does two things:
		# 1) is a representation of the OS version
		# 2) is potentially the name of a variant
		osVersion = None
		if kifXmlPath.isFile(): # kif.xml exists so try to read it
			osVersion = getOsVerFromKifXml(str(kifXmlPath))
			if osVersion != None:
				self.__Raptor.Info("OS version \"%s\" determined from file \"%s\"" % (osVersion, kifXmlPath))

		# OS version was not determined from the kif.xml, e.g. because it doesn't exist
		# or there was a problem parsing it. So, we fall over to using the buildinfo.txt
		if osVersion == None and buildInfoTxtPath.isFile():
			osVersion = getOsVerFromBuildInfoTxt(str(buildInfoTxtPath))
			if osVersion != None:
				self.__Raptor.Info("OS version \"%s\" determined from file \"%s\"" % (osVersion, buildInfoTxtPath))

		# If we determined a non-empty string for the OS Version, attempt to apply it
		if osVersion and osVersion in self.__Raptor.cache.variants:
			self.__Raptor.Info("applying the OS variant to the configuration \"%s\"." % aBuildUnit.name)
			aBuildUnit.variants.append(self.__Raptor.cache.variants[osVersion])
		else:
			self.__Raptor.Info("no OS variant for the configuration \"%s\"." % aBuildUnit.name)

