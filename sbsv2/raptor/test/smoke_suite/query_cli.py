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
	
	t.name = "query_cli_config"
	t.command = "sbs --query=config[armv5_urel]"
	t.mustmatch_singleline = [
		"<sbs version='2\.\d+\.\d+'>",
		"fullname='arm\.v5\.urel\.rvct.*'",
		"outputpath='.*/epoc32/release/armv5/urel'",
		"</sbs>"
		]
	t.mustnotmatch_singleline = []
	t.run()
	
	t.name = "query_cli_config_bv"
	t.command = "sbs --query=config[armv5_urel.test_bv_1] --configpath=test/smoke_suite/test_resources/bv"
	t.mustmatch_singleline = [
		"<sbs version='2\.\d+\.\d+'>",
		"fullname='arm\.v5\.urel\.rvct._.\.test_bv_1'",
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
		"outputpath='.*/epoc32/release/%s/rel'" % t2,
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
	
	t.name = "query_cli"
	t.print_result()
	return t
