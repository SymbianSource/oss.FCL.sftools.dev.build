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
	t.id = "14"
	t.name = "implib_armv5"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/bld.inf" \
		+ " -c armv5 LIBRARY"
	# ABIv1 .lib files are not generated on Linux
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.dso"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_implib/bld.inf', [
		['simple_implib_lib/armv5/udeb/simple_implib.prep',
                 'simple_implib_lib/armv5/urel/simple_implib.prep']
	])
	t.run("linux")
	# Run test on Windows if that is the current OS
	if t.result == SmokeTest.SKIP:
		t.targets.extend([
			"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.lib",
			"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.lib"
		])
		t.run("windows")
		
	return t
