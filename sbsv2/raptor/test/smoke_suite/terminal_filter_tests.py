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
	t.id = "87"
	t.name = "terminal_filter_tests"
	t.description = "terminal_filter_tests: Tests the terminal filter against" \
			+ " log files to ensure it 'does the right thing'"
	t.command = "$(SBS_HOME)/test/smoke_suite/test_resources/refilter/testfilterterminal"
	t.countmatch = [
		# One of each type of error occurs early in the 'sbs' call where there
		# is a recipe inside another recipe. Then the errors occur in the
		# opposite order where are 2 closing tags next to each other before 2
		# opening tags appear next to each other
			["sbs: error: Opening recipe tag found before closing recipe tag for previous recipe:", 2],
			["Discarding previous recipe \(Possible logfile corruption\)", 2],
			["sbs: error: Closing recipe tag found before opening recipe tag:", 2],
			["Unable to print recipe data \(Possible logfile corruption\)", 2]
	]
	t.errors = 4
	t.run()
	return t
