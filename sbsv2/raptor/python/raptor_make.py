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
# raptor_make module
# This module contains the classes that write and call Makefile wrappers.
#

import hashlib
import os
import random
import raptor
import raptor_timing
import raptor_utilities
import raptor_version
import raptor_data
import re
import subprocess
import time
from raptor_makefile import *
import traceback
import sys
from xml.sax.saxutils import escape
from xml.sax.saxutils import unescape


class BadMakeEngineException(Exception):
	pass

def string_following(prefix, str):
	"""If str starts with prefix then return the rest of str, otherwise None"""
	if str.startswith(prefix):
		return str[len(prefix):]
	else:
		return None

def XMLEscapeLog(stream):
	""" A generator that reads a raptor log from a stream and performs an XML escape
	    on all text between tags, which is usually make output that could contain
	    illegal characters that upset XML-based log parsers.
	    This function yields "xml-safe" output line by line.
	"""
	inRecipe = False

	for line in stream:
		if line.startswith("<recipe"):
			inRecipe = True
		elif line.startswith("</recipe"):
			inRecipe = False
			
		# unless we are inside a "recipe", any line not starting
		# with "<" is free text that must be escaped.
		if inRecipe or line.startswith("<"):
			yield line
		else:
			yield escape(line)

def AnnoFileParseOutput(annofile):
	""" A generator that extracts log output from an emake annotation file, 
	    perform an XML-unescape on it and "yields" it line by line.  """
	af = open(annofile, "r")

	inOutput = False

	buildid = ""
	for line in af:
		line = line.rstrip("\n\r")


		if not inOutput:
			o = string_following("<output>", line)
			if not o:
				o = string_following('<output src="prog">', line)

			if o:
				inOutput = True	
				yield unescape(o)+'\n'
				continue


			o = string_following('<build id="',line)
			if o:
				buildid = o[:o.find('"')]
				yield "Starting build: "+buildid+"\n"
				continue 

			o = string_following('<metric name="duration">', line)
			if o:
				secs = int(o[:o.find('<')])
				if secs != 0:
					duration = "%d:%d" % (secs/60, secs % 60)
				else:
					duration = "0:0"
				continue 


			o = string_following('<metric name="clusterAvailability">', line)
			if o:
				availability = o[:o.find('<')]
				continue 
				
		else:
			end_output = line.find("</output>")
		
			if end_output != -1:
				line = line[:end_output]
				inOutput = False
			
			if line != "":	
				yield unescape(line)+'\n'

	yield "Finished build: %s   Duration: %s (m:s)   Cluster availability: %s%%\n" %(buildid,duration,availability)
	af.close()



# raptor_make module classes

