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
		self.ok = True
		try:
			self.parser = xml.sax.make_parser(['xml.sax.expatreader'])
			self.parser.setContentHandler(self)
			self.parser.setErrorHandler(self)
			
		except Exception, ex:
			sys.stderr.write(self.formatError(str(ex)))
			self.ok = False
		
		return self.ok
	
		
	def write(self, text):
		"process some log text"
		try:
			self.parser.feed(text)
		except Exception, ex:
			sys.stderr.write(self.formatError(str(ex)))
			self.ok = False
				
		return self.ok
	

	def close(self):
		"finish off"
		try:
			self.parser.close()
		except Exception, ex:
			sys.stderr.write(self.formatError(str(ex)))
			self.ok = False
			
		return self.ok
	

# the end
