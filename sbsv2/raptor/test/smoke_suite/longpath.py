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

def run():

	#------------------------------------------------------------------------------
	# Content for files to be generated.
	#------------------------------------------------------------------------------
	cpp = "longerfilenamethanyoumightnormallyexpecttobepresent"
	path = "/test/smoke_suite/test_resources/longerpathnamesthanyoumightnormallyexpectinabuildtree/anotherlevelwithareallyreallyreallylongnamethistimeprobablyabitoverthetop/"
	path_eabi = "/test/smoke_suite/test_resources/longerpathnamesthanyoumightnormallyexpectinabuildtree/eabi/"
	
	#------------------------------------------------------------------------------
	# Some numbers for path and file operations
	#------------------------------------------------------------------------------
	cppStart = 1
	cppStop = 49
	
	import os
	import shutil
	import sys
	
	#------------------------------------------------------------------------------
	# Find SBS_Home
	#------------------------------------------------------------------------------
	sbsHome = os.environ["SBS_HOME"]
	
	#------------------------------------------------------------------------------
	# Create directories for both Linux and Windows
	#------------------------------------------------------------------------------
	d = os.path.dirname(sbsHome + path)
	if not os.path.exists(d):
		os.makedirs(d)
		
	d = os.path.dirname(sbsHome + path_eabi)
	if not os.path.exists(d):
		os.makedirs(d)

	#------------------------------------------------------------------------------
	# File generating utility
	#------------------------------------------------------------------------------
	while cppStart <= cppStop:
			t = str(cppStart)
			filename = sbsHome + path + 'test' + '%02d' %cppStart + '.cpp'
			content = 'int x' + t + ' = 0;'
			cppStart = cppStart + 1
			f = open (filename, 'w')
			f.write (content + '\n')
			f.close()
	cppStart = cppStart + 1

	#------------------------------------------------------------------------------
	# File copying utility
	#------------------------------------------------------------------------------
	dirname = sbsHome + '/test/smoke_suite/test_resources/long/paths/'
	cpp = dirname + 'test.cpp'
	bld = dirname + 'bld.inf'
	deftest = dirname + 'deftest.mmp'
	e32def = dirname + 'e32def.h'
	
	deftestu = dirname + 'deftestu.def'
	
	dst_cpp = sbsHome + path + 'test.cpp'
	dst_bld = sbsHome + path + 'bld.inf'
	dst_deftest = sbsHome + path + 'deftest.mmp'
	dst_e32def = sbsHome + path + 'e32def.h'
	dst_deftestu = sbsHome + path_eabi + 'deftestu.def'
	
		
	if os.path.exists(dst_cpp):
		pass
	else:
		shutil.copy(cpp, dst_cpp)
		shutil.copy(bld, dst_bld)
		shutil.copy(deftest, dst_deftest)
		shutil.copy(e32def, dst_e32def)
		shutil.copy(deftestu , dst_deftestu)
		dirname = sbsHome + path
		
	t = SmokeTest()
	t.id = "41"
	t.name = "longpath"
	t.command = "sbs -b " + \
			"smoke_suite/test_resources/longerpathnamesthanyoumightnormallyexpectinabuildtree/anotherlevelwithareallyreallyreallylongnamethistimeprobablyabitoverthetop/bld.inf" + \
			" -c armv5"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/deftest.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/deftest.dll.sym",
		"$(EPOCROOT)/epoc32/release/armv5/lib/deftest{000a0000}.dso",
		"$(EPOCROOT)/epoc32/release/armv5/lib/deftest.dso",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/deftest.dll",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/deftest.dll.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/deftest.dll",
		"$(EPOCROOT)/epoc32/release/armv5/urel/deftest.dll.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/longerpathnamesthanyoumightnormallyexpectinabuildtree/anotherlevelwithareallyreallyreallylongnamethistimeprobablyabitoverthetop/bld.inf', [
		"deftest_/armv5/udeb/deftest_udeb_objects.via",
		"deftest_/armv5/udeb/test.o",
		"deftest_/armv5/udeb/test09.o",
		"deftest_/armv5/udeb/test19.o",
		"deftest_/armv5/udeb/test29.o",
		"deftest_/armv5/udeb/test39.o",
		"deftest_/armv5/udeb/test49.o",
		"deftest_/armv5/urel/deftest_urel_objects.via",
		"deftest_/armv5/urel/test.o",
		"deftest_/armv5/urel/test09.o",
		"deftest_/armv5/urel/test19.o",
		"deftest_/armv5/urel/test29.o",
		"deftest_/armv5/urel/test39.o",
		"deftest_/armv5/urel/test49.o"
	])
	t.run()
	return t
