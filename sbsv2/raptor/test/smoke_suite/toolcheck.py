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

import os
from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "0092a"
	t.name = "toolcheck"
	t.description = """Test toolcheck works properly, with 3 options: on, off and forced. 
				TOOL1 3 4 and 5 are expected to fail and 2 to pass"""
	result = SmokeTest.PASS
	toolcheckDir = os.environ["SBS_HOME"].replace("\\","/") + "/test/smoke_suite/test_resources/toolcheck"

	# toolcheck ON
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -n --configpath=" + toolcheckDir + \
			" -c default.toolcheck --toolcheck=on"
	
	t.mustmatch = [
		".*tool 'TOOLCHECK1' from config 'none' did not return version.*",
		".*tool 'TOOLCHECK3' from config 'none' did not return version.*",
		".*tool 'TOOLCHECK4' from config 'none' did not return version.*",
		".*tool 'TOOLCHECK5' from config 'none' did not return version.*"
		]
	t.mustnotmatch = [
		".*TOOLCHECK2.*",
		".*TOOLCHECK6.*"
		]
	t.errors = 4
	t.returncode = 1
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# toolcheck OFF
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -n --configpath=" + toolcheckDir + \
			" -c default.toolcheck --toolcheck=off"

	t.id = "0092b"
	t.mustmatch = []
	t.mustnotmatch = [
		".*TOOLCHECK1.*",
		".*TOOLCHECK3.*",
		".*TOOLCHECK4.*",
		".*TOOLCHECK5.*",
		".*TOOLCHECK6.*"
		]
	t.errors = 0
	t.returncode = 0
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# force toolcheck
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -n --configpath=" + toolcheckDir + \
			" -c default.toolcheck --toolcheck=forced"

	t.id = "0092c"
	t.mustmatch = [
		".*tool 'TOOLCHECK1' from config 'none' did not return version.*",
		".*tool 'TOOLCHECK3' from config 'none' did not return version.*",
		".*tool 'TOOLCHECK4' from config 'none' did not return version.*",
		".*tool 'TOOLCHECK5' from config 'none' did not return version.*"
		]
	t.mustnotmatch = [
		".*TOOLCHECK2.*",
		".*TOOLCHECK6.*"
	]
	t.errors = 4
	t.returncode = 1
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t.id = "0092"
	t.result = result
	t.print_result()
	return t

