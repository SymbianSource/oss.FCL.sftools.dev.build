#
# Copyright (c) 2006-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# raptor_data module
# This module contains the classes that make up the Raptor Data Model.
#

import copy
import generic_path
import os
import hashlib
import raptor_utilities
import re
import types
import sys
import subprocess
from tempfile import gettempdir
from time import time, clock
import traceback
import raptor_cache


class MissingInterfaceError(Exception):
	def __init__(self, s):
		Exception.__init__(self,s)

# What host platforms we recognise
# This allows us to tie some variants to one host platform and some to another
class HostPlatform(object):
	""" List the host platforms on which we can build.  Allow configuration
 	    files to specify different information based on that.
	"""
	hostplatforms = ["win32", "win64", "linux2"]
	hostplatform = sys.platform

	@classmethod
	def IsKnown(cls, platformpattern):
		"Does the parameter match the name of a known platform "
		hpnre = re.compile(platformpattern, re.I)
		for hp in cls.hostplatforms:
			if hpnre.match(hp):
				return True
		return False

	@classmethod
	def IsHost(cls, platformpattern):
		""" Does the parameter match the name of the
		    platform that we're executing on? """
		ppre = re.compile(platformpattern, re.I)
		if ppre.match(cls.hostplatform):
			return True
		return False


# Make sure not to start up on an unsupported platform
if not HostPlatform.IsKnown(HostPlatform.hostplatform):
	raise Exception("raptor_data module loaded on an unrecognised platform '%s'. Expected one of %s" % (HostPlatform.hostplatform, str(HostPlatform.hostplatforms)))


# raptor_data module classes

class Model(object):
	"Base class for data-model objects"

	__slots__ = ('host', 'source', 'cacheID')

	def __init__(self):
		self.source = None	# XML file
		self.host = None
		self.cacheID = ""	# default set of cached objects
		# not using the cache parameter - there to make the 
		# init for all Model objects "standard"


	def SetSourceFile(self, filename):
		self.source = filename


	def SetProperty(self, name, value):
		raise InvalidPropertyError()


	def AddChild(self, child):
		raise InvalidChildError()


	def Valid(self):
		return False

	def IsApplicable(self):
		"This variant may be caused to only apply when used on a particular host build platform"
		if self.host is None:
			return True

		if HostPlatform.IsHost(self.host):
			return True

		return False


class InvalidPropertyError(Exception):
	pass

class InvalidChildError(Exception):
	pass

class BadReferenceError(Exception):
	pass


class Reference(Model):
	"Base class for data-model reference objects"

	def __init__(self, ref = None):
		Model.__init__(self)
		self.ref = ref
		self.modifiers = []

	def SetProperty(self, name, value):
		if name == "ref":
			self.ref = value
		elif name == "mod":
			self.modifiers = value.split(".")
		else:
			raise InvalidPropertyError()

	def Resolve(self):
		raise BadReferenceError()

	def GetModifiers(self, cache):
		mods = []
		for m in self.modifiers:
			try:
				mods.append(cache.FindNamedVariant(m))
			except KeyError:
				raise BadReferenceError(m)
		return mods

	def Valid(self):
		return self.ref


class VariantContainer(Model):

	def __init__(self):
		Model.__init__(self)	# base class constructor
		self.variants = []


	def __str__(self):
		return "\n".join([str(v) for v in self.variants])


	def AddVariant(self, variant):
		if type(variant) is types.StringTypes:
			variant = VariantRef(ref = variant)


		# Only add the variant if it's not in the list
		# already
		if not variant in self.variants:
			self.variants.append(variant)

	def GetVariants(self, cache):
		# resolve any VariantRef objects into Variant objects
		missing_variants = []
		for i,var in enumerate(self.variants):
			if isinstance(var, Reference):
				try:
					self.variants[i] = var.Resolve(cache=cache)

				except BadReferenceError:
					missing_variants.append(var.ref)

		if len(missing_variants) > 0:
			raise MissingVariantException("Missing variants '%s'", " ".join(missing_variants))

		return self.variants


class Interface(Model):

	def __init__(self, name = None):
		Model.__init__(self)	# base class constructor
		self.name = name
		self.flm = None
		self.abstract = False
		self.extends = None
		self.params = []
		self.paramgroups = []

	def __str__(self):
		return "<interface name='%s'>" % self.name + "</interface>"

	def FindParent(self, cache):
		try:
			return cache.FindNamedInterface(self.extends, self.cacheID)
		except KeyError:
			raise BadReferenceError("Cannot extend interface because it cannot be found: "+str(self.extends))

	def GetParams(self, cache):
		if self.extends != None:
			parent = self.FindParent(cache)

			# what parameter names do we have already?
			names = set([x.name for x in self.params])

			# pick up ones we don't have that are in our parent
			pp = []
			for p in parent.GetParams(cache):
				if not p.name in names:
					pp.append(p)

			# list parent parameters first then ours
			pp.extend(self.params)
			return pp

		return self.params

	def GetParamGroups(self, cache):
		if self.extends != None:
			parent = self.FindParent(cache)

			# what parameter names do we have already?
			patterns = set([x.pattern for x in self.paramgroups])

			# pick up ones we don't have that are in our parent
			for g in parent.GetParamGroups(cache):
				if not g.pattern in patterns:
					self.paramgroups.append(g)

		return self.paramgroups


	def GetFLMIncludePath(self, cache):
		"absolute path to the FLM"

		if self.flm == None:
			if self.extends != None:
				parent = self.FindParent(cache)

				return parent.GetFLMIncludePath(cache)
			else:
				raise InvalidPropertyError()

		if not os.path.isabs(self.flm):
			self.flm = os.path.join(os.path.dirname(self.source), self.flm)

		return generic_path.Path(self.flm)


	def SetProperty(self, name, value):
		if name == "name":
			self.name = value
		elif name == "flm":
			self.flm = value
		elif name == "abstract":
			self.abstract = (value == "true")
		elif name == "extends":
			self.extends = value
		else:
			raise InvalidPropertyError()


	def AddChild(self, child):
		if isinstance(child, Parameter):
			self.AddParameter(child)
		elif isinstance(child, ParameterGroup):
			self.AddParameterGroup(child)
		else:
			raise InvalidChildError()


	def AddParameter(self, parameter):
		self.params.append(parameter)

	def AddParameterGroup(self, parametergroup):
		self.paramgroups.append(parametergroup)

	def Valid(self):
		return (self.name != None)


