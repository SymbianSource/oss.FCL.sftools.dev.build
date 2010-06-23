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
	t.id = "81"
	t.name = "export_multi"
	t.description = "Test that the export section only gets included once even if all platforms are selected (see DPDEF138366)"
	# Note I'm not including 'tools' to avoid a dependency on MSVC6
	# Given this test will not be necessary once the export section is removed from the make files anyway, I'm not too worried.
	t.command = "sbs -b smoke_suite/test_resources/basics/helloworld/Bld.inf -c winscw -c armv5 -c tools2 -c armv7 -c gccxml EXPORT"
	t.mustnotmatch = [
		".*warning: overriding commands for target.*",
		".*warning: ignoring old commands for target.*"
	]
	t.run()
	return t
