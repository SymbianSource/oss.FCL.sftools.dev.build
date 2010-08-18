#
# Copyright (c) 2007-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# This module tests the MMPParser Class()
# It runs on data from the standard input
#


from mmpparser import *
import unittest
import os
import re

class MMPTester(MMPBackend):
	"""A parser testing "backend" for the MMP language
	This is used to test MMP parsing independently of the build system. """
	def __init__(self):
		super(MMPTester,self).__init__()
		self.sourcepath="."
		self.platformblock = None
		self.output=""

	def log(self,text):
		self.output += text + "\n"

	def doStartResource(self,s,loc,toks):
		self.log("Create resource "+toks[0]+" of " + str(toks))
		return "OK"

	def doResourceAssignment(self,s,loc,toks):
		self.log("Set "+toks[0]+" to " + toks[1])
		return "OK"

	def doEndResource(self,s,loc,toks):
		self.log("Finalise resource "+toks[0]+" of " + str(toks))
		return "OK"

	def doStartPlatform(self,s,loc,toks):
		self.log("Start Platform block "+toks[0])
		self.platformblock = toks[0]
		return "OK"

	def doEndPlatform(self,s,loc,toks):
		self.log("Finalise platform " + self.platformblock)
		return "OK"

	def doSetSwitch(self,s,loc,toks):
		self.log("Set switch "+toks[0]+" ON")
		return "OK"

	def doAssignment(self,s,loc,toks):
		self.log("Set "+toks[0]+" to " + str(toks[1]))
		return "OK"

	def doAppend(self,s,loc,toks):
		self.log("Append to "+toks[0]+" the values: " + str(toks[1]))
		return "OK"

	def doUIDAssignment(self,s,loc,toks):
		self.log("Set UID2 to " + toks[1][0])
		if len(toks[1]) > 1:
			self.log("Set UID3 to " + toks[1][1])
		return "OK"

	def doSourcePathAssignment(self,s,loc,toks):
		self.log("Remembering self.sourcepath state:  "+str(toks[0])+" is now " + str(toks[1]))
		self.sourcepath=toks[1]
		return "OK"

	def doSourceAssignment(self,s,loc,toks):
		self.log("Setting "+toks[0]+" to " + str(toks[1]))
		for i in toks[1]:
			self.log(self.sourcepath + "\\" + i)
		return "OK"
	
	def doDocumentAssignment(self,s,loc,toks):
		self.log("Setting "+toks[0]+" to " + str(toks[1]))
		for i in toks[1]:
			self.log(self.sourcepath + "\\" + i)
		return "OK"
	
	def doStartBitmap(self,s,loc,toks):
		self.log("BITMAP Create "+toks[0]+" to " + str(toks[1]))
		return "OK" 
		
	def doBitmapAssignment(self,s,loc,toks):
		self.log("BITMAP Setting "+toks[0]+" to " + str(toks[1]))
		self.log("		must set a value within a bitmap FLM call")
		return "OK"

	def doEndBitmap(self,s,loc,toks):
		self.log("Finish bitmap "+toks[0]+" to " + str(toks[1]))
		return "OK" 

	def doStartStringTable(self,s,loc,toks):
		self.log("Start STRINGTABLE "+toks[1])
		return "OK" 

	def doStringTableAssignment(self,s,loc,toks):
		self.log("Set"+toks[0]+" to " + toks[1])
		return "OK"

	def doEndStringTable(self,s,loc,toks):
		self.log("End STRINGTABLE "+toks[1])
		return "OK" 

	def doUnknownStatement(self,s,loc,toks):
		self.log("Ignoring unknown statement at " + str(loc))
		return "OK"

	def doUnknownBlock(self,s,loc,toks):
		self.output += "Ignoring unknown block at " + str(loc)
		return "OK"

	def doMMP(self,s,loc,toks):
		return "MMP"



