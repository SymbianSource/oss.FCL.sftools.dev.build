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

# Unit Test for the Raptor_cli (command line interface) module

import raptor_cli
import sys
import unittest
import os,subprocess
import re

class TestRaptorCli(unittest.TestCase):

	def setUp(self):
		sbsHome = os.environ["SBS_HOME"]
		self.windows = sys.platform.lower().startswith("win")
		
		self.doExportsOnly = False
		self.whatDir = sbsHome + "/test/simple"
		self.listconfig=[]
		self.bldinfvalue=[]
		self.makeoptions=[]
		self.sysdeflayers=[]
		self.sysdeforderlayers = True
		self.whatlist = []
		self.targets = []
		self.regexpwin = re.compile(r"^[A-Za-z]:\\",re.I)
		self.RunningQuiet = False
		self.allowCommandLineOverrides = True
		self.ignoreOsDetection = False
		self.filterList = "filter_terminal,filter_logfile"
		self.noDependInclude = False
		self.noDependGenerate = False
		
	def AddConfigName(self,configname):
		self.listconfig.append(configname)
		return True

	def AddConfigList(self,configlist):
		return True

	def AddSpecFile(self,specfilename):
		self.listspec.append(specfilename)
		return True

	def SetRoot(self,root):
		self.rootvalue = root
		return True
	
	def SetCheck(self,check):
		self.doCheck = check
		return True
	
	def SetWhat(self,what):
		self.doWhat = what
		return True
	
	def SetTries(self,tries):
		self.tries = tries
		return True
		
	def SetSysDefFile(self,sysdef):
		self.sysdefvalue = sysdef
		return True
			
	def SetSysDefBase(self,sysdefbase):
		self.sysdefbasevalue = sysdefbase
		return True

	def AddSysDefLayer(self,sysdeflayer):
		self.sysdeflayers.append(sysdeflayer)
		return True

	def SetSysDefOrderLayers(self,sysdeforderlayers):
		self.sysdeflayers = sysdeforderlayers
		return True

	def AddBuildInfoFile(self,bldinf):
		self.bldinfvalue.append(bldinf)
		return True

	def RunQuietly(self,QuietMode):
		self.RunningQuiet = QuietMode
		return True

	def SetTopMakefile(self,topmake):
		self.topmake = topmake
		return True
	
	def SetLogFileName(self, logfile):
		self.logFileName = logfile
		return True
		
	def SetMakeEngine(self, engine):
		self.makeEngine = engine
		return True
		
	def AddMakeOption(self, makeOption):
		self.makeOptions.append(makeOption)
		return True
			
	def SetDebugOutput(self, filename):
		return True
		
	def SetExportOnly(self, yesOrNo):
		self.doExportOnly = yesOrNo
		return True

	def SetNoExport(self, yesOrNo):
		self.doExport = not yesOrNo
		return True
	
	def SetKeepGoing(self, yesOrNo):
		return True
	
	def SetNoBuild(self, yesOrNo):
		return True
	
	def SetNoDependInclude(self, yesOrNo):
		self.noDependInclude = yesOrNo
		return True

	def SetNoDependGenerate(self, yesOrNo):
		self.noDependGenerate = yesOrNo
		return True
		
	def SetJobs(self, N):
		return True

	def SetToolCheck(self, toolcheck):
		return True
	
	def SetTiming(self, yesOrNo):
		return True

	def SetParallelParsing(self, onoroff):
		self.pp=onoroff
		return True

	def AddProject(self, project):
		return True

	def AddQuery(self, query):
		return True
	
	def PrintVersion(self):
		return True
			 			 
	def Info(self, format, *extras):
		"Send an information message to the configured channel"
		if self.RunningQuiet==False:
			sys.stdout.write(("INFO: " + format + "\n") % extras)

	def Warn(self, format, *extras):
		"Send a warning message to the configured channel"
		sys.stdout.write(("WARNING: " + format + "\n") % extras)
		
	def IgnoreOsDetection(self, value):
		self.ignoreOsDetection = value
		return True
	
	def FilterList(self, value):
		self.filterList = value
		return True
	
	def AddSourceTarget(self, filename):
		self.targets.append(filename)
	
	def testDoRaptor(self):
		args = ['-c','config1',
				'-c','config name with spaces',
				'-s', 'wrong_file.xml',
				'--sysdef', 'system_definition.xml',
				'-a', 'wrong_base_dir',
				'--sysdefbase', 'C:\definitions',
				'-l', 'a_layer',
				'--layer', 'b_layer',
				'-b', 'bld1.inf',
				'--bldinf', 'bld2.inf',
				'-f', 'a_log_file.log',
				'-m', 'top.mk',
				'--makefile', '/home/Makefile',
				'--filters', 'filter_01,filter_02',
				'--export-only',
				'--source-target', 'some_source_file.cpp',
				'--source-target', 'some_resource_file.rss',
				'--pp', 'on',
				'--no-depend-include',
				'--no-depend-generate']
		
		raptor_cli.GetArgs(self,args)
		self.assertEqual(self.RunningQuiet,False)
		self.assertEqual(self.listconfig[0],'config1')
		self.assertEqual(self.listconfig[1],'config name with spaces')
		self.assertEqual(self.sysdefvalue,'system_definition.xml')
		self.assertEqual(self.sysdefbasevalue,'C:\\definitions')
		self.assertEqual(self.sysdeflayers[0],'a_layer')
		self.assertEqual(self.sysdeflayers[1],'b_layer')
		self.assertEqual(self.bldinfvalue[0],'bld1.inf')
		self.assertEqual(self.bldinfvalue[1],'bld2.inf')
		self.assertEqual(self.topmake,'/home/Makefile')
		self.assertEqual(self.logFileName,'a_log_file.log')
		self.assertEqual(self.filterList,'filter_01,filter_02')
		self.assertEqual(self.doExportOnly,True)
		self.assertEqual(self.targets[0], 'some_source_file.cpp')
		self.assertEqual(self.targets[1], 'some_resource_file.rss')
		self.assertEqual(self.pp, 'on')
		self.assertEqual(self.noDependInclude, True)
		self.assertEqual(self.noDependGenerate, True)

# run all the tests

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "999"
	t.name = "raptor_cli_unit"

	tests = unittest.makeSuite(TestRaptorCli)
	result = unittest.TextTestRunner(verbosity=2).run(tests)

	if result.wasSuccessful():
		t.result = SmokeTest.PASS
	else:
		t.result = SmokeTest.FAIL

	return t
