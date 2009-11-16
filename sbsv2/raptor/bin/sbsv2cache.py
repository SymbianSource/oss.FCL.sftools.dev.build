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
# Creates CBR tool compatible cache files from SBSv2 .whatlog variant output
#


import sys
import os
from optparse import OptionParser
import xml.parsers.expat
import re


# Global dictionary of ComponentReleasable objects, keyed on bld.inf file
BuildReleasables = {}

# Provide a means to form  "traditional" ABLD-like build platforms and variants from SBSv2 configurations
ConfigMatch = re.compile(r'^(?P<PLATFORM>\w+)_(?P<VARIANT>\w+)(\.((?P<PLATFORMADD>smp)|\w+))*')

WinscwTreeMatch = re.compile(r'[\\|\/]epoc32[\\|\/]release[\\|\/]winscw[\\|\/](?P<VARIANT>(urel|udeb))[\\|\/]', re.IGNORECASE)
WinDriveMatch = re.compile(r'[A-Za-z]:')

# $self->{abldcache}->{'<bld.inf location> export -what'} =
# $self->{abldcache}->{'<bld.inf location> <phase> <platform> <variant> -what'} =
# $self->{abldcache}->{'plats'} =
CacheGroupPrefix = "$self->{abldcache}->{\'"
CacheGroupSuffix = "\'} =\n"
CacheExportGroup = CacheGroupPrefix+"%s export -what"+CacheGroupSuffix
CacheBuildOutputGroup = CacheGroupPrefix+"%s %s %s %s -what"+CacheGroupSuffix
CachePlatsGroup = CacheGroupPrefix+"plats"+CacheGroupSuffix
CacheListOpen = "\t[\n"
CacheListItem = "\t\'%s\'"
CacheListItemPair = "\t[\'%s\', \'%s\']"
CacheListClose = "\t];\n\n"


class ComponentReleasable(object):
	"""Wraps up a bld.inf file in terms of its packagable releasable output."""
	
	# If EPOCROOT is set, provide a means to confirm that potentially publishable releasables live under EPOCROOT/epoc32
	ReleaseTreeMatch = None
	if os.environ.has_key("EPOCROOT"):
		ReleaseTreeMatch = re.compile(r'\"*'+os.path.abspath(os.path.join(os.environ["EPOCROOT"],"epoc32")).replace('\\',r'\/').replace('\/',r'[\\|\/]+')+r'[\\|\/]+', re.IGNORECASE)
		
	def __init__(self, aBldInfFile, aVerbose=False):
		self.__BldInfFile = aBldInfFile
		self.__Verbose = aVerbose
		self.__Exports = {}
		self.__BuildOutput = {}
		self.__Platforms = {}
		
	def __IsReleasableItem(self, aBuildItem):
		if self.ReleaseTreeMatch and self.ReleaseTreeMatch.match(aBuildItem):
			return True
		
		if self.__Verbose:
			print "Discarding: \'%s\' from \'%s\' as not in the release tree." % (aBuildItem, self.__BldInfFile)
		return False

	def __StoreBuildItem(self, aPlatform, aVariant, aBuildItem):
		if not self.__BuildOutput.has_key(aPlatform):
			self.__BuildOutput[aPlatform] = {}
			if aPlatform != "ALL":
				self.__Platforms[aPlatform.upper()] = 1
		if not self.__BuildOutput[aPlatform].has_key(aVariant):
			self.__BuildOutput[aPlatform][aVariant] = {}
		
		if aBuildItem:
			self.__BuildOutput[aPlatform][aVariant][aBuildItem] = 1
		
	def AddExport(self, aDestination, aSource):
		if not self.__IsReleasableItem(aDestination):
			return
		self.__Exports[aDestination] = aSource

	def AddBuildOutput(self, aBuildItem, aPlatform="ALL", aVariant="ALL"):
		if not self.__IsReleasableItem(aBuildItem):
			return
		if aPlatform != "ALL" and aVariant == "ALL":
			self.__StoreBuildItem(aPlatform, "urel", aBuildItem)
			self.__StoreBuildItem(aPlatform, "udeb", aBuildItem)
		else:
			self.__StoreBuildItem(aPlatform, aVariant, aBuildItem)
		
	def Finalise(self):
		# Re-visit the stored build items and, in the context of all build platforms having been processed for the
		# component, copy platform-generic "ALL" output to the concrete build platform outputs
		if self.__BuildOutput.has_key("ALL"):
			allItems = self.__BuildOutput["ALL"]["ALL"].keys()		
			for platform in self.__BuildOutput.keys():
				for variant in self.__BuildOutput[platform].keys():
					for allItem in allItems:
						self.__StoreBuildItem(platform, variant, allItem)			
			del self.__BuildOutput["ALL"]
	
	def GetBldInf(self):
		return self.__BldInfFile

	def GetExports(self):
		return self.__Exports

	def GetBuildOutput(self):
		return self.__BuildOutput

	def GetPlatforms(self):
		return self.__Platforms

	def HasReleasables(self):
		return (self.__BuildOutput or self.__Exports)
							

