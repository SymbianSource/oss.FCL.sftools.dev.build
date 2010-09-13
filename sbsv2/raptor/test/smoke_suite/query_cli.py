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

import raptor_tests

def run():
	
	t = raptor_tests.SmokeTest()
	t.description = "Test the --query command-line option"

	t.name = "query_cli_alias"
	t.command = "sbs --query=aliases"
	t.mustmatch_singleline = [
		"<sbs version='2\.\d+\.\d+'>",
		"<alias.*name='armv5_urel'.*/>",
		"<alias.*name='armv5_udeb'.*/>",
		"<alias.*name='winscw_urel'.*/>",
		"<alias.*name='winscw_udeb'.*/>",
		"<alias.*name='tools2_rel'.*/>",
		"<alias.*name='tools2_deb'.*/>",
		"</sbs>"
		]
	t.mustnotmatch_singleline = [
		"<alias.*name='make'.*/>",
		"<alias.*name='emake'.*/>"
		]
	t.run()
	
	t.name = "query_cli_product"
	t.command = "sbs --query=products --configpath=test/smoke_suite/test_resources/bv"
	t.mustmatch_singleline = [
		"<sbs version='2\.\d+\.\d+'>",
		"<product.*name='test_bv_1'.*/>",
		"<product.*name='test_bv_2'.*/>",
		"<product.*name='test_bv_3'.*/>",
		"</sbs>"
		]
	t.mustnotmatch_singleline = [
		"<product.*name='arm'.*/>",
		"<product.*name='root'.*/>"
		]
	t.run()

	winscwtargets =[ "<targettype name='ani'/>",
				"<targettype name='dll'/>",
				"<targettype name='exe'/>",
				"<targettype name='exexp'/>",
				"<targettype name='fsy'/>",
				"<targettype name='implib'/>",
				"<targettype name='kdll'/>",
				"<targettype name='kext'/>",
				"<targettype name='klib'/>",
				"<targettype name='ldd'/>",
				"<targettype name='lib'/>",
				"<targettype name='none'/>",
				"<targettype name='pdd'/>",
				"<targettype name='pdl'/>",
				"<targettype name='pdll'/>",
				"<targettype name='plugin'/>",
				"<targettype name='plugin3'/>",
				"<targettype name='stddll'/>",
				"<targettype name='stdexe'/>",
				"<targettype name='stdlib'/>",
				"<targettype name='textnotifier2'/>",
				"<targettype name='var'/>"]
	armtargets = winscwtargets + [
				"<targettype name='kexe'/>",
				"<targettype name='var2'/>" ]
	tools2targets = [ "<targettype name='exe'/>",
					"<targettype name='lib'/>"]

	t.name = "query_cli_config"
	t.command = "sbs --query=config[armv5_urel]"
	t.mustmatch_singleline = [
		"<sbs version='2\.\d+\.\d+'>",
		"meaning='arm\.v5\.urel\.rvct.*'",
		"<build>",
		"<macro name='__SUPPORT_CPP_EXCEPTIONS__'/>",
		"<macro name='_UNICODE'/>",
		"<macro name='__SYMBIAN32__'/>",
		"<macro name='__EPOC32__'/>",
		"<macro name='__MARM__'/>",
		"<macro name='__EABI__'/>",
		"<macro name='__PRODUCT_INCLUDE__' value='\".*epoc32/include/variant/symbian_os.hrh\"'/>",
		"<macro name='__MARM_ARMV5__'/>",
		"<macro name='__ARMCC_2__'/>",
		"<macro name='__ARMCC_2_2__'/>",
		"<macro name='NDEBUG'/>",
		"<macro name='__ARMCC__'/>",
		"<preinclude file='.*/epoc32/include/rvct/rvct.h'/>"
		] + armtargets + [
		"</build>",
		"<metadata>",
		"outputpath='.*/epoc32/release/armv5/urel'",
		"include path='.*/epoc32/include/variant'",
		"include path='.*/epoc32/include'",
		"preinclude file='.*/epoc32/include/variant/Symbian_OS.hrh'",
		"macro name='SBSV2' value='_____SBSV2'/>",
		"macro name='ARMCC' value='_____ARMCC'/>",
		"macro name='EPOC32' value='_____EPOC32'/>",
		"macro name='MARM' value='_____MARM'/>",
		"macro name='EABI' value='_____EABI'/>",
		"macro name='GENERIC_MARM' value='_____GENERIC_MARM'/>",
		"macro name='MARM_ARMV5' value='_____MARM_ARMV5'/>",
		"macro name='ARMCC_2' value='_____ARMCC_2'/>",
		"macro name='ARMCC_2_2' value='_____ARMCC_2_2'/>",
		"macro name='__GNUC__' value='3'/>",		
		"</metadata>",
		"</sbs>"
		]
	t.mustnotmatch_singleline = []
	t.run()
	
	t.name = "query_cli_config_bv"
	t.command = "sbs --query=config[armv5_urel.test_bv_1] --configpath=test/smoke_suite/test_resources/bv"
	t.mustmatch_singleline = [
		"<sbs version='2\.\d+\.\d+'>",
		"meaning='arm\.v5\.urel\.rvct._.\.test_bv_1'",
		"outputpath='.*/epoc32/release/armv5\.one/urel'",
		"</sbs>"
		]
	t.mustnotmatch_singleline = []
	t.run()
	
	t.name = "query_cli_config_others"
	t.command = "sbs --query=config[winscw_urel] --query=config[tools2_rel]"
	
	if t.onWindows:
		t2 = "tools2"
	else:
		t2 = raptor_tests.ReplaceEnvs("tools2/$(HOSTPLATFORM_DIR)")
		
	t.mustmatch_singleline = [
		"<sbs version='2\.\d+\.\d+'>",
		"outputpath='.*/epoc32/release/winscw/urel'",
		"outputpath='.*/epoc32/release/%s/rel'" % t2
		] + winscwtargets + tools2targets + [
		"</sbs>"
		]
	t.mustnotmatch_singleline = []
	t.run()
	
	t.name = "query_cli_bad"
	t.command = "sbs --query=nonsense"
	t.mustmatch_singleline = [
		"<sbs version='2\.\d+\.\d+'>",
		"exception 'unknown query' with query 'nonsense'",
		"</sbs>"
		]
	t.mustnotmatch_singleline = []
	t.errors = 1
	t.returncode = 1
	t.run()

	t.name = "query_cli_evaluator_error"
	t.command = "sbs --query=config[arm.badenv] --configpath=test/smoke_suite/test_resources/query_cli"
	t.mustmatch_singleline = [
		"<config .*query='arm.badenv'.*>DONTSETTHISEVER is not set in the environment and has no default",
		"<config .*meaning='arm.badenv'.*>DONTSETTHISEVER is not set in the environment and has no default"
		]
	t.mustnotmatch_singleline = []
	t.errors = 0
	t.returncode = 0
	t.run()
	
	t.name = "query_cli"
	t.print_result()
	return t
