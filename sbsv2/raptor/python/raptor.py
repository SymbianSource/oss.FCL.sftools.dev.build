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
# raptor module
# This module represents the running Raptor program. Raptor is started
# either by calling the Main() function, which creates an instance of
# the raptor.Raptor class and calls its methods to perform a build based
# on command-line parameters, or by explicitly creating a raptor.Raptor
# instance and calling its methods to set-up and perform a build.
#

name = "sbs"			# the public name for the raptor build tool
env  = "SBS_HOME"		# the environment variable that locates us
xml  = "sbs_init.xml"	# the primary initialisation file
env2 = "HOME"		 	# the environment variable that locates the user
xml2 = ".sbs_init.xml"	# the override initialisation file

import generic_path
import os
import raptor_cache
import raptor_cli
import raptor_data
import raptor_make
import raptor_meta
import raptor_utilities
import raptor_version
import raptor_xml
import filter_list
import sys
import types
import time
import re
import traceback
import pluginbox
from xml.sax.saxutils import escape


if not "HOSTPLATFORM" in os.environ or not "HOSTPLATFORM_DIR" in os.environ:
	print "Error: HOSTPLATFORM and HOSTPLATFORM_DIR must be set in the environment (this is usually done automatically by the startup script)."
	sys.exit(1)

hostplatform = os.environ["HOSTPLATFORM"].split(" ")
hostplatform_dir = os.environ["HOSTPLATFORM_DIR"]

# defaults can use EPOCROOT
if "EPOCROOT" in os.environ:
	epocroot = os.environ["EPOCROOT"].replace("\\","/")
else:
	if 'linux' in hostplatform:
		epocroot=os.environ['HOME'] + os.sep + "epocroot"
		os.environ["EPOCROOT"] = epocroot
	else:
		epocroot = "/"
		os.environ["EPOCROOT"] = os.sep

if "SBS_BUILD_DIR" in os.environ:
	sbs_build_dir = os.environ["SBS_BUILD_DIR"]
else:
	sbs_build_dir = (epocroot + "/epoc32/build").replace("//","/")



# only use default XML from the epoc32 tree if it exists
defaultSystemConfig = "lib/config"
epoc32UserConfigDir = generic_path.Join(epocroot, "epoc32/sbs_config")
if epoc32UserConfigDir.isDir():
	defaultSystemConfig = str(epoc32UserConfigDir) + os.pathsep + defaultSystemConfig

# parameters that can be overriden by the sbs_init.xml file
# or by the command-line.
defaults = {
		"allowCommandLineOverrides" : True,
		"CLI" : "raptor_cli",
		"buildInformation" : generic_path.Path("bld.inf"),
		"defaultConfig" : "default",
		"jobs": 4,
		"keepGoing": False,
		"logFileName" : generic_path.Join(sbs_build_dir,"Makefile.%TIME.log"),
		"makeEngine" : "make",
		"preferBuildInfoToSystemDefinition" : False,
		"pruneDuplicateMakefiles": True,
		"quiet" : False,
		"systemConfig" :  defaultSystemConfig,
		"systemDefinition" : generic_path.Path("System_Definition.xml"),
		"systemDefinitionBase" : generic_path.Path("."),
		"systemFLM" : generic_path.Path("lib/flm"),
		"systemPlugins" : generic_path.Path("python/plugins"),
		"topMakefile" : generic_path.Join(sbs_build_dir,"Makefile"),
		"tries": 1,
		"writeSingleMakefile": True,
		"ignoreOsDetection": False,
		"toolcheck": "on",
		"filterList": "filterterminal,filterlogfile"
		}


