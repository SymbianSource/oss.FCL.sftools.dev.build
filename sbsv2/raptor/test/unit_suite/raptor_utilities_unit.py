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
# raptor_utilities_unit module
# This module tests the classed forming the Raptor bld.inf and .mmp parsing support
#

import os
import raptor_utilities
import sys
import unittest

class TestRaptorUtilities(unittest.TestCase):
	pass
				
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "raptor_utilities_unit"

	tests = unittest.makeSuite(TestRaptorUtilities)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
