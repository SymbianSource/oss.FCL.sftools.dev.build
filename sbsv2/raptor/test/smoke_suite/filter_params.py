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
	t.description = "Test the passing of parameters to log filters"
	
	command = "sbs -b smoke_suite/test_resources/simple/bld.inf -c armv5_urel --filters="
	
	# no parameters means count all tags	
	t.name = "filter_params_all_tags"
	t.command = command + "FilterTagCounter"
	t.mustmatch_singleline = [
		"^info \d+ \d+",
		"^whatlog \d+ \d+",
		"^clean \d+ \d+"	
		]
	t.run()
	
	# empty parameter lists are valid
	t.name = "filter_params_all_tags2"
	t.command = command + "FilterTagCounter[]"
	t.run()
	
	# parameters mean report only those tags	
	t.name = "filter_params_info"
	t.command = command + "FilterTagCounter[info]"
	t.mustmatch_singleline = [
		"^info \d+ \d+"
		]
	t.mustnotmatch_singleline = [
		"^whatlog \d+ \d+",
		"^clean \d+ \d+"	
		]
	t.run()
	
	# multiple parameters are valid	
	t.name = "filter_params_info_clean"
	t.command = command + "FilterTagCounter[info,clean]"
	t.mustmatch_singleline = [
		"^info \d+ \d+",
		"^clean \d+ \d+"
		]
	t.mustnotmatch_singleline = [
		"^whatlog \d+ \d+"
		]
	t.run()
	
	# using the same filter with different parameters is valid
	t.name = "filter_params_info_clean2"
	t.command = command + "FilterTagCounter[info],FilterTagCounter[clean]"
	t.run()
	
	# using the same filter with the same parameters is valid too
	t.name = "filter_params_info_clean3"
	t.command = command + "FilterTagCounter[info,clean],FilterTagCounter[info,clean]"
	t.run()
	
	
	# parameters must work with the sbs_filter script as well
	
	command = "sbs_filter --filters=%s < smoke_suite/test_resources/logexamples/filter_component.log"
	t.logfileOption = lambda :""
	t.makefileOption = lambda :""

	# should still work with no parameters
	t.name = "sbs_filter_no_params"
	t.command = command % "FilterComp"
	t.mustmatch_singleline = [
		]
	t.mustnotmatch_singleline = [
		"[<>]" # no elements should be printed at all as no bld.inf is selected
		]
	t.run()
	
	# should work with an empty parameter list
	t.name = "sbs_filter_no_params2"
	t.command = command % "FilterComp[]"
	t.run()
	
	# with a parameter
	t.name = "sbs_filter_one_param"
	t.command = command % "FilterComp[email]"
	t.stdout = [
		"<error bldinf='y:/src/email/bld.inf'>email error #1</error>",
		"<error bldinf='y:/src/email/bld.inf'>email error #2</error>",
		"<warning bldinf='y:/src/email/bld.inf'>email warning #1</warning>",
		"<warning bldinf='y:/src/email/bld.inf'>email warning #2</warning>",
		"<whatlog bldinf='y:/src/email/bld.inf' config='armv5_urel' mmp='y:/src/email/a.mmp'>",
		"<build>/epoc32/data/email_1</build>",
		"<build>/epoc32/data/email_2</build>",
		"</whatlog>",
		"<recipe bldinf='y:/src/email/bld.inf' name='dummy'>",
		"+ make_email",
		"email was made fine",
		"<status exit='ok'></status>",
		"</recipe>",
		"<fake bldinf='y:src/email/bld.inf'>",
		"  <foo>",
		"   <bar>",
		"     <fb>fb email</fb>",
		"   </bar>",
		" </foo>",
		"</fake>"
		]
	t.mustmatch_singleline = []
	t.mustnotmatch_singleline = []
	t.warnings = 2
	t.errors = 2
	t.run()
	
	# with multiple filters
	t.name = "sbs_filter_multi"
	t.command = command % "FilterComp[txt],FilterTagCounter[file,recipe]"
	t.stdout = []
	t.mustmatch_singleline = [ "txt", "^file \d+", "^recipe \d+" ]
	t.mustnotmatch_singleline = [ "email" ]
	t.warnings = 2
	t.errors = 0
	t.run()
	
	t.name = "filter_params"
	t.print_result()
	return t
