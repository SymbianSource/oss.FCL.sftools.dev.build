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

from raptor_tests import SmokeTest, AntiTargetSmokeTest

def run():
	result = SmokeTest.PASS
	
	t = SmokeTest()
	t.id = "0057a"
	t.name = "gccxml"
	t.usebash = True
	t.command = "sbs -b smoke_suite/test_resources/simple_gui/bld.inf " + \
			"-c gccxml_urel -m ${SBSMAKEFILE} -f ${SBSLOGFILE} && " + \
			"grep -o 'gcc.*-fpermissive' ${SBSLOGFILE}"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/gccxml/includeheaders.txt",
		"$(EPOCROOT)/epoc32/release/gccxml/urel/helloworldexe.gxp"
		]
	t.addbuildtargets('smoke_suite/test_resources/simple_gui/bld.inf', [
		"helloworld_exe/gccxml/HelloWorld.mmp.xml",
		"helloworld_exe/helloworld_HelloWorld.rsc.d",
		"helloworld_exe/gccxml/HelloWorld.rss.rfi",
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg.rsc.d",
		"helloworld_exe/gccxml/HelloWorld_reg.rss.rfi",
		"helloworld_exe/gccxml/urel/HelloWorld_Application.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_Application.xml",
		"helloworld_exe/gccxml/urel/HelloWorld_AppUi.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_AppUi.xml",
		"helloworld_exe/gccxml/urel/HelloWorld_AppView.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_AppView.xml",
		"helloworld_exe/gccxml/urel/HelloWorld_Document.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_Document.xml",
		"helloworld_exe/gccxml/urel/HelloWorld_Main.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_Main.xml"
	])
	t.mustmatch = [
		".*gcc.*-fpermissive.*"
	]
	# Windows-only until formal delivery of a Linux version of gccxml_cc1plus
	t.run("windows")
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	elif t.result == SmokeTest.SKIP:
		return t
	
	
	t = AntiTargetSmokeTest()
	t.id = "0057b"
	t.name = "gccxml_reallyclean"
	t.command = "sbs -b smoke_suite/test_resources/simple_gui/bld.inf " + \
			"-c gccxml_urel REALLYCLEAN"
	t.antitargets = ["$(EPOCROOT)/epoc32/release/gccxml/urel/helloworldexe.gxp"]
	t.addbuildantitargets('smoke_suite/test_resources/simple_gui/bld.inf', [
		"helloworld_exe/gccxml/HelloWorld.mmp.xml",
		"helloworld_exe/helloworld_HelloWorld.rsc.d",
		"helloworld_exe/gccxml/HelloWorld.rss.rfi",
		"helloworld_reg_exe/helloworld_reg_HelloWorld_reg.rsc.d",
		"helloworld_exe/gccxml/HelloWorld_reg.rss.rfi",
		"helloworld_exe/gccxml/urel/HelloWorld_Application.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_Application.xml",
		"helloworld_exe/gccxml/urel/HelloWorld_AppUi.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_AppUi.xml",
		"helloworld_exe/gccxml/urel/HelloWorld_AppView.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_AppView.xml",
		"helloworld_exe/gccxml/urel/HelloWorld_Document.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_Document.xml",
		"helloworld_exe/gccxml/urel/HelloWorld_Main.xml.d",
		"helloworld_exe/gccxml/urel/HelloWorld_Main.xml"
	])
	t.run("windows")
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
		
		
	t = SmokeTest()
	t.id = "0057c"
	t.name = "gccxml_var2"
	t.command = "sbs -b smoke_suite/test_resources/simple_gui/BldVar2.inf " + \
			"-c gccxml_urel -f -"
	
	# Don't allow -m or -f to be appended
	t.logfileOption = lambda :""
	t.makefileOption = lambda :""
	
	t.mustmatch = [".*__KERNEL_MODE__.*"]
	t.errors = 1 # not really VAR2 code, so it wont build cleanly
	t.returncode = 1
	t.run("windows")
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
		
		
	t = SmokeTest()
	t.id = "0057d"
	t.name = "gccxml_stdcpp"
	t.command = "sbs -b smoke_suite/test_resources/simple_gui/Bld_stdcpp.inf " + \
			"-c gccxml_urel -f -"
	
	# Don't allow -m or -f to be appended
	t.logfileOption = lambda :""
	t.makefileOption = lambda :""
	
	t.mustmatch = [".*__SYMBIAN_STDCPP_SUPPORT__.*"]
	t.errors = 0 # reset after previous run
	t.run("windows")
	if t.result == SmokeTest.FAIL:
		result = SmokeTest.FAIL
	
		
	t.id = "57"
	t.name = "gccxml"
	t.result = result
	t.print_result()
	return t

