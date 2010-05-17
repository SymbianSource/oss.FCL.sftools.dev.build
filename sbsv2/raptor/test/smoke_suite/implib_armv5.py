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
	t.id = "14"
	t.name = "implib_armv5"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/bld.inf" \
		+ " -c armv5 LIBRARY"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/simple_implib{000a0000}.dso"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_implib/bld.inf', [
		['simple_implib_lib/armv5/udeb/simple_implib.prep',
                 'simple_implib_lib/armv5/urel/simple_implib.prep']
	])
	t.run()
	
	t.print_result()	
	return t
