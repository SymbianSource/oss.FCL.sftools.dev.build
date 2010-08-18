# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# \bin\perl
# Test harness
# 
#

use lib qw(../);
use lib qw(../stages);

use unit_CConfig;
use unit_CProcessStage;
use unit_CStageRunner;
use unit_stage_CDelta;

use CTestScore;

my $score = New CTestScore();

if (!defined($score))
	{
	exit(1);
	}

$score = unit_CConfig::RunTest($score);
$score = unit_CProcessStage::RunTest($score);
$score = unit_CStageRunner::RunTest($score);
$score = unit_stage_CDelta::RunTest($score);

$score->Print();
