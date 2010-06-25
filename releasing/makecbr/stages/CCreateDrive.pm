#!\bin\perl
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
# CCreateDrive
# Create release drive and configure the release tools
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CCreateDrive;
use vars ('@ISA');
@ISA = qw( CProcessStage );

use Cwd;
use Cwd 'chdir';
use File::Path;
use File::Basename;

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
	if (($drive !~ /^[A-Z]:?$/i) and ($drive !~ /^[A-Z]?\*:?$/i))
		{
		$options->Error("'$drive' is not a valid drive letter.");
		$passed = 0;
		}

	my $reltoolsini = $options->Get("Reltools.ini location");
	if (!-e $reltoolsini)
		{
		$options->Error("Reltools file '$reltoolsini' does not exist");
	   	$passed = 0;
		}

	my $releasenotestemplate = $options->Get("Release notes template location");
	if (!-e $releasenotestemplate)
		{
		$options->Error("Release notes template '$releasenotestemplate' does not exist");
		$passed = 0;
		}

	my $techviewdir = $options->Get("Techview directory");
	$techviewdir =~ s/[\/\\]+$//; # Remove trailing slashes for consistency
	if (!-d $techviewdir)
		{
		$options->Error("Techview directory '$techviewdir' does not exist");
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

	# Store existing drive letter
	my $olddrive = Cwd::getcwd();

	STOP:
		{
		do
			{
			if ($olddrive !~ /^[A-Za-z]:/)
				{
				$options->Error("getcwd() did not return drive letter, rather '$olddrive'");
				$passed = 0;
				last STOP;
				}

			$olddrive = substr($olddrive,0,1);

			($options->Set("Original drive", $olddrive)) or ($passed = 0);

			my $reltools = $options->Get("Reltools.ini location");
			if ($reltools !~ /^[A-Za-z]:/)
				{
				# Add the original drive letter if it has been omitted
				$reltools = $olddrive.":".$reltools;
				}

			my $techviewdir = $options->Get("Techview directory");
			if ($techviewdir !~ /^[A-Za-z]:/)
				{
				$techviewdir = $olddrive.":".$techviewdir;
				}
			$techviewdir =~ s/[\/\\]+$//; # Remove any slashes from the end which can break subst

			my $releasenotestemplate = $options->Get("Release notes template location");
			if ($releasenotestemplate !~ /^[A-Za-z]:/)
				{
				$releasenotestemplate = $olddrive.":".$releasenotestemplate;
				}
			my $dpfile = File::Basename::dirname($releasenotestemplate) . '/distribution.policy';
			$dpfile =~ s/\//\\/g;

			my $releasenotes = $options->Get("Release notes location");
			my $dptarget =  File::Basename::dirname($releasenotes) . '/distribution.policy';
			$dptarget =~ s/\//\\/g;

			my $drive = $options->Get("Spare drive letter");

			if ($drive !~ /:$/)
				{
				$drive = $drive.":";
				}

			if ($drive =~ /\*:$/)
				{
				# Search for available drive
				$drive =~ s/\*:$//;
				$drive = uc($drive);

				if (length($drive) == 0)
					{
					# Start drive not specified
					$drive = 'A';
					}
				elsif (length($drive) > 1)
					{
					# Assert: This /should/ have already been checked.
					$options->Error("$drive is not a valid drive letter to search from");
					$passed = 0;
					last STOP;
					}

				while (ord($drive) <= ord('Z'))
					{
					system("subst $drive: ".$techviewdir." > nul 2>&1") or last;
					$drive = chr(ord($drive)+1);
					}

				if (ord($drive) <= ord('Z'))
					{
					if ($options->Set("Spare drive letter", "$drive:"))
						{
						$options->Print("Using drive $drive: as spare drive");
						$drive = $drive.":";
						}
					else
						{
						$options->Error("Couldn't store found drive letter ($drive:)");
						$passed = 0;
						last STOP;
						}
					}
				else
					{
					$options->Error("Couldn't find a spare drive to use");
					$passed = 0;
					last STOP;
					}
				}
			else
				{
				# Subst drive directly
				my $output = `subst $drive $techviewdir 2>&1`;
				if ($? >> 8)
					{
					$options->Error("Couldn't subst to '$techviewdir' to $drive : $output");
					$passed = 0;
					last STOP;
					}
				}

			if (!chdir($drive))
				{
				$options->Error("Couldn't change to drive $drive : $!");
				$passed = 0;
				last STOP;
				}

			# Install reltools.ini

			if (!-d "\\epoc32\\relinfo")
				{
				my $output = `mkdir \\epoc32\\relinfo 2>&1`;
				if ($? >> 8)
					{
					$options->Error("Couldn't create \\epoc32\\relinfo directory: $output");
					$passed = 0;
					last STOP;
					}
				}

            my $ini = '\epoc32\relinfo\reltools.ini';

            unlink($ini) if -e $ini; # delete if it's already there

			my $output = `copy $reltools $ini 2>&1`;
			if ($? >> 8)
				{
				$options->Error("Couldn't install reltools.ini file from $reltools: $output");
				$passed = 0;
				last STOP;
				}

			# Set path

			$ENV{PATH} = $ENV{PATH}.";$drive\\epoc32\\tools;$drive\\epoc32\\gcc\\bin;";
			$ENV{EPOCROOT} = "\\";

			# Create release note
			if (!open(TEMPLATE, $releasenotestemplate))
				{
				$options->Error("Could not read from release notes template '$releasenotestemplate': $!");
				$passed = 0;
				last STOP;
				}

			my $releasenotesdir = $releasenotes;
			$releasenotesdir =~ s/[\/\\][^\/\\]*$//;
			if (!-d $releasenotesdir)
				{
				if (!mkpath($releasenotesdir))
					{
					$options->Error("Could not create directory '$releasenotesdir' for release notes: $!");
					$passed = 0;
					close(TEMPLATE);
					last STOP;
					}
				}
			system("copy $dpfile $dptarget > nul 2>&1");

			if (!open(NOTES, ">".$releasenotes))
				{
				$options->Error("Could not write release notes to '$releasenotes': $!");
				$passed = 0;
				close(TEMPLATE);
				last STOP;
				}

			foreach my $line (<TEMPLATE>)
				{
				chomp($line);

				# Replace macros
				my $found;
				do
					{
					$found = 0;
					my $opening = index($line, "%");
					if ($opening != -1)
						{
						my $closing = index($line, "%", $opening+1);

						if ($closing != -1)
							{
							$found = 1;
							my $len = $closing-$opening+1;
							my $key = substr($line, $opening+1, $len-2);
							my $value = $options->Get($key);
							if (defined($value))
								{
								substr($line, $opening, $len, $value);
								}
							else
								{
								$options->Error("No value for '$key' defined, as found in release notes template");
								$passed = 0;
								close(NOTES);
								close(TEMPLATE);
								last STOP;
								}
							}
						}
					} while ($found);

				print NOTES $line."\n";
				}

			close(TEMPLATE);
			close(NOTES);
			}
		# 'last STOP' jumps here
		}

	return $passed;
	}
1;
