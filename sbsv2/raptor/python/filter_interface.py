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
# Base Class for defining filter classes
# All filter classes that get defined should derive from this base class
#

class Filter(object):
	
	def open(self, params):
		return False
	
	def write(self, text):
		return False

	def summary(self):
		return False
	
	def close(self):
		return False
	
	def formatError(self, message):
		return "sbs: error: " + message + "\n"
		
	def formatWarning(self, message):
		return "sbs: warning: " + message + "\n"	

	def parseNamedParams(self, names, params):
		''' Match named parameters e.g. ['a=b','c=d'] against a list of expected
		names.  Allow for abbreviations.
		'''
		r = {}
		
		# Shorten all the names so they match abbreviations
		shortnames = []

		for name in names:
			shortname = ""
			conflict = True
			while len(shortname)<len(name) and conflict:
				shortname+=name[len(shortname)]
				conflict = False
				othernames = names[:] # Copy
				othernames.remove(name)
				for othername in othernames:
					if othername.startswith(shortname):
						conflict = True
						break
				if conflict == False:
					shortnames.append((shortname,name))
					r[name] = [] # Prime the hash key for this param
			if conflict:
				raise KeyError("Parameter name '{0}' duplicated".format(name))

		# Parse the params
		for param in params:
			if '=' in param:
				(key,value) = param.split('=')
				matched = False
				for (shortname, name) in shortnames:
					if key.strip().startswith(shortname):
						r[name].append(value.strip())
						matched = True
						break
				if not matched:
					raise ValueError("Named parameter '{0}' not valid in filter {1}".format(key,self.__class__.__name__))
			else:
				# Unnamed arg
				if not '' in names:
					raise ValueError("All parameters to the {0} filter must be named".format(self.__class__.__name__))
				else:
					r[''].append(param.strip())
		return r	
			
import sys
import xml.sax

class FilterSAX(Filter, xml.sax.handler.ContentHandler, xml.sax.handler.ErrorHandler):
	"base class for filters using a SAX parser"
	
	# define these methods in your subclass
	
	def startDocument(self):
		"called once before any elements are seen"
		pass
		
	def startElement(self, name, attributes):
		"called on the opening of any element"
		pass
	
	def characters(self, char):
		"called one or more times with body text from an element"
		pass
		
	def endElement(self, name):
		"called on the closing of any element"
		pass
	
	def endDocument(self):
		"called once when all elements are closed"
		pass

	def error(self, exception):
		"the parse found an error which is (possibly) recoverable"
		pass
		
	def fatalError(self, exception):
		"the parser thinks an error occurred which should stop everything"
		pass
		
	def warning(self, exception):
		"the parser found something to complain about that might not matter"
		pass
		
	# these methods are from the Filter base class
	
	def open(self, params):
		"initialise"
		
		self.params = params

		self.parser = xml.sax.make_parser(['xml.sax.expatreader'])
		self.parser.setContentHandler(self)
		self.parser.setErrorHandler(self)
		
		self.ok = True

		return self.ok
			
	def write(self, text):
		"process some log text"
		if self.ok:
			self.parser.feed(text)
		return self.ok

	def close(self):
		"finish off"
		try:
			self.parser.close()
		except Exception, ex:
			sys.stderr.write(self.formatError(str(ex)))
			self.ok = False
			
		return self.ok
	
class RaptorLogNotValid(Exception):
	pass

class PerRecipeFilter(FilterSAX):
	# Define this in your class
	def handleRecipe(self):
		# These variables are available to you:
		# self.name
		# self.target
		# self.host
		# self.layer
		# self.component
		# self.bldinf
		# self.mmp
		# self.config
		# self.platform
		# self.phase
		# self.source
		# self.prereqs
		# self.text
		# self.exit
		# self.attempt (final attempt number)
		# self.flags
		# self.start
		# self.elapsed

		return False
	
	# Helper functions
	def formatData(self, key, hash='self'):
		'''Output prettifier - return the attribute value, or just return 'undef' if the attribute is not set.'''

		if hash=='self':
			hash=self.__dict__
		if hash.has_key(key):
			return hash[key]
		else:
			return 'undef'
	
	# data keys
	recipeData = set(['name','target','host','layer','component','bldinf','mmp','config','platform','phase','source','prereqs'])
	statusData = set(['exit','attempt','flags'])
	timeData = set(['start','elapsed'])

	# methods from the SAX parser
	def startDocument(self):
		self.inRecipe = False
		self.text = ""

	def startElement(self, name, attributes):
		if name == "recipe":
			if self.inRecipe:
				self.error(RaptorLogNotValid("Nested recipes; {0} recipe for {1} inside {2} recipe for {3}".format(self.formatData('name', hash=attributes), self.formatData('target',hash=attributes), self.formatData('name'), self.formatData('target') )))
			else:
				self.inRecipe = True
				self.__setHashElements(attributes, self.__dict__, self.recipeData )		
		elif self.inRecipe:
			if name == "status":
				self.__setHashElements(attributes, self.__dict__, self.statusData)
			elif name == "time":
				self.__setHashElements(attributes, self.__dict__, self.timeData)
			else:
				self.error(RaptorLogNotValid("Unexpected <{0}> tag in {1} recipe for {2}".format(name, self.formatData('name'), self.formatData('target'))))
	
	def endElement(self, name):
		if name == "recipe":
			if not self.inRecipe:
				self.error(RaptorLogNotValid("Extra recipe close tag"))
			else:
				if not self.handleRecipe():
					self.error(RaptorLogNotValid('Handling of {0} recipe for {1} failed'.format(self.formatData('name'), self.formatData('target'))))
				self.inRecipe = False
				
				self.__delData(self.recipeData|self.statusData|self.timeData)
				self.text=""

	def characters(self, char):
		if self.inRecipe:
			self.text += char

	def error(self, exception):
		"the parse found an error which is (possibly) recoverable"
		pass
		
	def fatalError(self, exception):
		"the parser thinks an error occurred which should stop everything"
		pass
		
	def warning(self, exception):
		"the parser found something to complain about that might not matter"
		pass

	# Private methods
	def __setHashElements(self, fro, to, keys):
		for key in keys:
			if fro.has_key(key):
				to[key] = fro[key]

	def __delData(self, keys):
		for key in keys:
			if self.__dict__.has_key(key):
				del self.__dict__[key]

# the end
