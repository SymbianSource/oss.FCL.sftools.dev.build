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
import os

def run():
	t = SmokeTest()
	t.id = "55"
	t.name = "romfile"
	t.description = """
		Tests the creation and content of an .iby romfile for the armv5.test
		configuration. Also tests for creation of relevant test batch files.
		"""
	t.usebash = True
	t.command = "sbs -b $(EPOCROOT)/src/ongoing/group/romfile/other_name.inf " \
			+ "-c armv5.test ROMFILE -f - " \
			+ "&& cat $(EPOCROOT)/epoc32/rom/src/ongoing/group/romfile/armv5test.iby"
	
	# Don't allow -m or -f to be appended
	t.logfileOption = lambda :""
	t.makefileOption = lambda :""
	t.targets = [
		"$(EPOCROOT)/epoc32/rom/src/ongoing/group/romfile/armv5test.iby",
		"$(EPOCROOT)/epoc32/data/z/test/src/armv5.auto.bat",
		"$(EPOCROOT)/epoc32/data/z/test/src/armv5.manual.bat"
		]

	# Check the content of the generated .iby file.

	t.mustmatch = [
		# Check whatlog output includes batch files and .iby file
		r".*/epoc32/rom/src/ongoing/group/romfile/armv5test.iby</build>.*",
		r".*/epoc32/data/z/test/src/armv5.auto.bat</build>.*",
		r".*/epoc32/data/z/test/src/armv5.manual.bat</build>.*",
		
		# The comment that is put at the start of the file.
		r".*// epoc32/rom/src/ongoing/group/romfile/armv5test\.iby\n.*",

		# The batch files that are added by the build system.
		r".*\ndata=/epoc32/data/z/test/src/armv5\.auto\.bat test/src\.auto\.bat\n.*",
		r".*\ndata=/epoc32/data/z/test/src/armv5\.manual\.bat test/src\.manual\.bat\n.*",

		# Some normal files.
		r".*\nfile=/epoc32/release/##MAIN##/##BUILD##/t_rand\.exe\s+sys/bin/t_rand\.exe\n.*",
		r".*\nfile=/epoc32/release/##MAIN##/##BUILD##/t_swapfsys\.exe\s+sys/bin/t_swapfsys\.exe\n.*",
		r".*\nfile=/epoc32/release/##MAIN##/##BUILD##/t_localtime\.exe\s+sys/bin/t_localtime\.exe\n.*",

		# Some files where the MMP file has the PAGED or UNPAGED keywords.
		r".*\nfile=/epoc32/release/##MAIN##/##BUILD##/t_pagestress\.exe\s+sys/bin/t_pagestress\.exe paged\n.*",
		r".*\nfile=/epoc32/release/##MAIN##/##BUILD##/t_fsys\.exe\s+sys/bin/t_fsys\.exe unpaged\n.*",

		# Some files where the MMP file has the ROMTARGET or RAMTARGET keywords.
		r".*\ndata=/epoc32/release/##MAIN##/##BUILD##/t_prel\.dll\s+/sys/bin/t_prel\.dll attrib=r\n.*",
		r".*\nfile=/epoc32/release/##MAIN##/##BUILD##/t_sysbin\.exe\s+sys/bin/t_sysbin\.exe\n.*",
		r".*\ndata=/epoc32/release/##MAIN##/##BUILD##/t_sysbin\.exe\s+/sys/bin/t_sysbin_ram\.exe attrib=r\n.*",
		r".*\nfile=/epoc32/release/##MAIN##/##BUILD##/t_sysbin\.exe\s+/sys/bin/t_sysbina\.exe\n.*",
		r".*\nfile=/epoc32/release/##MAIN##/##BUILD##/t_sysbin\.exe\s+/system/programs/t_sysbinb\.exe\n.*"
		]
	t.mustnotmatch = [
		# Try to detect file paths that contain two or more slashes in a row,
		# without flagging C++ style comments.
		r"\w//+\w"
		]

	t.run("windows")

	if t.result == SmokeTest.SKIP:
		t.command = "sbs -b $(EPOCROOT)/src/ongoing/group/romfile/other_name.inf" \
				+ " -c armv5.test ROMFILE -f -" \
				+ " && cat $(EPOCROOT)/epoc32/rom/src/ongoing/group/romfile/armv5test.iby"

		# These two warnings are because gnumakefiles are not supported on
		# Linux:
		t.warnings = 2
		t.run("linux")

	return t
