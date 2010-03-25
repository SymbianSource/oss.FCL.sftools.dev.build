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

import generic_path
import unittest
import os
import sys
import re

class TestGenericPaths(unittest.TestCase):
	
	def setUp(self):
		self.cwd = os.getcwd().replace("\\", "/")
	
	def isWin32(self):
		return sys.platform.lower().startswith("win")
	
	
	def testClassCommon(self):
		
		p1 = generic_path.Path("a", "b")
		
		p2 = p1.Append("c")
		self.assertEqual(str(p2), "a/b/c")
		
		p3 = p1.Append("c", "d")
		self.assertEqual(str(p3), "a/b/c/d")
		
		p4 = p1.Prepend("z")
		self.assertEqual(str(p4), "z/a/b")
		
		p5 = p1.Prepend("y", "z")
		self.assertEqual(str(p5), "y/z/a/b")
		
		self.assertEqual(str(p5.Dir()), "y/z/a")
		self.assertEqual(p5.File(), "b")
		
		p6 = generic_path.Join("test")
		self.assertEqual(str(p6.Dir()), "")
		self.assertEqual(p6.File(), "test")
	
	
	def testClassWin32(self):
		if not self.isWin32():
			return
		
		local1 = generic_path.Path('some\\folder\\another\\')
		local2 = generic_path.Join(local1, "test", "tmp")
		
		self.assertEqual(str(local2),"some/folder/another/test/tmp")
		
		# Absolute
		
		local1 = generic_path.Path('some\\folder')
		self.failIf(local1.isAbsolute())
		
		abs1 = local1.Absolute()
		self.assertEqual(str(abs1).lower(), (self.cwd + "/some/folder").lower())
		
		local2 = generic_path.Path('C:\\some\\folder')
		self.failUnless(local2.isAbsolute())
		
		abs2 = local2.Absolute()
		self.assertEqual(str(abs2), "C:/some/folder")

		local3 = generic_path.Path('\\somerandomfolder')
		self.failUnless(re.match('^[A-Za-z]:/somerandomfolder$',str(local3)))

		local4 = generic_path.Path('\\my\\folder\\')
		self.failUnless(re.match('^[A-Za-z]:/my/folder$',str(local4)))

		local5 = generic_path.Path('\\')
		self.failUnless(re.match('^[A-Za-z]:$',str(local5)))
		
		local6 = generic_path.Path("C:")
		self.failUnless(local6.isAbsolute())
		self.failUnless(local6.isDir())
		self.failUnless(local6.Exists())
		
		local7 = local6.Absolute()
		self.assertEqual(str(local7), "C:")
		
		local8 = generic_path.Path("C:/")
		self.failUnless(local8.isAbsolute())
		self.failUnless(local8.isDir())
		self.failUnless(local8.Exists())
		
		local9 = local8.Absolute()
		self.assertEqual(str(local9), "C:")
		                              	
		# Drives
		
		driveD = generic_path.Path("D:\\", "folder")
		self.assertEqual(str(driveD), "D:/folder")
		
		driveA = generic_path.Path("a:\\")
		self.assertEqual(str(driveA), "a:")
		self.assertEqual(str(driveA.Dir()), "a:")
		
		driveZ = generic_path.Path("Z:\\test")
		self.assertEqual(str(driveZ), "Z:/test")
		
		joinC = generic_path.Join("C:\\", "something")
		self.assertEqual(str(joinC), "C:/something")
		
		joinM = generic_path.Join("M:", "something")
		self.assertEqual(str(joinM), "M:/something")
		
		# Path
		
		path2 = generic_path.Path("m:/sys/thing/")
		self.assertEqual(str(path2), "m:/sys/thing")
		
		path3 = generic_path.Path("m:\\sys\\thing\\")
		self.assertEqual(str(path3), "m:/sys/thing")
		
		path4 = generic_path.Path("m:\\")
		self.assertEqual(str(path4), "m:")
		
		path5 = generic_path.Path("\\sys\\thing\\")
		self.failUnless(re.match('^[A-Za-z]:/sys/thing$', str(path5)))
		
		path6 = generic_path.Path("m:/")
		self.assertEqual(str(path6), "m:")
		
		# SpaceSafePath
		
		epocroot = os.path.abspath(os.environ.get('EPOCROOT')).replace('\\','/').rstrip('/')
		pathwithspaces = epocroot+"/epoc32/build/Program Files/Some tool installed with spaces/no_spaces/s p c/no_more_spaces"
		path7 = generic_path.Path(pathwithspaces)

		# SpaceSafe paths on Windows are 8.3 format, and these can only be deduced if they actually exist.	
		os.makedirs(pathwithspaces)
		spacesafe = path7.GetSpaceSafePath()
		self.assertTrue(spacesafe.endswith("PROGRA~1/SOMETO~1/NO_SPA~1/SPC~1/NO_MOR~1"))
		
		os.removedirs(pathwithspaces)
		spacesafe = path7.GetSpaceSafePath()		
		self.assertEqual(spacesafe, None)

		
	def testClassLinux(self):
		if self.isWin32():
			return
		
		local1 = generic_path.Path('some/folder/another/')
		local2 = generic_path.Join(local1, "test", "tmp")
		
		self.assertEqual(str(local2),"some/folder/another/test/tmp")
		
		msys1 = generic_path.Path('some/folder/another/')
		msys2 = generic_path.Join(msys1, "test", "tmp")
		
		self.assertEqual(str(msys2),"some/folder/another/test/tmp")
		
		# Absolute
		
		local1 = generic_path.Path('some/folder')
		self.failIf(local1.isAbsolute())
		
		abs1 = local1.Absolute()
		self.assertEqual(str(abs1), self.cwd + "/some/folder")
		
		local2 = generic_path.Path('/some/folder')
		self.failUnless(local2.isAbsolute())
		
		abs2 = local2.Absolute()
		self.assertEqual(str(abs2), "/some/folder")
		
		root = generic_path.Path("/")
		self.assertEqual(str(root), "/")
		
		# Path
		
		path = generic_path.Path("some/thing/")
		self.assertEqual(str(path), "some/thing")
		
		# SpaceSafePath
		
		# This doesn't mean much on non-Windows platforms, but we confirm nothing breaks if it is used
		pathwithspaces = "/Program Files/Some tool installed with spaces/no_spaces/s p c/no_more_spaces"
		path2 = generic_path.Path(pathwithspaces)
	
		spacesafe = path2.GetSpaceSafePath()		
		self.assertEqual(spacesafe, None)
		
 
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "generic_path_unit"

	tests = unittest.makeSuite(TestGenericPaths)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
