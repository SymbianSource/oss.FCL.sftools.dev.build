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

from raptor_tests import AntiTargetSmokeTest
import os

def run():
	
	# This .inf file is created for clean_simple_export and
	# reallyclean_simple_export tests to use so that we can put the
	# username into the output filenames - which helps a lot when
	# several people run tests on the same computer (e.g. linux machines)
	bld_inf = open('smoke_suite/test_resources/simple_export/expbld.inf', 'w')
	user = os.environ['USER']
	bld_inf.write("""
	
PRJ_PLATFORMS
ARMV5 WINSCW

PRJ_MMPFILES
simple.mmp

PRJ_EXPORTS
#if !defined( WINSCW )
// Exports conditional on build configuration macros aren't actually supported,
// but we confirm that we preprocess in the context of an armv5 build when both
// winscw and armv5 configurations are (implicitly, as there's no "-c" argument)
// used.  This is in order to work around assumptions currently made in the
// source base.
simple_exp1.h exported_1.h
#endif
simple_exp2.h exported_2.h
simple_exp3.h exported_3.h
executable_file executable_file
"file with a space.doc" "exportedfilewithspacesremoved.doc"
"file with a space.doc" "exported file with a space.doc"

simple_exp1.h /tmp/{0}/  //
simple_exp2.h \\tmp\\{0}/  //
simple_exp3.h /tmp/{0}/simple_exp3.h 
simple_exp4.h //
read_only.h was_read_only.h //

""".format(user))
	bld_inf.close()
	
	exported_files = [
		"$(EPOCROOT)/epoc32/include/exported_1.h",
		"$(EPOCROOT)/epoc32/include/exported_2.h",
		"$(EPOCROOT)/epoc32/include/exported_3.h",
		"$(EPOCROOT)/epoc32/include/exportedfilewithspacesremoved.doc",
		"$(EPOCROOT)/epoc32/include/exported file with a space.doc",
		"/tmp/$(USER)/simple_exp1.h",
		"/tmp/$(USER)/simple_exp2.h",
		"/tmp/$(USER)/simple_exp3.h",
		"$(EPOCROOT)/epoc32/include/executable_file",
		"$(EPOCROOT)/epoc32/include/simple_exp4.h",
		"$(EPOCROOT)/epoc32/include/was_read_only.h",
		]

	t = AntiTargetSmokeTest()
	
	# Check basic export success
	t.name = "export_basic"
	t.command = "sbs -b smoke_suite/test_resources/simple_export/expbld.inf export"
	t.targets = exported_files
	t.antitargets = []
	t.run()
	
	# Confirm executable permissions are retained on Linux
	t.name = "export_executable_permissions"
	t.usebash = True
	t.command = "ls -l ${EPOCROOT}/epoc32/include/executable_file"
	t.mustmatch = [ "^.rwxrwxr.x[\.\+]? .*executable_file.*$" ]
	t.targets = [] # prevent auto clean-up up of target files from previous test
	t.antitargets = []
	t.run("linux")

	# Check clean does not delete exports
	t.name = "export_clean"
	t.command = "sbs -b smoke_suite/test_resources/simple_export/expbld.inf clean"
	t.mustmatch = []
	t.targets = exported_files
	t.antitargets = []
	t.run()

	# Confirm reallyclean deletes all exports, including those that were read-only
	# as source (and so should now be removable at their destination)
	t.name = "export_reallyclean" 
	t.command = "sbs -b smoke_suite/test_resources/simple_export/expbld.inf reallyclean"
	t.targets = []
	t.antitargets = exported_files
	t.run()

	# Check --noexport suppresses exports
	t.name = "export_noexport" 
	t.command = "sbs -b smoke_suite/test_resources/simple_export/expbld.inf --noexport -n"
	t.targets = []
	t.antitargets = exported_files
	t.run()
	
	t.name = "export"
	t.print_result()
	return t
