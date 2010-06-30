#!/bin/perl
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
# Automated Component Based Releasing system front end
# 
#

use strict;
use Getopt::Long;
use Cwd;
use FindBin;

use lib $FindBin::Bin;

use CStageRunner;
use CConfig;

my @GTTechViewPrepareStages=("CCreateDrive","CGetPrevRel","CCheckMrpUpdates","CDelta", "CCheckEnv");
my @GTTechViewReleaseStages=("CReleaseEnv","CStoreMrpState");
my @GTstages=("CRemoveNonGT", "CInstallGTConflicts", "CPrepGTRelease", "CCheckEnv", "CReleaseEnv");
my @finishStages=("CCleanUp");

my $help = q/
  makecbr.pl -b build_id -c config_file -v release_version [-j max_processes]
    [-i int_version] [-p prev_version] [-l log_file] [-d debug_output] [-repair]
   * where:
  build_id is a unique build identifier
  config_file is the filename of the configuration file
  release_version is the version to be assigned to any updated components
   * Optionally:
  max_processes is the maximum number of parallel processes allowed
  int_version is the internal version string to use for publishing components
  prev_version is the version to assume as the previous baseline, to override
    automatic determination
  log_file is a file to log all output to
  debug_output is a file to write intermediate stage output to in case of an
    error
   * -repair assumes a failure in GT_TechView and resumes from the MakeEnv step.
/;

my($build_id, $config_file, $log_file, $parallel, $release_ver, $debug_file, $help_flag, $prev_ver, $repair, $int_ver);

GetOptions (
   'b=s'    => \$build_id,
   'c=s'    => \$config_file,
   'l=s'    => \$log_file,
   'v=s'    => \$release_ver,
   'p=s'    => \$prev_ver,
   'd=s'    => \$debug_file,
   '+h'     => \$help_flag,
   'repair' => \$repair,
   'i=s'    => \$int_ver,
   'j=i'    => \$parallel
);

if (defined($help_flag))
	{
	print $help;
	exit;
	}

if (!defined($config_file))
	{
	die "A configuration file must be specified (using the -c option)\n";
	}

if (!defined($parallel)) {
   $parallel = 0;
}

my $options = New CConfig();
if (defined($log_file))
	{
	$options->SetLog($log_file) or exit;
	}

if (defined($debug_file))
	{
	# Ensure path isn't relative

	if ($debug_file !~ /^[A-Za-z]:/)
		{
		if ($debug_file =~ /^[^\/\\]/)
			{
			# Path is relative
			$debug_file = getcwd()."\\".$debug_file;
			}
		else
			{
			# Path is only missing drive letter
			my $drive = getcwd();
			$drive =~ s/^([A-Za-z]):.*$/$1/ or $options->Die("ERROR: getcwd() did not return drive letter, rather '$drive'");
			$debug_file = $drive.":".$debug_file;
			}
		}
	$debug_file =~ s/\//\\/g; # Make all slashes backslashes
	}

$options->Reload($config_file) or $options->Die("ERROR: Couldn't load config file '$config_file'");

$options->Set("Build identifier",$build_id) or $options->Die("ERROR: Build identifier '$build_id' is invalid");
$options->Set("Release version",$release_ver) or $options->Die("ERROR: Release version '$release_ver' is invalid");

if (defined($int_ver))
    {
    $options->Set("Internal version",$int_ver) or $options->Die("ERROR: Internal version '$int_ver' is invalid");
    }
else
    {
    $options->Set("Internal version",$release_ver);
    }

if (defined($prev_ver))
	{
	$options->Set("Last baseline version",$prev_ver) or $options->Die("ERROR: Previous baseline version '$prev_ver' is invalid");
	}

if (defined($parallel)) {
   $options->Set('Max Parallel Tasks', $parallel) or $options->Die("ERROR: Max parallel processes '$parallel' is invalid");
}

my @stages = ();
if (defined($repair))
	{
	push @stages, "CConfigureRepair";
	}
else
	{
	push @stages, @GTTechViewPrepareStages;
	}
    
push @stages, (@GTTechViewReleaseStages, @GTstages, @finishStages);

my $stageRunner = New CStageRunner(\@stages, $options);
if (!$stageRunner->Run())
	{
	if (defined($debug_file))
		{
		$options->Save($debug_file);
		}
	$options->Die("");
	}
