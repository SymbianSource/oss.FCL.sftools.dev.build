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
from raptor_tests import where

def run():
	t = SmokeTest()
	t.id = "0012a"
	t.name = "dll_armv5_winscw_freeze"
	t.description = """Builds a component with unfrozen exports from clean,
		followed by a FREEZE, a further CLEAN and then a check that new .def
		files are present. The PERL environment variable is set to the absolute
		Perl path in order to test a known issue with the execution of tools
		such as efreeze under Cygwin when multiple arguments are listed.
		Part b tests whether removing an export works when using the variant;
		remove_freeze"""
	t.usebash = True
	
	perl_location = where("perl")
	
	t.command = """
sbs -b smoke_suite/test_resources/unfrozen/freeze.inf -p unfrozensymbols_for_freeze.mmp -c armv5 -c winscw CLEAN > /dev/null &&
export PERL="%s" &&
sbs -b smoke_suite/test_resources/unfrozen/freeze.inf -p unfrozensymbols_for_freeze.mmp -c armv5 -c winscw > /dev/null &&
sbs -b smoke_suite/test_resources/unfrozen/freeze.inf -p unfrozensymbols_for_freeze.mmp -c armv5_urel -c winscw_urel FREEZE -m ${SBSMAKEFILE} -f ${SBSLOGFILE}
""" % perl_location

	t.targets = [
		"smoke_suite/test_resources/unfrozen/frozen/bwins/frozenu.def",
		"smoke_suite/test_resources/unfrozen/frozen/eabi/frozenu.def"		
		]

	t.warnings = 2	
	t.run()
	
	
	t.id = "0012b"
	t.name = "armv5_re-freeze_with_removed_export"
	
	t.command = "sbs -b smoke_suite/test_resources/unfrozen/freeze.inf" \
			+ " -p frozen_with_removed_export.mmp -c armv5_urel ;" \
			+ " sbs -b smoke_suite/test_resources/unfrozen/freeze.inf" \
			+ " -p frozen_with_removed_export.mmp FREEZE" \
			+ " -c armv5_urel.remove_freeze" \
			+ " -m ${SBSMAKEFILE} -f ${SBSLOGFILE} &&" \
			+ " grep -ir '_ZN10CMessenger11ShowMessageEv @ 1 NONAME ABSENT' $(SBS_HOME)/test/smoke_suite/test_resources/unfrozen/frozen/eabi/frozenu.def"
			
	t.targets = []
	t.mustmatch = [
		"_ZN10CMessenger11ShowMessageEv @ 1 NONAME ABSENT"
	]
	t.warnings = 0
	t.errors = 1
			
	t.run()
	
	
	t.id = "0012c"
	t.name = "winscw_re-freeze_with_removed_export"
	
	t.command = "sbs -b smoke_suite/test_resources/unfrozen/freeze.inf" \
			+ " -p frozen_with_removed_export.mmp -c winscw_urel ;" \
			+ " sbs -b smoke_suite/test_resources/unfrozen/freeze.inf" \
			+ " -p frozen_with_removed_export.mmp FREEZE" \
			+ " -c winscw_urel.remove_freeze" \
			+ " -m ${SBSMAKEFILE} -f ${SBSLOGFILE} &&" \
			+ " grep -ir '?ShowMessage@CMessenger@@QAEXXZ @ 3 NONAME ABSENT' $(SBS_HOME)/test/smoke_suite/test_resources/unfrozen/frozen/bwins/frozenu.def"

	t.mustmatch = [
		"\?ShowMessage@CMessenger@@QAEXXZ @ 3 NONAME ABSENT"
	]
			
	t.run()
	

	t.id = "0012d"
	t.name = "efreeze_info"
	
	t.command = "sbs -b smoke_suite/test_resources/unfrozen/freeze.inf" \
			+ " -p unfrozensymbols_for_freeze.mmp -c winscw freeze"
			
	t.mustmatch = [
		"EFREEZE: DEF file up to date"
	]
	t.warnings = 0
	t.errors = 0
			
	t.run()


	t.id = "12"
	t.name = "dll_armv5_winscw_freeze"
	t.print_result()
	return t

