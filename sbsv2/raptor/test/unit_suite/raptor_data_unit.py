#
# Copyright (c) 2006-2010 Nokia Corporation and/or its subsidiary(-ies).
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
import sys
import unittest

class TestRaptorData(unittest.TestCase):

	def setUp(self):
		self.envStack = {}
		
		
	def SetEnv(self, name, value):
		# set environment variable and remember the old value (if there is one)		
		if os.environ.has_key(name):
			self.envStack[name] = os.environ[name]
		os.environ[name] = value
		
	def isWin(self):
		return 'win' in raptor.hostplatform
			
	def RestoreEnv(self, name):
		# put environment back to its state before SetEnv
		if self.envStack.has_key(name):
			os.environ[name] = self.envStack[name]
		else:
			del os.environ[name]    # was not defined
			
			
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
		
	def testProblematicEnvironment(self):
		aRaptor = raptor.Raptor()		
		
		# 1: ask for environment variable values that will break makefile parsing due to
		# backslashes forming line continuation characters
		self.SetEnv("ENVVAR_BSLASH_END1", "C:\\test1a\\;C:\\test1b\\")
		self.SetEnv("ENVVAR_BSLASH_END2", "C:\\test2a\\;C:\\test2b\\\\")
		self.SetEnv("ENVVAR_BSLASH_END3", "C:\\test3a\\;C:\\test3b\\\\\\")
		var = raptor_data.Variant("my.var")
		var.AddOperation(raptor_data.Env("ENVVAR_BSLASH_END1"))
		var.AddOperation(raptor_data.Env("ENVVAR_BSLASH_END2"))
		var.AddOperation(raptor_data.Env("ENVVAR_BSLASH_END3"))

		eval = aRaptor.GetEvaluator(None, var.GenerateBuildUnits(aRaptor.cache)[0])
		self.RestoreEnv("ENVVAR_BSLASH_END1")
		self.RestoreEnv("ENVVAR_BSLASH_END2")
		self.RestoreEnv("ENVVAR_BSLASH_END3")
		
		value = eval.Get("ENVVAR_BSLASH_END1")
		self.assertEqual(value, "C:\\test1a\\;C:\\test1b\\\\")
		
		value = eval.Get("ENVVAR_BSLASH_END2")
		self.assertEqual(value, "C:\\test2a\\;C:\\test2b\\\\")
		
		value = eval.Get("ENVVAR_BSLASH_END3")
		self.assertEqual(value, "C:\\test3a\\;C:\\test3b\\\\\\\\")
		
		# 2: check 'tool' and 'toolchain' type environment variable values for correct behaviour when paths contain spaces
		# this is different depending on host OS platform and whether or not the paths/tools actually exist
		epocroot = os.path.abspath(os.environ.get('EPOCROOT')).replace('\\','/').rstrip('/')
		pathwithspaces = epocroot+"/epoc32/build/Program Files/Some tool installed with spaces/no_spaces/s p c/no_more_spaces"
		toolwithspaces = pathwithspaces+"/testtool.exe"	
		self.SetEnv("ENVVAR_TOOL_WITH_SPACES", toolwithspaces)
		self.SetEnv("ENVVAR_TOOLCHAINPATH_WITH_SPACES", pathwithspaces)
		toolVar = raptor_data.Variant("tool.var")
		toolchainpathVar = raptor_data.Variant("toolchainpath.var")
		toolVar.AddOperation(raptor_data.Env("ENVVAR_TOOL_WITH_SPACES", "", "tool"))
		toolchainpathVar.AddOperation(raptor_data.Env("ENVVAR_TOOLCHAINPATH_WITH_SPACES", "", "toolchainpath"))
		invalidValueException = "the environment variable %s is incorrect - it is a '%s' type but contains spaces that cannot be neutralised:"
		
		# 2a: paths/tools exist - on Windows we expect 8.3 paths post-evaluation, on all other platforms error exceptions
		os.makedirs(pathwithspaces)
		testtool = open(toolwithspaces,'wb')
		testtool.close()
		
		exceptionText = ""
		value = ""
		try:
			eval = aRaptor.GetEvaluator(None, toolVar.GenerateBuildUnits(aRaptor.cache)[0])
			value = eval.Get("ENVVAR_TOOL_WITH_SPACES")
		except Exception, e:
			exceptionText = str(e)
			
		if self.isWin():
			self.assertTrue(value)
			self.assertFalse(' ' in value)
		else:
			self.assertTrue(exceptionText.startswith(invalidValueException % ("ENVVAR_TOOL_WITH_SPACES", "tool")))

		exceptionText = ""
		value = ""
		try:
			eval = aRaptor.GetEvaluator(None, toolchainpathVar.GenerateBuildUnits(aRaptor.cache)[0])
			value = eval.Get("ENVVAR_TOOLCHAINPATH_WITH_SPACES")
		except Exception, e:
			exceptionText = str(e)
			
		if self.isWin():
			self.assertTrue(value)
			self.assertFalse(' ' in value)
		else:
			self.assertTrue(exceptionText.startswith(invalidValueException % ("ENVVAR_TOOLCHAINPATH_WITH_SPACES", "toolchainpath")))
		
		# 2b: paths/tools don't exist - should throw error exceptions on all platforms as 8.3 paths are only available
		# for use if a path/tool exists
		os.remove(toolwithspaces)
		os.removedirs(pathwithspaces)

		exceptionText = ""
		try:
			eval = aRaptor.GetEvaluator(None, toolVar.GenerateBuildUnits(aRaptor.cache)[0])
		except Exception, e:
			exceptionText = str(e)
		self.assertTrue(exceptionText.startswith(invalidValueException % ("ENVVAR_TOOL_WITH_SPACES", "tool")))

		exceptionText = ""
		try:
			eval = aRaptor.GetEvaluator(None, toolchainpathVar.GenerateBuildUnits(aRaptor.cache)[0])
		except Exception, e:
			exceptionText = str(e)			
		self.assertTrue(exceptionText.startswith(invalidValueException % ("ENVVAR_TOOLCHAINPATH_WITH_SPACES", "toolchainpath")))

		# clean-up
		self.RestoreEnv("ENVVAR_TOOL_WITH_SPACES")
		self.RestoreEnv("ENVVAR_TOOLCHAINPATH_WITH_SPACES")
	
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

	def testGetBuildUnits(self):
		r = raptor.Raptor()

		# <group name="g1">
		g1 = raptor_data.Group("g1")
		r.cache.AddGroup(g1)
		
		# <groupRef ref="g2" mod="A.B"/>
		g2a = raptor_data.GroupRef()
		g2a.SetProperty("ref", "g2")
		g2a.SetProperty("mod", "A.B")
		g1.AddChild(g2a)
		
		# <groupRef ref="g2" mod="C.D"/>
		g2b = raptor_data.GroupRef()
		g2b.SetProperty("ref", "g2")
		g2b.SetProperty("mod", "C.D")
		g1.AddChild(g2b)
		
		# <group name="g2">
		g2 = raptor_data.Group("g2")
		r.cache.AddGroup(g2)
		
		# <varRef ref="V" mod="E.F"/>
		v2 = raptor_data.VariantRef()
		v2.SetProperty("ref", "V")
		v2.SetProperty("mod", "E.F")
		g2.AddChild(v2)
		
		# <varRef ref="V" mod="G.H"/>
		v3 = raptor_data.VariantRef()
		v3.SetProperty("ref", "V")
		v3.SetProperty("mod", "G.H")
		g2.AddChild(v3)
		
		# <aliasRef ref="X" mod="I.J"/>
		v4 = raptor_data.AliasRef()
		v4.SetProperty("ref", "X")
		v4.SetProperty("mod", "I.J")
		g2.AddChild(v4)
		
		# <aliasRef ref="X" mod="K.L"/>
		v5 = raptor_data.AliasRef()
		v5.SetProperty("ref", "X")
		v5.SetProperty("mod", "K.L")
		g2.AddChild(v5)
		
		r.cache.AddVariant(raptor_data.Variant("A"))
		r.cache.AddVariant(raptor_data.Variant("B"))
		r.cache.AddVariant(raptor_data.Variant("C"))
		r.cache.AddVariant(raptor_data.Variant("D"))
		r.cache.AddVariant(raptor_data.Variant("E"))
		r.cache.AddVariant(raptor_data.Variant("F"))
		r.cache.AddVariant(raptor_data.Variant("G"))
		r.cache.AddVariant(raptor_data.Variant("H"))
		r.cache.AddVariant(raptor_data.Variant("I"))
		r.cache.AddVariant(raptor_data.Variant("J"))
		r.cache.AddVariant(raptor_data.Variant("K"))
		r.cache.AddVariant(raptor_data.Variant("L"))
		
		r.cache.AddVariant(raptor_data.Variant("V"))
		
		# <alias name="X" meaning="A.B.C.D.E.F.G.H/>
		alias = raptor_data.Alias("X")
		alias.SetProperty("meaning", "A.B.C.D.E.F.G.H")
		r.cache.AddAlias(alias)

		r.cache.AddVariant(raptor_data.Variant("Y"))
		r.cache.AddVariant(raptor_data.Variant("Z"))
	
		units = raptor_data.GetBuildUnits(["g1.Y", "g1.Z"], r.cache, r)
		
		# <group name="g1">
		#   <groupRef ref="g2" mod="A.B"/>    g2.A.B
		#   <groupRef ref="g2" mod="C.D"/>    g2.C.D
		# </group>
		# <group name="g2">
		#   <varRef ref="V" mod="E.F"/>       V.E.F
		#   <varRef ref="V" mod="G.H"/>       V.G.H
		#   <aliasRef ref="X" mod="I.J"/>     X.I.J
		#   <aliasRef ref="X" mod="K.L"/>     X.K.L
		# </group>
		# <alias name="X" meaning="A.B.C.D.E.F.G.H/>
		#
		expected = [ "VEFABY", "VGHABY", "ABCDEFGHIJABY", "ABCDEFGHKLABY",
				     "VEFCDY", "VGHCDY", "ABCDEFGHIJCDY", "ABCDEFGHKLCDY",
		             "VEFABZ", "VGHABZ", "ABCDEFGHIJABZ", "ABCDEFGHKLABZ",
				     "VEFCDZ", "VGHCDZ", "ABCDEFGHIJCDZ", "ABCDEFGHKLCDZ" ]
		
		self.failUnlessEqual(len(units), len(expected))
		
		for u in units:
			vars = "".join([v.name for v in u.variants])
			self.failUnless(vars in expected, vars + " was not expected")
			expected.remove(vars)
		
		self.failUnless(len(expected) == 0, str(expected) + " not found")
		
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
