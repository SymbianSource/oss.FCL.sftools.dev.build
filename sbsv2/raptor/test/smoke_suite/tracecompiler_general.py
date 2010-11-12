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
	t.description = "Testcases (ID 0101a - 0101d) test trace compiler"
	# General test for trace compiler, which generates
	# 1. trace headers like <source>Traces.h
	# 2. fixed_id.definitions
	# 3. dictionary files like <project name>_<UID>_Dictionary.xml
	# 4. trace definitions like <project name>_<UID>_TraceDefinitions.h
	t.id = "101a"
	t.name = "TC_general"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf -c armv5.tracecompiler"	
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/testTC.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testTC{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/testTC.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/testTC.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testTC.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testTC.dll.map",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitmainTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitpermparserTraces.h",	
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/fixed_id.definitions",
		"$(EPOCROOT)/epoc32/ost_dictionaries/testTC_0x1000008d_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/platform/symbiantraces/autogen/testTC_0x1000008d_TraceDefinitions.h"
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf', [
		"testTC_dll/armv5/udeb/wlanhwinit.o",
		"testTC_dll/armv5/udeb/wlanhwinit.o.d",
		"testTC_dll/armv5/udeb/wlanhwinitmain.o",
		"testTC_dll/armv5/udeb/wlanhwinitmain.o.d",
		"testTC_dll/armv5/udeb/wlanhwinitpermparser.o",
		"testTC_dll/armv5/udeb/wlanhwinitpermparser.o.d",
		"testTC_dll/armv5/udeb/testTC_udeb_objects.via",
		"testTC_dll/armv5/udeb/testTC{000a0000}.def",
		"testTC_dll/armv5/urel/wlanhwinit.o",
		"testTC_dll/armv5/urel/wlanhwinit.o.d",
		"testTC_dll/armv5/urel/wlanhwinitmain.o",
		"testTC_dll/armv5/urel/wlanhwinitmain.o.d",
		"testTC_dll/armv5/urel/wlanhwinitpermparser.o",
		"testTC_dll/armv5/urel/wlanhwinitpermparser.o.d",	
		"testTC_dll/armv5/urel/testTC_urel_objects.via",
		"testTC_dll/armv5/urel/testTC{000a0000}.def",
		"testTC_dll/tracecompile_testTC_dll_1000008d.done"
	])
	t.run()
	
	# General CLEAN test for trace compiler outputs
	t.id = "101b"
	t.name = "TC_general_CLEAN"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf -c armv5.tracecompiler CLEAN"
	t.targets = []	
	t.antitargets = [
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitmainTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitpermparserTraces.h"
		]
	t.addbuildantitargets('smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf', [
		"testtc_dll/tracecompile_testTC_dll_1000008d.done"
	])
	t.run()
			
	t.id = "101c"
	t.name = "TC_bv_path"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/TC_featurevariant/group/bld.inf -c armv5.tracecompiler" 
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/HelloWorld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/HelloWorld.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/HelloWorld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/HelloWorld.exe.map",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/TC_featurevariant/traces/HelloWorldTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/TC_featurevariant/traces/fixed_id.definitions",
		"$(EPOCROOT)/epoc32/ost_dictionaries/HelloWorld_0xe78a5aa3_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/platform/symbiantraces/autogen/HelloWorld_0xe78a5aa3_TraceDefinitions.h"
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/TC_featurevariant/group/bld.inf', [
		"HelloWorld_exe/armv5/udeb/HelloWorld.o",
		"HelloWorld_exe/armv5/udeb/HelloWorld.o.d",
		"HelloWorld_exe/armv5/udeb/HelloWorld_udeb_objects.via",
		"HelloWorld_exe/armv5/urel/HelloWorld.o",
		"HelloWorld_exe/armv5/urel/HelloWorld.o.d",
		"HelloWorld_exe/armv5/urel/HelloWorld_urel_objects.via",
		"HelloWorld_exe/tracecompile_HelloWorld_exe_e78a5aa3.done"
	])
	t.antitargets = []
	t.run()

	# 101d-101f test trace compiler auto mechanism, which is used to avoid wasting time on source 
	# containing no osttraces.
	# Trace compiler only runs when there are osttraces code in source. Raptor decides this by
	# checking whether there is a "traces" or "traces_<prj_name>" folder in USERINCLUDE in a mmp file. 
	t.id = "101d"
	t.name = "TC_autorun1"
	# Run - USERINCLUDE ../traces_autorun1
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf -c armv5.tracecompiler" + \
			" -p autorun1.mmp"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o",
		"test_/tracecompile_test_exe_00000001.done"
	])
	t.antitargets = [] # Currently unnecessary, but helps the code be robust
	t.run()
	
	t.id = "101e"
	t.name = "TC_autorun2"
	# No run - USERINCLUDE ./tracesnotmatch
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf -c armv5.tracecompiler" + \
			" -p autorun2.mmp CLEAN " + \
			"&& sbs -b smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf -c armv5.tracecompiler" + \
			" -p autorun2.mmp"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o",
	])
	t.antitargets = [] # Currently unnecessary, but helps the code be robust
	t.addbuildantitargets('smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf', [
		"test_/tracecompile_test_exe_00000001.done"
	])
	t.run()

	t.id = "101f"
	t.name = "TC_autorun3"
	# No run - no UID
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf -c armv5.tracecompiler" + \
			" -p autorun3.mmp CLEAN " + \
			"&& sbs -b smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf -c armv5.tracecompiler" + \
			" -p autorun3.mmp"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o",
	])
	t.antitargets = []
	t.addbuildantitargets('smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf', [
		"test_/tracecompile_test_exe_00000001.done"
	])
	t.run()

	# Test trace compiler doesn't run when it is switched off
	# Trace compiler switch is off by default. To turn it on use variant ".tracecompiler". 
	t.id = "101g"
	t.name = "TC_switch_off"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf -c armv5.tracecompiler" + \
			" -p autorun1.mmp CLEAN " + \
			"&& sbs -b smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf -c armv5 -p autorun1.mmp"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o"
	])
	t.antitargets = []
	t.addbuildantitargets('smoke_suite/test_resources/tracecompiler/TC_autorun/bld.inf', [
		"test_/tracecompile_test_exe_00000001.done"
	])
	t.run()


	t.id = "101"
	t.name = "tracecompiler_general"
	t.print_result()
	return t

