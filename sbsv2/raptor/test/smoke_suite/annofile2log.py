#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
	t.id = "43563"
	t.name = "annofile2log"
	t.description = "test workaround for log corruption from a make engine whose name begins with 'e'"
	
	t.usebash = True
	t.errors = 0
	t.returncode = 1
	t.exceptions = 0
	t.command = "cd smoke_suite/test_resources/annofile2log && ( diff -wB <(python testanno2log.py <(bzip2 -dc scrubbed_ncp_dfs_resource.anno.bz2)) <(bzip2 -dc scrubbed_ncp_dfs_resource.stdout.bz2))"
	
	t.mustmatch_multiline = [ 
		".*1a2.*" + 
		"Starting build: 488235.{1,3}" +
		"14009c12884.{1,4}" +
		"---.{1,4}" +
		"Finished build: 488235   Duration: 1:15 \(m:s\)   Cluster availability: 100%.*"
                ]


	t.run()

	t.print_result()
	return t
