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
	t.id = "40"
	t.name = "mmp_newlib_keyword"
	t.description = "Test the NEWLIB MMP keyword by specifying an invalid " + \
			"library to link against"
	t.command = "sbs -b smoke_suite/test_resources/newlib/bld.inf"
	# 1 error is expected because the NEWLIB library we are trying to link
	# Against does not exist
	t.errors = 1
	t.run()
	return t
