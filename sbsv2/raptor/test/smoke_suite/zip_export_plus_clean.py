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

from raptor_tests import AntiTargetSmokeTest, ReplaceEnvs
from raptor_meta import MetaReader
from raptor_utilities import sanitise
import re

def run():
	premarkerfile = sanitise(ReplaceEnvs("$(SBS_HOME)_test_smoke_suite_test_resources_simple_zip_export_archive.zip$(EPOCROOT)_epoc32_testunzip"))
	markerfile = MetaReader.unzippedPathFragment(premarkerfile) + ".unzipped"
	
	t = AntiTargetSmokeTest()

	# Check basic export success	
	t.name = "zip_export"
	t.command = "sbs -b smoke_suite/test_resources/simple_zip_export/bld.inf"
	t.targets = [
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile1.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile2.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile3.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile4.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefilelinuxbin",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefilereadonly.txt",
		"$(EPOCROOT)/epoc32/build/" + markerfile
	]
	t.run()

	# Confirm executable permissions are retained on Linux	
	t.name = "zip_export_execute_permissions"
	t.usebash = True
	t.targets = [] # prevent auto clean-up up of target files from previous test
	t.command = "ls -l $(EPOCROOT)/epoc32/testunzip/archive/archivefilelinuxbin"
	t.mustmatch = ["-[rw-]{2}x[rw-]{2}x[rw-]{2}x"]
	t.run("linux")

	# Confirm reallyclean deletes all exports, including those that were read-only
	# as source (and so should now be removable at their destination)	
	t.name = "zip_export_reallyclean"
	t.command = "sbs -b smoke_suite/test_resources/simple_zip_export/bld.inf reallyclean"
	t.mustmatch = []
	t.antitargets = [
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile1.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile2.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile3.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile4.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefilelinuxbin",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefilereadonly.txt",
		"$(EPOCROOT)/epoc32/build/" + markerfile
	]
	t.run()
	
	t.name = "zip_export_plus_clean"
	t.print_result()
	return t