class InterfaceRef(Reference):

	def __str__(self):
		return "<interfaceRef ref='%s'/>" % self.ref

	def Resolve(self, cache):
		try:
			return cache.FindNamedInterface(self.ref, self.cacheID)
		except KeyError:
			raise BadReferenceError()


class Specification(VariantContainer):

	def __init__(self, name = "", type = ""):
		VariantContainer.__init__(self)	# base class constructor
		self.name = name
		self.type = type
		self.interface = None
		self.childSpecs = []
		self.parentSpec = None


	def __str__(self):
		s = "<spec name='%s'>" % str(self.name)
		s += VariantContainer.__str__(self)
		for c in self.childSpecs:
			s += str(c) + '\n'
		s += "</spec>"
		return s


	def SetProperty(self, name, value):
		if name == "name":
			self.name = value
		else:
			raise InvalidPropertyError()


	def Configure(self, config, cache):
		# configure all the children (some may be Filters or parents of)
		for spec in self.GetChildSpecs():
			spec.Configure(config, cache = cache)


	def HasInterface(self):
		return self.interface != None


	def SetInterface(self, interface):
		if isinstance(interface, Interface) \
		or isinstance(interface, InterfaceRef):
			self.interface = interface
		else:
			self.interface = InterfaceRef(ref = interface)


	def GetInterface(self, cache):
		"""return the Interface (fetching from the cache if it was a ref)
		may return None"""

		if self.interface == None \
		or isinstance(self.interface, Interface):
			return self.interface

		if isinstance(self.interface, InterfaceRef):
			try:
				self.interface = self.interface.Resolve(cache=cache)
				return self.interface

			except BadReferenceError:
				raise MissingInterfaceError("Missing interface %s" % self.interface.ref)

	def AddChild(self, child):
		if isinstance(child, Specification):
			self.AddChildSpecification(child)
		elif isinstance(child, Interface) \
		  or isinstance(child, InterfaceRef):
			self.SetInterface(child)
		elif isinstance(child, Variant) \
		  or isinstance(child, VariantRef):
			self.AddVariant(child)
		else:
			raise InvalidChildError()


	def AddChildSpecification(self, child):
		child.SetParentSpec(self)
		self.childSpecs.append(child)


	def SetParentSpec(self, parent):
		self.parentSpec = parent


	def GetChildSpecs(self):
		return self.childSpecs


	def Valid(self):
		return True


	def GetAllVariantsRecursively(self, cache):
		"""Returns all variants contained in this node and in its ancestors.

		The returned value is a list, the structure of which is [variants-in-parent,
		variants-in-self].

		Note that the function recurses through parent *Specifications*, not through
		the variants themselves.
		"""
		if self.parentSpec:
			variants = self.parentSpec.GetAllVariantsRecursively(cache = cache)
		else:
			variants = []

		variants.extend( self.GetVariants(cache = cache) )

		return variants


class Filter(Specification):
	"""A Filter is two Specification nodes and a True/False switch.

	Filter extends Specification to have two nodes, only one of
	which can be active at any time. Which node is active is determined
	when the Configure method is called after setting up a Condition.

	If several Conditions are set, the test is an OR of all of them."""

	def __init__(self, name = ""):
		Specification.__init__(self, name = name)	# base class constructor
		self.Else = Specification(name = name)     # same for Else part
		self.isTrue = True
		self.configNames = set()            #
		self.variableNames = set()          # TO DO: Condition class
		self.variableValues = {}            #

	def __str__(self, prefix = ""):
		s = "<filter name='%s'>\n"% self.name
		s += "<if config='%s'>\n" % " | ".join(self.configNames)
		s += Specification.__str__(self)
		s += "</if>\n <else>\n"
		s += str(self.Else)
		s += " </else>\n</filter>\n"
		return s


	def SetConfigCondition(self, configName):
		self.configNames = set([configName])

	def AddConfigCondition(self, configName):
		self.configNames.add(configName)


	def SetVariableCondition(self, variableName, variableValues):
		self.variableNames = set([variableName])
		if type(variableValues) == types.ListType:
			self.variableValues[variableName] = set(variableValues)
		else:
			self.variableValues[variableName] = set([variableValues])

	def AddVariableCondition(self, variableName, variableValues):
		self.variableNames.add(variableName)
		if type(variableValues) == types.ListType:
			self.variableValues[variableName] = set(variableValues)
		else:
			self.variableValues[variableName] = set([variableValues])


	def Configure(self, buildUnit, cache):
		self.isTrue = False

		if buildUnit.name in self.configNames:
			self.isTrue = True
		elif self.variableNames:

			evaluator = Evaluator(self.parentSpec, buildUnit, cache=cache)

			for variableName in self.variableNames:
				variableValue = evaluator.Get(variableName)

				if variableValue in self.variableValues[variableName]:
					self.isTrue = True
					break

		# configure all the children too
		for spec in self.GetChildSpecs():
			spec.Configure(buildUnit, cache=cache)


	def HasInterface(self):
		if self.isTrue:
			return Specification.HasInterface(self)
		else:
			return self.Else.HasInterface()


	def GetInterface(self, cache):
		if self.isTrue:
			return Specification.GetInterface(self, cache = cache)
		else:
			return self.Else.GetInterface(cache = cache)


	def GetVariants(self, cache):
		if self.isTrue:
			return Specification.GetVariants(self, cache = cache)
		else:
			return self.Else.GetVariants(cache = cache)


	def SetParentSpec(self, parent):
		# base class method
		Specification.SetParentSpec(self, parent)
		# same for Else part
		self.Else.SetParentSpec(parent)


	def GetChildSpecs(self):
		if self.isTrue:
			return Specification.GetChildSpecs(self)
		else:
			return self.Else.GetChildSpecs()


