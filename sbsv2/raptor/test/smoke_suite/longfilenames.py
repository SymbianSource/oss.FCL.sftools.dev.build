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

from raptor_tests import SmokeTest
import os
import re
import sys

def run():
	# Content for files to be generated.
	cpp = "longerfilenamethanyoumightnormallyexpecttobepresent"
	path = "/test/smoke_suite/test_resources/longfilenames/"
	targetinfo = """TARGET			longfilenames.exe
TARGETTYPE		exe
UID				0xE8000047
LIBRARY			euser.lib
SYSTEMINCLUDE	/epoc32/include
"""
	
	# Some numbers for path and file operations
	length_limit = 245 # Safety-margin of 10 chars for changing dir structures in Raptor
	extLen = 8 # eg. _001.o.d
	numLen = 43 # release directory length (c_0000000000000000/longfilenames_exe/winscw/urel/) (minus a few as a safety-margin)
	pathmultiplier = 5	# expand cpp to the maximum length
	mmpStart = 1
	mmpStop = 270
	cppStart = 1
	cppStop = 270


	# Find SBS_Home and its length as a string
	sbsHome = os.environ["SBS_HOME"]
	sbsLen = len(sbsHome)
	
	# Work out path lengths required
	dirname = sbsHome + path
	string = cpp * pathmultiplier
	dirlen = len(dirname)
	fileLen = length_limit - dirlen - numLen - extLen
	if fileLen < 0:
		print "Error: Your test path is too long for the longfilenames test to work"
		sys.exit()
	fileName = string[0:fileLen]

	# Generate the mmp file using the mmp string
	f = open(dirname + 'longfilenames.mmp', 'w')
	f.writelines(targetinfo)
	f.writelines("\nSOURCE		" + cpp + ".cpp\n")
	while mmpStart <= mmpStop:
		sourceinfo = "SOURCE		" + fileName + '_%03d' %mmpStart + ".cpp " + '\n'
		f.writelines(sourceinfo)
		mmpStart += 1
	f.close()

	# File generating utility
	while cppStart <= cppStop:
		t = str(cppStart)
		filename = dirname + fileName + '_%03d' %cppStart + '.cpp'
		content = 'int x' + t + ' = 1;'
		f = open (filename, 'w')
		f.write (content)
		f.close()
		cppStart += 1


	t = SmokeTest()
	t.id = "79"
	t.name = "longfilenames"
	t.command = "sbs -b smoke_suite/test_resources/longfilenames/bld.inf -c winscw"
	t.description = """Ensure that winscw links with large amounts of object files with long names are buildable.
		Note that the link in the build of this component should always be greater than 16500 chars, regardless
		of environment - we know such calls are currently problematic on Windows with GNU Make and Cygwin's
		Bash unless a linker response file is not used to hold the object files."""
	t.targets = [
		"$(EPOCROOT)/epoc32/release/winscw/urel/longfilenames.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/longfilenames.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/longfilenames/bld.inf', [
		"longfilenames_exe/winscw/urel/longerfilenamethanyoumightnormallyexpecttobepresent.dep",
		"longfilenames_exe/winscw/urel/longerfilenamethanyoumightnormallyexpecttobepresent.o",
		"longfilenames_exe/winscw/urel/longerfilenamethanyoumightnormallyexpecttobepresent.o.d",
		"longfilenames_exe/winscw/urel/longfilenames.UID.CPP",
		"longfilenames_exe/winscw/urel/longfilenames_UID_.dep",
		"longfilenames_exe/winscw/urel/longfilenames_UID_.o",
		"longfilenames_exe/winscw/urel/longfilenames_UID_.o.d",
		"longfilenames_exe/winscw/urel/longfilenames_urel_objects.lrf"]
		)
	
	basefilename = "longfilenames_exe/winscw/urel/" + fileName + "_%03d.%s"
	for i in range(1, 271):		
		t.addbuildtargets('smoke_suite/test_resources/longfilenames/bld.inf', [
			basefilename % (i, "dep"),
			basefilename % (i, "o"),
			basefilename % (i, "o.d")
			]
		)

	t.run()
		
	# Remove all created files
	
	# Matches longerfilena......_nnn.cpp
	cpp_regex = re.compile("^.+_\d{3}.cpp$", re.I)
	for file in os.listdir(dirname):
		if cpp_regex.match(file) is not None:
			try:
				os.remove(dirname + file)
			except:
				pass
	
	try:
		os.remove(dirname + 'longfilenames.mmp')
	except:
		pass
	
	return t
