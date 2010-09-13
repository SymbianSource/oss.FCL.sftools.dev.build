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
# Filter class for generating HTML summary pages
#

import os
import re
import csv
import sys
import shutil
import tempfile
import filter_interface

class HTML(filter_interface.FilterSAX):

	def __init__(self, params = []):
		"""parameters to this filter are..."""
		super(HTML, self).__init__()
	
	# FilterSAX method overrides
	
	def startDocument(self):
		
		if self.params.logFileName:
			self.dirname = str(self.params.logFileName).replace("%TIME", self.params.timestring) + "_html"
		else:
			self.dirname = "html" # writing to stdout doesn't make sense
		
		# read regular expressions from the first file on the config path
		self.regex = []
		for p in self.params.configPath:
			if not p.isAbsolute():
				p = self.params.home.Append(p)
				
			csv = p.Append("logfile_regex.csv")
			if csv.isFile():
				self.regex = self.readregex(str(csv))
				break
		
		self.elements = []
		self.recipe_tag = None
		self.error_tag = None
		self.warning_tag = None
		
		self.components = {}
		self.configurations = {}
		self.totals = Records()
		
		# create all the directories
		for s in Records.SUBDIRS:
			dir = os.path.join(self.dirname, s)
			if not os.path.isdir(dir):
				try:
					os.makedirs(dir)
				except:
					return self.err("could not create directory '%s'" % dir)
				
		# create an index.html
		try:
			indexname = os.path.join(self.dirname, "index.html")
			
			self.index = open(indexname, "w")
			self.index.write("""<html>
<head>
<title>Raptor Build Summary</title>
<link type="text/css" rel="stylesheet" href="style.css">
</head>
<body>
<h1>Raptor Build Summary</h1>
""")				
		except:
			return self.err("could not create file '%s'" % indexname)
		
		# copy over a style file if none exists in the output already
		css = os.path.join(self.dirname, "style.css")
		if not os.path.isfile(css):
			try:
				style = str(self.params.home.Append("style/filter_html.css"))
				shutil.copyfile(style, css)
			except:
				self.moan("could not copy '%s' to '%s'" % (style, css))
				
		# create a temporary file to record all the "what" files in. We can
		# only test the files for existence after "make" has finished running.
		try:
			self.tmp = tempfile.TemporaryFile()
		except:
			return self.err("could not create temporary file")
		
		return self.ok
		
	def startElement(self, name, attributes):
		"call the start handler for this element if we defined one."
		
		self.generic_start(name)    # tracks element nesting
		
		function_name = "start_" + name
		try:
			HTML.__dict__[function_name](self, attributes)
		except KeyError:
			pass
			
	def characters(self, char):
		"process [some of] the body text for the current element."
		
		function_name = "char_" + self.elements[-1]
		try:
			HTML.__dict__[function_name](self, char)
		except KeyError:
			pass
		
	def endElement(self, name):
		"call the end handler for this element if we defined one."
		
		function_name = "end_" + name
		try:
			HTML.__dict__[function_name](self)
		except KeyError:
			pass
		
		self.generic_end()    # tracks element nesting
	
	def endDocument(self):
		
		self.existencechecks()
		self.dumptotals()
		try:
			self.index.write("<p><table><tr><th></th>")
			
			for title in Records.TITLES:
				self.index.write('<th class="numbers">%s</th>' % title)
			
			self.index.write("</tr>")
			self.index.write(self.totals.tablerow("total"))
			self.index.write("</table>")
			
			
			self.index.write("<h2>by configuration</h2>")
			self.index.write("<p><table><tr><th></th>")
			
			for title in Records.TITLES:
				self.index.write('<th class="numbers">%s</th>' % title)
			
			self.index.write("</tr>")
			
			# the list of configuration names in alphabetical order
			names = self.configurations.keys()
			names.sort()
			
			# print the "unknown" configuration results first
			if 'unknown' in names:
				self.index.write(self.configurations['unknown'].tablerow("no specific configuration"))
				names.remove('unknown')
				
			# print the rest
			for name in names:
				self.index.write(self.configurations[name].tablerow(name))
			
			self.index.write("</table>")
			
			
			self.index.write("<h2>by component</h2>")
			self.index.write("<p><table><tr><th></th>")
			
			for title in Records.TITLES:
				self.index.write('<th class="numbers">%s</th>' % title)
			
			self.index.write("</tr>")
			
			# the list of component names in alphabetical order
			names = self.components.keys()
			names.sort()
			
			# print the "unknown" component results first
			if 'unknown' in names:
				self.index.write(self.components['unknown'].tablerow("no specific component"))
				names.remove('unknown')
				
			# print the rest
			for name in names:
				self.index.write(self.components[name].tablerow(name))
			
			self.index.write("</table>")	
			self.index.write("</body></html>")
			self.index.close()
		except Exception, e:
			return self.err("could not close index " + str(e))
		
	# error and warning exception handlers for FilterSAX
	
	def error(self, exception):
		self.fatalError(exception) # all errors are fatal
		
	def fatalError(self, exception):
		self.err("exception " + str(exception))
		
	def warning(self, exception):
		"""only print warnings if no errors have occurred yet.
		
		because after an error everything goes mad."""
		if self.ok:
			sys.stderr.write(self.formatWarning("HTML filter " + str(exception)))
	
	# our error handling functions
	
	def err(self, text):
		"""only print the first error, then go quiet.
		
		because after a fatal error there are usually hundreds of
		meaningless repeats and/or garbage that doesn't help anyone."""
		if self.ok:
			sys.stderr.write(self.formatError("HTML filter " + text))
		self.ok = False
		return self.ok
	
	def moan(self, text):
		"""print a warning about something that is annoying but not fatal."""
		if self.ok:
			sys.stderr.write(self.formatWarning("HTML filter " + text))
		return self.ok
	
	# our content handling functions
	
	def start_buildlog(self, attributes):
		try:
			self.index.write("<p><tt>sbs " + attributes['sbs_version'] + "</tt>")
		except KeyError:
			pass
	
	def end_buildlog(self):
		pass
		
	def start_recipe(self, attributes):
		self.recipe_tag = TaggedText(attributes)
		
	def char_recipe(self, char):
		self.recipe_tag.text += char
		
	def end_recipe(self):
		# an "ok" recipe may contain warnings / remarks
		if self.recipe_tag.exit == 'ok':
			self.record(self.recipe_tag, self.classify(self.recipe_tag.text))
		
		# a "failed" recipe is always an error
		elif self.recipe_tag.exit == 'failed':
			self.record(self.recipe_tag, Records.ERROR)
		
		# "retry" should just be ignored (for now)
		# but will be recorded in a later version.
		
		self.recipe_tag = None
	
	def start_status(self, attributes):
		try:
			if self.recipe_tag:
				self.recipe_tag.exit = attributes['exit']
				self.recipe_tag.code = attributes['code']
			else:
				self.err("status element not inside a recipe element")
		except KeyError:
			pass
		
	def start_error(self, attributes):
		self.error_tag = TaggedText(attributes)
	
	def char_error(self, char):
		self.error_tag.text += char
		
	def end_error(self):
		self.record(self.error_tag, Records.ERROR)
		self.error_tag = None
		
	def start_warning(self, attributes):
		self.warning_tag = TaggedText(attributes)
	
	def char_warning(self, char):
		self.warning_tag.text += char
		
	def end_warning(self):
		self.record(self.warning_tag, Records.WARNING)
		self.warning_tag = None
	
	def start_whatlog(self, attributes):
		try:
			for attrib in ['bldinf', 'config']:
				self.tmp.write("|")
				if attrib in attributes:
					self.tmp.write(attributes[attrib])
			self.tmp.write("\n")
		except:
			return self.err("could not write to temporary file")
	
	def start_export(self, attributes):
		try:
			self.tmp.write(attributes['destination'] + "\n")
		except:
			return self.err("could not write to temporary file")
		
	def start_resource(self, attributes):
		self.resource_tag = ""
		
	def char_resource(self, char):
		self.resource_tag += char
		
	def end_resource(self):
		try:
			self.tmp.write(self.resource_tag.strip() + "\n")
		except:
			return self.err("could not write to temporary file")

	def start_bitmap(self, attributes):
		self.bitmap_tag = ""
		
	def char_bitmap(self, char):
		self.bitmap_tag += char
		
	def end_bitmap(self):
		try:
			self.tmp.write(self.bitmap_tag.strip() + "\n")
		except:
			return self.err("could not write to temporary file")
	
	def start_stringtable(self, attributes):
		self.stringtable_tag = ""
		
	def char_stringtable(self, char):
		self.stringtable_tag += char
		
	def end_stringtable(self):
		try:
			self.tmp.write(self.stringtable_tag.strip() + "\n")
		except:
			return self.err("could not write to temporary file")

	def start_member(self, attributes):
		self.member_tag = ""
		
	def char_member(self, char):
		self.member_tag += char
		
	def end_member(self):
		try:
			self.tmp.write(self.member_tag.strip() + "\n")
		except:
			return self.err("could not write to temporary file")
	
	def start_build(self, attributes):
		self.build_tag = ""
		
	def char_build(self, char):
		self.build_tag += char
		
	def end_build(self):
		try:
			self.tmp.write(self.build_tag.strip() + "\n")
		except:
			return self.err("could not write to temporary file")
				
	# even if we ignore an element we need to mark its coming and going
	# so that we know which element any character data belongs to.
	
	def generic_start(self, name):
		self.elements.append(name)
	
	def generic_end(self):
		self.elements.pop()

	# text classification
	
	def classify(self, text):
		"test the text for errors, warnings and remarks."
		
		# there shouldn't actually be any errors in here because we
		# are only looking at "ok" recipes... BUT there are bad tools
		# out there which don't set an error code when they fail, so
		# we should look out for those cases.
		
		for line in text.splitlines():
			if not line or line.startswith("+"):
				continue    # it is a blank line or a command, not its output
			
			# the first expression that matches wins
			for r in self.regex:
				if r[0].search(line):
					return r[1]
		
		return Records.OK
	
	# reporting of "errors" to separate files
	
	def record(self, taggedtext, type):
		if self.totals.isempty(type):
			self.createoverallfile(type)
		self.appendoverallfile(type, taggedtext)
		
		configuration = taggedtext.config
		
		if configuration in self.configurations:
			if self.configurations[configuration].isempty(type):
				self.createconfigurationfile(configuration, type)
				
			self.appendconfigurationfile(configuration, type, taggedtext)
		else:
			# first time for configuration
			self.configurations[configuration] = Records()
			self.createconfigurationfile(configuration, type)
			self.appendconfigurationfile(configuration, type, taggedtext)
			
		component = taggedtext.bldinf
		
		if component in self.components:
			if self.components[component].isempty(type):
				self.createcomponentfile(component, type)
				
			self.appendcomponentfile(component, type, taggedtext)
		else:
			# first time for component
			self.components[component] = Records()
			self.createcomponentfile(component, type)
			self.appendcomponentfile(component, type, taggedtext)
	
	def createoverallfile(self, type):
		if type == Records.OK:
			# we don't want to show successes, just count them
			return
		
		linkname = os.path.join(Records.SUBDIRS[type], "overall.html")
		filename = os.path.join(self.dirname, linkname)
		title = Records.TITLES[type] + " for all configurations"
		try:
			file = open(filename, "w")
			file.write("<html><head><title>%s</title>" % title)
			file.write('<link type="text/css" rel="stylesheet" href="../style.css"></head><body>')
			file.write("<h1>%s</h1>" % title)
			file.close()
		except:
			return self.err("cannot create file '%s'" % filename)
		
		self.totals.set(type, 'filename', filename)
		self.totals.set(type, 'linkname', linkname)
	
	def appendoverallfile(self, type, taggedtext):
		self.totals.inc(type, 'N')   # one more and counting
		
		if type == Records.OK:
			# we don't want to show successes, just count them
			return
		
		filename = self.totals.get(type, 'filename')
		try:
			file = open(filename, "a")
			file.write("<p>component: %s " % taggedtext.bldinf)
			file.write("config: %s\n" % taggedtext.config)
			file.write("<pre>" + taggedtext.text.strip() + "</pre>")
			file.close()
		except:
			return self.err("cannot append to file '%s'" % filename)
		
	def createconfigurationfile(self, configuration, type):
		if type == Records.OK:
			# we don't want to show successes, just count them
			return
		
		linkname = os.path.join(Records.SUBDIRS[type], "cfg_" + configuration + ".html")
		filename = os.path.join(self.dirname, linkname)
		title = Records.TITLES[type] + " for configuration " + configuration
		try:
			file = open(filename, "w")
			file.write("<html><head><title>%s</title>" % title)
			file.write('<link type="text/css" rel="stylesheet" href="../style.css"></head><body>')
			file.write("<h1>%s</h1>" % title)
			file.close()
		except:
			return self.err("cannot create file '%s'" % filename)
		
		self.configurations[configuration].set(type, 'filename', filename)
		self.configurations[configuration].set(type, 'linkname', linkname)
	
	def appendconfigurationfile(self, configuration, type, taggedtext):
		self.configurations[configuration].inc(type, 'N')   # one more and counting
		
		if type == Records.OK:
			# we don't want to show successes, just count them
			return
		
		filename = self.configurations[configuration].get(type, 'filename')
		try:
			file = open(filename, "a")
			file.write("<p>component: %s\n" % taggedtext.bldinf)
			file.write("<pre>" + taggedtext.text.strip() + "</pre>")
			file.close()
		except:
			return self.err("cannot append to file '%s'" % filename)
		
	def createcomponentfile(self, component, type):
		if type == Records.OK:
			# we don't want to show successes, just count them
			return
		
		linkname = os.path.join(Records.SUBDIRS[type], "bld_" + re.sub("[/:]","_",component) + ".html")
		filename = os.path.join(self.dirname, linkname)
		title = Records.TITLES[type] + " for component " + component
		try:
			file = open(filename, "w")
			file.write("<html><head><title>%s</title>" % title)
			file.write('<link type="text/css" rel="stylesheet" href="../style.css"></head><body>')
			file.write("<h1>%s</h1>" % title)
			file.close()
		except:
			return self.err("cannot create file '%s'" % filename)
		
		self.components[component].set(type, 'filename', filename)
		self.components[component].set(type, 'linkname', linkname)
	
	def appendcomponentfile(self, component, type, taggedtext):
		self.components[component].inc(type, 'N')   # one more and counting
		
		if type == Records.OK:
			# we don't want to show successes, just count them
			return
		
		filename = self.components[component].get(type, 'filename')
		try:
			file = open(filename, "a")
			file.write("<p>config: %s\n" % taggedtext.config)
			file.write("<pre>" + taggedtext.text.strip() + "</pre>")
			file.close()
		except:
			return self.err("cannot append to file '%s'" % filename)

	def existencechecks(self):
		try:
			self.tmp.flush()	# write what is left in the buffer
			self.tmp.seek(0)	# rewind to the beginning
			
			missing_tag = TaggedText({})
			missed = set()    # only report missing files once
			
			for line in self.tmp.readlines():
				if line.startswith("|"):
					parts = line.split("|")
					attribs = { 'bldinf' : parts[1].strip(),
							    'config' : parts[2].strip() }
					missing_tag = TaggedText(attribs)
				else:
					filename = line.strip()
					if not filename in missed and not os.path.isfile(filename):
						missing_tag.text = filename
						self.record(missing_tag, Records.MISSING)
						missed.add(filename)
					
			self.tmp.close()	# this also deletes the temporary file
		except Exception,e:
			return self.err("could not close temporary file " + str(e))
	
	def dumptotals(self):
		"""write the numbers of errors, warnings etc. into a text file.
		
		so that a grand summariser can tie together individual log summaries
		into one big summary page."""
		try:
			filename = os.path.join(self.dirname, "totals.txt")
			file = open(filename, "w")
			file.write(self.totals.textdump())
			file.close()
		except:
			self.err("cannot write totals file '%s'" % filename)
		
	def readregex(self, csvfile):
		"""read the list of regular expressions from a csv file.
		
		the file format is TYPE,REGEX,DESCRIPTION
		
		If the description is "ignorecase" then the regular expression is
		compiled with re.IGNORECASE and will match case-insensitively.
		"""
		regexlist = []
		try:
			reader = csv.reader(open(csvfile, "rb"))
			for row in reader:
				try:
					type = None
					
					if row[0] == "CRITICAL" or row[0] == "ERROR":
						type = Records.ERROR
					elif row[0] == "WARNING":
						type = Records.WARNING
					elif row[0] == "REMARK":
						type = Records.REMARK
						
					# there are other types like INFO that we don't
					# care about so silently ignore them.
					if type:
						if row[2].lower() == "ignorecase":
							regex = re.compile(row[1], re.I)
						else:
							regex = re.compile(row[1])
						regexlist.append((regex, type))
				except:
					self.moan("ignored bad regex '%s' in file '%s'" % (row[1], csvfile))
		except Exception, ex:
			self.err("cannot read regex file '%s': %s" % (csvfile, str(ex)))
			return []
		
		return regexlist
	
