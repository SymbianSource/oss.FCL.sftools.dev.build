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

from raptor_tests import CheckWhatSmokeTest
import re, os

def run():
	t = CheckWhatSmokeTest()
	t.id = "66"
	t.name = "gui_whatlog"
	t.command = "sbs -b smoke_suite/test_resources/simple_gui/Bld.inf -f - -m" \
			+ " ${SBSMAKEFILE} -c armv5.whatlog -c winscw.whatlog"
	componentpath = re.sub(r'\\','/',os.path.abspath("smoke_suite/test_resources/simple_gui"))
	t.regexlinefilter = \
			re.compile("^<(whatlog|export|build>|resource>|bitmap>)")
	t.hostossensitive = False
	t.usebash = True
	t.targets = [
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/localisation/group/helloworld.info",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/include/helloworld.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/localisation/helloworld/rsc/helloworld.rpp",
		"$(EPOCROOT)/epoc32/localisation/group/helloworld_reg.info",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.rsc",
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
		"helloworld_exe/helloworld__resource_apps_sc.rpp",
		"helloworld_exe/helloworld__resource_apps_sc.rpp.d",
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
		"helloworld_reg_exe/helloworld_reg__private_10003a3f_apps_sc.rpp.d"
	])
	t.stdout = [
		"<whatlog bldinf='"+componentpath+"/Bld.inf' mmp='"+componentpath+"/HelloWorld.mmp' config='armv5_udeb.whatlog'>",
		"<bitmap>$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.mbm</bitmap>",
		"<resource>$(EPOCROOT)/epoc32/include/helloworld.rsg</resource>",
		"<resource>$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.rsc</resource>",
		"<resource>$(EPOCROOT)/epoc32/localisation/helloworld/rsc/helloworld.rpp</resource>",
		"<resource>$(EPOCROOT)/epoc32/localisation/group/helloworld.info</resource>",
		"<resource>$(EPOCROOT)/epoc32/data/z/private/10003a3f/apps/helloworld_reg.rsc</resource>",
		"<resource>$(EPOCROOT)/epoc32/localisation/helloworld_reg/rsc/helloworld_reg.rpp</resource>",
		"<resource>$(EPOCROOT)/epoc32/localisation/group/helloworld_reg.info</resource>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe.map</build>",
		"<whatlog bldinf='"+componentpath+"/Bld.inf' mmp='"+componentpath+"/HelloWorld.mmp' config='winscw_urel.whatlog'>",
		"<bitmap>$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.mbm</bitmap>",
		"<bitmap>$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.mbm</bitmap>",
		"<bitmap>$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.mbm</bitmap>",
		"<resource>$(EPOCROOT)/epoc32/include/helloworld.rsg</resource>",
		"<resource>$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.rsc</resource>",
		"<resource>$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.rsc</resource>",
		"<resource>$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.rsc</resource>",
		"<resource>$(EPOCROOT)/epoc32/localisation/helloworld/rsc/helloworld.rpp</resource>",
		"<resource>$(EPOCROOT)/epoc32/localisation/group/helloworld.info</resource>",
		"<resource>$(EPOCROOT)/epoc32/data/z/private/10003a3f/apps/helloworld_reg.rsc</resource>",
		"<resource>$(EPOCROOT)/epoc32/release/winscw/udeb/z/private/10003a3f/apps/helloworld_reg.rsc</resource>",
		"<resource>$(EPOCROOT)/epoc32/release/winscw/urel/z/private/10003a3f/apps/helloworld_reg.rsc</resource>",
		"<resource>$(EPOCROOT)/epoc32/localisation/helloworld_reg/rsc/helloworld_reg.rpp</resource>",
		"<resource>$(EPOCROOT)/epoc32/localisation/group/helloworld_reg.info</resource>",
		"<build>$(EPOCROOT)/epoc32/release/winscw/urel/helloworld.exe</build>",
		"<build>$(EPOCROOT)/epoc32/release/winscw/urel/helloworld.exe.map</build>",
		"<whatlog bldinf='"+componentpath+"/Bld.inf' mmp='"+componentpath+"/HelloWorld.mmp' config='armv5_urel.whatlog'>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe.map</build>",
		"<whatlog bldinf='"+componentpath+"/Bld.inf' mmp='"+componentpath+"/HelloWorld.mmp' config='winscw_udeb.whatlog'>",
		"<build>$(EPOCROOT)/epoc32/release/winscw/udeb/helloworld.exe</build>",
	]
	t.run()
	return t