class ComponentGroup(object):
	""" 	Some components that should be built togther 
		e.g. a Layer in the system definition. 
	""" 
	def __init__(self, name, componentlist=[]):
		self.components = componentlist
		self.name = name

	def __iter__(self):
		return iter(self.components)

	def __getitem__(self,x):
		if isinstance(x, slice):
			return self.components[x.start:x.stop]
		return self.components[x]

	def __setitem__(self,k, v):
		self.components[k] = v

	def __len__(self):
		return len(self.components)

	def extend(self, c):
		self.components.extend(c)
	
	def append(self, c):
		self.components.append(c)

	def GenerateSpecs(self, genericspecs, configs):
		"""Return a build spec hierarchy for a ComponentGroup. This involves parsing the component MetaData (bld.infs, mmps). 
		Takes a raptor object as a parameter (build), together with a list of Configurations.

		Returns a tuple consisting of a list of specification objects and a list of dependency files
		that relate to these specs.
		"""

		self.specs = []
		self.specs.extend(genericspecs)
		self.configs = configs
		self.dependencies = set()

		metaReader = None
		if len (self.components):
			try:
				# create a MetaReader that is aware of the list of
				# configurations that we are trying to build.
				metaReader = raptor_meta.MetaReader(build, configs)

				# convert the list of bld.inf files into a specification
				# hierarchy suitable for all the configurations we are using.
				self.specs.extend(metaReader.ReadBldInfFiles(self.components,build.doExportOnly))

			except raptor_meta.MetaDataError, e:
				log.Error(e.Text)

		log.Info("Buildable specification group '%s'", name)
		build.AttachSpecs(self.specs)

		# Get a unique list of the dependency files that were created
		if metaReader:
			for c in metaReader.BuildPlatforms:
				self.dependencies.update(c["METADEPS"])


	def CreateMakefile(self, makefilename_base, engine, named = False):
		if len(self.specs) <= 0:
			return None

		if named:
			makefile = generic_path.Path(str(makefilename_base) + "_" + raptor_utilities.sanitise(self.name))
		else:
			makefile = generic_path.Path(str(makefilename_base))

		# insert the start time into the Makefile name?
		makefile.path = makefile.path.replace("%TIME", build.timestring)

		engine.Write(makefile, self.specs, self.configs)

		return makefile


	def GenerateMetadataSpecs(self, configs):
		# insert the start time into the Makefile name?

		self.configs = build.GetConfig("build").GenerateBuildUnits()

		# Pass certain CLI flags through to the makefile-generating sbs calls
		cli_options = ""
			
		if build.debugOutput == True:
			cli_options += " -d"
				
		if build.ignoreOsDetection == True:
			cli_options += " -i"
			
		if build.keepGoing == True:
			cli_options += " -k"
			
		if build.quiet == True:
			cli_options += " -q"

		
		nc = len(self.components)
		number_blocks = 16
		block_size = (nc / number_blocks) + 1
		component_blocks = []
		spec_nodes = []
		
		b = 0
		while b < nc:
			component_blocks.append(self.components[b:b+block_size])
			b += block_size
			
		if len(component_blocks[-1]) <= 0:
			component_blocks.pop()
		
		loop_number = 0
		for block in component_blocks:
			loop_number += 1
			specNode = raptor_data.Specification("metadata_" + self.name)

			componentList = " ".join([str(c) for c in block])
			configList = " ".join([c.name for c in configs])
			
			makefile_path = str(build.topMakefile) + "_" + str(loop_number)
			try:
				os.unlink(makefile_path) # until we have dependencies working properly
			except Exception,e:
				# print "couldn't unlink %s: %s" %(componentMakefileName, str(e))
				pass
			
			# add some basic data in a component-wide variant
			var = raptor_data.Variant()
			var.AddOperation(raptor_data.Set("COMPONENT_PATHS", componentList))
			var.AddOperation(raptor_data.Set("MAKEFILE_PATH", makefile_path))
			var.AddOperation(raptor_data.Set("CONFIGS", configList))
			var.AddOperation(raptor_data.Set("CLI_OPTIONS", cli_options))
			# Pass on '-n' (if specified) to the makefile-generating sbs calls
			if build.noBuild:
				var.AddOperation(raptor_data.Set("NO_BUILD", "1"))
			specNode.AddVariant(var)
	
	
	
			try:
				interface = build.cache.FindNamedInterface("build.makefiles")
				specNode.SetInterface(interface)
			except KeyError:
				build.Error("Can't find flm interface 'build.makefiles' ")
				
			spec_nodes.append(specNode)
			
			

		## possibly some error handling here?

		self.specs = spec_nodes


class BuildCompleteException(Exception):
	pass

# raptor module classes