class Parameter(Model):

	def __init__(self, name = None, default = None):
		Model.__init__(self)	# base class constructor
		self.name = name
		self.default = default


	def SetProperty(self, name, value):
		if name == "name":
			self.name = value
		elif name == "default":
			self.default = value
		else:
			raise InvalidPropertyError()


	def Valid(self):
		return (self.name != None)

class ParameterGroup(Model):
	"""A group of Parameters specified in an interface by a regexp"""
	def __init__(self, pattern = None, default = None):
		Model.__init__(self)	# base class constructor
		self.pattern = pattern

		self.patternre = None
		if pattern:
			try:
				self.patternre = re.compile(pattern)
			except TypeError:
				pass
		self.default = default


	def SetProperty(self, pattern, value):
		if pattern == "pattern":
			self.pattern = value
			self.patternre = re.compile(value)
		elif pattern == "default":
			self.default = value
		else:
			raise InvalidPropertyError()


	def Valid(self):
		return (self.pattern != None and self.patternre != None)


class Operation(Model):
	"Base class for variant operations"
	__slots__ = 'type'
	def __init__(self):
		Model.__init__(self)	# base class constructor
		self.type = None

	def Apply(self, oldValue):
		pass


class Append(Operation):
	__slots__ = ('name', 'value', 'separator')
	def __init__(self, name = None, value = None, separator = " "):
		Operation.__init__(self)	# base class constructor
		self.name = name
		self.value = value
		self.separator = separator


	def __str__(self):
		attributes = "name='" + self.name + "' value='" + self.value + "' separator='" + self.separator + "'"
		return "<append %s/>" % attributes


	def Apply(self, oldValue):
		if len(oldValue) > 0:
			if len(self.value) > 0:
				return oldValue + self.separator + self.value
			else:
				return oldValue
		else:
			return self.value


	def SetProperty(self, name, value):
		if name == "name":
			self.name = value
		elif name == "value":
			self.value = value
		elif name == "separator":
			self.separator = value
		else:
			raise InvalidPropertyError()


	def Valid(self):
		return (self.name != None and self.value != None)


class Prepend(Operation):
	__slots__ = ('name', 'value', 'separator')
	def __init__(self, name = None, value = None, separator = " "):
		Operation.__init__(self)	# base class constructor
		self.name = name
		self.value = value
		self.separator = separator


	def __str__(self, prefix = ""):
		attributes = "name='" + self.name + "' value='" + self.value + "' separator='" + self.separator + "'"
		return "<prepend %s/>" % prefix


	def Apply(self, oldValue):
		if len(oldValue) > 0:
			if len(self.value) > 0:
				return self.value + self.separator + oldValue
			else:
				return oldValue
		else:
			return self.value


	def SetProperty(self, name, value):
		if name == "name":
			self.name = value
		elif name == "value":
			self.value = value
		elif name == "separator":
			self.separator = value
		else:
			raise InvalidPropertyError()


	def Valid(self):
		return (self.name != None and self.value != None)


class Set(Operation):
	__slots__ = ('name', 'value', 'type', 'versionCommand', 'versionResult')
	"""implementation of <set> operation"""

	def __init__(self, name = None, value = "", type = ""):
		Operation.__init__(self)	# base class constructor
		self.name = name
		self.value = value
		self.type = type
		self.versionCommand = ""
		self.versionResult = ""


	def __str__(self):
		attributes = "name='" + self.name + "' value='" + self.value + "' type='" + self.type + "'"
		if type == "tool":
			attributes += " versionCommand='" + self.versionCommand + "' versionResult='" + self.versionResult

		return "<set %s/>" % attributes


	def Apply(self, oldValue):
		return self.value


	def SetProperty(self, name, value):
		if name == "name":
			self.name = value
		elif name == "value":
			self.value = value
		elif name == "type":
			self.type = value
		elif name == "versionCommand":
			self.versionCommand = value
		elif name == "versionResult":
			self.versionResult = value
		elif name == "host":
			if HostPlatform.IsKnown(value):
				self.host = value
		else:
			raise InvalidPropertyError()


	def Valid(self):
		return (self.name != None and self.value != None)

class BadToolValue(Exception):
	pass

