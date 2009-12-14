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
	t.name = "dll_armv5_smp"
	t.id = "63"
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c " + \
			"armv5 -c armv5.smp"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5smp/udeb/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5smp/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5smp/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5smp/urel/createstaticdll.dll"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/bld.inf', [
		"createstaticdll_dll/armv5/udeb/CreateStaticDLL.o",
		"createstaticdll_dll/armv5/urel/CreateStaticDLL.o",
		"createstaticdll_dll/armv5smp/udeb/CreateStaticDLL.o",
		"createstaticdll_dll/armv5smp/urel/CreateStaticDLL.o"
	])
	t.run()
	return t
