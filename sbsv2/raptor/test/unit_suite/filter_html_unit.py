
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".

'''
Test the HTML class in plugins/filter_html.py
'''

import os
import shutil
import sys
import unittest

test_data = os.path.join(os.getcwd(),"unit_suite","data","html_filter")

# add the plugins directory to the python path
sys.path.append(os.path.join(os.environ['SBS_HOME'], "python", "plugins"))
# so that we can import the filter module directly
import filter_html
import generic_path

class Mock(object):
	'''empty object for attaching arbitrary attributes and functions.'''
	pass
	
class TestFilterHtml(unittest.TestCase):
	'''test cases for the HTML log filter.
	
	This is a minimal set of tests for starters. As people start using this
	filter and reporting bugs and niggles we can add test cases here to
	avoid regressions.'''
	
	def setUp(self):
		self.mock_params = Mock()
		self.mock_params.configPath = [generic_path.Path("config")]
		self.mock_params.home = generic_path.Path(test_data)
		self.mock_params.logFileName = generic_path.Path("tmp/foo")
		self.mock_params.timestring = "now"
		
		# where do we expect the output to be written
		self.html_dir = str(self.mock_params.logFileName) + "_html"
		
	def tearDown(self):
		'''remove all the generated output files and directories.'''
		if os.path.isdir(self.html_dir):
			shutil.rmtree(self.html_dir)
	
	def testPass(self):
		'''are the setUp and tearDown methods sane.'''
		pass
	
	def testConstructor(self):
		'''simply construct an HTML object.'''
		html = filter_html.HTML()

	def testMinimalLog(self):
		'''process a minimal log file.'''
		html = filter_html.HTML()
		self.assertTrue( html.open(self.mock_params) )
		self.assertTrue( html.write('<?xml version="1.0" encoding="ISO-8859-1" ?>\n') )
		self.assertTrue( html.write('<buildlog sbs_version="2.99.9 [hi]">') )
		self.assertTrue( html.write('</buildlog>') )
		self.assertTrue( html.close() )
		
		self.assertTrue( os.path.isfile(self.html_dir + "/index.html") )
		self.assertTrue( os.path.isfile(self.html_dir + "/style.css") )
		
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.name = "filter_html_unit"

	tests = unittest.makeSuite(TestFilterHtml)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
