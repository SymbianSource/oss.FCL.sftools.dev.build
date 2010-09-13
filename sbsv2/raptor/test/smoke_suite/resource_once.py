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
	t.name =  "resource_once"
	t.description = "Ensure we only generate the resource header once even when there are many languages.  Make sure that the right language (96) is used for the headerfile."
	t.command = "sbs  -b smoke_suite/test_resources/resource/group/simple.inf -c winscw_udeb -m ${SBSMAKEFILE} -f ${SBSLOGFILE}; XX=$?; cat ${SBSLOGFILE}; exit $XX" 
	t.usebash = True
	t.targets = [
		"$(EPOCROOT)/epoc32/include/testresource.hrh",
		"$(EPOCROOT)/epoc32/include/testresource_badef.rh",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/testresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/testresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.r37",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/testresource/testresource.r37",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/testresource/testresource.r37",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.r94",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/testresource/testresource.r94",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/testresource/testresource.r94",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.r96",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/testresource/testresource.r96",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/testresource/testresource.r96",
		"$(EPOCROOT)/epoc32/include/testresource.rsg",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/testresource.exe"
		]
	t.countmatch = [["rcomp.*-h.*rsg.*r96",1],  # must see r96 once
	                ["rcomp.*-h.*rsg",1]]  # must not see any other language
	t.run()

	t.print_result()
	return t
