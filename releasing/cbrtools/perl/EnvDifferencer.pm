# Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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

package EnvDifferencer;

use strict;
use RelData;

sub New {
  my $class = shift;
  my $self = bless {}, (ref $class || $class);
  $self->{iniData} = shift;
  $self->{verbose} = shift;
  $self->{startcomp} = undef;
  $self->{endcomp} = undef;
  $self->{startver} = undef;
  $self->{endver} = undef;
  $self->{reldatacache} = {}; # keyed by concatenated of comp and ver
  $self->{results} = undef;
  if ($self->{verbose}) {
    require Data::Dumper ;
    Data::Dumper->import();
  }
  return $self;
}

sub SetStartCompVer {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  $self->Reset();
  $self->{startcomp} = $comp;
  $self->{startver} = $ver;
}

sub SetEndCompVer {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  $self->Reset();
  $self->{endcomp} = $comp;
  $self->{endver} = $ver;
}

sub Reset {
  my $self = shift;
  $self->{results} = undef;
}

# Accessor methods

sub StartEnvReldata {
  my $self = shift;
  die "Start component not defined" unless $self->{startcomp};
  die "Start version not defined" unless $self->{startver};
  return $self->RelData($self->{startcomp}, $self->{startver});
}

sub EndEnvReldata {
  my $self = shift;
  die "End component not defined" unless $self->{endcomp};
  die "End version not defined" unless $self->{endver};
  return $self->RelData($self->{endcomp}, $self->{endver});
}

sub StartReldata {
  my $self = shift;
  my $comp = shift;
  return $self->RelData($comp, $self->StartVersion($comp));
}

sub EndReldata {
  my $self = shift;
  my $comp = shift;
  return $self->RelData($comp, $self->EndVersion($comp));
}

sub StartVersion {
  my $self = shift;
  my $comp = shift;
  return $self->GetStartEnv()->{$comp};
}

sub EndVersion {
  my $self = shift;
  my $comp = shift;
  return $self->GetEndEnv()->{$comp};
}

sub ChangedComps {
  my $self = shift;
  $self->DoDiff;
  return $self->{results}->{diff}->{changed};
}

sub NewerComps {
  my $self = shift;
  $self->CompareDiffDates;
  return $self->{results}->{diffdates}->{newer};
}

sub OlderComps {
  my $self = shift;
  $self->CompareDiffDates;
  return $self->{results}->{diffdates}->{older};
}

sub UnchangedComps {
  my $self = shift;
  $self->DoDiff;
  return $self->{results}->{diff}->{same};
}

sub OnlyStart {
  my $self = shift;
  $self->DoDiff;
  return $self->{results}->{diff}->{onlystart};
}

sub OnlyEnd {
  my $self = shift;
  $self->DoDiff;
  return $self->{results}->{diff}->{onlyend};
}

sub IntermediateReldatas {
  my $self = shift;
  my $comp = shift;
  my $relDataObjects = RelData->OpenSet($self->{iniData}, $comp, $self->{verbose});

  my $startdate = $self->StartReldata($comp)->ReleaseTime();
  my $enddate = $self->EndReldata($comp)->ReleaseTime();

  # Specifically exclude the start and end reldatas... i.e use < > not <= >=
  my @results = grep { $_->ReleaseTime() < $enddate and $_->ReleaseTime() > $startdate } @$relDataObjects;
  return \@results;
}

sub GetStartEnv {
  my $self = shift;
  unless ($self->{results}->{startenv}) {
    if ($self->{startcomp}) {
      $self->{results}->{startenv} = $self->StartEnvReldata()->Environment();
    } else {
      $self->{results}->{startenv} = $self->CurrentEnv;
    }
  }
  return $self->{results}->{startenv};
}

sub GetEndEnv {
  my $self = shift;
  unless ($self->{results}->{endenv}) {
    if ($self->{endcomp}) {
      $self->{results}->{endenv} = $self->EndEnvReldata()->Environment();
    } else {
      $self->{results}->{endenv} = $self->CurrentEnv;
    }
  }
  return $self->{results}->{endenv};
}

### Private

sub CurrentEnv {
  my $self = shift;
  my $envDb = EnvDb->Open($self->{iniData}, $self->{verbose});
  return $envDb->VersionInfo();
}

