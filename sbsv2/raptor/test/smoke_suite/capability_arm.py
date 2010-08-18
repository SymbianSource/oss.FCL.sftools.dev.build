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

from raptor_tests import SmokeTest
import sys

def run():
	t = SmokeTest()
	t.usebash = True


	if sys.platform.startswith("win"):
		elf2e32 = "$(EPOCROOT)/epoc32/tools/elf2e32.exe"
	else:
		elf2e32 = "$(EPOCROOT)/epoc32/tools/elf2e32"

	description = """This test attempts to check that an exe gets the capabilities that we requested.  It's ARM specific since it uses elf2e32. Tries to demonstrate capabilties being turned off then on in the mmp."""
	command = "sbs -b smoke_suite/test_resources/simple/capability.inf -c %s -m ${SBSMAKEFILE} -f ${SBSLOGFILE} && " + \
			  elf2e32 + " --dump=s  --e32input=$(EPOCROOT)/epoc32/release/armv5/urel/test_capability.exe"
	targets = [
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_capability.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_capability.exe.map"
		]	
	buildtargets = [
		]
	mustmatch = [
		"\s*Secure ID: 10003a5c$",
		"\s*Vendor ID: 00000000$",
		"\s*Capabilities: 00000000 000fffbf$",
		"\s*CommDD$",
		"\s*PowerMgmt$",
		"\s*MultimediaDD$",
		"\s*ReadDeviceData$",
		"\s*WriteDeviceData$",
		"\s*TrustedUI$",
		"\s*DiskAdmin$",
		"\s*NetworkControl$",
		"\s*AllFiles$",
		"\s*SwEvent$",
		"\s*NetworkServices$",
		"\s*LocalServices$",
		"\s*ReadUserData$",
		"\s*WriteUserData$",
		"\s*Location$",
		"\s*SurroundingsDD$",
		"\s*UserEnvironment$",
		"\s*TCB$"
	]
	mustnotmatch = [
		"DRM"
	]
	warnings = 0
	
	t.id = "0107"
	t.name = "capability_arm"
	t.description = description
	t.command = command % "arm.v5.urel.gcce4_4_1"
	t.targets = targets
	t.mustmatch = mustmatch
	t.mustnotmatch = mustnotmatch
	t.warnings = warnings
	t.run()
	return t
