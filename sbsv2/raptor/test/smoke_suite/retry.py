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

from raptor_tests import AntiTargetSmokeTest

def run():
	t = AntiTargetSmokeTest()
	t.id = "59"
	t.name = "retry"
	#
	# -t 3 means try each recipe up to 3 times, if it fails.
	#
	# There are 3 FLM calls: 
	#    retry_1 fails once then succeeds.
	#    retry_2 fails twice then succeeds.
	#    retry_3 fails all 3 times.
	#
	# use -k in case the retry_3 case happens to be run first.
	#
	t.command = "sbs -b smoke_suite/test_resources/retry/bld.inf -c armv5_urel -t 3 -k"
	t.targets = [
		"$(EPOCROOT)/epoc32/build/retry_1.1",
		"$(EPOCROOT)/epoc32/build/retry_1.ok",
		"$(EPOCROOT)/epoc32/build/retry_2.1",
		"$(EPOCROOT)/epoc32/build/retry_2.2",
		"$(EPOCROOT)/epoc32/build/retry_2.ok",
		"$(EPOCROOT)/epoc32/build/retry_3.1",
		"$(EPOCROOT)/epoc32/build/retry_3.2",
		"$(EPOCROOT)/epoc32/build/retry_3.3"
	]
	t.antitargets = [
		"$(EPOCROOT)/epoc32/build/retry_1.2",
		"$(EPOCROOT)/epoc32/build/retry_1.3",
		"$(EPOCROOT)/epoc32/build/retry_2.3",
		"$(EPOCROOT)/epoc32/build/retry_3.ok"
	]
	t.returncode = 1
	t.run()
	return t
