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
# Unit tests for the raptor module

import raptor
import raptor_version
import re
import unittest
import generic_path
import tempfile
import os

class TestRaptor(unittest.TestCase):

	def testConstructor(self):
		r = raptor.Raptor()
		self.failUnless(r)


	def testHome(self):
		r = raptor.Raptor()
		self.failUnless(r.home)
		r = raptor.Raptor("dirname")
		self.failUnless(r.errorCode == 1) # picked up that dirname doesn't exist
		

	def testVersion(self):
		self.failUnless(re.match("^\d+\.\d+\.", raptor_version.Version()))


	def testCLISupport(self):
		r = raptor.Raptor()
		r.RunQuietly(True)
		r.AddConfigName("tom")
		r.AddConfigName("dick")
		r.AddConfigName("harry")
		r.SetEnv("ROOT", "/a/b/c")
		r.SetEnv("TREE", "beech")
		r.SetJobs(4)
		r.AddProject("foo.mmp")
		r.AddProject("bar.mmp")
		r.SetSysDefFile("SysDef.xml")
		r.SetSysDefBase("C:\\mysysdef")
		r.AddBuildInfoFile("build.info")
		r.SetTopMakefile("E:\\epoc32\\build\\Makefile")

	def setUp(self):
		self.r = raptor.Raptor()
		self.r.out = OutputMock()
		
		self.cwd = generic_path.CurrentDir()
		self.isFileReturningFalse = lambda: False
		self.isFileReturningTrue = lambda: True
		
		self.sysDef = self.cwd.Append(self.r.systemDefinition)
		self.bldInf = self.cwd.Append(self.r.buildInformation)

	def testCreateWarningForNonexistingBldInfAndSystemDefinitionFile(self): 
		"""Test if sbs creates warning if executed without specified 
		component to build i.e. default bld.inf (bld.inf in current 
		directory) or system definition file.

		Uses an empty temporary directory for this."""

		d = tempfile.mkdtemp(prefix='raptor_test') 
		cdir = os.getcwd()
		os.chdir(d) 
		self.r.GetComponentGroupsFromCLI()
		os.chdir(cdir) # go back
		os.rmdir(d)
		
		self.assertTrue(self.r.out.warningWritten())

	def testCreateWarningForExistingBldInf(self):
		d = tempfile.mkdtemp(prefix='raptor_test') 
		cdir = os.getcwd()
		os.chdir(d)
		f = open("bld.inf","w")
		f.close()
		self.r.GetComponentGroupsFromCLI()
		os.unlink("bld.inf")
		os.chdir(cdir) # go back
		os.rmdir(d)

		self.assertFalse(self.r.out.warningWritten())

	def testCreateWarningForExistingSystemDefinitionFile(self): 
		d = tempfile.mkdtemp(prefix='raptor_test') 
		cdir = os.getcwd()
		os.chdir(d)
		f = open("System_Definition.xml","w")
		f.close()
		self.r.GetComponentGroupsFromCLI()
		os.unlink("System_Definition.xml")
		os.chdir(cdir) # go back
		os.rmdir(d)

		self.assertFalse(self.r.out.warningWritten())
	
	# Test Info, Warn & Error functions can handle attributes
	def testInfoAttributes(self):
		self.r.Info("hello %s", "world", planet="earth")
		expected = "<info planet='earth'>hello world</info>\n"
		self.assertEquals(self.r.out.actual, expected)
		
	def testWarnAttributes(self):
		self.r.Warn("look out", where="behind you")
		expected = "<warning where='behind you'>look out</warning>\n"
		self.assertEquals(self.r.out.actual, expected)
		
	def testErrorAttributes(self):
		self.r.Error("messed up %s and %s", "all", "sundry", bldinf="bld.inf")
		expected = "<error bldinf='bld.inf'>messed up all and sundry</error>\n"
		self.assertEquals(self.r.out.actual, expected)	
		
	# Test Info, Warn & Error functions to ensure XML control chars are escaped
	def testInfoXMLEscaped(self):
		self.r.Info("h&l>o<&amp;")
		expected = "<info>h&amp;l&gt;o&lt;&amp;amp;</info>\n"
		self.assertEquals(self.r.out.actual, expected)
		
	def testWarnXMLEscaped(self):
		self.r.Warn("h&l>o<&amp;")
		expected = "<warning>h&amp;l&gt;o&lt;&amp;amp;</warning>\n"
		self.assertEquals(self.r.out.actual, expected)
		
	def testErrorXMLEscaped(self):
		self.r.Error("h&l>o<&amp;")
		expected = "<error>h&amp;l&gt;o&lt;&amp;amp;</error>\n"
		self.assertEquals(self.r.out.actual, expected)
	
		
# Mock output class preserving output for checking
# Can also check if any warning has been written
class OutputMock(object):
	actual = ""
	
	def write(self, text):
		self.actual = text
		
	def warningWritten(self):
		regExp = re.compile(".*warning.*")
		if regExp.match(self.actual):
			return True
		return False
			
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "raptor_unit"

	tests = unittest.makeSuite(TestRaptor)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
