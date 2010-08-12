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
	t.name = "dll_x86"
	t.description = "Build a basic DLL TARGETTYPE for x86"
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c x86"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/x86/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/x86/udeb/createstaticdll.dll.map",
		"$(EPOCROOT)/epoc32/release/x86/urel/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/x86/urel/createstaticdll.dll.map",
		"$(EPOCROOT)/epoc32/release/x86/lib/createstaticdll.lib",
		"$(EPOCROOT)/epoc32/release/x86/lib/createstaticdll{000a0000}.lib"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/bld.inf', [
		"createstaticdll_dll/x86/udeb/CreateStaticDLL.o",
		"createstaticdll_dll/x86/udeb/CreateStaticDLL.o.d",
		"createstaticdll_dll/x86/urel/CreateStaticDLL.o",
		"createstaticdll_dll/x86/urel/CreateStaticDLL.o.d",
		"createstaticdll_dll/x86/udeb/createstaticdll_udeb_objects.via",
		"createstaticdll_dll/x86/urel/createstaticdll_urel_objects.via",	
		["createstaticdll_dll/x86/udeb/createstaticdll.prep",
		"createstaticdll_dll/x86/urel/createstaticdll.prep"],	
		["createstaticdll_dll/x86/udeb/createstaticdll.lib.exp",
		"createstaticdll_dll/x86/urel/createstaticdll.lib.exp"]	
		])
	
	t.run("windows")
	return t
