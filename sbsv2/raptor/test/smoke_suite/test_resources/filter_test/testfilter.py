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
# Filter class to test customised filtering
# Will output a simple message when certain input text is found
#

import sys
import filter_interface


class TestFilter(filter_interface.Filter):
	
	def open(self, raptor_instance):
		return True
		
		
	def write(self, text):
		"""Write a message to stdout to say the test passed"""
		
		if "<info>The make-engine exited successfully.</info>" in text:
			sys.stdout.write("\nTest Passed!\n")
		return True
	
	
	def close(self):
		return True
