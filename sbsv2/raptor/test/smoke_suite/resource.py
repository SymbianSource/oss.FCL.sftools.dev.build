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
		"helloworld_exe/helloworld_HelloWorld.rsc.rpp",
		"helloworld_exe/helloworld_HelloWorld.rsc.d",
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg.rsc.rpp",
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg.rsc.d"])

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
	res_depfile= buildLocation+"/dependentresource_/dependentresource_dependentresource.rsc.d"


	t.targets = [
		"$(EPOCROOT)/epoc32/data/z/resource/anotherresource/testresource.r01",
		"$(EPOCROOT)/epoc32/data/z/resource/anotherresource/testresource.rsc",
		"$(EPOCROOT)/epoc32/data/z/resource/dependentresource/dependentresource.rsc",
		"$(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.r01",
		"$(EPOCROOT)/epoc32/include/testresource.hrh",
		"$(EPOCROOT)/epoc32/include/testresource.rsg",
		"$(EPOCROOT)/epoc32/include/onelang.rsg",
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
		"testheader_/testheader_testresource_sc.rsg.d",
		"testheader_/testheader_testresource_sc.rsg.rpp",
		"testresource_/testresource_testresource.r02.rpp",
		"onelang_/onelang_onelang_sc.rsg.rpp",
		"testresource_/testresource_testresource.rsc.rpp"])

	t.command = "sbs -b smoke_suite/test_resources/resource/group/bld.inf  -c armv5_urel -c winscw_urel reallyclean ; sbs --no-depend-generate -j 16 -b smoke_suite/test_resources/resource/group/bld.inf -c armv5_urel -c  winscw_urel -f ${SBSLOGFILE} -m ${SBSMAKEFILE} && grep 'epoc32.include.test[^ ]*.rsg' %s && { X=`md5sum $(EPOCROOT)/epoc32/release/winscw/urel/z/resource/anotherresource/testresource.rsc` && Y=`md5sum $(EPOCROOT)/epoc32/data/z/resource/testresource/testresource.rsc` && [ \"${X%% *}\" != \"${Y%% *}\" ] ; }  && wc -l %s " % (res_depfile, res_depfile)


	t.mustnotmatch = []

	t.mustmatch = [
			"[23] .*.dependentresource_.dependentresource_dependentresource.rsc.d"
		      ]

	t.run()
	
	t.id="30b"
	t.name =  "resource_corner_cases_reallyclean"
	t.usebash = True
	t.description =  """ Additional corner cases for resources:
						 1) Use of "TARGETTYPE none" but not "TARGET" mmp keyword.
						 2) Use of a resource with no LANG. """

	t.targets = []

	t.command = "sbs -b smoke_suite/test_resources/resource/group/bld2.inf -c armv5_urel -c winscw_urel reallyclean"
	t.mustnotmatch = []
	t.mustmatch = []
	t.run()
	
	t.id="30c"
	t.name =  "resource_corner_cases"
	t.usebash = True
	t.description =  """ Additional corner cases for resources:
						 1) Use of "TARGETTYPE none" but not "TARGET" mmp keyword.
						 2) Use of a resource with no LANG. """
	
	buildLocation = ReplaceEnvs("$(EPOCROOT)/epoc32/build/") + BldInfFile.outputPathFragment('smoke_suite/test_resources/resource/group/bld2.inf')
	rsc_file= buildLocation+"/testresource_/testresource_testresource.rsc"
	

	t.targets = ["$(EPOCROOT)/epoc32/data/z/resource/apps/notargetkeyword.mbm",
				 "$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/notargetkeyword.mbm",
				 "$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/notargetkeyword.mbm",
				 rsc_file ]

	t.command = "sbs -b smoke_suite/test_resources/resource/group/bld2.inf -c armv5_urel -c winscw_urel"
	t.mustnotmatch = []
	t.mustmatch = []
	t.run()

	t.name = 'resource'
	t.print_result()
	return t
