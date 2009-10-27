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
# raptor_cache module
# This module represents a cache of objects for a Raptor program.
#

import raptor_data
import raptor_xml
import generic_path
import os

# raptor_cache module attributes


# raptor_cache module classes

class Cache:

	def __init__(self, Raptor):
		self.raptor = Raptor
		self.aliases = {}
		self.groups = {}
		self.interfaces = {}
		self.variants = {}

	def Load(self, gPathOrGPathList, cacheID = ""):
		"""scan directory for xml files containing Raptor objects.
		Input is either a generic path object or a list of
		generic path objects.

		If a cacheID is supplied then the loaded objects are
		placed into containers which are marked with that ID.
		This is useful for Interfaces which may be loaded from
		several locations (different epoc32 trees for example)
		but need to be kept separate.
		"""

		pathlist = []
		filenames = []

		# Create pathlist - this will be of length one if gPathOrGPathList is a
		# generic path object; otherwise it's a list so just make all supplied paths generic
		if isinstance(gPathOrGPathList, list):
			pathlist = map(lambda x: x.GetLocalString(), gPathOrGPathList)
		elif isinstance(gPathOrGPathList, generic_path.Path):
			pathlist = [gPathOrGPathList.GetLocalString()]
		else:
			self.raptor.Warn("Empty list or blank path supplied.")

		# Only when debugging, print the list. The for loop will be
		# skipped if not in debug mode
		if self.raptor.debugOutput:
			for path in pathlist:
				self.raptor.Debug("Loading XML cache from %s", path)

		# Internal function to get the list of XML
		# files recursively
		def getXmlFiles(aDir, aFileList):
			dirList = []
			for fname in os.listdir(aDir):
				path = os.path.join(aDir, fname)
				if os.path.isdir(path):
					dirList.append(path)
				else: # It's a file
					if path.endswith(".xml"): # Only files ending in .xml get added
						aFileList.append(path)
			# Now iterate over directory list; this way, the files in the top level of
			# aDir will be added before all files in any subdirectory of aDir
			for dir in dirList:
				getXmlFiles(dir, aFileList)

		# This will add all files in all top level directories and all XML files
		for path in pathlist:
			# gPathOrGPathList passed to Load() can be a file or a
			# directory, or a list of files or directories or both
			if os.path.isfile(path):
				if path.endswith(".xml"): # Only files whose names end in .xml get added
					filenames.append(path)
			elif os.path.isdir(path):
				getXmlFiles(path, filenames)
			else: # it isn't a file or directory
				self.raptor.Warn("No file or directory found for '%s'", path)

		if not filenames:
			# No XML files found in any of the paths
			return

		# Parse XML files, and add the objects to our
		# configuration/interface/variant dictionaries
		for fullpath in filenames:
			try:
				objects = raptor_xml.Read(self.raptor, fullpath)

			except raptor_xml.XMLError:
				self.raptor.Warn("Failed to read XML file %s", fullpath)
				continue

			self.raptor.Debug("%d objects found in XML file %s", len(objects), fullpath)

			for obj in objects:
				# top-level objects need to know which XML file they came from.
				obj.SetSourceFile(fullpath)
				try:
					self.AddObject(obj, cacheID)
				except UnexpectedObjectError:
					self.raptor.Warn("Unexpected object %s", str(obj))

	def AddObject(self, obj, cacheID):
		"""add a Group, Alias, Interface or Variant.

		The cacheID is only used to separate Interfaces.
		"""

		if isinstance(obj, raptor_data.Group):
			self.AddGroup(obj)
		elif isinstance(obj, raptor_data.Alias):
			self.AddAlias(obj)
		elif isinstance(obj, raptor_data.Interface):
			self.AddInterface(obj, cacheID)
		elif isinstance(obj, raptor_data.Variant):
			self.AddVariant(obj)
		else:
			raise UnexpectedObjectError


	def FindNamedGroup(self, name):
		return self.groups[name]

	def AddGroup(self, obj):
		if obj.name in self.groups:
			self.WarnDuplicate("group", self.groups[obj.name], obj)
			return

		obj.SetOwner(self.raptor)
		self.groups[obj.name] = obj

	def FindNamedAlias(self, name):
		return self.aliases[name]

	def AddAlias(self, obj):
		if obj.name in self.aliases:
			self.WarnDuplicate("alias", self.aliases[obj.name], obj)
			return

		obj.SetOwner(self.raptor)
		self.aliases[obj.name] = obj


	def FindNamedInterface(self, name, cacheID = ""):
		try:
			return self.interfaces[cacheID][name]
		except KeyError, e:
			if cacheID == "":
				raise e
			else:
				return self.interfaces[""][name]


	def AddInterface(self, obj, cacheID):
		if not cacheID in self.interfaces:
			self.interfaces[cacheID] = {}

		if obj.name in self.interfaces[cacheID]:
			self.WarnDuplicate("interface", self.interfaces[cacheID][obj.name], obj)
			return

		obj.SetOwner(self.raptor)
		obj.cacheID = cacheID
		self.interfaces[cacheID][obj.name] = obj


	def FindNamedVariant(self, name):
		return self.variants[name]


	def AddVariant(self, obj):
		# anonymous variants can never be referenced, so ignore them
		if obj.name:
			if self.variants.has_key(obj.name):
				self.WarnDuplicate("variant", self.variants[obj.name], obj)
				return

			obj.SetOwner(self.raptor)
			self.variants[obj.name] = obj


	def WarnDuplicate(self, type, objOld, objNew):
		"""tell us where duplicate objects came from."""
		oldSource = objOld.source
		if oldSource == None:
			oldSource = "unknown"

		newSource = objNew.source
		if newSource == None:
			newSource = "unknown"

		# don't warn if we are reloading the object from the same
		# file as before: since that is quite ligitimate.
		if oldSource == newSource and oldSource != "unknown":
			return

		# actually this is just for information not a warning
		self.raptor.Info("Duplicate %s '%s' (the one from '%s' will override the one in '%s')",
						 type, objOld.name, oldSource, newSource)


class UnexpectedObjectError(Exception):
	pass


# end of the raptor_cache module
