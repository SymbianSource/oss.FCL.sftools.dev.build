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
# 
#

package Symbian::DistributionPolicy::Reader;
use strict;

use File::Basename;
use Symbian::DistributionPolicy;

our $cache = {}; # Persistent (private) cache

sub new {
    return bless {};
}

# public.

sub ReadPolicyFile {
    my $self = shift;
    my $path = shift;
    my $dir  = -d $path ? $path : dirname($path);
    # look in cache first, retrieve if not already defined
    return $cache->{$dir} ||= $self->readfile($dir.'\\DISTRIBUTION.POLICY');
}

# private.

sub readfile {
    my $self = shift;
    my $file = shift;
    my $hasCategory;
    my $policy = Symbian::DistributionPolicy->new();
    # default policy applies when the file does not exist
    return $policy if !-e $file;
    # attempt to open the policy file
    open(POLICY, $file) or die "Couldn't open $file: $!\n";
    # read policy data
    while (<POLICY>) {
        s/(?<!\\)#.*$//;  # ignore comments
        s/^\s+|\s+$//g;   # trim whitespace
        next unless /\S/; # skip blank line
        # parse line
        if (/^authori[sz]ed\s+(.+?)(?:\s+until\s+(.+?))?$/i) {
            # licensee specific authorisation
            if (!$policy->SetAuthorizedUntil($1, $2)) {
                warn "Invalid Authorized directive in $file\n";
            }
        } elsif (/^category\s+([a-z])$/i) {
            # ipr category
            if (!$policy->SetCategory($1)) {
                warn "Invalid Category directive in $file\n";
            }
            $hasCategory = 1;
        } elsif (/^description\s+(.*)$/i) {
            # free text description
            $policy->SetDescription($1);
        } elsif (/^expires\s+(.*)$/i) {
            # best before date
            if (!$policy->SetExpires($1)) {
                warn "Invalid Expires directive in $file\n";
            }
        } elsif (/^export\s+(un)?restricted$/i) {
            # exportable/embargoed?
            $policy->SetExportRestricted(!defined($1));
        } elsif (/^osd:\s*(.+?)$/i) {
            # parse osd info
            $self->handle_osd($1, $policy);
        }
    }
    close(POLICY);
    
    if (!$hasCategory) {
        warn "Warning: \'$file\' does not contain an IPR category\n";
    }
    
    return $policy;
}

sub handle_osd {
    my $self = shift;
    local $_ = shift;
    my $policy = shift;
    # SGL.PPS246.201DistributionPolicyFileContents.doc
    if (/^(common|optional)\s+(symbian|replaceable)\s+(.+)$/i) {
        # set common/optional
        if (lc($1) eq 'common') {
            $policy->SetCommon(1);
        } else {
            $policy->SetOptional(1);
        }
        # set symbian/replaceable
        if (lc($2) eq 'symbian') {
            $policy->SetSymbian(1);
        } else {
            $policy->SetReplaceable(1);
        }
    } elsif (/^(?:reference\/test)\s+(.+)$/i) {
        # set test
        $policy->SetTest(1);
    } elsif (/^(?:test\/reference)\s+(.+)$/i) {
        # synonym for reference/test
        $policy->SetTest(1);
    } else {
        warn "Invalid OSD directive: '$_' (see SGL.PPS246.201)\n";
    }
}

1;

=pod

=head1 NAME

Symbian::DistributionPolicy::Reader - Caching DISTRIBUTION.POLICY file reader.

=head1 SYNOPSIS

 use Symbian::DistributionPolicy::Reader;

 my $dpr = Symbian::DistributionPolicy::Reader->new();

 my $policy = $dpr->ReadPolicyFile($path);

=head1 DESCRIPTION

This module parses and caches policy data from DISTRIBUTION.POLICY files.

=head1 METHODS

=head2 new()

Creates the reader object.

=head2 ReadPolicyFile($path)

Read the DISTRIBUTION.POLICY file in $path (which can be e.g. a source file, a
directory or the DISTRIBUTION.POLICY file itself) and return a
Symbian::DistributionPolicy object containing the policy data. The policy is
cached to prevent unnecessary re-reading of .POLICY files in subsequent calls.

=head1 SEE ALSO

L<Symbian::DistributionPolicy> to find out what you can do with your $policy
object.

=head1 COPYRIGHT

 Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
 All rights reserved.
 This component and the accompanying materials are made available
 under the terms of the License "Eclipse Public License v1.0"
 which accompanies this distribution, and is available
 at the URL "http://www.eclipse.org/legal/epl-v10.html".
 
 Initial Contributors:
 Nokia Corporation - initial contribution.
 
 Contributors:
 
 Description:
 

=cut
