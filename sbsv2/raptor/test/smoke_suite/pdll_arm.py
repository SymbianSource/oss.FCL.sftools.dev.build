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

from raptor_tests import AntiTargetSmokeTest

def run():
	t = AntiTargetSmokeTest()
	t.usebash = True
	
	command = "sbs -b smoke_suite/test_resources/simple_dll/pbld.inf -c %s -f -"
	maintargets = [
		"$(EPOCROOT)/epoc32/release/%s/udeb/createstaticpdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/%s/urel/createstaticpdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/%s/udeb/createstaticpdll.dll",
		"$(EPOCROOT)/epoc32/release/%s/urel/createstaticpdll.dll"
		]
	armv5targets = [
		"$(EPOCROOT)/epoc32/release/%s/lib/createstaticpdll.dso",
		"$(EPOCROOT)/epoc32/release/%s/lib/createstaticpdll{000a0000}.dso"
		]
	buildtargets =  [
		"createstaticpdll_dll/%s/udeb/CreateStaticDLL.o",
		"createstaticpdll_dll/%s/urel/CreateStaticDLL.o"
		]
	mustmatch = [
		r".*\busrt\d_\d\.lib\b.*",
		r".*\bscppnwdl\.dso\b.*"
		]
	mustnotmatch = [
		".*ksrt.*"
		]
	
	t.id = "0109a"
	t.name = "pdll_armv5_rvct"
	t.command = command % "armv5"
	t.targets = map(lambda p: p % "armv5", maintargets + armv5targets)[:]	# Shallow, as we optionally extend later and then re-use
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/pbld.inf', map(lambda p: p % "armv5", buildtargets))
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.run()
		
	t.id = "0109b"
	t.name = "pdll_armv5_clean"
	t.command = command % "armv5" + " clean"
	t.targets = []
	t.mustmatch = []
	t.mustnotmatch = []
	t.run()
	
	t.id = "0109c"
	t.name = "pdll_armv5_gcce"
	t.command = command % "gcce_armv5"
	t.targets = map(lambda p: p % "armv5", maintargets + armv5targets)
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/pbld.inf', map(lambda p: p % "armv5", buildtargets))
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.run()

	t.id = "0109d"
	t.name = "pdll_armv5_gcce_clean"
	t.command = command % "gcce_armv5" + " clean"
	t.targets = []
	t.mustmatch = []
	t.mustnotmatch = []
	t.run()

	t.id = "0109e"
	t.name = "pdll_armv7_rvct"
	t.command = command % "armv7"
	t.targets = map(lambda p: p % "armv7", maintargets)[:]	# Shallow, as we optionally extend later and then re-use
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/pbld.inf', map(lambda p: p % "armv7", buildtargets))
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.run()
	
	t.id = "0109f"
	t.name = "pdll_armv7_clean"
	t.command = command % "armv7" + " clean"
	t.targets = []
	t.mustmatch = []
	t.mustnotmatch = []
	t.run()
	
	t.id = "0109g"
	t.name = "pdll_armv7_gcce"
	t.command = command % "arm.v7.udeb.gcce4_3_2 -c arm.v7.urel.gcce4_3_2"
	t.targets = map(lambda p: p % "armv7", maintargets)
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/pbld.inf', map(lambda p: p % "armv7", buildtargets))
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.run()

	t.id = "109"
	t.name = "pdll_arm"
	t.print_result()
	return t
