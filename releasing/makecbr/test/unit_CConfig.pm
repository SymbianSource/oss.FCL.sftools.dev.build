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
# Unit test for CConfig
# 
#

package unit_CConfig;

use lib qw(../);
use lib qw(../stages);
use FindBin;
use Cwd;
use lib $FindBin::Bin."\\..";
use CConfig;
use CTestScore;

sub RunTest($)
	{
	my ($testscore) = @_;

	print "> *** Testing CConfig ***\n";

	if (!defined($testscore))
		{
		$testscore = New CTestScore();
		}
	
	if (!defined($ENV{TEMP}))
		{
		print STDOUT "TEMP environment variable must be defined before testing of CConfig is run.\n";
		return $testscore;
		}
		
	my $testFilename = $ENV{TEMP}."\\CConfig.tst";
	
	if (-e $testFilename)
		{
		print STDOUT "File '$testFilename' already exists.\nPlease delete this file to enable testing of CConfig.\n";
		return $testscore;
		}
		
	open(TESTFILE,">$testFilename");
	print TESTFILE "Key:value\n";
	close(TESTFILE);

	my $testConfig=New CConfig($testFilename);
	
	$testscore->Test($testConfig->Get("Key") eq "value", "Loaded in file");
	$testscore->Test($testConfig->Get("kEy") eq "value", "Tested key case insensitivity");
	$testscore->Test($testConfig->Set("key:2", "value2"), "Set extra key");
	$testscore->Test( ($testConfig->Get("Key") eq "value") && ($testConfig->Get("key:2") eq "value2"), "Returned all key values");
	$testscore->Test(!defined($testConfig->Get("nokey")), "Getting invalid key is undefined");
	$testscore->Test($testConfig->Set("key3", ["value3","value4"]), "Set list value");
	my $listref=$testConfig->Get("key3");
	$testscore->Test( (ref($listref) eq "ARRAY") && (($listref->[0]) eq "value3") && (($listref->[1]) eq "value4"), "Returned list value");
	$testscore->Test($testConfig->Save($testFilename), "Saved file");
	$testConfig->Set("key4", "value5");
	$testscore->Test($testConfig->Reload($testFilename), "Loaded file");
	$listref=$testConfig->Get("key3");
	$testscore->Test( ($testConfig->Get("Key") eq "value") && ($testConfig->Get("key:2") eq "value2") && (ref($listref) eq "ARRAY") && (($listref->[0]) eq "value3") && (($listref->[1]) eq "value4") && (!defined( $testConfig->Get("key4") )), "Returned all key values");
	$testscore->Test(!($testConfig->Set(undef, "val")), "Can't set undefined key");
	$testscore->Test(!($testConfig->Set("key5", undef)), "Can't set undefined value");
	$testscore->Test($testConfig->Set("key6", ""), "Can set empty value");
	$testscore->Test($testConfig->Set("", "val"), "Can set empty key");
	$testscore->Test(!($testConfig->Set("key7", {"hashkey"=>"hashval"})), "Can't set hash value");
  
  # Support for additional behaviour to handle Error message, scanlog format etc.
	my $logFilename = "CConfig_scanlog.log";
  TestConfigStatus($testConfig, $testscore);
  TestLogFile($testFilename, $logFilename, $testscore);
  ValidateLogFile($logFilename, $testscore);
	unlink $logFilename;
  TestDieConditions($testFilename, $testscore);
	unlink $testFilename;
  
	return $testscore;
	} 

sub TestConfigStatus($$)
  {
  my $testConfig = shift;
  my $testScore = shift;
  # First check the initial internal state of CConfig
  $testScore->Test($testConfig->{iPhaseErrorCount} == 0, "Initial error count is zero");
  $testScore->Test(!defined ($testConfig->{iPhase}), "Initial undefined initial phase");
  }

