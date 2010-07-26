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
# Filter class for testing the filter framework by creatnig an exception
#

import os
import sys
import raptor
import filter_interface

class FilterTestCrash(filter_interface.Filter):

	def open(self, raptor_instance):
		"""Open a log file for the various I/O methods to write to."""
		self.counter = 0
		return True

	def write(self, text):
		"""Write text into the log file"""

		self.counter += 1
		if self.counter == 10:
			raise Exception("A test exception in a filter was generated on line %d of the log\n" % self.counter)
		

		return True

	def summary(self):
		return False

	def close(self):
		return False
