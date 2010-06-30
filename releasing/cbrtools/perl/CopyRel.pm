#!perl
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
# 
#
# Description:
# CopyRelease - contains fuctions to copy a release in an archive
#

package CopyRel;

use strict;
use RelData;
use PushPullRel;

BEGIN {
  @CopyRel::ISA=('PushPullRel');
};

sub new {
  my $class = shift;
  my $inidata = shift; 
  my $force = shift;
  my $verbose = shift;
  my $project = shift;

  my $self = bless {}, (ref $class || $class);

  $self->{iniData} = $inidata;
  $self->{force} = $force;
  $self->{verbose} = $verbose;
  $self->{project} = $project;
  $self->{errors} = [];
  
  return $self;
}

sub CopyRelease {
  my $self = shift;
  my $component = shift;
  my $versionToCopy = shift;
  my $version = shift; 
  my $internalVersion = shift;

  my $releaseDir = $self->ObtainReleaseDir($component, $versionToCopy);
  my $releaseCopyDir;
  
  # Obtain the release copy directory
  if(defined $self->{project}){
    $releaseCopyDir = $self->{iniData}->PathData->LocalArchivePathForNewComponent($component, $version, $self->{project});
  }
  else{
    $releaseCopyDir = $releaseDir; 
    $releaseCopyDir =~ s/$versionToCopy$/$version/; 
  }
  
  eval {
    
    # Preform the copying of files
    $self->PerformCopying($component, $versionToCopy, $releaseCopyDir, $releaseDir);
    
    if($versionToCopy !~ /^$version$/i || $versionToCopy !~ /^$internalVersion$/i){
      # Update the reldata so that the release number is correct...
      $self->UpdateRelData($component, $version, $internalVersion);
    }
  };
  
  if ($@) {
    print "$@";
    $self->_AddError($@);
  }
}

sub UpdateRelData {
  my $self = shift;
  my $component = shift;
  my $version = shift;
  my $internalVersion = shift;
  
  my $reldata;
  
  if (!($reldata = RelData->Open($self->{iniData}, $component, $version, 0))) {
    die "ERROR: Couldn't open version '$version' of '$component'";
  }
  
  $reldata->UpdateProject($self->{project});
  $reldata->UpdateInternalVersion("$internalVersion");

  my $env = $reldata->Environment;

  foreach my $thisComp (sort keys %{$env}) {
    
    if($thisComp =~ /$component/i) {
      $env->{$thisComp} = $version;
    }
  }
  
  $reldata->UpdateEnv($env);
}

sub ObtainReleaseDir {
  my $self = shift;
  my $component = shift;
  my $version = shift;
  
  my $releaseDir;
  
  if (!($releaseDir = $self->{iniData}->PathData->LocalArchivePathForExistingComponent($component, $version))) {
    die "ERROR: Couldn't locate component '$component' at version '$version'";
  }

  return $releaseDir;
}

1;

__END__

=head1 NAME

CopyRel.pm - Class for copying a release version.

=head1 DESCRIPTION

Provides an API to create a new release version which is a copy of an another release. This class extends the methods provide by PushPullRel.pm to enable the copying of a release version.

=head1 INTERFACE

=head2 New

Creates a new object of this class. Takes four parameters. 1) An IniData object corresponding
to your local repository. 2) Force (overwrites). 3) Verbose.  4) Project name to uses, which is associated to archive paths as set the reltools.ini.

=head2 CopyRelease

Takes component name, verson to copy, new version and new internal version. Is used to initiate the copying of a release.

=head2 UpdateRelData

Takes component name, version and internal version. Is used to update the reldata of a newly copied release so that the release version information is correct in the reldata file.

=head2 ObtainReleaseDir

Takes component name and version. Is used to get the release dir using the component name and version as input.

=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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

