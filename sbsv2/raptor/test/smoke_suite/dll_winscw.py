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
	t.id = "34"
	t.name = "dll_winscw"
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c winscw"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/winscw/udeb/createstaticdll.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/createstaticdll.dll.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/bld.inf', [
		"createstaticdll_dll/winscw/udeb/CreateStaticDLL.o",
		"createstaticdll_dll/winscw/udeb/createstaticdll.UID.CPP",
		"createstaticdll_dll/winscw/udeb/createstaticdll_UID_.o",
		"createstaticdll_dll/winscw/urel/CreateStaticDLL.o",
		"createstaticdll_dll/winscw/urel/createstaticdll.UID.CPP",
		"createstaticdll_dll/winscw/urel/createstaticdll_UID_.o"
	])
	t.run()
	return t
