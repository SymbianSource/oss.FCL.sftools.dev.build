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
	t.description = "Tests Raptor can build win32 tools on linux"

	t.id = "111a"
	t.name = "tools2_cross_compilation_pdrtran" 
	t.command = "sbs -b smoke_suite/test_resources/tools2/cross/BLD.INF -p PDRTRAN.MMP -c tools2 -c tools2.win32"

	t.targets = [
			"$(EPOCROOT)/epoc32/release/tools2/deb/pdrtran.exe",
			"$(EPOCROOT)/epoc32/release/tools2/rel/pdrtran.exe",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/deb/pdrtran",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/rel/pdrtran",
			"$(EPOCROOT)/epoc32/tools/pdrtran.exe",
			"$(EPOCROOT)/epoc32/tools/pdrtran"
			]
	t.addbuildtargets("smoke_suite/test_resources/tools2/cross/BLD.INF", [
			"pdrtran_/pdrtran_exe/tools2/deb/PDRTRAN.o",
			"pdrtran_/pdrtran_exe/tools2/deb/LEXICAL.o",
			"pdrtran_/pdrtran_exe/tools2/deb/PDRREADR.o",
			"pdrtran_/pdrtran_exe/tools2/deb/PDRRECRD.o",
			"pdrtran_/pdrtran_exe/tools2/deb/READER.o",
			"pdrtran_/pdrtran_exe/tools2/deb/RECORD.o",
			"pdrtran_/pdrtran_exe/tools2/deb/STRNG.o",
			"pdrtran_/pdrtran_exe/tools2/rel/PDRTRAN.o",
			"pdrtran_/pdrtran_exe/tools2/rel/LEXICAL.o",
			"pdrtran_/pdrtran_exe/tools2/rel/PDRREADR.o",
			"pdrtran_/pdrtran_exe/tools2/rel/PDRRECRD.o",
			"pdrtran_/pdrtran_exe/tools2/rel/READER.o",
			"pdrtran_/pdrtran_exe/tools2/rel/RECORD.o",
			"pdrtran_/pdrtran_exe/tools2/rel/STRNG.o",
			"pdrtran_/pdrtran_exe/tools2/deb/$(HOSTPLATFORM_DIR)/PDRTRAN.o",
			"pdrtran_/pdrtran_exe/tools2/deb/$(HOSTPLATFORM_DIR)/LEXICAL.o",
			"pdrtran_/pdrtran_exe/tools2/deb/$(HOSTPLATFORM_DIR)/PDRREADR.o",
			"pdrtran_/pdrtran_exe/tools2/deb/$(HOSTPLATFORM_DIR)/PDRRECRD.o",
			"pdrtran_/pdrtran_exe/tools2/deb/$(HOSTPLATFORM_DIR)/READER.o",
			"pdrtran_/pdrtran_exe/tools2/deb/$(HOSTPLATFORM_DIR)/RECORD.o",
			"pdrtran_/pdrtran_exe/tools2/deb/$(HOSTPLATFORM_DIR)/STRNG.o",
			"pdrtran_/pdrtran_exe/tools2/rel/$(HOSTPLATFORM_DIR)/PDRTRAN.o",
			"pdrtran_/pdrtran_exe/tools2/rel/$(HOSTPLATFORM_DIR)/LEXICAL.o",
			"pdrtran_/pdrtran_exe/tools2/rel/$(HOSTPLATFORM_DIR)/PDRREADR.o",
			"pdrtran_/pdrtran_exe/tools2/rel/$(HOSTPLATFORM_DIR)/PDRRECRD.o",
			"pdrtran_/pdrtran_exe/tools2/rel/$(HOSTPLATFORM_DIR)/READER.o",
			"pdrtran_/pdrtran_exe/tools2/rel/$(HOSTPLATFORM_DIR)/RECORD.o",
			"pdrtran_/pdrtran_exe/tools2/rel/$(HOSTPLATFORM_DIR)/STRNG.o"
			])
	t.run("linux")

	
	t.id = "111b"
	t.name = "tools2_cross_compilation_libs"
	t.command = "sbs -b smoke_suite/test_resources/tools2/bld.inf -c tools2.win32 -c tools2"

	t.targets = [
			"$(EPOCROOT)/epoc32/release/tools2/deb/tool_exe.exe",
			"$(EPOCROOT)/epoc32/release/tools2/deb/libtool_lib1.a",
			"$(EPOCROOT)/epoc32/release/tools2/deb/libtool_lib2.a",
			"$(EPOCROOT)/epoc32/release/tools2/rel/tool_exe.exe",
			"$(EPOCROOT)/epoc32/release/tools2/rel/libtool_lib1.a",
			"$(EPOCROOT)/epoc32/release/tools2/rel/libtool_lib2.a",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/deb/tool_exe",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/deb/libtool_lib1.a",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/deb/libtool_lib2.a",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/rel/tool_exe",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/rel/libtool_lib1.a",
			"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/rel/libtool_lib2.a",
			"$(EPOCROOT)/epoc32/tools/tool_exe.exe",
			"$(EPOCROOT)/epoc32/tools/tool_exe"
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
			"tool_exe_exe/tool_exe_exe/tools2/deb/tool_exe_a.o",
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
	t.run("linux")


	t.usebash = True
	t.id = "111c"
	t.name = "tools2_cross_compilation_toolcheck_linux"
	t.command = "$(EPOCROOT)/epoc32/tools/pdrtran smoke_suite/test_resources/tools2/cross/TEST.PD $(EPOCROOT)/epoc32/build/TEST_PDRTRAN.PDR"
	t.targets = [
		 	"$(EPOCROOT)/epoc32/build/TEST_PDRTRAN.PDR"
			]
	t.mustmatch = [
			"PDRTRAN V41"
			]		
	t.run("linux")

	
	t.id = "111d"
	t.name = "tools2_cross_compilation_toolcheck_windows"
	t.command = "file $(EPOCROOT)/epoc32/tools/pdrtran.exe"
	t.targets = []
	t.mustmatch = [
			"MS Windows"
			]		
	t.run("linux")


	t.id = "111e"
	t.name = "tools2_cross_compilation_platmacro_linux"
	t.command = "sbs -b smoke_suite/test_resources/tools2/cross/BLD.INF -p platmacros.mmp -c tools2"
	t.targets = [
			"$(EPOCROOT)/epoc32/tools/test_platmacros"
			]
	t.mustmatch = [
			"TOOLS2_LINUX"
			]
	t.mustnotmatch = [
			"TOOLS2_WINDOWS"
			]
	t.warnings = 1
	t.run("linux")


	t.id = "111f"
	t.name = "tools2_cross_compilation_platmacro_windows"
	t.command = "sbs -b smoke_suite/test_resources/tools2/cross/BLD.INF -p platmacros.mmp -c tools2.win32"
	t.targets = [
			"$(EPOCROOT)/epoc32/tools/test_platmacros.exe"
			]
	t.mustmatch = [
			"TOOLS2_WINDOWS"
			]
	t.mustnotmatch = [
			"TOOLS2_LINUX"
			]
	t.warnings = 1
	t.run("linux")


	t.id = "111"
	t.name = "tools2_cross_compilation"
	t.print_result()
	return t
