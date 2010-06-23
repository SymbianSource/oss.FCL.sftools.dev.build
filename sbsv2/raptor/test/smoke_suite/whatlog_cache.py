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
import os

def run():
	t = SmokeTest()
	t.id = "77"
	t.name = "whatlog_cache"
	t.description = """Test sbsv2cache.py cache file generation using Raptor .whatlog variant output.
		This is currently a Windows only activity due to CBR tools restrictions."""
	t.usebash = True

	if 'SBS_PYTHON' in os.environ:
		pythonRun = "$(SBS_PYTHON)"
	else:
		pythonRun = "$(SBS_HOME)/win32/python264/python.exe"

	# Build something using the .whatlog variant.  Take the build log and give it to sbsv2cache.py, deducing
	# the location of the generated cache file from the verbose output.  If generated, dump the cache file to
	# STDOUT so we can validate the content in this test script.  Clean up when finished.
	t.command = """sbs -b smoke_suite/test_resources/simple_gui/Bld.inf -f ${SBSLOGFILE} -m ${SBSMAKEFILE} -c armv5.whatlog -c winscw.whatlog
		CACHEFILE=`%s $SBS_HOME/bin/sbsv2cache.py -v -s -o $EPOCROOT/epoc32/build/abldcache -l $SBSLOGFILE | sed -n \'s#Creating: ##p\'`
		if [ -n \"${CACHEFILE:+x}\" ]; then
			cat $CACHEFILE
		fi
		rm -r $EPOCROOT/epoc32/build/abldcache""" % pythonRun
		
	t.targets = [
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/include/helloworld.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/data/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/helloworld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/helloworld.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/helloworld.exe.map"
		]
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
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg_sc.rpp.d"
	])
	t.countmatch = [
		["\$self->{abldcache}->{.*\\\\test\\\\smoke_suite\\\\test_resources\\\\simple_gui target (armv5|winscw) (udeb|urel) -what\'} =", 4],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\data\\\\\\\\z\\\\\\\\private\\\\\\\\10003a3f\\\\\\\\apps\\\\\\\\helloworld_reg.rsc\'", 4],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\data\\\\\\\\z\\\\\\\\resource\\\\\\\\apps\\\\\\\\helloworld.mbm\'", 4],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\data\\\\\\\\z\\\\\\\\resource\\\\\\\\apps\\\\\\\\helloworld.rsc\'", 4],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\include\\\\\\\\helloworld.rsg\'", 4],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\release\\\\\\\\(armv5|winscw)\\\\\\\\(udeb|urel)\\\\\\\\helloworld.exe\'",4],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\release\\\\\\\\(armv5|winscw)\\\\\\\\(udeb|urel)\\\\\\\\helloworld.exe.map\'", 3],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\release\\\\\\\\winscw\\\\\\\\(udeb|urel)\\\\\\\\z\\\\\\\\private\\\\\\\\10003a3f\\\\\\\\apps\\\\\\\\helloworld_reg.rsc\'", 2],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\release\\\\\\\\winscw\\\\\\\\(udeb|urel)\\\\\\\\z\\\\\\\\resource\\\\\\\\apps\\\\\\\\helloworld.mbm\'", 2],
		[".*\'.*\\\\\\\\epoc32\\\\\\\\release\\\\\\\\winscw\\\\\\\\(udeb|urel)\\\\\\\\z\\\\\\\\resource\\\\\\\\apps\\\\\\\\helloworld.rsc\'", 2],
		["\$self->{abldcache}->{\'plats\'} =", 1],
		[".*\'ARMV5\'", 1],
		[".*\'WINSCW\'", 1]
	]
	t.run("windows")
	return t
