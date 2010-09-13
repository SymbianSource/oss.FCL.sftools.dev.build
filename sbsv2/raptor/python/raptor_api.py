#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
# raptor_api module
#
# Python API for Raptor. External code should interact with Raptor via this
# module only, as it is the only programatic interface considered public. The
# command line --query option is also implemented using this module.

# constants
ALL = 1

# objects

class Reply(object):
	"""object to return values from API calls.
	"""
	def __init__(self, text="", raptor=None):
		self._raptor = raptor
		self.text = text
		
	def _getEvaluator(self, meaning):
		""" Note: Will pass on Evaluator constructor exceptions """
		try:
			return self.__evaluator
		except AttributeError:	
			# create an evaluator for the named configuration
			tmp = raptor_data.Alias("tmp")
			tmp.SetProperty("meaning", meaning)
		
			units = tmp.GenerateBuildUnits(self._raptor.cache)
			self.__evaluator = self._raptor.GetEvaluator(None, units[0])
			return self.__evaluator
	
	def __str__(self):
		name = type(self).__name__.lower()
		
		string = "<" + name
		children = []
		longend = False
		
		for attribute,value in self.__dict__.items():
			if attribute != "text" and not attribute.startswith('_'):
				if isinstance(value, Reply):
					children.append(value)
				elif isinstance(value, list):
					for item in value:
						if isinstance(item, Reply):
							children.append(item)
						else:
							raise BadReply(str(item)+" is not a Reply object")
				else:
					if value != None: # skip attributes whose value is None
						string += " %s='%s'" % (attribute, value)
		
		if children or self.text:
			string += ">"
			longend = True
		
		if self.text:
			string += self.text
			children.sort()
			# Note mixing sortable and unsortable lists results in
			# sort not working, so if you really need your
			# children to come out in the right order, put them in
			# a list.  This is only for niceness, where it works.
		
		if children:
			string += "\n"
				
			for c in children:
				clines = str(c).rstrip().split("\n")
				string += "".join(map(lambda l:"  "+l+"\n",clines))
			
		if longend:
			string += "</%s>\n" % name
		else:	
			string += "/>\n"
		
		return string

	
class BadReply(Exception):
	pass

class Alias(Reply):
	def __init__(self, name, meaning):
		super(Alias,self).__init__()
		self.name = name
		self.meaning = meaning
	
	def __cmp__(self, other):
		""" Add __cmp__ to enable comparisons between two Alias objects based upon name."""
		return cmp(self.name, other.name)

class Config(Reply):
	def __init__(self, raptor, name, text = None):
		""" Constructor to create a Config from a user-supplied name.
		possibly including aliases (but not groups)
		"""
		super(Config,self).__init__(text, raptor)

		self.query = name
		
		# Work out the real name
		names = name.split(".")
		if names[0] in self._raptor.cache.aliases:
			x = self._raptor.cache.FindNamedAlias(names[0])
			
			if len(names) > 1:
				self.meaning = x.meaning + "." + ".".join(names[1:])
			else:
				self.meaning = x.meaning
				
		elif names[0] in self._raptor.cache.variants:
			self.meaning = name
			
		else:
			raise BadQuery("'%s' is not an alias or a variant" % names[0])
		
	def resolveOutputPath(self):
		""" Get the outputpath """
		try:
			evaluator = self._getEvaluator(self.meaning)
			# This is messy as some configs construct the path inside the FLM
			# rather than talking it from the XML: usually because of some
			# conditional logic... but maybe some refactoring could avoid that.
			releasepath = evaluator.Get("RELEASEPATH")
			if not releasepath:
				raise BadQuery("could not get RELEASEPATH for config '%s'" % self.fullname)
		
			variantplatform = evaluator.Get("VARIANTPLATFORM")
			varianttype = evaluator.Get("VARIANTTYPE")
			featurevariantname = evaluator.Get("FEATUREVARIANTNAME")
		
			platform = evaluator.Get("TRADITIONAL_PLATFORM")
		
			if platform == "TOOLS2":
				self.outputpath = releasepath
			else:
				if not variantplatform:
					raise BadQuery("could not get VARIANTPLATFORM for config '%s'" % self.fullname)
			
				if featurevariantname:
					variantplatform += featurevariantname
				
				if not varianttype:
					raise BadQuery("could not get VARIANTTYPE for config '%s'" % self.fullname)
			
				self.outputpath = str(generic_path.Join(releasepath, variantplatform, varianttype))
		except Exception, e: # Unable to determine output path
			self.text = str(e)

	def resolveMetadata(self):
		try:
			metadata = self.metadata
		except AttributeError:
			metadata = MetaData(self.meaning, self._raptor)
			self.metadata = metadata
			
		try:
			metadata.resolve()
		except Exception:
			# Evaluator exception hopefully - already handled
			self.metadata = None

	def resolveBuild(self):
		try:
			build = self.build
		except AttributeError:
			build = Build(self.meaning, self._raptor)
			self.build = build
			
		try:
			build.resolve()
		except Exception:
			# Evaluator exception, hopefully - already handled
			self.build = None
	
	def resolveTargettypes(self):
		try:
			build = self.build
		except AttributeError:	
			build = Build(self.meaning, self._raptor)
			self.build = build
		
		try:
			build.resolveTargettypes()
		except Exception:
			# Evaluator exception hopefully - already handled
			self.build = None

