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

from raptor_tests import CheckWhatSmokeTest, ReplaceEnvs
import re

def run():
	markerfile = re.sub("(\\\\|\/|:|;| )", "_",
			ReplaceEnvs("$(SBS_HOME)_test_smoke_suite_test_resources_simple_zip_export_archive.zip$(EPOCROOT)_epoc32_testunzip.unzipped"))
	
	t = CheckWhatSmokeTest()
	t.id = "25"
	t.name = "zip_export_what"
	t.command = "sbs --what " + \
			"-b smoke_suite/test_resources/simple_zip_export/bld.inf"
	t.stdout = [
		'$(EPOCROOT)/epoc32/testunzip/archive/archivefile1.txt',
		'$(EPOCROOT)/epoc32/testunzip/archive/archivefile2.txt',
		'$(EPOCROOT)/epoc32/testunzip/archive/archivefile3.txt',
		'$(EPOCROOT)/epoc32/testunzip/archive/archivefile4.txt',
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefilelinuxbin"
	]
	
	t.targets = [
		'$(EPOCROOT)/epoc32/testunzip/archive/archivefile1.txt',
		'$(EPOCROOT)/epoc32/testunzip/archive/archivefile2.txt',
		'$(EPOCROOT)/epoc32/testunzip/archive/archivefile3.txt',
		'$(EPOCROOT)/epoc32/testunzip/archive/archivefile4.txt',
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefilelinuxbin",
		"$(EPOCROOT)/epoc32/build/" + markerfile
	]
	t.run()
	return t
