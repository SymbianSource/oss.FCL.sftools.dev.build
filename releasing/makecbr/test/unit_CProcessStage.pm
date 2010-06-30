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
# Unit test for CProcessStage (Stage base class)
# 
#

package unit_CProcessStage;

use lib qw(../);
use lib qw(../stages);
use FindBin;
use lib $FindBin::Bin."\\..";
use CProcessStage;
use CTestScore;

sub RunTest($)
	{
	my ($testscore) = @_;

	print "> *** Testing CProcessStage ***\n";

	if (!defined($testscore))
		{
		$testscore = New CTestScore();
		}
	
	if (!defined($ENV{TEMP}))
		{
		print STDOUT "TEMP environment variable must be defined before testing of CProcessStage is run.\n";
		return $testscore;
		}
		
	my $testFilename = $ENV{TEMP}."\\CConfig.tst";
	
	if (-e $testFilename)
		{
		print STDOUT "File '$testFilename' already exists.\nPlease delete this file to enable testing of CProcessStage.\n";
		return $testscore;
		}
		
	open(TESTFILE,">$testFilename");
	print TESTFILE "key:value\n";
	close(TESTFILE);

	my $testConfig=New CConfig($testFilename);
	my $testStage=New CProcessStage($testConfig);
	unlink $testFilename;
	
	$testscore->Test($testStage->iOptions()->Get("key") eq "value", "Created stage with expected options");
	$testscore->Test($testStage->PreCheck(), "Base implementation of PreCheck returns true (OK)");
	$testscore->Test($testStage->Run(), "Base implementation of Run returns true (OK)");

	return $testscore;
	} 

1;
