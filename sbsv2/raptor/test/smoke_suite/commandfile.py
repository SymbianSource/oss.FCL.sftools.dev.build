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
	t.id = "4"
	t.name = "commandfile"
	t.command = "sbs " \
			+ "--command=smoke_suite/test_resources/simple/commands-v7.txt " \
			+ "-c armv7_udeb"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv7/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv7/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv7/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv7/urel/test.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [
		"test_/armv7/udeb/test.o",
		"test_/armv7/urel/test.o"
	])
	t.run()
	return t
	
