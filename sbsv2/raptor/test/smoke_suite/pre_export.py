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
	t.id = "32"
	t.name = "pre_export"
	t.command = "sbs -b smoke_suite/test_resources/pre-export/bld.inf -c " + \
			"armv5 -k"
	t.targets = [
		"$(EPOCROOT)/epoc32/include/my.mmh",
		"$(EPOCROOT)/epoc32/include/second.mmh",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/petest.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/petest.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/petest.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/petest.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/pre-export/bld.inf', [
		"petest_/armv5/udeb/test.o",
		"petest_/armv5/urel/test.o"
	])
	# we expect these errors because there are 2 MMP files deliberately missing
	t.errors = 4
	t.returncode = 1
	t.run()
	return t
