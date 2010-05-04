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
# raptor_api_unit module

import generic_path
import raptor
import raptor_api
import unittest

class TestRaptorApi(unittest.TestCase):
			
	def testContext(self):
		api = raptor_api.Context()
		
	def testContextInitialiser(self):
		r = raptor.Raptor()
		api = raptor_api.Context(r)
		
	def testAliases(self):
		r = raptor.Raptor()
		r.cache.Load( generic_path.Join(r.home, "test", "config", "api.xml") )

		api = raptor_api.Context(r)
	
		aliases = api.getaliases() # type == ""
		self.failUnlessEqual(len(aliases), 4)
		self.failUnlessEqual(set(["alias_A","alias_B","s1","s2"]),
							 set(a.name for a in aliases))
		
		aliases = api.getaliases(raptor_api.ALL) # ignore type
		self.failUnlessEqual(len(aliases), 6)
		
		aliases = api.getaliases("X") # type == "X"
		self.failUnlessEqual(len(aliases), 1)
		self.failUnlessEqual(aliases[0].name, "alias_D")
		self.failUnlessEqual(aliases[0].meaning, "a.b.c.d")
	
	def testConfig(self):
		r = raptor.Raptor()
		r.cache.Load( generic_path.Join(r.home, "test", "config", "api.xml") )

		api = raptor_api.Context(r)
		
		if r.filesystem == "unix":
			path = "/home/raptor/foo/bar"
		else:
			path = "C:/home/raptor/foo/bar"
			
		config = api.getconfig("buildme")
		self.failUnlessEqual(config.fullname, "buildme")
		self.failUnlessEqual(config.outputpath, path)
		
		config = api.getconfig("buildme.foo")
		self.failUnlessEqual(config.fullname, "buildme.foo")
		self.failUnlessEqual(config.outputpath, path)
		
		config = api.getconfig("s1")
		self.failUnlessEqual(config.fullname, "buildme.foo")
		self.failUnlessEqual(config.outputpath, path)
		
		config = api.getconfig("s2.product_A")
		self.failUnlessEqual(config.fullname, "buildme.foo.bar.product_A")
		self.failUnlessEqual(config.outputpath, path)
		
	def testProducts(self):
		r = raptor.Raptor()
		r.cache.Load( generic_path.Join(r.home, "test", "config", "api.xml") )

		api = raptor_api.Context(r)
		
		products = api.getproducts() # type == "product"
		self.failUnlessEqual(len(products), 2)
		self.failUnlessEqual(set(["product_A","product_C"]),
							 set(p.name for p in products))
		
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.name = "raptor_api_unit"

	tests = unittest.makeSuite(TestRaptorApi)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
