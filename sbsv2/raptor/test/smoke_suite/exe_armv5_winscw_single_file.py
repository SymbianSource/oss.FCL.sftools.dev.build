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

	t = SmokeTest()
	t.name = "exe_armv5_winscw_single_file_baseline_build"

	# Build component
	t.id = "0089a"
	t.command = "sbs -b smoke_suite/test_resources/simple_gui/Bld.inf -c armv5 -c winscw"
	t.addbuildtargets('smoke_suite/test_resources/simple_gui/Bld.inf', [
		"helloworld_exe/helloworld.mbm_bmconvcommands",
		"helloworld_exe/helloworld_HelloWorld_sc.rpp",
		"helloworld_exe/helloworld_HelloWorld_sc.rpp.d",
		"helloworld_exe/armv5/udeb/HelloWorld_Application.o",
		"helloworld_exe/armv5/udeb/HelloWorld_Application.o.d",
		"helloworld_exe/armv5/udeb/HelloWorld_AppUi.o",
		"helloworld_exe/armv5/udeb/HelloWorld_AppUi.o.d",
		"helloworld_exe/armv5/udeb/HelloWorld_AppView.o",
		"helloworld_exe/armv5/udeb/HelloWorld_AppView.o.d",
		"helloworld_exe/armv5/udeb/HelloWorld_Document.o",
		"helloworld_exe/armv5/udeb/HelloWorld_Document.o.d",
		"helloworld_exe/armv5/udeb/HelloWorld_Main.o",
		"helloworld_exe/armv5/udeb/HelloWorld_Main.o.d",
		"helloworld_exe/armv5/udeb/helloworld_udeb_objects.via",
		"helloworld_exe/armv5/urel/HelloWorld_Application.o",
		"helloworld_exe/armv5/urel/HelloWorld_Application.o.d",
		"helloworld_exe/armv5/urel/HelloWorld_AppUi.o",
		"helloworld_exe/armv5/urel/HelloWorld_AppUi.o.d",
		"helloworld_exe/armv5/urel/HelloWorld_AppView.o",
		"helloworld_exe/armv5/urel/HelloWorld_AppView.o.d",
		"helloworld_exe/armv5/urel/HelloWorld_Document.o",
		"helloworld_exe/armv5/urel/HelloWorld_Document.o.d",
		"helloworld_exe/armv5/urel/HelloWorld_Main.o",
		"helloworld_exe/armv5/urel/HelloWorld_Main.o.d",
		"helloworld_exe/armv5/urel/helloworld_urel_objects.via",
		"helloworld_exe/winscw/udeb/helloworld.UID.CPP",
		"helloworld_exe/winscw/udeb/HelloWorld_Application.dep",
		"helloworld_exe/winscw/udeb/HelloWorld_Application.o",
		"helloworld_exe/winscw/udeb/HelloWorld_Application.o.d",
		"helloworld_exe/winscw/udeb/HelloWorld_AppUi.dep",
		"helloworld_exe/winscw/udeb/HelloWorld_AppUi.o",
		"helloworld_exe/winscw/udeb/HelloWorld_AppUi.o.d",
		"helloworld_exe/winscw/udeb/HelloWorld_AppView.dep",
		"helloworld_exe/winscw/udeb/HelloWorld_AppView.o",
		"helloworld_exe/winscw/udeb/HelloWorld_AppView.o.d",
		"helloworld_exe/winscw/udeb/HelloWorld_Document.dep",
		"helloworld_exe/winscw/udeb/HelloWorld_Document.o",
		"helloworld_exe/winscw/udeb/HelloWorld_Document.o.d",
		"helloworld_exe/winscw/udeb/HelloWorld_Main.dep",
		"helloworld_exe/winscw/udeb/HelloWorld_Main.o",
		"helloworld_exe/winscw/udeb/HelloWorld_Main.o.d",
		"helloworld_exe/winscw/udeb/helloworld_udeb_objects.lrf",
		"helloworld_exe/winscw/udeb/helloworld_UID_.dep",
		"helloworld_exe/winscw/udeb/helloworld_UID_.o",
		"helloworld_exe/winscw/udeb/helloworld_UID_.o.d",
		"helloworld_exe/winscw/urel/helloworld.UID.CPP",
		"helloworld_exe/winscw/urel/HelloWorld_Application.dep",
		"helloworld_exe/winscw/urel/HelloWorld_Application.o",
		"helloworld_exe/winscw/urel/HelloWorld_Application.o.d",
		"helloworld_exe/winscw/urel/HelloWorld_AppUi.dep",
		"helloworld_exe/winscw/urel/HelloWorld_AppUi.o",
		"helloworld_exe/winscw/urel/HelloWorld_AppUi.o.d",
		"helloworld_exe/winscw/urel/HelloWorld_AppView.dep",
		"helloworld_exe/winscw/urel/HelloWorld_AppView.o",
		"helloworld_exe/winscw/urel/HelloWorld_AppView.o.d",
		"helloworld_exe/winscw/urel/HelloWorld_Document.dep",
		"helloworld_exe/winscw/urel/HelloWorld_Document.o",
		"helloworld_exe/winscw/urel/HelloWorld_Document.o.d",
		"helloworld_exe/winscw/urel/HelloWorld_Main.dep",
		"helloworld_exe/winscw/urel/HelloWorld_Main.o",
		"helloworld_exe/winscw/urel/HelloWorld_Main.o.d",
		"helloworld_exe/winscw/urel/helloworld_UID_.dep",
		"helloworld_exe/winscw/urel/helloworld_UID_.o",
		"helloworld_exe/winscw/urel/helloworld_UID_.o.d",
		"helloworld_exe/winscw/urel/helloworld_urel_objects.lrf",
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg_sc.rpp",
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg_sc.rpp.d"
	])

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# Ensure we don't clean up from the previous build in any subsequent runs
	t.addbuildtargets('smoke_suite/test_resources/simple_gui/Bld.inf', [])
	t.targets = []
	t.usebash = True

	# Touch both a straight source and a resource file and confirm we can recompile in isolation without additional impact
	t.id = "0089b"
	t.name = "exe_armv5_winscw_single_file_touch_rebuild"
	t.command = """
		sleep 1
		touch smoke_suite/test_resources/simple_gui/HelloWorld_Document.cpp
		touch smoke_suite/test_resources/simple_gui/HelloWorld.rss
		sbs -f - --source-target=smoke_suite/test_resources/simple_gui/HelloWorld_Document.cpp --source-target=smoke_suite/test_resources/simple_gui/HelloWorld.rss -b smoke_suite/test_resources/simple_gui/Bld.inf"""
	t.countmatch = [
		[".*recipe name='resource(preprocess|header|compile)'", 3],
		[".*recipe name='compile'.*", 2],
		[".*recipe name='win32compile2object'.*", 2]
	]
	t.mustnotmatch = [
		".*recipe name='(win32simplelink|postlink|link)'.*"
	]

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	# Attempt separate source and resource file compile where nothing should be done
	t.id = "0089c"
	t.name = "exe_armv5_winscw_single_file_notouch_rebuild"
	t.command = "sbs -f - --source-target=smoke_suite/test_resources/simple_gui/HelloWorld_Document.cpp --source-target=smoke_suite/test_resources/simple_gui/HelloWorld.rss -b smoke_suite/test_resources/simple_gui/Bld.inf"
	t.mustmatch = []
	t.countmatch = [
		[".*make.*Nothing to be done for.*SOURCETARGET_.*", 10]
	]
	t.mustnotmatch = [
		".*recipe name='(resourcepreprocess|win32compile2object|compile|win32simplelink|postlink|link)'.*"
	]

	t.run()
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL

	t.id = "89"
	t.name = "exe_armv5_winscw_single_file"
	t.description = """Builds a component and tests single file compilation for straight source and resource files"""
	t.result = result
	t.print_result()
	return t
