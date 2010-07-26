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
# CCleanUp
# Returns the machine configuration to its initial state
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CCleanUp;
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
	$self->CheckOpt('Spare drive letter');
	
	# Checks list options are defined and set to lists; dies otherwise
	# $self->CheckListOpt('List option name');
	}

# boolean PreCheck()
# Ensures that all required results from previous stages are set to reasonable
# values before this stage is run
#
# Returns false if result options are invalid
sub PreCheck()
	{
	my $self = shift;

	return 1; # Nothing to check
	}

# boolean Run()
# Performs the body of work for this stage
#
# Returns false if it encounters problems
sub Run()
	{
	my $self = shift;

	my $options = $self->iOptions();

	my $drive = $options->Get("Spare drive letter");
	$drive =~ s/:$//;
	$drive = $drive.":"; # Ensure there is a single colon on the end
	
	if (system("subst /D $drive"))
		{
		$options->Warning("Couldn't clean up $drive drive");
		}
	
	return 1; # This stage has no fatal errors
	}
1;
