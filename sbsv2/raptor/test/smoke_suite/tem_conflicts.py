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

def run():
	t = SmokeTest()
	t.id = "0094"
	t.name = "tem_conflicts"
	t.usebash = 1
	t.command = "sbs -b smoke_suite/test_resources/tem_conflict/bld.inf " + \
		"-c armv5 -j 2 -f $SBSLOGFILE; cat $SBSLOGFILE"
	t.targets = [
		"$(EPOCROOT)/epoc32/tools/makefile_templates/test/tem_conflicts.mk",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/test/tem_conflicts.meta",
		"$(EPOCROOT)/epoc32/tools/makefile_templates/test/tem_conflicts.sh"
		]
	t.mustnotmatch = [
		"cp: cannot open .* for reading: Permission denied",
		"cp: cannot stat .*: No such file or directory",
		"rm: cannot remove .*: No such file or directory",
		"rm: cannot remove .*: Permission denied"
		]
	t.run()
	return t
