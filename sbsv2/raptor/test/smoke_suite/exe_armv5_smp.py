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
	t.id = "62"
	t.name = "exe_armv5_smp"
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 -c" \
			+ " armv5.smp"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5smp/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5smp/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5smp/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5smp/urel/test.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o",
		"test_/armv5smp/udeb/test.o",
		"test_/armv5smp/urel/test.o"
	])
	t.run()
	return t
