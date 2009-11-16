#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# raptor_xml_unit module
# This module tests the identification and parsing of XML metadata files
#

import os
import raptor
import generic_path
import raptor_xml
import unittest

class TestRaptorXML(unittest.TestCase):
	
	def setUp(self):
		self.__logger = raptor.Raptor()
		self.__nullSysDefRoot = generic_path.Path("smoke_suite/test_resources")
		self.__sysDefRoot = generic_path.Join(os.environ[raptor.env],"test/smoke_suite/test_resources")
		self.__sysDefFileRoot = generic_path.Join(os.environ[raptor.env], "test/metadata/system")
		
	def testSystemDefinitionProcessing(self):
		# Make formatting neater
		print
		expectedBldInfs = [generic_path.Join(self.__sysDefRoot, "simple/bld.inf"),\
						generic_path.Join(self.__sysDefRoot, "basics/helloworld/Bld.inf")]
		
		sysdefs = ["1.4.1", "1.3.1", "1.5.1"]
		for sysdef in sysdefs:
			systemModel = raptor_xml.SystemModel(self.__logger,
					generic_path.Join(self.__sysDefFileRoot,
					"system_definition_" + sysdef + ".xml"), self.__sysDefRoot)
			self.__compareFileLists(expectedBldInfs, systemModel.GetAllComponents())
		
	
		sourceroot = ""
		if os.environ.has_key('SOURCEROOT'):
			sourceroot = os.environ['SOURCEROOT']
		os.environ['SOURCEROOT'] = self.__sysDefRoot.GetLocalString()
		systemModel = raptor_xml.SystemModel(self.__logger, generic_path.Join(self.__sysDefFileRoot, "system_definition_2.0.0.xml"), self.__nullSysDefRoot)
		self.__compareFileLists(expectedBldInfs, systemModel.GetAllComponents())

		del os.environ["SOURCEROOT"]
		systemModel = raptor_xml.SystemModel(self.__logger, generic_path.Join(self.__sysDefFileRoot, "system_definition_2.0.0.xml"), self.__sysDefRoot)
		self.__compareFileLists(expectedBldInfs, systemModel.GetAllComponents())
		
		os.environ["SOURCEROOT"] = 'i_am_not_a_valid_path_at_all'
		systemModel = raptor_xml.SystemModel(self.__logger, generic_path.Join(self.__sysDefFileRoot, "system_definition_2.0.0.xml"), self.__sysDefRoot)
		self.__compareFileLists(expectedBldInfs, systemModel.GetAllComponents())

				
		del os.environ["SOURCEROOT"]
		systemModel = raptor_xml.SystemModel(self.__logger, generic_path.Join(self.__sysDefFileRoot, "system_definition_3.0.0.xml"), self.__sysDefRoot)
		self.__compareFileLists([], systemModel.GetAllComponents())
				
		
		systemModel = raptor_xml.SystemModel(self.__logger, generic_path.Join(self.__sysDefFileRoot, "system_definition_multi_layers.xml"), self.__sysDefRoot)

		expectedBldInfs = [ generic_path.Join(self.__sysDefRoot, "simple/bld.inf"),\
							generic_path.Join(self.__sysDefRoot, "simple_dll/bld.inf"),\
						    generic_path.Join(self.__sysDefRoot, "simple_export/bld.inf"),\
						    generic_path.Join(self.__sysDefRoot, "simple_gui/Bld.inf"),\
						    generic_path.Join(self.__sysDefRoot, "simple_implib/bld.inf"),\
						    generic_path.Join(self.__sysDefRoot, "simple_lib/bld.inf"),\
						    generic_path.Join(self.__sysDefRoot, "simple_stringtable/bld.inf"),\
						    generic_path.Join(self.__sysDefRoot, "simple_test/bld.inf")]
		self.__compareFileLists(expectedBldInfs, systemModel.GetAllComponents())
	
		expectedBldInfs = [ generic_path.Join(self.__sysDefRoot, "simple_export/bld.inf"),\
						    generic_path.Join(self.__sysDefRoot, "simple_gui/Bld.inf")]
		self.__compareFileLists(expectedBldInfs, systemModel.GetLayerComponents("Second Layer"))

		self.__compareFileLists([], systemModel.GetLayerComponents("Fifth Layer"))
				
		self.__compareFileLists([], systemModel.GetLayerComponents("Sixth Layer"))
		
				
		# Probably redundant, but return local environment (at least its dictionary) to pre-test state
		os.environ["SOURCEROOT"] = sourceroot
		
	def __compareFileLists (self, aListOne, aListTwo):
		
		self.assertEquals(len(aListOne), len(aListTwo))
		
		i = 0
		while i < len(aListOne) :
			self.assertEquals(aListOne[i].GetLocalString().lower(), aListTwo[i].GetLocalString().lower())
			i = i + 1
		
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "raptor_xml_unit"

	tests = unittest.makeSuite(TestRaptorXML)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
