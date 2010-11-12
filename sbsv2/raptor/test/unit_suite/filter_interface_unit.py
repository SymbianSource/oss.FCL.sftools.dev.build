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
# Unit tests for the filter_interface module

import unittest
import filter_interface
import sys

# No point testing the Filter interface - it's fully abstract

class TestFilterInterface(unittest.TestCase):
	def testSAXFilter(self):
		# Areas for improvement:
		# - Test non-well formed XML
		# - Test all error cases (error, fatalError, warning)
		class testFilter(filter_interface.FilterSAX):
			def __init__(self):
				super(testFilter,self).__init__()
				self.failed = False
				self.seendoc = False
				self.startcount = 2
				self.endcount = 2
				self.charcount = 14

			def startDocument(self):
				if self.seendoc:
					self.failed = True
					sys.stdout.write('FAIL: Nested document elements')
				self.seendoc = True

			def startElement(self, name, attributes):
				self.startcount -= 1

				if self.startcount < 0:
					self.failed = True
					# Report the number of excessive start elements
					sys.stdout.write('FAIL: Seen {0} too many start elements'.format(0-self.startcount))

			def endElement(self, name):
				self.endcount -= 1

				if self.endcount < 0:
					self.failed = True
					# Report the number of excessive end elements
					sys.stdout.write('FAIL: Seen {0} too many end elements'.format(0-self.endcount))

			def endDocument(self):
				if not self.seendoc:
					self.failed = True
					self.stdout.write('FAIL: Not in a document at doc end')
				self.seendoc = False

			def characters(self, char):
				self.charcount -= len(char)

				if self.charcount < 0:
					self.failed = True
					# Report the number of excessive characters
					sys.stdout.write('FAIL: Seen {0} too many characters'.format(0-self.charcount))

			def finish(self):
				# if self.seendoc:
				# 	self.failed = True
				#	sys.stdout.write('FAIL: Still in a doc at end')
				if self.startcount > 0:
					# Already tested to see if it's less than 0
					self.failed = True
					sys.stdout.write('FAIL: Not enough start elements')
				if self.endcount > 0:
					self.failed = True
					sys.stdout.write('FAIL: Not enough end elements')
				if self.charcount > 0:
					self.failed = True
					sys.stdout.write('FAIL: Not enough chars')

		
		filter = testFilter()
		filter.open([])
		self.assertTrue(filter.write("<foo>FooText<bar>BarText</bar></foo>"))
		filter.finish()
		self.assertFalse(filter.failed)

	def testPerRecipeFilter(self):
		class testFilter(filter_interface.PerRecipeFilter):
			recipes = [ { 'name':'recipe1', 'target':'target1', 'host':'host1', 'layer':'layer1',  'component':'component1', 'bldinf':'test1.inf', 'mmp':'test1.mmp', 'config':'winscw_test1', 'platform':'plat1', 'phase':'PHASE1', 'source':'source1', 'prereqs':'prereqs1', 'text':'\nTest text 1\n\n'},
			{ 'name':'recipe2', 'target':'target2', 'host':'host2', 'layer':'layer2',  'component':'component2', 'bldinf':'test2.inf', 'mmp':'test2.mmp', 'config':'winscw_test2', 'platform':'', 'phase':'PHASE2', 'source':'', 'prereqs':'', 'text':'\nTest text 2\n\n'} ]

			def __init__(self):
				super(testFilter,self).__init__()
				self.failed = False

			def HandleRecipe(self):
				testRecipe = self.recipes[0]
				self.recipes = self.recipes[1:]

				for key in testRecipe.keys():
					if not self.__dict__.has_key(key):
						self.failed = True
						sys.stdout.write('FAIL: self.{0} not set\n'.format(key))
					elif self.__dict__[key] != testRecipe[key]:
						self.failed = True
						sys.stdout.write('FAIL: {0} != {1}\n'.format(repr(self.__dict__[key]),repr(testRecipe[key])))
	
		filter = testFilter()
		filter.open([])
		self.assertTrue(filter.write('''<?xml version="1.0" encoding="ISO-8859-1" ?>
<buildlog sbs_version="99.99.9 [ISODATE symbian build system CHANGESET]" xmlns="http://symbian.com/xml/build/log" xmlns:progress="http://symbian.com/xml/build/log/progress" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://symbian.com/xml/build/log http://symbian.com/xml/build/log/1_0.xsd">
<info>sbs: version 99.99.9 [ISODATE symbian build system CHANGESET]
</info>
<progress:discovery object_type='bld.inf references' count='1' />
<whatlog bldinf='test.inf' mmp='' config=''>
<export destination='test' source='test2'/>
</whatlog>
<recipe name='recipe1' target='target1' host='host1' layer='layer1' component='component1' bldinf='test1.inf' mmp='test1.mmp' config='winscw_test1' platform='plat1' phase='PHASE1' source='source1' prereqs='prereqs1'>
<![CDATA[Test text 1]]><time start='1234567890.01234' elapsed='1.234' />
<status exit='ok' attempt='1' flags='FLAGS1' />
</recipe>
<recipe name='recipe2' target='target2' host='host2' layer='layer2' component='component2' bldinf='test2.inf' mmp='test2.mmp' config='winscw_test2' platform='' phase='PHASE2' source='' prereqs=''>
<![CDATA[Test text 2]]><time start='0123456789.12340' elapsed='2.345' />
<status exit='failed' attempt='2' flags='FLAGS2' />
</recipe>
</buildlog>
'''))
		self.assertFalse(filter.failed)

# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "filter_interface_unit"

	tests = unittest.makeSuite(TestFilterInterface)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
