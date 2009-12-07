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
	t.id = "71"
	t.name = "metadep"
	t.description =  """Tests metadata dependency generation.  Changes 
			to bld.infs and mmps can be detected."""
	t.usebash = True
	t.command = """export SBSLOGFILE SBSMAKEFILE; bash smoke_suite/test_resources/metadep.sh 2>&1"""
			
	t.targets = [
		]

	t.mustmatch_multiline = [
""".*Step 1 .*no warnings or errors.*
sbs: build log in.*
\+ sleep 1.*
.*make -rf .*epoc32/build/metadata_all.mk.*
.*make.*epoc32/build/metadata_all.mk. is up to date.*
Step 2 .*
.*RE-RUNNING SBS with previous parameters.*
Step 3 .*
.*RE-RUNNING SBS with previous parameters.*
.*RE-RUNNING SBS with previous parameters.*"""
	]
	t.mustnotmatch_multiline = [
"""RE-RUNNING SBS with previous parameters.*
RE-RUNNING SBS with previous parameters.*
RE-RUNNING SBS with previous parameters.*
RE-RUNNING SBS with previous parameters.*"""
	]
	t.run()
	return t
