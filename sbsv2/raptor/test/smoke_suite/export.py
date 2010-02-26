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

from raptor_tests import SmokeTest, AntiTargetSmokeTest
import os

def run():
	result = SmokeTest.PASS
	
	# This .inf file is created for clean_simple_export and
	# reallyclean_simple_export tests to use so that we can put the
	# username into the output filenames - which helps a lot when
	# several people run tests on the same computer (e.g. linux machines)
	bld = open('smoke_suite/test_resources/simple_export/expbld.inf', 'w')
	bld.write("PRJ_PLATFORMS\n"
		"ARMV5 WINSCW\n\n"

		"PRJ_MMPFILES\n"
		"simple.mmp\n\n"

		"PRJ_EXPORTS\n"
		"simple_exp1.h exported_1.h\n"
		"simple_exp2.h exported_2.h\n"
		"simple_exp3.h exported_3.h\n"
		"executable_file executable_file\n"
		'"file with a space.doc" "exportedfilewithspacesremoved.doc"\n'
		'"file with a space.doc" "exported file with a space.doc"\n\n'

		"simple_exp1.h /tmp/"+os.environ['USER']+"/  //\n"
		"simple_exp2.h \\tmp\\"+os.environ['USER']+"/  //\n"
		"simple_exp3.h /tmp/"+os.environ['USER']+"/simple_exp3.h \n"
		"simple_exp4.h //")
	bld.close()


	t = SmokeTest()
	t.id = "0023a"
	t.name = "export"
	t.command = "sbs -b smoke_suite/test_resources/simple_export/expbld.inf " \
			+ "-c armv5 EXPORT"
	t.targets = [
		"$(EPOCROOT)/epoc32/include/exported_1.h",
		"$(EPOCROOT)/epoc32/include/exported_2.h",
		"$(EPOCROOT)/epoc32/include/exported_3.h",
		"$(EPOCROOT)/epoc32/include/exportedfilewithspacesremoved.doc",
		"$(EPOCROOT)/epoc32/include/exported file with a space.doc",
		"/tmp/$(USER)/simple_exp1.h",
		"/tmp/$(USER)/simple_exp2.h",
		"/tmp/$(USER)/simple_exp3.h",
		"$(EPOCROOT)/epoc32/include/executable_file",
		"$(EPOCROOT)/epoc32/include/simple_exp4.h"
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t = SmokeTest()
	t.id = "0023a1"
	t.name = "export"
	t.usebash = True
	t.command = "ls -l ${EPOCROOT}/epoc32/include/executable_file"
	t.mustmatch = [ "^.rwxrwxr.x .*executable_file.*$" ]
	t.targets = []
	t.run()
	t.usebash = False

	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	# Testing if clean deletes any exports which it is not supposed to
	t.id = "0023b"
	t.name = "export_clean" 
	t.command = "sbs -b smoke_suite/test_resources/simple_export/expbld.inf " \
			+ "-c armv5 clean"
	t.mustmatch = []
	t.targets = [
		"$(EPOCROOT)/epoc32/include/exported_1.h",
		"$(EPOCROOT)/epoc32/include/exported_2.h",
		"$(EPOCROOT)/epoc32/include/exported_3.h",
		"$(EPOCROOT)/epoc32/include/executable_file",
		"$(EPOCROOT)/epoc32/include/exportedfilewithspacesremoved.doc",
		"$(EPOCROOT)/epoc32/include/exported file with a space.doc",
		"/tmp/$(USER)/simple_exp1.h",
		"/tmp/$(USER)/simple_exp2.h",
		"/tmp/$(USER)/simple_exp3.h"
		]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL


	t = AntiTargetSmokeTest()
	t.id = "0023c"
	t.name = "export_reallyclean" 
	t.command = "sbs -b smoke_suite/test_resources/simple_export/expbld.inf " \
			+ "-c armv5 reallyclean"
	t.antitargets = [
		'$(EPOCROOT)/epoc32/include/exported_1.h',
		'$(EPOCROOT)/epoc32/include/exported_2.h',
		'$(EPOCROOT)/epoc32/include/exported_3.h',
		"$(EPOCROOT)/epoc32/include/executable_file",
		'$(EPOCROOT)/epoc32/include/exportedfilewithspacesremoved.doc',
		'$(EPOCROOT)/epoc32/include/exported file with a space.doc',
		'/tmp/$(USER)/simple_exp1.h',
		'/tmp/$(USER)/simple_exp2.h',
		'/tmp/$(USER)/simple_exp3.h',
		'$(EPOCROOT)/epoc32/include/simple_exp4.h'
	]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# Check that the --noexport feature really does prevent exports from happening
	t = AntiTargetSmokeTest()
	t.id = "0023d"
	t.name = "export_noexport" 
	t.command = "sbs -b smoke_suite/test_resources/simple_export/expbld.inf " \
			+ "-c armv5 --noexport -n"
	t.antitargets = [
		'$(EPOCROOT)/epoc32/include/exported_1.h',
		'$(EPOCROOT)/epoc32/include/exported_2.h',
		'$(EPOCROOT)/epoc32/include/exported_3.h',
		"$(EPOCROOT)/epoc32/include/executable_file",
		'$(EPOCROOT)/epoc32/include/exportedfilewithspacesremoved.doc',
		'$(EPOCROOT)/epoc32/include/exported file with a space.doc',
		'/tmp/$(USER)/simple_exp1.h',
		'/tmp/$(USER)/simple_exp2.h',
		'/tmp/$(USER)/simple_exp3.h',
		'$(EPOCROOT)/epoc32/include/simple_exp4.h'
	]
	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
		
	t.id = "23"
	t.name = "export"
	t.result = result
	t.print_result()
	return t