class MetaData(Reply):
	def __init__(self, meaning, raptor):
		super(MetaData,self).__init__("", raptor)
		self.__meaning = meaning

	def resolve(self):
		includepaths = []
		preincludeheader = ""
		platmacros = []

		evaluator = self._getEvaluator(self.__meaning)

		# Initialise data and metadata objects
		buildunits = raptor_data.GetBuildUnits([self.__meaning], self._raptor.cache, self._raptor)
		metareader = raptor_meta.MetaReader(self._raptor, buildunits)
		metadatafile = raptor_meta.MetaDataFile(generic_path.Path("bld.inf"), "cpp", [], None, self._raptor)
		
		# There is only one build platform here; obtain the pre-processing include paths,
		# OS pre-include file, compiler pre-include file and macros.			
		includepaths = metadatafile.preparePreProcessorIncludePaths(metareader.BuildPlatforms[0])
		preincludeheader = metareader.BuildPlatforms[0]['VARIANT_HRH']
		
		# Macros arrive as a a list of strings, or a single string, containing definitions of the form "name" or "name=value". 
		platmacrolist = metadatafile.preparePreProcessorMacros(metareader.BuildPlatforms[0])
		platmacros.extend(map(lambda macrodef: [macrodef.partition("=")[0], macrodef.partition("=")[2]], platmacrolist))

		# Add child elements to appropriate areas if they were calculated
		if len(includepaths) > 0:
			self.includepaths = map(lambda x: Include(str(x)), includepaths)
		
		if preincludeheader != "":
			self.preincludeheader = PreInclude(str(preincludeheader))
		
		if len(platmacros):
			self.platmacros = map(lambda x: Macro(x[0],x[1]) if x[1] else Macro(x[0]), platmacros)

class Build(Reply):
	def __init__(self, meaning, raptor):
		super(Build,self).__init__("", raptor)
		self.__meaning = meaning
		
	def resolve(self):
		compilerpreincludeheader = ""
		sourcemacros = []

		evaluator = self._getEvaluator(self.__meaning)

		platform = evaluator.Get("TRADITIONAL_PLATFORM")
			
		# Compiler preinclude files may or may not be present, depending on the configuration.
		if evaluator.Get("PREINCLUDE"):
			compilerpreincludeheader = generic_path.Path(evaluator.Get("PREINCLUDE"))
			
		# Macros arrive as a a list of strings, or a single string, containing definitions of the form "name" or "name=value". 
		# If required, we split to a list, and then processes the constituent parts of the macro.
		sourcemacrolist = evaluator.Get("CDEFS").split()
		sourcemacros.extend(map(lambda macrodef: [macrodef.partition("=")[0], macrodef.partition("=")[2]], sourcemacrolist))

		if platform == "TOOLS2":
			# Source macros are determined in the FLM for tools2 builds, therefore we have to
			# mimic the logic here
			if 'win' in raptor.hostplatform or 'win32' in self.__meaning:
				sourcemacrolist = evaluator.Get("CDEFS.WIN32").split()
			else:
				sourcemacrolist = evaluator.Get("CDEFS.LINUX").split()
			sourcemacros.extend(map(lambda macrodef: [macrodef.partition("=")[0], macrodef.partition("=")[2]], sourcemacrolist))

		if len(sourcemacros):
			self.sourcemacros = map(lambda x: Macro(x[0],x[1]) if x[1] else Macro(x[0]), sourcemacros)
			
		if compilerpreincludeheader:
			self.compilerpreincludeheader = PreInclude(str(compilerpreincludeheader))

	def resolveTargettypes(self):
		evaluator = self._getEvaluator(self.__meaning)
		targettypes = evaluator.Get("TARGET_TYPES").split(' ')
		self.targettypes = []
		for type in targettypes:
			self.targettypes.append(TargetType(type))
		self.targettypes.sort()	

