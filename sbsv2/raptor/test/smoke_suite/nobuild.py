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

from raptor_tests import AntiTargetSmokeTest

def run():
	t = AntiTargetSmokeTest()
	t.id = "76"
	t.name = "nobuild"

	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf CLEAN " + \
			"&& sbs -b smoke_suite/test_resources/simple/bld.inf -n -m ${SBSMAKEFILE} -f ${SBSLOGFILE} " + \
			"&& grep -i 'No build performed' ${SBSLOGFILE}"
	
	t.targets = []
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [])
	t.antitargets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe"
	]
	t.addbuildantitargets('smoke_suite/test_resources/simple/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o",
		"test_/armv5/udeb/test3.o",
		"test_/armv5/udeb/test4.o",
		"test_/armv5/udeb/test5.o",
		"test_/armv5/udeb/test1.o",
		"test_/armv5/udeb/test6.o",
		"test_/armv5/udeb/test2.o",
		"test_/armv5/urel/test3.o",
		"test_/armv5/urel/test4.o",
		"test_/armv5/urel/test5.o",
		"test_/armv5/urel/test1.o",
		"test_/armv5/urel/test6.o",
		"test_/armv5/urel/test2.o",
		"test_/winscw/udeb/test.o",
		"test_/winscw/urel/test.o",
		"test_/winscw/udeb/test3.o",
		"test_/winscw/udeb/test4.o",
		"test_/winscw/udeb/test5.o",
		"test_/winscw/udeb/test1.o",
		"test_/winscw/udeb/test6.o",
		"test_/winscw/udeb/test2.o",
		"test_/winscw/urel/test3.o",
		"test_/winscw/urel/test4.o",
		"test_/winscw/urel/test5.o",
		"test_/winscw/urel/test1.o",
		"test_/winscw/urel/test6.o",
		"test_/winscw/urel/test2.o"
		])
	t.mustmatch = [
		".*No build performed.*"
	]

	t.run()
	return t
