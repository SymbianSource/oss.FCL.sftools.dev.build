#
# Copyright (c) 2000-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Component description file
#
from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "8"
	t.name = "bitmap"
	t.description = "This step is for testing BITMAP keyword and MIFCONV support for s60"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/bitmap/bld.inf BITMAP && grep -ir 'MIFCONV_TEST:=1' $(EPOCROOT)/epoc32/build"
	t.targets = [
		"$(EPOCROOT)/epoc32/include/testbitmap.mbg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/testbitmap.mBm",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/test/mifconv.xml",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/test/mifconv.flm"
		]
	t.addbuildtargets('smoke_suite/test_resources/bitmap/bld.inf', [
		"testbitmap_dll/testbitmap.mBm_bmconvcommands"
	])
	t.mustmatch = [
		".*Makefile(_all)?.bitmap:MIFCONV_TEST:=1.*"
	]
	t.mustnotmatch = [
		".*Makefile(_all)?.default:MIFCONV_TEST.*"
	]
	t.run()
	return t
