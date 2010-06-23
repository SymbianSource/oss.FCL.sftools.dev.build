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
	t.id = "26"
	t.name = "armv5_stringtable"
	t.command = "sbs -b smoke_suite/test_resources/simple_stringtable/bld.inf" \
			+ " -c armv5 EXPORT"
	t.targets = [
		"$(EPOCROOT)/epoc32/include/strconsts.h"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_stringtable/bld.inf', [
		"stringtabletest_/strconsts.h",
		"stringtabletest_/strconsts.cpp"
	])
	t.run()
	return t
