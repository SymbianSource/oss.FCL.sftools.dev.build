#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
	
	buildtargets = [
		"etest_lib/x86/udeb/etest_udeb_objects.via",
		"etest_lib/x86/udeb/test_lib.o",
		"etest_lib/x86/urel/etest_urel_objects.via",
		"etest_lib/x86/urel/test_lib.o"
		]
	buildtargets.extend(__generatedFiles("x86"))	
		
	t = SmokeTest()
	t.name = "lib_x86"
	t.description = "Build a basic LIB TARGETTYPE for x86"
	t.command = "sbs -b smoke_suite/test_resources/simple_lib/bld.inf -c x86"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/x86/udeb/etest.lib",
		"$(EPOCROOT)/epoc32/release/x86/urel/etest.lib"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_lib/bld.inf', buildtargets)
	
	t.run("windows")
	return t
