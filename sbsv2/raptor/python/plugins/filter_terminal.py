#
# Copyright (c) 2008-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Filter class for filtering XML logs and generating reports
# Prints errors and warnings to stdout
#

import sys
import raptor
import filter_interface
import generic_path
import os
import os.path
import re

class Recipe(object):
	"""State machine that parses a recipe
	"""

	suppress = []
	warningRE = re.compile("^.*((Warning:)|(MAKEDEF WARNING:)) .*$", re.DOTALL | re.M | re.I)
	infoRE = None
	name = [ "default" ]
	recipes = []

	def __init__(self, text):
		self.suppress = self.__class__.suppress
		self.text = text
		self.warningRE = Recipe.warningRE
	
	def warnings(self):
		return self.warningRE.findall(self.text)

	def info(self):
		if self.infoRE:
			return self.infoRE.findall(self.text)
		else:
			return []

	@classmethod			
	def factory(cls, name, text):
		for r in Recipe.recipes:
			if name in r.name:
				return r(text)
		return Recipe(text)
	

class MwLinkerRecipe(Recipe):
	suppress = [ 
		re.compile(
r"^mwldsym2: warning: Cannot locate library \"MSL_All_Static_MSE_Symbian\" specified in #pragma comment\(lib,...\)$"
r"[\n\r]*mwldsym2: warning: referenced from.*$"
r"[\n\r]*mwldsym2: warning: Option 'Use default libraries' is enabled but linker used.*$"
r"[\n\r]*mwldsym2: warning: runtime library from MW\[...\]LibraryFiles \(msl_all_static_mse_symbian_d.lib\);$"
r"[\n\r]*mwldsym2: warning: this indicates a potential settings/libraries mismatch.*$"
		, re.M)
		, re.compile(
r"^mwldsym2.exe: warning: Multiply defined symbol: ___get_MSL_init_count in.*$"
r"[\n\r]*mwldsym2.exe: warning: files uc_cwhelp.obj \(.*\), startup.win32.c.obj \(msl_all_static_mse_symbian_d.lib\),.*$"
r"[\n\r]*mwldsym2.exe: warning: keeping definition in startup.win32.c.obj.*$"
		, re.M )
		, re.compile(
r"^mwldsym2.exe: warning: Option 'Use default libraries' is enabled but linker used.*$"
r"[\n\r]*mwldsym2.exe: warning: runtime library from MW\[...\]LibraryFiles \(msl_all_static_mse_symbian_d.lib\);.*$"
r"[\n\r]*mwldsym2.exe: warning: this indicates a potential settings/libraries mismatch.*$"
	, re.M)
	]
	name = [ "win32stagetwolink", "win32simplelink" ]

	def warnings(self):
		edited = self.text
		for s in MwLinkerRecipe.suppress:
			edited = s.sub("", edited)
		return Recipe.warningRE.findall(edited)

Recipe.recipes.append(MwLinkerRecipe)


class FreezeRecipe(Recipe):
	name = [ "freeze" ]
	warningRE = re.compile("^(WARNING:) .*$", re.DOTALL | re.M | re.I)
	infoRE = re.compile("^(EFREEZE:) .*$", re.DOTALL | re.M | re.I)

	def __init__(self, text):
		Recipe.__init__(self, text)
		self.warningRE = FreezeRecipe.warningRE
		self.infoRE = FreezeRecipe.infoRE

Recipe.recipes.append(FreezeRecipe)