# This writes out a log file
sub TestLogFile($$)
	{
  my $testFilename = shift;
  my $logFilename = shift;
  my $testScore = shift;
  my $testConfig = New CConfig($testFilename);
  # This puts a logfile in the current working directory
  # i.e. test/CConfig.log
	#my $logFilename = "CConfig_scanlog.log";
  $testConfig->SetLog($logFilename);
  #$testConfig->Command("Command");
  $testConfig->PhaseStart("Phase_1");
  $testScore->Test($testConfig->{iPhase} eq "Phase_1", "Phase_1 defined");
  $testConfig->Component("Component_1");
  $testConfig->Error("Phase_1 error message");
  $testConfig->Warning("Phase_1 warning message");
  my $phaseErrors = $testConfig->PhaseEnd();
  $testScore->Test($phaseErrors == 1, "Phase_1 reported 1 error");
  $testConfig->PhaseStart("Phase_2");
  $testConfig->Warning("Phase_2 warning message");
  $testConfig->Print("Opening Phase_3 should finish Phase_2");  
  $testConfig->PhaseStart("Phase_3");
  $testScore->Test(1, "Phase switching didn't die");
  $phaseErrors = $testConfig->PhaseEnd();
  $testScore->Test($phaseErrors == 0, "Phase_3 reported no errors");
  #my $logPath = cwd()."/".$logFilename;
  #print "> *** Please check CConfig log file at $logPath ***\n";
  $testScore->Test(1, "Logfile \"$logFilename\" written");
  }

sub ValidateLogFile($$)
  {
  # This is the expected log file output - without the date/time stamp
  my $logFilename = shift;
  my $testScore = shift;
  my $logFileExpected = "===-------------------------------------------------
=== Phase_1
===-------------------------------------------------
=== Phase_1 started 
=== Phase_1 == Component_1
ERROR: Phase_1 error message
WARNING: Phase_1 warning message
=== Phase_1 finished 
===-------------------------------------------------
=== Phase_2
===-------------------------------------------------
=== Phase_2 started 
WARNING: Phase_2 warning message
Opening Phase_3 should finish Phase_2
=== Phase_2 finished 
===-------------------------------------------------
=== Phase_3
===-------------------------------------------------
=== Phase_3 started 
=== Phase_3 finished 
";
  $testScore->Test($logFileExpected eq ReadTimelessLogFile($logFilename), "Logfile \"$logFilename\" matches");
  }

# Read a scanlog file and strip the time/date stamp
sub ReadTimelessLogFile($)
  {
    my $filename = shift;
    my $retVal;
  	open(LOGFILE,"$filename");
    while (defined (my $line = <LOGFILE>))
      {
      if ($line =~ m/.+started .+/)
        {
        $line =~ s/(.+started ).+/$1/;
        }
      elsif ($line =~ m/.+finished .+/)
        {
        $line =~ s/(.+finished ).+/$1/;
        }
      $retVal .= $line;
      }
    #print "\nParsed:\n";
    #print $retVal;
    return $retVal;
  }

sub TestDieConditions($$)
  {
    my $testFilename = shift;
    my $testScore = shift;
    my $testConfig;
    my $logFilename = "CConfig_scrap.log";
    # Try a direct Die() call
    $testConfig = New CConfig($testFilename);
    eval
      {
      $testConfig->Die("Die message.");
      };
    if ($@) {
      $testScore->Test(1, "Died on Die() command");
    } else {
      $testScore->Test(0, "Failed to die on Die() command");
    }
    # Try setting SetErrorDie() then calling Error()
    $testConfig = New CConfig($testFilename);
    $testConfig->SetLog($logFilename);
    # Try PhaseEnd() before any PhaseStart() has been called
    $testConfig = New CConfig($testFilename);
    $testConfig->SetLog($logFilename);
    eval
      {
      # No PhaseStart() has been made so a PhaseEnd() should fail
      $testConfig->PhaseEnd();
      };
    if ($@) {
      $testScore->Test(1, "Died on PhaseEnd() command when there was no prior PhaseStart()");
    } else {
      $testScore->Test(0, "Failed to die on PhaseEnd() command");
    }
    # Try setting provoking PhaseEnd() when phase has errors
    $testConfig = New CConfig($testFilename);
    $testConfig->SetLog($logFilename);
    $testConfig->PhaseStart("Error_Phase_1");
    $testConfig->Error("Error message.");
    eval
      {
      # Here is the killer line that should cause it to fail.
      # Phase 1 has an error but the phase has not been collected
      # before starting False_Phase_2
      $testConfig->PhaseStart("False_phase_2");
      };
    if ($@) {
      $testScore->Test(1, "Died on PhaseStart() command when previous phase had Error() calls");
    } else {
      $testScore->Test(0, "Failed to die on Error() command");
    }
  	unlink $logFilename;
  }

1;
