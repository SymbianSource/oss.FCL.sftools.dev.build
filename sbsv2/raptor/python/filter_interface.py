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
	
	def open(self, raptor):
		return False
	
	def write(self, text):
		return False

	def summary(self):
		return False
	
	def close(self):
		return False
	
	def formatError(self, message):
		return "sbs: error: " + message + "\n"
