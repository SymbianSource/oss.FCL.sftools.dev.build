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
# raptor_xml module
#

import os
import raptor_data
import raptor_utilities
import xml.dom.minidom
import re
import generic_path

# raptor_xml module attributes

namespace = "http://symbian.com/xml/build"
xsdVersion = "build/2_0.xsd"
xsdIgnore = "build/666.xsd"

_constructors = {"alias":raptor_data.Alias,
				 "aliasRef":raptor_data.AliasRef,
				 "append":raptor_data.Append,
				 "env":raptor_data.Env,
				 "group":raptor_data.Group,
				 "groupRef":raptor_data.GroupRef,
				 "interface":raptor_data.Interface,
				 "interfaceRef":raptor_data.InterfaceRef,
				 "param":raptor_data.Parameter,
				 "paramgroup":raptor_data.ParameterGroup,
				 "prepend":raptor_data.Prepend,
				 "set":raptor_data.Set,
				 "spec":raptor_data.Specification,
				 "var":raptor_data.Variant,
				 "varRef":raptor_data.VariantRef}


# raptor_xml module classes

class XMLError(Exception):
	pass

# raptor_xml module functions

def Read(Raptor, filename):
	"Read in a Raptor XML document"

	# try to read and parse the XML file
	try:
		dom = xml.dom.minidom.parse(filename)

	except: # a whole bag of exceptions can be raised here
		raise XMLError

	# <build> is always the root element
	build = dom.documentElement
	objects = []

	fileVersion = build.getAttribute("xsi:schemaLocation")

	# ignore the file it matches the "invalid" schema
	if fileVersion.endswith(xsdIgnore):
		return objects

	# check that the file matches the expected schema
	if not fileVersion.endswith(xsdVersion):
		Raptor.Warn("file '%s' uses schema '%s' which does not end with the expected version '%s'", filename, fileVersion, xsdVersion)

	# create a Data Model object from each sub-element
	for child in build.childNodes:
		if child.namespaceURI == namespace \
		and child.nodeType == child.ELEMENT_NODE:
			try:
				o = XMLtoDataModel(Raptor, child)
				if o is not None:
					objects.append(o)
			except raptor_data.InvalidChildError:
				Raptor.Warn("Invalid element %s in %s", child.localName, filename)

	# discard the XML
	dom.unlink()
	return objects


def XMLtoDataModel(Raptor, node):
	"Create a data-model object from an XML element"

	# look-up a function to create an object from the node name
	try:
		constructor = _constructors[node.localName]

	except KeyError:
		Raptor.Warn("Unknown element %s", node.localName)
		return

	model = constructor()

	# deal with the attributes first
	if node.hasAttributes():
		for i in range(node.attributes.length):
			attribute = node.attributes.item(i)
			try:

				model.SetProperty(attribute.localName, attribute.value)

			except raptor_data.InvalidPropertyError:
				Raptor.Warn("Can't set attribute %s for element %s",
							 attribute.localName, node.localName)

	# add the sub-elements
	for child in node.childNodes:
		if child.namespaceURI == namespace \
		and child.nodeType == child.ELEMENT_NODE:
			try:
				gc = XMLtoDataModel(Raptor, child)
				if gc is not None:
					model.AddChild(gc)

			except raptor_data.InvalidChildError:
				Raptor.Warn("Can't add child %s to element %s",
							 child.localName, node.localName)

	# only return a valid object (or raise error)
	if model.Valid():
		if model.IsApplicable():
			return model
		else:
			return None
	else:
		raise raptor_data.InvalidChildError


class SystemModelComponent(generic_path.Path):
	"""Path sub-class that wraps up a component bld.inf file with
	system_definition.xml context information."""

	def __init__(self, aBldInfFile, aLayerName, aContainerNames, aSystemDefinitionFile, aSystemDefinitionBase, aSystemDefinitionVersion):
		generic_path.Path.__init__(self, aBldInfFile.Absolute().path)
		self.__ContainerNames = aContainerNames
		self.__LayerName = aLayerName
		self.__SystemDefinitionFile = aSystemDefinitionFile
		self.__SystemDefinitionBase = aSystemDefinitionBase
		self.__SystemDefinitionVersion = aSystemDefinitionVersion

	def GetSystemDefinitionFile(self):
		return self.__SystemDefinitionFile

	def GetSystemDefinitionBase(self):
		return self.__SystemDefinitionBase

	def GetSystemDefinitionVersion(self):
		return self.__SystemDefinitionVersion

	def GetLayerName(self):
		return self.__LayerName

	def GetContainerName(self, aContainerType):
		if self.__ContainerNames.has_key(aContainerType):
			return self.__ContainerNames[aContainerType]
		return ""


