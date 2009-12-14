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
import re,os

def run():
	t = CheckWhatSmokeTest()
	t.id = "54"
	t.name = "gnumakefile_what"
	t.command = "sbs -b smoke_suite/test_resources/gnumakefile/bld.inf --what"
	componentpath = re.sub(r'\\','/',os.path.abspath("smoke_suite/test_resources/gnumakefile"))

	t.stdout = [
	# Generated txt files by the gnumakefile
		componentpath+"/master_bld_ARMV5_UDEB.txt",
		componentpath+"/master_bld_ARMV5_UREL.txt",
		componentpath+"/master_bld_WINSCW_UDEB.txt",
		componentpath+"/master_bld_WINSCW_UREL.txt",
		componentpath+"/master_final_ARMV5_UDEB.txt",
		componentpath+"/master_final_ARMV5_UREL.txt",
		componentpath+"/master_final_WINSCW_UDEB.txt",
		componentpath+"/master_final_WINSCW_UREL.txt",
		componentpath+"/master_lib_ARMV5_UDEB.txt",
		componentpath+"/master_lib_ARMV5_UREL.txt",
		componentpath+"/master_lib_WINSCW_UDEB.txt",
		componentpath+"/master_lib_WINSCW_UREL.txt",
		componentpath+"/master_makmake_ARMV5_UDEB.txt",
		componentpath+"/master_makmake_ARMV5_UREL.txt",
		componentpath+"/master_makmake_WINSCW_UDEB.txt",
		componentpath+"/master_makmake_WINSCW_UREL.txt",
		componentpath+"/master_resource_ARMV5_UDEB.txt",
		componentpath+"/master_resource_ARMV5_UREL.txt",
		componentpath+"/master_resource_WINSCW_UDEB.txt",
		componentpath+"/master_resource_WINSCW_UREL.txt",
		componentpath+"/slave_bld_ARMV5_UDEB.txt",
		componentpath+"/slave_bld_ARMV5_UREL.txt",
		componentpath+"/slave_bld_WINSCW_UDEB.txt",
		componentpath+"/slave_bld_WINSCW_UREL.txt",
		componentpath+"/slave_final_ARMV5_UDEB.txt",
		componentpath+"/slave_final_ARMV5_UREL.txt",
		componentpath+"/slave_final_WINSCW_UDEB.txt",
		componentpath+"/slave_final_WINSCW_UREL.txt",
		componentpath+"/slave_lib_ARMV5_UDEB.txt",
		componentpath+"/slave_lib_ARMV5_UREL.txt",
		componentpath+"/slave_lib_WINSCW_UDEB.txt",
		componentpath+"/slave_lib_WINSCW_UREL.txt",
		componentpath+"/slave_makmake_ARMV5_UDEB.txt",
		componentpath+"/slave_makmake_ARMV5_UREL.txt",
		componentpath+"/slave_makmake_WINSCW_UDEB.txt",
		componentpath+"/slave_makmake_WINSCW_UREL.txt",
		componentpath+"/slave_resource_ARMV5_UDEB.txt",
		componentpath+"/slave_resource_ARMV5_UREL.txt",
		componentpath+"/slave_resource_WINSCW_UDEB.txt",
		componentpath+"/slave_resource_WINSCW_UREL.txt"
	]
	t.run("windows") # we don't have make 3.79 on Linux
	return t
