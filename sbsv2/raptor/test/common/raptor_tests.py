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
#

# run the smoke tests

import os
import re
import stat
import sys
import subprocess
import traceback
from shutil import rmtree

sys.path.append(os.environ["SBS_HOME"]+"/python")
from raptor_meta import BldInfFile

logDir = "$(EPOCROOT)/epoc32/build/smoketestlogs"

debug_mode_active = False

# Environment #################################################################

# On MYS there is USERNAME but not USER
if 'USER' not in os.environ:
	os.environ['USER'] = os.environ['USERNAME']

def activate_debug():
	"""
		Activate debug-mode remotely
	"""
	global debug_mode_active
	debug_mode_active = True

# Determine the OS version in the epocroot we're testing
# since some tests expect different outcomes for 9.4 and 9.5
def getsymbianversion():
	epocroot = os.environ['EPOCROOT']
	b = open (epocroot+"/epoc32/data/buildinfo.txt","r")
	binfo = " ".join(b.readlines())
	vmatch = (re.compile("v(9\.[0-9])")).search(binfo)
	if vmatch:
		osversion = vmatch.group(1)
	else:
		osversion = '9.4'
	return osversion

envRegex = re.compile("\$\((.+?)\)")
fixEnvironment = ['EPOCROOT', 'SBS_HOME', 'SBS_CYGWIN', 'SBS_MINGW', 'SBS_PYTHON']

def ReplaceEnvs(item):
	
	envs = envRegex.findall(item)

	for e in set(envs):
		try:
			val = os.environ[e]
			if e in fixEnvironment:
				# Raptor "fixes up" EPOCROOT etc. so we must do the same:
				# add the drive letter (make absolute)
				val = os.path.abspath(val)
				# use forward slashes
				val = val.replace("\\", "/")
				# remove trailing slashes
				val = val.rstrip("/")
			item = item.replace("$(" + e + ")", val)
		except KeyError:
			print e, "is not set in the environment"
			raise ValueError
				
	return item

# Utility functions ###########################################################



def where(input_file):
	"""Search for 'input_file' in the system path"""
	locations = []
	if sys.platform.startswith("win"):
		if not input_file.lower().endswith(".exe"):
			input_file += ".exe"
			for current_file in [loop_number + "\\" + input_file for loop_number in
					     os.environ["PATH"].split(";")]:
				try:
					stat = os.stat(current_file)
					locations.append(current_file)
				except OSError, error:
					pass
	else:
		whichproc = subprocess.Popen(args=["which", input_file], 
					stdout=subprocess.PIPE,
					stderr=subprocess.STDOUT,
					shell=False,
					universal_newlines=True)
		output = whichproc.stdout.readlines()
		whichproc.wait()

		if len(output) > 0:
			locations.append(output[0:(len(output) - 1)])
				
	if len(locations) == 0:
		print "Error: " + input_file + " not defined in PATH environment variable"
	else:
		return locations[0]
	
def clean_epocroot():
	"""
	This method walks through epocroot and cleans every file and folder that is
	not present in the manifest file
	"""
	epocroot = os.path.abspath(os.environ['EPOCROOT']).replace('\\','/')
	print "Cleaning Epocroot: %s" % epocroot
	all_files = {} # dictionary to hold all files
	folders = [] # holds all unique folders in manifest
	host_platform = os.environ["HOSTPLATFORM_DIR"]
	try:
		mani = "$(EPOCROOT)/manifest"
		manifest = open(ReplaceEnvs(mani), "r")
		le = len(epocroot)
		for line in manifest:
			line = line.replace("$(HOSTPLATFORM_DIR)", host_platform)
			line = line.replace("./", epocroot+"/").rstrip("\n")
			all_files[line] = True
			# This bit makes a record of unique folders into a list
			pos = line.rfind("/", le)
			while pos > le: # Look through the parent folders
				f = line[:pos]
				if f not in folders:
					folders.append(f)
				pos = line.rfind("/", le, pos)
				

		# This algorithm walks through epocroot and handles files and folders
		walkpath = "$(EPOCROOT)"
		for (root, dirs, files) in os.walk(ReplaceEnvs(walkpath), topdown =
				False):
			if root.find(".hg") != -1:
				continue

			# This loop handles all files
			for name in files:
				name = os.path.join(root, name).replace("\\", "/")
								
				if name not in all_files:
					try:
						os.remove(name)
					except:
						# chmod to rw and try again
						try:
							os.chmod(name, stat.S_IRWXU)
							os.remove(name)
						except:							
							print "\nEPOCROOT-CLEAN ERROR:"
							print (sys.exc_type.__name__ + ":"), \
									sys.exc_value
							if sys.exc_type.__name__ != "WindowsError":
								print traceback.print_tb(sys.exc_traceback)
									
			# This loop handles folders
			for name in dirs:
				if name.find(".hg") != -1:
					continue
				
				name = os.path.join(root, name).replace("\\", "/")
				if name not in all_files and name not in folders:
					# Remove the folder fully with no errors if full
					try:
						rmtree(ReplaceEnvs(name))
					except:
						print "\nEPOCROOT-CLEAN ERROR:"
						print (sys.exc_type.__name__ + ":"), \
								sys.exc_value
						if sys.exc_type.__name__ != "WindowsError":
							print traceback.print_tb(sys.exc_traceback)
	except IOError,e:
		print e
	
	print "Epocroot Cleaned"