class Env(Set):
	"""implementation of <env> operator"""

	def __init__(self, name = None, default = None, type = ""):
		Set.__init__(self, name, "", type)	# base class constructor
		self.default = default


	def __str__(self):
		attributes = "name='" + self.name + "' type='" + self.type + "'"
		if self.default != None:
			attributes += " default='" + self.default + "'"

		if type == "tool":
			attributes += " versionCommand='" + self.versionCommand + "' versionResult='" + self.versionResult + "'"

		return "<env %s/>" % attributes


	def Apply(self, oldValue):
		try:
			value = os.environ[self.name]
			
			if value:
				if self.type in ["path", "tool", "toolchainpath"]:
					# if this value is some sort of path or tool then we need to make sure
					# it is a proper absolute path in our preferred format.
					try:
						path = generic_path.Path(value)
						value = str(path.Absolute())
					except ValueError,e:
						raise BadToolValue("the environment variable %s is incorrect: %s" % (self.name, str(e)))
					
					if self.type in ["tool", "toolchainpath"]:
						# if  we're dealing with tool-related values, then make sure that we can get "safe"
						# versions if they contain spaces - if we can't, that's an error, as they won't
						# survive full usage in the toolcheck or when used and/or referenced in FLMs						
						if ' ' in value:
							path = generic_path.Path(value)
							spaceSafeValue = path.GetSpaceSafePath()
						
							if not spaceSafeValue:
								raise BadToolValue("the environment variable %s is incorrect - it is a '%s' type but contains spaces that cannot be neutralised: %s" % (self.name, self.type, value))
							
							value = spaceSafeValue	
				elif value.endswith('\\'):
					# if this value ends in an un-escaped backslash, then it will be treated as a line continuation character
					# in makefile parsing - un-escaped backslashes at the end of values are therefore escaped					
					count = len(value) - len(value.rstrip('\\'))	# an odd number of backslashes means there's one to escape
					if count % 2:
						value += '\\'	
		except KeyError:
			if self.default != None:
				value = self.default
			else:
				raise BadToolValue("%s is not set in the environment and has no default" % self.name)

		return value


	def SetProperty(self, name, value):
		if name == "default":
			self.default = value
		else:
			Set.SetProperty(self, name, value)


	def Valid(self):
		return (self.name != None)


class BuildUnit(object):
	"Represents an individual buildable unit."

	def __init__(self, name, variants):
		self.name = name
		
		# A list of Variant objects.
		self.variants = variants

		# Cache for the variant operations implied by this BuildUnit.
		self.operations = []
		self.variantKey = ""

	def GetOperations(self, cache):
		"""Return all operations related to this BuildUnit.
		
		The result is cached, and so will only be computed once per BuildUnit.
		"""
		key = '.'.join([x.name for x in self.variants])
		if self.variantKey != key:
			self.variantKey = key
			for v in self.variants:
				self.operations.extend( v.GetAllOperationsRecursively(cache=cache) )

		return self.operations

class Config(object):
	"""Abstract type representing an argument to the '-c' option.

	The fundamental property of a Config is that it can generate one or more
	BuildUnits.
	"""

	def __init__(self):
		self.modifiers = []

	def AddModifier(self, variant):
		self.modifiers.append(variant)

	def ClearModifiers(self):
		self.modifiers = []

	def GenerateBuildUnits(self,cache):
		"""Returns a list of BuildUnits.

		This function must be overridden by derived classes.
		"""
		raise NotImplementedError()


class Variant(Model, Config):

	__slots__ = ('cache','name','host','extends','ops','variantRefs','allOperations')

	def __init__(self, name = ""):
		Model.__init__(self)
		Config.__init__(self)
		self.name = name

		# Operations defined inside this variant.
		self.ops = []

		# The name of our parent variant, if any.
		self.extends = ""

		# Any variant references used inside this variant.
		self.variantRefs = []

		self.allOperations = []

	def SetProperty(self, name, value):
		if name == "name":
			self.name = value
		elif name == "host":
			if HostPlatform.IsKnown(value):
				self.host = value
		elif name == "extends":
			self.extends = value
		else:
			raise InvalidPropertyError()

	def AddChild(self, child):
		if isinstance(child, Operation):
			self.ops.append(child)
		elif isinstance(child, VariantRef):
			self.variantRefs.append(child)
		else:
			raise InvalidChildError()

	def Valid(self):
		return self.name

	def AddOperation(self, op):
		self.ops.append(op)

	def GetAllOperationsRecursively(self, cache):
		"""Returns a list of all operations in this variant.

		The list elements are themselves lists; the overall structure of the
		returned value is:

		[ [ops-from-parent],[ops-from-varRefs], [ops-in-self] ]
		"""

		if not self.allOperations:
			if self.extends:
				parent = cache.FindNamedVariant(self.extends)
				self.allOperations.extend( parent.GetAllOperationsRecursively(cache = cache) )
			for r in self.variantRefs:
				for v in [ r.Resolve(cache = cache) ] + r.GetModifiers(cache = cache):
					self.allOperations.extend( v.GetAllOperationsRecursively(cache = cache) )
			self.allOperations.append(self.ops)

		return self.allOperations

	def GenerateBuildUnits(self,cache):

		name = self.name
		vars = [self]

		for m in self.modifiers:
			name = name + "." + m.name
			vars.append(m)
		return [ BuildUnit(name=name, variants=vars) ]

	def isDerivedFrom(self, progenitor, cache):
		if self.name == progenitor:
			return True

		pname = self.extends
		while pname is not None and pname is not '':
			parent = cache.FindNamedVariant(pname)
			if parent is None:
				break
			if parent.name == progenitor:
				return True
			pname = parent.extends

		return False

	def __str__(self):
		s = "<var name='%s' extends='%s'>\n" % (self.name, self.extends)
		for op in self.ops:
			s +=  str(op) + '\n'
		s += "</var>"
		return s

