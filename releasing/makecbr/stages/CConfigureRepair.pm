#!\bin\perl
# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# CConfigureRepair
# Create release drive and configure the release tools
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CConfigureRepair;
use vars ('@ISA');
@ISA = qw( CProcessStage );

use Cwd;
use Cwd 'chdir';
use File::Path;

# void CheckOpts()
# Ensures that all required (user) options are set to reasonable values at the
# start of execution
# 
# Dies if options invalid
sub CheckOpts()
	{
	my $self = shift;
	my $options = $self->iOptions();
	
	# Checks options are defined; dies otherwise
	$self->CheckOpt("Spare drive letter");
	$self->CheckOpt("Release notes template location");
	$self->CheckOpt("Release notes location");
	$self->CheckOpt("Reltools.ini location");
	$self->CheckOpt("Techview directory");

	# Checks options are sensible
	my $passed = 1;

	my $drive = $options->Get("Spare drive letter");
	if ($drive !~ /^[A-Z]:?$/i)
		{
		if ($drive !~ /\*/i)
			{
			$options->Error("'$drive' is not a valid drive letter.");
			}
		else
			{
			$options->Error("Cannot repair on drive '$drive' - an explicit drive letter must be given in the config file.");
			}
		$passed = 0;
		}
	
	my $reltoolsini = $options->Get("Reltools.ini location");
	if (!-e $reltoolsini)
		{
		$options->Print("ERROR: Reltools file '$reltoolsini' does not exist");
	   	$passed = 0;	
		}
	
	my $releasenotestemplate = $options->Get("Release notes template location");
	if (!-e $releasenotestemplate)
		{
		$options->Print("ERROR: Release notes template '$releasenotestemplate' does not exist");
		$passed = 0;
		}
	
	my $techviewdir = $options->Get("Techview directory");
	$techviewdir =~ s/[\/\\]+$//; # Remove trailing slashes for consistency
	if (!-d $techviewdir)
		{
		$options->Print("ERROR: Techview directory '$techviewdir' does not exist");
		$passed = 0;
		}
	
	if (!$passed)
		{
		$options->Die("");
		}
	}

# boolean PreCheck()
# Ensures that all required results from previous stages are set to reasonable
# values before this stage is run
#
# Returns false if result options are invalid
sub PreCheck()
	{
	my $self = shift;

	return 1; # Nothing from previous stages to check
	}

# boolean Run()
# Performs the body of work for this stage
#
# Returns false if it encounters problems
sub Run()
	{
	my $self = shift;
	my $passed = 1; # True, so far
	my $options = $self->iOptions();

	my $techviewdir = $options->Get("Techview directory");
	$techviewdir =~ s/[\/\\]+$//; # Remove any slashes from the end which can break subst
	
	# Store existing drive letter
	my $olddrive = Cwd::getcwd();
	
	if ($olddrive !~ /^[A-Za-z]:/)
	       	{
		$options->Print("ERROR: getcwd() did not return drive letter, rather '$olddrive'");
		$passed = 0;
		}
	else
		{
		$olddrive = substr($olddrive,0,1);

		($options->Set("Original drive", $olddrive)) or ($passed = 0);
		}

	my $drive = $options->Get("Spare drive letter");
	if ($drive !~ /:$/)
		{
		$drive = $drive.":";
		}

	if ($techviewdir !~ /^[A-Za-z]:/)
		{
		$techviewdir = $olddrive.":".$techviewdir;
		}
	
	if (!-d ($drive."\\"))
		{
		# Drive doesn't exist, subst it
		my $output = `subst $drive $techviewdir 2>&1`;
		if ($? >> 8)
			{
			$options->Error("Couldn't subst to '$techviewdir' to $drive : $output");
			$passed = 0;
			}
		}
	
	if ($passed && (!chdir($drive)))
		{
		$options->Print("ERROR: Couldn't change to drive $drive : $!");
		$passed = 0;
		}

	# Set path

	$ENV{PATH} = $ENV{PATH}.";$drive\\epoc32\\tools;$drive\\epoc32\\gcc\\bin;";
	$ENV{EPOCROOT} = "\\";

	return $passed;
	}
1;
