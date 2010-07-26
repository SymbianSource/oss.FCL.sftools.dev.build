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
# CRemoveNonGT
# Removes any components not belonging to the GT release from the environment including their installed binaries
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CRemoveNonGT;
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
	my $options=$self->iOptions();

	# Checks option is defined; dies otherwise
	$self->CheckOpt('GT component list'); # Ensures option named 'GT component List' is defined
	
	# Checks option is set correctly
	if (!-e $options->Get("GT component list"))
		{
		$options->Die("ERROR: File '".$options->Get("Component list")."' (component list) could not be found");
		}
		
	# Load in list of components and corresponding .mrp files
	my $complist = $options->Get("GT component list");
	my @components;

	if (!open(COMPLIST, $complist))
		{
		$options->Die("ERROR: Could not open '$complist' (GT component list)");
		}
	else
		{
		foreach my $line (<COMPLIST>)
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
					push @components, lc($parms[0]);
					}
				}
			}
			
		close(COMPLIST);
		}

	# Search for envdb API
	my $found = 0;
	foreach my $path (split(/;/,$ENV{PATH}))
		{
		if (-e $path."\\envdb\.pm")
			{
			$found = 1;
			last;
			}
		}
	
	if (!$found)
		{
		$options->Die("ERROR: Couldn't find release tools in path");
		}
		
	$self->iComponents(\@components);
	}

# boolean PreCheck()
# Ensures that all required results from previous stages are set to reasonable
# values before this stage is run
#
# Returns false if result options are invalid
sub PreCheck()
	{
	my $self = shift;

	return 1; # Nothing to check - always passes
	}

# Getter/setters
sub iComponents
	{
	my $self = shift;
	if (@_) { $self->{iCOMPONENTS} = shift; }
	return $self->{iCOMPONENTS};
	}
	
# boolean Run()
# Performs the body of work for the stage
#
# Returns false if it encounters problems
sub Run()
	{
	my $self = shift;
	my $passed = 1; # True, so far
	my $options=$self->iOptions();

	# Install envdb API
	my $found = 0;
	foreach my $path (split(/;/,$ENV{PATH}))
		{
		if (-e $path."\\envdb\.pm")
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
		
	require EnvDb;
	require IniData;

	my $envdb;

	if (!(my $inidata = IniData->New()))
		{
		$options->Error("Couldn't read reltools.ini");
		$passed = 0;
		}
	elsif (!($envdb = EnvDb->Open($inidata, 0)))
		{
		$options->Error("Couldn't open environment database");
		$passed = 0;
		}
	
	# Determine currently installed components
	my @envComps;
	
	if ($envdb)
		{
		@envComps = keys(%{$envdb->VersionInfo()});
		}
	
	# Remove any components not in the GT component list
	my @listComps = @{$self->iComponents()};
	foreach my $component (@envComps)
		{
    # Support for scanlog phase component
    $options->Component($component);
		my @found = grep( (lc($_) eq lc($component)), @listComps );
		if (scalar(@found)==0)
			{
			$envdb->RemoveComponent($component);
			}
		}

	return $passed;
	}
1;
