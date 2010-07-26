#!bin\perl
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
# Unit test for CStageRunner
# 
#

package unit_CStageRunner;

use lib qw(../);
use lib qw(../stages);
use FindBin;
use lib $FindBin::Bin."\\..";
use CStageRunner;
use CTestScore;

sub RunTest($)
	{
	my ($testscore) = @_;

	print "> *** Testing CStageRunner ***\n";

	if (!defined($testscore))
		{
		$testscore = New CTestScore();
		}
	
	if (!defined($ENV{TEMP}))
		{
		print STDOUT "TEMP environment variable must be defined before testing of CStageRunner is run.\n";
		return $testscore;
		}
		
	my $testFilename = $ENV{TEMP}."\\CConfig.tst";
	
	if (-e $testFilename)
		{
		print STDOUT "File '$testFilename' already exists.\nPlease delete this file to enable testing of CStageRunner.\n";
		return $testscore;
		}
		
	open(TESTFILE,">$testFilename");
	print TESTFILE "key:value\n";
	close(TESTFILE);

	my $testConfig=New CConfig($testFilename);
	unlink $testFilename;

	my $testStageRunner = eval("New CStageRunner([\"CExampleStage\"], \$testConfig);");
	$testscore->Test(defined($testStageRunner), "Instantiated example stage runner");
	$testscore->Test($testStageRunner->Run(), "Run example stage runner");

	$testStageRunner = eval("New CStageRunner([\"CNonexistantStage\"], \$testConfig);");
	$testscore->Test(!defined($testStageRunner), "Didn't instantiate bad stage");

	return $testscore;
	} 

1;
