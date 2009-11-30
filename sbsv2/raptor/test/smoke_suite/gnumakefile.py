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
	t.id = "53"	
	t.name = "gnumakefile"
	t.command = "sbs -b smoke_suite/test_resources/gnumakefile/bld.inf"
	t.targets = [
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_bld_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_bld_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_bld_WINSCW_UDEB.txt",
	  	"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_bld_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_final_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_final_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_final_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_final_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_lib_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_lib_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_lib_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_lib_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_makmake_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_makmake_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_makmake_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_makmake_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_resource_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_resource_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_resource_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/master_resource_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_bld_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_bld_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_bld_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_bld_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_final_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_final_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_final_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_final_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_lib_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_lib_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_lib_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_lib_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_makmake_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_makmake_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_makmake_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_makmake_WINSCW_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_resource_ARMV5_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_resource_ARMV5_UREL.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_resource_WINSCW_UDEB.txt",
		"$(SBS_HOME)/test/smoke_suite/test_resources/gnumakefile/slave_resource_WINSCW_UREL.txt"
		]
	t.run("windows") # we don't have make 3.79 on Linux
	return t
