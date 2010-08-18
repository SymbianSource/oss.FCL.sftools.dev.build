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

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	
	t.id = "71a"
	t.name = "implib_implicit_def"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/nodef/group/bld.inf" \
			+ " -p implib_implicit_def.mmp"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/implib_implicit_def.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/implib_implicit_def{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/implib_implicit_def.lib"
		]
	t.run()

	t.id = "71b"
	t.name = "implib_no_def"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/nodef/group/bld.inf" \
			+ " -p implib_no_def.mmp"
	t.targets = []
	t.mustmatch = [
		"No DEF File for IMPLIB target type in"	
		]
	t.errors = 2 # 1 for winscw and 1 for armv5
	t.returncode = 1
	t.run()

	t.id = "71"
	t.name = "implib_nodef"
	t.print_result()

	return t
