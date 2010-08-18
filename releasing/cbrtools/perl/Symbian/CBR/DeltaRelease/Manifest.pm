# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Symbian::CBR::Delta::Manifest.pm
#

package Symbian::CBR::DeltaRelease::Manifest;

use strict;
use XML::Simple;
use Carp;
use POSIX qw(strftime);
use base qw (Exporter);

#
#Constants
#

use constant DELTA_MANIFEST_FILE      => 'delta_manifest_baseline.xml';
use constant META_FILES               => 'metafiles';
use constant ADDED_ZIPS               => 'addedZips';

our @EXPORT_OK = qw(DELTA_MANIFEST_FILE META_FILES ADDED_ZIPS);



#
#Public.
#

sub new {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  return $self;
}

sub Save {
  my $self = shift;
  my $destination = shift;
  mkpath ($destination) unless (-e $destination);
  my $manifestFile = File::Spec->catfile($destination,DELTA_MANIFEST_FILE);
  print "Writing Delta manifest file.\n " ;
  #Hash structure to be provided as input for XML::Simple->XMLout()
  my $manifestHash = {
    version => "1.0.0",
    meta => { 'reference-baseline' => { 'value' => $self->{referenceBaseline} },
              'reference-version' => { 'value' => $self->{referenceVersion} },
              'nominated-baseline' => { 'value' => $self->{nominatedBaseline} },
              'nominated-version' => { 'value' => $self->{nominatedVersion} },
              'created-time' => { 'value' => strftime( '%Y-%m-%dT%H:%M:%S', localtime() ) } }
  };
  my $cgroups = {};
  foreach my $thisComp (sort keys %{$self->{components}}) {
    my $compStatus = $self->{components}{$thisComp}{'status'};
    my $nomVer = $self->{components}{$thisComp}{'nominatedVersion'} if (defined $self->{components}{$thisComp}{'nominatedVersion'});
    my $refVer = $self->{components}{$thisComp}{'referenceVersion'} if (defined $self->{components}{$thisComp}{'referenceVersion'});
    my $zgroups = {};
    my @zGroupArray = ();
    foreach  my $thisZip (sort keys %{$self->{components}{$thisComp}{'zipFiles'}}) {
      my $thisZipFileStatus = $self->{components}{$thisComp}{'zipFiles'}{$thisZip}{'status'};
      if ( !defined $zgroups->{$thisZip} ) {
        $zgroups->{$thisZip} = {file => []};
        if ($thisZip =~ /^exports([A-Z])\.zip$/i) {
          $zgroups->{$thisZip}{'ipr-category'} = $1;
          $zgroups->{$thisZip}{'content-type'} = "exports";
        }
        elsif ($thisZip =~ /^source([A-Z])\.zip$/i) {
          $zgroups->{$thisZip}{'ipr-category'} = $1;
          $zgroups->{$thisZip}{'content-type'} = "source";
        }
        elsif ($thisZip =~ /^binaries\.zip$/i) {
          $zgroups->{$thisZip}{'content-type'} = "binary";
        }
        elsif ($thisZip =~ /^binaries\_([_a-zA-Z0-9]+)\.zip$/i) {
          $zgroups->{$thisZip}{'content-type'} = "binary";
          $zgroups->{$thisZip}{'platform'} = $1;
        }
        $zgroups->{$thisZip}{status} = $thisZipFileStatus;
        push @zGroupArray, $zgroups->{$thisZip};
      }
      foreach my $thisFile (keys %{$self->{components}{$thisComp}{'zipFiles'}{$thisZip}{files}}) {
        my $file = { path => $thisFile };
        $file->{status} = $self->{components}{$thisComp}{'zipFiles'}{$thisZip}{files}{$thisFile}{status};
        $file->{type} = $self->{components}{$thisComp}{'zipFiles'}{$thisZip}{files}{$thisFile}{type};
        push @{$zgroups->{$thisZip}{file}}, $file;
      }
    }
    if ( !defined $cgroups->{$thisComp} ) {
      $cgroups->{$thisComp} = { files => [] };
      $cgroups->{$thisComp}{name} = $thisComp;
      $cgroups->{$thisComp}{status} = $compStatus;
      $cgroups->{$thisComp}{referenceVersion} = $refVer if(defined $refVer);
      $cgroups->{$thisComp}{nominatedVersion} = $nomVer if(defined $nomVer);
      push @{$manifestHash->{component}}, $cgroups->{$thisComp};
    }
    foreach my $zgroup (@zGroupArray) {
      push @{$cgroups->{$thisComp}{files}}, $zgroup;
    }
    foreach my $thisFile (sort keys %{$self->{components}{$thisComp}{metafiles}}) {
      my $file = { path => $thisFile };
      push @{$cgroups->{$thisComp}{metafiles}{file}}, $file;
    }
  }
  #Use the hash structure for calling the XMLout() to write the manifest file
  eval {XMLout(
        $manifestHash,
        xmldecl     => '<?xml version="1.0" ?>',
        rootname    => 'manifest',
        outputfile  => $manifestFile )};
  croak "Error: Can't write manifest file: $@\n" if $@;
}

