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
	t.id = "43"
	t.name = "named_extension"
	t.description = "Test -p option with named extensions - should clean then" \
			+ " create success.txt"
	t.command = "sbs -b smoke_suite/test_resources/basics/helloworld/Bld.inf " \
			+ "REALLYCLEAN && sbs -b " \
			+ "smoke_suite/test_resources/basics/helloworld/Bld.inf -p run_this"
	t.targets = [
		"$(EPOCROOT)/epoc32/success.txt"
		]
	t.antitargets = [
		"$(EPOCROOT)/epoc32/failure.txt",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/HelloWorld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/HelloWorld.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/HelloWorld.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/HelloWorld.exe"
	]
	t.addbuildantitargets("smoke_suite/test_resources/basics/helloworld/Bld.inf", [
		"$(EPOCROOT)/epoc32/build/basics/helloworld/helloworld_exe/armv5/udeb/HelloWorld.o",
		"$(EPOCROOT)/epoc32/build/basics/helloworld/helloworld_exe/armv5/urel/HelloWorld.o",
		"$(EPOCROOT)/epoc32/build/basics/helloworld/helloworld_exe/winscw/udeb/HelloWorld.o",
		"$(EPOCROOT)/epoc32/build/basics/helloworld/helloworld_exe/winscw/urel/HelloWorld.o"
		])
	t.run()
	return t
