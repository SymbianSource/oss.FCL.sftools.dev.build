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
# Filter to write out a list of executable files built per sysdef layer

import filter_interface
import sys
import os.path
import os

class Filter_EXEs(filter_interface.PerRecipeFilter):
	def __init__(self, params):
		super(Filter_EXEs, self).__init__()
		
		try:
			params = self.parseNamedParams(['layer','config','output'],params)
			# e.g. ['layer=a','config=armv5_udeb','config=armv5_urel']
		except ValueError:
			raise ValueError("All parameters to the Filter_EXEs filter must be labelled.  Valid labels are 'layer','config' and 'output'.")
		else:
			self.layers = params['layer']
			self.configs = params['config']
			output = params['output']
			if len(output) > 1:
				raise ValueError("Only one 'output' parameter to the Filter_EXEs filter is permissible.")
			if len(output) > 0:
				self.output = output[0]

				if not os.path.isdir(self.output):
					os.makedirs(self.output)

			self.unmatchedlayers = self.layers[:] # [:] = Shallow copy, not ref
			self.unmatchedconfigs = self.configs[:]
			self.fileswritten = {}

	def handleRecipe(self):
		if (self.name == 'linkandpostlink' or self.name == 'win32simplelink') and self.target.endswith('.exe'):
			if ((len(self.configs) == 0 or (self.config in self.configs)) and
			  (len(self.layers) == 0 or (self.layer in self.layers))):
				layer = self.formatData('layer') or 'nolayer'
				config = self.formatData('config') or 'noconfig'
				filename = "{0}_{1}.txt".format(layer,config)
				try:
					filename = os.path.join(self.output, filename)
				except AttributeError:
					pass # No output path to join

				if not filename in self.fileswritten:
					newfilename = filename
					if os.path.exists(filename):
						# Oops - file already exists
						index = 2 # Start with .txt2
						while os.path.exists(filename+str(index)):
							index += 1
						newfilename = filename+str(index)
					file = open(newfilename,"w")
					self.fileswritten[filename] = (newfilename, 1, file)
				else:
					(realfilename, num, file) = self.fileswritten[filename]
					self.fileswritten[filename] = (realfilename, num+1, file)

				file.write(os.path.basename(self.target)+"\n")

				try:
					self.unmatchedlayers.remove(self.layer)
				except ValueError:
					# Already removed
					pass
				try:
					self.unmatchedconfigs.remove(self.config)
				except ValueError:
					# Already removed
					pass
		return True

	def summary(self):
		if len(self.layers) > 0:
			for layer in self.unmatchedlayers:
				self.info("Layer '{0}' did not match any EXEs\n".format(layer))
		if len(self.configs) > 0:
			for config in self.unmatchedconfigs:
				self.info("Config '{0}' did not match any EXEs\n".format(config))
		for (filename, num, file) in self.fileswritten.values():
			file.close()
			self.info("Wrote {0} file(s) into {1}\n".format(num, filename) )

	def error(self,exception):
		sys.stderr.write(self.formatError(str(exception)))

	def fatalError(self,exception):
		for (realfilename, num,file) in self.fileswritten.values():
			file.close()

		raise(exception)

	def warning(self,exception):
		sys.stderr.write(str(exception))

	def info(self, text):
		sys.stdout.write(text)