class TargetType(Reply):
	def __init__(self, name):
		super(TargetType,self).__init__()
		self.name = name

	def __cmp__(self, other):
		return cmp(self.name, other.name)

class Product(Reply):
	def __init__(self, name):
		super(Product,self).__init__()
		self.name = name
	
	def __cmp__(self, other):
		""" Add __cmp__ to enable comparisons between two Product objects based upon name."""
		return cmp(self.name, other.name)

class Include(Reply):
	def __init__(self, path):
		super(Include,self).__init__()
		self.path = path

class PreInclude(Reply):
	def __init__(self, file):
		super(PreInclude,self).__init__()
		self.file = file

class Macro(Reply):
	def __init__(self, name, value=None):
		super(Macro,self).__init__()
		self.name = name
		self.value = value

import generic_path
import raptor
import raptor_data
import raptor_meta
import re

class Context(object):
	"""object to contain state information for API calls.
	
	For example,
	
	api = raptor_api.Context()
	val = api.getaliases("X")
	"""
	def __init__(self, initialiser=None):
		# this object has a private Raptor object that can either be
		# passed in or created internally.
		
		if initialiser == None:
			self.__raptor = raptor.Raptor()
		else:
			self.__raptor = initialiser
			
	def stringquery(self, query):
		"""turn a string into an API call and execute it.
		
		This is a convenience method for "lazy" callers.
		
		The return value is also converted into a well-formed XML string.
		"""
		
		if query == "aliases":
			aliases = self.getaliases()
			return "".join(map(str, aliases)).strip()
		
		elif query == "products":
			variants = self.getproducts()
			return "".join(map(str, variants)).strip()
		
		elif query.startswith("config"):
			match = re.match("config\[(.*)\]", query)
			if match:
				config = self.getconfig(match.group(1))
				return str(config).strip()
			else:
				raise BadQuery("syntax error")
		
		raise BadQuery("unknown query")

	def getaliases(self, type=""):
		"""extract all aliases of a given type.
		
		the default type is "".
		to get all aliases pass type=ALL
		"""
		aliases = []
		
		for a in self.__raptor.cache.aliases.values():
			if type == ALL or a.type == type:
				# copy the members we want to expose
				aliases.append( Alias(a.name, a.meaning) )
		aliases.sort()	
		return aliases
	
	def getconfig(self, name):
		"""extract the values for a given configuration.
		
		'name' should be an alias or variant followed optionally by a
		dot-separated list of variants. For example "armv5_urel" or
		"armv5_urel.savespace.vasco".
		"""

		config = Config(self.__raptor, name)
		config.resolveOutputPath()
		config.resolveTargettypes()
		config.resolveMetadata()
		config.resolveBuild()
		return config		
		
	def getproducts(self):
		"""extract all product variants."""
		
		variants = []
		
		for v in self.__raptor.cache.variants.values():
			if v.type == "product":
				# copy the members we want to expose
				variants.append( Product(v.name) )
		variants.sort()	
		return variants
	
class BadQuery(Exception):
	pass

# end of the raptor_api module
