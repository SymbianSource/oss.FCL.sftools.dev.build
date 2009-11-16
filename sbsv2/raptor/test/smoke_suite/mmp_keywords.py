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
	result = SmokeTest.PASS
	t = SmokeTest()
	t.description = "This testcase tests all mmp keywords including new implementation of 'paged/unpaged code/data'"
	t.usebash = True
	t.id = "75a"
	t.name = "mmp_1"
	t.command = "sbs -b smoke_suite/test_resources/mmp/mmp1/group/bld.inf -c armv5 -f-"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/shutdownsrv.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/shutdownsrv.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/shutdownsrv.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/shutdownsrv.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/lib/exportlibrary_shutdownsrv.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/exportlibrary_shutdownsrv{000a0000}.dso",
	]
	t.addbuildtargets("smoke_suite/test_resources/mmp/mmp1/group/bld.inf", [
		"shutdownsrv_dll/armv5/udeb/shutdownsrv.o",
		"shutdownsrv_dll/armv5/urel/shutdownsrv.o",
		"shutdownsrv_dll/armv5/udeb/shutdownsrvpatchdata.o",
		"shutdownsrv_dll/armv5/urel/shutdownsrvpatchdata.o",
		"shutdownsrv_dll/armv5/udeb/shutdowntimer.o",
		"shutdownsrv_dll/armv5/urel/shutdowntimer.o"
		])
	t.mustmatch = [
		".*elf2e32.*(--defaultpaged|--codepaging=default.*--datapaging=default).*",
		".*armlink.*--verbose.*"
	]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	t.id = "75b"
	t.name = "mmp_2"
	t.command = "sbs -b smoke_suite/test_resources/mmp/mmp2/group/bld.inf -c armv5 -f-"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/imageprocessorperf.lib",
		"$(EPOCROOT)/epoc32/release/armv5/urel/imageprocessorperf.lib"		
	]
	t.addbuildtargets("smoke_suite/test_resources/mmp/mmp2/group/bld.inf", [
		"imageprocessorperf_lib/armv5/udeb/ColorConverter.o",
		"imageprocessorperf_lib/armv5/urel/ColorConverter.o",
		"imageprocessorperf_lib/armv5/udeb/ImageProcessor.o",
		"imageprocessorperf_lib/armv5/urel/ImageProcessor.o"
		])
	t.mustmatch = [
		".*armcc.*-O0.*-g.*--cpu 6.*-Otime.*",
		".*armcc.*-O3.*--cpu 6.*-Otime.*",
		".*OPTION ARMASM has no effect.*",
		".*OPTION_REPLACE ARMASM has no effect.*"
	]
	t.mustnotmatch = [
		".*armcc.*--export_all_vtbl.*"
	]
	t.warnings = 2
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	
	t.id = "75c"
	t.name = "mmp_3"
	t.command = "sbs -b smoke_suite/test_resources/mmp/mmp3/bld.inf -c armv5 -c winscw -f-"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/tbm.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/tbm.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/tbm.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/tbm.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/t_oom.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/t_oom.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/t_oom.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/t_oom.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dfpaeabi_vfpv2.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dfpaeabi_vfpv2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dfpaeabi_vfpv2.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dfpaeabi_vfpv2.dll.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_oom.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_oom.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/t_oom.exe"
		]
	t.addbuildtargets("smoke_suite/test_resources/mmp/mmp3/bld.inf", [
		"tbm_exe/armv5/udeb/tbm.o",
		"tbm_exe/armv5/urel/tbm.o",
		"t_oom_exe/armv5/udeb/t_oom.o",
		"t_oom_exe/armv5/urel/t_oom.o",
		"dfpaeabi_vfpv2_dll/armv5/udeb/dfpaeabi.o",
		"dfpaeabi_vfpv2_dll/armv5/urel/dfpaeabi.o",
		"t_oom_exe/winscw/udeb/t_oom.o",
		"t_oom_exe/winscw/udeb/t_oom_UID_.o",
		"t_oom_exe/winscw/urel/t_oom.o",
		"t_oom_exe/winscw/urel/t_oom_UID_.o"
		])
	t.mustmatch = [
		".*armlink.*udeb/eexe.lib.*-o.*armv5/udeb/t_oom.exe.sym.*euser.dso.*efsrv.dso.*estor.dso.*euser.dso.*",
		".*armlink.*urel/eexe.lib.*-o.*armv5/urel/t_oom.exe.sym.*euser.dso.*efsrv.dso.*euser.dso.*",
		".*mwldsym2.*udeb/eexe.lib.*euser.lib.*efsrv.lib.*estor.lib.*euser.lib.*-o.*winscw/udeb/t_oom.exe.*",
		".*mwldsym2.*urel/eexe.lib.*euser.lib.*efsrv.lib.*euser.lib.*-o.*winscw/urel/t_oom.exe.*"
		]
	t.mustnotmatch = []
	t.warnings = 0
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	
	t.id = "75d"
	t.name = "mmp_4"
	t.command = "sbs -b smoke_suite/test_resources/mmp/mmp4/group/bld.inf -c winscw"
	t.targets = [			
		"$(EPOCROOT)/epoc32/release/winscw/udeb/d_newldd.ldd",
		"$(EPOCROOT)/epoc32/release/winscw/urel/d_newldd.ldd",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/d_lddturnaroundtimertest.ldd",
		"$(EPOCROOT)/epoc32/release/winscw/urel/d_lddturnaroundtimertest.ldd",
		"$(EPOCROOT)/epoc32/release/winscw/urel/d_lddturnaroundtimertest.ldd.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/t_sharedio3.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_sharedio3.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_sharedio3.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/t_rbuf.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_rbuf.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_rbuf.exe.map"
		]
	t.addbuildtargets("smoke_suite/test_resources/mmp/mmp4/group/bld.inf", [
		"d_newldd_ldd/winscw/udeb/d_newldd.o",
		"d_newldd_ldd/winscw/udeb/d_newldd.UID.CPP",
		"d_newldd_ldd/winscw/udeb/d_newldd_UID_.o",
		"d_newldd_ldd/winscw/urel/d_newldd.o",
		"d_newldd_ldd/winscw/urel/d_newldd.UID.CPP",
		"d_newldd_ldd/winscw/urel/d_newldd_UID_.o",
		"d_newldd_ldd/winscw/udeb/t_new_classes.o",
		"d_newldd_ldd/winscw/urel/t_new_classes.o",
		"d_lddturnaroundtimertest_ldd/winscw/udeb/d_lddturnaroundtimertest.o",
		"d_lddturnaroundtimertest_ldd/winscw/udeb/d_lddturnaroundtimertest.UID.CPP",
		"d_lddturnaroundtimertest_ldd/winscw/udeb/d_lddturnaroundtimertest_UID_.o",
		"d_lddturnaroundtimertest_ldd/winscw/urel/d_lddturnaroundtimertest.o",
		"d_lddturnaroundtimertest_ldd/winscw/urel/d_lddturnaroundtimertest.UID.CPP",
		"d_lddturnaroundtimertest_ldd/winscw/urel/d_lddturnaroundtimertest_UID_.o",
		"t_sharedio3_exe/winscw/udeb/t_sharedio.o",
		"t_sharedio3_exe/winscw/udeb/t_sharedio3.UID.CPP",
		"t_sharedio3_exe/winscw/udeb/t_sharedio3_UID_.o",
		"t_sharedio3_exe/winscw/urel/t_sharedio.o",
		"t_sharedio3_exe/winscw/urel/t_sharedio3.UID.CPP",
		"t_sharedio3_exe/winscw/urel/t_sharedio3_UID_.o",
		"t_rbuf_exe/winscw/udeb/t_rbuf.o",
		"t_rbuf_exe/winscw/udeb/t_rbuf.UID.CPP",
		"t_rbuf_exe/winscw/udeb/t_rbuf_UID_.o",
		"t_rbuf_exe/winscw/urel/t_rbuf.o",
		"t_rbuf_exe/winscw/urel/t_rbuf.UID.CPP",
		"t_rbuf_exe/winscw/urel/t_rbuf_UID_.o"
		])
	t.mustmatch = []
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	# Test keywords: version, firstlib, nocompresstarget
	t.id = "75e"
	t.name = "mmp_5"
	t.command = "sbs -b smoke_suite/test_resources/mmp/mmp5/bld.inf -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/fuzzv5.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/fuzzv5.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/fuzzlib.lib",
		"$(EPOCROOT)/epoc32/release/armv5/urel/fuzzlib.lib"
		]
	t.addbuildtargets("smoke_suite/test_resources/mmp/mmp5/bld.inf", [
		"fuzzv5_exe/armv5/udeb/fuzzv5.o",
		"fuzzv5_exe/armv5/urel/fuzzv5.o",
		"fuzzlib_lib/armv5/udeb/uc_exe_.cpp",
		"fuzzlib_lib/armv5/urel/uc_exe_.cpp",
		"fuzzlib_lib/armv5/udeb/uc_exe_.o",
		"fuzzlib_lib/armv5/urel/uc_exe_.o",
		])
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	t.id = "75f"
	t.name = "mmp_6"
	t.command = "sbs -b smoke_suite/test_resources/mmp/mmp6_7/bld.inf -c armv5 -k -p diagsuppress.mmp -f-"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/diagsuppress_test.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/diagsuppress_test.dll",
		]

	t.mustmatch = [
					"--diag_suppress 6780",
					"--diag_suppress 6331"
					]

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	t.id = "75g"
	t.name = "mmp_7"
	t.command = "sbs -b smoke_suite/test_resources/mmp/mmp6_7/bld.inf -c armv5 -k -p diagsuppress_noarmlibs.mmp -f-"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/urel/diagsuppress_noarmlibs_test.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/diagsuppress_noarmlibs_test.dll"
		]

	t.mustmatch = ["--diag_suppress 6331"]
	t.mustnotmatch = ["--diag_suppress 6780"]

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# Test keyword: version
	t.id = "75h"
	t.name = "mmp_8"
	t.command = "sbs -b smoke_suite/test_resources/mmp/mmp8/bld.inf"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_mmp_version.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_mmp_version.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test_mmp_version.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test_mmp_version.exe"
		]
	t.mustmatch = []
	t.mustnotmatch = []
	t.warnings = 2
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t.id = "75"
	t.name = "mmp_keywords"
	t.result = result
	t.print_result()
	return t
