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
# \bin\perl
# CTestScore
# 
#

package CTestScore;

use lib qw(../);
use lib qw(../stages);

use strict;

sub New()
	{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {};
	bless($self, $class);

	$self->Reset();

	return $self;
	}

sub Reset()
	{
	my $self = shift;

	$self->{tested} = 0;
	$self->{passed} = 0;
	}

sub Test($$)
	{
	my $self = shift;
	my ($passed, $testname) = @_;

	if ($passed < 0)
		{
		$passed = 1;
		}

	$self->{tested} = $self->{tested}+1;
	$self->{passed} = $self->{passed}+$passed;

	if ($passed > 0)
		{
		print "-- $testname...OK\n";
		}
	else
		{
		print "*#*#* $testname...FAILED\n";
		}
	}

sub Print()
	{
	my $self = shift;

	my $tested = $self->{tested};
	my $passed = $self->{passed};
	my $score;
	if ($tested == 0)
		{
		$score = "undefined";
		}
	else
		{
		$score = int($passed/$tested*100);
		}

	print $score."% pass rate; of $tested tests run, $passed passed, ".($tested-$passed)." failed.\n";
	}
1;