def fix_id(input_id):
	return input_id.zfill(4)


def grep(file, string):
	return

	
# Test classes ################################################################

class SmokeTest(object):
	"""Base class for Smoke Test objects.
	
	Each test is defined (minimally) by,
	1) an ID number as a string
	2) a name
	3) a raptor command-line
	4) some parameters to check the command results against

	The run() method will,
	1) delete all the listed target files
	2) execute the raptor command
	3) check that the test results match the test parameters
	4) count the warnings and errors reported
	"""
	
	PASS = "pass"
	FAIL = "fail"
	SKIP = "skip"	

	def __init__(self):
		
		self.id = "0"
		self.name = "smoketest"
		self.description = ""
		self.command = "sbs --do_what_i_want"
		self.targets = []
		self.missing = 0
		self.warnings = 0
		self.errors = 0
		self.exceptions = 0
		self.returncode = 0

		self.onWindows = sys.platform.startswith("win")

		# These variables are for tests that treat the text as a list of lines. In
		# particular, "." will not match end-of-line. This means that, for example,
		# "abc.*def" will only match if "abc" and "def" appear on the same line.
		self.mustmatch = []
		self.mustnotmatch = []
		self.mustmatch_singleline = []
		self.mustnotmatch_singleline = []
		
		# These variables are for tests that treat the text as a single string of
		# characters. The pattern "." will match anything, including end-of-line.
		self.mustmatch_multiline = []
		self.mustnotmatch_multiline = []
		
		self.countmatch = []

		self.outputok = True
		self.usebash = False
		self.failsbecause = None
		self.result = SmokeTest.SKIP
		self.environ = {} # Allow tests to set the environment in which commands run.
		self.sbs_build_dir = "$(EPOCROOT)/epoc32/build"

	def run(self, platform = "all"):
		previousResult = self.result
		self.id = fix_id(self.id)
		try:
			if self.runnable(platform):
				
				if not self.pretest():
					self.result = SmokeTest.FAIL
				
				elif not self.test():
					self.result = SmokeTest.FAIL
				
				elif not self.posttest():
					self.result = SmokeTest.FAIL
				
				else:
					self.result = SmokeTest.PASS
			else:
				self.skip(platform)
		except Exception, e:
			print e
			self.result = SmokeTest.FAIL
		
		# print the result of this run()
		self.print_result(internal = True)
		
		# if a previous run() failed then the overall result is a FAIL
		if previousResult == SmokeTest.FAIL:
			self.result = SmokeTest.FAIL
	
	def print_result(self, value = "", internal = False):
		# the test passed :-)
		
		result = self.result
			
		string = ""
		if not internal:
			string += "\n" + self.name + ": "
		
		if value:
			print string + value
		else:
			if result == SmokeTest.PASS:
				string += "PASSED"
			elif result == SmokeTest.FAIL:
				string += "FAILED"
			
			print string 
	
	def runnable(self, platform):
		# can this test run on this platform?	
		if platform == "all":
			return True
		
		isWin = self.onWindows
		wantWin = platform.startswith("win")
		
		return (isWin == wantWin)

	def skip(self, platform):
		print "\nSKIPPING:", self.name, "for", platform

	def logfileOption(self):
		return "-f " + self.logfile();
	
	def logfile(self):
		return logDir + "/" + self.name + ".log"
	
	def makefileOption(self):
		return "-m " + self.makefile();
	
	def makefile(self):
		return logDir + "/" + self.name + ".mk"

	def removeFiles(self, files):
		for t in files:
			tgt = os.path.normpath(ReplaceEnvs(t))

			if os.path.exists(tgt):
				try:
					os.chmod(tgt, stat.S_IRWXU)
					if os.path.isdir(tgt):
						rmtree(tgt)
					else:
						os.remove(tgt)
				except OSError:
					print "Could not remove", tgt, "before the test"
					return False
		return True


	def clean(self):
		# remove all the target files

		# flatten any lists first (only 1 level of flattenening expected)
		# these indicate alternative files - one of them will exist after a build
		removables = []
		for i in self.targets:
			if type(i) is not list:
				removables.append(i)
			else:
				removables.extend(i)
				
		return self.removeFiles(removables)

	def pretest(self):
		# what to do before the test runs
		
		print "\nID:", self.id
		print "TEST:", self.name

		return self.clean()
			
	def test(self):
		# run the actual test
		
		# put the makefile and log in $EPOCROOT/build/smoketestlogs
		if self.usebash:
			command = ReplaceEnvs(self.command)
		else:
			command = ReplaceEnvs(self.command + 
					" " + self.makefileOption() + 
					" " + self.logfileOption())
	
		print "COMMAND:", command


		# Any environment settings specific to this test
		shellenv = os.environ.copy()
		for ev in self.environ:
			shellenv[ev] = self.environ[ev]

		if self.usebash:
			shellpath = shellenv['PATH']
			
			if 'SBS_SHELL' in os.environ:
				BASH = os.environ['SBS_SHELL']
			else:
				if self.onWindows:
					if 'SBS_CYGWIN' in shellenv:
						BASH = ReplaceEnvs("$(SBS_CYGWIN)/bin/bash.exe")
					else:
						BASH = ReplaceEnvs("$(SBS_HOME)/win32/cygwin/bin/bash.exe")
				else:
					BASH = ReplaceEnvs("$(SBS_HOME)/$(HOSTPLATFORM_DIR)/bin/bash")
				
			if self.onWindows:
				if 'SBS_CYGWIN' in shellenv:
					shellpath = ReplaceEnvs("$(SBS_CYGWIN)/bin") + ";" + shellpath
				else:
					shellpath = ReplaceEnvs("$(SBS_HOME)/win32/cygwin/bin") + ";" + shellpath

			shellenv['SBSMAKEFILE']=ReplaceEnvs(self.makefile())
			shellenv['SBSLOGFILE']=ReplaceEnvs(self.logfile())
			shellenv['PATH']=shellpath
			shellenv['PYTHON_HOME'] = ""
			shellenv['CYGWIN']="nontsec nosmbntsec"

			p = subprocess.Popen(args=[BASH, '-c', command], 
					stdout=subprocess.PIPE,
					stderr=subprocess.PIPE,
					env=shellenv,
					shell=False,
					universal_newlines=True)

			(std_out, std_err) = p.communicate()
			
			self.output = std_out + std_err
		else:
			p = subprocess.Popen(command, 
					stdout=subprocess.PIPE,
					stderr=subprocess.PIPE,
					env=shellenv,
					shell=True,
					universal_newlines=True)

			(std_out, std_err) = p.communicate()
			
			self.output = std_out + std_err
			
		if debug_mode_active:
			print self.output

		if p.returncode != self.returncode:
			print "RETURN: got", p.returncode, "expected", self.returncode
			return False
			
		return True
	
	def posttest(self):
		# what to do after the test has run
	
		# count the targets that got built
		found = 0
		missing = []
		for t in self.targets:
			if type(t) is not list:
				target_alternatives=[t]

			found_flag = False	
			for alt in target_alternatives:
				tgt = os.path.normpath(ReplaceEnvs(alt))
				if os.path.exists(tgt):
					found_flag = True
					break
			if found_flag:
				found += 1
			else:
				missing.append(tgt)
	
		# count the errors and warnings
		warn = 0
		error = 0
		exception = 0
		lines = self.output.split("\n")
	
		for line in lines:
			if line.find("sbs: warning:") != -1 or line.find("<warning") != -1:
				warn += 1
			elif line.find("sbs: error:") != -1 or line.find("<error") != -1:
				error += 1
			elif line.startswith("Traceback"):
				exception += 1

		# Check the output for required, forbidden and counted regexp matches
		self.outputok = True
		
		for expr in self.mustmatch_singleline + self.mustmatch:
			if not re.search(expr, self.output, re.MULTILINE):
				self.outputok = False
				print "OUTPUTMISMATCH: output did not match: %s" % expr

		for expr in self.mustnotmatch_singleline + self.mustnotmatch:
			if re.search(expr, self.output, re.MULTILINE):
				self.outputok = False
				print "OUTPUTMISMATCH: output should not have matched: %s" % expr

		for expr in self.mustmatch_multiline:
			if not re.search(expr, self.output, re.DOTALL):
				self.outputok = False
				print "OUTPUTMISMATCH: output did not match: %s" % expr

		for expr in self.mustnotmatch_multiline:
			if re.search(expr, self.output, re.DOTALL):
				self.outputok = False
				print "OUTPUTMISMATCH: output should not have matched: %s" % expr

		for (expr,num) in self.countmatch:
			expr_re = re.compile(expr)
			matchnum = len(expr_re.findall(self.output))
			if  matchnum != num:
				print "OUTPUTMISMATCH: %d matches occurred when %d were expected: %s" % (matchnum, num, expr)
				self.outputok = False

		# Ignore errors/warnings if they are set to (-1)
		if self.errors == (-1):
			self.errors = error
		if self.warnings == (-1):
			self.warnings= warn

		# all as expected?
		if  self.missing == len(missing) \
				and self.warnings == warn \
				and self.errors == error \
				and self.exceptions == exception \
				and self.outputok:
			return True
	
		# something was wrong :-(
	
		if len(missing) != self.missing:
			print "MISSING: %d, expected %s" % (len(missing), self.missing)
			for file in missing:
				print "\t%s" % (file)
			
		if warn != self.warnings:
			print "WARNINGS: %d, expected %d" % (warn, self.warnings)
		
		if error != self.errors:
			print "ERRORS: %d, expected %d" % ( error, self.errors)
		
		if exception != self.exceptions:
			print "EXCEPTIONS: %d, expected %d" % (exception, self.exceptions)
		
		return False
	
	def addbuildtargets(self, bldinfsourcepath, targetsuffixes):
		"""Add targets that are under epoc32/build whose path
		can change based on an md5 hash of the path to the bld.inf.
		"""

		fragment = BldInfFile.outputPathFragment(bldinfsourcepath)

		for t in targetsuffixes:
			if type(t) is not list:
				newt=self.sbs_build_dir+'/'+fragment+"/"+t
				self.targets.append(newt)
			else:
				self.targets.append([self.sbs_build_dir+'/'+fragment+"/"+x for x in t])
		return 

