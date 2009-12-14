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

from raptor_tests import CheckWhatSmokeTest
import re, os

def run():
	t = CheckWhatSmokeTest()
	t.id = "67"
	t.name = "implib_whatlog"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/bld.inf -f -" \
			" -m ${SBSMAKEFILE} -c armv5.whatlog -c winscw.whatlog LIBRARY"
	componentpath = re.sub(r'\\','/',os.path.abspath("smoke_suite/test_resources/simple_implib"))
	t.regexlinefilter = re.compile("^<(whatlog|build>)")
	t.hostossensitive = False
	t.usebash = True
	# ABIv1 .lib files are not generated on Linux
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/simple_implib.lib"
		]
	t.stdout = [
		"<whatlog bldinf='"+componentpath+"/bld.inf' mmp='"+componentpath+"/simple_implib.mmp' config='winscw_udeb.whatlog'>",
		"<build>$(EPOCROOT)/epoc32/release/winscw/udeb/simple_implib.lib</build>",
		"<whatlog bldinf='"+componentpath+"/bld.inf' mmp='"+componentpath+"/simple_implib.mmp' config='winscw_urel.whatlog'>",
		"<build>$(EPOCROOT)/epoc32/release/winscw/udeb/simple_implib.lib</build>",
		"<whatlog bldinf='"+componentpath+"/bld.inf' mmp='"+componentpath+"/simple_implib.mmp' config='armv5_udeb.whatlog'>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.dso</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.dso</build>",
		"<whatlog bldinf='"+componentpath+"/bld.inf' mmp='"+componentpath+"/simple_implib.mmp' config='armv5_urel.whatlog'>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.dso</build>",
		"<build>$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.dso</build>"
	]
	t.run("linux")
	if t.result == CheckWhatSmokeTest.SKIP:
		t.targets.extend([
			"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.lib",
			"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.lib"
		])
		t.stdout.extend([
			"<build>$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.lib</build>",
			"<build>$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.lib</build>"
		])
		t.run("windows")
		
	return t
