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
from raptor_tests import ReplaceEnvs
import os

def run():
	# Generate source files for simple_lib tests
	dir = ReplaceEnvs("$(SBS_HOME)/test/smoke_suite/test_resources/simple_lib")
	zs = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
	for i in range(1, 100):
		file = open(os.path.join(dir, zs + "_" + str(i) + ".cpp"), "w")
		file.write("int f(void) { return 1; }\n")
		file.close()

	# Convenience method to list generated source build output
	def __generatedFiles(aConfig):
		udeb = "etest_lib/%s/udeb/" % aConfig
		urel = "etest_lib/%s/urel/" % aConfig
	
		generated = []
		for i in range(1, 100):
			generated.append(udeb + zs + "_" + str(i) + ".o")
			generated.append(udeb + zs + "_" + str(i) + ".o.d")
			generated.append(urel + zs + "_" + str(i) + ".o")
			generated.append(urel + zs + "_" + str(i) + ".o.d")
		return generated
		
	t = SmokeTest()
	result = SmokeTest.PASS
	
	armv5targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/etest.lib",
		"$(EPOCROOT)/epoc32/release/armv5/urel/etest.lib"
		]
	armv5buildtargets = [
		"etest_lib/armv5/udeb/etest_udeb_objects.via",
		"etest_lib/armv5/udeb/test_lib.o",
		"etest_lib/armv5/urel/etest_urel_objects.via",
		"etest_lib/armv5/urel/test_lib.o"
		]
	armv5buildtargets.extend(__generatedFiles("armv5"))
		
	t.id = "0013a"
	t.name = "lib_armv5_rvct"
	t.command = "sbs -b smoke_suite/test_resources/simple_lib/bld.inf -c armv5 LIBRARY"
	t.targets = armv5targets
	t.addbuildtargets('smoke_suite/test_resources/simple_lib/bld.inf', armv5buildtargets)
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
		
	t.id = "0013b"
	t.name = "lib_armv5_clean"
	t.command = "sbs -b smoke_suite/test_resources/simple_lib/bld.inf -c armv5 clean"
	t.targets = []
	t.run()	
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	t.id = "0013c"
	t.name = "lib_armv5_gcce"
	t.command = "sbs -b smoke_suite/test_resources/simple_lib/bld.inf -c gcce_armv5 LIBRARY"
	t.targets = armv5targets
	t.addbuildtargets('smoke_suite/test_resources/simple_lib/bld.inf', armv5buildtargets)
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	t.name = "lib_armv7"
	t.id = "0013d"
	t.command = "sbs -b smoke_suite/test_resources/simple_lib/bld.inf -c armv7 LIBRARY"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv7/udeb/etest.lib",
		"$(EPOCROOT)/epoc32/release/armv7/urel/etest.lib"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_lib/bld.inf', [
		"etest_lib/armv7/udeb/etest_udeb_objects.via",
		"etest_lib/armv7/udeb/test_lib.o",
		"etest_lib/armv7/urel/etest_urel_objects.via",
		"etest_lib/armv7/urel/test_lib.o"
	])
	t.addbuildtargets('smoke_suite/test_resources/simple_lib/bld.inf', __generatedFiles("armv7"))
	
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	

	t.id = "13"
	t.name = "lib_armv5_armv7"
	t.result = result
	t.print_result()
	return t
