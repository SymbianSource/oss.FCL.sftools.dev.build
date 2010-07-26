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
	t.id = "37"
	t.name = "implib_winscw_what"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/bld.inf -c " \
			+ "winscw --what LIBRARY"
	t.stdout = [
		'$(EPOCROOT)/epoc32/release/winscw/udeb/simple_implib.lib'
	]
	t.run()
	return t
