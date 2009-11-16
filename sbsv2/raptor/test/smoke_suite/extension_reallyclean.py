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

from raptor_tests import AntiTargetSmokeTest

def run():
	t = AntiTargetSmokeTest()
	t.id = "19"
	t.name = "extension_reallyclean"
	t.description = "These 2 sets of tests are for testing REALLYCLEAN on TEM" \
			+ " files"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/simple_extension/bld.inf " \
			+ "-c armv5_urel -m ${SBSMAKEFILE} -f ${SBSLOGFILE}; ls " \
			+ "$(EPOCROOT)/epoc32/build/tem_export_test; sbs -b " \
			+ "smoke_suite/test_resources/simple_extension/bld.inf -c " \
			+ "armv5_urel REALLYCLEAN -m ${SBSMAKEFILE}_2 -f ${SBSLOGFILE}_2"
	t.mustnotmatch = [
		"ls.*/epoc32/build/tem_export_test: No such file or directory"
	]
	t.antitargets = [
		"$(EPOCROOT)/epoc32/build/tem_export_test",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/clean.mk",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/clean.meta",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/build.mk",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/sbsv2test/build.meta",
		"$(EPOCROOT)/epoc32/release/armv5/urel/simple_extension.txt"
	]
	t.run()
	return t
