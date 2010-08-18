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

from raptor_tests import AntiTargetSmokeTest

def run():

	t = AntiTargetSmokeTest()
	t.id = "99"
	t.name = "unfrozen_savespace"

	t.command = "sbs -b smoke_suite/test_resources/unfrozen/bld.inf -k -c winscw -c armv5 CLEAN" \
				" && sbs -b smoke_suite/test_resources/unfrozen/bld.inf -c winscw.savespace -c armv5.savespace"

	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols2.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/unfrozensymbols2{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols2.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols2.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/unfrozensymbols2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_unfrozen.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_unfrozen.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/test_unfrozen.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/unfrozensymbols.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/unfrozensymbols.dll.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/unfrozensymbols2.dll",
		"$(EPOCROOT)/epoc32/release/winscw/urel/unfrozensymbols2.dll.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test_unfrozen.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test_unfrozen.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols2.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols2.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/unfrozensymbols2.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_unfrozen.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_unfrozen.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test_unfrozen.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/unfrozensymbols.dll",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/unfrozensymbols.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/unfrozensymbols2.dll",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/unfrozensymbols2.lib",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test_unfrozen.exe"
		]

	t.antitargets = []

	t.addbuildantitargets('smoke_suite/test_resources/unfrozen/bld.inf', [
		"test_unfrozen_/armv5/udeb",
		"test_unfrozen_/armv5/urel",
		"test_unfrozen_/winscw/udeb",
		"test_unfrozen_/winscw/urel"
		# TODO: Add these anti targets once we figure out how to actually delete
		# them.
		# "unfrozensymbols2_dll/armv5/udeb",
		# "unfrozensymbols2_dll/armv5/urel",
		# "unfrozensymbols2_dll/winscw/udeb",
		# "unfrozensymbols2_dll/winscw/urel",
		# "unfrozensymbols_dll/armv5/udeb",
		# "unfrozensymbols_dll/armv5/urel",
		# "unfrozensymbols_dll/winscw/udeb",
		# "unfrozensymbols_dll/winscw/urel"
		] )

	t.countmatch = [
			[".*Elf2e32: Warning: New Symbol .* found, export\(s\) not yet Frozen.*", 14],
			[".*\.def\(\d\) : .*@\d.*", 10]
		]

	t.warnings = 8

	t.run()

	return t