sub LoadManifest {
  my $self = shift;
  my $manifestFile = shift;
  print "Reading $manifestFile file.\n";

  my $manifest    = eval{XMLin(
                    $manifestFile,
                    forcearray => [ qw(component files file metafiles) ], keyattr => [])
                    };

  croak "Error: Can't read manifest file '$manifestFile': $@\n" if $@;

  # Mapping from xml keyword to our internal data structure keyword
  my %metaFieldMap = ('nominated-baseline' => 'nominatedBaseline',
                      'nominated-version'  => 'nominatedVersion',
                      'reference-baseline' => 'referenceBaseline',
                      'reference-version'  => 'referenceVersion',
                      'created-time'       => 'createdTime');

  foreach my $metaInformation (@{$manifest->{meta}}) {
    $self->{$metaFieldMap{$metaInformation->{name}}} = $metaInformation->{value};
  }
  
  foreach my $component ( @{$manifest->{component} } ) {  
    $self->{components}->{$component->{name}} = {
                referenceVersion => $component->{referenceVersion},
                nominatedVersion => $component->{nominatedVersion},
                status => $component->{status}}; 

    foreach my $zipfile ( @{ $component->{files} } ) {
      my $content = $zipfile->{'content-type'};
      my $category;
      my $platform;
      my $zipFileName ;
      if ($content eq "source" or $content eq "exports") {
        $category = $zipfile->{'ipr-category'};
        $zipFileName = $content.$category.".zip";
      }
      else {
        $platform = $zipfile->{platform};
        if (defined $platform) {
          $zipFileName = "binaries_".$platform.".zip";
        }
        else {
          $zipFileName = "binaries.zip";
        }
      }
      
      $self->{components}->{$component->{name}}->{zipFiles}->{$zipFileName}->{status} = $zipfile->{status};
     
      foreach my $file (@{$zipfile->{file}}) {      
        $self->{components}->{$component->{name}}->{zipFiles}->{$zipFileName}->{files}->{$file->{path}} = {
                                                                                          status => $file->{status},
                                                                                          type => $file->{type}};
      }
    }
    foreach my $metafiles ( @{ $component->{metafiles} } ) {
      foreach my $file (@{$metafiles->{file}}) {
        my $name = $file->{path};
        $self->{components}->{$component->{name}}->{metafiles}->{$name} = 1;
      }
    }
  }
}

sub SetReferenceBaselineComp {
  my $self = shift;
  my $comp = shift;
  $self->{referenceBaseline} = $comp;
}

sub SetReferenceBaselineVer {
  my $self = shift;
  my $version = shift;
  $self->{referenceVersion} = $version;
}

sub SetNominatedBaselineComp {
  my $self = shift;
  my $comp = shift;
  $self->{nominatedBaseline} = $comp;
}

