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
	t.id = "0096"
	t.name = "kdll_armv5"
	t.usebash = 1

	t.command = "sbs -b smoke_suite/test_resources/simple_kdll/bld.inf -c armv5_urel -f-"

	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_kdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_kdll.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_kdll.dll.sym"
		]

	t.mustmatch = [
		r".*\bksrt\d_\d\.lib\b.*",
		r".*\bekll\.lib\b.*"
		]

	t.mustnotmatch = [
		r".*usrt.*",
		r".*scppnwdl.*"
		]

	t.run()
	return t
