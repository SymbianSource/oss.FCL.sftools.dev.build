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
# CInstallGTConflicts
# Installs GT versions of any files (as listed in the techview_dups log)
# and writes an mrp file to ship those files in the GT only release
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CInstallGTConflicts;
use vars ('@ISA');
@ISA = qw( CProcessStage );

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
	$self->CheckOpt('Conflicting files log');
	$self->CheckOpt('GT directory');
	$self->CheckOpt('GT conflicts mrp location');
	$self->CheckOpt('GT conflicts component name');
	$self->CheckOpt('Release notes location');

	# Checks and loads conflicting files log
	my $gtConflicts = $options->Get('Conflicting files log');

	if (!-e $gtConflicts)
		{
		$options->Die("ERROR: Conflicting files log '$gtConflicts' does not exist");
		}
	elsif (open(GTCONFLICTS, $options->Get('Conflicting files log')))
		{
		my @conflicts;
		
		foreach my $line (<GTCONFLICTS>)
			{
			chomp($line);
			push @conflicts, $line;
			}
		close (GTCONFLICTS);

		$self->iConflicts(\@conflicts);
		}
	else
		{
		$options->Die("ERROR: Couldn't open conflicting files log: $!");
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
	my $passed = 1; # True, so far

	if (!$self->PreCheckOpt("Original drive"))
	 	{
		$self->iOptions()->Error("Original starting drive has not been recorded");
	 	$passed = 0;
	 	}

	return $passed;
	}

# Getter/setters
sub iConflicts
	{
	my $self = shift;
	if (@_) { $self->{iCONFLICTS} = shift; }
	return $self->{iCONFLICTS};
	}
	
# boolean Run()
# Performs the body of work for this stage
#
# Returns false if it encounters problems
sub Run()
	{
	my $self = shift;

	my $passed = 1; # True, so far

	my @conflicts = @{$self->iConflicts()};
	my $options = $self->iOptions();
  
	my $GTdir = $options->Get('GT directory');
	my $olddrive = $options->Get('Original drive');
	if ($GTdir !~ /^[A-Za-z]:/)
		{
		# Add the original drive letter if it has been omitted
		$GTdir = $olddrive.":".$GTdir;
		}
	my $mrppath = $options->Get('GT conflicts mrp location');
	my $mrpname = $options->Get('GT conflicts component name');
	my $relnotes = $options->Get('Release notes location');
	my $mrpdir = $mrppath;
	$mrpdir =~ s/[\/\\][^\/\\]*$//; # Remove leafname

	if (!-d $mrpdir)
		{
		if (!mkpath($mrpdir))
			{
			$options->Error("Couldn't make directory '$mrpdir'");
			$passed = 0;
			}
		}
	elsif (!open(MRP, ">$mrppath"))
		{
		$options->Error("Couldn't open '$mrppath' for writing: $!");
		$passed = 0;
		}
	else
		{
		print MRP "component\t$mrpname\n\n";
		
		foreach my $file (@conflicts)
			{
			$options->Print($file);
			my $dir = $file;
			$dir =~ s/[\/\\][^\/\\]*$//; # Remove leafname

			if (!-d $dir)
				{
				if (!mkpath($dir))
					{
					$options->Error("Couldn't make directory '$dir' for file '$file'");
					$passed = 0;
					next;
					}
				}
			
			if ($file !~ /^[\\\/]/)
				{
				# If path is not absolute, make it absolute
				$file = "\\".$file;
				}
			if (($file =~ /epoc32[\/\\].*\.sym$/) || ($file =~ /epoc32[\/\\].*\.bsc$/))
				{
				# These files are excluded from the environment deliberately
				}
			elsif (-e $file)
				{
				if ( ($file !~ /epoc32[\/\\]localisation[\/\\].*\.rpp$/i)
				  && ($file !~ /epoc32[\/\\]build[\/\\]/i) )
					{
					# File should not already be there. Try to determine the problem
					my @bininfo = `bininfo $file 2>&1`;
			
					if ($? >> 8)
						{
						$options->Warning("File '$file' from conflicting files log is present when non GT components have been removed. May be a source file?");
						}
					else
						{
						$options->Warning("File '$file' from conflicting files log is present in a GT component:");
						}
					
					foreach my $line (@bininfo)
						{
						if ($line =~ /^Usage:/)
							{
							last;
							}
						$options->Print($line);
						}
					}
				}
			elsif (system("copy $GTdir\\$file $file >nul 2>&1"))
				{
				# Build files are excluded, but might be regenerated. Worth trying
				# to copy if present, but no issue if not present.
				if ($file !~ /epoc32[\/\\]build[\/\\]/i)
					{
					$options->Error("Couldn't copy file '$file' from $GTdir: $!");
					$passed = 0;
					}
				}
			else
				{
				# Have copied $file from GT directory to working drive
					
				# Record the new file in the MRP file
				print MRP "binary\t$file\n";
				}
			}

		print MRP "notes_source\t$relnotes\n";
		close(MRP);
		}
	
	return $passed;
	}
1;
