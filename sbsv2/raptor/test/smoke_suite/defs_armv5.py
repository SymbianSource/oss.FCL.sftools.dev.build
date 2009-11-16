#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
	t.id = "21"
	t.name = "defs_armv5"
	t.command = "sbs -b smoke_suite/test_resources/defs/group/bld.inf -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/deftest.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/deftest.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/deftest{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/deftest.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/deftest.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/deftest.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/deftest.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/deftest.dll.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/defs/group/bld.inf', [
		"deftest_/armv5/udeb/deftest_udeb_objects.via",
		"deftest_/armv5/udeb/test.o",
		"deftest_/armv5/urel/deftest_urel_objects.via",
		"deftest_/armv5/urel/test.o"
	])
	t.run()
	return t
