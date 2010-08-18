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
# Raptor installer maker script - generates a Windows installer for Raptor using
# the NSIS package in the accompanying directory. Works on Windows and Linux.

import optparse
import os
import os.path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import unzip
import zipfile

tempdir = ""

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

	# Ensure the correct executable is called	
	dotexe=""
	if "win" in sys.platform.lower():
		dotexe=".exe"
	
	makensispath = os.path.join(tempdir, "NSIS", "makensis" + dotexe)
	
	if not "win" in sys.platform.lower():
		os.chmod(makensispath, stat.S_IRWXU)

	return makensispath
	
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
	print "Done."

def __writeDirTreeToArchive(zip, dirlist, sbshome, win32supportdirs=False):
	"""Auxilliary function to write all files in each directory trees of dirlist into the
	open archive "zip" assuming valid sbshome; destination path is tweaked for win32supportdirs, 
	so set this to true when writing files into $SBS_HOME/win32"""
	for name in dirlist:
		files = os.walk(os.path.join(sbshome, name))
		for dirtuple in files:
			filenames = dirtuple[2]
			dirname = dirtuple[0]
			for file in filenames:
				# Filter out unwanted files
				if not file.lower().endswith(".pyc") and \
				not file.lower().endswith(".project") and \
				not file.lower().endswith(".cproject") and \
				not file.lower().endswith(".pydevproject"):
					origin = os.path.join(dirname, file)
					
					# For the win32 support directories, the destination is different
					if win32supportdirs:
						destination = os.path.join("sbs", "win32", os.path.basename(name.rstrip(os.sep)), 
												dirname.replace(name, "").strip(os.sep), file)
					else:
						destination = os.path.join("sbs", dirname.rstrip(os.sep).replace(sbshome, "").strip(os.sep), file)
					
					print "Compressing", origin, "\tto\t", destination 
					zip.write(origin, destination)

def writeZip(filename, sbshome, sbsbvdir, sbscygwindir, sbsmingwdir, sbspythondir):
	"""Write a zip archive with file name "filename" assuming SBS_HOME is sbshome, and  
	that sbsbvdir, sbscygwindir, sbsmingwdir, sbspythondir are the win32 support directories."""
	
	# *Files* in the top level SBS_HOME directory
	sbshome_files = ["RELEASE-NOTES.html", "license.txt"]
	
	# Directories in SBS_HOME
	sbshome_dirs = ["bin", "examples", "lib", "notes", "python", 
				"schema", "style", os.sep.join(["win32", "bin"])]
	
	# Win32 support directories
	win32_dirs = [sbsbvdir, sbscygwindir, sbsmingwdir, sbspythondir]
	
	try:
		# Open the zip archive for writing; if a file with the same
		# name exists, it will be truncated to zero bytes before 
		# writing commences
		zip = zipfile.ZipFile(filename, "w", zipfile.ZIP_DEFLATED)
		
		# Write the files in the top-level of SBS_HOME into the archive
		for name in sbshome_files:
			origin = os.path.join(sbshome, name)
			destination = os.path.join("sbs", name)
			print "Compressing", origin, "\tto\t", destination 
			zip.write(origin, destination)
		
		# Write all files in the the directories in the top-level of SBS_HOME into the archive
		print "Reading the sbs directories..."
		__writeDirTreeToArchive(zip, sbshome_dirs, sbshome, win32supportdirs=False)
		print "Writing sbs directories to the archive is complete."
		
		# Write all files in the the win32 support directories in the top-level of SBS_HOME into the archive
		print "Reading the win32 support directories"
		__writeDirTreeToArchive(zip, win32_dirs, sbshome, win32supportdirs=True)
		print "Writing win32 support directories to the archive is complete."
		
		zip.close()
		print "Zipoutput: \"" + os.path.join(os.getcwd(), filename) + "\""
		print "Zip file creation successful."
	except Exception, e:
		print "Error: failed to create zip file: %s" % str(e)
		sys.exit(2)

# Create CLI and parse it
parser = optparse.OptionParser()

parser.add_option("-s", "--sbs-home", dest="sbshome", help="Path to use as SBS_HOME environment variable. If not present the script exits.")

parser.add_option("-w", "--win32-support", dest="win32support", help="Path to Win32 support directory. If not present the script exits.")

parser.add_option("-b", "--bv", dest="bv", help="Path to Binary variation CPP \"root\" directory. Can be a full/relatitve path; prefix with \"WIN32SUPPORT\\\" to be relative to the Win32 support directory. Omitting this value will assume a default to a path inside the Win32 support directory.")

parser.add_option("-c", "--cygwin", dest="cygwin", help="Path to Cygwin \"root\" directory. Can be a full/relatitve path; prefix with \"WIN32SUPPORT\\\" to be relative to the Win32 support directory. Omitting this value will assume a default to a path inside the Win32 support directory.")

