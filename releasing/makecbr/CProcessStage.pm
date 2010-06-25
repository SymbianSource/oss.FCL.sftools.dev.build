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
# CProcessStage
# 
#

package CProcessStage;

use strict;

# CProcessStage New(CConfig aOptions) : constructor
sub New($)
	{
	my $proto = shift;
	my ($aOptions) = @_;

	my $class = ref($proto) || $proto;

	my $self = {};
	bless($self, $class);

	# Save class name
	$self->iName($class);

	# Store options
	$self->iOptions($aOptions);

	# Validate options
	$self->CheckOpts();

	return $self;
	}

# Getter/setters
sub iOptions
	{
	my $self = shift;
	if (@_) { $self->{iOPTIONS} = shift; }
	return $self->{iOPTIONS};
	}
sub iName
	{
	my $self = shift;
	if (@_) { $self->{iNAME} = shift; }
	return $self->{iNAME};
	}

# void CheckOpts()
# Panics if options invalid
sub CheckOpts()
	{
	}

# boolean PreCheck()
sub PreCheck()
	{
	return 1; # Nothing to check - check passed
	}

# boolean Run()
sub Run()
	{
	return 1; # Nothing run - nothing failed
	}

# Convenience functions...

# void CheckOpt()
# Dies if option not defined, or is a list
sub CheckOpt($)
	{
	my $self = shift;
	my ($option) = @_;
	my $options = $self->iOptions();

	my $val = $options->Get($option);
	if (!defined($val))
		{
		$options->Die("ERROR: Option '$option' not defined.");
		}
	elsif (ref($val))
		{
		$options->Die("ERROR: Option '$option' must not be a list.");
		}
	}

# void CheckListOpt()
# Dies if option is not a listref, or is not defined
sub CheckListOpt($)
	{
	my $self = shift;
	my ($option) = @_;
	my $options = $self->iOptions();

	my $val = $options->Get($option);
	if (!defined($val))
		{
		$options->Die("ERROR: Option '$option' not defined.");
		}
	elsif (ref($val) ne "ARRAY")
		{
		$options->Die("ERROR: Option '$option' must be a list.");
		}
	}

# void PreCheckOpt()
# Returns false if option is not defined or is a list
sub PreCheckOpt($)
	{
	my $self = shift;
	my ($option) = @_;

	my $val = $self->iOptions()->Get($option);
	if ( (!defined($val)) || (ref($val)) )
		{
		return 0;
		}
	else
		{
		return 1;
		}
	}
	
# void PreCheckListOpt()
# Returns false if option is not a listref, or is not defined
sub PreCheckListOpt($)
	{
	my $self = shift;
	my ($option) = @_;

	my $val = $self->iOptions()->Get($option);
	if ( (!defined($val)) || (ref($val) ne "ARRAY") )
		{
		return 0;
		}
	else
		{
		return 1;
		}
	}
1;
