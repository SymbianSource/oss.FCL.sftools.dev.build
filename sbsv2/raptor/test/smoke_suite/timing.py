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
	
	t.description = "Test that a timing log is created and contains total parse and build durations"

	t.id = "0103b"
	t.name = "timing_on"
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf" + \
			" --filters=FilterLogfile,FilterTiming -f ${SBSLOGFILE} && " + \
			"grep progress:duration ${SBSLOGFILE}.timings"
	t.mustmatch = [
			"^<progress:duration object_type='layer' task='parse' key='.*' duration='\d+.\d+' />$",
			"^<progress:duration object_type='layer' task='build' key='.*' duration='\d+.\d+' />$",
			"^<progress:duration object_type='all' task='all' key='all' duration='\d+.\d+' />$"
			]
	t.mustnotmatch = []
	t.run()


	t.id = "103"
	t.name = "timing"
	t.print_result()
	
	return t