sub SetNominatedBaselineVer {
  my $self = shift;
  my $version = shift;
  $self->{nominatedVersion} = $version;
}

sub SetComponentDetails {
  my $self = shift;
  my $comp = shift;
  my $status = shift;
  my $refVersion = shift;
  my $nomVersion = shift;
  $self->{components}{$comp}{'status'} = $status;
  $self->{components}{$comp}{'referenceVersion'} = $refVersion if(defined $refVersion);
  $self->{components}{$comp}{'nominatedVersion'} = $nomVersion if(defined $nomVersion);
}

sub SetZipfileDetails {
  my $self = shift;
  my $comp = shift;
  my $zipFile = shift;
  my $status = shift;
  $self->{components}{$comp}{zipFiles}{$zipFile}{'status'} = $status;
}

sub SetFileDetails {
  my $self = shift;
  my $comp = shift;
  my $zipFile = shift;
  my $file = shift;
  my $status = shift;
  my $type = shift;
  $self->{components}{$comp}{zipFiles}{$zipFile}{files}{$file}{status} = $status;
  $self->{components}{$comp}{zipFiles}{$zipFile}{files}{$file}{type} = $type;
}

sub RecordMetaFile {
  my $self = shift;
  my $comp = shift;
  my $file = shift;
  $self->{components}{$comp}{metafiles}{$file} = 1;
}

sub GetReferenceBaselineComp {
  my $self = shift;
  return $self->{referenceBaseline} ;
}

sub GetReferenceBaselineVer {
  my $self = shift;
  return $self->{referenceVersion};
}

sub GetNominatedBaselineComp {
  my $self = shift;
  return $self->{nominatedBaseline};
}

sub GetNominatedBaselineVer {
  my $self = shift;
  return $self->{nominatedVersion};
}

sub ListAllComponents {
  my $self = shift;
  return $self->{components};
}

sub GetCompStatus {
  my $self = shift;
  my $comp = shift;
  return $self->{components}{$comp}{'status'};
}

sub GetCompReferenceVer {
  my $self = shift;
  my $comp = shift;
  return $self->{components}{$comp}{'referenceVersion'};
}

sub GetCompNominatedVer {
  my $self = shift;
  my $comp = shift;
  return $self->{components}{$comp}{'nominatedVersion'};
}


sub GetZipFilesForComp {
  my $self = shift;
  my $comp = shift;
  return ($self->{components}{$comp}{zipFiles} || {});
}

sub GetZipStatus {
  my $self = shift;
  my $comp = shift;
  my $zipFile = shift;
  return $self->{components}{$comp}{zipFiles}{$zipFile}{'status'};
}

sub GetFilesForZip {
  my $self = shift;
  my $comp = shift;
  my $zipFile = shift;
  return ($self->{components}{$comp}{zipFiles}{$zipFile}{files} || {});
}

sub GetFileStatus {
  my $self = shift;
  my $comp = shift;
  my $zipFile = shift;
  my $file  = shift;
  $self->{components}{$comp}{zipFiles}{$zipFile}{files}{$file}{status};
}

sub GetFileType {
  my $self = shift;
  my $comp = shift;
  my $zipFile = shift;
  my $file  = shift;
  return $self->{components}{$comp}{zipFiles}{$zipFile}{files}{$file}{type};
}

sub GetMetaFiles {
  my $self = shift;
  my $comp = shift;
  return ($self->{components}{$comp}{metafiles} || {});
}

1;

__END__

=head1 NAME

Symbian::CBR::DeltaRelease::Manifest.pm - Provides an interface to data associated with a deltas created from reference version to the nominated version.

=head2 new

Creates a new Symbian::CBR::Delta::Manifest object.

=head2 Save

Expects to be passed a destination path. Creates destination path if destination path is not existing, and save the hash structure to xml file.

=head2 LoadManifest

Expects to be passed a manifest file name. Reads delta manifest file and converts into a hash structure.

=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
