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
# CExampleStage - TODO - Change this when using this stage as a template
# <Insert description of this stage here>
# 
#

use strict;

use lib qw(../);
use lib qw(../stages);
use FindBin;
use lib $FindBin::Bin."\\..";

# Load base class
use CProcessStage;

package CExampleStage; # TODO - Change this when using this stage as a template
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
	print "Subclass checking options.\n";

	# Checks options are defined; dies otherwise
	# $self->CheckOpt('Option name');
	
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
	my $passed = 1; # True, so far

	print "Subclass pre-stage check.\n";
	# if (!$self->PreCheckOpt("key"))
	# 	{
	# 	$passed = 0;
	# 	}

	return $passed;
	}

# boolean Run()
# Performs the body of work for this stage
#
# Returns false if it encounters problems
sub Run()
	{
	my $self = shift;
	my $passed = 1; # True, so far

	print "Subclass stage running.\n";
	
	return $passed;
	}
1;
