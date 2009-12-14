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
	t.id = "105"
	t.name = "pdll_winscw"
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/pbld.inf -c winscw"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/winscw/udeb/createstaticpdll.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/createstaticpdll.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/createstaticpdll.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/createstaticpdll.dll.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/pbld.inf', [
		"createstaticpdll_dll/winscw/udeb/CreateStaticDLL.o",
		"createstaticpdll_dll/winscw/udeb/createstaticpdll.UID.CPP",
		"createstaticpdll_dll/winscw/udeb/createstaticpdll_UID_.o",
		"createstaticpdll_dll/winscw/urel/CreateStaticDLL.o",
		"createstaticpdll_dll/winscw/urel/createstaticpdll.UID.CPP",
		"createstaticpdll_dll/winscw/urel/createstaticpdll_UID_.o"
	])
	t.run()
	return t
