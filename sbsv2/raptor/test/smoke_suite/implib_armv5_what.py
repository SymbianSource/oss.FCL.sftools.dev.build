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

from raptor_tests import CheckWhatSmokeTest

def run():
	t = CheckWhatSmokeTest()
	t.id = "15"
	t.name = "implib_armv5_what"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/bld.inf -c " + \
			"armv5 --what LIBRARY"
	# ABIv1 .lib files are not generated on Linux
	t.stdout = [
		'$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.dso',
		'$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.dso'
	]
	t.run("linux")
	# Run test on Windows if that is the current OS
	if t.result == CheckWhatSmokeTest.SKIP:
		t.stdout.extend([
			'$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.lib',
			'$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.lib'
		])
		t.run("windows")
	
	return t
