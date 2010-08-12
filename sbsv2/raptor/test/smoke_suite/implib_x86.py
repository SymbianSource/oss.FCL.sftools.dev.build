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
	t.name = "implib_x86"
	t.description = "Build a basic IMPLIB TARGETTYPE for x86"
	t.command = "sbs -b smoke_suite/test_resources/simple_implib/bld.inf -c x86"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/x86/lib/simple_implib.lib"
		]
	t.addbuildtargets("smoke_suite/test_resources/simple_implib/bld.inf", [	
		["simple_implib_lib/x86/udeb/simple_implib.prep",
		"simple_implib_lib/x86/urel/simple_implib.prep"],	
		])
	
	t.run("windows")
	return t
