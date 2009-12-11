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
parser.add_option("-s", "--sbs-home", dest="sbshome",
                  help="Path to use as SBS_HOME environment variable. If not present the script exits.")
parser.add_option("-w", "--win32-support", dest="win32support",
                  help="Path to use as SBS_HOME environment variable. If not present the script exits.")

(options, args) = parser.parse_args()

if options.sbshome == None:
	print "ERROR: no SBS_HOME passed in. Exiting..."
	sys.exit(2)

if options.win32support == None:
	print "ERROR: no win32support directory specified. Unable to proceed. Exiting..."
	sys.exit(2)
else:
	# Required irectories inside the win32-support repository
	win32supportdirs = ["bv", "cygwin", "mingw", "python252"]
	for dir in win32supportdirs:
		if not os.path.isdir(os.path.join(options.win32support, dir)):
			print "ERROR: directory %s does not exist. Cannot build installer. Exiting..."
			sys.exit(2)

def parseconfig(xmlFile="raptorinstallermaker.xml"):
	pass

def generateinstallerversionheader(sbshome = None):
	shellenv = os.environ.copy()
	shellenv["PYTHONPATH"] = os.path.join(os.environ["SBS_HOME"], "python")
	
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
generateinstallerversionheader(options.sbshome)
nsiscommand = makensispath + " /DRAPTOR_LOCATION=%s /DWIN32SUPPORT=%s raptorinstallerscript.nsi" % (options.sbshome, options.win32support)
print "nsiscommand = %s" % nsiscommand
runmakensis(nsiscommand)
cleanup()

