#
# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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
# Filter class for doing a Check operation but also prints component information.
#

import os
import sys
import re
import filter_interface
import filter_what

class FilterCheckComp(filter_what.FilterWhat):

	def __init__(self):
		super(FilterCheckComp, self).__init__()
		self.check = True

	def write(self, text):
		"process some log text"
		ok = True
		
		for line in text.splitlines():
			ok = filter_what.FilterWhat.write(self, line)
			if not ok:
				break
		self.ok = ok
		return self.ok
	
	def start_bldinf(self, bldinf):
		dir = None
		if "win" in self.buildparameters.platform:
			dir = os.path.dirname(bldinf.replace("/","\\"))
			dir = os.path.splitdrive(dir)[1]
		else:
			dir = os.path.dirname(bldinf)

		self.outfile.write("=== %s == %s\n" % (dir, dir))
		self.outfile.write("=== check == %s\n" % (dir))
		self.outfile.write("-- sbs_filter --filters=FilterCheckComp\n++ Started at Thu Feb 11 10:05:19 2010\nChdir %s\n" % dir)

	def end_bldinf(self):
		self.outfile.write("++ Finished at Thu Feb 11 10:05:20 2010\n")

	def close(self):
		self.outfile.write("++ Finished at Thu Feb 11 10:05:20 2010\n")
		self.outfile.write("=== check finished Thu Feb 11 10:05:20 2010\n")

	def open(self, build_parameters):
		t = filter_what.FilterWhat.open(self, build_parameters)
		if t:
			self.outfile.write("\n===-------------------------------------------------\n")
			self.outfile.write("=== check\n")
			self.outfile.write("===-------------------------------------------------\n")
			self.outfile.write("=== check started Thu Feb 11 10:02:21 2010\n")

		self.path_prefix_to_strip = os.path.abspath(build_parameters.epocroot)
		self.path_prefix_to_add_on = build_parameters.incoming_epocroot
		return t
