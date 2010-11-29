#
# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "28"
	t.name = "armv5_testcode"
	t.command = "sbs -b smoke_suite/test_resources/simple_test/bld.inf -c " + \
			"armv5.test -f - "
	
	# Don't allow -f to be appended
	t.logfileOption = lambda :""
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/urel/simple_test_auto.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/simple_test_manual.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/simple_test_auto.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/simple_test_manual.exe",
		"$(EPOCROOT)/epoc32/include/testexportheader.h",
		"$(EPOCROOT)/epoc32/data/z/test/smoke_suite_test_resources_simple_test/armv5.auto.bat",
		"$(EPOCROOT)/epoc32/data/z/test/smoke_suite_test_resources_simple_test/armv5.manual.bat"
		]
	t.mustmatch = [".*/epoc32/data/z/test/smoke_suite_test_resources_simple_test/armv5.auto.bat</build>.*"]
	t.run()
	return t
