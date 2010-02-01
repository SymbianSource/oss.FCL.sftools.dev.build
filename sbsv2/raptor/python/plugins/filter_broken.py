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
# Example of a Filter class using the SAX parser base class
#

import filter_interface

class FilterBroken(filter_interface.FilterSAX):
	
	def startDocument(self):
		self.first = True
		
	def startElement(self, name, attributes):
		pass
	
	def characters(self, char):
		pass
		
	def endElement(self, name):
		pass
	
	def endDocument(self):
		pass
	
	def error(self, exception):
		pass
		
	def fatalError(self, exception):
		if self.first:
			print "fatal error:", str(exception)
			self.first = False
		
	def warning(self, exception):
		pass
	
# the end
