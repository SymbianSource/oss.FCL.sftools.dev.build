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
# Test for the filter_exes filter

from raptor_tests import AntiTargetSmokeTest

def run():
	t = AntiTargetSmokeTest()
	t.description = "Test the filter_exes filter"

	log = "< smoke_suite/test_resources/logexamples/filter_exes.log"

	t.usebash = True
	t.name = "filter_exes_all_exes"
	t.id = "999a"
	t.command = "sbs_filter --filter=filter_exes[] "+log+" -f ${SBSLOGFILE} -m ${SBSMAKEFILE} && cat one_armv5_urel.txt"
	t.mustmatch = [ "Wrote 1 file\(s\) into one_armv5_urel\.txt",
		"Wrote 1 file\(s\) into two_winscw_udeb\.txt",
		"^one\.exe$" ]
	t.targets = [ "one_armv5_urel.txt",
		"two_winscw_udeb.txt" ]
	t.antitargets = [ "ignore_armv5_udeb.txt",
		"ignore_armv5_urel.txt" ]
	t.run()

	t.name = "filter_exes_by_layer"
	t.id = "999b"
	t.usebash = False
	t.command = "sbs_filter --filter=filter_exes[layer=two] "+log
	t.mustmatch = [ "Wrote 1 file\(s\) into two_winscw_udeb\.txt" ]
	t.mustnotmatch = [ "Wrote 1 file\(s\) into one_armv5_urel\.txt" ]
	t.targets = [ "two_winscw_udeb.txt" ]
	t.antitargets = [ "ignore_armv5_udeb.txt",
		"ignore_armv5_urel.txt",
		"one_armv5_urel.txt" ]
	t.run()

	t.name = "filter_exes_by_config"
	t.id = "999c"
	t.command = "sbs_filter --filter=filter_exes[config=armv5_urel] "+log
	t.mustmatch = [ "Wrote 1 file\(s\) into one_armv5_urel\.txt" ]
	t.mustnotmatch = [ "Wrote 1 file\(s\) into two_winscw_udeb\.txt" ]
	t.targets = [ "one_armv5_urel.txt" ]
	t.antitargets = [ "ignore_armv5_udeb.txt",
		"ignore_armv5_urel.txt",
		"two_winscw_udeb.txt" ]
	t.run()
	
	t.clean()

	t.name = "filter_exes_specified_output"
	t.id = "999d"
	t.command = "sbs_filter --filter=filter_exes[output=$(EPOCROOT)/epoc32/build/filter_exes_test] "+log
	t.mustmatch = [ "Wrote 1 file\(s\) into .*epoc32/build/filter_exes_test[/\\\\]one_armv5_urel\.txt",
		"Wrote 1 file\(s\) into .*epoc32/build/filter_exes_test[/\\\\]two_winscw_udeb\.txt" ]
	t.targets = [ "$(EPOCROOT)/epoc32/build/filter_exes_test/one_armv5_urel.txt",
		"$(EPOCROOT)/epoc32/build/filter_exes_test/two_winscw_udeb.txt"]
	t.run()

	t.id = "999"
	t.name = "filter_exes"
	return t
