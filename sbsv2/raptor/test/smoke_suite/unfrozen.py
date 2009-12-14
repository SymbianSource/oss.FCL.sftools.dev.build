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
	t.id = "49"
	t.name = "unfrozen"
	t.description = "Test EXPORTUNFROZEN forced import library generation with both completely unfrozen and part-frozen examples"
	t.command = "sbs -b smoke_suite/test_resources/unfrozen/bld.inf -k -c winscw -c armv5 CLEAN" \
				" && sbs -b smoke_suite/test_resources/unfrozen/bld.inf -k -c winscw -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols.dll.map",		
		"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols2.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols2{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols2.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols2.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols2.dll.map",				
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_unfrozen.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_unfrozen.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_unfrozen.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/unfrozensymbols.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/unfrozensymbols.dll.map",		
		"$(EPOCROOT)/epoc32/release/winscw/urel/unfrozensymbols2.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/unfrozensymbols2.dll.map",				
		"$(EPOCROOT)/epoc32/release/winscw/urel/test_unfrozen.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test_unfrozen.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols.dll.map",		
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols2.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols2.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols2.dll.map",				
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_unfrozen.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_unfrozen.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_unfrozen.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/unfrozensymbols.dll",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/unfrozensymbols.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/unfrozensymbols2.dll",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/unfrozensymbols2.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test_unfrozen.exe"
		]
	t.addbuildtargets('smoke_suite/test_resources/unfrozen/bld.inf', [
		"unfrozensymbols_dll/armv5/urel/unfrozensymbols{000a0000}.def",
		"unfrozensymbols_dll/armv5/urel/unfrozensymbols{000a0000}.dso",
		"unfrozensymbols_dll/armv5/urel/unfrozensymbols_urel_objects.via",
		"unfrozensymbols_dll/armv5/urel/unfrozensymbols.o.d",
		"unfrozensymbols_dll/armv5/urel/unfrozensymbols.o",
		"unfrozensymbols2_dll/armv5/urel/unfrozensymbols2{000a0000}.def",
		"unfrozensymbols2_dll/armv5/urel/unfrozensymbols2{000a0000}.dso",
		"unfrozensymbols2_dll/armv5/urel/unfrozensymbols2_urel_objects.via",
		"unfrozensymbols2_dll/armv5/urel/unfrozensymbols.o.d",
		"unfrozensymbols2_dll/armv5/urel/unfrozensymbols.o",
		"test_unfrozen_/armv5/urel/test_unfrozen_urel_objects.via",
		"test_unfrozen_/armv5/urel/test.o.d",
		"test_unfrozen_/armv5/urel/test.o",		
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols.UID.CPP",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols.o",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols_UID_.o",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols.dep",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols_UID_.dep",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols.o.d",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols_UID_.o.d",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols.lib",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols.inf",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols.dll",
		"unfrozensymbols_dll/winscw/urel/unfrozensymbols.def",	
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols2.UID.CPP",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols.o",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols2_UID_.o",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols.dep",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols2_UID_.dep",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols.o.d",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols2_UID_.o.d",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols2.lib",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols2.inf",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols2.dll",
		"unfrozensymbols2_dll/winscw/urel/unfrozensymbols2.def",				
		"test_unfrozen_/winscw/urel/test_unfrozen.UID.CPP",
		"test_unfrozen_/winscw/urel/test.o",
		"test_unfrozen_/winscw/urel/test_unfrozen_UID_.o",
		"test_unfrozen_/winscw/urel/test.dep",
		"test_unfrozen_/winscw/urel/test_unfrozen_UID_.dep",
		"test_unfrozen_/winscw/urel/test.o.d",
		"test_unfrozen_/winscw/urel/test_unfrozen_UID_.o.d",		
		"unfrozensymbols_dll/armv5/udeb/unfrozensymbols{000a0000}.def",
		"unfrozensymbols_dll/armv5/udeb/unfrozensymbols{000a0000}.dso",
		"unfrozensymbols_dll/armv5/udeb/unfrozensymbols_udeb_objects.via",
		"unfrozensymbols_dll/armv5/udeb/unfrozensymbols.o.d",
		"unfrozensymbols_dll/armv5/udeb/unfrozensymbols.o",
		"unfrozensymbols_dll/armv5/udeb/unfrozensymbols.o",		
		"unfrozensymbols2_dll/armv5/udeb/unfrozensymbols2{000a0000}.def",
		"unfrozensymbols2_dll/armv5/udeb/unfrozensymbols2{000a0000}.dso",
		"unfrozensymbols2_dll/armv5/udeb/unfrozensymbols2_udeb_objects.via",
		"unfrozensymbols2_dll/armv5/udeb/unfrozensymbols.o.d",
		"unfrozensymbols2_dll/armv5/udeb/unfrozensymbols.o",
		"unfrozensymbols2_dll/armv5/udeb/unfrozensymbols.o",				
		"test_unfrozen_/armv5/udeb/test_unfrozen_udeb_objects.via",
		"test_unfrozen_/armv5/udeb/test.o.d",
		"test_unfrozen_/armv5/udeb/test.o",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols.UID.CPP",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols.o",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols_UID_.o",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols.dep",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols_UID_.dep",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols.o.d",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols_UID_.o.d",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols.lib",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols.inf",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols.dll",
		"unfrozensymbols_dll/winscw/udeb/unfrozensymbols.def",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols2.UID.CPP",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols.o",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols2_UID_.o",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols.dep",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols2_UID_.dep",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols.o.d",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols2_UID_.o.d",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols2.lib",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols2.inf",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols2.dll",
		"unfrozensymbols2_dll/winscw/udeb/unfrozensymbols2.def",			
		"test_unfrozen_/winscw/udeb/test_unfrozen.UID.CPP",
		"test_unfrozen_/winscw/udeb/test.o",
		"test_unfrozen_/winscw/udeb/test_unfrozen_UID_.o",
		"test_unfrozen_/winscw/udeb/test.dep",
		"test_unfrozen_/winscw/udeb/test_unfrozen_UID_.dep",
		"test_unfrozen_/winscw/udeb/test.o.d",
		"test_unfrozen_/winscw/udeb/test_unfrozen_UID_.o.d"
	])
	# Match both ARMV5 (elf2e32) and WINSCW (makedef) unfrozen export warnings and confirm the number found.  Format:
	# Elf2e32: Warning: New Symbol _ZN10CMessenger5NewLCER12CConsoleBaseRK7TDesC16 found, export(s) not yet Frozen
	# F:/path/epocroot/epoc32/build/unfrozen/c_939fe933110ed5aa/unfrozensymbols_dll/winscw/udeb/unfrozensymbols.def(3) : ?NewLC@CMessenger@@SAPAV1@AAVCConsoleBase@@ABVTDesC16@@@Z @1
	# More matches are expected with elf2e32 due to extra build impedimenta in EABI builds.
	t.countmatch = [
				[".*Elf2e32: Warning: New Symbol .* found, export\(s\) not yet Frozen.*", 14],
				[".*\.def\(\d\) : .*@\d.*", 10]
				]
	t.warnings = 8
	# ABIv1 .lib files are not generated on Linux
	t.run("linux")
	if t.result == SmokeTest.SKIP:
		t.targets.extend([
			"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols.lib",
			"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols{000a0000}.lib",
			"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols2.lib",
			"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols2{000a0000}.lib"
			])
		t.run("windows")
	
	return t
