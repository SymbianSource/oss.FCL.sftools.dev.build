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

def run():
	t = SmokeTest()
	t.description = """Raptor should keep going and build as much as possible with the -k option specified."""
	
	command = "sbs -b smoke_suite/test_resources/simple/bld.inf -k"
	config = " --configpath=test/smoke_suite/test_resources/keepgoing"
	targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.sym"
		]	
	buildtargets = [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o",
		"test_/armv5/udeb/test.o.d",
		"test_/armv5/udeb/test3.o.d",
		"test_/armv5/udeb/test4.o.d",
		"test_/armv5/udeb/test5.o.d",
		"test_/armv5/udeb/test1.o.d",
		"test_/armv5/udeb/test6.o.d",
		"test_/armv5/udeb/test2.o.d",
		"test_/armv5/udeb/test3.o",
		"test_/armv5/udeb/test4.o",
		"test_/armv5/udeb/test5.o",
		"test_/armv5/udeb/test1.o",
		"test_/armv5/udeb/test6.o",
		"test_/armv5/udeb/test2.o",
		"test_/armv5/urel/test.o.d",
		"test_/armv5/urel/test3.o.d",
		"test_/armv5/urel/test4.o.d",
		"test_/armv5/urel/test5.o.d",
		"test_/armv5/urel/test1.o.d",
		"test_/armv5/urel/test6.o.d",
		"test_/armv5/urel/test2.o.d",
		"test_/armv5/urel/test3.o",
		"test_/armv5/urel/test4.o",
		"test_/armv5/urel/test5.o",
		"test_/armv5/urel/test1.o",
		"test_/armv5/urel/test6.o",
		"test_/armv5/urel/test2.o",
		"test_/armv5/udeb/test_udeb_objects.via",
		"test_/armv5/urel/test_urel_objects.via"
		]
	
	# using a non-existent config with -c should build any independent configs
	t.id = "115a"
	t.name = "keepgoing_bad_config"
	t.command = command + " -c armv5 -c armv5.bogus"
	t.targets = targets
	t.addbuildtargets("smoke_suite/test_resources/simple/bld.inf", buildtargets)
	t.mustmatch = ["sbs: error: Unknown build variant 'bogus'"]
	t.warnings = 0
	t.errors = 1
	t.returncode = 1
	t.run()
	
	# using groups with bad sub-groups should build any independent groups
	t.id = "115b"
	t.name = "keepgoing_bad_subgroup"
	t.command = command + config + " -c lots_of_products"
	t.mustmatch = ["Unknown reference 'qwertyuio'",
	               "Unknown reference 'asdfghjkl'",
	               "Unknown reference 'zxcvbnm_p'"]
	t.warnings = 0
	t.errors = 3
	t.returncode = 1
	t.run()
	
	# using groups with bad sub-sub-groups should build any independent groups
	t.id = "115c"
	t.name = "keepgoing_bad_subsubgroup"
	t.command = command + config + " -c lots_of_products_2"
	t.mustmatch = ["Unknown reference 'qwertyuio'",
	               "Unknown reference 'asdfghjkl'",
	               "Unknown reference 'zxcvbnm_p'"]
	t.warnings = 0
	t.errors = 3
	t.returncode = 1
	t.run()
	
	# summarise	
	t.id = "115"
	t.name = "keepgoing"
	t.print_result()
	return t
