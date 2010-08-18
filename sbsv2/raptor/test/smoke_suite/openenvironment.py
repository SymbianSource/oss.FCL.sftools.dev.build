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

from raptor_tests import SmokeTest, getsymbianversion

def run():
	t = SmokeTest()
	t.id = "39"
	t.name = "openenvironment"
	t.description = """Test STDEXE, STDLIB and STDDLL creation; Test open environment project linking against a symbian environment
		library; Test symbian environment project linking against an open environment library"""
	t.usebash = True
	t.command = "sbs -k -b smoke_suite/test_resources/oe/group/bld.inf -c armv5 -c winscw " + \
		"-m ${SBSMAKEFILE} -f ${SBSLOGFILE}; grep -E \"(armlink|checklib|mwldsym2)\" ${SBSLOGFILE}"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/urel/t_oedll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/symbian_test.lib",
		"$(EPOCROOT)/epoc32/release/armv5/urel/t_oeexe.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/t_oelib.lib",
		"$(EPOCROOT)/epoc32/release/armv5/urel/t_oeexe.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/t_oeexe.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/t_oedll.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/t_oedll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/symbian_test.lib",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/t_oeexe.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/t_oelib.lib",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/t_oeexe.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/t_oeexe.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/t_oedll.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/lib/t_oedll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/t_oedll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/winscw/urel/symbian_test.lib",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_oedll.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_oeexe.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_oelib.lib",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_oeexe.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/t_oedll.dll.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/symbian_test.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/t_oedll.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/t_oedll.dll",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/t_oelib.lib"
		]
	t.addbuildtargets('smoke_suite/test_resources/oe/group/bld.inf', [
		"t_oedll_dll/armv5/urel/t_oedll{000a0000}.dso",
		"t_oedll_dll/armv5/urel/t_oedll_urel_objects.via",
		"t_oedll_dll/armv5/urel/t_oedll.o",
		"t_oedll_dll/armv5/urel/t_oedll.o.d",
                # either prep file can exist - luck determines which
                 ['t_oedll_dll/armv5/urel/t_oedll.prep',
                  't_oedll_dll/armv5/udeb/t_oedll.prep'],
		"t_oedll_dll/armv5/urel/t_oedll{000a0000}.def",
		"t_oedll_dll/armv5/udeb/t_oedll{000a0000}.dso",
		"t_oedll_dll/armv5/udeb/t_oedll_udeb_objects.via",
		"t_oedll_dll/armv5/udeb/t_oedll.o",
		"t_oedll_dll/armv5/udeb/t_oedll.o.d",
		"t_oedll_dll/armv5/udeb/t_oedll{000a0000}.def",
		"symbian_test_lib/armv5/urel/symbian_test_urel_objects.via",
		"symbian_test_lib/armv5/urel/symbian_lib.o.d",
		"symbian_test_lib/armv5/urel/symbian_lib.o",
		"symbian_test_lib/armv5/udeb/symbian_test_udeb_objects.via",
		"symbian_test_lib/armv5/udeb/symbian_lib.o.d",
		"symbian_test_lib/armv5/udeb/symbian_lib.o",
		"wrong_newlib_test_oeexe_exe/armv5/urel/wrong_newlib_test_oeexe_urel_objects.via",
		"wrong_newlib_test_oeexe_exe/armv5/urel/t_oeexe.o",
		"wrong_newlib_test_oeexe_exe/armv5/urel/t_oeexe.o.d",
		"wrong_newlib_test_oeexe_exe/armv5/udeb/t_oeexe.o",
		"wrong_newlib_test_oeexe_exe/armv5/udeb/wrong_newlib_test_oeexe_udeb_objects.via",
		"wrong_newlib_test_oeexe_exe/armv5/udeb/t_oeexe.o.d",
		"wrong_newlib_seexe_exe/armv5/urel/wrong_newlib_seexe_urel_objects.via",
		"wrong_newlib_seexe_exe/armv5/urel/wrong_newlib_symbian.o",
		"wrong_newlib_seexe_exe/armv5/urel/wrong_newlib_symbian.o.d",
		"wrong_newlib_seexe_exe/armv5/udeb/wrong_newlib_seexe_udeb_objects.via",
		"wrong_newlib_seexe_exe/armv5/udeb/wrong_newlib_symbian.o",
		"wrong_newlib_seexe_exe/armv5/udeb/wrong_newlib_symbian.o.d",
		"t_oeexe_exe/armv5/urel/t_oeexe_urel_objects.via",
		"t_oeexe_exe/armv5/urel/t_oeexe.o",
		"t_oeexe_exe/armv5/urel/t_oeexe.o.d",
		"t_oeexe_exe/armv5/udeb/t_oeexe.o",
		"t_oeexe_exe/armv5/udeb/t_oeexe.o.d",
		"t_oeexe_exe/armv5/udeb/t_oeexe_udeb_objects.via",
		"t_oelib_lib/armv5/urel/t_oelib_urel_objects.via",
		"t_oelib_lib/armv5/urel/t_oelib.o",
		"t_oelib_lib/armv5/urel/t_oelib.o.d",
		"t_oelib_lib/armv5/udeb/t_oelib.o",
		"t_oelib_lib/armv5/udeb/t_oelib_udeb_objects.via",
		"t_oelib_lib/armv5/udeb/t_oelib.o.d",
		"t_oedll_dll/winscw/urel/t_oedll.dep",
		"t_oedll_dll/winscw/urel/t_oedll.lib",
		"t_oedll_dll/winscw/urel/t_oedll_SYM_.cpp",
		"t_oedll_dll/winscw/urel/t_oedll.dll",
		"t_oedll_dll/winscw/urel/t_oedll_UID_.o",
		"t_oedll_dll/winscw/urel/t_oedll_SYM_.o",
		"t_oedll_dll/winscw/urel/t_oedll.o",
		"t_oedll_dll/winscw/urel/t_oedll_UID_.o.d",
		"t_oedll_dll/winscw/urel/t_oedll.o.d",
		"t_oedll_dll/winscw/urel/t_oedll_UID_.dep",
		"t_oedll_dll/winscw/urel/t_oedll.sym",
		"t_oedll_dll/winscw/urel/t_oedll.UID.CPP",
		"t_oedll_dll/winscw/urel/t_oedll_SYM_.o.d",
		"t_oedll_dll/winscw/urel/t_oedll_SYM_.dep",
                # The prep.def file can be in urel or udeb
                ['t_oedll_dll/winscw/urel/t_oedll.prep.def',
                 't_oedll_dll/winscw/udeb/t_oedll.prep.def'],
		"t_oedll_dll/winscw/urel/t_oedll.def",
		"t_oedll_dll/winscw/urel/t_oedll.inf",
		"t_oedll_dll/winscw/udeb/t_oedll.dep",
		"t_oedll_dll/winscw/udeb/t_oedll.lib",
		"t_oedll_dll/winscw/udeb/t_oedll_SYM_.cpp",
		"t_oedll_dll/winscw/udeb/t_oedll.dll",
		"t_oedll_dll/winscw/udeb/t_oedll_UID_.o",
		"t_oedll_dll/winscw/udeb/t_oedll_SYM_.o",
		"t_oedll_dll/winscw/udeb/t_oedll.o",
		"t_oedll_dll/winscw/udeb/t_oedll_UID_.o.d",
		"t_oedll_dll/winscw/udeb/t_oedll.o.d",
		"t_oedll_dll/winscw/udeb/t_oedll_UID_.dep",
		"t_oedll_dll/winscw/udeb/t_oedll.sym",
		"t_oedll_dll/winscw/udeb/t_oedll.UID.CPP",
		"t_oedll_dll/winscw/udeb/t_oedll_SYM_.o.d",
		"t_oedll_dll/winscw/udeb/t_oedll_SYM_.dep",
		"t_oedll_dll/winscw/udeb/t_oedll.def",
		"t_oedll_dll/winscw/udeb/t_oedll.inf",
		"symbian_test_lib/winscw/urel/symbian_lib.dep",
		"symbian_test_lib/winscw/urel/symbian_lib.o.d",
		"symbian_test_lib/winscw/urel/symbian_lib.o",
		"symbian_test_lib/winscw/udeb/symbian_lib.dep",
		"symbian_test_lib/winscw/udeb/symbian_lib.o.d",
		"symbian_test_lib/winscw/udeb/symbian_lib.o",
		"wrong_newlib_test_oeexe_exe/winscw/urel/wrong_newlib_test_oeexe_UID_.dep",
		"wrong_newlib_test_oeexe_exe/winscw/urel/wrong_newlib_test_oeexe_UID_.o.d",
		"wrong_newlib_test_oeexe_exe/winscw/urel/t_oeexe_wins.dep",
		"wrong_newlib_test_oeexe_exe/winscw/urel/t_oeexe_wins.o",
		"wrong_newlib_test_oeexe_exe/winscw/urel/wrong_newlib_test_oeexe.UID.CPP",
		"wrong_newlib_test_oeexe_exe/winscw/urel/wrong_newlib_test_oeexe_UID_.o",
		"wrong_newlib_test_oeexe_exe/winscw/urel/t_oeexe_wins.o.d",
		"wrong_newlib_test_oeexe_exe/winscw/udeb/wrong_newlib_test_oeexe_UID_.dep",
		"wrong_newlib_test_oeexe_exe/winscw/udeb/wrong_newlib_test_oeexe_UID_.o.d",
		"wrong_newlib_test_oeexe_exe/winscw/udeb/t_oeexe_wins.dep",
		"wrong_newlib_test_oeexe_exe/winscw/udeb/t_oeexe_wins.o",
		"wrong_newlib_test_oeexe_exe/winscw/udeb/wrong_newlib_test_oeexe.UID.CPP",
		"wrong_newlib_test_oeexe_exe/winscw/udeb/wrong_newlib_test_oeexe_UID_.o",
		"wrong_newlib_test_oeexe_exe/winscw/udeb/t_oeexe_wins.o.d",
		"wrong_newlib_seexe_exe/winscw/urel/wrong_newlib_seexe_UID_.dep",
		"wrong_newlib_seexe_exe/winscw/urel/wrong_newlib_seexe_UID_.o",
		"wrong_newlib_seexe_exe/winscw/urel/wrong_newlib_symbian.dep",
		"wrong_newlib_seexe_exe/winscw/urel/wrong_newlib_symbian.o",
		"wrong_newlib_seexe_exe/winscw/urel/wrong_newlib_symbian.o.d",
		"wrong_newlib_seexe_exe/winscw/urel/wrong_newlib_seexe.UID.CPP",
		"wrong_newlib_seexe_exe/winscw/urel/wrong_newlib_seexe_UID_.o.d",
		"wrong_newlib_seexe_exe/winscw/udeb/wrong_newlib_seexe_UID_.dep",
		"wrong_newlib_seexe_exe/winscw/udeb/wrong_newlib_seexe_UID_.o",
		"wrong_newlib_seexe_exe/winscw/udeb/wrong_newlib_symbian.dep",
		"wrong_newlib_seexe_exe/winscw/udeb/wrong_newlib_symbian.o",
		"wrong_newlib_seexe_exe/winscw/udeb/wrong_newlib_symbian.o.d",
		"wrong_newlib_seexe_exe/winscw/udeb/wrong_newlib_seexe.UID.CPP",
		"wrong_newlib_seexe_exe/winscw/udeb/wrong_newlib_seexe_UID_.o.d",
		"t_oeexe_exe/winscw/urel/t_oeexe_UID_.o",
		"t_oeexe_exe/winscw/urel/t_oeexe_UID_.dep",
		"t_oeexe_exe/winscw/urel/t_oeexe_wins.dep",
		"t_oeexe_exe/winscw/urel/t_oeexe_wins.o",
		"t_oeexe_exe/winscw/urel/t_oeexe_UID_.o.d",
		"t_oeexe_exe/winscw/urel/t_oeexe.UID.CPP",
		"t_oeexe_exe/winscw/urel/t_oeexe_wins.o.d",
		"t_oeexe_exe/winscw/udeb/t_oeexe_UID_.o",
		"t_oeexe_exe/winscw/udeb/t_oeexe_UID_.dep",
		"t_oeexe_exe/winscw/udeb/t_oeexe_wins.dep",
		"t_oeexe_exe/winscw/udeb/t_oeexe_wins.o",
		"t_oeexe_exe/winscw/udeb/t_oeexe_UID_.o.d",
		"t_oeexe_exe/winscw/udeb/t_oeexe.UID.CPP",
		"t_oeexe_exe/winscw/udeb/t_oeexe_wins.o.d",
		"t_oelib_lib/winscw/urel/t_oelib.o",
		"t_oelib_lib/winscw/urel/t_oelib.o.d",
		"t_oelib_lib/winscw/urel/t_oelib.dep",
		"t_oelib_lib/winscw/udeb/t_oelib.o",
		"t_oelib_lib/winscw/udeb/t_oelib.o.d",
		"t_oelib_lib/winscw/udeb/t_oelib.dep"
	])
	
	# On 9.4 the open environment checks for
	# mixed symbianc++ and stdc++ new/delete won't fail
	if getsymbianversion() != "9.4":
		t.mustmatch = [
			'.*checklib: error: library .*epoc32.release.armv5.urel.symbian_test.lib is incompatible with standard.*',
			'.*checklib: error: library .*epoc32.release.armv5.urel.t_oelib.lib is incompatible with Symbian.*',
			'.*checklib: error: library .*epoc32.release.armv5.udeb.symbian_test.lib is incompatible with standard.*',
			'.*checklib: error: library .*epoc32.release.armv5.udeb.t_oelib.lib is incompatible with Symbian.*',
			'.*checklib: error: library .*epoc32.release.winscw.urel.symbian_test.lib is incompatible with standard.*',
			'.*checklib: error: library .*epoc32.release.winscw.urel.t_oelib.lib is incompatible with Symbian.*',
			'.*checklib: error: library .*epoc32.release.winscw.udeb.t_oelib.lib is incompatible with Symbian.*',
			'.*checklib: error: library .*epoc32.release.winscw.udeb.symbian_test.lib is incompatible with standard.*',
			'.*armlink.*oe_exe_without_stdcpp.*scppnwdl.dso.*',
			'.*armlink.*symbian_exe_with_stdcpp.*stdnew.dso.*',
			'.*armlink.*oedll.*stdnew.dso.*',
			'.*armlink.*oeexe.*stdnew.dso.*',
			'.*armlink.*symbian_newlib.exe.*scppnwdl.dso.*'
		]
		t.mustnotmatch = [
			'.*armlink.*oe_exe_without_stdcpp.*stdnew.dso.*',
			'.*armlink.*symbian_exe_with_stdcpp.*scppnwdl.dso.*',
			'.*armlink.*oedll.*scppnwdl.dso.*',
			'.*armlink.*oeexe.*scppnwdl.dso.*',
			'.*armlink.*symbian_newlib.exe.*stdnew.dso.*',
			'.*mwldsym2.*scppnwdl.lib.*symbian_exe_with_stdcpp.exe.*'
		]
	else: 
		# these files will build for 9.4
		t.targets.extend([
			"$(EPOCROOT)/epoc32/release/winscw/urel/wrong_newlib_test_oeexe.exe",
			"$(EPOCROOT)/epoc32/release/winscw/urel/wrong_newlib_test_oeexe.exe.map",
			"$(EPOCROOT)/epoc32/release/winscw/udeb/wrong_newlib_test_oeexe.exe",
			"$(EPOCROOT)/epoc32/release/winscw/udeb/wrong_newlib_test_oeexe.exe.map",
			"$(EPOCROOT)/epoc32/release/winscw/urel/wrong_newlib_test_seexe.exe",
			"$(EPOCROOT)/epoc32/release/winscw/urel/wrong_newlib_test_seexe.exe.map",
			"$(EPOCROOT)/epoc32/release/winscw/udeb/wrong_newlib_test_seexe.exe",
			"$(EPOCROOT)/epoc32/release/winscw/udeb/wrong_newlib_test_seexe.exe.map",
			"$(EPOCROOT)/epoc32/release/armv5/urel/wrong_newlib_test_oeexe.exe",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/wrong_newlib_test_oeexe.exe",
			"$(EPOCROOT)/epoc32/release/armv5/urel/wrong_newlib_test_seexe.exe",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/wrong_newlib_test_seexe.exe",
			"$(EPOCROOT)/epoc32/release/armv5/urel/wrong_newlib_test_oeexe.exe.map",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/wrong_newlib_test_oeexe.exe.map",
			"$(EPOCROOT)/epoc32/release/armv5/urel/wrong_newlib_test_seexe.exe.map",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/wrong_newlib_test_seexe.exe.map",
			"$(EPOCROOT)/epoc32/release/armv5/urel/wrong_newlib_test_oeexe.exe.sym",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/wrong_newlib_test_oeexe.exe.sym",
			"$(EPOCROOT)/epoc32/release/armv5/urel/wrong_newlib_test_seexe.exe.sym",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/wrong_newlib_test_seexe.exe.sym"
		])
	t.run()
	return t
