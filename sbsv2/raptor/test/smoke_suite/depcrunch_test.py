#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
	t.usebash = True
	
	t.description = "Test that dependency crunching for resource dependency files produces expected output" 

	t.id = "43562999"
	t.name = "depcrunch"
	t.command = "python $SBS_HOME/bin/depcrunch.py --extensions mbg,rsg --assume EPOCROOT < smoke_suite/test_resources/depcrunch/dep2.rpp.d"
	t.stdout = [
		r"EPOCROOT/epoc32/build/resource/c_98665870f0168225/dependentresource_/dependentresource_dependentresource_sc.rpp: \\",
		r" EPOCROOT/testresource1.mbg \\",
		r" EPOCROOT/testresource2.rsg \\",
		r" EPOCROOT/testresource3.rsg \\",
		r" EPOCROOT/testresource4.mbg \\",
		r" EPOCROOT/testresource5.rsg \\",
		r" EPOCROOT/testresource6.mbg \\",
		r" EPOCROOT/testresource7.rsg \\",
		r" EPOCROOT/testresource8.mbg \\",
		r" EPOCROOT/testresource9.rsg "
		]
	t.run()


	t.print_result()
	
	return t

