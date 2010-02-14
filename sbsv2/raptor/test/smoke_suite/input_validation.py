#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
	t.description = "Set of tests for commandline option validation e.g. checking that the specified make engine exists"
	
	
	t.usebash = True
	t.errors = 1
	t.returncode = 1
	t.exceptions = 0
	base_command = "sbs -b smoke_suite/test_resources/simple/bld.inf -f ${SBSLOGFILE} -m ${SBSMAKEFILE}"
	
	t.id = "42562a"
	t.name = "validate_makeengine_nonexist"
	t.command = base_command + " -e amakeenginethatdoesnotexist"
	t.mustmatch = ["Unable to use make engine: 'amakeenginethatdoesnotexist' does not appear to be a make engine - no settings found for it"]

	t.run()

	t.id = "43562b"
	t.mustmatch = ["Unable to use make engine: 'arm' is not a build engine \(it's a variant but it does not extend 'make_engine'"]
	t.name = "validate_makeengine_is_a_non_makengine_variant"
	t.command = base_command + " -e arm"
	t.run()

	# aliases can be of the form name='blah' meaning='x.y.z'  i.e. where the alias is for a sequence of variants
	# this tests that we detect that at least one of these variants has make_engine as a parent
	# it is possible for one of them not to and we mustn't bomb-out just because of that
	t.id = "43562c"
	t.mustmatch = []
	t.name = "validate_real_dfs_modded_makeengine_alias"
	t.command = "export HOME=$SBS_HOME/test/custom_options/dfsconfig;  " + base_command + " -e dfstestmake -c arm.v5.urel.gcce4_4_1"
	t.errors = 0
	t.warnings = 0
	t.returncode = 0
	t.run()
	
	t.id = "43562"
	t.name = "input_validation"
	t.print_result()
	return t
