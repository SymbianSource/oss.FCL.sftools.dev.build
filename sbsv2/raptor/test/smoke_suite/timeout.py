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

from raptor_tests import SmokeTest
import os

def run():
	t = SmokeTest()
	t.description = "test that long commands time out and get retried"
	
	exitCode = "128"

	t.id = "60a"
	t.name = "timeout"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/timeout/bld.inf -f -"

	t.mustmatch_singleline = [
		"status exit='failed' code='" + exitCode + "' attempt='1' reason='timeout'",
	]
	t.errors = -1
	t.returncode = 1
	t.run()
	
	t.id = "60b"
	t.name = "timeout with retries"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/timeout/bld.inf -t 3 -f -"

	t.mustmatch_singleline = [
		"status exit='retry' code='" + exitCode + "' attempt='1' reason='timeout'",
		"status exit='retry' code='" + exitCode + "' attempt='2' reason='timeout'",
		"status exit='failed' code='" + exitCode + "' attempt='3' reason='timeout'",
	]
	t.errors = -1
	t.returncode = 1
	t.run()
	
	t.id = "60"
	t.name = "timeout"
	t.print_result()
	return t
