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

package Symbian::DistributionPolicy;
use strict;

use POSIX qw(mktime);

# create OSD bit vector constants for $obj->{osd}
use constant SYMBIAN_DPOL_COMMON      => 0x0001;
use constant SYMBIAN_DPOL_OPTIONAL    => 0x0002;
use constant SYMBIAN_DPOL_SYMBIAN     => 0x0004;
use constant SYMBIAN_DPOL_REPLACEABLE => 0x0008;
use constant SYMBIAN_DPOL_TEST        => 0x0010;

sub new {
    my $class = shift;
    my $self = {
        authorized        => {},
        category          => undef,
        description       => '',
        expires           => undef,
        export_restricted => undef,
        osd               => 0,
    };
    bless $self, $class;
    return $self;
}

# public.

sub Authorized {
    my $self = shift;
    my $licensee = shift;
    my $time = @_ ? shift : time; # use current time if not specified
    # absent = fail
    return if !exists $self->{authorized}{$licensee};
    # present without expiry = pass
    return 1 if !defined $self->{authorized}{$licensee};
    # check expiry
    return $self->{authorized}{$licensee} > $time;
}

sub SetAuthorizedUntil {
    my $self = shift;
    my $licensee = shift;
    my $until = shift;
    return if !defined $licensee;
    $self->{authorized}{$licensee} = $self->parsedate($until);
    # success depends on whether a date was passed and parsed successfully
    return defined $until ? defined $self->{authorized}{$licensee} : 1;
}

sub Category {
    return $_[0]->{category};
}

sub SetCategory {
    my $self = shift;
    my $cat = uc(shift); # uppercase
    return if !defined $cat;
    if ($cat !~ /^[A-Z]$/) {
        warn "Invalid IPR category: '$cat'\n";
        return;
    }
    $self->{category} = $cat;
    return 1;
}

sub Common {
    return $_[0]->{osd} & SYMBIAN_DPOL_COMMON;
}

sub SetCommon {
    my $self = shift;
    my $bool = shift;
    return $self->SetOptional(1) if !$bool;
    $self->{osd} |= SYMBIAN_DPOL_COMMON;
    $self->{osd} &= ~SYMBIAN_DPOL_OPTIONAL; # toggles optional off
    return 1;
}

sub Description {
    return $_[0]->{description};
}

sub SetDescription {
    my $self = shift;
    my $desc = shift;
    $self->{description} = defined $desc ? $desc : '';
    return 1;
}

sub Expires {
    return $_[0]->{expires};
}

sub SetExpires {
    my $self = shift;
    my $date = shift;
    return if !defined $date;
    $self->{expires} = $self->parsedate($date);
    # if parsedate failed it returned undef so that is our status
    return defined $self->{expires};
}

sub Expired {
    my $self = shift;
    my $time = @_ ? shift : time;
    # not defined = no expiry
    return if !defined $self->{expires};
    # check expiry
    return $self->{expires} < $time;
}

sub ExportRestricted {
    my $self = shift;
    
    # If the category is defined then we know a distribution policy file has been parsed.
    if ($self->{category}) {
        # double ! reduces the value to a boolean
        return !!$self->{export_restricted};
    }
    return undef;
}

sub SetExportRestricted {
    my $self = shift;
    my $flag = shift;
    $self->{export_restricted} = $flag;
    return 1;
}

sub Optional {
    return $_[0]->{osd} & SYMBIAN_DPOL_OPTIONAL;
}

sub SetOptional {
    my $self = shift;
    my $bool = shift;
    return $self->SetCommon(1) if !$bool;
    $self->{osd} |= SYMBIAN_DPOL_OPTIONAL;
    $self->{osd} &= ~SYMBIAN_DPOL_COMMON; # toggles common off
    return 1;
}

sub Replaceable {
    return $_[0]->{osd} & SYMBIAN_DPOL_REPLACEABLE;
}

