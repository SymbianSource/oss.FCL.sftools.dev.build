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
	t.id = "80"
	t.name = "sbs_with_nonexisting_bldinf"
	t.description = "Test if sbs generates warning if invoked without bld.inf specified i.e. using default bld.inf which doesn't exist"
	t.command = "mkdir ${EPOCROOT}/emptydir; rm ${EPOCROOT}/emptydir/*;  cd ${EPOCROOT}/emptydir; sbs -f ${SBSLOGFILE} -m {SBSMAKEFILE}"
	t.usebash = True
	t.warnings = 1 
	t.run()
	return t
