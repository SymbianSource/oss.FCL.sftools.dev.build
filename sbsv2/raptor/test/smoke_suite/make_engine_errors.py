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
	t.id = "113"
	t.name = "make_engine_errors"
	t.description = "Errors reported by gmake and emake should be escaped to ensure that the logs are valid XML"
	
	t.mustmatch_singleline = ["Circular b &lt;- a dependency",
							  "non_existent_&amp;_needs_escaping.txt"]
	
	t.mustnotmatch_singleline = ["Circular b <- a dependency",
							     "non_existent_&_needs_escaping.txt"]
	
	t.usebash = True
	t.errors = 1
	t.returncode = 1
	base_command = "sbs --no-depend-generate -b smoke_suite/test_resources/make_engine_errors/bld.inf -f-"
	
	t.id = "113a"
	t.name = "gmake_engine_errors"
	t.command = base_command + " -e make"
	t.run()

	t.id = "113b"
	t.name = "emake_engine_errors"
	t.command = base_command + " -e emake"
	t.run()
	
	t.id = "113c"
	t.name = "emake_engine_errors_with_merged_streams"
	t.command = base_command + " -e emake --mo=--emake-mergestreams=1"
	t.run()
		
	t.id = "113"
	t.name = "make_engine_errors"
	t.print_result()
	return t
