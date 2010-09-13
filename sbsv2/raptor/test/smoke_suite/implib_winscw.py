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
	t.id = "36"
	t.name = "implib_winscw"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/bld.inf -c " \
			+ "winscw LIBRARY"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/winscw/udeb/simple_implib.lib"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_implib/bld.inf', [
		["simple_implib_lib/winscw/udeb/simple_implib.prep.def",
		"simple_implib_lib/winscw/urel/simple_implib.prep.def"]
	])
	t.run()
	return t
