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
# makefile module
# This module is for writing calls to Function-Like Makefiles
#

import re
import os
import generic_path

class MakefileSelector(object):
	"""A "query" which is used to separate some flm interface calls
	  into separate makefile trees."""
	def __init__(self, name="default", interfacepattern=None, defaulttarget=None, ignoretargets=None):
		self.name=name
		if interfacepattern is not None:
			self.interfacepattern=re.compile(interfacepattern, re.I)
		else:
			self.interfacepattern=None
		self.defaulttarget=defaulttarget
		self.ignoretargets=ignoretargets

class Makefile(object):
	"""Representation of the file that is created from the build specification 
	   tree.
	"""
	def __init__(self, directory, selector, parent=None, filenamebase="Makefile", prologue=None, epilogue=None, defaulttargets=None):
		self.filenamebase = filenamebase
		self.directory = directory
		if selector.name != "":
			extension = "." + selector.name
		else:
			extension = ""
		self.filename = generic_path.Join(directory,filenamebase + extension)
		self.selector = selector
		self.parent = parent
		self.childlist = []
		self.file = None
		self.prologue = prologue
		self.epilogue = epilogue
		self.defaulttargets = defaulttargets
		self.dead = False

	def open(self):
		if self.dead:
			raise Exception, "Attempt to reopen completed makefile %s " % (self.filename)

		if self.file is None:
			directory = self.filename.Dir()
			if not (str(directory) == "" or directory.Exists()):
				try:
					os.makedirs(directory.GetLocalString())
				except Exception,e:
					raise Exception, "Cannot make directory '%s' for file '%s' in '%s': %s " % (str(directory),str(self.filename),str(self.directory),str(e))

			self.file = open(str(self.filename),"w+")
			
			self.file.write('# GENERATED MAKEFILE : DO NOT EDIT\n\n')
			if self.selector.defaulttarget:
				self.file.write('MAKEFILE_GROUP:=%s\n.PHONY:: %s\n%s:: # Default target\n' \
							% (self.selector.defaulttarget, self.selector.defaulttarget, self.selector.defaulttarget))
			else:
				self.file.write('MAKEFILE_GROUP:=DEFAULT\n')
			if self.prologue != None:
				self.file.write(self.prologue)
				
			if self.defaulttargets != None:
				self.file.write('# dynamic default targets\n')
				for defaulttarget in self.defaulttargets:
					self.file.write('.PHONY:: %s\n' % defaulttarget)
					self.file.write('%s:\n' % defaulttarget)
				self.file.write('\n')
			
	def addChild(self, child):
		self.open()
		self.file.write("include %s\n" % child.filename)
		child.open()

	def createChild(self, subdir):
		child = Makefile(str(self.filename.Dir().Append(subdir)), self.selector, self, self.filenamebase, self.prologue, self.epilogue, self.defaulttargets)
		self.addChild(child)
		child.open()
		return child

	def addCall(self, specname, configname, ifname, useAllInterfaces, flmpath, parameters, guard = None):
		"""Add an FLM call to the makefile.
			specname is the name of the build specification (e.g. the mmp name)
			configname is the name of the configuration which this call is made for
			flmpath is the absolute path to the flm
			parameters is an array of tuples, (paramname, paramvalue)	
			guard is a hash value that should be unique to the FLM call

		   This call will return False if the ifname does not match the selector for 
		   the makefile. e.g. it prevents one from adding a resource FLM call to a
		   makefile which is selecting export FLM calls. Selection is overridden if
		   useAllInterfaces is True.
		"""
		# create the directory if it does not exist

		if self.selector.interfacepattern is not None:
			ifmatch = self.selector.interfacepattern.search(ifname)
			if ifmatch == None and useAllInterfaces == False:
				return False

		self.open()
		# now we can write the values into the makefile
		self.file.write("# call %s\n" % flmpath)
		self.file.write("SBS_SPECIFICATION:=%s\n" % specname)
		self.file.write("SBS_CONFIGURATION:=%s\n\n" % configname)

		if guard:
			self.file.write("ifeq ($(%s),)\n%s:=1\n\n" % (guard, guard))
		
		for (p, value) in parameters:
			self.file.write("%s:=%s\n" % (p, value))
	
		self.file.write("include %s\n" % flmpath)
		self.file.write("MAKEFILE_LIST:= # work around potential gnu make stack overflow\n\n")
		
		if guard:
			self.file.write("endif\n\n")

		return True

	def addInclude(self, makefilename):
		"""
		"""
		# create the directory if it does not exist

		self.open()
		# now we can write the values into the makefile
		self.file.write("include %s\n" % (makefilename+"."+self.selector.name))

	def close(self):
		if self.file is not None:
			if self.epilogue != None:
				self.file.write(self.epilogue)
			self.file.write('# END OF GENERATED MAKEFILE : DO NOT EDIT\n')
			self.file.close()
			self.file = None
			self.dead = True

	def __del__(self):
		self.close()
			
		

class MakefileSet(object):
	grouperselector = MakefileSelector(name="")
	defaultselectors = [ 
		MakefileSelector("export", '\.export$', "EXPORT"),
		MakefileSelector("bitmap", '\.bitmap$', "BITMAP"),
		MakefileSelector("resource", '\.resource$', "RESOURCE"),
		MakefileSelector("default", '\.(?!export$|bitmap$|resource$).*$', "ALL")
		]

	def __init__(self, directory, selectors=defaultselectors, makefiles=None, parent=None, filenamebase="Makefile", prologue=None, epilogue=None, defaulttargets=None):
		self.directory = generic_path.Path(directory)
		self.filenamebase = filenamebase
		self.parent = parent
		if makefiles is not None:
			self.makefiles = makefiles
		else:
			self.makefiles = []
			for sel in selectors:
				self.makefiles.append(Makefile(directory, sel, None, filenamebase, prologue, epilogue, defaulttargets))
		self.groupermakefile = Makefile(directory, MakefileSet.grouperselector, None, filenamebase, "# GROUPER MAKEFILE\n\nALL::\n\n", "\n")
		
		for mf in self.makefiles:
			self.groupermakefile.addChild(mf)


	def createChild(self, subdir):
		"""Create a set of "sub" makefiles that are included by this set."""
		newmakefiles = []
		for mf in self.makefiles:
			newmf = mf.createChild(subdir)
			newmakefiles.append(newmf)

		newset = MakefileSet(str(self.directory.Append(subdir)), None, newmakefiles, self, self.filenamebase)
		self.groupermakefile.addChild(newset.groupermakefile)

		return newset

	def addCall(self, specname, configname, ifname, useAllInterfaces, flmpath, parameters, guard = None):
		"""Find out which makefiles to write this FLM call to 
		   and write it to those (e.g. the exports makefile) """
		for f in self.makefiles:
			f.addCall(specname, configname, ifname, useAllInterfaces, flmpath, parameters, guard)

	def addInclude(self, makefilename):
		"""include a makefile from each of the makefiles in the set - has the selector name appended to it."""
		for f in self.makefiles:
			f.addInclude(makefilename)

	def makefileNames(self):
		for mf in self.makefiles:
			yield str(mf.filename)
	
	def ignoreTargets(self, makefile):
		"""Get hold of a makefile's selector based on its name and
		   determine whether it ignores targets based on a regexp."""
		for mf in self.makefiles:
			filename = str(mf.filename)			
			if filename == makefile:
				return mf.selector.ignoretargets 
		return None

	def close(self):
		for mf in self.makefiles:
			mf.close()
		self.groupermakefile.close()

	def __del__(self):
		self.close()
