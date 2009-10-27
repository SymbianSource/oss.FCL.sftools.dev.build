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
parser.add_option("-s", "--sbs_home", dest="sbs_home",
                  help="Path to use as SBS_HOME environment variable. If not present the script exits.")

(options, args) = parser.parse_args()

if options.sbs_home == None:
	print "ERROR: no SBS_HOME passed in. Exiting..."
	sys.exit(2)


def parseconfig(xmlFile="raptorinstallermaker.xml"):
	pass

def generateinstallerversionheader(sbs_home = None):
	os.environ["SBS_HOME"] = sbs_home
	os.environ["PATH"] = os.path.join(os.environ["SBS_HOME"], "bin") + os.pathsep + os.environ["PATH"]
	
	versioncommand = "sbs -v"
	
	# Raptor version string looks like this
	# sbs version 2.5.0 [2009-02-20 release]
	sbs_version_matcher = re.compile(".*(\d+\.\d+\.\d+).*", re.I)
	
	# Create Raptor subprocess
	sbs = subprocess.Popen(versioncommand, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
	
	# Get all the lines matching the RE
	for line in sbs.stdout.readlines():
		res = sbs_version_matcher.match(line)
		if res:
			raptorversion = res.group(1)
			print "Successfully determined Raptor version %s" % raptorversion

	sbs.wait() # Wait for process to end
	
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
	print "Done."

makensispath = unzipnsis(".\\NSIS.zip")
generateinstallerversionheader(options.sbs_home)
nsiscommand = makensispath + " /DRAPTOR_LOCATION=%s raptorinstallerscript.nsi" % options.sbs_home
print "nsiscommand = %s" % nsiscommand
runmakensis(nsiscommand)
cleanup()

