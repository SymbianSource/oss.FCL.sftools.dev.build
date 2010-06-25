# -*- coding: iso-8859-1 -*- This line *must* be on the first line of the file!
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

	# Should have returncode of 1 and output 1 error, but not cause a traceback
	t.returncode = 1
	t.errors = 1
	t.mustmatch = ["sbs: error: Non-ASCII character in argument or command file"]

	result = SmokeTest.PASS

	t.id = "0091a"
	t.name = "non_ascii_argument"

	# The dash in "-c" is an en dash, not a normal ASCII dash.
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf –c armv5"

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	t.id = "0091b"
	t.name = "non_ascii_commandfile"

	t.command = "sbs --command=smoke_suite/test_resources/non_ascii/cmd.txt"

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	t.id = "91"
	t.name = "non_ascii"
	t.result = result
	t.print_result()
	return t

