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
import sys

def run():
	t = SmokeTest()
	t.id = "58"
	t.name = "lib_versioned"
	t.command = "sbs -b smoke_suite/test_resources/versioned_lib/bld.inf" + \
		    " -b smoke_suite/test_resources/versioned_lib/dllversioning.inf" + \
		    " -c armv5 -c winscw "
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/testver.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testver{00020000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testver{00030000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/version.ed.lib.04.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/version.ed.lib{000a0000}.04.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versioned.lib.03.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versioned.lib{000a0000}.03.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versionedlib.02.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versionedlib01.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versionedlib01{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versionedlib{000a0000}.02.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/testver.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/testver.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/testver{00020000}.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/testver{00020000}.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testver.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testver.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testver{00020000}.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testver{00020000}.dll.sym",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/version.ed.lib.04.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/versioned.lib.03.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/versionedlib.02.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/versionedlib01.lib"
		]

	if sys.platform.lower().startswith("win"):
		t.targets.extend (	
		[
		"$(EPOCROOT)/epoc32/release/armv5/lib/testver.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versionedlib01.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versioned.lib.03.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versionedlib.02.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testver{00020000}.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testver{00030000}.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versioned.lib{000a0000}.03.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/version.ed.lib.04.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/version.ed.lib{000a0000}.04.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versionedlib01{000a0000}.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/versionedlib{000a0000}.02.lib"
		] )
		
	t.run()
	return t
