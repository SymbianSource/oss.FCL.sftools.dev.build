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
import os

def run():
	t = SmokeTest()
	
	# tests for building feature variants
	t.id = "56"
	t.name = "featurevariants"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/bv/bld.inf -c armv5 " + \
                "-c armv5.test_bv_1 -c armv5.test_bv_2 -c armv5.test_bv_3 " + \
                "--configpath=test/smoke_suite/test_resources/bv -f-"
	t.targets = [
		# prebuilt files
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dummy.lib",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dummy.lib",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/debfake.lib",
		"$(EPOCROOT)/epoc32/release/armv5/urel/relfake.lib",
		
		# built files
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll_invariant.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll_invariant.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll_invariant.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll_invariant.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll_invariant.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll_invariant.dll.sym",

		"$(EPOCROOT)/epoc32/release/armv5.one/udeb/createstaticdll_variant1.dll",
		"$(EPOCROOT)/epoc32/release/armv5.one/udeb/createstaticdll_variant1.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.one/udeb/createstaticdll_variant1.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.one/udeb/createstaticdll_variant2.dll",
		"$(EPOCROOT)/epoc32/release/armv5.one/udeb/createstaticdll_variant2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.one/udeb/createstaticdll_variant2.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.one/udeb/createexe_variant3.exe.vmap",

		"$(EPOCROOT)/epoc32/release/armv5.one/urel/createstaticdll_variant1.dll",
		"$(EPOCROOT)/epoc32/release/armv5.one/urel/createstaticdll_variant1.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.one/urel/createstaticdll_variant1.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.one/urel/createstaticdll_variant2.dll",
		"$(EPOCROOT)/epoc32/release/armv5.one/urel/createstaticdll_variant2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.one/urel/createstaticdll_variant2.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.one/urel/createexe_variant3.exe.vmap",

		"$(EPOCROOT)/epoc32/release/armv5.two/udeb/createstaticdll_variant1.dll",
		"$(EPOCROOT)/epoc32/release/armv5.two/udeb/createstaticdll_variant1.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.two/udeb/createstaticdll_variant1.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.two/udeb/createstaticdll_variant2.dll",
		"$(EPOCROOT)/epoc32/release/armv5.two/udeb/createstaticdll_variant2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.two/udeb/createstaticdll_variant2.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.two/udeb/createexe_variant3.exe.vmap",
		
		"$(EPOCROOT)/epoc32/release/armv5.two/urel/createstaticdll_variant1.dll",
		"$(EPOCROOT)/epoc32/release/armv5.two/urel/createstaticdll_variant1.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.two/urel/createstaticdll_variant1.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.two/urel/createstaticdll_variant2.dll",
		"$(EPOCROOT)/epoc32/release/armv5.two/urel/createstaticdll_variant2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.two/urel/createstaticdll_variant2.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.two/urel/createexe_variant3.exe.vmap",

		"$(EPOCROOT)/epoc32/release/armv5.three/udeb/createstaticdll_variant1.dll",
		"$(EPOCROOT)/epoc32/release/armv5.three/udeb/createstaticdll_variant1.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.three/udeb/createstaticdll_variant1.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.three/udeb/createstaticdll_variant2.dll",
		"$(EPOCROOT)/epoc32/release/armv5.three/udeb/createstaticdll_variant2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.three/udeb/createstaticdll_variant2.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.three/udeb/createexe_variant3.exe.vmap",
		
		"$(EPOCROOT)/epoc32/release/armv5.three/urel/createstaticdll_variant1.dll",
		"$(EPOCROOT)/epoc32/release/armv5.three/urel/createstaticdll_variant1.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.three/urel/createstaticdll_variant1.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.three/urel/createstaticdll_variant2.dll",
		"$(EPOCROOT)/epoc32/release/armv5.three/urel/createstaticdll_variant2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5.three/urel/createstaticdll_variant2.dll.vmap",
		"$(EPOCROOT)/epoc32/release/armv5.three/urel/createexe_variant3.exe.vmap",

		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll_invariant.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll_invariant{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll_variant1.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll_variant1{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll_variant2.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll_variant2{000a0000}.dso",

		"$(EPOCROOT)/epoc32/data/z/resource/apps/dummy_var1.rsc",
		"$(EPOCROOT)/epoc32/include/dummy_var1.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/dummy_var2.rsc",
		"$(EPOCROOT)/epoc32/include/dummy_var2.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/dummy_var3.rsc",
		"$(EPOCROOT)/epoc32/include/dummy_var3.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/dummy_inv.rsc",
		"$(EPOCROOT)/epoc32/include/dummy_inv.rsg"
		]
	t.addbuildtargets('smoke_suite/test_resources/bv/bld.inf', [
		"createstaticdll_invariant_dll/armv5/udeb/CreateStaticDLL_invariant.o",
		"createstaticdll_invariant_dll/armv5/udeb/CreateStaticDLL_invariant.o.d",
		"createstaticdll_invariant_dll/armv5/udeb/createstaticdll_invariant_udeb_objects.via",
		"createstaticdll_invariant_dll/armv5/udeb/createstaticdll_invariant{000a0000}.def",
		"createstaticdll_invariant_dll/armv5/udeb/createstaticdll_invariant{000a0000}.dso",
		"createstaticdll_invariant_dll/armv5/urel/CreateStaticDLL_invariant.o",
		"createstaticdll_invariant_dll/armv5/urel/CreateStaticDLL_invariant.o.d",
		"createstaticdll_invariant_dll/armv5/urel/createstaticdll_invariant_urel_objects.via",
		"createstaticdll_invariant_dll/armv5/urel/createstaticdll_invariant{000a0000}.def",
		"createstaticdll_invariant_dll/armv5/urel/createstaticdll_invariant{000a0000}.dso",
		
		"dummy_inv_dll/dummy_inv__resource_apps_sc.rpp",
		"dummy_inv_dll/dummy_inv__resource_apps_sc.rpp.d",
		"dummy_var1_dll/dummy_var1__resource_apps_sc.rpp",
		"dummy_var1_dll/dummy_var1__resource_apps_sc.rpp.d",
		"dummy_var2_dll/dummy_var2__resource_apps_sc.rpp",
		"dummy_var2_dll/dummy_var2__resource_apps_sc.rpp.d",
		"dummy_var3_exe/dummy_var3__resource_apps_sc.rpp",
		"dummy_var3_exe/dummy_var3__resource_apps_sc.rpp.d",
		
		
		"createstaticdll_variant1_dll/armv5.one/udeb/CreateStaticDLL_variant1.o",
		"createstaticdll_variant1_dll/armv5.one/udeb/CreateStaticDLL_variant1.o.d",
		"createstaticdll_variant1_dll/armv5.one/udeb/createstaticdll_variant1_udeb_objects.via",
		"createstaticdll_variant1_dll/armv5.one/udeb/createstaticdll_variant1{000a0000}.def",
		"createstaticdll_variant1_dll/armv5.one/udeb/createstaticdll_variant1{000a0000}.dso",
		"createstaticdll_variant1_dll/armv5.one/urel/CreateStaticDLL_variant1.o",
		"createstaticdll_variant1_dll/armv5.one/urel/CreateStaticDLL_variant1.o.d",
		"createstaticdll_variant1_dll/armv5.one/urel/createstaticdll_variant1_urel_objects.via",
		"createstaticdll_variant1_dll/armv5.one/urel/createstaticdll_variant1{000a0000}.def",
		"createstaticdll_variant1_dll/armv5.one/urel/createstaticdll_variant1{000a0000}.dso",
		
		"createstaticdll_variant2_dll/armv5.one/udeb/CreateStaticDLL_variant2.o",
		"createstaticdll_variant2_dll/armv5.one/udeb/CreateStaticDLL_variant2.o.d",
		"createstaticdll_variant2_dll/armv5.one/udeb/createstaticdll_variant2_udeb_objects.via",
		"createstaticdll_variant2_dll/armv5.one/udeb/createstaticdll_variant2{000a0000}.def",
		"createstaticdll_variant2_dll/armv5.one/udeb/createstaticdll_variant2{000a0000}.dso",
		"createstaticdll_variant2_dll/armv5.one/urel/CreateStaticDLL_variant2.o",
		"createstaticdll_variant2_dll/armv5.one/urel/CreateStaticDLL_variant2.o.d",
		"createstaticdll_variant2_dll/armv5.one/urel/createstaticdll_variant2_urel_objects.via",
		"createstaticdll_variant2_dll/armv5.one/urel/createstaticdll_variant2{000a0000}.def",
		"createstaticdll_variant2_dll/armv5.one/urel/createstaticdll_variant2{000a0000}.dso",
		
		"createexe_variant3_exe/armv5.one/udeb/CreateEXE_variant3.o",
		"createexe_variant3_exe/armv5.one/udeb/CreateEXE_variant3.o.d",
		"createexe_variant3_exe/armv5.one/udeb/createexe_variant3_udeb_objects.via",
		"createexe_variant3_exe/armv5.one/urel/CreateEXE_variant3.o",
		"createexe_variant3_exe/armv5.one/urel/CreateEXE_variant3.o.d",
		"createexe_variant3_exe/armv5.one/urel/createexe_variant3_urel_objects.via",
		
		
		"createstaticdll_variant1_dll/armv5.two/udeb/CreateStaticDLL_variant1.o",
		"createstaticdll_variant1_dll/armv5.two/udeb/CreateStaticDLL_variant1.o.d",
		"createstaticdll_variant1_dll/armv5.two/udeb/createstaticdll_variant1_udeb_objects.via",
		"createstaticdll_variant1_dll/armv5.two/udeb/createstaticdll_variant1{000a0000}.def",
		"createstaticdll_variant1_dll/armv5.two/udeb/createstaticdll_variant1{000a0000}.dso",
		"createstaticdll_variant1_dll/armv5.two/urel/CreateStaticDLL_variant1.o",
		"createstaticdll_variant1_dll/armv5.two/urel/CreateStaticDLL_variant1.o.d",
		"createstaticdll_variant1_dll/armv5.two/urel/createstaticdll_variant1_urel_objects.via",
		"createstaticdll_variant1_dll/armv5.two/urel/createstaticdll_variant1{000a0000}.def",
		"createstaticdll_variant1_dll/armv5.two/urel/createstaticdll_variant1{000a0000}.dso",
		
		"createstaticdll_variant2_dll/armv5.two/udeb/CreateStaticDLL_variant2.o",
		"createstaticdll_variant2_dll/armv5.two/udeb/CreateStaticDLL_variant2.o.d",
		"createstaticdll_variant2_dll/armv5.two/udeb/createstaticdll_variant2_udeb_objects.via",
		"createstaticdll_variant2_dll/armv5.two/udeb/createstaticdll_variant2{000a0000}.def",
		"createstaticdll_variant2_dll/armv5.two/udeb/createstaticdll_variant2{000a0000}.dso",
		"createstaticdll_variant2_dll/armv5.two/urel/CreateStaticDLL_variant2.o",
		"createstaticdll_variant2_dll/armv5.two/urel/CreateStaticDLL_variant2.o.d",
		"createstaticdll_variant2_dll/armv5.two/urel/createstaticdll_variant2_urel_objects.via",
		"createstaticdll_variant2_dll/armv5.two/urel/createstaticdll_variant2{000a0000}.def",
		"createstaticdll_variant2_dll/armv5.two/urel/createstaticdll_variant2{000a0000}.dso",
		
		"createexe_variant3_exe/armv5.two/udeb/CreateEXE_variant3.o",
		"createexe_variant3_exe/armv5.two/udeb/CreateEXE_variant3.o.d",
		"createexe_variant3_exe/armv5.two/udeb/createexe_variant3_udeb_objects.via",
		"createexe_variant3_exe/armv5.two/urel/CreateEXE_variant3.o",
		"createexe_variant3_exe/armv5.two/urel/CreateEXE_variant3.o.d",
		"createexe_variant3_exe/armv5.two/urel/createexe_variant3_urel_objects.via",
		
		
		"createstaticdll_variant1_dll/armv5.three/udeb/CreateStaticDLL_variant1.o",
		"createstaticdll_variant1_dll/armv5.three/udeb/CreateStaticDLL_variant1.o.d",
		"createstaticdll_variant1_dll/armv5.three/udeb/createstaticdll_variant1_udeb_objects.via",
		"createstaticdll_variant1_dll/armv5.three/udeb/createstaticdll_variant1{000a0000}.def",
		"createstaticdll_variant1_dll/armv5.three/udeb/createstaticdll_variant1{000a0000}.dso",
		"createstaticdll_variant1_dll/armv5.three/urel/CreateStaticDLL_variant1.o",
		"createstaticdll_variant1_dll/armv5.three/urel/CreateStaticDLL_variant1.o.d",
		"createstaticdll_variant1_dll/armv5.three/urel/createstaticdll_variant1_urel_objects.via",
		"createstaticdll_variant1_dll/armv5.three/urel/createstaticdll_variant1{000a0000}.def",
		"createstaticdll_variant1_dll/armv5.three/urel/createstaticdll_variant1{000a0000}.dso",
		
		"createstaticdll_variant2_dll/armv5.three/udeb/CreateStaticDLL_variant2.o",
		"createstaticdll_variant2_dll/armv5.three/udeb/CreateStaticDLL_variant2.o.d",
		"createstaticdll_variant2_dll/armv5.three/udeb/createstaticdll_variant2_udeb_objects.via",
		"createstaticdll_variant2_dll/armv5.three/udeb/createstaticdll_variant2{000a0000}.def",
		"createstaticdll_variant2_dll/armv5.three/udeb/createstaticdll_variant2{000a0000}.dso",
		"createstaticdll_variant2_dll/armv5.three/urel/CreateStaticDLL_variant2.o",
		"createstaticdll_variant2_dll/armv5.three/urel/CreateStaticDLL_variant2.o.d",
		"createstaticdll_variant2_dll/armv5.three/urel/createstaticdll_variant2_urel_objects.via",
		"createstaticdll_variant2_dll/armv5.three/urel/createstaticdll_variant2{000a0000}.def",
		"createstaticdll_variant2_dll/armv5.three/urel/createstaticdll_variant2{000a0000}.dso",
		
		"createexe_variant3_exe/armv5.three/udeb/CreateEXE_variant3.o",
		"createexe_variant3_exe/armv5.three/udeb/CreateEXE_variant3.o.d",
		"createexe_variant3_exe/armv5.three/udeb/createexe_variant3_udeb_objects.via",
		"createexe_variant3_exe/armv5.three/urel/CreateEXE_variant3.o",
		"createexe_variant3_exe/armv5.three/urel/CreateEXE_variant3.o.d",
		"createexe_variant3_exe/armv5.three/urel/createexe_variant3_urel_objects.via"
	])
	# Test that static libs are linked from the invariant place.
	t.mustmatch = [
		"armlink.*epoc32/release/armv5/urel/bv_static_lib.lib",
		"armlink.*epoc32/release/armv5/udeb/bv_static_lib.lib"
	]
	t.run()
	
	
	# tests for the createvmap script
	createvmap = "python $(SBS_HOME)/bin/createvmap.py"
	vmapfile = "$(EPOCROOT)/epoc32/build/test.vmap"
	vmap = " -o " + vmapfile
	
	if 'SBS_BVCPP' in os.environ:
		bvcpp = " -c " + os.environ['SBS_BVCPP']
	else:
		bvcpp = " -c $(SBS_HOME)/$(HOSTPLATFORM_DIR)/bv/bin/cpp"
		if t.onWindows:
			bvcpp += ".exe"

	bvdata = "$(SBS_HOME)/test/smoke_suite/test_resources/bv"
	
	preinc = " -p " + bvdata + "/var1/var1.h"
	listA = " -f " + bvdata + "/listA.txt"
	listB = " -f " + bvdata + "/listB.txt"
	listC = " -f " + bvdata + "/listC.txt"
	srcWith = " -s " + bvdata + "/with_macros.cpp"
	srcWithout = " -s " + bvdata + "/without_macros.cpp"
	badSrc = " -s " + bvdata + "/with_errors.cpp"

	t.id = "56a"
	t.name = "createvmap exits with an error"
	t.usebash = True
	t.command = createvmap
	t.returncode = 1
	t.targets = []
	t.mustmatch = []
	t.run()

	
	t.id = "56b"
	t.name = "createvmap shows cpp errors"
	t.usebash = True
	t.command = createvmap + vmap + bvcpp + preinc + listA + badSrc
	t.returncode = 1
	t.targets = []
	t.mustmatch = ["#error this code is broken"]
	t.run()
	
	
	t.id = "56c"
	t.name = "createvmap errors on missing feature list"
	t.usebash = True
	t.command = createvmap + vmap + bvcpp + preinc + listC + srcWith
	t.returncode = 1
	t.targets = []
	t.mustmatch = ["The feature list '.*listC.txt' does not exist"]
	t.run()
	
	
	t.id = "56d"
	t.name = "createvmap warns on featureless code"
	t.usebash = True
	t.command = createvmap + vmap + bvcpp + preinc + listA + srcWithout
	t.returncode = 0
	t.targets = [vmapfile]
	t.mustmatch = ["warning: No feature macros were found in the source"]
	t.run()
	
	
	t.id = "56e"
	t.name = "createvmap creates the right vmap file"
	t.usebash = True
	t.command = createvmap + vmap + bvcpp + preinc + listA + listB + srcWith + srcWithout + " && cat " + vmapfile
	t.returncode = 0
	t.targets = [vmapfile]
	t.mustmatch = ["A_1=defined", "B_1000=undefined"]
	t.run()
	
	
	# print the overall result
	t.id = "56"
	t.name = "featurevariants"
	t.print_result()
	return t
