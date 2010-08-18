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
	t.id = "46"
	t.name = "wrong_projectname"
	t.description = "Test -p with wrong project name"
	t.command = "sbs -b smoke_suite/test_resources/basics/helloworld/Bld.inf " \
			+ "-p wrongname1.mmp -p wrongname2.mmp"
	t.targets = []
	t.warnings = 2 # One for armv5, one for winscw.
	t.run()
	return t