class MakeEngine(object):

	def __init__(self, Raptor, engine="make_engine"):
		self.raptor = Raptor
		self.valid = True
		self.descrambler = None
		self.descrambler_started = False

		# look for an alias first as this gives end-users a chance to modify
		# the shipped variant rather than completely replacing it.
		if engine in Raptor.cache.aliases:
			avar = Raptor.cache.FindNamedAlias(engine)
		elif engine in Raptor.cache.variants:
			avar = Raptor.cache.FindNamedVariant(engine)
		else:
			raise BadMakeEngineException("'%s' does not appear to be a make engine - no settings found for it" % engine)

		if not avar.isDerivedFrom("make_engine", Raptor.cache):
			raise BadMakeEngineException("'%s' is not a build engine (it's a variant but it does not extend 'make_engine')" % engine)
					
		# find the variant and extract the values
		try:
			units = avar.GenerateBuildUnits(Raptor.cache)
			evaluator = Raptor.GetEvaluator( None, units[0] , gathertools=True)

			# shell
			self.shellpath = evaluator.Get("DEFAULT_SHELL")
			usetalon_s = evaluator.Get("USE_TALON") 
			self.usetalon = usetalon_s is not None and usetalon_s != ""
			self.talonshell = str(evaluator.Get("TALON_SHELL"))
			self.talontimeout = str(evaluator.Get("TALON_TIMEOUT"))
			self.talonretries = str(evaluator.Get("TALON_RETRIES"))

			# commands
			self.initCommand = evaluator.Get("initialise")
			self.buildCommand = evaluator.Get("build")
			self.shutdownCommand = evaluator.Get("shutdown")

			# options
			self.makefileOption = evaluator.Get("makefile")
			self.keepGoingOption = evaluator.Get("keep_going")
			self.jobsOption = evaluator.Get("jobs")
			self.defaultMakeOptions = evaluator.Get("defaultoptions")

			# Logging
			#  copylogfromannofile means, for emake, that we should ignore 
			# emake's console output and instead extract output from its annotation
			# file.  This is a workaround for a problem where some emake
			# console output is lost.  The annotation file has a copy of this
			# output in the "parse" job and it turns out to be uncorrupted.
			self.copyLogFromAnnoFile = (evaluator.Get("copylogfromannofile") == "true")
			self.annoFileName = None

			if self.copyLogFromAnnoFile:
				for o in self.raptor.makeOptions:
					self.annoFileName = string_following("--emake-annofile=", o)
					if self.annoFileName:
						self.raptor.Info("annofile: " + o)

				if not self.annoFileName:
					self.raptor.Info("Cannot copy log from annotation file as no annotation filename was specified via the option --mo=--emake-annofile=<filename>")
					self.copyLogFromAnnoFile = False

			# buffering
			self.scrambled = (evaluator.Get("scrambled") == "true")

			# check tool versions
			Raptor.CheckToolset(evaluator, avar.name)
			
			# default targets (can vary per-invocation)
			self.defaultTargets = Raptor.defaultTargets

			# work out how to split up makefiles
			try:
				selectorNames = [ x.strip() for x in evaluator.Get("selectors").split(',') if x.strip() != "" ]
				self.selectors = []


				if len(selectorNames) > 0:
					for name in selectorNames:
						pattern = evaluator.Get(name.strip() + ".selector.iface")
						target = evaluator.Get(name.strip() + ".selector.target")
						ignoretargets = evaluator.Get(name.strip() + ".selector.ignoretargets")
						self.selectors.append(MakefileSelector(name,pattern,target,ignoretargets))
			except KeyError:
				Raptor.Error("%s.selector.iface, %s.selector.target not found in make engine configuration", name, name)
				self.selectors = []

		except KeyError:
			self.valid = False
			raise BadMakeEngineException("Bad '%s' configuration found." % engine)

		# there must at least be a build command...
		if not self.buildCommand:
			self.valid = False
			raise BadMakeEngineException("No build command for '%s'"% engine)


		if self.usetalon:
			talon_settings="""
TALON_SHELL:=%s
TALON_TIMEOUT:=%s
TALON_RECIPEATTRIBUTES:=\
 name='$$RECIPE'\
 target='$$TARGET'\
 host='$$HOSTNAME'\
 layer='$$COMPONENT_LAYER'\
 component='$$COMPONENT_NAME'\
 bldinf='$$COMPONENT_META' mmp='$$PROJECT_META'\
 config='$$SBS_CONFIGURATION' platform='$$PLATFORM'\
 phase='$$MAKEFILE_GROUP' source='$$SOURCE'
export TALON_RECIPEATTRIBUTES TALON_SHELL TALON_TIMEOUT
USE_TALON:=%s

""" % (self.talonshell, self.talontimeout, "1")
		else:
			talon_settings="""
USE_TALON:=

"""


		timing_start = "$(info " + \
				raptor_timing.Timing.custom_string(tag = "start",
				object_type = "makefile", task = "parse",
				key = "$(THIS_FILENAME)",
				time="$(shell date +%s.%N)").rstrip("\n") + ")"
				
		timing_end = "$(info " + \
				raptor_timing.Timing.custom_string(tag = "end",
				object_type = "makefile", task = "parse",
				key = "$(THIS_FILENAME)",
				time="$(shell date +%s.%N)").rstrip("\n") + ")"


		self.makefile_prologue = """

# generated by %s %s

HOSTPLATFORM:=%s
HOSTPLATFORM_DIR:=%s
OSTYPE:=%s
FLMHOME:=%s
SHELL:=%s
THIS_FILENAME:=$(firstword $(MAKEFILE_LIST))

%s

include %s

""" 		% (  raptor.name, raptor_version.fullversion(),
			 " ".join(raptor.hostplatform),
			 raptor.hostplatform_dir,
			 self.raptor.filesystem,
			 str(self.raptor.systemFLM),
			 self.shellpath,
			 talon_settings,
			 self.raptor.systemFLM.Append('globals.mk') )

		# Unless dependency processing has been eschewed via the CLI, use a .DEFAULT target to
		# trap missing dependencies (ignoring user config files that we know are usually absent)
		if not (self.raptor.noDependGenerate or self.raptor.noDependInclude):
			self.makefile_prologue += """

$(FLMHOME)/user/final.mk:
$(FLMHOME)/user/default.flm:
$(FLMHOME)/user/globals.mk:

.DEFAULT::
	@echo "<warning>Missing dependency detected: $@</warning>"

"""

		# Only output timings if requested on CLI
		if self.raptor.timing:
			self.makefile_prologue += "\n# Print Start-time of Makefile parsing\n" \
					+ timing_start + "\n\n"
	
	
			self.makefile_epilogue = "\n\n# Print End-time of Makefile parsing\n" \
				+ timing_end + "\n"
		else:
			self.makefile_epilogue = ""

		self.makefile_epilogue += """

include %s

""" 			% (self.raptor.systemFLM.Append('final.mk') )

	def Write(self, toplevel, specs, configs):
		"""Generate a set of makefiles, or one big Makefile."""

		if not self.valid:
			return None

		self.raptor.Debug("Writing Makefile '%s'" % (str(toplevel)))

		self.toplevel = toplevel

		# create the top-level makefiles
		makefileset = None

		try:
			makefileset = MakefileSet(directory = str(toplevel.Dir()),
										   selectors = self.selectors,
										   filenamebase = str(toplevel.File()),
										   prologue = self.makefile_prologue,
										   epilogue = self.makefile_epilogue,
										   defaulttargets = self.defaultTargets)

			# are we pruning duplicates?
			self.prune = self.raptor.pruneDuplicateMakefiles
			self.hashes = set()

			# are we writing one Makefile or lots?
			self.many = not self.raptor.writeSingleMakefile

			# add a makefile for each spec under each config
			config_makefileset = makefileset
			for c in configs:
				if self.many:
					config_makefileset = makefileset.createChild(c.name)

				# make sure the config_wide spec item is put out first so that it
				# can affect everything.
				ordered_specs=[]
				config_wide_spec = None
				for s in specs:
					if s.name == "config_wide":
						config_wide_spec = s
					else:
						ordered_specs.append(s)

				if config_wide_spec is not None:
					config_wide_spec.Configure(c, cache = self.raptor.cache)
					self.WriteConfiguredSpec(config_makefileset, config_wide_spec, c, True)

				for s in ordered_specs:
					s.Configure(c, cache = self.raptor.cache)
					self.WriteConfiguredSpec(config_makefileset, s, c, False)

			makefileset.close()
		except Exception,e:
			tb = traceback.format_exc()
			if not self.raptor.debugOutput:
				tb=""
			self.raptor.Error("Failed to write makefile '%s': %s : %s" % (str(toplevel),str(e),tb))
			makefileset = None

		return makefileset


	def WriteConfiguredSpec(self, parentMakefileSet, spec, config, useAllInterfaces):
		# ignore this spec if it is empty
		hasInterface = spec.HasInterface()
		childSpecs = spec.GetChildSpecs()

		if not hasInterface and not childSpecs:
			return

		parameters = []
		dupe = True
		iface = None
		guard = None
		if hasInterface:
			# find the Interface (it may be a ref)
			try:
				iface = spec.GetInterface(self.raptor.cache)

			except raptor_data.MissingInterfaceError, e:	
				self.raptor.Error("No interface for '%s'", spec.name)
				return

			if iface.abstract:
				self.raptor.Error("Abstract interface '%s' for '%s'",
								  iface.name, spec.name)
				return

			# we need to guard the FLM call with a hash based on all the
			# parameter values so that duplicate calls cannot be made.
			# So we need to find all the values before we can write
			# anything out.
			md5hash = hashlib.md5()
			md5hash.update(iface.name)

			# we need an Evaluator to get parameter values for this
			# Specification in the context of this Configuration
			evaluator = self.raptor.GetEvaluator(spec, config)

			def addparam(k, value, default):
				if value == None:
					if p.default != None:
						value = p.default
					else:
						self.raptor.Error("%s undefined for '%s'",
										  k, spec.name)
						value = ""

				parameters.append((k, value))
				md5hash.update(value)

			# parameters required by the interface
			for p in iface.GetParams(self.raptor.cache):
				val = evaluator.Resolve(p.name)
				addparam(p.name,val,p.default)

			# Use Patterns to fetch a group of parameters
			for g in iface.GetParamGroups(self.raptor.cache):
				for k,v in evaluator.ResolveMatching(g.patternre):
					addparam(k,v,g.default)

			hash = md5hash.hexdigest()
			dupe = hash in self.hashes

			self.hashes.add(hash)

		# we only create a Makefile if we have a new FLM call to contribute,
		# OR we are not pruning duplicates (guarding instead)
		# OR we have some child specs that need something to include them.
		if dupe and self.prune and not childSpecs:
			return

		makefileset = parentMakefileSet
		# Create a new layer of makefiles?
		if self.many:
			makefileset = makefileset.createChild(spec.name)

		if not (self.prune and dupe):
			if self.prune:
				guard = ""
			else:
				guard = "guard_" + hash

		# generate the call to the FLM
		if iface is not None:
			makefileset.addCall(spec.name, config.name, iface.name, useAllInterfaces, iface.GetFLMIncludePath(self.raptor.cache), parameters, guard)

		# recursive includes

		for child in childSpecs:
			self.WriteConfiguredSpec(makefileset, child, config, useAllInterfaces)

		if self.many:
			makefileset.close() # close child set of makefiles as we'll never see them again.

	def Make(self, makefileset):
		"run the make command"

		if not self.valid:
			return False
	
		if self.usetalon:
			# Always use Talon since it does the XML not
			# just descrambling
			if not self.StartTalon() and not self.raptor.keepGoing:
				self.Tidy()
				return False
		else:
			# use the descrambler if we are doing a parallel build on
			# a make engine which does not buffer each agent's output
			if self.raptor.jobs > 1 and self.scrambled:
				self.StartDescrambler()
				if  not self.descrambler_started and not self.raptor.keepGoing:
					self.Tidy()
					return False
			
		# run any initialisation script
		if self.initCommand:
			self.raptor.Info("Running %s", self.initCommand)
			if os.system(self.initCommand) != 0:
				self.raptor.Error("Failed in %s", self.initCommand)
				self.Tidy()
				return False

		# Save file names to a list, to allow the order to be reversed
		fileName_list = list(makefileset.makefileNames())

		# Iterate through args passed to raptor, searching for CLEAN or REALLYCLEAN
		clean_flag = False
		for arg in self.raptor.args:
			clean_flag = ("CLEAN" in self.raptor.args) or \
			            ("REALLYCLEAN" in self.raptor.args)

		# Files should be deleted in the opposite order to the order
		# they were built. So reverse file order if cleaning
		if clean_flag:
			fileName_list.reverse()

		# Report number of makefiles to be built
		self.raptor.InfoDiscovery(object_type = "makefile", count = len(fileName_list))

		# Process each file in turn
		for makefile in fileName_list:
			if not os.path.exists(makefile):
				self.raptor.Info("Skipping makefile %s", makefile)
				continue
			self.raptor.Info("Making %s", makefile)
			# assemble the build command line
			command = self.buildCommand

			if self.makefileOption:
				command += " " + self.makefileOption + " " + ' "' + str(makefile) + '" '

			if self.raptor.keepGoing and self.keepGoingOption:
				command += " " + self.keepGoingOption

			if self.raptor.jobs > 1 and self.jobsOption:
				command += " " + self.jobsOption +" "+ str(self.raptor.jobs)

			# Set default options first so that they can be overridden by
			# ones set by the --mo option on the raptor commandline:
			command += " " + self.defaultMakeOptions
			# Can supply options on the commandline to override default settings.
			if len(self.raptor.makeOptions) > 0:
				for o in self.raptor.makeOptions:
					if o.find(";") != -1 or  o.find("\\") != -1:
						command += "  " + "'" + o + "'"
					else:
						command += "  " + o

			# Switch off dependency file including?
			if self.raptor.noDependInclude or self.raptor.noDependGenerate:
				command += " NO_DEPEND_INCLUDE=1"
			
			# Switch off dependency file generation (and, implicitly, inclusion)?
			if self.raptor.noDependGenerate:
				command += " NO_DEPEND_GENERATE=1"
			
			if self.usetalon:
				# use the descrambler if we set it up
				command += ' TALON_DESCRAMBLE=' 
				if self.scrambled:
					command += '1 '
				else:
					command += '0 '
			else:
				if self.descrambler_started:
					command += ' DESCRAMBLE="' + self.descrambler + '"'
			
			# use the retry mechanism if requested
			if self.raptor.tries > 1:
				command += ' RECIPETRIES=' + str(self.raptor.tries)
				command += ' TALON_RETRIES=' + str(self.raptor.tries - 1)

			# targets go at the end, if the makefile supports them
			addTargets = self.raptor.targets[:]
			ignoreTargets = makefileset.ignoreTargets(makefile)
			if addTargets and ignoreTargets:
				for target in self.raptor.targets:
					if re.match(ignoreTargets, target):
						addTargets.remove(target)

			if addTargets:
				command += " " + " ".join(addTargets)

			# Send stderr to a file so that it can't mess up the log (e.g.
			# clock skew messages from some build engines scatter their
			# output across our xml.
			stderrfilename = makefile+'.stderr'
			stdoutfilename = makefile+'.stdout'
			command += " 2>'%s' " % stderrfilename

			# Keep a copy of the stdout too in the case of using the 
			# annofile - so that we can trap the problem that
			# makes the copy-log-from-annofile workaround necessary
			# and perhaps determine when we can remove it.
			if self.copyLogFromAnnoFile:
				command += " >'%s' " % stdoutfilename

			# Substitute the makefile name for any occurrence of #MAKEFILE#
			command = command.replace("#MAKEFILE#", str(makefile))

			self.raptor.Info("Executing '%s'", command)

			# execute the build.
			# the actual call differs between Windows and Unix.
			# bufsize=1 means "line buffered"
			#
			try:
				# Time the build
				self.raptor.InfoStartTime(object_type = "makefile",
						task = "build", key = str(makefile))
				
				makeenv=os.environ.copy()
				if self.usetalon:
					makeenv['TALON_RECIPEATTRIBUTES']="none"
					makeenv['TALON_SHELL']=self.talonshell
					makeenv['TALON_BUILDID']=str(self.buildID)
					makeenv['TALON_TIMEOUT']=str(self.talontimeout)

				if self.raptor.filesystem == "unix":
					p = subprocess.Popen([command], bufsize=65535,
						stdout=subprocess.PIPE,
						stderr=subprocess.STDOUT,
						close_fds=True, env=makeenv, shell=True)
				else:
					p = subprocess.Popen(args = 
						[raptor_data.ToolSet.shell, '-c', command],
						bufsize=65535,
						stdout=subprocess.PIPE,
						stderr=subprocess.STDOUT,
						shell = False,
						universal_newlines=True, env=makeenv)
				stream = p.stdout

				inRecipe = False

				if not self.copyLogFromAnnoFile:
					for l in XMLEscapeLog(stream):
						self.raptor.out.write(l)

					returncode = p.wait()
				else:
					returncode = p.wait()

					annofilename = self.annoFileName.replace("#MAKEFILE#", makefile)
					self.raptor.Info("copylogfromannofile: Copying log from annotation file %s to work around a potential problem with the console output", annofilename)
					try:
						for l in XMLEscapeLog(AnnoFileParseOutput(annofilename)):
							self.raptor.out.write(l)
					except Exception,e:
						self.raptor.Error("Couldn't complete stdout output from annofile %s for %s - '%s'", annofilename, command, str(e))


				# Take all the stderr output that went into the .stderr file
				# and put it back into the log, but safely so it can't mess up
				# xml parsers.
				try:
					e = open(stderrfilename,"r")
					for line in e:
						self.raptor.out.write(escape(line))
					e.close()
				except Exception,e:
					self.raptor.Error("Couldn't complete stderr output for %s - '%s'", command, str(e))
				# Report end-time of the build
				self.raptor.InfoEndTime(object_type = "makefile",
						task = "build", key = str(makefile))

				if returncode != 0  and not self.raptor.keepGoing:
					self.Tidy()
					return False

			except Exception,e:
				self.raptor.Error("Exception '%s' during '%s'", str(e), command)
				self.Tidy()
				# Still report end-time of the build
				self.raptor.InfoEndTime(object_type = "Building", task = "Makefile",
						key = str(makefile))
				return False

		# run any shutdown script
		if self.shutdownCommand != None and self.shutdownCommand != "":
			self.raptor.Info("Running %s", self.shutdownCommand)
			if os.system(self.shutdownCommand) != 0:
				self.raptor.Error("Failed in %s", self.shutdownCommand)
				self.Tidy()
				return False

		self.Tidy()
		return True

	def Tidy(self):
		if self.usetalon:
			self.StopTalon() 
		else:
			"clean up after the make command"
			self.StopDescrambler()

	def StartTalon(self):
		# the talon command
		beginning = raptor.hostplatform_dir + "/bin"
		if "win" in raptor.hostplatform:
			end = ".exe"
		else:
			end = ""
			
		self.talonctl = str(self.raptor.home.Append(beginning, "talonctl"+end))
			
		# generate a unique build number
		random.seed()
		looking = True
		tries = 0
		while looking and tries < 100:
			self.buildID = raptor.name + str(random.getrandbits(32))
			
			command = self.talonctl + " start"

			os.environ["TALON_BUILDID"] = self.buildID
			self.raptor.Info("Running %s", command)
			looking = (os.system(command) != 0)
			tries += 1
		if looking:
			self.raptor.Error("Failed to initialise the talon shell for this build")
			self.talonctl = ""
			return False
		
		return True
	
	def StopTalon(self):
		if self.talonctl:
			command = self.talonctl + " stop"
			self.talonctl = ""
			
			self.raptor.Info("Running %s", command)
			if os.system(command) != 0:
				self.raptor.Error("Failed in %s", command)
				return False
			
		return True
	
	def StartDescrambler(self):
		# the descrambler command
		beginning = raptor.hostplatform_dir + "/bin"
		if "win" in raptor.hostplatform:
			end = ".exe"
		else:
			end = ""

		self.descrambler = str(self.raptor.home.Append(beginning, "sbs_descramble"+end))
			
		# generate a unique build number
		random.seed()
		looking = True
		tries = 0
		while looking and tries < 100:
			buildID = raptor.name + str(random.getrandbits(32))

			command = self.descrambler + " " + buildID + " start"
			self.raptor.Info("Running %s", command)
			looking = (os.system(command) != 0)
			tries += 1

		if looking:
			self.raptor.Error("Failed to start the log descrambler")
			self.descrambler_started = True
			return False

		self.descrambler_started = True
		self.descrambler +=	" " + buildID

		return  True

	def StopDescrambler(self):
		if self.descrambler_started:
			command = self.descrambler + " stop"
			self.descrambler = ""

			self.raptor.Info("Running %s", command)
			if os.system(command) != 0:
				self.raptor.Error("Failed in %s", command)
				return False
		return True



# raptor_make module functions


# end of the raptor_make module
