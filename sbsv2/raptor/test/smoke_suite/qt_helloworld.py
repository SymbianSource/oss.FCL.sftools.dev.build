#
# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# This test case requires install of Qt. 

from raptor_tests import SmokeTest
import os

def run():
	t = SmokeTest()

	t.description = "Ensure Raptor builds Qt applications successfully"	

	t.id = "0110"
	t.name = "qt_helloworld"
	# Internal QT deliveries use a QMAKE launcher that expects EPOCROOT to end in a slash
	# We ensure it does (doesn't matter if there are multiple slashes)
	t.environ["EPOCROOT"] = os.environ["EPOCROOT"] + os.sep
	t.command = "cd smoke_suite/test_resources/qt && $(EPOCROOT)/epoc32/tools/qmake -spec symbian-sbsv2 && sbs"
	t.targets = [
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/bld.inf",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/helloworldqt.loc",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/helloworldqt.rss",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/helloworldqt_reg.rss",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/helloworldqt_template.pkg",
			"$(SBS_HOME)/test/smoke_suite/test_resources/qt/Makefile",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworldqt.exe",
			"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworldqt.exe.map",
			"$(EPOCROOT)/epoc32/release/armv5/urel/helloworldqt.exe",
			"$(EPOCROOT)/epoc32/release/armv5/urel/helloworldqt.exe.map",
			"$(EPOCROOT)/epoc32/release/winscw/udeb/helloworldqt.exe",
			"$(EPOCROOT)/epoc32/release/winscw/urel/helloworldqt.exe",
			"$(EPOCROOT)/epoc32/release/winscw/urel/helloworldqt.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/qt/bld.inf', [
		"helloworldqt_exe/armv5/udeb/helloworld.o",
		"helloworldqt_exe/armv5/udeb/helloworld.o.d",
		"helloworldqt_exe/armv5/urel/helloworld.o",
		"helloworldqt_exe/armv5/urel/helloworld.o.d",
		"helloworldqt_exe/winscw/udeb/helloworld.o",
		"helloworldqt_exe/winscw/udeb/helloworld.o.d",	
		"helloworldqt_exe/winscw/urel/helloworld.o",
		"helloworldqt_exe/winscw/urel/helloworld.o.d"
	])
	t.run("windows")

	return t

