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
	t.usebash = True
	result = AntiTargetSmokeTest.PASS
	
	command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c %s -f-"
	maintargets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll"
		]
	abiv1libtargets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.lib"
		]	
	buildtargets =  [
		"createstaticdll_dll/armv5/udeb/CreateStaticDLL.o",
		"createstaticdll_dll/armv5/urel/CreateStaticDLL.o"
		]
	mustmatch = [
		r".*\busrt\d_\d\.lib\b.*",
		r".*\bscppnwdl\.dso\b.*"
			]
	mustnotmatch = [
		".*ksrt.*"
		]
	
	# Note that ABIv1 import libraries are only generated for RVCT-based armv5
	# builds on Windows
	
	t.id = "0009a"
	t.name = "dll_armv5_rvct"
	t.command = command % "armv5"
	t.targets = maintargets[:]	# Shallow, as we optionally extend later and then re-use
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/bld.inf', buildtargets)
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.run("linux")
	if t.result == AntiTargetSmokeTest.SKIP:
		t.targets.extend(abiv1libtargets)
		t.run("windows")
	if t.result == AntiTargetSmokeTest.FAIL:
		result = AntiTargetSmokeTest.FAIL
		
	t.id = "0009b"
	t.name = "dll_armv5_clean"
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c armv5 clean"
	t.targets = []
	t.mustmatch = []
	t.mustnotmatch = []
	t.run()	
	if t.result == AntiTargetSmokeTest.FAIL:
		result = AntiTargetSmokeTest.FAIL		
		
	t.id = "0009c"
	t.name = "dll_armv5_gcce"
	t.command = command % "gcce_armv5"
	t.targets = maintargets
	t.antitargets = abiv1libtargets
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/bld.inf', buildtargets)
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.run()	
	if t.result == AntiTargetSmokeTest.FAIL:
		result = AntiTargetSmokeTest.FAIL
	
	t.id = "9"
	t.name = "dll_armv5"
	t.result = result
	t.print_result()
	return t
