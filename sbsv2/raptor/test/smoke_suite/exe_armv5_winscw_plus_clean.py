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

from raptor_tests import SmokeTest, AntiTargetSmokeTest

def run():
	result = SmokeTest.PASS
	
	t = SmokeTest()
	t.id = "0005a"
	t.name = "exe_armv5_winscw"
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 " + \
			"-c winscw"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o",
		"test_/winscw/udeb/test.o",
		"test_/winscw/udeb/test_UID_.o",
		"test_/winscw/udeb/test.UID.CPP",
		"test_/winscw/urel/test.o",
		"test_/winscw/urel/test_UID_.o",
		"test_/winscw/urel/test.UID.CPP"
	])
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
		
	
	"Check that CLEAN removes built files"
	c = AntiTargetSmokeTest()
	c.id = "0005b"
	c.name = "exe_armv5_winscw_clean"
	c.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 " + \
			"-c winscw CLEAN"
	c.antitargets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe.map"
		]
	c.addbuildantitargets('smoke_suite/test_resources/simple/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o",
		"test_/winscw/udeb/test.o",
		"test_/winscw/udeb/test_UID_.o",
		"test_/winscw/udeb/test.UID.CPP",
		"test_/winscw/urel/test.o",
		"test_/winscw/urel/test_UID_.o",
		"test_/winscw/urel/test.UID.CPP"
	])
	c.run()
	if c.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	
	"Rebuild"
	t.id = "0005c"
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	
	"Check that REALLYCLEAN removes built files"
	c.id = "0005d"
	c.name = "exe_armv5_winscw_reallyclean"
	c.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 " + \
			"-c winscw REALLYCLEAN"
	c.run()
	if c.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	
	t.id = "5"
	t.name = "exe_armv5_winscw_plus_clean"
	t.result = result
	t.print_result()
	return t
