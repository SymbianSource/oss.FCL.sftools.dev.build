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
# raptor_meta_unit module
# This module tests the classes forming the Raptor bld.inf and .mmp parsing support
#

import raptor
import raptor_meta
import raptor_utilities
import raptor_data
import mmpparser
import unittest
import generic_path
import os
import sys
import re

class TestRaptorMeta(unittest.TestCase):

	def setUp(self):
		self.raptor = raptor.Raptor()
		self.__testRoot = generic_path.Path(os.environ[raptor.env], "test").Absolute()
		self.__makefilePathTestRoot = self.__testRoot
		self.__epocroot = self.__testRoot
		self.__variant_cfg_root = self.__testRoot.Append('metadata/config')
		self.__variant_cfg = self.__variant_cfg_root.Append('test_cfg.cfg')
		self.__platmacros_armv5 = "ARMCC EPOC32 MARM EABI ARMCC_2 ARMCC_2_2 GENERIC_MARM MARM_ARMV5"
		self.__platmacros_armv6 = "ARMCC EPOC32 MARM EABI ARMCC_2 ARMCC_2_2 GENERIC_MARM MARM_ARMV5 ARMV6"
		self.__platmacros_armv7 = "ARMCC EPOC32 MARM EABI ARMCC_2 ARMCC_2_2 GENERIC_MARM MARM_ARMV5 ARMV7"
		self.__platmacros_winscw = "CW32 WINS WINSCW"

		self.variant_hrh = self.__testRoot.Append('metadata/include/test_hrh.hrh')
		
		self.__OSRoot = ""
		if raptor_utilities.getOSFileSystem() == "cygwin":
			self.__OSRoot = str(self.__makefilePathTestRoot)[:2]

		# we need some sort of generic platform for preprocessing
		self.defaultPlatform = { 'PLATFORM': 'generic',
							     'EPOCROOT': self.__epocroot,
							     'VARIANT_HRH': self.variant_hrh,
							     'SYSTEMINCLUDE' : '',
							     'id': 0,
							     'key': '0000000000000000',
							     'key_md5': '0000000000000000',
							     'ISFEATUREVARIANT' : False,
							     'PLATMACROS' : self.__platmacros_armv5,
								 'SBS_BUILD_DIR' : str(self.__epocroot) + "/epoc32/build",
								 'METADEPS' : [] 
							   }
		# For testing purposes, the ARMV5 platform is flagged here as feature variant.
		# In metadata processing terms, this means that the location of the HRH file
		# is not automatically added to the SYSTEMINCLUDE path, and so is specified
		# directly.
		self.ARMV5           = { 'PLATFORM': 'ARMV5',
							     'EPOCROOT': self.__epocroot,
							     'VARIANT_HRH': self.variant_hrh,
							     'SYSTEMINCLUDE' : str(self.variant_hrh.Dir()),
							     'id': 1,
							     'key': '1111111111111111',
							     'key_md5': '1111111111111111',
							     'ISFEATUREVARIANT' : True,
							     'PLATMACROS' : self.__platmacros_armv5,
								 'SBS_BUILD_DIR' : str(self.__epocroot) + "/epoc32/build",
								 'METADEPS' : [] 
							   }
		self.ARMV5SMP        = { 'PLATFORM': 'ARMV5SMP',
							     'EPOCROOT': self.__epocroot,
							     'VARIANT_HRH': self.variant_hrh,
							     'SYSTEMINCLUDE' : str(self.variant_hrh.Dir()),
							     'id': 1,
							     'key': '1111111111111111',
							     'key_md5': '1111111111111111',
							     'ISFEATUREVARIANT' : False,
							     'PLATMACROS' : self.__platmacros_armv5,
								 'SBS_BUILD_DIR' : str(self.__epocroot) + "/epoc32/build",
								 'METADEPS' : [] 
							   }
		self.ARMV6           = { 'PLATFORM': 'ARMV6',
							     'EPOCROOT': self.__epocroot,
							     'VARIANT_HRH': self.variant_hrh,
							     'SYSTEMINCLUDE' : str(self.variant_hrh.Dir()),
							     'id': 1,
							     'key': '1111111111111111',
							     'key_md5': '1111111111111111',
							     'ISFEATUREVARIANT' : False,
							     'PLATMACROS' : self.__platmacros_armv6,
								 'SBS_BUILD_DIR' : str(self.__epocroot) + "/epoc32/build",
								 'METADEPS' : [] 
							   }
		self.ARMV7           = { 'PLATFORM': 'ARMV7',
							     'EPOCROOT': self.__epocroot,
							     'VARIANT_HRH': self.variant_hrh,
							     'SYSTEMINCLUDE' : str(self.variant_hrh.Dir()),
							     'id': 1,
							     'key': '1111111111111111',
							     'key_md5': '1111111111111111',
							     'ISFEATUREVARIANT' : False,
							     'PLATMACROS' : self.__platmacros_armv7,
								 'SBS_BUILD_DIR' : str(self.__epocroot) + "/epoc32/build",
								 'METADEPS' : [] 
							   }
		self.ARMV7SMP         = { 'PLATFORM': 'ARMV7SMP',
							     'EPOCROOT': self.__epocroot,
							     'VARIANT_HRH': self.variant_hrh,
							     'SYSTEMINCLUDE' : str(self.variant_hrh.Dir()),
							     'id': 1,
							     'key': '1111111111111111',
							     'key_md5': '1111111111111111',
							     'ISFEATUREVARIANT' : False,
							     'PLATMACROS' : self.__platmacros_armv7,
								 'SBS_BUILD_DIR' : str(self.__epocroot) + "/epoc32/build",
								 'METADEPS' : [] 
							   }
		self.WINSCW          = { 'PLATFORM': 'WINSCW',
							     'EPOCROOT': self.__epocroot,
							     'VARIANT_HRH': self.variant_hrh,
							     'SYSTEMINCLUDE' : '',
							     'id': 2,
							     'key': '2222222222222222',
							     'key_md5': '2222222222222222',
							     'ISFEATUREVARIANT' : False,
							     'PLATMACROS' : self.__platmacros_winscw,
								 'SBS_BUILD_DIR' : str(self.__epocroot) + "/epoc32/build",
								 'METADEPS' : [] 
							   }
				
		self.testPlats = [self.ARMV5, self.ARMV5SMP, self.ARMV6, self.ARMV7, self.ARMV7SMP, self.WINSCW]
		
		# Get the version of CPP that we are using and hope it's correct
		# since there is no tool check.
		if os.environ.has_key('SBS_GNUCPP'):
			self.__gnucpp = os.environ['SBS_GNUCPP']
		else: 
			self.__gnucpp = "cpp" 
	
	def testPreProcessor(self):
		# Just test for correct behaviour on failure, other tests excercise correct behaviour on success
		preProcessor = raptor_meta.PreProcessor('cpp_that_does_not_exist', 
											    '-undef -nostdinc', 
											    '-I', '-D', '-include',
											    self.raptor)

		try:
			 preProcessor.preprocess()
		except Exception, e:
			self.assertTrue(isinstance(e, raptor_meta.MetaDataError))
			self.assertTrue(re.match('^Preprocessor exception', e.Text))

	def testConfigParsing(self):
		# .cfg file specified, but does not exist		
		try:
			configDetails = raptor_meta.getVariantCfgDetail(self.__epocroot, 
														    self.__variant_cfg_root.Append("missing"))
		except Exception, e:
			self.assertTrue(isinstance(e, raptor_meta.MetaDataError))
			self.assertTrue(re.match('^Could not read variant configuration file.*$', e.Text))
			
		# No .hrh file specified
		try:
			configDetails = raptor_meta.getVariantCfgDetail(self.__epocroot,
														    self.__variant_cfg_root.Append("empty_cfg.cfg"))
		except Exception, e:
			self.assertTrue(isinstance(e, raptor_meta.MetaDataError))
			self.assertTrue(re.match('No variant file specified in .*', e.Text))
					
		# .hrh file does not exist
		try:
			configDetails = raptor_meta.getVariantCfgDetail(self.__epocroot,
														    self.__variant_cfg_root.Append("invalid_cfg.cfg"))
		except Exception, e:
			self.assertTrue(isinstance(e, raptor_meta.MetaDataError))
			self.assertTrue(re.match('Variant file .* does not exist', e.Text))
				
		# Valid .cfg file
		configDetails = raptor_meta.getVariantCfgDetail(self.__epocroot, 
													    self.__variant_cfg)
		self.failUnless(configDetails)
		
		found_variant_hrh = str(configDetails.get('VARIANT_HRH'))	
		expected_variant_hrh = str(self.variant_hrh)
		
		self.assertEqual(found_variant_hrh, expected_variant_hrh)
	

	def __testBuildPlatforms(self, aRootBldInfLocation, aBldInfFile, 
							 aExpectedBldInfPlatforms, aExpectedBuildablePlatforms):
		bldInfFile = aRootBldInfLocation.Append(aBldInfFile)
		self.failUnless(bldInfFile)
		
		depfiles=[]
		bldInfObject = raptor_meta.BldInfFile(bldInfFile, self.__gnucpp, depfiles=depfiles, log=self.raptor)
		
		bp = bldInfObject.getBuildPlatforms(self.defaultPlatform)
		self.assertEquals(bp, aExpectedBldInfPlatforms)

		buildableBldInfBuildPlatforms = raptor_meta.getBuildableBldInfBuildPlatforms(bp,
				'ARMV5 ARMV7 WINSCW',
				'ARMV5 ARMV5SMP ARMV7 WINSCW',
				'ARMV5 ARMV7 WINSCW')
		
		for expectedBuildablePlatform in aExpectedBuildablePlatforms:
			self.assertTrue(expectedBuildablePlatform in buildableBldInfBuildPlatforms)
			
		self.assertEqual(len(aExpectedBuildablePlatforms),
						 len(buildableBldInfBuildPlatforms))
		return
	
	def testBldInfPlatformDeduction(self):
		bldInfTestRoot = self.__testRoot.Append('metadata/project/bld.infs')
				
		self.__testBuildPlatforms(bldInfTestRoot, 'no_prj_platforms.inf', 
								  [], ['ARMV7', 'ARMV5', 'WINSCW', 'GCCXML'])
		self.__testBuildPlatforms(bldInfTestRoot, 'no_plats.inf', 
								  [], ['ARMV7', 'ARMV5', 'WINSCW', 'GCCXML'])
		self.__testBuildPlatforms(bldInfTestRoot, 'default_plats.inf', 
								  ['DEFAULT'], ['ARMV7', 'ARMV5', 'WINSCW', 'GCCXML'])
		self.__testBuildPlatforms(bldInfTestRoot, 'default_plats_minus_plat.inf', 
								  ['DEFAULT', '-WINSCW'], ['ARMV7', 'ARMV5', 'GCCXML'])
		self.__testBuildPlatforms(bldInfTestRoot, 'single_plat.inf', 
								  ['ARMV5'], ['ARMV5', 'GCCXML'])
		self.__testBuildPlatforms(bldInfTestRoot, 'multiple_plats.inf', 
								  ['ARMV5', 'WINSCW', 'TOOLS'], ['ARMV5', 'WINSCW', 'TOOLS', 'GCCXML'])
		return
	
	def __testBldInfTestCode(self, aTestRoot, aBldInf, aActual, aExpected):
		loop_number = 0
		for actual in aActual:
			self.assertEquals(actual, aExpected[loop_number])
			loop_number += 1
		
	def testBldInfTestType(self):
		bldInfTestRoot = self.__testRoot.Append('metadata/project/mmps/test_mmps')
		
		bldInfFile = bldInfTestRoot.Append('test_mmps.inf')
		depfiles = []
		bldInfObject = raptor_meta.BldInfFile(bldInfFile, self.__gnucpp, depfiles=depfiles, log=self.raptor)
		testArmv5Platform = self.ARMV5
		testArmv5Platform["TESTCODE"] = True
		bldInfObject.getRomTestType(testArmv5Platform)
		
		self.__testBldInfTestCode(bldInfTestRoot, 'test_mmps.inf',
				[bldInfObject.testManual, bldInfObject.testAuto], [1, 1])
	
	def __testExport(self, aExportObject, aSource, aDestination, aAction):			
		self.assertEquals(aExportObject.getSource(), aSource)
		self.assertEqualsOrContainsPath(aExportObject.getDestination(), aDestination)
		self.assertEquals(aExportObject.getAction(), aAction)
	
	def assertEqualsOrContainsPath(self, aRequirement, aCandidate):
		# If aRequirement is a list, which it might well be, we should
		# assert that aPathString is contained in it
		# If aRequirement not a list, it will be a string, and 
		# we should assert equality of the strings
		# On windows we shouldn't care about the case of the drive letter.

		if isinstance(aRequirement, list):
			pathsequal = False
			for r in aRequirement:
				pathsequal = path_compare_notdrivelettercase(r,aCandidate) or pathsequal
			self.assertTrue(pathsequal)
		else:
			self.assertTrue(path_compare_notdrivelettercase(aRequirement,aCandidate))
		
	def testBldInfExports(self):
		bldInfTestRoot = self.__testRoot.Append('metadata/project/bld.infs')
		bldInfMakefilePathTestRoot = str(self.__makefilePathTestRoot) + '/metadata/project/'
		
		depfiles = []
		bldInfObject = raptor_meta.BldInfFile(bldInfTestRoot.Append('exports.inf'), 
											  self.__gnucpp, depfiles=depfiles, log=self.raptor)
					
		exports = bldInfObject.getExports(self.defaultPlatform)
		
		# export1.h
		self.__testExport(exports[0], 
						  bldInfMakefilePathTestRoot+'bld.infs/export1.h', 
						  '$(EPOCROOT)/epoc32/include/export1.h', 
						  'copy')

		# export2.h				export_test\export2.h
		self.__testExport(exports[1], 
						  bldInfMakefilePathTestRoot+'bld.infs/export2.h', 
						  '$(EPOCROOT)/epoc32/include/export_test/export2.h', 
						  'copy')
		
		# export3.h				..\export_test\export3.h
		self.__testExport(exports[2], 
						  bldInfMakefilePathTestRoot+'bld.infs/export3.h', 
						  '$(EPOCROOT)/epoc32/export_test/export3.h', 
						  'copy')
		
		# export4.h				\export_test_abs\export4.h
		self.__testExport(exports[3], 
						  bldInfMakefilePathTestRoot+'bld.infs/export4.h', 
						  self.__OSRoot+'/export_test_abs/export4.h', 
						  'copy')

		# export5.h				\epoc32\export_test_abs\export5.h
		self.__testExport(exports[4], 
						  bldInfMakefilePathTestRoot+'bld.infs/export5.h', 
						  '$(EPOCROOT)/epoc32/export_test_abs/export5.h', 
						  'copy')
		
		# export6.h				|..\export_test_rel\export6.h
		self.__testExport(exports[5], 
						  bldInfMakefilePathTestRoot+'bld.infs/export6.h', 
						  bldInfMakefilePathTestRoot+'export_test_rel/export6.h', 
						  'copy')
		
		# export6.h				|\export_test_rel\export7.h
		self.__testExport(exports[6], 
						  bldInfMakefilePathTestRoot+'bld.infs/export7.h', 
						  bldInfMakefilePathTestRoot+'bld.infs/export_test_rel/export7.h',
						  'copy')
		
		# export7.h				|export_test_rel\export8.h
		self.__testExport(exports[7], 
						  bldInfMakefilePathTestRoot+'bld.infs/export8.h', 
						  bldInfMakefilePathTestRoot+'bld.infs/export_test_rel/export8.h', 
						  'copy')

		# :zip export9.zip
		self.__testExport(exports[8], 
						  bldInfMakefilePathTestRoot+'bld.infs/export9.zip', 
						  '$(EPOCROOT)', 
						  'unzip')

		# :zip export10.zip		export_test
		self.__testExport(exports[9], 
						  bldInfMakefilePathTestRoot+'bld.infs/export10.zip', 
						  '$(EPOCROOT)/export_test', 
						  'unzip')

		# :zip export11.zip		/export_test
		self.__testExport(exports[10], 
						  bldInfMakefilePathTestRoot+'bld.infs/export11.zip', 
						  self.__OSRoot+'/export_test', 
						  'unzip')

		# :zip export12.zip		/epoc32/export_test
		self.__testExport(exports[11], 
						  bldInfMakefilePathTestRoot+'bld.infs/export12.zip', 
						  '$(EPOCROOT)/epoc32/export_test', 
						  'unzip')
 
		# export13.rsc			z:/resource/app/export13.rsc
		# Once for each of the three locations for emulated drives
		# epoc32/data/z/resource/app/export13.rsc *and* in
		# epoc32/release/winscw/udeb/z/resource/app/export13.rsc *and* in
		# epoc32/release/winscw/urel/z/resource/app/export13.rsc
		self.__testExport(exports[12], 
						  bldInfMakefilePathTestRoot+'bld.infs/export13.rsc', 
						  '$(EPOCROOT)/epoc32/data/z/resource/app/export13.rsc', 
						  'copy')
		
		self.__testExport(exports[12], 
						  bldInfMakefilePathTestRoot+'bld.infs/export13.rsc', 
						  '$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/app/export13.rsc', 
						  'copy')
		
		self.__testExport(exports[12], 
						  bldInfMakefilePathTestRoot+'bld.infs/export13.rsc', 
						  '$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/app/export13.rsc', 
						  'copy')
		

		testExports = bldInfObject.getTestExports(self.defaultPlatform)
		
		# testexport1.h
		self.__testExport(testExports[0], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport1.h', 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport1.h', 
						  'copy')
		
		# testexport2.h				export_test_rel\testexport2.h
		self.__testExport(testExports[1], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport2.h', 
						  bldInfMakefilePathTestRoot+'bld.infs/export_test_rel/testexport2.h', 
						  'copy')

		# testexport3.h				..\export_test_rel\testexport3.h
		self.__testExport(testExports[2], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport3.h', 
						  bldInfMakefilePathTestRoot+'export_test_rel/testexport3.h', 
						  'copy')

		# testexport4.h				\export_test_abs\testexport4.h
		self.__testExport(testExports[3], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport4.h', 
						  self.__OSRoot+'/export_test_abs/testexport4.h', 
						  'copy')

		# testexport5.h				\epoc32\export_test_abs\testexport5.h
		self.__testExport(testExports[4], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport5.h', 
						  '$(EPOCROOT)/epoc32/export_test_abs/testexport5.h', 
						  'copy')

		# testexport6.h				|..\export_test_rel\testexport6.h
		self.__testExport(testExports[5], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport6.h', 
						  bldInfMakefilePathTestRoot+'export_test_rel/testexport6.h', 
						  'copy')

		# testexport7.h				|\export_test_rel\testexport7.h
		self.__testExport(testExports[6], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport7.h', 
						  bldInfMakefilePathTestRoot+'bld.infs/export_test_rel/testexport7.h', 
						  'copy')

		# testexport8.h				|export_test_rel\testexport8.h
		self.__testExport(testExports[7], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport8.h', 
						  bldInfMakefilePathTestRoot+'bld.infs/export_test_rel/testexport8.h', 
						  'copy')

		# :zip testexport9.zip
		self.__testExport(testExports[8], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport9.zip', 
						  '$(EPOCROOT)', 
						  'unzip')

		# :zip testexport10.zip		export_test
		self.__testExport(testExports[9], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport10.zip', 
						  '$(EPOCROOT)/export_test', 
						  'unzip')

		# :zip testexport11.zip		/export_test
		self.__testExport(testExports[10], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport11.zip', 
						  self.__OSRoot+'/export_test', 
						  'unzip')

		# :zip testexport12.zip		/epoc32/export_test
		self.__testExport(testExports[11], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport12.zip', 
						  '$(EPOCROOT)/epoc32/export_test', 
						  'unzip')

		# testexport13.rsc		z:/resource/app/testexport13.rsc
		# Once for each of the three locations for emulated drives
		# epoc32/data/z/resource/app/testexport13.rsc *and* in
		# epoc32/release/winscw/udeb/z/resource/app/testexport13.rsc *and* in
		# epoc32/release/winscw/urel/z/resource/app/testexport13.rsc
		self.__testExport(testExports[12], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport13.rsc', 
						  '$(EPOCROOT)/epoc32/data/z/resource/app/testexport13.rsc', 
						  'copy')
		
		self.__testExport(testExports[12], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport13.rsc', 
						  '$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/app/testexport13.rsc', 
						  'copy')
		
		self.__testExport(testExports[12], 
						  bldInfMakefilePathTestRoot+'bld.infs/testexport13.rsc', 
						  '$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/app/testexport13.rsc', 
						  'copy')


	def __testExtension(self, aExtensionObject, aMakefile, aTestParameters):
		
		templateExtensionRoot = ""
		
		if not aMakefile.startswith("$("):
			templateExtensionRoot = '$(MAKEFILE_TEMPLATES)/'
			
		self.assertEquals(aExtensionObject.getMakefile(), templateExtensionRoot+aMakefile)
		
		testOptions = aExtensionObject.getOptions()
		testVariables = aExtensionObject.getStandardVariables()
		
		for testParameter in aTestParameters.keys():
			if (testParameter.startswith("STDVAR_")):
				stdvar = testParameter.replace("STDVAR_", "")
				stdvalue = aTestParameters.get(testParameter)
				self.assertTrue(testVariables.has_key(stdvar))
				self.assertEquals(testVariables.get(stdvar), aTestParameters.get(testParameter))
			else:
				self.assertTrue(testOptions.has_key(testParameter))
				self.assertEquals(testOptions.get(testParameter), aTestParameters.get(testParameter))

	def testBldInfExtensions(self):
		bldInfTestRoot = self.__testRoot.Append('metadata/project/bld.infs')
		bldInfMakefilePathTestRoot = str(self.__makefilePathTestRoot)+'/metadata/project/bld.infs'			
		depfiles = []
		bldInfObject = raptor_meta.BldInfFile(bldInfTestRoot.Append('extensions.inf'),
											  self.__gnucpp, depfiles=depfiles, log=self.raptor)
		
		extensions = bldInfObject.getExtensions(self.ARMV5)
		
		self.__testExtension(extensions[0],
							'test/dummyextension1.mk',
							{'TARGET':'dummyoutput1.exe',
							'SOURCES':'dummysource11.cpp dummysource12.cpp dummysource13.cpp',
							'DEPENDENCIES':'dummylib11.lib dummylib12.lib',
							'TOOL':'dummytool1.exe',
							'OPTION11':'option11value',
							'OPTION12':'$(MAKE_VAR)',
							'STDVAR_TO_ROOT':"",
							'STDVAR_TO_BLDINF':bldInfMakefilePathTestRoot,
							'STDVAR_EXTENSION_ROOT':bldInfMakefilePathTestRoot}		
							)
		
		self.__testExtension(extensions[1],
							'test/dummyextension2.mk',
							{'TARGET':'dummyoutput2.exe',
							'SOURCES':'dummysource21.cpp dummysource22.cpp dummysource23.cpp',
							'DEPENDENCIES':'dummylib21.lib dummylib22.lib',
							'TOOL':'dummytool2.exe',
							'OPTION21':'option21value',
							'OPTION22':'$(MAKE_VAR)',
							'STDVAR_TO_ROOT':"",
							'STDVAR_TO_BLDINF':bldInfMakefilePathTestRoot,
							'STDVAR_EXTENSION_ROOT':bldInfMakefilePathTestRoot}
							)
		
		self.__testExtension(extensions[2],
							'$(' + raptor.env + ')/test/dummyextension3.mk',
							{'TARGET':'dummyoutput3.exe',
							'SOURCES':'dummysource31.cpp dummysource32.cpp dummysource33.cpp',
							'DEPENDENCIES':'dummylib31.lib dummylib32.lib',
							'TOOL':'dummytool3.exe',
							'OPTION31':'option31value',
							'OPTION32':'$(MAKE_VAR)',
							'STDVAR_TO_ROOT':"",
							'STDVAR_TO_BLDINF':bldInfMakefilePathTestRoot,
							'STDVAR_EXTENSION_ROOT':bldInfMakefilePathTestRoot}
							)
		
		testExtensions = bldInfObject.getTestExtensions(self.ARMV5)

		self.__testExtension(testExtensions[0],
							'test/dummytestextension1.mk',
							{'TARGET':'dummytestoutput1.exe',
							'SOURCES':'dummytestsource11.cpp dummytestsource12.cpp dummytestsource13.cpp',
							'DEPENDENCIES':'dummytestlib11.lib dummytestlib12.lib',
							'TOOL':'dummytesttool1.exe',
							'OPTIONTEST11':'optiontest11value',
							'OPTIONTEST12':'$(MAKE_VAR)',
							'STDVAR_TO_ROOT':"",
							'STDVAR_TO_BLDINF':bldInfMakefilePathTestRoot,
							'STDVAR_EXTENSION_ROOT':bldInfMakefilePathTestRoot}		
							)

		self.__testExtension(testExtensions[1],
							'test/dummytestextension2.mk',
							{'TARGET':'dummytestoutput2.exe',
							'SOURCES':'dummytestsource21.cpp dummytestsource22.cpp dummytestsource23.cpp',
							'DEPENDENCIES':'dummytestlib21.lib dummytestlib22.lib',
							'TOOL':'dummytesttool2.exe',
							'OPTIONTEST21':'optiontest21value',
							'OPTIONTEST22':'$(MAKE_VAR)',
							'STDVAR_TO_ROOT':"",
							'STDVAR_TO_BLDINF':bldInfMakefilePathTestRoot,
							'STDVAR_EXTENSION_ROOT':bldInfMakefilePathTestRoot}		
							)
		
	def testBldInfIncludes(self):
		bldInfTestRoot = self.__testRoot.Append('metadata/project/bld.infs/includes')
		depfiles=[]
		bldInfObject = raptor_meta.BldInfFile(bldInfTestRoot.Append('top_level.inf'),
											  self.__gnucpp, depfiles=depfiles, log=self.raptor)
		Root = str(bldInfTestRoot)
		
		mmpFiles = bldInfObject.getMMPList(self.ARMV5)
		self.assertEquals(len(mmpFiles['mmpFileList']), 3)	
		self.assertEquals(str(mmpFiles['mmpFileList'][0].filename), Root + "/dir3/down_dir.mmp")
		self.assertEquals(str(mmpFiles['mmpFileList'][1].filename), Root + "/dir1/dir2/up_dir.mmp")
		self.assertEquals(str(mmpFiles['mmpFileList'][2].filename), Root + "/top_level.mmp")

		exports = bldInfObject.getExports(self.ARMV5)
		self.assertEquals(exports[0].getSource(), Root + "/dir3/down_dir_export_source.h")
		self.assertEquals(exports[1].getSource(), Root + "/dir1/dir2/up_dir_export_source.h")
		self.assertEquals(exports[2].getSource(), Root + "/top_level_export_source.h")

	def testMmpIncludes(self):
		mmpTestRoot = self.__testRoot.Append('metadata/project/mmps/includes')
		mmpMakefilePathTestRoot = str(self.__makefilePathTestRoot)+'/metadata/project/mmps/includes'

		depfiles=[]
		bldInfObject = raptor_meta.BldInfFile(mmpTestRoot.Append('top_level.inf'),
										 self.__gnucpp, depfiles=depfiles, log=self.raptor)
		
		mmpFiles = bldInfObject.getMMPList(self.ARMV5)
		mmpdeps = []
		mmpFile = raptor_meta.MMPFile(mmpFiles['mmpFileList'][0].filename, 
										   self.__gnucpp,
										   bldInfObject,
									           depfiles=mmpdeps,
										   log=self.raptor)
		
		self.assertEquals(str(mmpFile.filename), 
						  str(mmpTestRoot.Append("top_level.mmp")))
	
	
		mmpContent = mmpFile.getContent(self.ARMV5)
		mmpBackend = raptor_meta.MMPRaptorBackend(None, str(mmpFile.filename), str(bldInfObject.filename))
		mmpParser = mmpparser.MMPParser(mmpBackend)
		parseresult = None
		try:
			parseresult = mmpParser.mmp.parseString(mmpContent)
		except Exception,e:
			pass
			
		self.assertTrue(parseresult)
		self.assertEquals(parseresult[0],'MMP')

		mmpBackend.finalise(self.ARMV5)
		
		var = mmpBackend.BuildVariant

		sources = []
		for i in var.ops:
			if i.name == "SOURCE":
				sources.extend(i.value.split(" "))

		self.assertTrue((mmpMakefilePathTestRoot+'/top_level.cpp') in sources)
		self.assertTrue((mmpMakefilePathTestRoot+'/dir1/dir2/up_dir.cpp') in sources)
		self.assertTrue((mmpMakefilePathTestRoot+'/dir3/down_dir.cpp') in sources)
	
	
	def testDefFileResolution(self):
		
		class DefFileTest(object):
			""" Test resolveDefFile for a particular set of mmp options """
			def __init__(self, resolveddeffile, mmpfilename, deffilekeyword, target, nostrictdef, platform):
				self.resolveddeffile = resolveddeffile
				self.mmpfilename=mmpfilename
				self.deffilekeyword=deffilekeyword
				self.target=target
				self.nostrictdef = nostrictdef
				self.platform = platform
		
			def test(self, raptor):
				m = raptor_meta.MMPRaptorBackend(raptor, self.mmpfilename, "")
				m.deffile = self.deffilekeyword
				m.nostrictdef = self.nostrictdef
				f = m.resolveDefFile(self.target, self.platform)
				
				return path_compare_notdrivelettercase(self.resolveddeffile,f)
		
		defFileTests = []
		
		for testPlat in self.testPlats:			
			epocroot = str(testPlat['EPOCROOT'])
			releaseDir = testPlat['PLATFORM'].lower()
			defFileDir = "eabi"
			if testPlat['PLATFORM'] == "WINSCW":
				defFileDir = "bwins"
							
			defFileTests.extend([
				DefFileTest(
					self.__OSRoot+'/test/'+defFileDir+'/targetu.def',
					'/test/component/mmpfile.mmp',
					'',
					'target.exe',
					False,
					testPlat),
				DefFileTest(
					self.__OSRoot+'/test/'+defFileDir+'/target.def',
					'/test/component/mmpfile.mmp',
					'',
					'target.exe',
					True,
					testPlat),
				DefFileTest(
					self.__OSRoot+'/test/'+defFileDir+'/targetu.DEF',
					'/test/component/mmpfile.mmp',
					'target.DEF',
					'target.exe',
					False,
					testPlat),
				DefFileTest(
					self.__OSRoot+'/test/'+defFileDir+'/target2.DEF',
					'/test/component/mmpfile.mmp',
					'target2.DEF',
					'target.exe',
					True,
					testPlat),
				DefFileTest(
					self.__OSRoot+'/test/component/target2u.DEF',
					'/test/component/mmpfile.mmp',
					'./target2.DEF',
					'target.exe',
					False,
					testPlat),
				DefFileTest(
					self.__OSRoot+'/test/component/target2.DEF',
					'/test/component/mmpfile.mmp',
					'./target2.DEF',
					'target.exe',
					True,
					testPlat),
				DefFileTest(
					self.__OSRoot+'/test/component/'+defFileDir+'/target3u.DEF',
					'/test/component/mmpfile.mmp',
					'./~/target3.DEF',
					'target.exe',
					False,
					testPlat),
				DefFileTest(
					epocroot+'/epoc32/include/def/'+defFileDir+'/targetu.def',
					'/test/component/mmpfile.mmp',
					'/epoc32/include/def/~/target.def',
					'target.exe',
					False,
					testPlat),
				DefFileTest(
					epocroot+'/epoc32/release/'+releaseDir+'/target.def',
					'/test/component/mmpfile.mmp',
					'/epoc32/release/'+releaseDir+'/target.def',
					'target.exe',
					True,
					testPlat),
				DefFileTest(
					self.__OSRoot+'/deffiles/targetu.def',
					'/test/component/mmpfile.mmp',
					'/deffiles/target.def',
					'target.exe',
					False,
					testPlat)
				])
		
		for t in defFileTests:
			result = t.test(self.raptor)
			self.assertEquals(result, True)
	
	def dummyMetaReader(self):
		"make raptor_meta.MetaReader.__init__ into a none operation"
		self.savedInit = raptor_meta.MetaReader.__init__

		def DummyMetaReaderInit(self, aRaptor):
			self._MetaReader__Raptor = aRaptor

		raptor_meta.MetaReader.__init__ = DummyMetaReaderInit

	def restoreMetaReader(self):
		"make raptor_meta.MetaReader.__init__ operational again"
		raptor_meta.MetaReader.__init__ = self.savedInit

	def testApplyOsVariant(self):
		self.dummyMetaReader()

		# Mock output class
		class OutputMock(object):
			def write(self, text):
				pass
				
		bu = raptor_data.BuildUnit("os_variant", [])
					
		self.raptor.keepGoing = False
		
		metaReader = raptor_meta.MetaReader(self.raptor)
		metaReader.ApplyOSVariant(bu, ".")

		self.raptor.keepGoing = True
		self.raptor.out = OutputMock()
		metaReader = raptor_meta.MetaReader(self.raptor)	
		metaReader.ApplyOSVariant(bu, ".")

		self.restoreMetaReader()

	def __assertEqualStringList(self, aListOne, aListTwo):
		self.assertEquals(len(aListOne), len(aListTwo))
		
		i = 0
		while i < len(aListOne) :
			self.assertEquals(aListOne[i], aListTwo[i])
			i = i + 1
		
	def testOptionReplace(self):
		# Test how we resolve known permutations of values given to the .mmp file OPTION_REPLACE keyword
		mockBackend = raptor_meta.MMPRaptorBackend(self.raptor, "somefile.mmp", "")
		
		results = mockBackend.resolveOptionReplace('--argA')
		self.__assertEqualStringList(results, ['--argA<->'])

		results = mockBackend.resolveOptionReplace('--argB value')
		self.__assertEqualStringList(results, ['--argB%20<->@@', '@@%<->--argB%20value'])
		
		results = mockBackend.resolveOptionReplace('--argD value1 --argE')
		self.__assertEqualStringList(results, ['--argD%20<->@@', '@@%<->--argD%20value1', '--argE<->'])
		
		results = mockBackend.resolveOptionReplace('--argF --argG')
		self.__assertEqualStringList(results, ['--argF<->--argG'])
		
		results = mockBackend.resolveOptionReplace('--argH --argI value')
		self.__assertEqualStringList(results, ['--argH<->--argI%20value'])
		
		results = mockBackend.resolveOptionReplace('--argJ value1 --argK value2')
		self.__assertEqualStringList(results, ['--argJ%20<->@@', '@@%<->--argJ%20value1', '--argK%20<->@@', '@@%<->--argK%20value2'])		
		
		results = mockBackend.resolveOptionReplace('--argL value1 --argM value2 --argN --argO')
		self.__assertEqualStringList(results, ['--argL%20<->@@', '@@%<->--argL%20value1', '--argM%20<->@@', '@@%<->--argM%20value2', '--argN<->--argO'])		
		
		results = mockBackend.resolveOptionReplace('--argP value1 value2 --argQ value3 value4')
		self.__assertEqualStringList(results, ['--argP%20<->@@', '@@%<->--argP%20value1', '--argQ%20<->@@', '@@%<->--argQ%20value3'])		
		
		results = mockBackend.resolveOptionReplace('value1 value2')
		self.__assertEqualStringList(results, [])

		results = mockBackend.resolveOptionReplace('value1 --argR')
		self.__assertEqualStringList(results, ['--argR<->'])
		
		results = mockBackend.resolveOptionReplace('-singleHyphenargS value1 -singleHyphenargT value2')
		self.__assertEqualStringList(results, ['-singleHyphenargS%20<->@@', '@@%<->-singleHyphenargS%20value1', '-singleHyphenargT%20<->@@', '@@%<->-singleHyphenargT%20value2'])

		results = mockBackend.resolveOptionReplace('--assignmentArgU=value1 --assignmentArgV=value2')
		self.__assertEqualStringList(results, ['--assignmentArgU=value1<->--assignmentArgV=value2'])
	
	def testModuleName(self):
		self.dummyMetaReader()

		# Test how we resolve known permutations of values given to the .mmp file OPTION_REPLACE keyword
		mockBackend = raptor_meta.MetaReader(self.raptor)
		
		resultsDictList = [ {"bldinf":"Z:/src/romfile/group/tb92/GROUP/bld.inf", "result":"romfile"},
				    {"bldinf":"/src/romfile/group/tb92/GROUP/bld.inf", "result":"romfile"},
				    {"bldinf":"Z:/src/romFile/group/tb92/GROUP/another.inf", "result":"romFile"},
				    {"bldinf":"X:/src/RoMfile/group/bld.inf", "result":"RoMfile"},
				    {"bldinf":"w:/contacts/group/ONgoing/group/bld.inf", "result":"contacts"},
				    {"bldinf":"p:/group/bld.inf", "result":"module"},
				    {"bldinf":"/group/bld.inf", "result":"module"},
				    {"bldinf":"p:/ONGOING/bld.inf", "result":"module"},
				    {"bldinf":"/ONGOING/bld.inf", "result":"module"}
				    ]

		for result in resultsDictList:
			moduleName = mockBackend.ModuleName(result["bldinf"])
			self.assertEquals(moduleName, result["result"])

		self.restoreMetaReader()


def path_compare_notdrivelettercase(aRequirement, aCandidate):
	if sys.platform.startswith("win"):
		if aRequirement[1] == ":":
			aRequirement = aRequirement[0].lower() + aRequirement[1:]
			aCandidate = aCandidate[0].lower() + aCandidate[1:]

	return aRequirement == aCandidate

		
# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "raptor_meta_unit"

	tests = unittest.makeSuite(TestRaptorMeta)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
