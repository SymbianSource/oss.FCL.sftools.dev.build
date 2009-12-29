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

	t.description = "Ensure Raptor builds Qt applications successfully"	

	t.id = "00xx"
	t.name = "qt_apps"
	t.command = "cd manual_suite/test_resources/qt && qmake -spec symbian-sbsv2 && sbs"
	t.targets = [
			"$(SBS_HOME)/test/manual_suite/test_resources/qt/bld.inf",
			"$(SBS_HOME)/test/manual_suite/test_resources/qt/helloworld.loc",
			"$(SBS_HOME)/test/manual_suite/test_resources/qt/helloworld.rss",
			"$(SBS_HOME)/test/manual_suite/test_resources/qt/helloworld_reg.rss",
			"$(SBS_HOME)/test/manual_suite/test_resources/qt/helloworld_template.pkg",
			"$(SBS_HOME)/test/manual_suite/test_resources/qt/Makefile",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe.map",
			"$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe",
			"$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe.map",
			"$(EPOCROOT)/epoc32/release/winscw/udeb/helloworld.exe",
			"$(EPOCROOT)/epoc32/release/winscw/urel/helloworld.exe",
			"$(EPOCROOT)/epoc32/release/winscw/urel/helloworld.exe.map"
		]
	t.addbuildtargets('manual_suite/test_resources/qt/bld.inf', [
		"helloworld_exe/armv5/udeb/helloworld.o",
		"helloworld_exe/armv5/udeb/helloworld.o.d",
		"helloworld_exe/armv5/urel/helloworld.o",
		"helloworld_exe/armv5/urel/helloworld.o.d",
		"helloworld_exe/winscw/udeb/helloworld.o",
		"helloworld_exe/winscw/udeb/helloworld.o.d",	
		"helloworld_exe/winscw/urel/helloworld.o",
		"helloworld_exe/winscw/urel/helloworld.o.d"
	])
	t.run("windows")

	return t

