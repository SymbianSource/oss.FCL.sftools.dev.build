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
	t.id = "42"
	t.name = "emulated_drives"
	t.command = "sbs -b " + \
			"smoke_suite/test_resources/emulated_drives_export/bld.inf EXPORT"
	t.targets = [
		"$(EPOCROOT)/epoc32/data/c/private/10001234/policy/emulated_drives_export2.mbm",
		"$(EPOCROOT)/epoc32/winscw/c/private/10001234/policy/emulated_drives_export2.mbm",
		"$(EPOCROOT)/epoc32/data/z/private/10001234/policy/emulated_drives_export1.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/private/10001234/policy/emulated_drives_export1.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/private/10001234/policy/emulated_drives_export1.mbm"
		]
	t.run()
	return t
