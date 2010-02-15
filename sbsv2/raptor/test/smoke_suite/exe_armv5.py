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
	t.usebash = True
	result = SmokeTest.PASS

	description = """This test is testing 2 states of keywords, DEBUGGABLE on its own and with DEBUGGABLE_UDEBONLY together; in their mmp's
			make a new mmp change the target so that it generates another exe, and search together with that exe name when testing second test"""
	command = "sbs -b smoke_suite/test_resources/simple/bld.inf -b smoke_suite/test_resources/simple/debuggable_bld.inf -c %s -m ${SBSMAKEFILE} -f ${SBSLOGFILE} && " + \
			"grep -i '.*elf2e32.*--debuggable.*' ${SBSLOGFILE};"
	targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/debuggable.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/debuggable.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/debuggable.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/debuggable.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/debuggable.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/debuggable.exe.map"
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
	mustmatch = [
		".*elf2e32.*urel.*test.exe.*--debuggable.*",
		".*elf2e32.*udeb.*test.exe.*--debuggable.*",
		".*elf2e32.*udeb.*debuggable.exe.*--debuggable.*"
	]
	mustnotmatch = [
		".*elf2e32.*urel.*debuggable.exe.*--debuggable.*"
	]
	warnings = 1
	
	t.id = "0001a"
	t.name = "exe_armv5_rvct"
	t.description = description
	t.command = command % "armv5"
	t.targets = targets
	t.addbuildtargets("smoke_suite/test_resources/simple/bld.inf", buildtargets)
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.warnings = warnings
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
		
	t.id = "0001b"
	t.name = "exe_armv5_clean"
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 clean"
	t.targets = []
	t.mustmatch = []
	t.mustnotmatch = []
	t.warnings = 0
	t.run()	
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL	
	

	t.id = "0001c"
	t.name = "exe_armv5_gcce"
	t.command = command % "gcce_armv5"
	t.targets = targets
	t.addbuildtargets("smoke_suite/test_resources/simple/bld.inf", buildtargets)
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.warnings = warnings
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL	


	# Test for the Check Filter to ensure that it reports 
	# missing files properly when used from sbs_filter.py:
	import os
	abs_epocroot = os.path.abspath(os.environ["EPOCROOT"])
	t.id = "0001d"
	t.command = "rm $(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map; sbs_filter  --filters=FilterCheck < ${SBSLOGFILE}"
	t.targets = []
	t.mustmatch = ["MISSING:[ 	]+" + abs_epocroot.replace("\\","\\\\") + ".epoc32.release.armv5.udeb.test\.exe\.map.*"]
	t.mustnotmatch = []
	t.warnings = 1
	t.returncode = 2
	t.run()

	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL	
	t.id = "1"
	t.name = "exe_armv5"
	t.result = result
	t.print_result()
	return t
