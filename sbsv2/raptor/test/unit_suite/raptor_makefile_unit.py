#
# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# test flm makefile call generator module
# tests flm call generation.
#

from raptor_makefile import *
import re
import unittest
import os
import sys

epocroot = os.path.abspath(os.environ.get('EPOCROOT')).replace("\\","\/")
topdir = epocroot+"/epoc32/build/raptor_make_unit/"

def unlinkall(files):
	for f in files:
		try:
			os.unlink(f)
			#print "testsetup: Erased %s" % f	
			continue
		except OSError,e:
			#print "testsetup: No need to erase %s" % f
			continue


def checkall(files):
	status = True
	for f in files:
		if not os.path.isfile(f):
			print "Missing: %s" % f
			status = False
	return status 

class TestMakefile(unittest.TestCase):
	"Very basic testing of makefile creation class"
	def setUp(self):
		print "Setup"
		self.assertTrue(os.path.isdir(epocroot))
		unlinkall( [ topdir + "Makefile1",
			topdir + "Makefile2.testinterface1",
			topdir + "Makefile3.testinterface1",
			topdir + "child1/Makefile3.testinterface1" ])
			
	def testMakefileCreateEmpty(self):
		# No makefile is created because nothing is put into the makefile
		selector = MakefileSelector("testinterface1","testif1$")
		mf = Makefile(topdir,selector,None,"Makefile1","#prologue","#epilog")
		mf.close()
		self.assertFalse(os.path.isfile(topdir+"/Makefile1"))

	def testMakefileCreate(self):
		selector = MakefileSelector("testinterface1","testif1$")
		mf = Makefile(topdir,selector,None,"Makefile2","#prologue\n\n","#epilog\n\n")
		#(self, specname, configname, ifname, flmpath, parameters, guard = None):
		mf.addCall("testspec", "testconfig","testif1",False,"/flmhome/flm.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mf.close()
		self.assertFalse(os.path.isfile(topdir+"/Makefile2"))

	def testMakefileCreateChild(self):
		selector = MakefileSelector("testinterface1","testif1$")
		mf = Makefile(topdir,selector,None,"Makefile3","#prologue\n\n","#epilog\n\n")
		#(self, specname, configname, ifname, flmpath, parameters, guard = None):
		mf.addCall("testspec2", "testconfig","testif1",False,"/flmhome/flm.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		childmf = mf.createChild("child1")
		childmf.addCall("test child spec", "testconfig","testif1",False,"/flmhome/flm.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		childmf.addCall("test child spec", "testconfig","testif1",False,"/flmhome/flm.flm",[("TESTPARAM1","call2value1"),("TESTPARAM2","call2value2"),("TESTPARAM3","call2value3")])
		childmf.close()
		mf.close()
		self.assertTrue(os.path.isfile(topdir+"/Makefile3.testinterface1"))
		self.assertTrue(os.path.isfile(topdir+"/child1/Makefile3.testinterface1"))



class TestMakefileSet(unittest.TestCase):
	def setUp(self):
		print "Setup TestMakefileSet"
		unlinkall( [ topdir + "Makefile4",
		  topdir + "Makefile4.bitmap",
		  topdir + "Makefile4.default",
		  topdir + "Makefile4.export",
		  topdir + "Makefile4.resource",
		  topdir + "Makefile5",
		  topdir + "Makefile5.bitmap",
		  topdir + "Makefile5.default",
		  topdir + "Makefile5.export",
		  topdir + "Makefile5.resource",
		  topdir + "makefilechildren/Makefile6.bitmap",
		  topdir + "makefilechildren/Makefile6.resource",
		  topdir + "makefilechildren/Makefile6.default",
		  topdir + "makefilechildren/Makefile6.export",
		  topdir + "makefilechildren/child1/Makefile6.bitmap",
		  topdir + "makefilechildren/child1/Makefile6.resource",
		  topdir + "makefilechildren/child1/Makefile6.default",
		  topdir + "makefilechildren/child1/Makefile6.export",
		  topdir + "makefilechildren/child1/Makefile6",
		  topdir + "makefilechildren/Makefile6" ] )
		

	def testMakefileSetCreateNull(self):
		mfset = MakefileSet(directory=topdir, filenamebase="Makefile4", 
					prologue="# prologue\n\n", epilogue="# epilogue\n\n")
		mfset.close()
		self.assertTrue(checkall( [ topdir + "Makefile4",
			topdir + "Makefile4.bitmap",
			topdir + "Makefile4.default",
			topdir + "Makefile4.export",
			topdir + "Makefile4.resource" ]))

	def testMakefileSetCreate(self):
		mfset = MakefileSet(directory=topdir, filenamebase="Makefile5", 
					prologue="# prologue\n\n", epilogue="# epilogue\n\n")

		

		mfset.addCall("testspec3", "testconfig","export",False,"/flmhome/export.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mfset.addCall("testspec4", "testconfig","resource",False,"/flmhome/resource.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mfset.addCall("testspec5", "testconfig","bitmap",False,"/flmhome/bitmap.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mfset.addCall("testspec6", "testconfig","e32abiv2",False,"/flmhome/e32abiv2exe.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mfset.close()
		self.assertTrue(checkall( [ 
		  topdir + "Makefile5",
		  topdir + "Makefile5.bitmap",
		  topdir + "Makefile5.default",
		  topdir + "Makefile5.export",
		  topdir + "Makefile5.resource" ] ))

	def testMakefileSetChildren(self):
		mfset = MakefileSet(directory=topdir+"/makefilechildren", filenamebase="Makefile6", prologue="# prologue\n\n", epilogue="# epilogue\n\n")
		mfset.addCall("testspec3", "testconfig","export",False,"/flmhome/export.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mfset.addCall("testspec4", "testconfig","resource",False,"/flmhome/resource.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mfset.addCall("testspec5", "testconfig","bitmap",False,"/flmhome/bitmap.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mfset.addCall("testspec6", "testconfig","e32abiv2",False,"/flmhome/e32abiv2exe.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		mfset.addCall("testspec7", "testconfig","e32abiv2",False,"/flmhome/e32abiv2exe.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		childmfset = mfset.createChild("child1")
		childmfset.addCall("testspec7", "testconfig","e32abiv2",False,"/flmhome/e32abiv2exe.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		childmfset.addCall("testspec8", "testconfig","resource",False,"/flmhome/resource.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		childmfset.addCall("testspec9", "testconfig","bitmap",False,"/flmhome/bitmap.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		childmfset.addCall("testspec10", "testconfig","resource",False,"/flmhome/resource.flm",[("TESTPARAM1","testvalue1"),("TESTPARAM2","value2"),("TESTPARAM3","value3")])
		childmfset.close()
		mfset.close()

		self.assertTrue(checkall( [ topdir + "makefilechildren/Makefile6.bitmap",
		  topdir + "makefilechildren/Makefile6.resource",
		  topdir + "makefilechildren/Makefile6.default",
		  topdir + "makefilechildren/Makefile6.export",
		  topdir + "makefilechildren/child1/Makefile6.bitmap",
		  topdir + "makefilechildren/child1/Makefile6.resource",
		  topdir + "makefilechildren/child1/Makefile6.default",
		  topdir + "makefilechildren/child1/Makefile6.export",
		  topdir + "makefilechildren/child1/Makefile6",
		  topdir + "makefilechildren/Makefile6" ] ))

# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "raptor_makefile_unit"

	tests = unittest.makeSuite(TestMakefile)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
