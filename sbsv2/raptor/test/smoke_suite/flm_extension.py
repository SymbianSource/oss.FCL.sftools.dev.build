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

from raptor_tests import SmokeTest, ReplaceEnvs

def run():
	t = SmokeTest()
	
	t.name = "exported_flm_extension"
	t.command = "sbs -b smoke_suite/test_resources/simple_extension/flm_bld.inf -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/build/flm_test_1_2",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/tools/flm_export.xml",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/tools/flm_export.flm"
		]
	t.run()
	
	t.name = "per_component_flm"
	t.usebash = True
	t.command = "sbs --configpath=test/smoke_suite/test_resources/docs" + \
	            " -b smoke_suite/test_resources/simple_dll/bld.inf" + \
	            " -b smoke_suite/test_resources/simple_lib/bld.inf" + \
	            " -b smoke_suite/test_resources/tools2/bld.inf" + \
	            " -c armv5.documentation -c tools2.documentation -f-"
	t.targets = [         
		"$(EPOCROOT)/epoc32/docs/simple_dll.txt",
		"$(EPOCROOT)/epoc32/docs/CreateStaticDLL.mmp",

		"$(EPOCROOT)/epoc32/docs/simple_lib.txt",
		"$(EPOCROOT)/epoc32/docs/simple.mmp",

		"$(EPOCROOT)/epoc32/docs/tools2.txt",
		"$(EPOCROOT)/epoc32/docs/tool_exe.mmp",
		"$(EPOCROOT)/epoc32/docs/tool_lib1.mmp",
		"$(EPOCROOT)/epoc32/docs/tool_lib2.mmp"
		]
	t.mustmatch = [
		"simple_dll.txt uses " + ReplaceEnvs(t.targets[1]),
		"simple_lib.txt uses " + ReplaceEnvs(t.targets[3]),
		"tools2.txt uses " + ReplaceEnvs(t.targets[5]) + " " + \
		                     ReplaceEnvs(t.targets[6]) + " " + \
		                     ReplaceEnvs(t.targets[7])
		]
	t.run()
		
	t.name = "flm_extension"
	t.print_result()
	return t
