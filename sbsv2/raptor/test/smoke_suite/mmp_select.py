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
	t.id = "44"
	t.name = "mmp_select"
	t.description = "Test -p option"
	t.command = "sbs -b smoke_suite/test_resources/basics/helloworld/Bld.inf " \
			+ "-p hElLoWoRlD.mMp"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/HelloWorld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/HelloWorld.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/HelloWorld.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/HelloWorld.exe"
		]
	t.addbuildtargets('smoke_suite/test_resources/basics/helloworld/Bld.inf', [
		"helloworld_exe/armv5/udeb/HelloWorld.o",
		"helloworld_exe/armv5/urel/HelloWorld.o",
		"helloworld_exe/winscw/udeb/HelloWorld.o",
		"helloworld_exe/winscw/urel/HelloWorld.o"
	])
	t.run()
	return t
