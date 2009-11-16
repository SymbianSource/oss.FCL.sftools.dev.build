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
# PluginBox module - finds classes 
#

from os import listdir
import re
from types import TypeType, ModuleType
import sys

class PluginModule(object):
	"""Represents a module containing plugin classes """
	def __init__(self, file):
		self.module = __import__(file)
		self.classes = []
		self.__findclasses(self.module)

	def __findclasses(self,module):
		for c in module.__dict__:
			mbr = module.__dict__[c]
			if type(mbr) == TypeType:
				self.classes.append(mbr)

class PluginBox(object):
	"""
	A container that locates all the classes in a directory.
	Example usage:

		from person import Person
		ps = PluginBox("plugins")
		people = []
		for i in ps.classesof(Person):
			people.append(i())

	"""
	plugfilenamere=re.compile('^(.*)\.py$',re.I)
	def __init__(self, plugindirectory):
		self.pluginlist = []
		self.plugindir = plugindirectory
		sys.path.append(str(self.plugindir))
		for f in listdir(plugindirectory):
			m = PluginBox.plugfilenamere.match(f)
			if m is not None:
				self.pluginlist.append(PluginModule(m.groups()[0]))
		sys.path = sys.path[:-1]

	def classesof(self, classtype):
		"""return a list of all classes that are subclasses of <classtype>"""
		classes = []
		for p in self.pluginlist:
			for c in p.classes:
				if issubclass(c, classtype):
					if c.__name__ != classtype.__name__:
						classes.append(c)
		return classes

