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
import generic_path
import os

def run():
	t = SmokeTest()
	t.usebash = True
	result = SmokeTest.PASS

	abs_epocroot = os.path.abspath(os.environ["EPOCROOT"])
	cwd = os.getcwd().replace("\\","/")

	relative_epocroot = os.path.relpath(abs_epocroot.replace("\\","/"),cwd)

	
	description = """This tests the whatcomp filter.  As a byproduct it uses (and thus smoke-tests) sbs_filter.py"""
	command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c %s -m ${SBSMAKEFILE} -f ${SBSLOGFILE} what  && " + \
		  "EPOCROOT='%s' sbs_filter --filters FilterWhatComp < ${SBSLOGFILE} &&" % relative_epocroot + \
		  "EPOCROOT='%s' sbs_filter --filters FilterWhatComp < ${SBSLOGFILE}"  % abs_epocroot
	targets = [
		]	
	buildtargets = [
		]

	mustmatch_pre = [
		"-- abld -w",
		".*Chdir .*/smoke_suite/test_resources/simple.*",
		relative_epocroot + "/epoc32/release/armv5/urel/test.exe",
		relative_epocroot + "/epoc32/release/armv5/urel/test.exe.map",
		abs_epocroot + "/epoc32/release/armv5/urel/test.exe",
		abs_epocroot + "/epoc32/release/armv5/urel/test.exe.map",
	] 
	
	if os.sep == '\\':
		mustmatch = [ i.replace("\\", "\\\\" ).replace("/","\\\\") for i in mustmatch_pre ]
	else:
		mustmatch = mustmatch_pre

	mustnotmatch = [
	"error: no (CHECK|WHAT) information found"
	]
	warnings = 0
	
	t.id = "0106a"
	t.name = "whatcomp_basic"
	t.description = description
	t.command = command % "arm.v5.urel.gcce4_4_1"
	t.targets = targets
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.warnings = warnings
	t.run()

	t.id = "0106b"
	t.name = "whatcomp_component_repeated"
	t.description = """
			It is possible for what information about a component to not be grouped
			(i.e. for multiple whatlogs tags relating to a single component to be 
			interspersed with whatlog tags relating to other components).  
			Raptor must cope with that and must *not* report missing files under 
			the wrong component name."""
	t.command = "sbs_filter --filters=FilterWhatComp < smoke_suite/test_resources/logexamples/what_component_repeated.log"
	t.targets = []
	t.mustmatch = [] 
	t.mustmatch_multiline = [ 
		"Chdir y:.ext.app.emailwizard.*epoc32.data.something.*"+
		"Chdir y:.sf.mw.gsprofilesrv.ftuwizardmodel.*epoc32.release.armv5.something.*"+
		"Chdir y:.ext.app.emailwizard.*epoc32.data.something_else"
		]

	t.mustnotmatch = []
	t.warnings = 0
	t.run()

	t.id = "0106"
	t.name = "whatcomp"
	t.print_result()
	return t
