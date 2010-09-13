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
# The stringtable example doesn't currently build in full, hence it's built for
# EXPORT in isolation; We also test archives here - although an export, they
# will be exported in response to the first configuration processed (this
# example ensures it's armv5_udeb, so we can match against that config).
from raptor_tests import CheckWhatSmokeTest, ReplaceEnvs
from raptor_meta import MetaReader
from raptor_utilities import sanitise
import re
import os

def run():
	premarkerfile = sanitise(ReplaceEnvs("$(SBS_HOME)_test_smoke_suite_test_resources_simple_zip_export_archive.zip$(EPOCROOT)_epoc32_testunzip"))
	markerfile = MetaReader.unzippedPathFragment(premarkerfile) + ".unzipped"
	
	t = CheckWhatSmokeTest()
	t.id = "0069a"
	t.name = "stringtable_zip_whatlog"
	t.command = "sbs -b smoke_suite/test_resources/simple_stringtable/bld.inf -b smoke_suite/test_resources/simple_zip_export/bld.inf -f - -m ${SBSMAKEFILE} -c armv5_udeb.whatlog EXPORT"
	componentpath1 = re.sub(r'\\','/',os.path.abspath("smoke_suite/test_resources/simple_stringtable"))
	componentpath2 = re.sub(r'\\','/',os.path.abspath("smoke_suite/test_resources/simple_zip_export"))
	t.regexlinefilter = re.compile("^<(whatlog|archive|stringtable>|member>|zipmarker>)")
	t.hostossensitive = False
	t.usebash = True
	t.targets = [
		"$(EPOCROOT)/epoc32/include/strconsts.h",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile1.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile2.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile3.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefile4.txt",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefilelinuxbin",
		"$(EPOCROOT)/epoc32/testunzip/archive/archivefilereadonly.txt",
		"$(EPOCROOT)/epoc32/build/" + markerfile
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_stringtable/bld.inf', [
		"stringtabletest_/strconsts.cpp",
		"stringtabletest_/strconsts.h",
		"stringtabletest_/strconsts.st"
	])
	t.stdout = [
		"<whatlog bldinf='"+componentpath1+"/bld.inf' mmp='"+componentpath1+"/simple_stringtable.mmp' config='armv5_udeb.whatlog'>",
		"<stringtable>$(EPOCROOT)/epoc32/include/strconsts.h</stringtable>",
		"<whatlog bldinf='"+componentpath2+"/bld.inf' mmp='' config=''>",
		"<archive zipfile='"+componentpath2+"/archive.zip'>",
		"<member>$(EPOCROOT)/epoc32/testunzip/archive/archivefile1.txt</member>",
		"<member>$(EPOCROOT)/epoc32/testunzip/archive/archivefile2.txt</member>",
		"<member>$(EPOCROOT)/epoc32/testunzip/archive/archivefile3.txt</member>",
		"<member>$(EPOCROOT)/epoc32/testunzip/archive/archivefile4.txt</member>",
		"<member>$(EPOCROOT)/epoc32/testunzip/archive/archivefilelinuxbin</member>",
		"<member>$(EPOCROOT)/epoc32/testunzip/archive/archivefilereadonly.txt</member>",
		"<zipmarker>$(EPOCROOT)/epoc32/build/" + markerfile + "</zipmarker>"
	]
	t.run()
	
	"Tests to check that up-to-date zip exports are reported"
	t.id = "0069b"
	t.name = "stringtable_zip_whatlog_rebuild"
	t.targets = []
	t.run()
	
	t.id = "69"
	t.name = "stringtable_zip_whatlog"	
	t.print_result()
	return t
