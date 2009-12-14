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

class Refilter:
	"""
	Refilters an existing logfile with a specified filter
	
	Parameters:
			filtermodule: 	The name of the filter file to use for refiltering
			filtername:		The name of the filter class
			logfilename: 	The logfile to be parsed
	"""
	class Dummy_raptor:
		def __init__(self, logfile, targets):
			self.logFileName = logfile
			self.quiet = False
			self.dummy = False
			self.targets = targets

	def __init__(self, filtermodule, filtername, logfilename):
		dummy_raptor = Refilter.Dummy_raptor(logfilename, [])
		
		module=__import__(filtermodule)
		self.filter=eval("module."+filtername+"()")

		self.filter.open(dummy_raptor)

	def refilter(self, inputlog):
		file=open(inputlog)

		while True:
			line=file.readline()
			if not line:
				break
			self.filter.write(line)
