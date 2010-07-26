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
#

from raptor_tests import SmokeTest, CheckWhatSmokeTest

def run():
	result = SmokeTest.PASS
	t = SmokeTest()
	t.id = "0018a"
	t.name = "temclean"
	t.command = "sbs -b smoke_suite/test_resources/tem/bldclean.inf -c armv5 CLEAN"
	t.targets = [
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_succeeded",
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_failed"
		]
	t.missing = 2
	t.warnings = 1
	t.returncode = 0
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	
	t.id = "0018b"
	t.name = "temtest"
	t.command = "sbs -b smoke_suite/test_resources/tem/bld.inf -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_succeeded"
		]
	t.warnings = 2
	t.missing = 0
	t.returncode = 1
	t.mustmatch = [ "repeated call to TEM with same values.* Stop\." ]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t.id = "0018c"
	t.name = "temclean2"
	t.command = "sbs -b smoke_suite/test_resources/tem/bldclean.inf -c armv5 CLEAN"
	t.targets = [
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_succeeded",
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_failed"
		]
	t.missing = 2
	t.warnings = 1
	t.returncode = 0
	t.mustmatch = []
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t.id = "0018d"
	t.name = "badtem"
	t.command = "sbs -b smoke_suite/test_resources/tem/bad_bld.inf -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_failed"
		]
	t.warnings = 3
	t.missing = 0
	t.returncode = 1
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t.id = "0018e"
	t.name = "temclean3"
	t.command = "sbs -b smoke_suite/test_resources/tem/bldclean.inf -c armv5 CLEAN"
	t.targets = [
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_succeeded",
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_failed"
		]
	t.missing = 2
	t.warnings = 1
	t.returncode = 0
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t = CheckWhatSmokeTest()
	t.id = "0018f"
	t.name = "temwhat"
	t.command = "sbs -b smoke_suite/test_resources/simple_extension/bld.inf --what"
	t.output_expected_only_once = True	
	t.stdout = [
		# exports
		'$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/clean.mk',
		'$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/clean.meta',
		'$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/build.mk',
		'$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/build.meta',
		# release tree built
		'$(EPOCROOT)/epoc32/release/armv5/udeb/simple_extension.txt',
		'$(EPOCROOT)/epoc32/release/armv5/urel/simple_extension.txt',
		'$(EPOCROOT)/epoc32/release/winscw/udeb/simple_extension.txt',
		'$(EPOCROOT)/epoc32/release/winscw/urel/simple_extension.txt'
	]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t = SmokeTest()
	t.id = "0018g"
	t.name = "badtem2"
	t.command = "sbs -b smoke_suite/test_resources/tem/bad2_bld.inf -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/raptor_smoketest_tem_failed"
		]
	t.warnings = 3
	t.returncode = 1
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	t.id = "18"
	t.name = "temtest"
	t.result = result
	t.print_result()
	return t
