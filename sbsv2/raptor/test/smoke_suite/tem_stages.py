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
	result = SmokeTest.PASS

	# export the TEM

	t = SmokeTest()
	t.id = "73a"
	t.name = "tem_stages"
	t.command = "sbs -b smoke_suite/test_resources/tem_stages/bld.inf EXPORT"
	t.targets = [
		"$(EPOCROOT)/epoc32/tools/makefile_templates/test/tem_stages.mk",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/test/tem_stages.meta"
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
	# run the main test

	t.id = "73b"
	t.name = "tem_stages"
	t.command = "sbs -b smoke_suite/test_resources/tem_stages/bld.inf"
	t.targets = [
		"$(EPOCROOT)/epoc32/build/generated/tem_stages_generated.cpp",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated.h",

		"$(EPOCROOT)/epoc32/include/tem_stages_generated_armv5_urel.rsg",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_armv5_udeb.rsg",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_winscw_urel.rsg",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_winscw_udeb.rsg",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_armv5_urel.lib",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_armv5_udeb.lib",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_winscw_urel.lib",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_winscw_udeb.lib",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_armv5_urel.bin",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_armv5_udeb.bin",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_winscw_urel.bin",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_winscw_udeb.bin",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_armv5_urel.final",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_armv5_udeb.final",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_winscw_urel.final",
		"$(EPOCROOT)/epoc32/include/tem_stages_generated_winscw_udeb.final",

		"$(EPOCROOT)/epoc32/release/armv5/urel/tem_stages.lib",
		"$(EPOCROOT)/epoc32/release/armv5/urel/tem_stages.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/tem_stages.lib",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/tem_stages.exe",

		"$(EPOCROOT)/epoc32/release/armv5/urel/tem_stages.lib2",
		"$(EPOCROOT)/epoc32/release/armv5/urel/tem_stages.exe2",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/tem_stages.lib2",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/tem_stages.exe2",

		"$(EPOCROOT)/epoc32/release/winscw/urel/tem_stages.lib",
		"$(EPOCROOT)/epoc32/release/winscw/urel/tem_stages.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/tem_stages.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/tem_stages.exe",

		"$(EPOCROOT)/epoc32/release/winscw/urel/tem_stages.lib2",
		"$(EPOCROOT)/epoc32/release/winscw/urel/tem_stages.exe2",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/tem_stages.lib2",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/tem_stages.exe2",
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# return the combined result

	t.id = "73"
	t.name = "tem_stages"
	t.result = result
	t.print_result()
	return t
