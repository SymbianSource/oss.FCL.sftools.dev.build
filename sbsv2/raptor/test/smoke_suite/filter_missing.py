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

from raptor_tests import GenericSmokeTest

def run():
	result = GenericSmokeTest.PASS 
	
	t = GenericSmokeTest()
	t.id = "0072a"
	t.name = "filter_missing" 
	t.command = "sbs --filters=NonExistingFilter"
	t.mustmatch = [
			".*requested filters not found.*NonExistingFilter.*"
	]
	t.errors = 1
	t.returncode = 1
	t.run()
	if t.result == GenericSmokeTest.FAIL:
		result = GenericSmokeTest.FAIL

	t.id = "0072b"
	t.name = "filter_crashes"
	t.usebash = True
	t.command = "cp -f smoke_suite/test_resources/filter_test/testfilter_exceptions.py " \
			+ "$SBS_HOME/python/plugins ; " \
			+ "sbs -n --filters=FilterTestCrash,FilterLogFile,FilterTerminal " \
			+ "-b smoke_suite/test_resources/simple/bld.inf " \
			+ "-m ${SBSMAKEFILE} -f ${SBSLOGFILE} ; " \
    		+ "rm -f $SBS_HOME/python/plugins/testfilter_exceptions.py"
	t.errors = 0
	t.returncode = 0
	t.exceptions = 1
	t.mustmatch = [
			".*A test exception in a filter was generated.*",
			".*sbs: build log in.*"
	]

	t.run()
	if t.result == GenericSmokeTest.FAIL:
		result = GenericSmokeTest.FAIL
	
	t.id = "72"
	t.name = "filter_missing"
	t.result = result
	t.print_result()
	return t
