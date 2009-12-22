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
	t.command = "cd smoke_suite/test_resources/qt && $(EPOCROOT)/epoc32/tools/qmake -spec symbian-sbsv2 && sbs -b bld.inf"
	t.targets = [
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/bld.inf",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/qt_0xEe136753.mmp",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/qt.loc",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/qt.rss",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/qt_reg.rss",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/qt_template.pkg",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/Makefile",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/qt.exe",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/qt.exe.map",
			"$(EPOCROOT)/epoc32/release/armv5/urel/qt.exe",
			"$(EPOCROOT)/epoc32/release/armv5/urel/qt.exe.map",
			"$(EPOCROOT)/epoc32/release/winscw/udeb/qt.exe",
			"$(EPOCROOT)/epoc32/release/winscw/urel/qt.exe",
			"$(EPOCROOT)/epoc32/release/winscw/urel/qt.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/qt/bld.inf', [
		"qt_exe/armv5/udeb/helloworld.o",
		"qt_exe/armv5/udeb/helloworld.o.d",
		"qt_exe/armv5/urel/helloworld.o",
		"qt_exe/armv5/urel/helloworld.o.d",
		"qt_exe/winscw/udeb/helloworld.o",
		"qt_exe/winscw/udeb/helloworld.o.d",	
		"qt_exe/winscw/urel/helloworld.o",
		"qt_exe/winscw/urel/helloworld.o.d"
	])
	t.run("windows")

	return t


