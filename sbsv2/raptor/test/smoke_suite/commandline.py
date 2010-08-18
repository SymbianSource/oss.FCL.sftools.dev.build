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
# General commandline option handling tests which aren't appropriate as unit tests.

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "85a"
	t.name = "commandline_nodefaults"
	t.description = """Test that raptor complains if you run it without specifying any components and there is no default bld.inf or system definition in the current directory."""
	t.usebash = True
			
	t.command = """
		TMPDIR="build/commandline_testdefaults";
		cd $(EPOCROOT)/epoc32 && rm -rf "$TMPDIR" 2>/dev/null; mkdir -p "$TMPDIR" && cd "$TMPDIR" &&
		sbs ${SBSLOGFILE} -n ; rm -rf "$TMPDIR"
	""" 
		
	t.mustmatch = [".*warning: No default bld.inf or system definition.*found.* "]
	t.warnings = 1
	t.run()

	t.id = "0085"
	t.name = "commandline"
	return t
