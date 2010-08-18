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
	t.description = "tests that previous crash conditions now generate tidy errors."
	
	# no crash when there are bld.inf lines starting with a slash	
	t.id = "45a"
	t.name = "raptor_crash"
	t.command = "sbs -b smoke_suite/test_resources/simple_crash/bld.inf"
	t.errors = 2
	t.returncode = 1
	t.run()
	
	# should get an error code when running inside cmd
	t.id = "45b"
	t.name = "error_cmd"
	t.usebash = True
	t.command = "cmd /c sbs -s no_such_thing"
	t.mustmatch = ["System Definition file no_such_thing does not exist"]
	t.errors = 1
	t.returncode = 1
	t.run("windows")
	
	# should get an error code when running in bash
	t.id = "45c"
	t.name = "error_bash"
	t.usebash = True
	t.command = "sbs -s no_such_thing"
	t.mustmatch = ["System Definition file no_such_thing does not exist"]
	t.errors = 1
	t.returncode = 1
	t.run()
	
	# print the over all result
	t.id = "45"
	t.name = "raptor_crash"
	t.print_result()
	return t
