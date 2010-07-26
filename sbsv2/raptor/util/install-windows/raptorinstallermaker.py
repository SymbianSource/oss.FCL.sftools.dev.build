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
#
#! python

# Raptor installer maker!

import os
import os.path
import subprocess
import re
import optparse
import sys
import tempfile
import shutil
import unzip

tempdir = ""

parser = optparse.OptionParser()

parser.add_option("-s", "--sbs-home", dest="sbshome", help="Path to use as SBS_HOME environment variable. If not present the script exits.")

parser.add_option("-w", "--win32-support", dest="win32support", help="Path to Win32 support directory. If not present the script exits.")

parser.add_option("-b", "--bv", dest="bv", help="Path to Binary variation CPP \"root\" directory. Can be a full/relatitve path; prefix with \"WIN32SUPPORT\\\" to be relative to the Win32 support directory. Omitting this value will assume a default to a path inside the Win32 support directory.")

parser.add_option("-c", "--cygwin", dest="cygwin", help="Path to Cygwin \"root\" directory. Can be a full/relatitve path; prefix with \"WIN32SUPPORT\\\" to be relative to the Win32 support directory. Omitting this value will assume a default to a path inside the Win32 support directory.")

parser.add_option("-m", "--mingw", dest="mingw", help="Path to MinGW \"root\" directory. Can be a full/relatitve path; prefix with \"WIN32SUPPORT\\\" to be relative to the Win32 support directory. Omitting this value will assume a default to a path inside the Win32 support directory.")

parser.add_option("-p", "--python", dest="python", help="Path to Python \"root\" directory. Can be a full/relatitve path; prefix with \"WIN32SUPPORT\\\" to be relative to the Win32 support directory. Omitting this value will assume a default to a path inside the Win32 support directory.")

parser.add_option("--prefix", dest="versionprefix", help="A string to use as a prefix to the Raptor version string. This will be present in the Raptor installer's file name, the installer's pages as well as the in output from sbs -v.", type="string", default="")

parser.add_option("--postfix", dest="versionpostfix", help="A string to use as a postfix to the Raptor version string. This will be present in the Raptor installer's file name, the installer's pages as well as the in output from sbs -v.", type="string", default="")

(options, args) = parser.parse_args()

# Required directories inside the win32-support repository
win32supportdirs = {"bv":"bv", "cygwin":"cygwin", "mingw":"mingw", "python":"python264"}

if options.sbshome == None:
	print "ERROR: no SBS_HOME passed in. Exiting..."
	sys.exit(2)

if options.win32support == None:
	print "ERROR: no win32support directory specified. Unable to proceed. Exiting..."
	sys.exit(2)
else:
	# Check for command line overrides to defaults
	for directory in win32supportdirs:
		print "TEST %s" % directory
		value = getattr(options,directory)
		print "value =  %s" % str(value)
		if value != None: # Command line override
			if value.lower().startswith("win32support"):
				# Strip off "WIN32SUPPORT\" and join to Win32 support location
				win32supportdirs[directory] = os.path.join(options.win32support, value[13:]) 
			else:
				# Relative to current directory
				win32supportdirs[directory] = value

		else: # Use default location
			win32supportdirs[directory] = os.path.join(options.win32support, win32supportdirs[directory])
	
	print "\n\nwin32supportdirs = %s\n\n" % win32supportdirs

	# Check that all the specified directories exist and exit if any of them is missing.
	for directory in win32supportdirs:
		dir = win32supportdirs[directory]
		if os.path.isdir(dir):
			print "Found directory %s" % dir
		else:
			print "ERROR: directory %s does not exist. Cannot build installer. Exiting..." % dir
			sys.exit(2)

def generateinstallerversionheader(sbshome = None):
	shellenv = os.environ.copy()
	shellenv["PYTHONPATH"] = os.path.join(sbshome, "python")
	
	raptorversioncommand = "python -c \"import raptor_version; print raptor_version.numericversion()\""
	
	# Raptor version is obtained from raptor_version module's numericversion function.
	sbs_version_matcher = re.compile(".*(\d+\.\d+\.\d+).*", re.I)
	
	# Create Raptor subprocess
	versioncommand = subprocess.Popen(raptorversioncommand, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=shellenv)
	raptorversion = ""
	# Get all the lines matching the RE
	for line in versioncommand.stdout.readlines():
		res = sbs_version_matcher.match(line)
		if res:
			raptorversion = res.group(1)
			print "Successfully determined Raptor version %s" % raptorversion

	versioncommand.wait() # Wait for process to end
	
	raptorversion_nsis_header_string = "# Raptor version file\n\n!define RAPTOR_VERSION %s\n" % raptorversion
	
	fh = open("raptorversion.nsh", "w")
	fh.write(raptorversion_nsis_header_string)
	fh.close()
	print "Wrote raptorversion.nsh"
	return 0

def generateinstallerversion(sbshome = None):
	shellenv = os.environ.copy()
	shellenv["PYTHONPATH"] = os.path.join(sbshome, "python")
	
	raptorversioncommand = "python -c \"import raptor_version; print raptor_version.numericversion()\""
	
	# Raptor version is obtained from raptor_version module's numericversion function.
	sbs_version_matcher = re.compile(".*(\d+\.\d+\.\d+).*", re.I)
	
	# Create Raptor subprocess
	versioncommand = subprocess.Popen(raptorversioncommand, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=shellenv)
	raptorversion = ""
	# Get all the lines matching the RE
	for line in versioncommand.stdout.readlines():
		res = sbs_version_matcher.match(line)
		if res:
			raptorversion = res.group(1)
			print "Successfully determined Raptor version %s" % raptorversion

	versioncommand.wait() # Wait for process to end
	
	return raptorversion
	
def unzipnsis(pathtozip):
    global tempdir
    tempdir = tempfile.mkdtemp()
    un = unzip.unzip()
    print "Unzipping NSIS to %s..." % tempdir
    un.extract(pathtozip, tempdir)
    print "Done."
    
    return os.path.join(tempdir, "NSIS", "makensis.exe")
    
def runmakensis(nsiscommand):
	# Create makensis subprocess
	print "Running NSIS command\n%s" % nsiscommand
	makensis = subprocess.Popen(nsiscommand, shell=True)
	makensis.wait() # Wait for process to end

def cleanup():
	""" Clean up tempdir """
	global tempdir
	print "Cleaning up temporary directory %s" % tempdir
	shutil.rmtree(tempdir,True)
	try:
		os.remove("raptorversion.nsh")
		print "Successfully deleted raptorversion.nsh."
	except:
		print "ERROR: failed to remove raptorversion.nsh - remove manually if needed."
	print "Done."

makensispath = unzipnsis(".\\NSIS.zip")
# generateinstallerversionheader(options.sbshome)
raptorversion = options.versionprefix + generateinstallerversion(options.sbshome) + options.versionpostfix
nsiscommand = makensispath + " /DRAPTOR_LOCATION=%s /DBV_LOCATION=%s /DCYGWIN_LOCATION=%s /DMINGW_LOCATION=%s /DPYTHON_LOCATION=%s /DRAPTOR_VERSION=%s raptorinstallerscript.nsi" % (options.sbshome, 
				win32supportdirs["bv"],
				win32supportdirs["cygwin"],
				win32supportdirs["mingw"],
				win32supportdirs["python"],
				raptorversion)
print "nsiscommand = %s" % nsiscommand
runmakensis(nsiscommand)
cleanup()

