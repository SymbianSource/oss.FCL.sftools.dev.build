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
# Annofile class
#

import xml.sax
import os

class Annofile(xml.sax.handler.ContentHandler):
	"""A class to represent an emake anno file"""

	def __init__(self, name, maxagents=30):
		self.name = name
		self.overallAggregateTime = 0
		self.duration = 0
		self.inJob = False
		self.inMetricDuration = False
		self.jobType = ''
		self.nodes = set()
		self.maxagents = maxagents

		parser = xml.sax.make_parser()
		parser.setContentHandler(self)
		try:
			parser.parse(open(name))
		except xml.sax._exceptions.SAXParseException, e:
			print "Error:\n" + str(e)
			print "Ignore that file, parsing continues..."

	
	def startElement(self, name, attrs):
		if name == 'build':
			# attrs.get() returns unicode type
			self.cm = attrs.get('cm', '')
					
		elif name == 'job':
			self.inJob = True
			self.jobType = attrs.get('type', '')

		elif name == 'timing':
			# Find agent number
			node = attrs.get('node')
			if node not in self.nodes:
				self.nodes.add(node)
			
			# Calculate aggregate build time
			# This is the sum of time spending on each node
			# Ideally it equals the build time if there is 
			# only one node
			time = float(attrs.get('completed')) \
				- float(attrs.get('invoked'))
			self.overallAggregateTime += time

			# Calculate parse time
			if self.inJob and self.jobType == 'parse':
				self.parseTime = time

		elif name == 'metric':
			if attrs.get('name') == 'duration':
				self.inMetricDuration = True
			

	def endElement(self, name):
		if name == 'job':
			self.inJob = False
		elif name == 'metric':
			if self.inMetricDuration:
				self.inMetricDuration = False

		# Parse to the end of XML file
		elif name == 'build':
			self.doFinal()
	
	def characters(self, ch):
		if self.inMetricDuration:
			self.duration = ch


	# Get class attributes

	def getParseTime(self):
		"""Get the time that emake spends on 
		parsing all makefiles
		"""
		return self.parseTime

	def getOverallDuration(self):
		"""Get the overall build duration"""
		return float(self.duration)
	
	def getClusterManager(self):
		return self.cm

	def getAggregateTime(self):
		"""This is the sum of time spending on each node.
		Ideally it equals the build time if there is 
		only one node
		"""
		return self.overallAggregateTime
	
	# Calculate two efficiencies: 
	# first includes makefile parse time; second doesn't 
	def getEfficiency(self):
		"""100% means all nodes are busy from start to finish.
		"""
		at = self.getAggregateTime()
		num = self.maxagents
		d = self.getOverallDuration()
		
		idealDuration = at / num
		if d != 0:
			efficiency = round(idealDuration / d, 3)
		else:	
			efficiency = 0

		# This is efficiency WITHOUT counting makefile
		# parsing time.  Tempararily still useful.
		pt = self.getParseTime()
		idealD_wo = (at - pt) / num
		if d != pt:
			e_wo = round(idealD_wo / (d - pt), 3)
		else:
			e_wo = 0
		
		#return str(efficiency * 100) + '%', str(e_wo * 100) + '%'
		return efficiency, e_wo

	def doFinal(self):	
		report = open('anno_report.xml', 'a')
		report.write("<annofile name='%s'>\n" % self.name)	
		report.write("<metric name='agentNumber' value='%s'/>\n" % len(self.nodes))
		report.write("<metric name='makefileParseTime' value='%s'/>\n" \
				% self.getParseTime())
		report.write("<metric name='duration' value='%s'/>\n" \
				% self.getOverallDuration())
		report.write("<metric name='aggregateTime' value='%s'/>\n" \
				% self.getAggregateTime())
		report.write("<metric name='efficiency' value='%f'/>\n" \
				% self.getEfficiency()[0])
		report.write("<metric name='efficiencyNoMakefile' value='%f'/>\n" \
				% self.getEfficiency()[1])
		report.write("</annofile>\n")
		report.close()

	def __str__(self):
		s = " <metric name='agentcount' value='%d' />\n" % len(self.nodes) + \
			" <metric name='maxagents' value='%d' />\n" % self.maxagents + \
			" <metric name='parsetimesecs' value='%s' />\n" % self.getParseTime() + \
			" <metric name='overallduration' value='%s' />\n" % self.getOverallDuration() + \
			" <metric name='aggregatetime' value='%s' />\n" % self.getAggregateTime() + \
			" <metric name='efficiency' value='%s' />\n" % self.getEfficiency()[0] + \
			" <metric name='efficiency_nomake' value='%s' />\n" % self.getEfficiency()[1] 

		return s
	


if __name__ == '__main__':
	
	# Work around annoying DOCTYPE error by 
	# creating a dummy DTD file	
	if not os.path.exists('build.dtd'):
		dummy = open('build.dtd', 'w')
		dummy.close()

	################## Edit this basepath ################
	basepath = '92_7952_201022_logs\\output\\logs'
	######################################################

	# Find out all the annofiles
	annofiles = []
	for dirpath, dirs, files in os.walk(basepath):
		for f in files:
			if f.endswith('.anno') or f.endswith('.anno.xml'):
				annofiles.append(dirpath + '\\' + f)

	#print annofiles # debug
	
	# Parse all the annofiles and generate report
	# Write XML header
	report = open('anno_report.xml', 'w')
	report.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
	report.write("<report>\n")
	report.close()
	# Parse each annofile
	#num = 0 # debug
	parser = xml.sax.make_parser()
	for afilename in annofiles:
		parser.setContentHandler(Annofile(afilename))
		try:
			parser.parse(open(afilename))
		except xml.sax._exceptions.SAXParseException, e:
			print "Error:\n" + str(e)
			print "Ignore that file, parsing continues..."
			
		#num += 1 # <debug> only process num annofiles
		#if num == 3:
		#	break

	# Write XML footer
	report = open('anno_report.xml', 'a')
	report.write("</report>")
	report.close()

