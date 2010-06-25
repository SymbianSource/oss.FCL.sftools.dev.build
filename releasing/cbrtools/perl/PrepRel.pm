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

package PrepRel;

use strict;
use IniData;
use MrpData;
use Utils;


#
# Public.
#

sub PrepRel {
  my $iniData = shift;
  my $envDb = shift;
  my $comp = shift;
  my $ver = shift;
  my $intVer = shift;
  my $mrpName = shift;

  $envDb->CheckCompName($comp);
  die "Error: $ver is not a valid version number\n" if (defined $ver && !$ver);
  die "Error: $intVer is not a valid internal version number\n" 
    if (defined $intVer && !$intVer);

  if (not defined $ver and not defined $intVer and not defined $mrpName) {
    RemoveDbEntry($envDb, $comp);
    return;
  }

  my $updating = 0;
  if (not defined $ver) {
    $ver = $envDb->Version($comp);
    if (not defined $ver) {
      die "Error: $comp not installed; could not work out what version to use. Please specify a version number.\n";
    }
    elsif ($envDb->Status($comp) != EnvDb::STATUS_PENDING_RELEASE) {
      die "Error: New version not specified\n";
    }
    else {
      $updating = 1;
    }
  }
  else {
    my $currentVer = $envDb->Version($comp);
    if (defined $currentVer) {
      if (lc($ver) eq $currentVer) {
	$updating = 1;
      }
    }
    my $relDir = $iniData->PathData->LocalArchivePathForExistingOrNewComponent($comp,$ver);
    if (-e $relDir) {
      die "Error: $comp $ver already exists\n";
    }
  }

  if (not defined $intVer and $iniData->RequireInternalVersions() and not $updating) {
    die "Error: Internal version number not specified for $comp $ver\n";
  }

  if (defined $mrpName) {
    Utils::CheckExists($mrpName);
    Utils::AbsoluteFileName(\$mrpName);
    
    if($iniData->HasMappings()) {
      $mrpName = $iniData->PerformReverseMapOnFileName($mrpName);
    }
    
    $mrpName = Utils::RemoveSourceRoot($mrpName);
  }
  else {
    my $currentVersion = $envDb->Version($comp);
    unless (defined $currentVersion) {
      die "Error: Mrp name not specified for $comp $ver\n";
    }
  }

  $envDb->SetVersion($comp, $ver);
  $envDb->SetStatus($comp, EnvDb::STATUS_PENDING_RELEASE);
  if (defined $mrpName) {
    $envDb->SetMrpName($comp, $mrpName);
  }
  if (defined $intVer) {
    $envDb->SetInternalVersion($comp, $intVer);
  }
  $envDb->GenerateEmptySignature($comp, $ver);
}


#
# Private.
#

sub RemoveDbEntry {
  my $envDb = shift;
  my $comp = shift;
  my $ver = $envDb->Version($comp);
  if (defined $ver) {
    print "Remove environment database entry for $comp? [y/n] ";
    my $response = <STDIN>;
    chomp $response;
    if ($response =~ /^y$/i) {
      $envDb->DeleteSignature($comp, $ver);
      $envDb->SetVersion($comp, undef);
    }
    else {
      die "Remove aborted\n";
    }
  }
  else {
    die "Error: $comp not installed\n";
  }
}


1;

=head1 NAME

PrepRel.pm - Provides an interface to edit the environment database to prepare a component for release.

=head1 WARNING!

This is NOT the documentation for the command C<PrepRel>. This documentation refers to the internal release tools module called F<PrepRel.pm>. 

For the PrepRel command documentation, you'll need to explicitly specify the path to the C<PrepRel> command,

=head1 INTERFACE

=head2 PrepRel

Expects to be passed an C<IniData> reference, an C<EnvDb> reference, a component name. May optionally be passed in addition a version, an internal version and an F<mrp> file name. If no version parameter is specified, the component's database entry is removed. Otherwise the component's database entry is updates with the information provided, and its status set to C<STATUS_PENDING_RELEASE>.

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
