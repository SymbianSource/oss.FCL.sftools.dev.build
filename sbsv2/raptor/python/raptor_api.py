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
	def __init__(self, text=""):
		self.text = text
	
	def __str__(self):
		name = type(self).__name__.lower()
		
		string = "<" + name
		children = []
		longend = False
		
		for attribute,value in self.__dict__.items():
			if attribute != "text":
				if isinstance(value, Reply):
					children.append(value)
				else:
					string += " %s='%s'" % (attribute, value)
		
		if children or self.text:
			string += ">"
			longend = True
		
		if self.text:
			string += self.text
		
		if children:
			string += "\n"
				
		for c in children:
			string += str(c)
			
		if longend:
			string += "</%s>\n" % name
		else:	
			string += "/>\n"
		
		return string

class Alias(Reply):
	def __init__(self, name, meaning):
		super(Alias,self).__init__()
		self.name = name
		self.meaning = meaning

class Config(Reply):
	def __init__(self, fullname, outputpath):
		super(Config,self).__init__()
		self.fullname = fullname
		self.outputpath = outputpath

class Product(Reply):
	def __init__(self, name):
		super(Product,self).__init__()
		self.name = name

import generic_path
import raptor
import raptor_data
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
			
		return aliases
	
	def getconfig(self, name):
		"""extract the values for a given configuration.
		
		'name' should be an alias or variant followed optionally by a
		dot-separated list of variants. For example "armv5_urel" or
		"armv5_urel.savespace.vasco".
		"""
		names = name.split(".")
		if names[0] in self.__raptor.cache.aliases:
			x = self.__raptor.cache.FindNamedAlias(names[0])
			
			if len(names) > 1:
				fullname = x.meaning + "." + ".".join(names[1:])
			else:
				fullname = x.meaning
				
		elif names[0] in self.__raptor.cache.variants:
			fullname = name
			
		else:
			raise BadQuery("'%s' is not an alias or a variant" % names[0])
		
		# create an evaluator for the named configuration
		tmp = raptor_data.Alias("tmp")
		tmp.SetProperty("meaning", fullname)
		
		units = tmp.GenerateBuildUnits(self.__raptor.cache)
		evaluator = self.__raptor.GetEvaluator(None, units[0])
		
		# get the outputpath
		# this is messy as some configs construct the path inside the FLM
		# rather than talking it from the XML: usually because of some
		# conditional logic... but maybe some refactoring could avoid that.
		releasepath = evaluator.Get("RELEASEPATH")
		if not releasepath:
			raise BadQuery("could not get RELEASEPATH for config '%s'" % name)
		
		variantplatform = evaluator.Get("VARIANTPLATFORM")
		varianttype = evaluator.Get("VARIANTTYPE")
		featurevariantname = evaluator.Get("FEATUREVARIANTNAME")
		
		platform = evaluator.Get("TRADITIONAL_PLATFORM")
		
		if platform == "TOOLS2":
			outputpath = releasepath
		else:
			if not variantplatform:
				raise BadQuery("could not get VARIANTPLATFORM for config '%s'" % name)
			
			if featurevariantname:
				variantplatform += featurevariantname
				
			if not varianttype:
				raise BadQuery("could not get VARIANTTYPE for config '%s'" % name)
			
			outputpath = str(generic_path.Join(releasepath, variantplatform, varianttype))
		
		return Config(fullname, outputpath)
		
	def getproducts(self):
		"""extract all product variants."""
		
		variants = []
		
		for v in self.__raptor.cache.variants.values():
			if v.type == "product":
				# copy the members we want to expose
				variants.append( Product(v.name) )
			
		return variants
	
class BadQuery(Exception):
	pass

# end of the raptor_api module
