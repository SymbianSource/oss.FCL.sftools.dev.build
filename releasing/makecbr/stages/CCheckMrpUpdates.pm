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
# CCheckMrpUpdates
# Compare MRP checksums against the last release to spot any changes
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CCheckMrpUpdates;
use vars ('@ISA');
@ISA = qw( CProcessStage );

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
	$self->CheckOpt('GT+Techview baseline component name');
	$self->CheckOpt('Techview component list');
	$self->CheckOpt('GT component list');

	# Check options are sensible
	my $techviewcomplist = $options->Get("Techview component list");
	my $GTcomplist = $options->Get("GT component list");

	if (!-e $techviewcomplist)
		{
		$options->Die("ERROR: File '".$techviewcomplist."' (Techview component list) could not be found");
		}
	if (!-e $GTcomplist)
		{
		$options->Die("ERROR: File '".$GTcomplist."' (GT component list) could not be found");
		}

	# Load in list of components and corresponding .mrp files
	my %components;

	if (!open(TECHVIEWCOMPLIST, $techviewcomplist))
		{
		$options->Die("ERROR: Could not open '$techviewcomplist' (Techview component list)");
		}
	elsif (!open(GTCOMPLIST, $GTcomplist))
		{
		$options->Die("ERROR: Could not open '$GTcomplist' (GT component list)");
		}
	else
		{
		foreach my $line (<TECHVIEWCOMPLIST>)
			{
			chomp $line;
			$line =~ s/^\s*//; # Remove extraneous spaces
			$line =~ s/\s*$//;

			if ($line!~/^#/)
				{
				my @parms = split(/\s+/, $line);

				if (scalar(@parms) != 2)
					{
					$options->Die("ERROR: Entries in Techview component list should be of the form 'name mrp_location'. Problem in line:\n$line");
					}
				else
					{
					$components{lc($parms[0])} = $parms[1];
					}
				}
			}
		foreach my $line (<GTCOMPLIST>)
			{
			chomp $line;
			$line =~ s/^\s*//; # Remove extraneous spaces
			$line =~ s/\s*$//;

			if ($line!~/^#/)
				{
				my @parms = split(/\s+/, $line);

				if (scalar(@parms) != 2)
					{
					$options->Die("ERROR: Entries in GT component list should be of the form 'name mrp_location'. Problem in line:\n$line");
					}
				else
					{
					$components{lc($parms[0])} = $parms[1];
					}
				}
			}

		close(TECHVIEWCOMPLIST);
		close(GTCOMPLIST);
		}

	$self->iComponents(\%components);

	# Search for inidata API
	my $found = 0;
	foreach my $path (split(/;/,$ENV{PATH}))
		{
		if (-e $path."\\inidata\.pm")
			{
			$found = 1;
			last;
			}
		}

	if (!$found)
		{
		$options->Die("ERROR: Couldn't find release tools in path");
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
	my $options = $self->iOptions();

	foreach my $component (keys(%{$self->iComponents()}))
		{
		my $mrpfile = $self->iComponents()->{$component};

		next if ($mrpfile eq '*nosource*');

		if (!-e $mrpfile)
			{
			$options->Error("CCheckMrpUpdates::PreCheck() MRP file '".$mrpfile."' for component '".$component."' does not exist, ignoring it.");
      # Knock this component out and keep going
      delete ($self->{iCOMPONENTS}{$component});
			}
		}

	if (!$self->PreCheckOpt("Last baseline version"))
	 	{
		$options->Error("Last baseline version has not been defined.");
	 	$passed = 0;
	 	}

	return $passed;
	}

# Getter/setters
sub iComponents
	{
	my $self = shift;
	if (@_) { $self->{iCOMPONENTS} = shift; }
	return $self->{iCOMPONENTS};
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

	my $base = $options->Get("GT+Techview baseline component name");
	my $lastver = $options->Get("Last baseline version");

	# Load and initalise MD5 hash creator
	my $md5;

	if (eval "require Digest::MD5")
		{ # Prefer Digest::MD5, if available.
		$md5 = Digest::MD5->new();
		}
	elsif (eval "require MD5")
		{ # Try old version of MD5, if available.
		$md5 = new MD5;
		}
	elsif (eval "require Digest::Perl::MD5")
		{ # Try Perl (Slow) version of MD5, if available.
		$md5 = Digest::Perl::MD5->new();
		}
	else
		{
		$options->Error("Cannot load any MD5 Modules");
		$passed = 0;
		}

	# Load in hashes for previous release

	# - Install inidata API
	my $found = 0;
	foreach my $path (split(/;/,$ENV{PATH}))
		{
		if (-e $path."\\inidata\.pm")
			{
			push @INC, $path;
			$found = 1;
			last;
			}
		}

	if (!$found)
		{
		$options->Error("Couldn't find release tools in path");
		}

	require IniData;

	# - Read previous hashes

	my %oldmrps;

	if ($lastver =~ /^__initial/i)
	    {
	    # special - no previous release
	    }
	elsif (!(my $inidata = IniData->New()))
		{
		$options->Error("Couldn't read reltools.ini");
		$passed = 0;
		}
	elsif (!(my $path = $inidata->PathData->LocalArchivePathForExistingComponent($base, $lastver)))
		{
		$options->Error("Couldn't locate '$base' component at version '$lastver'");
		$passed = 0;
		}
	else
		{
		if (open(HASHFILE,$path."\\mrphash.lis"))
			{
			foreach my $line (<HASHFILE>)
				{
				my @args = split(/\s+/,$line);
				if (scalar(@args) != 3)
					{
					$options->Error("Failed to parse line '$line' from file '$path\\mrphash.lis");
					$passed = 0;
					last;
					}
				my ($comp, $mrppath, $hash) = @args;

				$oldmrps{lc($comp)} = [$mrppath, $hash];
				}

			close(HASHFILE);
			}
		}

	my @differing=();

	if ($passed)
		{
		foreach my $component (keys(%{$self->iComponents()}))
			{
			# Don't need to check ISC components, they have no mrp file    
			next if ($self->iComponents()->{lc($component)} eq '*nosource*');    
                            
			# Support for scanlog phase component
			$options->Component($component);
			
			# Compare filenames
			if (!defined( $oldmrps{lc($component)} ))
				{
				$options->Print("Not comparing $component - new component");
				}
			else
				{
				my ($oldpath, $oldhash) = @{$oldmrps{lc($component)}};
				my $newpath = $self->iComponents()->{lc($component)};
				if (lc($oldpath) ne lc($newpath))
					{
					$options->Print("Component ".$component."'s mrp file has moved from '$oldpath' to '$newpath'");
					push @differing, $component;
					}
				else
					{
					# Create hash for current mrp file
					$md5->reset();
					my $file;

					if (!($file = IO::File->new($newpath)))
						{
						$options->Error("Could not open \"$newpath\" for reading: $!");
						$passed = 0;
						last;
						}

					$md5->addfile($file);
					$file->close();
					my $newhash = $md5->hexdigest();

					# Compare
					if (lc($oldhash) ne lc($newhash))
						{
						$options->Print("Component ".$component."'s mrp file has been updated");
						push @differing, $component;
						}
					}
				}
			}

		if ($passed)
			{
			if (!($options->Set("Updated components", \@differing)))
				{
				$options->Error("Couldn't store updated mrp files list");
				$passed = 0;
				}
			}
		}

	return $passed;
	}
1;
