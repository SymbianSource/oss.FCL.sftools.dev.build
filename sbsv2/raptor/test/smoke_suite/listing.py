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
	t.id = "31"
	t.name = "listing"
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 " + \
			"-c winscw -k listing"
	t.targets = [
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test.armv5.urel.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test.armv5.udeb.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test.WINSCW.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test1.armv5.urel.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test1.armv5.udeb.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test1.WINSCW.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test2.armv5.urel.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test2.armv5.udeb.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test2.WINSCW.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test3.armv5.urel.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test3.armv5.udeb.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test3.WINSCW.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test4.armv5.urel.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test4.armv5.udeb.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test4.WINSCW.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test5.armv5.urel.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test5.armv5.udeb.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test5.WINSCW.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test6.armv5.urel.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test6.armv5.udeb.test.exe.lst",
		"$(SBS_HOME)/test/smoke_suite/test_resources/simple/test6.WINSCW.lst"
		]
	t.run()
	return t
