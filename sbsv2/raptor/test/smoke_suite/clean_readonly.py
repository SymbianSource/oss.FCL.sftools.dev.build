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
import os
import stat

def run():
	# This particular file createstaticdll.dll is changed to be readonly to test
	# 		if sbs CLEAN command actually gets rid of read only files
	fileForClean = (os.environ['EPOCROOT'] + \
			"/epoc32/release/armv5/urel/createstaticdll.dll")
	if os.path.exists(fileForClean):
		os.chmod(fileForClean, stat.S_IREAD)
	
	t = AntiTargetSmokeTest()
	t.id = "10"
	t.name = "cleanreadonly" 
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c armv5 CLEAN"
	t.antitargets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/build/test/simple_dll/createstaticdll_dll/armv5/udeb/CreateStaticDLL.o",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/build/test/simple_dll/createstaticdll_dll/armv5/urel/CreateStaticDLL.o",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll"
	]
	t.run()
	return t
