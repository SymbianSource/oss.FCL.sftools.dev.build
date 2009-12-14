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
from raptor_meta import BldInfFile

def run():
	result = SmokeTest.PASS
	
	t = SmokeTest()
	t.id = "0098a"
	t.name = "Build a component to begin with"
	t.description = "Build a simple component"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf"
			
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test.exe"
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# Ensure we don't clean up from the previous build in any subsequent runs
	t = SmokeTest()
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [])
	t.targets = []
	t.usebash = True

	t.id = "0098b"
	t.name ="Touch a source file dependency and make sure thats the only one rebuilt"
	t.description = "Touches one source file's dependency to check if its rebuilt"
	t.command = """
		sleep 1
		touch smoke_suite/test_resources/simple/test.h
		sbs -f - -b smoke_suite/test_resources/simple/bld.inf """
	# We should only recompile 1 source file, twice for armv5 and twice for winscw
	t.countmatch = [
		[".*recipe name='compile'.*", 2],
		[".*recipe name='win32compile2object'.*", 2]
	]

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	# Invalidate the dependency file to make sure its not regenerated
	t = SmokeTest()
	# Ensure we don't clean up from the previous build in any subsequent runs
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [])
	t.targets = []
	t.usebash = True

	t.id = "0098c"
	t.name ="Invalidate the dependency file to make sure its not regenerated"
	t.description = "Invalidate the dependency file to make sure its not regenerated"
	fragment = BldInfFile.outputPathFragment('smoke_suite/test_resources/simple/Bld.inf')
	t.command = """
		sleep 1
		touch smoke_suite/test_resources/simple/test.cpp
		echo INVALIDATE_ARMV5_DEPENDENCY_FILE >> $(EPOCROOT)/epoc32/build/"""+ fragment + """/test_/armv5/urel/test.o.d
		echo INVALIDATE_WINSCW_DEPENDENCY_FILE >> $(EPOCROOT)/epoc32/build/"""+ fragment + """/test_/winscw/urel/test.o.d
		sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5_urel -c winscw_urel
		rm -rf $(EPOCROOT)/epoc32/build/"""+ fragment + """/test_/armv5/urel/test.o.d
		rm -rf $(EPOCROOT)/epoc32/build/"""+ fragment + """/test_/winscw/urel/test.o.d"""
	t.errors = 1 # We expect the build to fail since we messed up the dependency file
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	t.id = "98"
	t.name = "basic_dependency"
	t.result = result
	t.print_result()
	return t