sub DoDiff {
  my $self = shift;

  return if $self->{results}->{diff};

  die "Neither environment was specified.\n" unless ($self->{startcomp} || $self->{endcomp});

  my %env1 = %{$self->GetStartEnv()};
  my %env2 = %{$self->GetEndEnv()};
  # Deliberately make copies, as we will be deleting stuff from them
  
  if ($self->{verbose}>1) {
    print "Start environment is ".Dumper(\%env1)."\n";
    print "End environment is ".Dumper(\%env2)."\n";
  }

  my @changed;
  my @onlynew;
  my @onlyold;
  my @same;

  # Compare $env1 against $env2 first.
  foreach my $thisComp (keys %env1) {
    my $ver1 = $env1{$thisComp};
    my $ver2 = $env2{$thisComp};
    if (not defined $ver2) {
      push @onlyold, $thisComp;
    }
    elsif (lc($ver1) eq lc($ver2)) {
      push @same, $thisComp;
    }
    else {
      push @changed, $thisComp;
    }

    if (defined $ver2) {
      # Remove this component from $env2 because it has been accounted for.
      # Components left over in the $env2 hash are those not present in $env1.
      delete $env2{$thisComp};
    }
  }

  # List the components in $env2 but not in $env1.
  @onlynew = keys %env2;

  $self->{results}->{diff} = {
    same => \@same,
    onlyend => \@onlynew,
    onlystart => \@onlyold,
    changed => \@changed
  };

  print "At end of main comparison... with results ".Dumper($self->{results}->{diff})."\n" if $self->{verbose}>1;
}

sub CompareDiffDates {
  my $self = shift;
  return if $self->{results}->{diffdates};
  $self->DoDiff; # returns if already completed

  my @older;
  my @newer;
  foreach my $thisComp (@{$self->{results}->{diff}->{changed}}) {
    my $relData1 = $self->StartReldata($thisComp);
    my $relData2 = $self->EndReldata($thisComp);
    if ($relData1->ReleaseTime() <= $relData2->ReleaseTime()) {
      push @newer, $thisComp;
    } else {
      push @older, $thisComp;
    }
  }

  $self->{results}->{diffdates} = {
    older => \@older,
    newer => \@newer
  };
  print "At end of date comparison... with results ".Dumper($self->{results}->{diffdates})."\n" if $self->{verbose}>1;
}

sub RelData {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  print "Asked for reldata for $comp $ver\n" if $self->{verbose}>2;

  die "Can't get reldata for undefined comp" unless $comp;
  die "Can't get reldata for undefined version of $comp" unless $ver;

  my $key = "$comp$ver";
  unless ($self->{reldatacache}->{$key}) {
    $self->{reldatacache}->{$key} = RelData->Open
      ($self->{iniData}, $comp, $ver, $self->{verbose});
  }
  return $self->{reldatacache}->{$key};
}

1;

__END__

=head1 NAME

EnvDifferencer.pm - A class to find differences between two environments.

=head1 DESCRIPTION

This class is used by C<DiffEnv> and C<ViewNotes> to examine the differences between two environments. To use it, first create an object, then use the C<SetStartCompVer> and C<SetEndCompVer> methods to set the component name and version that you wish to compare. You can then use any of the other methods to access information about the differences between them.

=head1 INTERFACE

=head2 Necessary calls

=head3 New

Expects to be passed two arguments; firstly, an C<IniData> object, and secondly, a verbosity level.

=head3 SetStartCompVer

=head3 SetEndCompVer

These two methods are each passed a component name a version number. These two environments are used for differencing. Note that no differencing is actually performed until information is requested by one of the accessor methods. These methods also call C<Reset>, which means that all results are deleted and a new diff will be performed whenever information is requested.

If one of these is not called before the comparison, then the current environment (as returned by a C<EnvDb> object) will be used for the missing environment.

=head3 Reset

This method should never be needed. It resets the object so that it performs a new diff the next time some information is requested.

=head2 Accessor Methods

Any of these may trigger a differencing to happen.

=head3 StartReldata

=head3 EndReldata

Takes a component name. Returns a C<RelData> object corresponding to that component in the start or the end environment.

=head3 StartVersion

=head3 EndVersion

Given a component name, returns the version number of that component in the start or the end environment. The behaviour is undefined if that component doesn't exist in the given environment.

=head3 GetStartEnv

=head3 GetEndEnv

Returns a hashref of the components and version numbers in each environment.

=head3 StartEnvReldata

=head3 EndEnvReldata

Returns the C<RelData> object corresponding to the environment itself.

=head3 ChangedComps

Returns a list of component names in both environments, but with different version numbers.

=head3 UnchangedComps

Returns a similar list of those components which are identical in both environments.

=head3 OnlyStart

=head3 OnlyEnd

Return lists of those components only in one or other environment.

=head3 NewerComps

=head3 OlderComps

These two methods trigger some additional differencing, which compares the dates of each changed component. They then return a list of those components which are newer, or older, in the end environment.

=head3 IntermediateReldatas

Given a component name, this returns a list of C<RelData> objects belonging to releases of that component made between the start and end release. It specifically does not include the start or end release.

=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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
