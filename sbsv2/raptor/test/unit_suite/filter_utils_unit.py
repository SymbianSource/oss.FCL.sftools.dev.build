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
# Test generic classes available for use in plugin log filters
#


import unittest
import filter_utils


testRecipeTemplate = \
"""<recipe name='%s' target='recipe_target' host="recipe_host" layer='recipe_layer' component='recipe_component' bldinf='recipe_bldinf' mmp='recipe_mmp' config='recipe_config' platform='recipe_platform' phase='recipe_phase' source='recipe_source'>"
<![CDATA[
%s
]]><time start='0123456789.123456789' elapsed='99.999' />
<status exit='%s' %s attempt='%d' />
</recipe>"""

testRecipeCalls = \
"""+ call_to_some_tool -a arg1 -a arg2 -a arg3
+ call_to_some_other_tool -a arg1 -a arg2 -a arg3"""
testRecipeOutput = \
"""output from some tool or other
some more output from some tool or other"""

# Fall-back warning and error examples
genericWarnings = \
"""Warning: generic warning from some tool or other
Warning: another generic warning from some tool or other"""
genericErrors = \
"""Error: generic error from some tool or other
Error: another generic error from some tool or other"""

# Real world examples of mwccsym2, mwldsym2 and mwwinrc errors and warnings
mwWarnings = \
"""mwldsym2.exe: warning: Multiply defined symbol: ___get_MSL_init_count in
..\sf\os\cellularsrv\telephonyserver\etelserverandcore\SETEL\ET_PHONE.CPP:36: warning: cannot find matching deallocation function for 'CReqEntry'"""
mwErrors = \
"""HelloWorld.cpp:21: undefined identifier 'stuff'
mwldsym2.exe: Specified file 'HelloWorld.o' not found"""
mwBenign = \
"""..\sf\os\lbs\locationrequestmgmt\locationserver\src\locserver.cpp:223: note: NOTE: CLocServer::DoNewSessionL. aMessage and aVersion not used. TBD"""


class TestFilterUtils(unittest.TestCase):
	
	def setUp(self):
		self.__recipeFactory = filter_utils.RecipeFactory()
	
	def __createRecipeLines(self, aName, aExit, aAttempt, aCode=None, aExtras=""):
		"""Customise the recipe test template for differing recipe tests
		The 'code' attribute of 'status' is optional, and different errors/warnings
		etc. can be added via aExtras"""
		code = ""
		if aCode:
			code = "code='%d'" % aCode
		midSection = testRecipeCalls + "\n" + testRecipeOutput
		if aExtras:
			midSection += "\n" + aExtras
		recipe = testRecipeTemplate % (aName, midSection, aExit, code, aAttempt)
		return recipe.split("\n")
	
	def __checkListContent(self, aExpected, aActual, aPrefixIgnore=""):
		"""Compare the content of two lists of strings.
		Optionally trim a prefix from the expected results."""
		for expected in aExpected:
			self.assertTrue(expected.lstrip(aPrefixIgnore) in aActual)
		self.assertEqual(len(aActual), len(aExpected))
	
	def testRecipeFactory(self):
		recipeLines = self.__createRecipeLines("generic", "ok", 1)
		recipe = self.__recipeFactory.newRecipe(recipeLines[0])
		self.assertTrue(isinstance(recipe, filter_utils.Recipe))
		
		recipeLines = self.__createRecipeLines("win32something", "ok", 1)
		recipe = self.__recipeFactory.newRecipe(recipeLines[0])
		self.assertTrue(isinstance(recipe, filter_utils.Win32Recipe))
		
	def testGenericRecipe(self):
		
		# 1. Basic successful recipe
		recipeLines = self.__createRecipeLines("recipe_name", "ok", 1)
		recipe = self.__recipeFactory.newRecipe(recipeLines[0])
				
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.name), 'recipe_name')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.target), 'recipe_target')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.layer), 'recipe_layer')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.component), 'recipe_component')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.bldinf), 'recipe_bldinf')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.mmp), 'recipe_mmp')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.config), 'recipe_config')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.platform), 'recipe_platform')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.phase), 'recipe_phase')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.source), 'recipe_source')
		
		self.assertFalse(recipe.isComplete())
				
		for x in range(1, len(recipeLines)):
			recipe.addLine(recipeLines[x])
		
		self.assertTrue(recipe.isComplete())
		self.assertTrue(recipe.isSuccess())
		
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.start), "0123456789.123456789")
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.elapsed), 99.999)
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.exit), 'ok')
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.attempts), 1)
		
		# Ignore "+ " tool call prefixes that are trimmed in getCalls output
		self.__checkListContent(testRecipeCalls.split("\n"), recipe.getCalls(), "+ ")
		self.__checkListContent(testRecipeOutput.split("\n"), recipe.getOutput())
		
		# 2. Recipe failure with errors
		recipeLines = self.__createRecipeLines("recipe_name", "failed", 3, 10, genericErrors)
		recipe = self.__recipeFactory.newRecipe()
		for line in recipeLines:
			recipe.addLine(line)
		self.assertFalse(recipe.isSuccess())
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.attempts), 3)
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.code), 10)	
		self.__checkListContent(genericErrors.split("\n"), recipe.getErrors())
		
		# 3. Recipe retry with warnings
		recipeLines = self.__createRecipeLines("recipe_name", "retry", 2, 5, genericWarnings)
		recipe = self.__recipeFactory.newRecipe()
		for line in recipeLines:
			recipe.addLine(line)
		self.assertFalse(recipe.isSuccess())
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.attempts), 2)
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.code), 5)		
		self.__checkListContent(genericWarnings.split("\n"), recipe.getWarnings())
	
	def testWin32Recipe(self):
		# Recipe failure with errors and warnings
		recipeLines = self.__createRecipeLines("win32something", "failed", 3, 10, mwWarnings + "\n" + mwErrors + "\n" + mwBenign)
		recipe = self.__recipeFactory.newRecipe(recipeLines[0])
		for line in recipeLines:
			recipe.addLine(line)
		self.assertFalse(recipe.isSuccess())
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.attempts), 3)
		self.assertEqual(recipe.getDetail(filter_utils.Recipe.code), 10)
		
		self.__checkListContent(mwWarnings.split("\n"), recipe.getWarnings())
		self.__checkListContent(mwErrors.split("\n"), recipe.getErrors())
	
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "filter_utils_unit"

	tests = unittest.makeSuite(TestFilterUtils)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