# derived class for tests that invoke some process, which have no log file and no makefile
# e.g. unit tests

class GenericSmokeTest(SmokeTest):
	
	def __init__(self):
		SmokeTest.__init__(self)

	def logfileOption(self):
		return ""
	
	def makefileOption(self):
		return ""
	
	def posttest(self):
		# dump the standard output to a log file
		dir = ReplaceEnvs(logDir)
		logfile = os.path.join(dir, self.name + ".log")
		try:
			if not os.path.exists(dir):
				os.makedirs(dir)
			file = open(logfile, "w")
			file.write(self.output)
			file.close()
		except:
			print "Could not save stdout in", logfile
			return False
		
		# do the base class things too
		return SmokeTest.posttest(self)
	
# derived class for --check, --what and .whatlog tests - these all write to stdout, but may
# not actually build anything

class CheckWhatSmokeTest(SmokeTest):
	
	def __init__(self):
		SmokeTest.__init__(self)
		
		# regular expression match object to restrict comparisons to specific lines
		self.regexlinefilter = None
		
		# paths in --what output are tailored to the host OS, hence slashes are converted appropriately
		# .whatlog output is used verbatim from the build/TEM/EM output
		self.hostossensitive = True
	
	def posttest(self):
		outlines = self.output.splitlines()
		
		ok = True
		seen = []
		
		# check for lines that we expected to see, optionally filtered
		for line in self.stdout:
			if self.regexlinefilter and not self.regexlinefilter.match(line):
				continue
			line = ReplaceEnvs(line)
			if self.hostossensitive and self.onWindows:
					line = line.replace("/", "\\")
				
			if line in outlines:
				seen.append(line)
			else:
				print "OUTPUT NOT FOUND:", line
				ok = False
		
		# and check for extra lines that we didn't expect, optionally filtered
		for line in outlines:
			if self.regexlinefilter and not self.regexlinefilter.match(line):
				continue
			if not line in seen:
				print "UNEXPECTED OUTPUT:", line
				ok = False
			
		# do the base class things too
		return (SmokeTest.posttest(self) and ok)	

