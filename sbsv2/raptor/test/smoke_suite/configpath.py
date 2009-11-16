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
import os.path
from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.logfileOption = lambda :""
	t.id = "0074a"
	t.name = "configpath"
	t.description = """Test --configpath option for sbs. Specify two remote
			locations and use the variants in those folders along with ones in
			each of the default folders."""

	# the variants here affect compile steps so we only need to see a single compile
	# to know whether the variant is doing its thing or not.
	t.addbuildtargets("smoke_suite/test_resources/simple/bld.inf",
	                  ["test_/armv5/udeb/test.o"])

	result = SmokeTest.PASS

	# the extra config folders are
	# smoke_suite/test_resources/configpathtest/v{2,3}
	sbshome = os.environ["SBS_HOME"].replace("\\","/")

	aFolder = sbshome + "/test/smoke_suite/test_resources/configpathtest/v2"
	bFolder = sbshome + "/test/smoke_suite/test_resources/configpathtest/v3"

	common = "sbs -b smoke_suite/test_resources/simple/bld.inf " + \
			"-c armv5.configpathtest1.configpathtest2.configpathtest3"

	# run the command using the built-in default systemConfig
	t.command = common + " --configpath=" + aFolder + os.pathsep + bFolder + \
			" -f -"

	t.mustmatch = [
		".*armv5_udeb.configpathtest1.configpathtest2.configpathtest3.*",
		".*armv5_urel.configpathtest1.configpathtest2.configpathtest3.*",
		".*Duplicate variant 'configpathtest3'.*",
		".*-DTESTPASSED.*",
		".*-DOSVARIANT95WASAPPLIED.*"
		]
	t.mustnotmatch = [
		".*sbs: error: Unknown variant.*",
		".*-DTESTFAILED.*"
		]
	# Duplicate variant is Info not Warn
	t.warnings = 0
	t.run()

	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# run the command again using a systemConfig from $HOME/.sbs_init.xml
	# and the configpath as two separate options.
	t.usebash = True
	homedir = sbshome + "/test/smoke_suite/test_resources/configpathtest/home"
	t.command = "export HOME=" + homedir + "; " + common + \
			" --configpath=" + aFolder + " --configpath=" + bFolder + " -f -"
	t.id = "0074b"
	t.mustmatch = [
		".*armv5_udeb.configpathtest1.configpathtest2.configpathtest3.*",
		".*armv5_urel.configpathtest1.configpathtest2.configpathtest3.*",
		".*Duplicate variant 'configpathtest3'.*"
		]
	t.mustnotmatch = [
		".*sbs: error: Unknown variant.*"
		]
	t.run()

	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	# Clean
	t.mustmatch = []
	t.targets = []
	t.id = "0074c"
	t.name = "CLEAN"
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 " + \
			"REALLYCLEAN"
	t.run() # Does not contribute to results

	t.id = "74"
	t.name = "configpath"
	t.result = result
	t.print_result()
	return t