class VariantRef(Reference):

	def __init__(self, ref=None):
		Reference.__init__(self, ref = ref)

	def __str__(self):
		return "<varRef ref='%s'/>" % self.ref

	def Resolve(self, cache):
		try:
			return cache.FindNamedVariant(self.ref)
		except KeyError:
			raise BadReferenceError(self.ref)

class MissingVariantException(Exception):
	pass

class Alias(Model, Config):

	def __init__(self, name=""):
		Model.__init__(self)
		Config.__init__(self)
		self.name = name
		self.meaning = ""
		self.varRefs = []
		self.variants = []

	def __str__(self):
		return "<alias name='%s' meaning='%s'/>" % (self.name, self.meaning)

	def SetProperty(self, key, val):
		if key == "name":
			self.name = val
		elif key == "meaning":
			self.meaning = val

			for u in val.split("."):
				self.varRefs.append( VariantRef(ref = u) )
		else:
			raise InvalidPropertyError()

	def Valid(self):
		return self.name and self.meaning

	def Resolve(self, cache):
		if not self.variants:
			missing_variants = []
			for r in self.varRefs:
				try:
					self.variants.append( r.Resolve(cache=cache) )
				except BadReferenceError:
					missing_variants.append(r.ref)
				
			if len(missing_variants) > 0:
				raise MissingVariantException("Missing variants '%s'" % " ".join(missing_variants))

	def GenerateBuildUnits(self, cache):
		self.Resolve(cache)

		name = self.name

		for v in self.modifiers:
			name = name + "." + v.name

		return [ BuildUnit(name=name, variants=self.variants + self.modifiers) ]

	def isDerivedFrom(self, progenitor, cache):
		self.Resolve(cache)
		for v in self.variants:
			if v.isDerivedFrom(progenitor,cache):
				return True
		return False

class AliasRef(Reference):

	def __init__(self, ref=None):
		Reference.__init__(self, ref)

	def __str__(self):
		return "<aliasRef ref='%s'/>" % self.ref

	def Resolve(self, cache):
		try:
			return cache.FindNamedAlias(self.ref)
		except KeyError:
			raise BadReferenceError(self.ref)


class Group(Model, Config):
	def __init__(self, name=""):
		Model.__init__(self)
		Config.__init__(self)
		self.name = name
		self.childRefs = []

	def SetProperty(self, key, val):
		if key == "name":
			self.name = val
		else:
			raise InvalidPropertyError()

	def AddChild(self, child):
		if isinstance( child, (VariantRef,AliasRef,GroupRef) ):
			self.childRefs.append(child)
		else:
			raise InvalidChildError()

	def Valid(self):
		return self.name and self.childRefs

	def __str__(self):
		s = "<group name='%s'>" % self.name
		for r in self.childRefs:
			s += str(r)
		s += "</group>"
		return s

	def GenerateBuildUnits(self, cache):
		units = []
		
		missing_variants = []
		for r in self.childRefs:
			try:
				obj = r.Resolve(cache=cache)
			except BadReferenceError:
				missing_variants.append(r.ref)
			else:
				obj.ClearModifiers()
				try:
					refMods = r.GetModifiers(cache)
				except BadReferenceError,e:
					missing_variants.append(str(e))
				else:
					for m in refMods + self.modifiers:
						obj.AddModifier(m)

					units.extend( obj.GenerateBuildUnits(cache) )

		if len(missing_variants) > 0:
			raise MissingVariantException("Missing variants '%s'" % " ".join(missing_variants))

		return units


class GroupRef(Reference):

	def __init__(self, ref=None):
		Reference.__init__(self, ref)

	def __str__(self):
		return "<groupRef ref='%s' mod='%s'/>" % (self.ref, ".".join(self.modifiers))

	def Resolve(self, cache):
		try:
			return cache.FindNamedGroup(self.ref)
		except KeyError:
			raise BadReferenceError(self.ref)

def GetBuildUnits(configNames, cache, logger):
	"""expand a list of config strings like "arm.v5.urel" into a list
	of BuildUnit objects that can be queried for settings.
	
	The expansion tries to be tolerant of errors in the XML so that a
	typo in one part of a group does not invalidate the whole group.
	"""
	
	# turn dot-separated name strings into Model objects (Group, Alias, Variant)
	models = []
		
	for c in set(configNames):
		ok = True
		names = c.split(".")

		base = names[0]
		mods = names[1:]

		if base in cache.groups:
			x = cache.FindNamedGroup(base)
		elif base in cache.aliases:
			x = cache.FindNamedAlias(base)
		elif base in cache.variants:
			x = cache.FindNamedVariant(base)
		else:
			logger.Error("Unknown build configuration '%s'" % base)
			continue

		x.ClearModifiers()

		for m in mods:
			if m in cache.variants:
				x.AddModifier( cache.FindNamedVariant(m) )
			else:
				logger.Error("Unknown build variant '%s'" % m)
				ok = False
				
		if ok:
			models.append(copy.copy(x))

	# turn Model objects into BuildUnit objects
	#
	# all objects have a GenerateBuildUnits method but don't use
	# that for Groups because it is not tolerant of errors (the
	# first error raises an exception and the rest of the group is
	# abandoned)
	units = []
		
	while len(models) > 0:
		x = models.pop()
		try:
			if isinstance(x, (Alias, Variant)):
				# these we just turn straight into BuildUnits
				units.extend(x.GenerateBuildUnits(cache))
			elif isinstance(x, Group):
				# deal with each part of the group separately (later)
				for child in x.childRefs:
					modChild = copy.copy(child)
					modChild.modifiers = child.modifiers + [m.name for m in x.modifiers]
					models.append(modChild)
			elif isinstance(x, Reference):
				# resolve references and their modifiers
				try:
					obj = x.Resolve(cache)
					modObj = copy.copy(obj)
					modObj.modifiers = x.GetModifiers(cache)
				except BadReferenceError,e:
					logger.Error("Unknown reference '%s'" % str(e))
				else:
					models.append(modObj)
		except Exception, e:
			logger.Error(str(e))

	return units
	