class Raptor(object):
	"""An instance of a running Raptor program.

	When operated from the command-line there is a single Raptor object
	created by the Main function. When operated by an IDE several Raptor
	objects may be created and operated at the same time."""


	M_BUILD = 1
	M_VERSION = 2	

	def __init__(self, home = None):

		self.DefaultSetUp(home)


	def DefaultSetUp(self, home = None):
		"revert to the default set-up state"
		self.errorCode = 0
		self.skipAll = False
		self.summary = True
		self.out = sys.stdout # Just until filters get started.

		# Create a bootstrap output system.
		self.out = filter_list.FilterList()

		if home == None:
			try:
				home = os.environ[env]
			except KeyError:
				home = os.getcwd()

		# make sure the home directory exists
		self.home = generic_path.Path(home).Absolute()

		if not self.home.isDir():
			self.Error("%s '%s' is not a directory", env, self.home)
			return

		# the set-up file location.
		# use the override "env2/xml2" if it exists
		# else use the primary "env/xml" if it exists
		# else keep the hard-coded defaults.
		self.raptorXML = self.home.Append(xml)

		if env2 in os.environ:
			sbs_init = generic_path.Join(os.environ[env2], xml2)
			if sbs_init.isFile():
				self.raptorXML = sbs_init

		# things that can be overridden by the set-up file
		for key, value in defaults.items():
			self.__dict__[key] = value

		# things to initialise
		self.args = []

		self.componentGroups = []
		self.orderComponentGroups = False
		self.commandlineComponents = []

		self.systemModel = None
		self.systemDefinitionFile = None
		self.systemDefinitionRequestedLayers = []
		self.systemDefinitionOrderLayers = False

		self.specGroups = {}

		self.configNames = []
		self.configsToBuild = set()
		self.makeOptions = []
		self.maker = None
		self.debugOutput = False
		self.doExportOnly = False
		self.noBuild = False
		self.noDependInclude = False
		self.projects = set()

		self.cache = raptor_cache.Cache(self)
		self.override = {env: str(self.home)}
		self.targets = []
		self.defaultTargets = []

		self.doCheck = False
		self.doWhat = False
		self.doParallelParsing = False
		self.mission = Raptor.M_BUILD

		# what platform and filesystem are we running on?
		self.filesystem = raptor_utilities.getOSFileSystem()

		self.toolset = None

		self.starttime = time.time()
		self.timestring = time.strftime("%Y-%m-%d-%H-%M-%S")

		self.fatalErrorState = False

	def AddConfigList(self, configPathList):
		# this function converts cmd line option into a list
		# and prepends it to default config.
		self.configPath = generic_path.NormalisePathList(configPathList.split(os.pathsep)) + self.configPath
		return True

	def AddConfigName(self, name):
		self.configNames.append(name)
		return True

	def RunQuietly(self, TrueOrFalse):
		self.quiet = TrueOrFalse
		return True

	def SetCheck(self, TrueOrFalse):
		self.doCheck = TrueOrFalse
		return True

	def SetWhat(self, TrueOrFalse):
		self.doWhat = TrueOrFalse
		return True

	def SetEnv(self, name, value):
		self.override[name] = value

	def AddTarget(self, target):
		if self.doCheck or self.doWhat:
			self.Warn("ignoring target %s because --what or --check is specified.\n", target)
		else:
			self.targets.append(target)
			
	def AddSourceTarget(self, filename):
		# source targets are sanitised and then added as if they were a "normal" makefile target
		# in addition they have a default, empty, top-level target assigned in order that they can
		# be presented to any generated makefile without error
		sourceTarget = generic_path.Path(filename).Absolute()
		sourceTarget = 'SOURCETARGET_' + raptor_utilities.sanitise(str(sourceTarget))
		self.AddTarget(sourceTarget)
		self.defaultTargets.append(sourceTarget)
		return True

	def SetSysDefFile(self, filename):
		self.systemDefinitionFile = generic_path.Path(filename)
		return True

	def SetSysDefBase(self, path):
		self.systemDefinitionBase = generic_path.Path(path)
		return True

	def AddSysDefLayer(self, layer):
		self.systemDefinitionRequestedLayers.append(layer)
		return True

	def SetSysDefOrderLayers(self, TrueOrFalse):
		self.systemDefinitionOrderLayers = TrueOrFalse
		return True

	def AddBuildInfoFile(self, filename):
		bldinf = generic_path.Path(filename).Absolute()
		self.commandlineComponents.append(bldinf)
		return True

	def SetTopMakefile(self, filename):
		self.topMakefile = generic_path.Path(filename)
		return True

	def SetDebugOutput(self, TrueOrFalse):
		self.debugOutput = TrueOrFalse
		return True

	def SetExportOnly(self, TrueOrFalse):
		self.doExportOnly = TrueOrFalse
		return True

	def SetNoBuild(self, TrueOrFalse):
		self.noBuild = TrueOrFalse
		return True

	def SetNoDependInclude(self, TrueOrFalse):
		self.noDependInclude = TrueOrFalse
		return True
		
	def SetKeepGoing(self, TrueOrFalse):
		self.keepGoing = TrueOrFalse
		return True

	def SetLogFileName(self, logfile):
		if logfile == "-":
			self.logFileName = None  # stdout
		else:
			self.logFileName = generic_path.Path(logfile)
		return True

	def SetMakeEngine(self, makeEngine):
		self.makeEngine = makeEngine
		return True

	def AddMakeOption(self, makeOption):
		self.makeOptions.append(makeOption)
		return True

	def SetJobs(self, numberOfJobs):
		try:
			self.jobs = int(numberOfJobs)
		except ValueError:
			self.jobs = 0

		if self.jobs < 1:
			self.Warn("The number of jobs (%s) must be a positive integer\n", numberOfJobs)
			self.jobs = 1
			return False
		return True

	def SetTries(self, numberOfTries):
		try:
			self.tries = int(numberOfTries)
		except ValueError:
			self.tries = 0

		if self.tries < 1:
			self.Warn("The number of tries (%s) must be a positive integer\n", numberOfTries)
			self.tries = 1
			return False
		return True

	def SetToolCheck(self, type):
		type = type.lower()
		toolcheck_types= [ "forced", "on", "off" ]
		if type in toolcheck_types:
			self.toolcheck=type
		else:
			self.Warn("toolcheck option must be one of: %s" % toolcheck_types)
			return False

		return True

	def SetParallelParsing(self, type):
		type = type.lower()
		if type == "on":
			self.doParallelParsing = True
		elif type == "off":
			self.doParallelParsing = False
		else:
			self.Warn(" parallel parsing option must be either 'on' or 'off' (was %s)"  % type)
			return False

		return True

	def AddProject(self, projectName):
		self.projects.add(projectName.lower())
		return True

	def FilterList(self, value):
		self.filterList = value
		return True

	def IgnoreOsDetection(self, value):
		self.ignoreOsDetection = value
		return True

	def PrintVersion(self,dummy):
		global name
		print name, "version", raptor_version.Version()
		self.mission = Raptor.M_VERSION
		return False

	# worker methods

	def Introduction(self):
		"""Print a header of useful information about Raptor"""

		self.Info("%s: version %s\n", name, raptor_version.Version())

		self.Info("%s %s", env, str(self.home))
		self.Info("Set-up %s", str(self.raptorXML))
		self.Info("Command-line-arguments %s", " ".join(self.args))
		self.Info("Current working directory %s", os.getcwd())
		
		# the inherited environment
		for e, value in os.environ.items():
			self.Info("Environment %s=%s", e, value)

		# and some general debug stuff
		self.Debug("Platform %s", "-".join(hostplatform))
		self.Debug("Filesystem %s", self.filesystem)
		self.Debug("Python %d.%d.%d", *sys.version_info[:3])
		self.Debug("Command-line-parser %s", self.CLI)

		for e,value in self.override.items():
			self.Debug("Override %s = %s", e, value)

		for t in self.targets:
			self.Debug("Target %s", t)


	def ConfigFile(self):
		if not self.raptorXML.isFile():
			return

		self.cache.Load(self.raptorXML)

		# find the 'defaults.raptor' variant and extract the values
		try:
			var = self.cache.FindNamedVariant("defaults.init")
			evaluator = self.GetEvaluator( None, raptor_data.BuildUnit(var.name,[var]) )

			for key, value in defaults.items():
				newValue = evaluator.Resolve(key)

				if newValue != None:
					# got a string for the value
					if type(value) == types.BooleanType:
						newValue = (newValue.lower() != "false")
					elif type(value) == types.IntType:
						newValue = int(newValue)
					elif isinstance(value, generic_path.Path):
						newValue = generic_path.Path(newValue)

					self.__dict__[key] = newValue

		except KeyError:
			# it is OK to not have this but useful to say it wasn't there
			self.Info("No 'defaults.init' configuration found in " + str(self.raptorXML))


	def CommandLine(self, args):
		# remember the arguments for the log
		self.args = args

		# assuming self.CLI = "raptor_cli"
		more_to_do = raptor_cli.GetArgs(self, args)

		# resolve inter-argument dependencies.
		# --what or --check implies the WHAT target and FilterWhat Filter
		if self.doWhat or self.doCheck:
			self.targets = ["WHAT"]
			self.filterList = "filterwhat"

		else:
			# 1. CLEAN/CLEANEXPORT/REALLYCLEAN needs the FilterClean filter.
			# 2. Targets that clean should not be combined with other targets.

			targets = [x.lower() for x in self.targets]

			CL = "clean"
			CE = "cleanexport"
			RC = "reallyclean"

			is_clean = 0
			is_suspicious_clean = 0

			if CL in targets and CE in targets:
				is_clean = 1
				if len(targets) > 2:
					is_suspicious_clean = 1
			elif RC in targets or CL in targets or CE in targets:
				is_clean = 1
				if len(targets) > 1:
					is_suspicious_clean = 1

			if is_clean:
				self.filterList += ",filterclean"
				if is_suspicious_clean:
					self.Warn('CLEAN, CLEANEXPORT and a REALLYCLEAN should not be combined with other targets as the result is unpredictable.')

		if not more_to_do:
			self.skipAll = True		# nothing else to do

	def ProcessConfig(self):
		# this function will perform additional processing of config

		# create list of generic paths
		self.configPath = generic_path.NormalisePathList(self.systemConfig.split(os.pathsep))

	def LoadCache(self):
		def mkAbsolute(aGenericPath):
			""" internal function to make a generic_path.Path
			absolute if required"""
			if not aGenericPath.isAbsolute():
				return self.home.Append(aGenericPath)
			else:
				return aGenericPath
		
		# make generic paths absolute (if required)
		self.configPath = map(mkAbsolute, self.configPath)
		self.cache.Load(self.configPath)

		if not self.systemFLM.isAbsolute():
			self.systemFLM = self.home.Append(self.systemFLM)

		self.cache.Load(self.systemFLM)

	def GetConfig(self, configname):
		names = configname.split(".")

		cache = self.cache

		base = names[0]
		mods = names[1:]

		if base in cache.groups:
			x = cache.FindNamedGroup(base)
		elif base in cache.aliases:
			x = cache.FindNamedAlias(base)
		elif base in cache.variants:
			x = cache.FindNamedVariant(base)
		else:
			raise Exception("Unknown build configuration '%s'" % configname)

		x.ClearModifiers()


		try:
			for m in mods: x.AddModifier( cache.FindNamedVariant(m) )
		except KeyError:
			raise Exception("Unknown build configuration '%s'" % configname)
		return x

	def GetBuildUnitsToBuild(self, configNames):
		"""Return a list of the configuration objects that correspond to the 
		   list of configuration names in the configNames parameter.

		raptor.GetBuildUnitsToBuild(["armv5", "winscw"])
		>>> [ config1, config2, ... , configN ]
		""" 

		if len(configNames) == 0:
			# use default config
			if len(self.defaultConfig) == 0:
				self.Warn("No default configuration name")
			else:
				configNames.append(self.defaultConfig)

		buildUnitsToBuild = set()


		for c in set(configNames):
			try:		
				x = self.GetConfig(c)
				buildUnitsToBuild.update( x.GenerateBuildUnits() )
			except Exception, e:
				self.FatalError(str(e))

		for b in buildUnitsToBuild:
			self.Info("Buildable configuration '%s'", b.name)

		if len(buildUnitsToBuild) == 0:
			self.Error("No build configurations given")

		return buildUnitsToBuild

	def CheckToolset(self, evaluator, configname):
		"""Check the toolset for a particular config, allow other objects access 
		to the toolset for this build (e.g. the raptor_make class)."""
		if self.toolset is None:
			if self.toolcheck == 'on':
				self.toolset = raptor_data.ToolSet(log=self)
			elif self.toolcheck == 'forced' :
				self.toolset = raptor_data.ToolSet(log=self, forced=True)
			else:
				return True

		return self.toolset.check(evaluator, configname)


	def CheckConfigs(self, configs):
		"""	Tool checking for all the buildable configurations
			NB. We are allowed to use different tool versions for different
			configurations."""

		tools_ok = True
		for b in configs:
			self.Debug("Tool check for %s", b.name)
			evaluator = self.GetEvaluator(None, b, gathertools=True)
			tools_ok = tools_ok and self.CheckToolset(evaluator, b.name)

		return tools_ok



	def GatherSysModelLayers(self, systemModel, systemDefinitionRequestedLayers):
		"""Return a list of lists of components to be built.

		components = GatherSysModelLayers(self, configurations)
		>>> set("abc/group/bld.inf","def/group/bld.inf, ....")
		"""
		layersToBuild = []

		if systemModel:
			# We either process all available layers in the system model, or a subset of
			# layers specified on the command line.  In both cases, the processing is the same,
			# and can be subject to ordering if explicitly requested.
			systemModel.DumpInfo()

			if systemDefinitionRequestedLayers:
				layersToProcess = systemDefinitionRequestedLayers
			else:
				layersToProcess = systemModel.GetLayerNames()

			for layer in layersToProcess:
				systemModel.DumpLayerInfo(layer)

				if systemModel.IsLayerBuildable(layer):
					layersToBuild.append(ComponentGroup(layer,
							systemModel.GetLayerComponents(layer)))

		return layersToBuild


	# Add bld.inf or system definition xml to command line componentGroups (depending on preference)
	def FindSysDefIn(self, aDir = None):
		# Find a system definition file

		if aDir is None:
			dir = generic_path.CurrentDir()
		else:
			dir = generic_path.Path(aDir)

		sysDef = dir.Append(self.systemDefinition)
		if not sysDef.isFile():
			return None

		return sysDef


	def FindComponentIn(self, aDir = None):
		# look for a bld.inf 

		if aDir is None:
			dir = generic_path.CurrentDir()
		else:
			dir = generic_path.Path(aDir)

		bldInf = dir.Append(self.buildInformation)
		componentgroup = []

		if bldInf.isFile():
			return bldInf

		return None

	def AttachSpecs(self, groups):
		# tell the specs which Raptor object they work for (so that they can
		# access the cache and issue warnings and errors)
		for spec in groups:
			spec.SetOwner(self)
			self.Info("Buildable specification '%s'", spec.name)
			if self.debugOutput:
				spec.DebugPrint()

	def GenerateGenericSpecs(self, configsToBuild):
		# if a Configuration has any config-wide interfaces
		# then add a Specification node to call each of them.
		configWide = {}
		genericSpecs = []
		for c in configsToBuild:
			evaluator = self.GetEvaluator(None, c)
			iface = evaluator.Get("INTERFACE.config")
			if iface:
				if iface in configWide:
					# seen it already, so reuse the node
					filter = configWide[iface]
					filter.AddConfigCondition(c.name)
				else:
					# create a new node
					filter = raptor_data.Filter("config_wide")
					filter.AddConfigCondition(c.name)
					for i in iface.split():
						spec = raptor_data.Specification(i)
						spec.SetInterface(i)
						filter.AddChildSpecification(spec)
					# remember it, use it
					configWide[iface] = filter
					genericSpecs.append(filter)

		self.AttachSpecs(genericSpecs)

		return genericSpecs


	def WriteMetadataDepsMakefile(self, component_group):
		""" Takes a list of (filename, target) tuples that indicate where """
		# Create a Makefile that includes all the dependency information for this spec group
		build_metamakefile_name = \
				os.path.abspath(sbs_build_dir).replace('\\','/').rstrip('/') + \
				'/metadata_%s.mk' % component_group.name.lower()
		bmkmf = open(build_metamakefile_name, "w+")
		bmkmf.write("# Build Metamakefile - Dependencies for metadata during the 'previous' build\n\n")
		bmkmf.write("PARSETARGET:=%s\n" % build_metamakefile_name)
		bmkmf.write("%s:  \n" % build_metamakefile_name)
		bmkmf.write("\t@echo -e \"\\nRE-RUNNING SBS with previous parameters\"\n")
		bmkmf.write("\t@echo pretend-sbs %s\n" % " ".join(self.args))
		try:
			for m in component_group.dependencies:
				filename, target = m
				bmkmf.write("-include %s\n\n" % filename)
		finally:
			bmkmf.close()

		return build_metamakefile_name


	def GetEvaluator(self, specification, configuration, gathertools=False):
		""" this will perform some caching later """
		return raptor_data.Evaluator(self, specification, configuration, gathertools=gathertools)


	def areMakefilesUptodate(self):
		return False


	def Make(self, makefile):

		if self.maker.Make(makefile):
			self.Info("The make-engine exited successfully.")
			return True
		else:
			self.Error("The make-engine exited with errors.")
			return False


	def Report(self):
		if self.quiet:
			return

		self.endtime = time.time()
		self.runtime = int(0.5 + self.endtime - self.starttime)
		self.raptor_params.runtime = self.runtime
		self.Info("Run time %s seconds" % self.runtime)

	def AssertBuildOK(self):
		"""Raise a BuildCompleteException if no further processing is required
		"""
		if self.Skip():
			raise BuildCompleteException("")

		return True

	def Skip(self):
		"""Indicate not to perform operation if:
		   fatalErrorState is set
		   an error code is set but we're not in keepgoing mode
		"""
		return self.fatalErrorState or ((self.errorCode != 0) and (not self.keepGoing))


	# log file open/close

	def OpenLog(self):
		"""Open a log file for the various I/O methods to write to."""

		try:
			# Find all the raptor plugins and put them into a pluginbox.
			if not self.systemPlugins.isAbsolute():
				self.systemPlugins = self.home.Append(self.systemPlugins)

			self.pbox = pluginbox.PluginBox(str(self.systemPlugins))

			self.raptor_params = BuildStats(self)

			# Open the requested plugins using the pluginbox
			self.out.open(self.raptor_params, self.filterList.split(','), self.pbox)

			# log header
			self.out.write("<?xml version=\"1.0\" encoding=\"ISO-8859-1\" ?>\n")

			namespace = "http://symbian.com/xml/build/log"
			schema = "http://symbian.com/xml/build/log/1_0.xsd"

			self.out.write("<buildlog sbs_version=\"%s\" xmlns=\"%s\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"%s %s\">\n"
						   % (raptor_version.Version(), namespace, namespace, schema))
			self.logOpen = True
		except Exception,e:
			self.out = sys.stdout # make sure that we can actually get errors out.
			self.logOpen = False
			self.FatalError("Unable to open the output logs: %s" % str(e))


	def CloseLog(self):
		if self.logOpen:
			self.out.summary()
			self.out.write("</buildlog>\n")

			if not self.out.close():
				self.errorCode = 1


	def Cleanup(self):
		# ensure that the toolset cache is flushed.
		if self.toolset is not None:
			self.toolset.write()

	# I/O methods

	@staticmethod
	def attributeString(dictionary):
		"turn a dictionary into a string of XML attributes"
		atts = ""
		for a,v in dictionary.items():
			atts += " " + a + "='" + v + "'"
		return atts
	
	def Info(self, format, *extras, **attributes):
		"""Send an information message to the configured channel
				(XML control characters will be escaped)
		"""
		self.out.write("<info" + self.attributeString(attributes) + ">" +
		               escape(format % extras) + "</info>\n")

	def Debug(self, format, *extras, **attributes):
		"Send a debugging message to the configured channel"

		# the debug text is out of our control so wrap it in a CDATA
		# in case it contains characters special to XML... like <>
		if self.debugOutput:
			self.out.write("<debug" + self.attributeString(attributes) + ">" +
			               "><![CDATA[\n" + (format % extras) + "\n]]></debug>\n")

	def Warn(self, format, *extras, **attributes):
		"""Send a warning message to the configured channel
				(XML control characters will be escaped)
		"""
		self.out.write("<warning" + self.attributeString(attributes) + ">" + 
		               escape(format % extras) + "</warning>\n")

	def FatalError(self, format, *extras, **attributes):
		"""Send an error message to the configured channel. This implies such a serious
		   error that the entire build must be shut down asap whilst still finishing off
		   correctly whatever housekeeping is possible e.g. producing error reports.
		   Remains quiet if the raptor object is already in a fatal state since there
		   further errors are probably triggered by the first.
		"""
		if not self.fatalErrorState:
			self.out.write("<error" + self.attributeString(attributes) + ">" + 
			               (format % extras) + "</error>\n")
			self.errorCode = 1
			self.fatalErrorState = True

	def Error(self, format, *extras, **attributes):
		"""Send an error message to the configured channel
				(XML control characters will be escaped)
		"""
		self.out.write("<error" + self.attributeString(attributes) + ">" + 
		               escape(format % extras) + "</error>\n")
		self.errorCode = 1


	def PrintXML(self, format, *extras):
		"Print to configured channel (no newline is added) (assumes valid xml)"
		if format:
			self.out.write(format % extras)


	def MakeComponentGroup(self, cg):
		if not self.maker:
			self.maker = raptor_make.MakeEngine(self)

		if self.maker == None:
			self.Error("No make engine present")
			return None

		makefile = cg.CreateMakefile(self.topMakefile, self.maker, self.systemDefinitionOrderLayers)
		if (not self.noBuild and makefile is not None) \
				or self.doParallelParsing:
			# run the build for a single group of specs
			self.Make(makefile)
		else:
			self.Info("No build performed for %s" % cg.name)

	def GetComponentGroupsFromCLI(self):
		"""Returns the list of componentGroups as specified by the
		   commandline interface to Raptor e.g. parameters
		   or the current directory"""
		componentGroups=[]
		# Look for bld.infs or sysdefs in the current dir if none were specified
		if self.systemDefinitionFile == None and len(self.commandlineComponents) == 0:
			if not self.preferBuildInfoToSystemDefinition:
				cwd = os.getcwd()
				self.systemDefinitionFile = self.FindSysDefIn(cwd)
				if self.systemDefinitionFile == None:
					aComponent = self.FindComponentIn(cwd)
					if aComponent:
						componentGroups.append(ComponentGroup('default',[aComponent]))
			else:
				aComponent = self.FindComponentIn(cwd)
				if aComponent is None:
					self.systemDefinitionFile = self.FindSysDefIn(cwd)
				else:
					componentGroups.append(ComponentGroup('default',[aComponent]))

			if len(componentGroups) <= 0 and  self.systemDefinitionFile == None:
				self.Warn("No default bld.inf or system definition file found in current directory (%s)", cwd)

		# If we now have a System Definition to parse then get the layers of components
		if self.systemDefinitionFile != None:
			systemModel = raptor_xml.SystemModel(self, self.systemDefinitionFile, self.systemDefinitionBase)
			componentGroups = self.GatherSysModelLayers(systemModel, self.systemDefinitionRequestedLayers)
			
		# Now get components specified on a commandline - build them after any
		# layers in the system definition.
		if len(self.commandlineComponents) > 0:
			componentGroups.append(ComponentGroup('commandline',self.commandlineComponents))

		# If we aren't building components in order then flatten down
		# the groups
		if not self.systemDefinitionOrderLayers:
			# Flatten the layers into one group of components if
			# we are not required to build them in order.
			newcg = ComponentGroup("all")
			for cg in componentGroups:
				newcg.extend(cg)
			componentGroups = [newcg]

		return componentGroups

	def Build(self):

		if self.mission != Raptor.M_BUILD: # help or version requested instead.
			return 0

		# open the log file
		self.OpenLog()


		try:
			# show the command and platform info
			self.AssertBuildOK()
			self.Introduction()
			# establish an object cache
			self.AssertBuildOK()
			
			self.LoadCache()

			# find out what configurations to build
			self.AssertBuildOK()
			buildUnitsToBuild = set()
			buildUnitsToBuild = self.GetBuildUnitsToBuild(self.configNames)

			# find out what components to build, and in what way
			componentGroups = []

			self.AssertBuildOK()
			if len(buildUnitsToBuild) >= 0:
				componentGroups = self.GetComponentGroupsFromCLI()

			componentCount = reduce(lambda x,y : x + y, [len(cg) for cg in componentGroups])

			if not componentCount > 0:
				raise BuildCompleteException("No components to build.")

			# check the configurations (tools versions)
			self.AssertBuildOK()

			if self.toolcheck != 'off':
				self.CheckConfigs(buildUnitsToBuild)
			else:
				self.Info(" Not Checking Tool Versions")

			self.AssertBuildOK()


			# if self.doParallelParsing and not (len(componentGroups) == 1 and len(componentGroups[0]) == 1):
			if self.doParallelParsing:
				# Create a Makefile to parse components in parallel and build them
				for cg in componentGroups:
					cg.GenerateMetadataSpecs(buildUnitsToBuild)
					self.MakeComponentGroup(cg)
				if self.noBuild:
					self.Info("No build performed")
			else:
				# Parse components serially, creating one set of makefiles
				# create non-component specs
				self.AssertBuildOK()
				generic_specs = self.GenerateGenericSpecs(buildUnitsToBuild)

				self.AssertBuildOK()
				for cg in componentGroups:
					# create specs for a specific group of components
					cg.GenerateSpecs(generic_specs, buildUnitsToBuild)
					self.WriteMetadataDepsMakefile(cg)	
					
					# generate the makefiles for one group of specs
					self.MakeComponentGroup(cg)

		except BuildCompleteException,b:
			if str(b) != "":
				self.Info(str(b))

		# final report
		if not self.fatalErrorState:
			self.Report()

		self.Cleanup()

		# close the log file
		self.CloseLog()

		return self.errorCode

	@classmethod
	def CreateCommandlineBuild(cls, argv):
		""" Perform a 'typical' build. """
		# configure the framework

		build = Raptor()
		build.AssertBuildOK()
		build.ConfigFile()
		build.ProcessConfig()
		build.CommandLine(argv)

		return build 



# Class for passing constricted parameters to filters
class BuildStats(object):

	def __init__(self, raptor_instance):
		self.logFileName = raptor_instance.logFileName
		self.quiet = raptor_instance.quiet
		self.doCheck = raptor_instance.doCheck
		self.doWhat = raptor_instance.doWhat
		self.platform = hostplatform
		self.skipAll = raptor_instance.fatalErrorState
		self.timestring = raptor_instance.timestring
		self.targets = raptor_instance.targets
		self.runtime = 0
		self.name = name


# raptor module functions

def Main(argv):
	"""The main entry point for Raptor.

	argv is a list of command-line parameters,
	NOT including the name of the calling script.

	The return value is zero for success and non-zero for failure."""

	DisplayBanner()

	# object which represents a build
	b = Raptor.CreateCommandlineBuild(argv)

	# allow all objects to log to the
	# build they're being used in
	global build
	global log
	build = b
	log = b


	result = b.Build()

	return result


def DisplayBanner():
	"""Stuff that needs printing out for every command."""
	pass



# end of the raptor module
