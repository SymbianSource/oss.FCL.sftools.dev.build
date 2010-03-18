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

def run():

	t = SmokeTest()
	t.usebash = True

	cmd_prefix = "sbs -b smoke_suite/test_resources/simple_paging/bld.inf -c armv5_urel "
	cmd_suffix = " -m ${SBSMAKEFILE} -f ${SBSLOGFILE} && cat ${SBSLOGFILE} "

	t.id = "0093a"
	t.name = "paging_default"
	t.command = cmd_prefix + "-p default.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			".*--codepaging=default.*", 
			".*--datapaging=default.*"
			]
	t.run("windows") # Windows-only until we've updated the Linux version of elf2e32.
	if t.result == "skip":
		return t

	t.id = "0093b"
	t.name = "paging_unpaged"
	t.command = cmd_prefix + "-p unpaged.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			".*--codepaging=unpaged.*", 
			".*--datapaging=unpaged.*"
			]
	t.run()

	t.id = "0093c"
	t.name = "paging_paged"
	t.command = cmd_prefix + "-p paged.mmp" + cmd_suffix
	# Either pagedcode or pageddata can imply bytepaircompresstarget 
	t.mustmatch_singleline = [
			".*--codepaging=paged.*", 
			".*--datapaging=paged.*",
			".*--compressionmethod=bytepair.*"
			]
	t.run()

	t.id = "0093d"
	t.name = "paging_unpagedcode_pageddata"
	t.command = cmd_prefix + "-p unpagedcode_pageddata.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			".*--codepaging=unpaged.*", 
			".*--datapaging=paged.*",
			".*--compressionmethod=bytepair.*"
			]
	t.run()

	t.id = "0093e"
	t.name = "paging_pagedcode_unpageddata"
	t.command = cmd_prefix + "-p pagedcode_unpageddata.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			".*--codepaging=paged.*", 
			".*--datapaging=unpaged.*",
			".*--compressionmethod=bytepair.*"
			]
	t.run()

	t.id = "0093f"
	t.name = "paging_pagedcode_defaultdata"
	t.command = cmd_prefix + "-p pagedcode_defaultdata.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			".*--codepaging=paged.*", 
			".*--datapaging=default.*",
			".*--compressionmethod=bytepair.*"
			]
	t.run()

	t.id = "0093g"
	t.name = "paging_paged_unpaged_no_bytepair"
	t.command = cmd_prefix + "-p paged_unpaged.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			".*--codepaging=unpaged.*", 
			".*--datapaging=unpaged.*"
			]
	t.mustnotmatch = [
			".*--compressionmethod=bytepair.*"	
			]
	t.warnings = 4 # 2 in log 2 on screen
	t.run()


	t.id = "0093"
	t.name = "paging"
	t.print_result()
	return t

