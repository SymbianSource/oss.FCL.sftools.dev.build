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
	t.id = "97"
	t.name = "dll_armv6"
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c armv6"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv6/udeb/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv6/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv6/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv6/urel/createstaticdll.dll"
		]
	t.antitargets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.lib"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/bld.inf', [
		"createstaticdll_dll/armv6/udeb/CreateStaticDLL.o",
		"createstaticdll_dll/armv6/urel/CreateStaticDLL.o",
		"createstaticdll_dll/armv6/udeb/armv6_specific.o",
		"createstaticdll_dll/armv6/urel/armv6_specific.o"
	])
	t.run()
	return t
