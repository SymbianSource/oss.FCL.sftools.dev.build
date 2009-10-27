#
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Raptor Binary Variation var file to xml spec generator
# Given a set of .var files, this script will generate an xml specification file
#


import sys,os,re,fnmatch
import xml.dom.minidom 
from optparse import OptionParser

doc = xml.dom.minidom.Document()
class VarFile:

	def __init__(self,aFile):
		self.virtual = False
		self.varname = ""
		self.varhrh = ""
		self.build_include = ""
		self.rom_include = ""
		self.extends = ""
		self.file = aFile

	# Parse the var file
	def ParseVarFile(self):
		file = open(self.file)
		vardata = file.readlines()
		for var in vardata:
			if re.match('VARIANT\s+(?P<VARIANTNAME>\w+)',var):
				self.varname = re.match('VARIANT\s+(?P<VARIANTNAME>\w+)',var)
			elif re.match('VARIANT_HRH\s+(?P<VARIANTHRH>.+)',var):
				self.varhrh  = re.match('VARIANT_HRH\s+(?P<VARIANTHRH>.+)',var)
			elif re.match('VIRTUAL\s+$',var):
				self.virtual = True
			elif re.match('BUILD_INCLUDE\s+.+',var):
				self.build_include = re.match('BUILD_INCLUDE\s+(?P<PROPERTY>\w+)\s+(?P<LOCATION>.+)',var)
			elif re.match('ROM_INCLUDE\s+.+',var):
				self.rom_include = re.match('ROM_INCLUDE\s+(?P<PROPERTY>\w+)\s+(?P<LOCATION>.+)',var)
			elif re.match('EXTENDS\s+(?P<EXTENDS>\w+)',var):
				self.extends = re.match('EXTENDS\s+(?P<EXTENDSNODE>\w+)',var)
		if self.varname:
			self.varname = self.varname.group('VARIANTNAME')
		if self.varhrh:
			self.varhrh  = self.varhrh.group('VARIANTHRH')
		if self.extends:
			self.extends = self.extends.group('EXTENDSNODE')
		file.close()
	
	# Write the specs for a variant object and attach it to a parent node
	def CreateSpec(self,parentNode):
	
		var = doc.createElement("var")
		parentNode.appendChild(var)

		# Set the FEATUREVARIANT name
		vname = doc.createElement("set")
		vname.setAttribute("name","FEATUREVARIANT")
		vname.setAttribute("value",self.varname)
		if self.virtual:
			vname.setAttribute("abstract","true")
		var.appendChild(vname)

		# Set the VARIANT_HRH name
		hrhname = doc.createElement("set")
		hrhname.setAttribute("name","VARIANT_HRH")
		hrhname.setAttribute("value",self.varhrh)
		var.appendChild(hrhname)

		# Set the build includes
		if self.build_include:
			buildincs = doc.createElement(self.build_include.group('PROPERTY'))
			buildincs.setAttribute("name","BUILD_INCLUDE")
			buildincs.setAttribute("value",self.build_include.group('LOCATION'))
			var.appendChild(buildincs)

		# Set the rom includes
		if self.rom_include:
			buildincs = doc.createElement(self.rom_include.group('PROPERTY'))
			buildincs.setAttribute("name","ROM_INCLUDE")
			buildincs.setAttribute("value",self.rom_include.group('LOCATION'))
			var.appendChild(buildincs)

# Main function
def main():

	parser = OptionParser(prog = "vartoxml.py")
	parser.add_option("-s","--sourcefile",action="append",dest="varfile",help="List of var files")
	parser.add_option("-o","--output",action="store",dest="outputxml",help="Output xml file")
	parser.add_option("-d","--folder",action="store",dest="folder",help="Folder names to search for var files")

	(options, leftover_args) = parser.parse_args(sys.argv[1:])
	
	childlist = [] 
	addedlist = []
	nodesList = []
	childnames = []
	i = 0
	
	# Get the list of .var file from the specified folder(s)
	if options.folder:
		for folder in options.folder:
			for fileName in os.listdir (folder):
				if fnmatch.fnmatch (fileName,'*.var'):
					if options.varfile:
						options.varfile.append(fileName)
					else:
						options.varfile = []
						options.varfile.append(fileName)
	
	# We need some source files for this script to work
	if not options.varfile:
		print "Error: No source files specified "
		sys.exit()
		
	# Set parent node to gibberish
	parentNode = doc.createElement("build")
	doc.appendChild(parentNode)
	newparentNode = ""
	
	# Removes duplicate elements in the arguments and iterate through them
	# to find the top-level abstract parent node
	for arg in list(set(options.varfile)):
		varobj = VarFile(arg)
		varobj.ParseVarFile()
		if varobj.extends:
			childlist.append(varobj)
		else:
			addedlist.append(varobj)
			conf = doc.createElement("config")
			conf.setAttribute("name",varobj.varname)
			parentNode.appendChild(conf)
			varobj.CreateSpec(conf)
			nodesList.append(conf)
	
	# Names of all the children need to be stored separately
	for c in childlist:
		childnames.append(c.varname)

	childlist2 = list(childlist)

	# Check the list is correct, and append orphan nodes to master BUILD node
	for ch in childlist2:
		if addedlist:
			if not ch.extends in addedlist[0].varname:
				if not ch.extends in childnames:
					conf = doc.createElement("config")
					conf.setAttribute("name",ch.varname)
					parentNode.appendChild(conf)
					varobj.CreateSpec(conf)
					nodesList.append(conf)
					addedlist.append(ch)
					childlist.remove(ch)
		else:
			if not ch.extends in childnames:
				conf = doc.createElement("config")
				conf.setAttribute("name",ch.varname)
				parentNode.appendChild(conf)
				varobj.CreateSpec(conf)
				nodesList.append(conf)
				addedlist.append(ch)
				childlist.remove(ch)
				
	# Make a copy of the new childlist
	childlist2 = list(childlist)

	# Go through all the children, and add them to the xml spec
	while (childlist2):
		# Refactor the childlist to remove elements which have been added
		for add in addedlist:
			if add in childlist:
				childlist.remove(add)
		for ch in childlist:
			if ch.extends == addedlist[i].varname:
				addedlist.append(ch)
				childlist2.remove(ch)
				conf = doc.createElement("config")
				conf.setAttribute("name",ch.varname)
				nodesList[i].appendChild(conf)
				nodesList.append(conf)
				ch.CreateSpec(conf)
			else:
				pass
		i = i + 1
	
	# If output xml file is specified, write to it otherwise print the xml to screen
	if options.outputxml:
		file = open(options.outputxml,"w")
		file.writelines(doc.toprettyxml(indent="  "))
		file.close()
	else:
		print doc.toprettyxml(indent="  ")


if __name__ == "__main__":
    main()
