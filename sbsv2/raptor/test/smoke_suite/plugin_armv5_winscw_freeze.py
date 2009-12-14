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
	t.id = "90"
	t.name = "plugin_armv5_winscw_freeze"
	t.description = """Builds two PLUGIN components, one with and one without an explicit DEFFILE statement,
		and confirms the correct FREEZE behaviour in each case.  The correct behaviour for a PLUGIN is indicative
		of all TARGETTYPEs where the build system defines known exports: FREEZE should do nothing unless an
		explicit DEFFILE statement is present in the .mmp file."""
	t.usebash = True
	
	t.command = """
		sbs -b smoke_suite/test_resources/simple_plugin/bld.inf -c armv5_urel -c winscw_urel CLEAN > /dev/null &&
		sbs -b smoke_suite/test_resources/simple_plugin/bld.inf -c armv5_urel -c winscw_urel > /dev/null &&
		sbs -b smoke_suite/test_resources/simple_plugin/bld.inf -c armv5_urel -c winscw_urel FREEZE -m ${SBSMAKEFILE} -f ${SBSLOGFILE}"""

	t.targets = [
		"smoke_suite/test_resources/simple_plugin/bwins/plugin2u.def",
		"smoke_suite/test_resources/simple_plugin/eabi/plugin2u.def"		
		]
	
	t.antitargets = [
		"smoke_suite/test_resources/simple_plugin/bwins/pluginu.def",
		"smoke_suite/test_resources/simple_plugin/eabi/pluginu.def"		
		]
	
	t.mustmatch = [
		".*EFREEZE: Appending 3 New Export\(s\) to .*/test/smoke_suite/test_resources/simple_plugin/eabi/plugin2u.def.*",
		".*EFREEZE: Appending 1 New Export\(s\) to .*/test/smoke_suite/test_resources/simple_plugin/bwins/plugin2u.def.*"
		]

	t.mustnotmatch = [
		".*EFREEZE: .*/test/smoke_suite/test_resources/simple_plugin/eabi/pluginu.def.*",
		".*EFREEZE: .*/test/smoke_suite/test_resources/simple_plugin/bwins/pluginu.def.*"
		]
	
	t.warnings = 2	
	t.run()
	return t
