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

def run():
	t = SmokeTest()
	t.description = "This testcase tests specific cases of using APPLY"
	t.usebash = True

	# Introduce LINKER_OPTIONS for tools2 linker
	t.id = "0108"
	t.name = "apply_linker_options"
	t.command = "sbs -b smoke_suite/test_resources/apply_usecases/linker_options/bld.inf -c tools2 -f -"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/tools2/rel/test_apply_linkeroptions.exe"
		]
	t.addbuildtargets("smoke_suite/test_resources/apply_usecases/linker_options/bld.inf", [
		"test_apply_linkeroptions_/test_apply_linkeroptions_exe/tools2/deb/test_apply_linkeroptions.o",
		"test_apply_linkeroptions_/test_apply_linkeroptions_exe/tools2/rel/test_apply_linkeroptions.o"
	])
	t.mustmatch = ["-lwsock32"]
	t.run("windows")

	return t