class ToolErrorException(Exception):
	def __init__(self, s):
		Exception.__init__(self,s)

class Tool(object):
	"""Represents a tool that might be used by raptor e.g. a compiler"""

	# It's difficult and expensive to give each tool a log reference but a class one
	# will facilitate debugging when that is needed without being a design flaw the
	# rest of the time.
	log = raptor_utilities.nulllog

	# For use in dealing with tools that return non-ascii version strings.
	nonascii = ""
	identity_chartable = chr(0)
	for c in xrange(1,128):
		identity_chartable += chr(c)
	for c in xrange(128,256):
		nonascii += chr(c)
		identity_chartable += " "

	def __init__(self, name, command, versioncommand, versionresult, id=""):
		self.name = name
		self.command = command
		self.versioncommand = versioncommand
		self.versionresult = versionresult
		self.id = id # what config this is from - used in debug messages
		self.date = None


		# Assume the tool is unavailable or the wrong
		# version until someone proves that it's OK
		self.valid = False


	def expand(self, toolset):
		self.versioncommand = toolset.ExpandAll(self.versioncommand)
		self.versionresult  = toolset.ExpandAll(self.versionresult)
		self.command = toolset.ExpandAll(self.command)
		self.key = hashlib.md5(self.versioncommand + self.versionresult).hexdigest()
		
		# We need the tool's date to find out if we should check it.
		try:
			if '/' in self.command:
				testfile = os.path.abspath(self.command.strip("\"'"))
			else:
				# The tool isn't a relative or absolute path so the could be relying on the 
				# $PATH variable to make it available.  We must find the tool if it's a simple 
				# executable file (e.g. "armcc" rather than "python myscript.py") then get it's date. 
				# We can use the date later to see if our cache is valid. 
				# If it really is not a simple command then we won't be able to get a date and
				# we won't be able to tell if it is altered or updated - too bad!
				testfile = generic_path.Where(self.command)
				#self.log.Debug("toolcheck: tool '%s' was found on the path at '%s' ", self.command, testfile)
				if testfile is None:
					raise Exception("Can't be found in path")

			if not os.path.isfile(testfile):
				raise Exception("tool %s appears to not be a file %s", self.command, testfile)
				
			testfile_stat = os.stat(testfile)
			self.date = testfile_stat.st_mtime
		except Exception,e:
			# We really don't mind if the tool could not be dated - for any reason
			Tool.log.Debug("toolcheck: '%s=%s' cannot be dated - this is ok, but the toolcheck won't be able to tell when a new version of the tool is installed. (%s)", self.name, self.command, str(e))
			pass
	
			
	def check(self, shell, evaluator, log = raptor_utilities.nulllog):

		self.vre = re.compile(self.versionresult)

		try:
			self.log.Debug("Pre toolcheck: '%s' for version '%s'", self.name, self.versionresult)
			p = subprocess.Popen(args=[shell, "-c", self.versioncommand], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
			log.Debug("Checking tool '%s' for version '%s'", self.name, self.versionresult)
			versionoutput,err = p.communicate()
		except Exception,e:
			versionoutput=None

		# Some tools return version strings with unicode characters! 
		# There is no good response other than a lot of decoding and encoding.
		# Simpler to ignore it:
		versionoutput_a = versionoutput.translate(Tool.identity_chartable,"")

		if versionoutput_a and self.vre.search(versionoutput_a) != None:
			log.Debug("tool '%s' returned an acceptable version '%s'", self.name, versionoutput_a)
			self.valid = True
		else:
			self.valid = False
			raise ToolErrorException("tool '%s' from config '%s' did not return version '%s' as required.\nCommand '%s' returned:\n%s\nCheck your environment and configuration.\n" % (self.name, self.id, self.versionresult, self.versioncommand, versionoutput_a))

def envhash(irrelevant_vars):
	"""Determine something unique about this environment to identify it.
	must ignore variables that change without mattering to the caller
	e.g. perhaps PATH matters but PWD and PPID don't"""
	envid = hashlib.md5()
	for k in os.environ:
		if k not in irrelevant_vars:
			envid.update(os.environ[k])
	return envid.hexdigest()[:16]


class ToolSet(object):
	""" 
	This class manages a bunch of tools and keeps a cache of
	all tools that it ever sees (across all configurations).
	toolset.check() is called for each config but the cache is kept across calls to
	catch the use of one tool in many configs.
	write() is used to flush the cache to disc.
	"""
	# The raptor shell - this is not mutable.
	if 'SBS_SHELL' in os.environ:
		shell = os.environ['SBS_SHELL']
	else:
		hostbinaries = os.path.join(os.environ['SBS_HOME'], 
	                                os.environ['HOSTPLATFORM_DIR'])
	                            
		if HostPlatform.IsHost('lin*'):
			shell=os.path.join(hostbinaries, 'bin/bash')
		else:
			if 'SBS_CYGWIN' in os.environ:
				shell=os.path.join(os.environ['SBS_CYGWIN'], 'bin\\bash.exe')
			else:
				shell=os.path.join(hostbinaries, 'cygwin\\bin\\bash.exe')


	irrelevant_vars = ['PWD','OLDPWD','PID','PPID', 'SHLVL' ]


	shell_version=".*GNU bash, version [34].*"
	shell_re = re.compile(shell_version)
	if 'SBS_BUILD_DIR' in os.environ:
		cachefile_basename = str(generic_path.Join(os.environ['SBS_BUILD_DIR'],"toolcheck_cache_"))
	elif 'EPOCROOT' in os.environ:
		cachefile_basename = str(generic_path.Join(os.environ['EPOCROOT'],"epoc32/build/toolcheck_cache_"))
	else:
		cachefile_basename = None

	tool_env_id = envhash(irrelevant_vars)
	filemarker = "sbs_toolcache_2.8.2"

	def __init__(self, log = raptor_utilities.nulllog, forced=False):
		self.__toolcheckcache = {}

		self.valid = True
		self.checked = False
		self.shellok = False
		self.configname=""
		self.cache_loaded = False
		self.forced = forced

		self.log=log

		# Read in the tool cache
		#
		# The cache format is a hash key which identifies the
		# command and the version that we're checking for. Then
		# there are name,value pairs that record, e.g. the date
		# of the command file or the name of the variable that
		# the config uses for the tool (GNUCP or MWCC or whatever)

		if ToolSet.cachefile_basename:
			self.cachefilename = ToolSet.cachefile_basename+".tmp"
			if not self.forced:
				try:
					f = open(self.cachefilename, "r+")
					# if this tool cache was recorded in
					# a different environment then ignore it.
					marker = f.readline().rstrip("\r\n")
					if marker == ToolSet.filemarker:
						env_id_tmp = f.readline().rstrip("\r\n")
						if env_id_tmp == ToolSet.tool_env_id:
							try:
								for l in f.readlines():
									toolhistory  = l.rstrip(",\n\r").split(",")
									ce = {}
									for i in toolhistory[1:]:
										(name,val) = i.split("=")
										if name == "valid":
											val = bool(val)
										elif name == "age":
											val = int(val)
										elif name == "date":
											if val != "None":
												val = float(val)
											else:
												val= None

										ce[name] = val
									self.__toolcheckcache[toolhistory[0]] = ce
								log.Info("Loaded toolcheck cache: %s\n", self.cachefilename)
							except Exception, e:
								log.Info("Ignoring garbled toolcheck cache: %s (%s)\n", self.cachefilename, str(e))
								self.__toolcheckcache = {}
									
						else:
							log.Info("Toolcheck cache %s ignored - environment changed\n", self.cachefilename)
					else:
						log.Info("Toolcheck cache not loaded = marker missing: %s %s\n", self.cachefilename, ToolSet.filemarker)
					f.close()
				except IOError, e:
					log.Info("Failed to load toolcheck cache: %s\n", self.cachefilename)
		else:
			log.Debug("Toolcheck cachefile not created because EPOCROOT not set in environment.\n")

	def check_shell(self):
		# The command shell is a critical tool because all the other tools run
		# within it so we must check for it first. It has to be in the path.
		# bash 4 is preferred, 3 is accepted
		try:
			p = subprocess.Popen(args=[ToolSet.shell, '--version'], bufsize=1024, shell = False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
			shellversion_out, errtxt = p.communicate()
			if ToolSet.shell_re.search(shellversion_out) == None:
				self.log.Error("A critical tool, '%s', did not return the required version '%s':\n%s\nPlease check that '%s' is in the path.", ToolSet.shell, ToolSet.shell_version, shellversion_out, ToolSet.shell)
				self.valid = False
		except Exception,e:
			self.log.Error("A critical tool could not be found.\nPlease check that '%s' is in the path. (%s)", ToolSet.shell,  str(e))
			self.valid = False

		return self.valid

	def check(self, evaluator, configname):
		"""Check the toolset for a particular config"""

		self.checked = True # remember that we did check something

		if not self.shellok:
			self.shellok = self.check_shell()
		self.shellok = True

		self.valid = self.valid and self.shellok

		cache = self.__toolcheckcache 
		for tool in evaluator.tools:
			if not self.forced:
				try:
					t = cache[tool.key]
						
				except KeyError,e:
					pass
				else:
					# if the cache has an entry for the tool then see if the date on
					# the tool has changed (assuming the tool is a simple executable file)
					if t.has_key('date') and (tool.date is None or (tool.date - t['date'] > 0.1))  :
						self.log.Debug("toolcheck forced: '%s'  changed since the last check: %s < %s", tool.command, str(t['date']), str(tool.date))
					else:
						t['age'] = 0 # we used it so it's obviously needed
						self.valid = self.valid and t['valid']
						self.log.Debug("toolcheck saved on: '%s'", tool.name)
						continue


			self.log.Debug("toolcheck done: %s -key: %s" % (tool.name, tool.key))

			try:
				tool.check(ToolSet.shell, evaluator, log = self.log)
			except ToolErrorException, e:
				self.valid = False
				self.log.Error("%s\n" % str(e))

			# Tool failures are cached just like successes - don't want to repeat them
			cache[tool.key] =  { "name" : tool.name, "valid" : tool.valid, "age" : 0 , "date" : tool.date }


	def write(self):
		"""Writes the tool check cache to disc.

		   toolset.write()
		"""
		cache = self.__toolcheckcache 

		# Write out the cache.
		if self.checked and ToolSet.cachefile_basename:
			self.log.Debug("Saving toolcache: %s", self.cachefilename)
			try:
				f = open(self.cachefilename, "w+")
				f.write(ToolSet.filemarker+"\n")
				f.write(ToolSet.tool_env_id+"\n")
				for k,ce in cache.iteritems():

					# If a tool has not been used for an extraordinarily long time
					# then forget it - to prevent the cache from clogging up with old tools.
					# Only write entries for tools that were found to be ok - so that the 
					# next time the ones that weren't will be re-tested

					if ce['valid'] and ce['age'] < 100:
						ce['age'] += 1
						f.write("%s," % k)
						for n,v in ce.iteritems():
							f.write("%s=%s," % (n,str(v)))
					f.write("\n")
				f.close()
				self.log.Info("Created/Updated toolcheck cache: %s\n", self.cachefilename)
			except Exception, e:
				self.log.Info("Could not write toolcheck cache: %s", str(e))
		return self.valid

class UninitialisedVariableException(Exception):
	pass

class RecursionException(Exception):
	pass

class Evaluator(object):
	"""Determine the values of variables under different Configurations.
	Either of specification and buildUnit may be None."""


	refRegex = re.compile("\$\((.+?)\)")

	def __init__(self, specification, buildUnit, cache, gathertools = False):
		self.dict = {}
		self.tools = []
		self.gathertools = gathertools
		self.cache = cache

		specName = "none"
		configName = "none"

		# A list of lists of operations.
		opsLists = []

		if buildUnit:
			ol = buildUnit.GetOperations(cache)
			self.buildUnit = buildUnit
			
			opsLists.extend( ol )

		if specification:
			for v in specification.GetAllVariantsRecursively(cache):
				opsLists.extend( v.GetAllOperationsRecursively(cache) )

		tools = {}

		unfound_values = []
		for opsList in opsLists:
			for op in opsList:
				# applying an Operation to a non-existent variable
				# is OK. We assume that it is just an empty string.
				try:
					oldValue = self.dict[op.name]
				except KeyError:
					oldValue = ""

				try:
					newValue = op.Apply(oldValue)
				except BadToolValue, e:
					unfound_values.append(str(e))
					newValue = "NO_VALUE_FOR_" + op.name
					
				self.dict[op.name] = newValue
			
				if self.gathertools:
					if op.type == "tool" and op.versionCommand and op.versionResult:
						tools[op.name] = Tool(op.name, newValue, op.versionCommand, op.versionResult, configName)

		if len(unfound_values) > 0:
			raise UninitialisedVariableException("\n".join(unfound_values))

		if self.gathertools:
			self.tools = tools.values()
		else:
			self.tools=[]

		# resolve inter-variable references in the dictionary
		unresolved = True

		for k, v in self.dict.items():
			self.dict[k] = v.replace("$$","__RAPTOR_ESCAPED_DOLLAR__")

		while unresolved:
			unresolved = False
			for k, v in self.dict.items():
				if v.find('$(' + k + ')') != -1:
						raise RecursionException("Recursion Detected in variable '%s' in configuration '%s' " % (k,configName))
				else:
					expanded = self.ExpandAll(v, specName, configName)

				if expanded != v:				# something changed?
					self.dict[k] = expanded
					unresolved = True			# maybe more to do

		# unquote double-dollar references
		for k, v in self.dict.items():
			self.dict[k] = v.replace("__RAPTOR_ESCAPED_DOLLAR__","$")

		for t in self.tools:
			t.expand(self)



	def Get(self, name):
		"""return the value of variable 'name' or None if not found."""

		if name in self.dict:
			return self.dict[name]
		else:
			return None


	def Resolve(self, name):
		"""same as Get except that env variables are expanded.

		raises BadReferenceError if the variable 'name' exists but a
		contained environment variable does not exist."""
		return self.Get(name) # all variables are now expanded anyway


	def ResolveMatching(self, pattern):
		""" Return a dictionary of all variables that match the pattern """
		for k,v in self.dict.iteritems():
			if pattern.match(k):
				yield (k,v)


	def ExpandAll(self, value, spec = "none", config = "none"):
		"""replace all $(SOMETHING) in the string value.

		returns the newly expanded string."""

		refs = Evaluator.refRegex.findall(value)

		# store up all the unset variables before raising an exception
		# to allow us to find them all
		unset_variables = [] 

		for r in set(refs):
			expansion = None

			if r in self.dict:
				expansion = self.dict[r]
			else:
				# no expansion for $(r)
				unset_variables.append("Unset variable '%s' used in spec '%s' with config '%s'" % (r, spec, config))
			if expansion != None:
				value = value.replace("$(" + r + ")", expansion)

		if len(unset_variables) > 0: # raise them all
			raise UninitialisedVariableException(". ".join(unset_variables))

		return value


# raptor_data module functions


# end of the raptor_data module