class SystemModel(object):
	"""A representation of the SystemModel section of a Symbian system_definition.xml file."""

	def __init__(self, aLogger, aSystemDefinitionFile, aSystemDefinitionBase):
		self.__Logger = aLogger
		self.__SystemDefinitionFile = aSystemDefinitionFile.GetLocalString()
		self.__SystemDefinitionBase = aSystemDefinitionBase.GetLocalString()
		self.__Version = {'MAJOR':0,'MID':0,'MINOR':0}
		self.__IdAttribute = "name"
		self.__ComponentRoot = ""
		self.__TotalComponents = 0
		self.__LayerList = []
		self.__LayerDetails = {}
		self.__MissingBldInfs = {}

		self.__DOM = None
		self.__SystemDefinitionElement = None

		if self.__Read():
			if self.__Validate():
				self.__Parse()

		if self.__DOM:
			self.__DOM.unlink()

	def HasLayer(self, aLayer):
		return aLayer in self.__LayerList

	def GetLayerNames(self):
		return self.__LayerList

	def GetLayerComponents(self, aLayer):
		if not self.HasLayer(aLayer):
			self.__Logger.Error("System Definition layer \"%s\" does not exist in %s", aLayer, self.__SystemDefinitionFile)
			return []

		return self.__LayerDetails[aLayer]

	def IsLayerBuildable(self, aLayer):
		if aLayer in self.__MissingBldInfs:
			for missingbldinf in self.__MissingBldInfs[aLayer]:
				self.__Logger.Error("System Definition layer \"%s\" from system definition file \"%s\" " + \
								    "refers to non existent bld.inf file %s", aLayer, self.__SystemDefinitionFile, missingbldinf)

		if len(self.GetLayerComponents(aLayer)):
			return True
		return False


	def GetAllComponents(self):
		components = []

		for layer in self.GetLayerNames():
			components.extend(self.GetLayerComponents(layer))

		return components

	def DumpLayerInfo(self, aLayer):
		if self.HasLayer(aLayer):
			self.__Logger.Info("Found %d bld.inf references in layer \"%s\"", len(self.GetLayerComponents(aLayer)), aLayer)

	def DumpInfo(self):
		self.__Logger.Info("Found %d bld.inf references in %s within %d layers:", len(self.GetAllComponents()), self.__SystemDefinitionFile, len(self.GetLayerNames()))
		self.__Logger.Info("\t%s", ", ".join(self.GetLayerNames()))
		self.__Logger.InfoDiscovery(object_type = "layers",
				count = len(self.GetLayerNames()))
		self.__Logger.InfoDiscovery(object_type = "bld.inf references",
				count = len(self.GetAllComponents()))

	def __Read(self):
		if not os.path.exists(self.__SystemDefinitionFile):
			self.__Logger.Error("System Definition file %s does not exist", self.__SystemDefinitionFile)
			return False

		self.__Logger.Info("System Definition file %s", self.__SystemDefinitionFile)

		# try to read the XML file
		try:
			self.__DOM = xml.dom.minidom.parse(self.__SystemDefinitionFile)

		except: # a whole bag of exceptions can be raised here
			self.__Logger.Error("Failed to parse XML file %s", self.__SystemDefinitionFile)
			return False

		# <SystemDefinition> is always the root element
		self.__SystemDefinitionElement = self.__DOM.documentElement

		return True

	def __Validate(self):
		# account for different schema versions in processing
		# old format : version >= 1.3.0
		# new format : version >= 2.0.0 (assume later versions are compatible...at least for now)
		version = re.match(r'(?P<MAJOR>\d)\.(?P<MID>\d)(\.(?P<MINOR>\d))?', self.__SystemDefinitionElement.getAttribute("schema"))

		if not version:
			self.__Logger.Error("Cannot determine schema version of XML file %s", self.__SystemDefinitionFile)
			return False

		self.__Version['MAJOR'] = int(version.group('MAJOR'))
		self.__Version['MID'] = int(version.group('MID'))
		self.__Version['MINOR'] = int(version.group('MINOR'))

		if self.__Version['MAJOR'] == 1 and self.__Version['MID'] > 2:
			self.__ComponentRoot = self.__SystemDefinitionBase
		elif self.__Version['MAJOR'] == 2 or self.__Version['MAJOR'] == 3:
			# 2.0.x and 3.0.0 formats support SOURCEROOT or SRCROOT as an environment specified base - we respect this, unless
			# explicitly overridden on the command line
			if os.environ.has_key('SRCROOT'):
				self.__ComponentRoot = generic_path.Path(os.environ['SRCROOT'])
			elif os.environ.has_key('SOURCEROOT'):
				self.__ComponentRoot = generic_path.Path(os.environ['SOURCEROOT'])

			if self.__SystemDefinitionBase and self.__SystemDefinitionBase != ".":
				self.__ComponentRoot = self.__SystemDefinitionBase
				if os.environ.has_key('SRCROOT'):
					self.__Logger.Info("Command line specified System Definition file base \'%s\' overriding environment SRCROOT \'%s\'", self.__SystemDefinitionBase, os.environ['SRCROOT'])
				elif os.environ.has_key('SOURCEROOT'):
					self.__Logger.Info("Command line specified System Definition file base \'%s\' overriding environment SOURCEROOT \'%s\'", self.__SystemDefinitionBase, os.environ['SOURCEROOT'])
		else:
			self.__Logger.Error("Cannot process schema version %s of file %s", version.string, self.__SystemDefinitionFile)
			return False

		if self.__Version['MAJOR'] >= 3:
			# id is the unique identifier for 3.0 and later schema
			self.__IdAttribute = "id"

		return True

	def __Parse(self):
		# For 2.0 and earlier: find the <systemModel> element (there can be 0 or 1) and search any <layer> elements for <unit> elements with "bldFile" attributes
		# the <layer> context of captured "bldFile" attributes is recorded as we go
		# For 3.0 and later, process any architectural topmost element, use the topmost element with an id as the "layer"
		for child in self.__SystemDefinitionElement.childNodes:
			if child.localName in ["systemModel", "layer", "package", "collection", "component"]:
				self.__ProcessSystemModelElement(child)

	def __CreateComponent(self, aBldInfFile, aUnitElement):
		# take a resolved bld.inf file and associated <unit/> element and returns a populated Component object
		containers = {}
		self.__GetElementContainers(aUnitElement, containers)
		layer = self.__GetEffectiveLayer(aUnitElement)
		component = SystemModelComponent(aBldInfFile, layer, containers, self.__SystemDefinitionFile, self.__SystemDefinitionBase, self.__Version)

		return component

	def __GetEffectiveLayer(self, aElement):
		#' return the ID of the topmost item which has an ID. For 1.x and 2.x, this will always be layer, for 3.x, it will be the topmost ID'd element in the file
		# never call this on the root element
		if aElement.parentNode.hasAttribute(self.__IdAttribute):
			return self.__GetEffectiveLayer(aElement.parentNode)
		elif aElement.hasAttribute(self.__IdAttribute):
			return aElement.getAttribute(self.__IdAttribute)
		return ""

	def __GetElementContainers(self, aElement, aContainers):
		# take a <unit/> element and creates a type->name dictionary of all of its parent containers
		# We're only interested in parent nodes if they're not the top-most node
		if aElement.parentNode.parentNode:
			parent = aElement.parentNode
			name = parent.getAttribute(self.__IdAttribute)

			if name:
				aContainers[parent.tagName] = name

			self.__GetElementContainers(parent, aContainers)

	def __ProcessSystemModelElement(self, aElement):
		"""Search for XML <unit/> elements with 'bldFile' attributes and resolve concrete bld.inf locations
		with an appreciation of different schema versions."""

		# The effective "layer" is the item whose parent does not have an id (or name in 2.x and earlier)
		if not aElement.parentNode.hasAttribute(self.__IdAttribute) :
			currentLayer = aElement.getAttribute(self.__IdAttribute)

			if not self.__LayerDetails.has_key(currentLayer):
				self.__LayerDetails[currentLayer] = []

			if not currentLayer in self.__LayerList:
				self.__LayerList.append(currentLayer)

		elif aElement.tagName == "unit" and aElement.hasAttributes():
			bldFileValue = aElement.getAttribute("bldFile")

			if bldFileValue:
				bldInfRoot = self.__ComponentRoot

				if self.__Version['MAJOR'] == 1:
					# version 1.x schema paths can use DOS slashes
					bldFileValue = raptor_utilities.convertToUnixSlash(bldFileValue)
				elif self.__Version['MAJOR'] >= 2:
					# version 2.x.x schema paths are subject to a "root" attribute off-set, if it exists
					rootValue = aElement.getAttribute("root")

					if rootValue:
						if os.environ.has_key(rootValue):
							bldInfRoot = generic_path.Path(os.environ[rootValue])
						else:
							# Assume that this is an error i.e. don't attempt to resolve in relation to SOURCEROOT
							bldInfRoot = None
							self.__Logger.Error("Cannot resolve \'root\' attribute value \"%s\" in %s", rootValue, self.__SystemDefinitionFile)
							return

				group = generic_path.Path(bldFileValue)

				if self.__Version['MAJOR'] < 3:
					# absolute paths are not changed by root var in 1.x and 2.x
					if not group.isAbsolute() and bldInfRoot:
						group = generic_path.Join(bldInfRoot, group)
				else:
					# only absolute paths are changed by root var in 3.x
					if group.isAbsolute() and bldInfRoot:
						group = generic_path.Join(bldInfRoot, group)

				bldinf = generic_path.Join(group, "bld.inf").FindCaseless()

				if bldinf == None:
					# recording layers containing non existent bld.infs
					bldinfname = group.GetLocalString()
					bldinfname = bldinfname + 'bld.inf'
					layer = self.__GetEffectiveLayer(aElement)
					if not layer in self.__MissingBldInfs:
						self.__MissingBldInfs[layer]=[]
					self.__MissingBldInfs[layer].append(bldinfname)

				else:
					component = self.__CreateComponent(bldinf, aElement)
					layer = component.GetLayerName()
					if layer:
						self.__LayerDetails[layer].append(component)
						self.__TotalComponents += 1
					else:
						self.__Logger.Error("No containing layer found for %s in %s", str(bldinf), self.__SystemDefinitionFile)

		# search the sub-elements
		for child in aElement.childNodes:
			if child.nodeType == child.ELEMENT_NODE:
				self.__ProcessSystemModelElement(child)


# end of the raptor_xml module
