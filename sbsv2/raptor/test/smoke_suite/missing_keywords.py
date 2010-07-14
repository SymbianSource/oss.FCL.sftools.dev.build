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
	t.name = "missing_keywords"

	t.command = "sbs -b smoke_suite/test_resources/invalid_metadata/bld.inf -c armv5"

	t.mustmatch_singleline = [
		"sbs: error: required keyword TARGET is missing"
		]

	t.errors = 1
	t.returncode = 1
	t.run()
	return t
