#
# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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

	t.name = "sbs_with_nonexisting_bldinf"
	t.description = "Test if sbs generates warning if invoked without bld.inf specified i.e. using default bld.inf which doesn't exist"
	t.command = "mkdir ${EPOCROOT}/emptydir; rm ${EPOCROOT}/emptydir/*;  cd ${EPOCROOT}/emptydir; sbs -f ${SBSLOGFILE} -m {SBSMAKEFILE}"
	t.usebash = True
	t.warnings = 1 
	t.run()
	
	t.name = "sbs_with_nonexisting_bldinf_cli"
	t.description = "Test if sbs generates an error if invoked with a bad -b option"
	t.command = "sbs -b none.inf"
	t.usebash = False
	t.errors = 1
	t.warnings = 0
	t.returncode = 1
	t.mustmatch = ["sbs: error: build info file does not exist \(component .*none.inf\)"] 
	t.run()
	
	t.print_result()
	return t
