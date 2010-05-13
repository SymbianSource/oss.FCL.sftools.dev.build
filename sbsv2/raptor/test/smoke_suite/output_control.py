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
from os import environ

from raptor_tests import SmokeTest

def run():

	commonbuildfiles = [ 
		"createstaticdll_dll/armv5/urel/CreateStaticDLL.o",
		"createstaticdll_dll/armv5/urel/CreateStaticDLL.o.d",
		"createstaticdll_dll/winscw/urel/CreateStaticDLL.o",
		"createstaticdll_dll/winscw/urel/CreateStaticDLL.o.d",
		"createstaticdll_dll/winscw/urel/createstaticdll.UID.CPP",
		"createstaticdll_dll/winscw/urel/createstaticdll_UID_.o.d"
	]
	
	t = SmokeTest()
	t.id = "82"
	t.name = "output_control"
	t.description = "Test building intermediate files into a location other than $EPOCROOT/epoc32/build. Use SBS_BUILD_DIR. environment variable."
	t.sbs_build_dir = environ['EPOCROOT'].replace("\\","/").rstrip("/") + '/anotherbuilddir'
	t.environ['SBS_BUILD_DIR'] = t.sbs_build_dir
	t.command = "sbs -b smoke_suite/test_resources/simple_dll/bld.inf -c armv5_urel -c winscw_urel"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/createstaticdll{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/urel/createstaticdll.dll",
                "$(EPOCROOT)/epoc32/release/winscw/urel/createstaticdll.dll",
                "$(EPOCROOT)/epoc32/release/winscw/urel/createstaticdll.dll.map"
								
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_dll/bld.inf', commonbuildfiles) 
	t.run()
	
	return t
