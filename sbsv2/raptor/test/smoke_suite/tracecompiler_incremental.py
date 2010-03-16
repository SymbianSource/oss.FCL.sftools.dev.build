#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
	t.description = "Test incremental rebuilding with TC on"
	t.id = "114a"
	t.name = "tracecompiler_incremental_clean"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf -c armv5_urel.tracecompiler CLEAN"
	t.run()

	t.id = "114b"
	t.name = "tracecompiler_incremental_prebuild"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf -c armv5_urel.tracecompiler -f - -m ${SBSMAKEFILE}"
	t.countmatch = [ ["name='compile'",3] ]
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/testTC.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testTC{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testTC.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testTC.dll.map",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitmainTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitpermparserTraces.h",	
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/fixed_id.definitions",
		"$(EPOCROOT)/epoc32/ost_dictionaries/testTC_0x1000008d_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/testTC_0x1000008d_TraceDefinitions.h"
		]
	t.run()

	t.id = "114c"
	t.name = "tracecompiler_incremental_rebuild"
	t.command = "touch smoke_suite/test_resources/tracecompiler/testTC/src/wlanhwinit.cpp && sbs -b smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf -c armv5_urel.tracecompiler -f - -m ${SBSMAKEFILE}"
	t.countmatch = [ ["name='compile'",1] ]
	t.targets = []
	t.run()

	t.id = "114"
	t.name = "tracecompiler_incremental"
	return t

