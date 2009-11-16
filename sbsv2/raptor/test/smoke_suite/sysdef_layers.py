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
	t.id = "48"
	t.name = "sysdef_layers"
	t.description = "Test system_definition.xml layer processing"
	t.command = 'sbs -s ' + \
			'smoke_suite/test_resources/sysdef/system_definition_order_layer_test.xml' + \
			' -l "Metadata Export" -l "Build Generated Source" -l ' + \
			'"Component with Layer Dependencies" -o'
	t.targets = [
		"$(SBS_HOME)/test/smoke_suite/test_resources/sysdef/build_gen_source/exported.inf",
		"$(SBS_HOME)/test/smoke_suite/test_resources/sysdef/build_gen_source/exported.mmh",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/data/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/include/helloworld.rsg",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/helloworld.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/helloworld.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/helloworld.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/urel/helloworld.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/helloworld.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/localisation/group/helloworld.info",
		"$(EPOCROOT)/epoc32/localisation/helloworld/rsc/helloworld.rpp",
		"$(EPOCROOT)/epoc32/localisation/helloworld/mbm/icon2m.bmp",
		"$(EPOCROOT)/epoc32/localisation/helloworld/mbm/icon3m.bmp",
		"$(EPOCROOT)/epoc32/localisation/helloworld/mbm/icon4m.bmp",
		"$(EPOCROOT)/epoc32/localisation/helloworld/mbm/icon24.bmp",
		"$(EPOCROOT)/epoc32/localisation/helloworld/mbm/icon32.bmp",
		"$(EPOCROOT)/epoc32/localisation/helloworld/mbm/icon48.bmp",
		"$(EPOCROOT)/epoc32/localisation/group/helloworld_reg.info",
		"$(EPOCROOT)/epoc32/localisation/helloworld_reg/rsc/helloworld_reg.rpp"
		]
	t.addbuildtargets('smoke_suite/test_resources/sysdef/build_gen_source/bld.inf', [
		"helloworld_/helloworld__resource_apps_sc.rpp"
		])
	t.addbuildtargets('smoke_suite/test_resources/sysdef/dependent/bld.inf', [
		"helloworld_exe/armv5/udeb/HelloWorld_Application.o",
		"helloworld_exe/armv5/udeb/HelloWorld_AppUi.o",
		"helloworld_exe/armv5/udeb/HelloWorld_AppView.o",
		"helloworld_exe/armv5/udeb/HelloWorld_Document.o",
		"helloworld_exe/armv5/udeb/HelloWorld_Main.o",
		"helloworld_exe/armv5/urel/HelloWorld_Application.o",
		"helloworld_exe/armv5/urel/HelloWorld_AppUi.o",
		"helloworld_exe/armv5/urel/HelloWorld_AppView.o",
		"helloworld_exe/armv5/urel/HelloWorld_Document.o",
		"helloworld_exe/armv5/urel/HelloWorld_Main.o",
		"helloworld_exe/winscw/udeb/HelloWorld_Application.o",
		"helloworld_exe/winscw/udeb/HelloWorld_AppUi.o",
		"helloworld_exe/winscw/udeb/HelloWorld_AppView.o",
		"helloworld_exe/winscw/udeb/HelloWorld_Document.o",
		"helloworld_exe/winscw/udeb/HelloWorld_Main.o",
		"helloworld_exe/winscw/udeb/helloworld.UID.CPP",
		"helloworld_exe/winscw/udeb/helloworld_UID_.o",
		"helloworld_exe/winscw/urel/HelloWorld_Application.o",
		"helloworld_exe/winscw/urel/HelloWorld_AppUi.o",
		"helloworld_exe/winscw/urel/HelloWorld_AppView.o",
		"helloworld_exe/winscw/urel/HelloWorld_Document.o",
		"helloworld_exe/winscw/urel/HelloWorld_Main.o",
		"helloworld_exe/winscw/urel/helloworld.UID.CPP",
		"helloworld_exe/winscw/urel/helloworld_UID_.o",
		"helloworld_reg_exe/helloworld_reg__private_10003a3f_apps_sc.rpp"
		])
	t.run()
	return t
