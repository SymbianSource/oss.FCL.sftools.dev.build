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
	t.id = "50"
	t.name = "sysdef_dud"
	t.description = "Test an invalid system_definition.xml file"
	t.command = "sbs -s " + \
			"smoke_suite/test_resources/sysdef/system_definition_dud.xml"
	t.targets = []
	t.errors = 1
	t.returncode = 1
	t.run()
	return t
