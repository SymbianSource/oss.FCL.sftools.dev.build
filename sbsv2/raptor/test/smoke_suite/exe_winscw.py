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

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "33"
	t.name = "exe_winscw"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c winscw -m ${SBSMAKEFILE} -f ${SBSLOGFILE}; grep -E \"mwldsym2\" ${SBSLOGFILE}"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/winscw/udeb/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/test.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple/bld.inf', [
		"test_/winscw/udeb/test.o",
		"test_/winscw/udeb/test_.o",
		"test_/winscw/udeb/test_UID_.o",
		"test_/winscw/udeb/test.UID.CPP",
		"test_/winscw/urel/test.o",
		"test_/winscw/urel/test_.o",
		"test_/winscw/urel/test_UID_.o",
		"test_/winscw/urel/test.UID.CPP"
	])
	# Check that the default operator new library is used
	t.mustmatch = [
		'.*mwldsym2.*scppnwdl.lib.*test.exe.*'
		]
	t.run()
	return t
