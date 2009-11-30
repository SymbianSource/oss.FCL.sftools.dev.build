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

from raptor_tests import AntiTargetSmokeTest

def run():
	t = AntiTargetSmokeTest()

	rootcommand = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf"
	targets = [
		"$(EPOCROOT)/epoc32/release/armv6/udeb/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv6/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv6/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv6/urel/createstaticdll.dll"
		]
	antitargets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.lib"
		]
	buildtargets = [
		"createstaticdll_dll/armv6/udeb/CreateStaticDLL.o",
		"createstaticdll_dll/armv6/urel/CreateStaticDLL.o",
		"createstaticdll_dll/armv6/udeb/armv6_specific.o",
		"createstaticdll_dll/armv6/urel/armv6_specific.o"
	]
	
	t.id = "0097a"
	t.name = "dll_armv6_rvct"
	t.command = rootcommand + " -c armv6"
	t.targets = targets
	t.antitargets = antitargets
	t.addbuildtargets("smoke_suite/test_resources/simple_dll/bld.inf", buildtargets)
	t.run()

	t.id = "0097b"
	t.name = "dll_armv6_clean"
	t.command = rootcommand + " -c armv6 clean"
	t.targets = []
	t.antitargets = []
	t.run()

	t.id = "0097c"
	t.name = "dll_armv6_gcce"
	t.command = rootcommand + " -c arm.v6.udeb.gcce4_3_2 -c arm.v6.urel.gcce4_3_2"
	t.targets = targets
	t.antitargets = antitargets
	t.addbuildtargets("smoke_suite/test_resources/simple_dll/bld.inf", buildtargets)
	t.run()

	t.id = "97"
	t.name = "dll_armv6"
	t.print_result()
	return t