parser.add_option("-m", "--mingw", dest="mingw", help="Path to MinGW \"root\" directory. Can be a full/relatitve path; prefix with \"WIN32SUPPORT\\\" to be relative to the Win32 support directory. Omitting this value will assume a default to a path inside the Win32 support directory.")

parser.add_option("-p", "--python", dest="python", help="Path to Python \"root\" directory. Can be a full/relatitve path; prefix with \"WIN32SUPPORT\\\" to be relative to the Win32 support directory. Omitting this value will assume a default to a path inside the Win32 support directory.")

parser.add_option("--prefix", dest="versionprefix", help="A string to use as a prefix to the Raptor version string. This will be present in the Raptor installer's file name, the installer's pages as well as the in output from sbs -v.", type="string", default="")

parser.add_option("--postfix", dest="versionpostfix", help="A string to use as a postfix to the Raptor version string. This will be present in the Raptor installer's file name, the installer's pages as well as the in output from sbs -v.", type="string", default="")

parser.add_option("--noclean", dest="noclean", help="Do not clean up the temporary directory created during the run.", action="store_true" , default=False)

parser.add_option("--noexe", dest="noexe", help="Do not create a Windows .exe installer of the Raptor installation.", action="store_true" , default=False)

parser.add_option("--nozip", dest="nozip", help="Do not create a zip archive of the Raptor installation.", action="store_true" , default=False)

(options, args) = parser.parse_args()

# Required directories inside the win32-support directory (i.e. the win32-support repository).
win32supportdirs = {"bv":"bv", "cygwin":"cygwin", "mingw":"mingw", "python":"python264"}

if options.sbshome == None:
	print "ERROR: no SBS_HOME passed in. Exiting..."
	sys.exit(2)
elif not os.path.isdir(options.sbshome):
	print "ERROR: the specified SBS_HOME directory \"%s\" does not exist. Cannot build installer. Exiting..."
	sys.exit(2)

if options.win32support == None:
	print "ERROR: no win32support directory specified. Unable to proceed. Exiting..."
	sys.exit(2)
else:
	# Check for command line overrides to defaults
	for directory in win32supportdirs:
		print "Checking for location \"%s\"..." % directory
		value = getattr(options,directory)
		print "Directory is %s" % str(value)
		if value != None: # Command line override
			if value.lower().startswith("win32support"):
				# Strip off "WIN32SUPPORT\" and join to Win32 support location
				win32supportdirs[directory] = os.path.join(options.win32support, value[13:]) 
			else:
				# Relative to current directory
				win32supportdirs[directory] = value

		else: # Use default location
			win32supportdirs[directory] = os.path.join(options.win32support, win32supportdirs[directory])
		
	print "\n\nIdentified win32supportdirs are = %s\n\n" % win32supportdirs

	# Check that all the specified directories exist and exit if any of them is missing.
	for directory in win32supportdirs:
		dir = win32supportdirs[directory]
		if os.path.isdir(dir):
			print "Found directory %s" % dir
		else:
			print "ERROR: directory %s does not exist. Cannot build installer. Exiting..." % dir
			sys.exit(2)


raptorversion = options.versionprefix + generateinstallerversion(options.sbshome) + options.versionpostfix

print "Using Raptor version %s ..." % raptorversion

if not options.noexe:
	makensispath = unzipnsis("." + os.sep + "NSIS.zip")
	if "win" in sys.platform.lower():
		switch="/"
	else:
		switch="-"

	nsiscommand = (makensispath + " " + 
				switch + "DRAPTOR_LOCATION=%s "  + 
				switch + "DBV_LOCATION=%s "  + 
				switch + "DCYGWIN_LOCATION=%s "  + 
				switch + "DMINGW_LOCATION=%s "  + 
				switch + "DPYTHON_LOCATION=%s "  +
				switch + "DRAPTOR_VERSION=%s " + 
				"%s" ) % \
			(	options.sbshome, 
				win32supportdirs["bv"], 
				win32supportdirs["cygwin"],
				win32supportdirs["mingw"],
				win32supportdirs["python"],
				raptorversion,
				os.path.join(options.sbshome, "util", "install-windows", "raptorinstallerscript.nsi")
			)
	
	# On Linux, we need to run makensis via Bash, so that is can find all its
	# internal libraries and header files etc. Makensis fails unless it 
	# is executed this way on Linux.
	if "lin" in sys.platform.lower():
		nsiscommand = "bash -c \"%s\"" % nsiscommand
	
	runmakensis(nsiscommand)
else:
	print "Not creating .exe as requested."

# Only clean NSIS installation in the temporary directory if requested
if not options.noclean:
	cleanup()
else:
	print "Not cleaning makensis in %s" % makensispath

# Only create zip archive if required
if not options.nozip:
	filename = "sbs-" + raptorversion + ".zip"
	writeZip(filename, options.sbshome, win32supportdirs["bv"], win32supportdirs["cygwin"], win32supportdirs["mingw"], win32supportdirs["python"])
else:
	print "Not creating zip archive as requested."

print "Finished."

