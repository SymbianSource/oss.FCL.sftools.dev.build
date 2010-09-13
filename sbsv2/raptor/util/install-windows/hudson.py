
# hudson runs this from the raptor/util/install-windows directory

import os
import re
import shutil
import subprocess
import sys

# run "hg id" to get the current branch name and tip changeset

hgid = subprocess.Popen(["hg", "id"], stdout=subprocess.PIPE)
stdout = hgid.communicate()[0]

if hgid.returncode == 0 and len(stdout) >= 12:
	changeset = stdout[0:12]
	print "CHANGESET", changeset

	prototype = ("wip" in stdout or "fix" in stdout)
	print "PROTOTYPE", prototype
else:
	sys.stderr.write("error: failed to get tip mercurial changeset.\n")
	sys.exit(1)

# get the raptor version string

sbs_v = subprocess.Popen(["../../bin/sbs", "-v"], stdout=subprocess.PIPE)
version = sbs_v.communicate()[0]

if sbs_v.returncode == 0:
	print "VERSION", version
	if not changeset in version:
		sys.stderr.write("error: changeset does not match the sbs version.\n")
		sys.exit(1)
        if prototype and not "PROTOTYPE" in version:
		sys.stderr.write("error: the sbs version should be marked PROTOTYPE.\n")
		sys.exit(1)
else:
	sys.stderr.write("error: failed to get sbs version.\n")
	sys.exit(1)

# find the SBS_HOME and WIN32_SUPPORT

if 'SBS_HOME' in os.environ:
	sbs_home = os.environ['SBS_HOME']
else:
	sys.stderr.write("error: no SBS_HOME is set.\n")
	sys.exit(1)

if 'WIN32_SUPPORT' in os.environ:
	win32_support = os.environ['WIN32_SUPPORT']
else:
	sys.stderr.write("error: no WIN32_SUPPORT is set.\n")
	sys.exit(1)

# run the Windows installer maker script

if prototype:
	postfix = "-PROTOTYPE-" + changeset
else:
	postfix = "-" + changeset

package_sbs = subprocess.Popen(["python", "raptorinstallermaker.py",
                                "-s", sbs_home, "-w", win32_support,
                                "--postfix=" + postfix],
                                stdout=subprocess.PIPE) #, stderr=subprocess.PIPE)
(stdout, stderr) = package_sbs.communicate()

if package_sbs.returncode == 0:
	match = re.search('Output: "([^"]+)"', stdout)
	zip_match = re.search('Zipoutput: "([^"]+)"', stdout)
	if match:
		tmp_archive = match.group(1)
		print "TMP ARCHIVE", tmp_archive
	else:
		sys.stderr.write("error: failed to find packaged filename.\n")
		sys.exit(1)
	
	if zip_match:
		tmp_zip_archive = zip_match.group(1)
		print "TMP ZIP ARCHIVE", tmp_zip_archive
	else:
		sys.stderr.write("error: failed to find zip filename.\n")
		sys.exit(1)
else:
	sys.stderr.write("error: failed to create windows package of sbs.\n")
	sys.exit(1)

# move the results to WORKSPACE

if 'WORKSPACE' in os.environ:
	final_archive = os.path.join(os.environ['WORKSPACE'], os.path.basename(tmp_archive))
	final_zip_archive = os.path.join(os.environ['WORKSPACE'], os.path.basename(tmp_zip_archive))
	print "WORKSPACE ARCHIVE", final_archive
	print "WORKSPACE ZIP ARCHIVE", final_zip_archive
else:
	sys.stderr.write("error: no WORKSPACE is set.\n")
	sys.exit(1)

try:
	shutil.move(tmp_archive, final_archive)
except Error, err:
	sys.stderr.write("error: could not rename '%s' as '%s'.\n" % (tmp_archive, final_archive))
	sys.exit(1)

try:
	shutil.move(tmp_zip_archive, final_zip_archive)
except Error, err:
	sys.stderr.write("error: could not rename '%s' as '%s'.\n" % (tmp_zip_archive, final_zip_archive))
	sys.exit(1)

# the end
