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

from raptor_tests import CheckWhatSmokeTest,AntiTargetSmokeTest
import re

def run():
	t = CheckWhatSmokeTest()
	t.description = "Trace Compiler Whatlog test"
	t.id = "xxx"
	t.name = "tracecompiler_whatlog"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf -c armv5.tracecompiler -m ${SBSMAKEFILE} -f ${SBSLOGFILE} && cat ${SBSLOGFILE}"
	t.hostossensitive = False
	t.regexlinefilter = re.compile("^<(whatlog|export|build>|resource>|bitmap>)")
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/testTC.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testTC{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testTC{000a0000}.lib",
		"$(EPOCROOT)/epoc32/release/armv5/lib/testTC.lib",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/testTC.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/testTC.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testTC.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testTC.dll.map",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitmainTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/wlanhwinitpermparserTraces.h",	
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/traces/fixed_id.definitions",
		"$(EPOCROOT)/epoc32/ost_dictionaries/testTC_0x1000008d_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/testTC_0x1000008d_TraceDefinitions.h"
		]
	t.stdout = [
		"<whatlog bldinf='$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf' mmp='$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/group/testTC.mmp' config='armv5_urel.tracecompiler'>",
		"<whatlog bldinf='$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/group/bld.inf' mmp='$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/testTC/group/testTC.mmp' config='armv5_udeb.tracecompiler'>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/lib/testTC.dso</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/lib/testTC{000a0000}.dso</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/lib/testTC{000a0000}.lib</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/lib/testTC.lib</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/udeb/testTC.dll</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/udeb/testTC.dll.map</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/urel/testTC.dll</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/urel/testTC.dll.map</build>",
		"<build>$(EPOCROOT)/epoc32/ost_dictionaries/testTC_0x1000008d_Dictionary.xml</build>",
		"<build>$(EPOCROOT)/epoc32/include/internal/SymbianTraces/autogen/testTC_0x1000008d_TraceDefinitions.h</build>"
		]		
	t.run("windows")

	return t

