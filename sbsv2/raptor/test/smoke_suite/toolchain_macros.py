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
import string

def run():
	t = SmokeTest()
	t.description = "Check that ARM toolchain specific macros are used in both metadata and source processing."
	t.warnings = -1
	
	toolchains = {
				'rvct2_2':   ['ARMCC', 'ARMCC_2', 'ARMCC_2_2', '__ARMCC__', '__ARMCC_2__',  '__ARMCC_2_2__'],
				'rvct3_1':   ['ARMCC', 'ARMCC_3', 'ARMCC_3_1', '__ARMCC__', '__ARMCC_3__' , '__ARMCC_3_1__'],
				'rvct4_0':   ['ARMCC', 'ARMCC_4', 'ARMCC_4_0', '__ARMCC__', '__ARMCC_4__' , '__ARMCC_4_0__'],
				'gcce4_3_2': ['GCCE',  'GCCE_4',  'GCCE_4_3',  '__GCCE__',  '__GCCE_4__' ,  '__GCCE_4_3__'],
				'gcce4_3_3': ['GCCE', 'GCCE_4', 'GCCE_4_3', '__GCCE__', '__GCCE_4__' , '__GCCE_4_3__'],
				'gcce4_4_1': ['GCCE', 'GCCE_4', 'GCCE_4_4', '__GCCE__', '__GCCE_4__' , '__GCCE_4_4__']
				}
	
	rootname = "toolchain_macros_armv5_%s_%s"
	rootcommand = "sbs -b smoke_suite/test_resources/toolchain_macros/bld.inf -c arm.v5.urel."
	macromatch = ": #warning( directive:)? %s(</warning>)?$"
	
	count = 0	
	for toolchain in sorted(toolchains.keys()):
		t.id = "0095" + string.ascii_lowercase[count]
		t.name = rootname % (toolchain, "clean")
		t.command = rootcommand + toolchain + " clean"
		t.mustmatch_singleline = []
		t.run()
		count += 1
		
		t.id = "0095" + string.ascii_lowercase[count]
		t.name = rootname % (toolchain, "build")
		t.command = rootcommand + toolchain
		mustmatch = []	
		for macro in toolchains[toolchain]:
			mustmatch.append(macromatch % macro)
		t.mustmatch_singleline = mustmatch
		t.run()
		count += 1

	t.id = "95"
	t.name = "toolchain_macros"
	t.print_result()
	return t