def error(aMessage):
	sys.stderr.write("ERROR: sbsv2cache.py : %s\n" % aMessage)
	sys.exit(1)
	
def processReleasableElement(aContext, aName, aValue, aVerbose):
	bldinf = aContext["bldinf"]
	mmp = aContext["mmp"]
	config = aContext["config"]

	platform = ""
	variant = ""
	configMatchResults = ConfigMatch.match(config)
	if configMatchResults:
		platform = configMatchResults.group('PLATFORM')
		variant = configMatchResults.group('VARIANT')	
		if configMatchResults.group('PLATFORMADD'):
			platform += configMatchResults.group('PLATFORMADD')
	
	if not BuildReleasables.has_key(bldinf):
		BuildReleasables[bldinf] = ComponentReleasable(bldinf, aVerbose)
	
	componentReleasable = BuildReleasables[bldinf]
	
	if aName == "export" :
		componentReleasable.AddExport(aValue["destination"], aValue["source"])
	elif aName == "member":
		componentReleasable.AddExport(aValue.keys()[0], aContext["zipfile"])
	elif aName == "build":
		componentReleasable.AddBuildOutput(aValue.keys()[0], platform, variant)
	elif aName == "resource" or aName == "bitmap":
		item = aValue.keys()[0]
		# Identify winscw urel/udeb specific resources, and store accordingly
		winscwTreeMatchResult = WinscwTreeMatch.search(item)
		if platform == "winscw" and winscwTreeMatchResult:
			componentReleasable.AddBuildOutput(item, platform, winscwTreeMatchResult.group("VARIANT").lower())
		else:
			componentReleasable.AddBuildOutput(item, platform)
	elif aName == "stringtable":
		componentReleasable.AddBuildOutput(aValue.keys()[0])			

def parseLog(aLog, aVerbose):
	if not os.path.exists(aLog):
		error("Log file %s does not exist." % aLog)
		
	parser = xml.parsers.expat.ParserCreate()
	parser.buffer_text = True
	
	elementContext = {}
	currentElement = []
		
	def start_element(name, attributes):
		if name == "whatlog" or name == "archive":
			elementContext.update(attributes)
		elif elementContext.has_key("bldinf"):
			if name == "export":
				# Exports are all attributes, so deal with them directly
				processReleasableElement(elementContext, name, attributes, aVerbose)
			else:
				# Other elements wrap values, get these later
				currentElement.append(name)
						
	def end_element(name):
		if name == "whatlog":
			elementContext.clear()
		elif name == "archive":
			del elementContext["zipfile"]
	
	def char_data(data):
		if elementContext.has_key("bldinf") and currentElement:
			processReleasableElement(elementContext, currentElement.pop(), {str(data):1}, aVerbose)
	
	parser.StartElementHandler = start_element
	parser.EndElementHandler = end_element
	parser.CharacterDataHandler = char_data

	try:
		if aVerbose:
			print "Parsing: " + aLog
			
		parser.ParseFile(open(aLog, "r"))
	except xml.parsers.expat.ExpatError, e:	
		error("Failure parsing log file \'%s\' (line %s)" % (aLog, e.lineno))

def normFileForCache(aFile):
	normedFile = WinDriveMatch.sub("",aFile)
	normedFile = normedFile.replace("/", "\\")
	normedFile = normedFile.replace("\\", "\\\\")
	normedFile = normedFile.replace("\\\\\\\\", "\\\\")
	normedFile = normedFile.replace("\"", "")
	return normedFile
	
