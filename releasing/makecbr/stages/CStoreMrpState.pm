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
# CStoreMrpState
# Records checksums for all mrp files used, for comparison in the next build
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CStoreMrpState;
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
	$self->CheckOpt('Release version');
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
      next if ($line =~ /\*nosource\*/);
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
      next if ($line =~ /\*nosource\*/);
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
		
		if (!-e $mrpfile)
			{
			$options->Error("MRP file '".$mrpfile."' for component '".$component."' does not exist, ignoring it.");
      # Knock this component out and keep going
      delete ($self->{iCOMPONENTS}{$component});
			}
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
	my $ver = $options->Get("Release version");

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
	
	# Install inidata API
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

	# Write file
	
	my %oldmrps = ();
	
	if (!(my $inidata = IniData->New()))
		{
		$options->Error("Couldn't read reltools.ini");
		$passed = 0;
		}
	elsif (!(my $path = $inidata->PathData->LocalArchivePathForExistingComponent($base, $ver)))
		{
		$options->Error("'$base' component at version '$ver' does seem to have been released");
		$passed = 0;
		}
	else
		{
		open(HASHFILE,">".$path."\\mrphash.lis");
		
		foreach my $component (keys(%{$self->iComponents()}))
			{
      # Support for scanlog phase component
      $options->Component($component);

			# Create hash for current mrp file
			my $mrppath = $self->iComponents()->{$component};
			
			$md5->reset();
		
			my $file;	
			if (!($file = IO::File->new($mrppath)))
				{
				$options->Error("Could not open \"$mrppath\" for reading: $!");
				$passed = 0;
				last;
				}
			
			$md5->addfile($file);
			$file->close();
			my $hash = $md5->hexdigest();
			
			print HASHFILE "$component $mrppath $hash\n";
			}

		close(HASHFILE);
		}
    
	return $passed;
	}
1;
