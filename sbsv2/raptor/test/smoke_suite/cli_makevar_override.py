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
# The mechanism for dealing with this was removed as the fix for SF bug 2134
# On the CLI, "something=something" is now treated as a target rather than a variable assignment

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.name = "cli_makevar_overide"
	t.id = "0117"
	t.description = "Attempt to override a makefile var at the command line."
	t.usebash = True
	
	t.command = "sbs -b smoke_suite/test_resources/basics/helloworld/Bld.inf REALLYCLEAN -m ${SBSMAKEFILE} -f ${SBSLOGFILE} HOSTPLATFORM_DIR=unlikelydir"  
	
	t.mustmatch = ["sbs: warning: CLEAN, CLEANEXPORT and a REALLYCLEAN should not be combined with other targets as the result is unpredictable"]
	
	t.warnings = 1
	t.run()
	
	return t
	