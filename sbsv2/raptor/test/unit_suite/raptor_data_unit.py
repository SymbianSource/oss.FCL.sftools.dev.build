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
# raptor_data_unit module
# This module tests the classes that make up the Raptor Data Model.
#

import generic_path
import os
import raptor
import raptor_cache
import raptor_data
import unittest

class TestRaptorData(unittest.TestCase):

	def setUp(self):
		self.envStack = {}
		
		
	def SetEnv(self, name, value):
		# set environment variable and remember the old value
		
		try:
			old = os.environ[name]
			self.envStack[name] = old
			os.environ[name] = value
		except KeyError:
			self.envStack[name] = None    # was not defined
		
			
	def RestoreEnv(self, name):
		# put environment back to its state before SetEnv
		saved = self.envStack[name]
		
		if saved == None:
			del os.environ[name]    # was not defined
		else:
			os.environ[name] = saved
			
			
	def testSimpleSpecification(self):
		spec = raptor_data.Specification("myProject")

		spec.SetInterface("Symbian.EXE")
		
		var = raptor_data.Variant("X")

		var.AddOperation(raptor_data.Set("SOURCES", "a.cpp"))
		var.AddOperation(raptor_data.Append("LIBS", "all.dll"))
		var.AddOperation(raptor_data.Append("INC", "/C/include"))
		var.AddOperation(raptor_data.Prepend("INC", "/B/include"))

		spec.AddVariant(var)
		spec.AddVariant("AlwaysBuildAsArm")

		self.failUnless(spec)
		self.failUnless(spec.Valid())
		self.failUnless(var.Valid())
		self.assertEqual(spec.name, "myProject")


	def testSimpleFilter(self):
		filter = raptor_data.Filter("filtered")
		filter.SetConfigCondition("ARMV5")
		
		filter.SetInterface(raptor_data.Interface("True.EXE"))
		filter.Else.SetInterface(raptor_data.Interface("False.EXE"))
		
		filter.AddVariant(raptor_data.Variant("True_var"))
		filter.Else.AddVariant(raptor_data.Variant("False_var"))
		
		filter.AddChildSpecification(raptor_data.Specification("TrueSpec"))
		filter.Else.AddChildSpecification(raptor_data.Specification("FalseSpec"))
		
		filter.Configure( raptor_data.BuildUnit("ARMV5",[]), cache=None )
		# check a positive test
		iface = filter.GetInterface(cache=None)
		self.assertEqual(iface.name, "True.EXE")
		vars = filter.GetVariants(cache = None)
		self.assertEqual(vars[0].name, "True_var")
		kids = filter.GetChildSpecs()
		self.assertEqual(kids[0].name, "TrueSpec")
		
		filter.Configure( raptor_data.BuildUnit("NOT_ARMV5",[]) , cache = None)
		# check a negative test
		iface = filter.GetInterface(cache = None)
		self.assertEqual(iface.name, "False.EXE")
		vars = filter.GetVariants(cache = None)
		self.assertEqual(vars[0].name, "False_var")
		kids = filter.GetChildSpecs()
		self.assertEqual(kids[0].name, "FalseSpec")
		

	def testSimpleVariant(self):
		var = raptor_data.Variant()
		self.failUnless(var)
		self.failIf( var.Valid() )

		var.SetProperty("name", "ABC")
		var.SetProperty("extends", "DEF")
		var.SetProperty("host", "GHI")

		self.assertEqual(var.name, "ABC")
		self.assertEqual(var.extends, "DEF")
		self.assertEqual(var.host, None)

		var.SetProperty("host", "win32")
		self.assertEqual(var.host, "win32")

		self.failUnless( var.Valid() )

		var.AddOperation( raptor_data.Set("CC", "armcc") )
		var.AddOperation( raptor_data.Set("LN", "armlink") )

		self.failUnless( var.Valid() )

		var.SetProperty("extends", "")
		ops = var.GetAllOperationsRecursively(None)

		self.assertEqual( len(ops), 1 )
		self.assertEqual( len(ops[0]), 2 )

	def testExtendedVariant(self):
		r = raptor.Raptor()

		varA = raptor_data.Variant("A")
		varA.SetProperty("extends", None)
		varA.AddOperation( raptor_data.Set("V1", "1A") )
		varA.AddOperation( raptor_data.Set("V2", "2A") )

		varB = raptor_data.Variant("B")
		varB.SetProperty("extends", "A")
		varB.AddOperation( raptor_data.Set("V2", "2B") )
		varB.AddOperation( raptor_data.Set("V3", "3B") )

		varC = raptor_data.Variant("C")
		varC.SetProperty("extends", "B")
		varC.AddOperation( raptor_data.Set("V3", "3C") )
		varC.AddOperation( raptor_data.Set("V4", "4C") )

		self.failUnless( varA.Valid() )
		self.failUnless( varB.Valid() )
		self.failUnless( varC.Valid() )

		r.cache.AddVariant(varA)
		r.cache.AddVariant(varB)
		r.cache.AddVariant(varC)

		e = r.GetEvaluator(None, varA.GenerateBuildUnits(r.cache)[0] )
		self.assertEqual( e.Get("V1"), "1A" )
		self.assertEqual( e.Get("V2"), "2A" )

		e = r.GetEvaluator(None, varB.GenerateBuildUnits(r.cache)[0] )
		self.assertEqual( e.Get("V1"), "1A" )
		self.assertEqual( e.Get("V2"), "2B" )
		self.assertEqual( e.Get("V3"), "3B" )

		e = r.GetEvaluator(None, varC.GenerateBuildUnits(r.cache)[0] )
		self.assertEqual( e.Get("V1"), "1A" )
		self.assertEqual( e.Get("V2"), "2B" )
		self.assertEqual( e.Get("V3"), "3C" )
		self.assertEqual( e.Get("V4"), "4C" )

	def testReferencedVariant(self):
		r = raptor.Raptor()

		varA = raptor_data.Variant("A")
		varA.SetProperty("extends", None)
		varA.AddOperation( raptor_data.Set("V1", "1A") )
		varA.AddOperation( raptor_data.Set("V2", "2A") )

		# B extends A, and has a reference to C.
		varB = raptor_data.Variant("B")
		varB.SetProperty("extends", "A")
		varB.AddOperation( raptor_data.Set("V2", "2B") )
		varB.AddOperation( raptor_data.Set("V3", "3B") )
		varB.AddChild( raptor_data.VariantRef("C") )

		varC = raptor_data.Variant("C")
		varC.SetProperty("extends", None)
		varC.AddOperation( raptor_data.Set("V3", "3C") )
		varC.AddOperation( raptor_data.Set("V4", "4C") )

		self.failUnless( varA.Valid() )
		self.failUnless( varB.Valid() )
		self.failUnless( varC.Valid() )

		r.cache.AddVariant(varA)
		r.cache.AddVariant(varB)
		r.cache.AddVariant(varC)

		e = r.GetEvaluator(None, varA.GenerateBuildUnits(r.cache)[0] )
		self.assertEqual( e.Get("V1"), "1A" )
		self.assertEqual( e.Get("V2"), "2A" )

		e = r.GetEvaluator(None, varC.GenerateBuildUnits(r.cache)[0] )
		self.assertEqual( e.Get("V3"), "3C" )
		self.assertEqual( e.Get("V4"), "4C" )

		e = r.GetEvaluator(None, varB.GenerateBuildUnits(r.cache)[0] )
		self.assertEqual( e.Get("V1"), "1A" )
		self.assertEqual( e.Get("V2"), "2B" )
		self.assertEqual( e.Get("V3"), "3B" )
		self.assertEqual( e.Get("V4"), "4C" )

	def testAlias(self):
		r = raptor.Raptor()

		varA = raptor_data.Variant("A")
		varA.AddOperation( raptor_data.Set("V1", "1A") )
		varA.AddOperation( raptor_data.Set("V2", "2A") )
		r.cache.AddVariant(varA)

		varB = raptor_data.Variant("B")
		varB.AddOperation( raptor_data.Set("V2", "2B") )
		varB.AddOperation( raptor_data.Set("V3", "3B") )
		r.cache.AddVariant(varB)

		varC = raptor_data.Variant("C")
		varC.AddOperation( raptor_data.Set("V3", "3C") )
		varC.AddOperation( raptor_data.Set("V4", "4C") )
		r.cache.AddVariant(varC)

		# <alias name="an_alias" meaning="A.B.C"/>
		alias = raptor_data.Alias("an_alias")
		alias.SetProperty("meaning", "A.B.C")
		r.cache.AddAlias(alias)

		self.failUnless( alias.Valid() )

		e = r.GetEvaluator(None, alias.GenerateBuildUnits(r.cache)[0] )
		self.assertEqual( e.Get("V1"), "1A" )
		self.assertEqual( e.Get("V2"), "2B" )
		self.assertEqual( e.Get("V3"), "3C" )
		self.assertEqual( e.Get("V4"), "4C" )

	def testGroup1(self):
		r = raptor.Raptor()

		varA = raptor_data.Variant("A")
		varA.AddOperation( raptor_data.Set("V1", "1A") )
		varA.AddOperation( raptor_data.Set("V2", "2A") )
		r.cache.AddVariant(varA)

		varB = raptor_data.Variant("B")
		varB.AddOperation( raptor_data.Set("V2", "2B") )
		varB.AddOperation( raptor_data.Set("V3", "3B") )
		r.cache.AddVariant(varB)

		varC = raptor_data.Variant("C")
		varC.AddOperation( raptor_data.Set("V3", "3C") )
		varC.AddOperation( raptor_data.Set("V4", "4C") )
		r.cache.AddVariant(varC)

		alias = raptor_data.Alias("alias")
		alias.SetProperty("meaning", "B.C")
		r.cache.AddAlias(alias)

		# This group has two buildable units: "A" and "alias" = "B.C".
		# <group name="group1">
		#	<varRef ref="A"/>
		#   <aliasRef ref="alias">
		# <group>
		group1 = raptor_data.Group("group1")
		group1.AddChild( raptor_data.VariantRef("A") )
		group1.AddChild( raptor_data.AliasRef("alias") )
		r.cache.AddGroup(group1)

		vRef = raptor_data.VariantRef("C")
		vRef.SetProperty("mod", "B")

		# This group has three buildable units: "C.B", "A" and "alias" = "B.C".
		# <group name="group2">
		#	<varRef ref="C" mod="B"/>
		#   <groupRef ref="group1"/>
		# <group>
		group2 = raptor_data.Group("group2")
		group2.AddChild(vRef)
		group2.AddChild( raptor_data.GroupRef("group1") )
		r.cache.AddGroup(group2)

		self.failUnless( group1.Valid() )
		self.failUnless( group2.Valid() )

		buildUnits = group1.GenerateBuildUnits(r.cache)
		self.assertEqual( len(buildUnits), 2 )
		self.assertEqual( buildUnits[0].name, "A" )
		self.assertEqual( buildUnits[1].name, "alias" )
		self.assertEqual( buildUnits[1].variants[0].name, "B" )
		self.assertEqual( buildUnits[1].variants[1].name, "C" )

		buildUnits = group2.GenerateBuildUnits(r.cache)
		self.assertEqual( len(buildUnits), 3 )
		self.assertEqual( buildUnits[0].name, "C.B" )
		self.assertEqual( buildUnits[1].name, "A" )
		self.assertEqual( buildUnits[2].name, "alias" )

		self.assertEqual( len(buildUnits[0].variants), 2 )
		self.assertEqual( len(buildUnits[1].variants), 1 )
		self.assertEqual( len(buildUnits[2].variants), 2 )

	def testGroup2(self):
		r = raptor.Raptor()

		r.cache.Load( generic_path.Join(r.home, "test", "config", "arm.xml") )

		buildUnits = r.cache.FindNamedGroup("G2").GenerateBuildUnits(r.cache)

		self.assertEqual( len(buildUnits), 8 )

		self.assertEqual(buildUnits[0].name, "ARMV5_UREL.MOD1")
		self.assertEqual(buildUnits[1].name, "ARMV5_UDEB.MOD1.MOD2")
		self.assertEqual(buildUnits[2].name, "ALIAS_1")
		self.assertEqual(buildUnits[3].name, "ALIAS_2.MOD1.MOD2.MOD1")
		self.assertEqual(buildUnits[4].name, "ARMV5_UREL.MOD2")
		self.assertEqual(buildUnits[5].name, "ARMV5_UDEB.MOD2")
		self.assertEqual(buildUnits[6].name, "MOD1")
		self.assertEqual(buildUnits[7].name, "MOD2")

	def testRefs(self):
		i1 = raptor_data.InterfaceRef()
		self.failIf(i1.Valid())

		i2 = raptor_data.InterfaceRef("")
		self.failIf(i2.Valid())

		i3 = raptor_data.InterfaceRef("ABC_abc.123")
		self.failUnless(i3.Valid())
		self.assertEqual(i3.ref, "ABC_abc.123")


	def testEvaluator(self):
		self.SetEnv("EPOCROOT", "/C")
		aRaptor = raptor.Raptor()
		cache = aRaptor.cache
		aRaptor.debugOutput = True
		cache.Load(generic_path.Join(aRaptor.home, "test", "config", "arm.xml"))
		
		var = cache.FindNamedVariant("ARMV5_UREL")
		eval = aRaptor.GetEvaluator( None, var.GenerateBuildUnits(aRaptor.cache)[0])
		self.RestoreEnv("EPOCROOT")
		
		# test the Get method
		varcfg = eval.Get("VARIANT_CFG")
		self.assertEqual(varcfg, "/C/variant/variant.cfg")
		
		# test the Resolve wrt EPOCROOT
		varcfg = eval.Resolve("VARIANT_CFG")
		self.assertEqual(varcfg, "/C/variant/variant.cfg")
	
	def testMissingEnvironment(self):
		# ask for an environment variable that is not set
		# and has no default value.
		var = raptor_data.Variant("my.var")
		var.AddOperation(raptor_data.Env("RAPTOR_SAYS_NO"))

		aRaptor = raptor.Raptor()
	
		try:	
			eval = aRaptor.GetEvaluator(None, var.GenerateBuildUnits(aRaptor.cache)[0] )
			badval = eval.Get("RAPTOR_SAYS_NO")
		except raptor_data.UninitialisedVariableException, e:
			return

		self.assertTrue(False)

	def checkForParam(self, params, name, default):
		for p in params:
			if p.name == name and (default == None or p.default == default):
				return True
		return False
	
	def testInterface(self):
		aRaptor = raptor.Raptor()
		cache = aRaptor.cache
		cache.Load(generic_path.Join(aRaptor.home, "test", "config", "interface.xml"))
		
		base = cache.FindNamedInterface("Base.XYZ")
		p = base.GetParams(cache)
		self.failUnless(self.checkForParam(p, "A", None))
		self.failUnless(self.checkForParam(p, "B", "baseB"))
		self.failUnless(self.checkForParam(p, "C", "baseC"))
		
		extended = cache.FindNamedInterface("Extended.XYZ")
		p = extended.GetParams(cache)
		self.failUnless(self.checkForParam(p, "A", None))
		self.failUnless(self.checkForParam(p, "B", "baseB"))
		self.failUnless(self.checkForParam(p, "C", "extC"))
		self.failUnless(self.checkForParam(p, "D", None))
		f = extended.GetFLMIncludePath(cache=cache)
		self.assertEqual(f.File(), "ext.flm")
		
		extended = cache.FindNamedInterface("Extended2.XYZ")
		p = extended.GetParams(cache)
		self.failUnless(self.checkForParam(p, "A", None))
		self.failUnless(self.checkForParam(p, "B", "baseB"))
		self.failUnless(self.checkForParam(p, "C", "extC"))
		self.failUnless(self.checkForParam(p, "D", None))
		f = extended.GetFLMIncludePath(cache)
		self.assertEqual(f.File(), "base.flm")
	
	
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "raptor_data_unit"

	tests = unittest.makeSuite(TestRaptorData)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
