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
	t.id = "30"
	t.name =  "resource"
	t.command = "sbs -b smoke_suite/test_resources/resource/group/bld.inf -b smoke_suite/test_resources/simple_gui/Bld.inf RESOURCE"
	t.targets = [
		"$(EPOCROOT)/epoc32/include/testresource.rsg",
		"$(EPOCROOT)/epoc32/include/testresource.hrh",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.r01",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/localisation/group/testresource.info",
		"$(EPOCROOT)/epoc32/localisation/testresource/rsc/testresource.rpp",
		
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/localisation/group/helloworld.info",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/include/helloworld.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/localisation/helloworld/rsc/helloworld.rpp",
		"$(EPOCROOT)/epoc32/data/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/localisation/helloworld_reg/rsc/helloworld_reg.rpp",
		"$(EPOCROOT)/epoc32/localisation/group/helloworld_reg.info",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/private/10003a3f/apps/helloworld_reg.rsc"	
		]
	
	t.addbuildtargets('smoke_suite/test_resources/resource/group/bld.inf', [	
		"testresource_/testresource_resource_testresource2_sc.rpp.d",
		"testresource_/testresource_resource_testresource3_02.rpp",
		"testresource_/testresource_resource_testresource3_02.rpp.d",
		"testresource_/testresource_resource_testresource3_sc.rpp",
		"testresource_/testresource_resource_testresource3_sc.rpp.d",
		"testresource_/testresource_resource_testresource_01.rpp",
		"testresource_/testresource_resource_testresource_01.rpp.d",
		"testresource_/testresource_resource_testresource_sc.rpp",
		"testresource_/testresource_resource_testresource_sc.rpp.d"])

	t.addbuildtargets('smoke_suite/test_resources/simple_gui/Bld.inf', [
		"helloworld_exe/helloworld.mbm_bmconvcommands",
		"helloworld_exe/helloworld__resource_apps_sc.rpp",
		"helloworld_exe/helloworld__resource_apps_sc.rpp.d",
		"helloworld_reg_exe/helloworld_reg__private_10003a3f_apps_sc.rpp",
		"helloworld_reg_exe/helloworld_reg__private_10003a3f_apps_sc.rpp.d"])

	t.mustnotmatch = ["HelloWorld.rss.* warning: trigraph"]
	
	t.run()
	return t
