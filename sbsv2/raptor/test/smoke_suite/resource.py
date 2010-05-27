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
from raptor_tests import ReplaceEnvs
from raptor_meta import BldInfFile

def run():
	t = SmokeTest()
	t.id = "30"
	t.name =  "resource"
	t.command = "sbs  -b smoke_suite/test_resources/simple_gui/Bld.inf RESOURCE"
	t.targets = [
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.mbm",
		"$(EPOCROOT)/epoc32/include/helloworld.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/data/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/helloworld.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/private/10003a3f/apps/helloworld_reg.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/private/10003a3f/apps/helloworld_reg.rsc"	
		]
	

	t.addbuildtargets('smoke_suite/test_resources/simple_gui/Bld.inf', [
		"helloworld_exe/helloworld.mbm_bmconvcommands",
		"helloworld_exe/helloworld_HelloWorld_sc.rpp",
		"helloworld_exe/helloworld_HelloWorld_sc.rpp.d",
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg_sc.rpp",
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg_sc.rpp.d"])

	t.mustnotmatch = ["HelloWorld.rss.* warning: trigraph"]
	
	t.run()

	t.id="30a"
	t.name =  "no_depend_gen_resource"
	t.usebash = True
	t.description =  """Check that dependent resources still build correctly even when we turn dependency generation off.  This
			    test cannot really do this reliably, if you think about it, since it can't force make to try building resources
			    in the 'wrong' order.  What it does attempt is to check that 
			    the ultimately generated dependency file is ok.
			    N.B.  It also attempts to ensure that the dependency file is 'minimal'  i.e. that it only references .mbg and .rsg files
			    that might come from other parts of the same build.  This is important for performance in situations where --no-depend-generate
			    is used because the weight of 'complete' dependency information would overwhelm make.
			 """
	buildLocation = ReplaceEnvs("$(EPOCROOT)/epoc32/build/") + BldInfFile.outputPathFragment('smoke_suite/test_resources/resource/group/bld.inf')
	res_depfile= buildLocation+"/dependentresource_/dependentresource_dependentresource_sc.rpp.d"


	t.targets = [
		"$(EPOCROOT)/epoc32/data/z/resource/anotherresource/testresource.r01",
		"$(EPOCROOT)/epoc32/data/z/resource/anotherresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/data/z/resource/dependentresource/dependentresource.rsc",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.r01",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/include/testresource.hrh",
		"$(EPOCROOT)/epoc32/include/testresource.rsg",
		"$(EPOCROOT)/epoc32/release/armv5/urel/testresource.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/anotherresource/testresource.r01",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/anotherresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/dependentresource/dependentresource.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/anotherresource/testresource.r01",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/anotherresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/dependentresource/dependentresource.rsc",
		res_depfile
		]

	t.addbuildtargets('smoke_suite/test_resources/resource/group/bld.inf', [
		"dependentresource_/dependentresource_dependentresource.rsc",
		"testresource_/testresource_dependentresource.r01",
		"testresource_/testresource_dependentresource.rsc",
		"testresource_/testresource_testresource_01.rpp",
		"testresource_/testresource_testresource_01.rpp.d",
		"testresource_/testresource_testresource_02.rpp",
		"testresource_/testresource_testresource_sc.rpp"])

	t.command = "sbs -b smoke_suite/test_resources/resource/group/bld.inf  -c armv5_urel -c winscw_urel reallyclean ; sbs --no-depend-generate -j 16 -b smoke_suite/test_resources/resource/group/bld.inf -c armv5_urel -c  winscw_urel -f ${SBSLOGFILE} -m ${SBSMAKEFILE} && grep 'epoc32.include.testresource.rsg' %s && { X=`md5sum $(EPOCROOT)/epoc32/release/winscw/urel/z/resource/anotherresource/testresource.rsc` && Y=`md5sum $(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.rsc` && [ \"${X%% *}\" != \"${Y%% *}\" ] ; }  && wc -l %s " % (res_depfile, res_depfile)

	t.mustnotmatch = []

	t.mustmatch = [
			"[23] .*.dependentresource_.dependentresource_dependentresource_sc.rpp.d"
		      ]

	t.run()

	t.name = 'resource'
	t.print_result()
	return t