class FilterTerminal(filter_interface.Filter):

	attribute_re = re.compile("([a-z][a-z0-9]*)='([^']*)'",re.I)
	maxdots = 40 # if one prints dots then don't print masses
	recipelinelimit = 1024 # don't scan ultra-long recipes in case we run out of memory

	# recipes that we think most users are interested in
	# and the mapping that we will use to output them as
	docare = {
		"asmcompile" : "asmcompile" ,
		"compile" : "compile" ,
		"postlink" : "target",
		"linkandpostlink" : "target",
		"resourcecompile" : "resource",
		"genstringtable" : "strtable",
		"tem" : "tem",
		"bitmapcompile" : "bitmap",
		"bitmapcopy" : "bitmapcopy",
		"win32compile2object" : "compile",
		"win32stagetwolink" : "target",
		"win32simplelink" : "target",
		"tools2install" : "target",
		"compile2object" : "compile",
		"msvctoolsinstall" : "target",
		"msvctoolscompile" : "compile",
		"freeze" : "freeze",
		"win32archive" : "target"
	}

	# Determine the width of the largest mapped recipe name
	recipewidth = 0
	for i in docare:
		l = len(docare[i])
		if l > recipewidth:
			recipewidth = l # justification for printing out recipes.
	recipewidth+=1

	def __init__(self):
		self.analyseonly = False
		self.quiet = False
		# defaults can use EPOCROOT
		if "EPOCROOT" in os.environ:
			self.epocroot = str(generic_path.Path(os.environ["EPOCROOT"]))
		else:
			self.epocroot = str(generic_path.Path('/'))
		self.current_recipe_logged = False
		self.cleaned = 0  # cleaned files
		self.dotcount = 0 # progress dots printed so far
		# list of strings to catch make errors (must be lowercase)
		self.make_error_expr = set([
				"error:",
				": ***",
				"make: interrupt/exception caught (code =",
				"make.exe: interrupt/exception caught (code =",
				"command returned code"
				])
		# list of strings to catch make warnings (must be lowercase)
		self.make_warning_expr = ["warning:"]

		# list of strings to catch recipe warnings (must be lowercase)
		self.recipe_warning_expr = ["warning:"]
		
	def isMakeWarning(self, text):
                """A simple test for warnings.
                Can be extended do to more comprehensive checking."""
		# generic warnings checked
		# array of make_warning_expr holds all the possible values
		for warn in self.make_warning_expr:
			if warn in text.lower():
				return True
	
		return False


	def isMakeError(self, text):
		"""A simple test for errors.	
		Can be extended to do more comprehensive checking."""

		# make, emake and pvmgmake spit out things like
		# make: *** No rule to make target X, needed by Y. Stop.
		#
		# array of make_error_expr holds all the possible values
		for err in self.make_error_expr:
			if err in text.lower():
				return True
		
		return False


	def open(self, raptor_instance):
		"""Set output to stdout for the various I/O methods to write to."""
		self.raptor = raptor_instance

		# Be totally silent?
		if self.raptor.logFileName is None:
			self.analyseonly = True

		# Only print errors and warnings?
		if self.raptor.quiet:
			self.quiet = True
		
		# the build configurations which were reported
		self.built_configs = []
		
		# keep count of errors and warnings
		self.err_count = 0
		self.warn_count = 0
		self.suppressed_warn_count = 0
		self.inBody = False
		self.inRecipe = False
		return True
		
	def write(self, text):
		"""Write errors and warnings to stdout"""
		
		if text.startswith("<error"):
			start = text.find(">")
			end = text.rfind("<")
			self.err_count += 1
			if not self.analyseonly:
				sys.stderr.write(str(raptor.name) + ": error: %s\n" \
						% text[(start + 1):end])
		elif text.startswith("<warning"):
			start = text.find(">")
			end = text.rfind("<")
			self.warn_count += 1
			if not self.analyseonly:
				sys.stdout.write(str(raptor.name) + ": warning: %s\n" \
					% text[(start + 1):end])
		elif text.startswith("<status "):
			# detect the status report from a recipe
			if text.find('failed') != -1:
				self.failed = True
				if text.find("reason='timeout'") != -1:
					self.timedout = True
			else:
				self.failed = False
			return
		elif text.startswith("<recipe "):
			# detect the start of a recipe
			if self.inRecipe:
				sys.stdout.flush()
				sys.stderr.write(self.formatError("Opening recipe tag found " \
						+ "before closing recipe tag for previous recipe:\n" \
						+ "Discarding previous recipe (Possible logfile " \
						+ "corruption)"))
				sys.stderr.flush()
			self.inRecipe = True
			self.current_recipe_logged = False
			m = FilterTerminal.attribute_re.findall(text)
			self.recipe_dict = dict ()
			for i in m:
				self.recipe_dict[i[0]] = i[1]

			# Decide what to tell the user about this recipe
			# The target file or the source file?  
			name = None
			if 'source' in self.recipe_dict:
				name = self.recipe_dict['source']

			name_to_user = ""
			# Make source files relative to the current directory if they are 
		 	# not generated files in epocroot.  Also make sure path is in 
			# the appropriate format for the user's shell.
			if name and (name.find("epoc32") == -1 or name.endswith('.UID.CPP')):
				for i in name.rsplit():
					name_to_user += " " + generic_path.Path(i).From(generic_path.CurrentDir()).GetShellPath()
			else:
				# using the target.  Shorten it if it's in epocroot by just chopping off
				# epocroot
				name_to_user = self.recipe_dict['target']
				if name_to_user.find(self.epocroot) != -1:
					name_to_user = name_to_user.replace(self.epocroot,"")
					if name_to_user.startswith('/') or name_to_user.startswith('\\'):
						name_to_user = name_to_user[1:]
				name_to_user = generic_path.Path(name_to_user).GetShellPath()	
			self.recipe_dict['name_to_user'] = name_to_user
			self.recipe_dict['mappedname'] = self.recipe_dict['name'] 

			# Status message to indicate that we are building
			recipename = self.recipe_dict['name']
			if recipename in FilterTerminal.docare:
				self.recipe_dict['mappedname'] = FilterTerminal.docare[recipename]
				self.logit_if()

			# This variable holds all recipe information
			self.failed = False # Recipe status
			self.timedout = False # Did it Timeout?
			self.recipeBody = []
			self.recipelineExceeded = 0
			return		
		elif text.startswith("</recipe>"):
			# detect the end of a recipe
			if not self.inRecipe:
				sys.stdout.flush()
				sys.stderr.write(self.formatError("Closing recipe tag found " \
						+ "before opening recipe tag:\nUnable to print " \
						+ "recipe data (Possible logfile corruption)"))
				sys.stderr.flush()
			else:
				self.inRecipe = False
				
				if self.failed == True:
					if not self.analyseonly:
						reason=""
						if self.timedout:
							reason="(timeout)"

						sys.stderr.write("\n FAILED %s %s for %s: %s\n" % \
								(self.recipe_dict['name'],
								reason,
								self.recipe_dict['config'],
								self.recipe_dict['name_to_user']))
	
						mmppath = generic_path.Path(self.recipe_dict['mmp']).From(generic_path.CurrentDir()).GetShellPath()
						if mmppath is not "":
							sys.stderr.write("  mmp: %s\n" % mmppath)
						if self.timedout:
							sys.stderr.write( \
"""    Timeouts may be due to network related issues (e.g. license servers),
    tool bugs or abnormally large components. TALON_TIMEOUT can be adjusted 
    in the make engine configuration if required.  Make engines may have 
    their own timeouts that Raptor cannot influence
""")
						else:
							for L in self.recipeBody:
								if not L.startswith('+'):
									sys.stdout.write("   %s\n" % L.rstrip())
					self.err_count += 1
				else:
					r = Recipe.factory(self.recipe_dict['name'], "".join(self.recipeBody))
					warnings = r.warnings()
					info = r.info()
					if len(warnings) or len(info):
						if not self.analyseonly:
							for L in self.recipeBody:
								if not L.startswith('+'):
									sys.stdout.write("   %s\n" % L.rstrip())
						self.warn_count += len(warnings)
	
				self.recipeBody = []
			return
		elif not self.inRecipe and self.isMakeError(text):
			# these two statements pick up errors coming from make
			self.err_count += 1
			sys.stderr.write("    %s\n" % text.rstrip())
			return
		elif not self.inRecipe and self.isMakeWarning(text):
			self.warn_count += 1
			sys.stdout.write("    %s\n" % text.rstrip())
			return
		elif text.startswith("<![CDATA["):
                	# save CDATA body during a recipe
			if self.inRecipe:
				self.inBody = True
		elif text.startswith("]]>"):
			if self.inRecipe:
				self.inBody = False
				if self.recipelineExceeded > 0:
					self.recipeBody.append("[filter_terminal: OUTPUT TRUNCATED: " + \
						"Recipe output limit exceeded; see logfile for full output " + \
						"(%s lines shown out of %s)]" % (FilterTerminal.recipelinelimit, \
						FilterTerminal.recipelinelimit + self.recipelineExceeded))
		elif text.startswith("<info>Copied"):
			if not self.analyseonly and not self.quiet:
				start = text.find(" to ") + 4
				end = text.find("</info>",start)
				short_target = text[start:end]
				if short_target.startswith(self.epocroot):
					short_target = short_target.replace(self.epocroot,"")[1:]
				short_target = generic_path.Path(short_target).GetShellPath()
				sys.stdout.write(" %s: %s\n" % ("export".ljust(FilterTerminal.recipewidth), short_target))
			return
		elif text.find("<rm files") != -1 or text.find("<rmdir ") != -1:
			# search for cleaning output but only if we 
			# are not in some recipe (that would be pointless)
			if not self.analyseonly and not self.quiet:
				if  self.cleaned == 0:
					sys.stdout.write("\ncleaning ")
					self.cleaned+=1
				elif self.dotcount < FilterTerminal.maxdots:
					if self.cleaned % 5 == 0:
						self.dotcount+=1
						sys.stdout.write(".")
					self.cleaned+=1
			
				return
		elif self.inBody:
			# We are parsing the output from a recipe
			# we have to keep the output until we find out
			# if the recipe failed. But not all of it if it turns
			# out to be very long
			if len(self.recipeBody) <= FilterTerminal.recipelinelimit:
				self.recipeBody.append(text)
			else:
				self.recipelineExceeded += 1
		elif text.startswith("<info>Buildable configuration '"):
			# <info>Buildable configuration 'name'</info>
			self.built_configs.append(text[30:-8])

	def logit(self):
		""" log a message """
		info = self.recipe_dict['mappedname'].ljust(FilterTerminal.recipewidth)
		config = self.recipe_dict['config']
		name = self.recipe_dict['name_to_user'].lstrip()
		# If its a multifile config, we print source files one below the other in a single
		# 'compile:' statement
		if config.endswith('multifile'):
			files =  self.recipe_dict['name_to_user'].split()
			name = ""
			for i in files:
				if i == files[0]:
					name +=  i
				else:
					name +=  '\n\t      ' + i
		sys.stdout.write(" %s: %s  \t[%s]\n" % (info, name, config))

	def logit_if(self):
		""" Tell the user about the recipe that we are processing """
		if not self.analyseonly and not self.quiet:
			if self.inRecipe and not self.current_recipe_logged:
				self.logit()
				self.current_recipe_logged = True
	
	def summary(self):
		"""Errors and warnings summary"""
		
		if self.raptor.skipAll or self.analyseonly:
			return


		if self.cleaned != 0:
			sys.stdout.write("\n\n")

		if self.warn_count > 0 or self.err_count > 0:
			sys.stdout.write("\n%s : warnings: %s\n" % (raptor.name,
					self.warn_count))
			sys.stdout.write("%s : errors: %s\n\n" % (raptor.name,
					self.err_count))
		else:
			sys.stdout.write("\nno warnings or errors\n\n")

		for bc in self.built_configs:
			sys.stdout.write("built " + bc + "\n")
			
		sys.stdout.write("\nRun time %d seconds\n" % self.raptor.runtime);
		sys.stdout.write("\n")
		return True
	
	def close(self):
		"""Tell raptor that there were errors."""
		if self.err_count > 0:
			return False
		return True

