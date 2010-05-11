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
	t.mustmatch_multiline = [
		r"EPOCROOT/epoc32/build/resource/c_98665870f0168225/dependentresource_/dependentresource_dependentresource_sc.rpp: \\\n"+
		r" EPOCROOT/testresource1.mbg \\\n"+
		r" EPOCROOT/testresource2.rsg \\\n"+
		r" EPOCROOT/testresource3.rsg \\\n"+
		r" EPOCROOT/testresource4.mbg \\\n"+
		r" EPOCROOT/testresource5.rsg \\\n"+
		r" EPOCROOT/testresource6.mbg \\\n"+
		r" EPOCROOT/testresource7.rsg \\\n"+
		r" EPOCROOT/testresource8.mbg \\\n"+
		r" EPOCROOT/testresource9.rsg \n"
		]
	t.run()


	t.print_result()
	
	return t

