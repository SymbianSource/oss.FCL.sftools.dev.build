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

from raptor_tests import CheckWhatSmokeTest
import re

def run():
	
	t = CheckWhatSmokeTest()
	t.id = "68"
	t.description = "Test output from WHAT target"
	t.name = "extension_whattarget"
	t.command = "sbs -b smoke_suite/test_resources/simple_extension/bld.inf" + \
			" WHAT -f - -m ${SBSMAKEFILE}"
	t.regexlinefilter = \
			re.compile("^<(whatlog|export|build>|resource>|bitmap>)")
	t.hostossensitive = False
	t.usebash = True
	t.targets = [
		"$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/clean.mk",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/clean.meta",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/build.mk",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/build.meta",
		]
	t.stdout = [
		"<whatlog bldinf='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/bld.inf' mmp='' config=''>",
		"<export destination='$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/clean.mk' source='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/clean.mk'/>",
		"<export destination='$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/clean.meta' source='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/clean.meta'/>",
		"<export destination='$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/build.mk' source='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/build.mk'/>",
		"<export destination='$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/build.meta' source='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/build.meta'/>",
		"<whatlog bldinf='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/bld.inf' mmp='' config='armv5_udeb'>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/udeb/simple_extension.txt</build>",
		"<whatlog bldinf='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/bld.inf' mmp='' config='armv5_urel'>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/urel/simple_extension.txt</build>",
		"<whatlog bldinf='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/bld.inf' mmp='' config='winscw_urel'>",
		"<build>$(EPOCROOT)/epoc32/release/winscw/urel/simple_extension.txt</build>",
		"<whatlog bldinf='$(SBS_HOME)/test/smoke_suite/test_resources/simple_extension/bld.inf' mmp='' config='winscw_udeb'>",
		"<build>$(EPOCROOT)/epoc32/release/winscw/udeb/simple_extension.txt</build>"
	]
	t.run()
	return t
