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
from raptor_tests import ReplaceEnvs
import os
import sys

def run():
	t = SmokeTest()
	t.description =  """talon_test: two part test
	1) Test talon's -c option
	2) Test talon with a script file that has some blank lines and a single non-blank command line
	"""

	# Don't need these as we are not invoking Raptor
	t.logfileOption = lambda : ""
	t.makefileOption = lambda : ""

	# Set up variables for talon
	bindir = ReplaceEnvs("$(SBS_HOME)/$(HOSTPLATFORM_DIR)/bin")
	bash = bindir + "/bash"
	talon = bindir + "/talon"

	# Adjust if on Windows - three "tries" for Bash on Windows.
	# 1 Default try
	if "win" in sys.platform.lower():
		bash = ReplaceEnvs("$(SBS_HOME)/win32/cygwin/bin/bash.exe")
		talon = ReplaceEnvs("$(SBS_HOME)/$(HOSTPLATFORM_DIR)/bin/talon.exe")
	
	# 2 Bash from a Cygwin
	if os.environ.has_key("SBS_CYGWIN"):
		bash = ReplaceEnvs("$(SBS_CYGWIN)/bin/bash.exe")
	
	# 3 Bash from an env. var.
	if os.environ.has_key("SBS_SHELL"):
		bash = os.environ["SBS_SHELL"]
	
	# Talon's command line
	commandline="\"|name=commandlinetest;COMPONENT_META=commandline/group/bld.inf;PROJECT_META=commandline.mmp;|echo Command line invocation output\""
	
	# Talon's "shell script"
	scriptfile=ReplaceEnvs("$(SBS_HOME)/test/smoke_suite/test_resources/talon_test/script")
	
	# Environment variables needed by talon - TALON_SHELL must be bash; the other two can be arbitrary.
	os.environ["TALON_SHELL"]=bash
	os.environ["TALON_BUILDID"]=str(t.id)
	os.environ["TALON_RECIPEATTRIBUTES"]="component=talontest"

	# First part of test - command line
	t.name = "talon_test command line"
	t.id = "100a"
	t.command = "%s -c %s" % (talon, commandline)
	t.targets = []
	t.mustmatch_multiline = ["<recipe component=talontest>.*<!\[CDATA\[.*\+ echo Command line invocation output" + 
			".*\]\]><time start='\d+\.\d+' elapsed='\d+\.\d+' />" + 
			".*<status exit='ok' attempt='1' />.*</recipe>"]

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# Second part of test - script file
	t.name = "talon_test script file"
	t.id = "100b"
	t.command = "%s %s" % (talon, scriptfile)
	t.targets = []
	t.mustmatch_multiline = ["<recipe component=talontest>.*<!\[CDATA\[.*\+ echo Script file output" + 
			".*\]\]><time start='\d+\.\d+' elapsed='\d+\.\d+' />" + 
			".*<status exit='ok' attempt='1' />.*</recipe>"]

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	

	# Print final result
	t.name = "talon_test"
	t.id = "100"
	t.print_result()

	# Delete the added environment variables
	del os.environ["TALON_SHELL"]
	del os.environ["TALON_BUILDID"]
	del os.environ["TALON_RECIPEATTRIBUTES"]

	return t
