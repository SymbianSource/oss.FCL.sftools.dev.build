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
	t.id = "51"
	t.name = "tools2"
	t.command = "sbs -b smoke_suite/test_resources/tools2/bld.inf -c tools2"


	t.targets = [
		"$(EPOCROOT)/epoc32/release/tools2/deb/libtool_lib1.a",
		"$(EPOCROOT)/epoc32/release/tools2/deb/libtool_lib2.a",
		"$(EPOCROOT)/epoc32/release/tools2/deb/tool_exe.exe",
		"$(EPOCROOT)/epoc32/release/tools2/rel/libtool_lib1.a",
		"$(EPOCROOT)/epoc32/release/tools2/rel/libtool_lib2.a",
		"$(EPOCROOT)/epoc32/release/tools2/rel/tool_exe.exe",
		"$(EPOCROOT)/epoc32/tools/tool_exe.exe",
	]
	t.addbuildtargets("smoke_suite/test_resources/tools2/bld.inf", [
		"libtool_lib1_a/libtool_lib1_lib/tools2/rel/tool_lib1_b.o",
		"libtool_lib1_a/libtool_lib1_lib/tools2/rel/tool_lib1_a.o",
		"libtool_lib2_a/libtool_lib2_lib/tools2/rel/tool_lib2_b.o",
		"libtool_lib2_a/libtool_lib2_lib/tools2/rel/tool_lib2_a.o",
		"libtool_lib1_a/libtool_lib1_lib/tools2/deb/tool_lib1_b.o",
		"libtool_lib1_a/libtool_lib1_lib/tools2/deb/tool_lib1_a.o",
		"libtool_lib2_a/libtool_lib2_lib/tools2/deb/tool_lib2_a.o",
		"libtool_lib2_a/libtool_lib2_lib/tools2/deb/tool_lib2_b.o",
		"tool_exe_exe/tool_exe_exe/tools2/rel/tool_exe_a.o",
		"tool_exe_exe/tool_exe_exe/tools2/rel/tool_exe_b.o",
		"tool_exe_exe/tool_exe_exe/tools2/deb/tool_exe_b.o",
		"tool_exe_exe/tool_exe_exe/tools2/deb/tool_exe_a.o"
		])
			
	t.run("windows") # tools2 output is platform dependent

	if t.result == SmokeTest.SKIP:
		t.targets = [
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/deb/tool_exe",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/deb/libtool_lib1.a",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/deb/libtool_lib2.a",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/rel/tool_exe",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/rel/libtool_lib1.a",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/rel/libtool_lib2.a",
			"$(EPOCROOT)/epoc32/tools/tool_exe"
		]
		t.addbuildtargets("smoke_suite/test_resources/tools2/bld.inf", [
			"libtool_lib1_a/libtool_lib1_lib/tools2/rel/$(HOSTPLATFORM_DIR)/tool_lib1_b.o",
			"libtool_lib1_a/libtool_lib1_lib/tools2/rel/$(HOSTPLATFORM_DIR)/tool_lib1_a.o",
			"libtool_lib2_a/libtool_lib2_lib/tools2/rel/$(HOSTPLATFORM_DIR)/tool_lib2_b.o",
			"libtool_lib2_a/libtool_lib2_lib/tools2/rel/$(HOSTPLATFORM_DIR)/tool_lib2_a.o",
			"libtool_lib1_a/libtool_lib1_lib/tools2/deb/$(HOSTPLATFORM_DIR)/tool_lib1_b.o",
			"libtool_lib1_a/libtool_lib1_lib/tools2/deb/$(HOSTPLATFORM_DIR)/tool_lib1_a.o",
			"libtool_lib2_a/libtool_lib2_lib/tools2/deb/$(HOSTPLATFORM_DIR)/tool_lib2_a.o",
			"libtool_lib2_a/libtool_lib2_lib/tools2/deb/$(HOSTPLATFORM_DIR)/tool_lib2_b.o",
			"tool_exe_exe/tool_exe_exe/tools2/rel/$(HOSTPLATFORM_DIR)/tool_exe_a.o",
			"tool_exe_exe/tool_exe_exe/tools2/rel/$(HOSTPLATFORM_DIR)/tool_exe_b.o",
			"tool_exe_exe/tool_exe_exe/tools2/deb/$(HOSTPLATFORM_DIR)/tool_exe_b.o",
			"tool_exe_exe/tool_exe_exe/tools2/deb/$(HOSTPLATFORM_DIR)/tool_exe_a.o"
			])
		t.run("linux") # tools2 output is platform dependent
		
	return t
