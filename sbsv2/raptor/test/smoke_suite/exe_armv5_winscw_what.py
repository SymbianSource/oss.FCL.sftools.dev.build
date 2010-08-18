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

from raptor_tests import CheckWhatSmokeTest

def run():
	t = CheckWhatSmokeTest()
	t.id = "7"
	t.name = "exe_armv5_winscw_what"
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 " + \
			"-c winscw --what"
	t.stdout = [
			# armv5 artefacts
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.map",
			# winscw artefacts
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe.map"
	]
	t.run()
	return t
