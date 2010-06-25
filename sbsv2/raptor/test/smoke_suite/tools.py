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

def run():	
	t = SmokeTest()
	t.id = "52"
	t.name = "tools"
	t.command = "sbs -b smoke_suite/test_resources/tools/bld.inf -c tools"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/tools/deb/tool_exe.bsc",
		"$(EPOCROOT)/epoc32/release/tools/deb/tool_exe.exe",
		"$(EPOCROOT)/epoc32/release/tools/deb/tool_exe.ilk",
		"$(EPOCROOT)/epoc32/release/tools/deb/tool_lib1.bsc",
		"$(EPOCROOT)/epoc32/release/tools/deb/tool_lib1.lib",
		"$(EPOCROOT)/epoc32/release/tools/deb/tool_lib2.bsc",
		"$(EPOCROOT)/epoc32/release/tools/deb/tool_lib2.lib",
		"$(EPOCROOT)/epoc32/release/tools/rel/tool_exe.exe",
		"$(EPOCROOT)/epoc32/release/tools/rel/tool_lib1.lib",
		"$(EPOCROOT)/epoc32/release/tools/rel/tool_lib2.lib",
		"$(EPOCROOT)/epoc32/tools/tool_exe.exe",
		"$(EPOCROOT)/epoc32/tools/tool_lib1.lib",
		"$(EPOCROOT)/epoc32/tools/tool_lib2.lib"
		]
	t.addbuildtargets('smoke_suite/test_resources/tools/bld.inf', [
		"tool_exe_exe/tools/deb/tool_exe_a.obj",
		"tool_exe_exe/tools/deb/tool_exe_a.sbr",
		"tool_exe_exe/tools/deb/tool_exe_b.obj",
		"tool_exe_exe/tools/deb/tool_exe_b.sbr",
		"tool_exe_exe/tools/rel/tool_exe_a.obj",
		"tool_exe_exe/tools/rel/tool_exe_a.sbr",
		"tool_exe_exe/tools/rel/tool_exe_b.obj",
		"tool_exe_exe/tools/rel/tool_exe_b.sbr",
		"tool_lib1_lib/tools/deb/tool_lib1_a.obj",
		"tool_lib1_lib/tools/deb/tool_lib1_a.sbr",
		"tool_lib1_lib/tools/deb/tool_lib1_b.obj",
		"tool_lib1_lib/tools/deb/tool_lib1_b.sbr",
		"tool_lib1_lib/tools/rel/tool_lib1_a.obj",
		"tool_lib1_lib/tools/rel/tool_lib1_a.sbr",
		"tool_lib1_lib/tools/rel/tool_lib1_b.obj",
		"tool_lib1_lib/tools/rel/tool_lib1_b.sbr",
		"tool_lib2_lib/tools/deb/tool_lib2_a.obj",
		"tool_lib2_lib/tools/deb/tool_lib2_a.sbr",
		"tool_lib2_lib/tools/deb/tool_lib2_b.obj",
		"tool_lib2_lib/tools/deb/tool_lib2_b.sbr",
		"tool_lib2_lib/tools/rel/tool_lib2_a.obj",
		"tool_lib2_lib/tools/rel/tool_lib2_a.sbr",
		"tool_lib2_lib/tools/rel/tool_lib2_b.obj",
		"tool_lib2_lib/tools/rel/tool_lib2_b.sbr",
	])
	t.run("windows") # no MSVC compiler on Linux
	return t