class TestMMPParser(unittest.TestCase):
	def setUp(self):
		pass

	def testAll(self):
		tests = [{'name' : "TestFeatures", 'text' :  
"""ASSPLIBRARY 123 456 789
LIBRARY  eexe euser
ALWAYS_BUILD_AS_ARM
NOEXPORTLIBRARY
TARGET FRED
TARGETTYPE EXE
SOURCEPATH \usr
SOURCE alice.cia fred.cpp bob.cpp
SOURCEPATH \someotherplace\ 
SOURCE custard.cpp the.cpp dragon.cpp

START ARMCC
ARMLIBS somelib
ARMRT
END

START WINC
END

START RESOURCE fred.rss
TARGET fred
TARGETPATH /usr/local
END
UID 0x12354 123455
""", 'mustmatch': r"Set UID3 to 123455"}, \
				{'name':"TestUnknownStatements", 'text': \
"""

TARGET FRED12345
SOURCEPATH \usr


""", 'mustmatch': r"Remembering self.sourcepath state:"}, \
				{'name':"PreceedingBlankLines", 'text': \
"""

ASSPLIBRARY 123 456 789
LIBRARY  eexe euser
ALWAYS_BUILD_AS_ARM
NOEXPORTLIBRARY
TARGET FRED
SOURCEPATH \usr
START ARMCC
ARMLIBS somepath
ARMRT
END
START RESOURCE fred.rss
TARGET fred
TARGETPATH /usr/local
END


""", 'mustmatch': r"Set TARGETPATH to /usr/local"}, \
				{ 'name': "Testvfprvct", 'text': \
"""
targettype dll
sourcepath .
source dfprvct2_2.cpp
library euser.lib
library scppnwdl.lib drtrvct2_2.lib
option armcc --no_exceptions --no_exceptions_unwind
start armcc
armrt
armlibs c_t__un.l
end
capability all
vendorid 0x70000001
target dfprvct2_2.dll
start armcc
armlibs f_t_p.l g_t_p.l
end
unpaged

""", 'mustmatch': r"Set switch UNPAGED ON"}, \
				{ 'name': "TestUSRT", 'text': \
"""
TARGET fred
START ARMCC
ARMINC 
ARMRT
END
VENDORID 0x70000001
""", 'mustmatch': r"Set VENDORID to 0x70000001"}, \
				{ 'name': "TestRESOURCE", 'text': \
"""
TARGET reccaf.dll
CAPABILITY TrustedUI ProtServ DRM
TARGETTYPE PLUGIN
UID 0x10009D8D 0x101ff761
VENDORID 0x70000001
SOURCEPATH ../source/reccaf
SOURCE CafApaRecognizer.cpp mimetypemapping.cpp
START RESOURCE 101ff761.rss
TARGET reccaf.rsc
END
USERINCLUDE ../source/caf
USERINCLUDE ../source/reccaf
SYSTEMINCLUDE /epoc32/include
SYSTEMINCLUDE /epoc32/include/caf
SYSTEMINCLUDE /epoc32/include/ecom
LIBRARY euser.lib apmime.lib estor.lib
LIBRARY caf.lib efsrv.lib
""", 'mustmatch': r"Create resource .* of"}, \
				{ 'name': "TestRESOURCE", 'text': \
"""
TARGET cafutils.dll
CAPABILITY All -Tcb
TARGETTYPE DLL
UID 0x101FD9B8
VENDORID 0x70000001
UNPAGED
SOURCEPATH ../source/cafutils
SOURCE Cafutils.cpp
SOURCE attributeset.cpp
SOURCE stringattribute.cpp
SOURCE stringattributeset.cpp
SOURCE virtualpath.cpp
SOURCE Metadata.cpp
SOURCE Metadataarray.cpp
SOURCE embeddedobject.cpp
SOURCE rightsinfo.cpp
SOURCE Virtualpathptr.cpp
SOURCE dirstreamable.cpp
SOURCE bitset.cpp
SOURCE cafmimeheader.cpp
SOURCE mimefieldanddata.cpp
USERINCLUDE ../inc
USERINCLUDE ../source/cafutils
SYSTEMINCLUDE /epoc32/include
SYSTEMINCLUDE /epoc32/include/caf
SYSTEMINCLUDE /epoc32/include/libc
LIBRARY euser.lib
LIBRARY estor.lib
LIBRARY charconv.lib
LIBRARY efsrv.lib
LIBRARY apgrfx.lib
LIBRARY ecom.lib
LIBRARY apmime.lib
""", 'mustmatch': r"LIBRARY"},
				{ 'name': "TestEmptyStringTable", 'text': \
"""
OPTION CW   -w off
TARGET          testwebbrowser.exe
TARGETTYPE      EXE
CAPABILITY ALL -TCB

SYSTEMINCLUDE   /epoc32/include /epoc32/include/ecom
USERINCLUDE     ../inc
USERINCLUDE     ../../httpexampleclient

START STRINGTABLE ../data/htmltagstable.st

END

SOURCEPATH      ../../httpexampleclient
SOURCE httpexampleutils.cpp
""", 'mustmatch': r"End STRINGTABLE OK"},
				{ 'name': "TestARMINC", 'text': \
"""
# 1 "<built-in>"
# 1 "<command line>"
# 10 "<command line>"
# 1 "/var/local/net/smb/tmurphy/cluster_epocroot_1/epoc32/include/variant/Symbian_OS_vFuture.hrh" 1
# 11 "<command line>" 2
# 1 "/localhome/tmurphy/pf/mcloverlay/cedar/generic/base/e32/compsupp/rvct2_2/drtrvct2_2_vfpv2.mmp"
# 1 "/localhome/tmurphy/pf/mcloverlay/cedar/generic/base/e32/compsupp/rvct2_2/drtrvct2_2_common.mmh" 1
TARGETTYPE dll
OPTION ARMCC--no_exceptions --no_exceptions_unwind
SOURCEPATH .
SOURCE rtabort.cpp
SOURCE rtdiv0.cpp
SOURCE rtexit.cpp
SOURCE rtlib.cpp
SOURCE rtraise.cpp
SOURCE drtrvct2_2.cpp
SOURCE rtopnew.cpp rtopdel.cpp
SOURCE sftfpini.cpp
LIBRARY scppnwdl.lib euser.lib
SYSTEMINCLUDE ../../include
START ARMCC
ARMRT
ARMINC
ARMLIBS c_t__un.l
ARMLIBS h_t__un.l
# 46 "/localhome/tmurphy/pf/mcloverlay/cedar/generic/base/e32/compsupp/rvct2_2/drtrvct2_2_common.mmh"
END
capability all
VENDORID 0x70000001
# 7 "/localhome/tmurphy/pf/mcloverlay/cedar/generic/base/e32/compsupp/rvct2_2/drtrvct2_2_vfpv2.mmp" 2
TARGET drtrvct2_2_vfpv2.dll
LINKAS drtrvct2_2.dll
NOEXPORTLIBRARY
START ARMCC
ARMLIBS f_tvp.l
END
unpaged
""", 'mustmatch': r"Set.*ARMINC"}]
		for i in tests:
			tester = MMPTester()
			mp = MMPParser(tester)
			try:
				result = mp.mmp.parseString(i['text'])
			except ParseException,e:
				pass
			self.assertEquals(result[0],'MMP')
			self.assertNotEquals(re.search(i['mustmatch'],tester.output,re.M),None)

# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "mmpparser_unit"

	tests = unittest.makeSuite(TestMMPParser)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
