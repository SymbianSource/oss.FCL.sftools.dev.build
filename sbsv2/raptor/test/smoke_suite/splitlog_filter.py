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
import sys

def run():
	result = SmokeTest.PASS
	
	t = SmokeTest()
	# Override logfileoption and makefileoption to stop them adding '-f' and '-m'
	t.logfileOption = lambda : ""
	t.makefileOption = lambda : ""
	t.id = "0083a"
	t.name = "splitlog_filter"
	t.description = "Tests scanlog_filter output"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 " + \
			"--filters=FilterSplitlog " + \
			"-f $(EPOCROOT)/epoc32/build/splitlog.xml " + \
			"&& cat $(EPOCROOT)/epoc32/build/splitlog.xml"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [
		"test_/armv5/udeb/test.o",
		"test_/armv5/urel/test.o"
		])
	t.mustmatch = [
		".*<info.*"		
		]
	t.mustnotmatch = [
		".*<clean.*",
		".*</clean>.*",
		".*<whatlog.*",
		".*</whatlog>.*",
		".*<recipe.*",
		".*</recipe>.*"
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	
	t.id = "0083b"
	t.name = "splitlog_cleancheck"
	t.command = "cat $(EPOCROOT)/epoc32/build/splitlog.clean.xml"
	t.targets = []
	t.mustmatch = [
		".*<clean.*",
		".*</clean>.*"
		]
	t.mustnotmatch = [
		".*<info.*"
		".*<whatlog.*",
		".*</whatlog>.*",
		".*<recipe.*",
		".*</recipe>.*"
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
		
	
	t.id = "0083c"
	t.name = "splitlog_whatlogcheck"
	t.command = "cat $(EPOCROOT)/epoc32/build/splitlog.whatlog.xml"
	t.mustmatch = [
		".*<whatlog.*",
		".*</whatlog>.*"
		]
	t.mustnotmatch = [
		".*<info.*",
		".*<clean.*",
		".*</clean>.*",
		".*<recipe.*",
		".*</recipe>.*"
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	t.id = "0083d"
	t.name = "splitlog_recipecheck"
	t.command = "cat $(EPOCROOT)/epoc32/build/splitlog.recipe.xml"
	t.mustmatch = [
		".*<recipe.*",
		".*</recipe>.*"
		]
	t.mustnotmatch = [
		".*<info.*",
		".*<clean.*",
		".*</clean>.*",
		".*<whatlog.*",
		".*</whatlog>.*"
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	
	t.id = "83"
	t.name = "splitlog_filter"
	t.result = result
	t.print_result()
	return t
