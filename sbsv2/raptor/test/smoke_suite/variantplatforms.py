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
	t.id = "300"
	t.name = "variantplatforms"
	t.description = "Can all the variant platforms be built at the same time."
	
	variantplatforms = ["armv5", "armv6", "armv7", "arm9e"]
	
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/variantplatforms/bld.inf -f-"
	t.mustmatch_singleline = []
	
	for vp in variantplatforms:
		t.command += " -c " + vp
		t.mustmatch_singleline.append("building variant platform " + vp)

	t.run()
	
	t.print_result()
	return t
