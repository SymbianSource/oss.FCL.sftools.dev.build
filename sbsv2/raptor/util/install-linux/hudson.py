
# hudson runs this from the raptor/util/install-linux directory

import datetime
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

# get today's date in ISO format YYYY-MM-DD

today = datetime.date.today().isoformat()
print "DATE", today

# insert the date and changeset into the raptor_version.py file

filename = "../../python/raptor_version.py"
lines = []
try:
	file = open(filename, "r")
	for line in file.readlines():
		if "ISODATE" in line and "CHANGESET" in line:
			line = line.replace("ISODATE", today)
			line = line.replace("CHANGESET", changeset)
			if prototype:
				line = line.replace("system", "system PROTOTYPE")
			lines.append(line)
		else:
			lines.append(line)
except IOError, ex:
	sys.stderr.write("error: failed to read file '%s'\n%s" % (filename, str(ex)))
	sys.exit(1)
finally:
	file.close()

# ... and write the modified raptor_version.py file

try:
	file = open(filename, "w")
	for line in lines:
		file.write(line)
except IOError, ex:
	sys.stderr.write("error: failed to write file '%s'\n%s" % (filename, str(ex)))
	sys.exit(1)
finally:
	file.close()

# check that we really did change the raptor version string

sbs_v = subprocess.Popen(["../../bin/sbs", "-v"], stdout=subprocess.PIPE)
version = sbs_v.communicate()[0]

if sbs_v.returncode == 0:
	print "VERSION", version
	if not today in version or not changeset in version:
		sys.stderr.write("error: date or changeset does not match the sbs version.\n")
		sys.exit(1)
        if prototype and not "PROTOTYPE" in version:
		sys.stderr.write("error: the sbs version should be marked PROTOTYPE.\n")
		sys.exit(1)
else:
	sys.stderr.write("error: failed to get sbs version.\n")
	sys.exit(1)

# run the Linux installer maker script

package_sbs = subprocess.Popen(["./package_sbs.sh", "-s"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
(stdout, stderr) = package_sbs.communicate()

if package_sbs.returncode != 0:
	sys.stderr.write("error: failed to create linux package of sbs.\n")
	sys.exit(1)

# find the name of the archive in /tmp

match = re.search('archive "([^"]+)" successfully created', stdout)
if match:
	tmp_archive = "/tmp/" + match.group(1)
	print "TMP ARCHIVE", tmp_archive
else:
	sys.stderr.write("error: failed to find linux archive file.\n")
	sys.exit(1)

# move it to the WORKSPACE root

if 'WORKSPACE' in os.environ:
	name = re.sub(r'/tmp/(sbs-\d+\.\d+\.\d+-).*', r'\1', tmp_archive)
	if prototype:
		fullname = name + "PROTOTYPE-" + changeset + ".run"
	else:
		fullname = name + changeset + ".run"
	final_archive = os.path.join(os.environ['WORKSPACE'], fullname)
	print "WORKSPACE ARCHIVE", final_archive
else:
	sys.stderr.write("error: no WORKSPACE is set.\n")
	sys.exit(1)

try:
	shutil.move(tmp_archive, final_archive)
except Error, err:
	sys.stderr.write("error: could not rename '%s' as '%s'.\n" % (tmp_archive, final_archive))
	sys.exit(1)

# the end
