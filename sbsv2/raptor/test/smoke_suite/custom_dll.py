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


from raptor_tests import SmokeTest 

def run():
	t = SmokeTest()
	t.name = "custom_dll"
	t.usebash = True
	t.command = "SBS_ELF2E32=$SBS_HOME/test/smoke_suite/test_resources/custom_dll/elf2e32/windows/elf2e32.exe  sbs -b smoke_suite/test_resources/custom_dll/bld.inf -c armv5 --configpath=$SBS_HOME/test/smoke_suite/test_resources/custom_dll/config"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/customdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/customdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/customdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/customdll.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/customdll.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/customdll.dll.map"
		]
	# Windows-only until we know about a suitable linux version of the post-linker
	t.run("windows")
	return t