class Records(object):
	"a group of related records e.g. errors, warnings and remarks."
	
	# the different types of record we want to group together
	OK      = 0
	ERROR   = 1
	WARNING = 2
	REMARK  = 3
	MISSING = 4
	
	SUBDIRS = [ "ok", "error", "warning", "remark", "missing" ]
	TITLES = [ "OK", "Errors", "Warnings", "Remarks", "Missing files" ]
	
	def __init__(self):
		self.data = [ {'N':0}, {'N':0}, {'N':0}, {'N':0}, {'N':0} ]
	
	def get(self, index, item):
		try:
			return self.data[index][item]
		except KeyError:
			return None
		
	def inc(self, index, item):
		self.data[index][item] += 1
	
	def isempty(self, index):
		return (self.data[index]['N'] == 0)
		
	def set(self, index, item, value):
		self.data[index][item] = value
	
	def tablerow(self, name):
		row = '<tr><td class="name">%s</td>' % name

		for i,datum in enumerate(self.data):
			number = datum['N']
			if number == 0:
				row += '<td class="zero">0</td>'
			else:
				row += '<td class="' + Records.SUBDIRS[i] + '">'
				try:
					link = datum['linkname']
					row += '<a href="%s">%d</a></td>' % (link,number)
				except KeyError:
					row += '%d</td>' % number
							
		row += "</tr>"
		return row
	
	def textdump(self):
		text = ""
		for i,datum in enumerate(self.data):
			number = datum['N']
			if number == 0:
				style = "zero"
			else:
				style = Records.SUBDIRS[i]
			text += str(i) + ',' + style + "," + str(number) + "\n"
		return text
				
class TaggedText(object):
	def __init__(self, attributes):
		
		for attrib in ['bldinf', 'config']:
			self.__dict__[attrib] = "unknown"
			if attrib in attributes:
				value = attributes[attrib]
				if value:
					self.__dict__[attrib] = value

		self.text = ""
		
# the end