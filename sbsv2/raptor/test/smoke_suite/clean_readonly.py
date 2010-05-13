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
	
	# build something; make it read-only; then try and clean it
	
	t = AntiTargetSmokeTest()
	t.id = "10a"
	t.name = "clean_readonly" 
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll"
	]
	t.addbuildtargets("smoke_suite/test_resources/simple_dll/bld.inf",
	[
	"createstaticdll_dll/armv5/udeb/CreateStaticDLL.o",
	"createstaticdll_dll/armv5/urel/CreateStaticDLL.o"
	])
	t.run()
	setupOK = (t.result != AntiTargetSmokeTest.FAIL)
	
	# This particular file createstaticdll.dll is changed to be readonly to test
	# 		if sbs CLEAN command actually gets rid of read only files
	fileForClean = os.environ['EPOCROOT'] + "/epoc32/release/armv5/urel/createstaticdll.dll"
	if os.path.exists(fileForClean):
		os.chmod(fileForClean, stat.S_IREAD)
	
	t.id = "10"
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c armv5 CLEAN"
	t.targets = []
	t.antitargets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/createstaticdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll"
	]
	t.addbuildantitargets("smoke_suite/test_resources/simple_dll/bld.inf",
	[
	"createstaticdll_dll/armv5/udeb/CreateStaticDLL.o",
	"createstaticdll_dll/armv5/urel/CreateStaticDLL.o"
	])
	t.run()
	
	if not setupOK:
		t.result = AntiTargetSmokeTest.FAIL
		
	return t