def dumpCacheFileList(aCacheFileObject, aItems, aPairs=False):	
	numItems = len(aItems)
	suffix = ",\n"
	
	aCacheFileObject.write(CacheListOpen)
	for item in aItems:
		if aItems.index(item) == numItems-1:
			suffix = "\n"			
		if aPairs:
			aCacheFileObject.write((CacheListItemPair % (normFileForCache(item[0]), normFileForCache(item[1]))) + suffix)
		else:
			aCacheFileObject.write((CacheListItem % normFileForCache(item)) + suffix)
	aCacheFileObject.write(CacheListClose)
	
def createCacheFile(aComponentReleasable, aOutputPath, aSourceExports, aVerbose):	
	if not aComponentReleasable.HasReleasables():
		return
	
	cacheFileDir = os.path.normpath(\
				os.path.join(aOutputPath, \
	            WinDriveMatch.sub("",os.path.dirname(aComponentReleasable.GetBldInf())).lstrip(r'/').lstrip(r'\\')))
	cacheFile = os.path.join(cacheFileDir, "cache")
	
	bldInfLoc = WinDriveMatch.sub("",os.path.dirname(aComponentReleasable.GetBldInf())).replace("/", "\\")

	if aVerbose:
		print "Creating: " + cacheFile
	
	if not os.path.exists(cacheFileDir):
		os.makedirs(cacheFileDir)
	
	try:
		cacheFileObject = open(cacheFile, 'w')
	
		exports = aComponentReleasable.GetExports()
		if exports:
			cacheFileObject.write(CacheExportGroup % bldInfLoc)
			if aSourceExports:
				dumpCacheFileList(cacheFileObject, exports.items(), True)
			else:
				dumpCacheFileList(cacheFileObject, exports.keys())
	
		buildOutput = aComponentReleasable.GetBuildOutput()		
		if buildOutput:
			for plat in buildOutput.keys():
				# Most cache output is represented as if performed for the "abld target" phase, but tools platforms
				# are presented as if performed by "abld build", and so must additionally replicate any exports
				# performed for the component in their variant output
				phase = "target"
				additionalOutput = []
				if plat == "tools" or plat == "tools2":
					phase = "build"
					if exports:
						additionalOutput = exports.keys()
				
				for variant in buildOutput[plat].keys():
					cacheFileObject.write(CacheBuildOutputGroup % (bldInfLoc, phase, plat, variant))
					dumpCacheFileList(cacheFileObject, buildOutput[plat][variant].keys() + additionalOutput)
	
		cacheFileObject.write(CachePlatsGroup)
		dumpCacheFileList(cacheFileObject, aComponentReleasable.GetPlatforms().keys())
		
		cacheFileObject.close()
	except IOError:
		error("Failure creating cache file %s." % cacheFile)


def main():
	parser = OptionParser(prog="sbsv2cache.py")
	parser.add_option("-l", "--log", action="append", dest="logs", help="log file to parse for <whatlog/> wrapped content.")
	parser.add_option("-o", "--outputpath", action="store", dest="outputpath", help="root location to generate cache files.")
	parser.add_option("-s", "--sourceexports", action="store_true", default=False, dest="sourceexports", help="generate cache files where each element in the export array is a ['destination', 'source'] array rather than just a 'destination' element.")
	parser.add_option("-v", "--verbose", action="store_true", default=False, dest="verbose", help="provide more information as things happen.")
	
	(options, leftover_args) = parser.parse_args(sys.argv[1:])

	if leftover_args or not options.logs or not options.outputpath:
		parser.print_help()
		sys.exit(1)
		
	print "sbsv2cache: started"
	
	# Parse build logs to populate the BuildReleasables dictionary
	for log in options.logs:
		parseLog(os.path.abspath(log), options.verbose)
	
	# Finalise components in BuildReleasables and create cache files as we go
	for component in BuildReleasables.keys():
		BuildReleasables[component].Finalise()
		createCacheFile(BuildReleasables[component], os.path.abspath(options.outputpath), options.sourceexports, options.verbose)
		
	print "sbsv2cache: finished"
	
if __name__ == "__main__":
	main()
	

