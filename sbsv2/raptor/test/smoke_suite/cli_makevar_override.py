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

# Checks that functionality for overriding makefile varaibles at the command no longer works


from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.name = "cli_makevar_overide"
	t.description = "Attempt to override a makefile var at the command line."
	t.usebash = True
	
	bldinf = "smoke_suite/test_resources/basics/helloworld/bld.inf"
	cmd1 = "sbs -b %s REALLYCLEAN -m ${SBSMAKEFILE} -f ${SBSLOGFILE} HOSTPLATFORM_DIR=unlikelydir" % bldinf
	cmd2 = "grep -i 'unlikelydir' ${SBSMAKEFILE}"
	t.command = cmd1 + " && " + cmd2

	t.mustmatch_singleline = ["2"]
	
	t.warnings = 1
	t.returncode = 2
	t.run()
	return t
	