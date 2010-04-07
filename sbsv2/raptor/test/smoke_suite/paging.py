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
			"--codepaging=default", 
			"--datapaging=default"
			]
	t.run()

	t.id = "0093b"
	t.name = "paging_unpaged"
	t.command = cmd_prefix + "-p unpaged.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			"--codepaging=unpaged", 
			"--datapaging=unpaged"
			]
	t.run()

	t.id = "0093c"
	t.name = "paging_paged"
	t.command = cmd_prefix + "-p paged.mmp" + cmd_suffix
	# Either pagedcode or pageddata can imply bytepaircompresstarget 
	t.mustmatch_singleline = [
			"--codepaging=paged", 
			"--datapaging=default",
			"--compressionmethod=bytepair"
			]
	t.run()

	t.id = "0093d"
	t.name = "paging_unpagedcode_pageddata"
	t.command = cmd_prefix + "-p unpagedcode_pageddata.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			"--codepaging=unpaged", 
			"--datapaging=paged",
			"--compressionmethod=bytepair"
			]
	t.run()

	t.id = "0093e"
	t.name = "paging_pagedcode_unpageddata"
	t.command = cmd_prefix + "-p pagedcode_unpageddata.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			"--codepaging=paged", 
			"--datapaging=unpaged",
			"--compressionmethod=bytepair"
			]
	t.run()

	t.id = "0093f"
	t.name = "paging_pagedcode_defaultdata"
	t.command = cmd_prefix + "-p pagedcode_defaultdata.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			"--codepaging=paged", 
			"--datapaging=default",
			"--compressionmethod=bytepair"
			]
	t.run()

	t.id = "0093g"
	t.name = "paging_paged_unpaged_no_bytepair"
	t.command = cmd_prefix + "-p paged_unpaged.mmp" + cmd_suffix
	t.mustmatch_singleline = [
			"--codepaging=unpaged", 
			"--datapaging=unpaged"
			]
	t.mustnotmatch = [
			"--compressionmethod=bytepair"	
			]
	t.warnings = 2 # 1 in the log and 1 on screen
	t.run()

	# test the pre-WDP paging options --paged and --unpaged
	# there is an os_properties.xml file in test/config that
	# turns POSTLINKER_SUPPORTS_WDP off
	
	t.id = "0093g"
	t.name = "paging_paged_no_wdp"
	t.command = cmd_prefix + "-p paged.mmp --configpath=test/config" + cmd_suffix
	t.mustmatch_singleline = [
			"--paged", 
			"--compressionmethod=bytepair"
			]
	t.mustnotmatch = []
	t.warnings = 0
	t.targets = [ "$(EPOCROOT)/epoc32/release/armv5/urel/paged.dll" ]
	t.run()
	
	t.id = "0093h"
	t.name = "paging_unpaged_no_wdp"
	t.command = cmd_prefix + "-p unpaged.mmp --configpath=test/config" + cmd_suffix
	t.mustmatch_singleline = [
			"--unpaged", 
			]
	t.mustnotmatch = [
			"--compressionmethod=bytepair"	
			]
	t.targets = [ "$(EPOCROOT)/epoc32/release/armv5/urel/unpaged.dll" ]
	t.run()

	t.id = "0093"
	t.name = "paging"
	t.print_result()
	return t

