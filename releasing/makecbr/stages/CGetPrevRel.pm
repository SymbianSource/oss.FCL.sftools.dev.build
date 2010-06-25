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
# CGetPrevRel
# Identify the last release version
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CGetPrevRel;
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

	# Checks options are defined; dies otherwise
	$self->CheckOpt('GT+Techview baseline component name');

	if (!$self->iOptions()->CheckRelTools())
		{
		$self->iOptions()->Die("ERROR: Couldn't find release tools in path");
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

	return 1; # Nothing to check from any previous stage
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

	my $basecomp = $options->Get('GT+Techview baseline component name');
	my $lastrel = $options->Get('Last baseline version');

	if (defined($lastrel))
		{
		$options->Print("Last baseline version manually defined as: $lastrel");

        return 1 if $lastrel =~ /^__initial/i; # special - no previous release

		# Check specified version exists

		$options->RequireRelTools();

		# Get list of components in previous release

		my $basecomp = $options->Get("GT+Techview baseline component name");
		my $lastver = $options->Get("Last baseline version");

		if (!(my $inidata = IniData->New()))
			{
			$options->Error("Couldn't read reltools.ini");
			$passed = 0;
			}
		else
			{
			my $reldata;
			eval
				{
				$reldata = RelData->Open($inidata, $basecomp, $lastver, 0);
				};
			unless( defined($reldata) )
				{
				$options->Print("REMARK: Couldn't open version $lastver of $basecomp");
				$lastrel = undef; # Revert to determining latest version
				}
			}
		}

	if (!defined($lastrel))
		{
		# Use latestver to determine last baseline version

		if (!defined($basecomp))
			{
			$options->Error("GT+Techview baseline component not set for latestver");
			$passed = 0;
			}
		elsif (!open (LATESTVER, "latestver $basecomp 2>&1 |"))
			{
			$options->Error("Couldn't spawn child process for latestver");
			$passed = 0;
			}
		else
			{
			my @output = ();
			my $version = undef;

			foreach my $line (<LATESTVER>)
				{
				chomp $line;
				push @output, $line;

				if ($line !~ /^\s*$/)
					{
					if (defined($version))
						{
						$options->Error("Latestver output had too many lines:");
						$passed = 0;
						last;
						}
					else
						{
						$version = $line;
						}
					}
				}

			if (!close (LATESTVER))
				{
				$options->Error("Latestver command failed:");
				$passed = 0;
				}

			if ($passed == 0)
				{
				foreach my $error (@output)
					{
					$options->Print($error);
					}
				}
			else
				{
				if ($options->Set("Last baseline version", $version))
					{
					$options->Print("Last baseline version determined as: $version");
					}
				else
					{
					$passed = 0;
					}
				}
			}
		}

	return $passed;
	}
1;