sub SetReplaceable {
    my $self = shift;
    my $bool = shift;
    return $self->SetSymbian(1) if !$bool;
    $self->{osd} |= SYMBIAN_DPOL_REPLACEABLE;
    $self->{osd} &= ~SYMBIAN_DPOL_SYMBIAN; # toggles symbian off
    return 1;
}

sub Symbian {
    return $_[0]->{osd} & SYMBIAN_DPOL_SYMBIAN;
}

sub SetSymbian {
    my $self = shift;
    my $bool = shift;
    return $self->SetReplaceable(1) if !$bool;
    $self->{osd} |= SYMBIAN_DPOL_SYMBIAN;
    $self->{osd} &= ~SYMBIAN_DPOL_REPLACEABLE; # toggles replaceable off
    return 1;
}

sub Test {
    return $_[0]->{osd} & SYMBIAN_DPOL_TEST;
}

sub SetTest {
    my $self = shift;
    my $bool = shift;
    if ($bool) {
        $self->{osd} |= SYMBIAN_DPOL_TEST; # on
    } else {
        $self->{osd} &= ~SYMBIAN_DPOL_TEST; # off
    }
    return 1;
}

# private.

sub parsedate {
    my $self = shift;
    my $date = shift; # dd/mm/yyyy
    return unless defined $date;
    if ($date !~ m!^(\d\d)/(\d\d)/(\d{4})$!) {
        warn "Invalid date: '$date'\n";
        return;
    }
    my($d, $m, $y) = ($1, $2, $3);
    my $time = mktime(59, 59, 23, $d, --$m, $y-1900);
    if (!defined $time) {
        warn "Date out of range: '$date'\n";
        return;
    }
    return $time;
}

1;

=pod

=head1 NAME

Symbian::DistributionPolicy - OO representation of a DISTRIBUTION.POLICY file.

=head1 SYNOPSIS

 # normally you would not create a policy object directly but
 # use one returned by the Symbian::DistributionPolicy::Reader...

 use Symbian::DistributionPolicy::Reader;

 my $dpr = Symbian::DistributionPolicy::Reader->new();

 my $policy = $dpr->ReadPolicyFile($path);

 # then you may query the object using the methods below

=head1 DESCRIPTION

This module provides an object to represent the data in a DISTRIBUTION.POLICY
file. The DISTRIBUTION.POLICY file specifies the policy information for all the
source code files in the same directory. The directives are:

=head2 Authorized LICENSEE_ID [until DATE]

The C<Authorized> directive overrides any IPR restriction and makes available
the source to the licensee with a specific I<LICENSEE_ID>. If the C<until>
keyword is used then I<DATE> should be a string in the format dd/mm/yyyy. The
exception made by this directive will expire at the end of this date. Only
one C<Authorized> directive is allowed per I<LICENSEE_ID>.

=head2 Category IPR_CATEGORY

The C<Category> directive specifies the IPR category of the source.
I<IPR_CATEGORY> may be any single character from the range A to Z. The default for
unclassified source is X.

=head2 Description TEXT

The C<Description> directive specifies a one-line textual description of the
directory content. I<TEXT> need not be quoted (in fact, it should not be).

=head2 Expires DATE

The C<Expires> directive specifies the date after which the directive(s) in the
DISTRIBUTION.POLICY file become invalid. I<DATE> must be in dd/mm/yyyy format.

=head2 Export STATUS

The C<Export> keyword specifies whether the source is export restricted or not.
The default is that it is not and this is equivalent to setting I<STATUS> to
Unrestricted. Changing I<STATUS> to Restricted will enable this feature.

=head2 OSD: ((COMMON|OPTIONAL) (SYMBIAN|REPLACEABLE)|REFERENCE/TEST) [NAME]

The OSD line describes the nature of the source in five metrics: (COMMON vs.
OPTIONAL and SYMBIAN vs. REPLACEABLE) or REFERENCE/TEST. The descriptions of
these are available in Schedule 2 of the CKL.

=head1 METHODS

In addition to the constructor, getters and setters are provided for all policy
directives:

