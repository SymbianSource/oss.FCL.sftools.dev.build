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
	t.usebash = True
	result = SmokeTest.PASS

	description = """This test covers parallel parsing."""
	command = "cd $(SBS_HOME)/test/smoke_suite/test_resources/pp/ && sbs --command=$(SBS_HOME)/test/smoke_suite/test_resources/pp/ppbldinf_commandfile -c armv5 -c winscw --pp=on --noexport -m ${SBSMAKEFILE} -f - | grep recipe "

	mmpcount = 10 # how many mmps in this parallel parsing test

	
	target_templ = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_pp#.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_pp#.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_pp#.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_pp#.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_pp#.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_pp#.exe.sym"
	]

	targets = []

	# Build up target list for 10 similar executables
	for num in range(1,mmpcount):
		for atarget in target_templ:
			targets.append(atarget.replace('pp#','pp'+ str(num)))

	mustmatch = [
		".*<recipe .*name='makefile_generation.*",
	]
	mustnotmatch = [
		".*<recipe .*name='makefile_generation_export.*",
		".*<error[^><]*>.*"
	]

	warnings = 0
		
	t.id = "104"
	t.name = "parallel_parsing"
	t.description = description
	t.command = command 
	t.targets = targets
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.warnings = warnings
	t.run()
	return t
