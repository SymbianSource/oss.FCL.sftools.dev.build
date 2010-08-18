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

# NB - the checksource filter can find the same problem twice
# So the count of 5 errors here is not actually accurate (AFAIK there are only 4)


from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "88"
	t.name = "exe_checksource"
	t.description = "Build a exe with a checksource filter"
	t.usebash = True
	
	bldinf = "smoke_suite/test_resources/checksource/helloworld/bld.inf"
	cmd1 = "sbs -b %s REALLYCLEAN -m ${SBSMAKEFILE} -f ${SBSLOGFILE}" % bldinf
	cmd2 = "sbs -b %s --filter=FilterCheckSource -m ${SBSMAKEFILE} -f ${SBSLOGFILE}" % bldinf
	cmd3 = "grep -i '.*checksource errors found.*' ${SBSLOGFILE}"
	t.command = cmd1 + " && " + cmd2 + " && " + cmd3

	t.mustmatch_singleline = ["[1-9] checksource errors found"]
	
	t.returncode = 1
	t.run("windows")
	return t