=begin text

    +--------------+-------------------+----------------------+
    | Directive    | Getter            | Setter               |
    +--------------+-------------------+----------------------+
    | Authorized   | Authorized        | SetAuthorizedUntil   |
    | Category     | Category          | SetCategory          |
    | Description  | Description       | SetDescription       |
    | Expires      | Expires           | SetExpires           |
    | Export       | ExportRestricted  | SetExportRestricted  |
    | OSD          | See table below for individual methods.  |
    +--------------+-------------------+----------------------+

=end

Individual OSD metrics getters and setters are detailed in the following table:

=begin text

    +-----------------+--------------+-----------------+
    | Metric          | Getter       | Setter          |
    +-----------------+--------------+-----------------+
    | COMMON          | Common       | SetCommon       |
    | OPTIONAL        | Optional     | SetOptional     |
    | REPLACEABLE     | Replaceable  | SetReplaceable  |
    | SYMBIAN         | Symbian      | SetSymbian      |
    | REFERENCE/TEST  | Test         | SetTest         |
    +-----------------+--------------+-----------------+

=end

=head2 new()

Creates the policy object with default settings (cat=X, desc='', expires=never,
export=unrestricted).

=head2 Authorized($licensee_id[, $time])

Returns the authorized status as a boolean (1=authorized, undef=not) for a
given $licensee_id. If a $time is not specified the current time will be used.
This is required if the C<Authorized> directive makes use of the I<until>
keyword and the expiry time needs to be checked.

=head2 SetAuthorizedUntil($licensee_id[, $date])

Adds an authorized licensee to the policy. If an expiry date is specified it
must be in dd/mm/yyyy format.

=head2 Category()

Returns the IPR category as a single-character string. If no IPR category exists
in the distrubution file then 'undef' will be returned.

=head2 SetCategory($cat)

Sets the category. Will accept any single character from the range A to Z as a
string in $cat.

=head2 Common()

Returns non-zero if the OSD metric COMMON is set.

=head2 SetCommon($bool)

Sets the OSD metric COMMON if $bool is true. Unsets it if $bool is false. Also
sets the mutually exclusive OPTIONAL to the opposite.

=head2 Description()

Returns the description text (never undef - if blank you get an empty string).

=head2 SetDescription($text)

Sets the description text.

=head2 Expires()

Returns the expiry time specified in the file (or undef if not specified). It
will be in UNIX (epoch) time format for your convenience. See Expired().

=head2 SetExpires($date)

Sets the expiry time to 23:59:59 on the date provided. $date should be a string
in dd/mm/yyyy format.

=head2 Expired([$time])

Will test whether the policy data has (or will have) expired at the time
specified. If no time is specified, the current time will be used - i.e. to
determine whether the policy has already expired.

=head2 ExportRestricted()

Returns the export restricted status as a boolean (1=restricted,
0=unrestricted, undef=information not available).

=head2 SetExportRestricted($flag)

Sets the export restricted status. $flag is a boolean (undef is allowed for
false).

=head2 Optional()

Returns non-zero if the OSD metric OPTIONAL is set.

=head2 SetOptional($bool)

Sets the OSD metric OPTIONAL if $bool is true. Unsets it if $bool is false. Also
sets the mutually exclusive COMMON to the opposite.

=head2 Replaceable()

Returns non-zero if the OSD metric REPLACEABLE is set.

=head2 SetReplaceable($bool)

Sets the OSD metric REPLACEABLE if $bool is true. Unsets it if $bool is false.
Also sets the mutually exclusive SYMBIAN to the opposite.

=head2 Symbian()

Returns non-zero if the OSD metric SYMBIAN is set.

=head2 SetSymbian($bool)

Sets the OSD metric SYMBIAN if $bool is true. Unsets it if $bool is false. Also
sets the mutually exclusive REPLACEABLE to the opposite.

=head2 Test()

Returns non-zero if the OSD metric REFERENCE/TEST is set.

=head2 SetTest($bool)

Sets the OSD metric REFERENCE/TEST if $bool is true. Unsets it if $bool is
false.

=head1 SEE ALSO

L<Symbian::DistributionPolicy::Reader> to see how to get your $policy object(s).

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
