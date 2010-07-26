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
# CPrepGTRelease
# Prepare GT only baseline and GT conflicts components for release
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CPrepGTRelease;
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
	$self->CheckOpt('GT only baseline component name');
	$self->CheckOpt('GT only baseline mrp location');
	$self->CheckOpt('GT conflicts component name');
	$self->CheckOpt('GT conflicts mrp location');
	$self->CheckOpt('Release version');
	}

# boolean PreCheck()
# Ensures that all required results from previous stages are set to reasonable
# values before this stage is run
#
# Returns false if result options are invalid
sub PreCheck()
	{
	my $self = shift;

	return 1; # Nothing to check; always passes
	}

# boolean Run()
# Performs the body of work for this stage
#
# Returns false if it encounters problems
sub Run()
	{
	my $self = shift;
	my $passed = 1; # True, so far

	my $options=$self->iOptions();

	my $baselinemrp = $options->Get('GT only baseline mrp location');
	my $baselinename = $options->Get('GT only baseline component name');
	my $conflictsmrp = $options->Get('GT conflicts mrp location');
	my $conflictsname = $options->Get('GT conflicts component name');
	my $version = $options->Get('Release version');

	my $output = `preprel -v $baselinename $version $version -m $baselinemrp 2>&1`;
	if ($? >> 8)
		{
		$options->Error("Preprel failed for $baselinename: $output");
		$passed = 0;
		}
	
	$output = `preprel -v $conflictsname $version $version -m $conflictsmrp 2>&1`;
	if ($? >> 8)
		{
		$options->Error("Preprel failed for $conflictsname: $output");
		$passed = 0;
		}
	
	return $passed;
	}
1;
