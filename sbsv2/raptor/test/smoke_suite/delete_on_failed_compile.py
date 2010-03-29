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

import os
from raptor_tests import AntiTargetSmokeTest

def setEnvVar(envvarname, newvalue):
	""" If the environment variable envvarname exists in the environment, set it to newvalue 
	and return the original value of envvarname. If envvarname does not exist, return None. """
	
	oldvalue = None
	
	if envvarname in os.environ:
		oldvalue = os.environ[envvarname]
		os.environ[envvarname] = newvalue
	
	return oldvalue
		

def run():
	# Set the ARM license file environment variables to junk files to ensure failed compiles.
	saved_armlmd_license_file = setEnvVar("ARMLMD_LICENSE_FILE", "123@456")
	saved_lm_license_file = setEnvVar("LM_LICENSE_FILE", "123@456")
	
	t = AntiTargetSmokeTest()
	t.id = "116"
	t.name = "delete_on_failed_compile"
	t.description = "Test that object files are not present following a forced failed compile."
	
	t.usebash = True
	base_command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5 -k"
	
	t.id = "116a" # Ensure everything is reallyclean before the test
	t.name = "delete_on_failed_compile_reallyclean_01"
	t.errors = 0
	t.returncode = 0
	t.antitargets = [ "" ]
	t.command = base_command + " reallyclean"
	t.run()
	
	t.id = "116b"  # Object files should *not* be present after this forced failed compile
	t.name = "delete_on_failed_compile_build"
	t.errors = 1
	t.returncode = 1
	# None of these files should be present
	t.addbuildantitargets('smoke_suite/test_resources/simple/bld.inf', 
		[	"test_/armv5/udeb/test.o",
			"test_/armv5/udeb/test1.o",
			"test_/armv5/udeb/test2.o",
			"test_/armv5/udeb/test3.o",
			"test_/armv5/udeb/test4.o",
			"test_/armv5/udeb/test5.o",
			"test_/armv5/udeb/test6.o",
			"test_/armv5/urel/test.o",
			"test_/armv5/urel/test1.o",
			"test_/armv5/urel/test2.o",
			"test_/armv5/urel/test3.o",
			"test_/armv5/urel/test4.o",
			"test_/armv5/urel/test5.o",
			"test_/armv5/urel/test6.o"  ])
	t.command = base_command
	t.run()
	
	t.id = "116c"
	t.name = "delete_on_error_reallyclean_02"
	t.errors = 0
	t.returncode = 0
	t.self.antitargets = [] # Remove the list of anti-targets
	t.command = base_command + " reallyclean"
	t.run()
	
	t.id = "116d"  # In this step, the object files should be there, but their contents will be invalid
	t.name = "delete_on_error_custom_make_engine"
	sbshome = os.environ["SBS_HOME"].replace("\\","/").rstrip("/")
	t.errors = 0
	t.returncode = 0
	t.mustmatch_singleline = []
	t.command = base_command + " -e make_test --configpath=%s/test/smoke_suite/test_resources/simple/makevariants" % sbshome 
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', 
		[	"test_/armv5/udeb/test.o",
			"test_/armv5/udeb/test1.o",
			"test_/armv5/udeb/test2.o",
			"test_/armv5/udeb/test3.o",
			"test_/armv5/udeb/test4.o",
			"test_/armv5/udeb/test5.o",
			"test_/armv5/udeb/test6.o",
			"test_/armv5/urel/test.o",
			"test_/armv5/urel/test1.o",
			"test_/armv5/urel/test2.o",
			"test_/armv5/urel/test3.o",
			"test_/armv5/urel/test4.o",
			"test_/armv5/urel/test5.o",
			"test_/armv5/urel/test6.o"  ])
	t.run()
	
	t.id = "116e"
	t.name = "delete_on_error_reallyclean_03"
	t.errors = 0
	t.returncode = 0
	t.self.targets = [] # Remove the list of targets
	t.command = base_command + " reallyclean"
	t.run()
	
	# Restore the license file environment variables, provided they existed.
	if saved_armlmd_license_file != None:
		saved_armlmd_license_file = setEnvVar("ARMLMD_LICENSE_FILE", saved_armlmd_license_file)
	if saved_lm_license_file != None:
		saved_lm_license_file = setEnvVar("LM_LICENSE_FILE", saved_lm_license_file)
	
	t.id = "116"
	t.name = ""
	t.print_result()
	return t
