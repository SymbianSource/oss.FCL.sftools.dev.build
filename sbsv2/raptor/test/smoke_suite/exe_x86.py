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
	t.name = "exe_x86"
	t.description = "Build a basic EXE TARGETTYPE for x86"
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c x86"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/x86/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/x86/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/x86/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/x86/urel/test.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [
		"test_/x86/udeb/test.o",
		"test_/x86/udeb/test.o.d",
		"test_/x86/udeb/test1.o",
		"test_/x86/udeb/test1.o.d",
		"test_/x86/udeb/test2.o",
		"test_/x86/udeb/test2.o.d",
		"test_/x86/udeb/test3.o",
		"test_/x86/udeb/test3.o.d",
		"test_/x86/udeb/test4.o",
		"test_/x86/udeb/test4.o.d",
		"test_/x86/udeb/test5.o",
		"test_/x86/udeb/test5.o.d",
		"test_/x86/udeb/test6.o",
		"test_/x86/udeb/test6.o.d",
		"test_/x86/urel/test.o",
		"test_/x86/urel/test.o.d",
		"test_/x86/urel/test1.o",
		"test_/x86/urel/test1.o.d",
		"test_/x86/urel/test2.o",
		"test_/x86/urel/test2.o.d",
		"test_/x86/urel/test3.o",
		"test_/x86/urel/test3.o.d",
		"test_/x86/urel/test4.o",
		"test_/x86/urel/test4.o.d",
		"test_/x86/urel/test5.o",
		"test_/x86/urel/test5.o.d",
		"test_/x86/urel/test6.o",
		"test_/x86/urel/test6.o.d",
		"test_/x86/udeb/test_udeb_objects.via",
		"test_/x86/urel/test_urel_objects.via"
		])
	
	t.run("windows")
	return t
