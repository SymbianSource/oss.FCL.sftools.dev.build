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
import generic_path
import os

def run():
	t = SmokeTest()
	t.usebash = True
	result = SmokeTest.PASS

	abs_epocroot = os.path.abspath(os.environ["EPOCROOT"]).replace("\\","/")
	cwd = os.getcwd().replace("\\","/")

	relative_epocroot = os.path.relpath(abs_epocroot,cwd).replace("\\","/")

	

	description = """This tests the whatcomp filter.  As a byproduct it uses (and thus smoke-tests) sbs_filter.py"""
	command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c %s -m ${SBSMAKEFILE} -f ${SBSLOGFILE} what  && " + \
		  "EPOCROOT=%s sbs_filter --filters FilterWhatComp < ${SBSLOGFILE} &&" % relative_epocroot + \
		  "EPOCROOT=%s sbs_filter --filters FilterWhatComp < ${SBSLOGFILE}"  % abs_epocroot
	targets = [
		]	
	buildtargets = [
		]
	mustmatch = [
		"-- abld -w",
		"Chdir .*/smoke_suite/test_resources/simple",
		relative_epocroot + "/epoc32/release/armv5/urel/test.exe",
		relative_epocroot + "/epoc32/release/armv5/urel/test.exe.map",
		abs_epocroot + "/epoc32/release/armv5/urel/test.exe",
		abs_epocroot + "/epoc32/release/armv5/urel/test.exe.map",
	] 
	mustnotmatch = [
	"error: no (CHECK|WHAT) information found"
	]
	warnings = 0
	
	t.id = "0106"
	t.name = "filter_whatcomp_sbs_filter"
	t.description = description
	t.command = command % "arm.v5.urel.gcce4_4_1"
	t.targets = targets
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.warnings = warnings
	t.run()

	t.print_result()
	return t
