# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Publishes a prepared release to the archive
# 
#

package CReleaseEnv;
use base qw(CProcessStage);
use strict;

# void CheckOpts()
# Ensures that all required (user) options are set to reasonable values at the
# start of execution
#
# Dies if options invalid
sub CheckOpts()
	{
	my $self = shift;

	$self->CheckOpt('Release archive'); # Ensures option named 'Release archive' was set. Dies if not
	}

# boolean PreCheck()
# Ensures that all required results from previous stages are set to reasonable
# values before this stage is run
#
# Returns false if result options are invalid
sub PreCheck()
	{
	my $self = shift;

	return 1; # Nothing to check here
	}

# boolean Run()
# Performs the body of work for this stage
#
# Returns false if it encounters problems
sub Run()
	{
	my $self = shift;

	my $archive = $self->iOptions()->Get("Release archive");

	my $logger = $self->iOptions();
	
	$logger->Component("CReleaseEnv: makeenv"); # For Scanlog compatibility

	return !$self->_runcmd("makeenv -v --useCachedManifest -w $archive"); # invert return code 0=pass, 1=fail
	}

sub _runcmd {

    my $self = shift;
    my $cmd = shift;
    my $lineproc = shift || sub {};
    my $logger = $self->iOptions();

    $logger->Print("Executing $cmd");
    
    if (!open(OUTPUT, "$cmd 2>&1 |")) {
        $logger->Error("Couldn't execute: $cmd ($!)");
        return -1;
    }

    while (<OUTPUT>) {
	chomp;
	
	$logger->Print($_);
	$lineproc->($_); # call callback with line data
    }

    close(OUTPUT);

    my $exit = $? >> 8;

    if ($exit) {
        $logger->Error("Command completed with nonzero exit code: $exit");
    } else {
        $logger->Print("Command completed successfully");
    }

    return $exit;
}

1;
