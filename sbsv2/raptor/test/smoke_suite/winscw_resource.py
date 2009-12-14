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
	t.id = "38"
	t.name = "winscw_resource"
	t.command = "sbs -b smoke_suite/test_resources/resource/group/bld.inf -c " \
			+ "winscw RESOURCE"
	t.targets = [
		"$(EPOCROOT)/epoc32/include/testresource.rsg",
		"$(EPOCROOT)/epoc32/include/testresource.hrh",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.r01",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/testresource/testresource.r01",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/testresource/testresource.r01",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/testresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/testresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/localisation/group/testresource.info",
		"$(EPOCROOT)/epoc32/localisation/testresource/rsc/testresource.rpp"
		]
	t.run()
	return t