# derived class for tests that also need to make sure that certain files
# are NOT created - sort of anti-targets.

class AntiTargetSmokeTest(SmokeTest):

	def __init__(self):
		SmokeTest.__init__(self)
		self.antitargets = []

	def pretest(self):
		""" Prepare for the test """
		# parent pretest first 
		ok = SmokeTest.pretest(self)
		
		# remove all the anti-target files
		return (self.removeFiles(self.antitargets) and ok)
	
	def posttest(self):
		""" look for antitargets """
		ok = True
		for t in self.antitargets:
			tgt = os.path.normpath(ReplaceEnvs(t))
			if os.path.exists(tgt):
				print "UNWANTED", tgt
				ok = False
				
		# do the base class things too
		return (SmokeTest.posttest(self) and ok)
	
	def addbuildantitargets(self, bldinfsourcepath, targetsuffixes):
		"""Add targets that are under epoc32/build whose path
		can change based on an md5 hash of the path to the bld.inf.
		"""

		fragment = BldInfFile.outputPathFragment(bldinfsourcepath)

		for t in targetsuffixes:
			if type(t) is not list:
				newt="$(EPOCROOT)/epoc32/build/"+fragment+"/"+t
				self.antitargets.append(newt)
			else:
				self.antitargets.append(["$(EPOCROOT)/epoc32/build/"+fragment+"/"+x for x in t])
		return

	
# the end
