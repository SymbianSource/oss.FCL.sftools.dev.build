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
	
	t.name = "filter_params"
	t.print_result()
	return t
