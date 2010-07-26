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

package MakeRel;

use strict;
use File::Path;
use File::Spec;
use File::Basename;
use IniData;
use EnvDb;
use MrpData;
use RelData;
use CatData;
use Utils;
use Symbian::CBR::Component::Manifest;
use Cwd;

#
# Public.
#

sub MakeReleases {
  my $self;
  $self->{iniData} = shift;
  $self->{envDb} = shift;
  $self->{mrpData} = shift;
  $self->{notesSrc} = shift;
  $self->{toolName} = shift;
  $self->{verbose} = shift;
  $self->{project} = shift;
  $self->{useCachedManifest} = shift;

  bless $self, "MakeRel";

  if (scalar(@{$self->{mrpData}}) == 0) { # Abort if there's nothing to do.
    return;
  }
  if (!$self->CheckArchive()) { # Abort if any of the releases already exist
    return;
  }

  my $versionInfo = $self->VersionInfo();
  eval {
    $self->GenerateReleaseFiles($versionInfo);
  };
  if ($@) {
    print $@;

    if($self->{toolName} =~ /MakeEnv/i){
      print "\nError: Unable to create environment successfully, archive might be corrupted.\n";
    }
    else{
      print "\nError: Unable to create component release successfully, archive might be corrupted.\n";
    }

    $self->Cleanup();
    return;
  }

  # Now that we know all releases have been successfully made, update the environment database.
  foreach my $thisMrpData (@{$self->{mrpData}}) {
    my $comp = $thisMrpData->Component();
    my $ver = $thisMrpData->ExternalVersion();
    $self->{envDb}->SetVersion($comp, $ver);
    $self->{envDb}->GenerateSignature($comp, $ver);
    $self->{envDb}->SetMrpName($comp, $thisMrpData->MrpName());
    $self->{envDb}->SetStatus($comp, EnvDb::STATUS_CLEAN);
  }
}


#
# Private.
#

sub VersionInfo {
  my $self = shift;

  # Get a copy of the current version information from the environment database and update it with the new versions.
  my $versionInfo = $self->{envDb}->VersionInfo();
  foreach my $thisMrpData (@{$self->{mrpData}}) {
    $versionInfo->{lc($thisMrpData->Component())} = $thisMrpData->ExternalVersion();
  }

  return $versionInfo;
}

sub CheckArchive {
  my $self = shift;
  my $good = 1;
  foreach my $thisMrpData (@{$self->{mrpData}}) {
    if (!$self->CheckDirs($thisMrpData)) {
      $good = 0; # Continue and check the rest
    }
  }
  return $good;
}

sub GenerateReleaseFiles {
  my $self = shift;
  my $versionInfo = shift;
  my $numMrps = scalar(@{$self->{mrpData}});
  foreach my $thisMrpData (@{$self->{mrpData}}) {
    $self->MakeDirs($thisMrpData);
    $self->ZipSource($thisMrpData);
    $self->ZipBinaries($thisMrpData);
    $self->ZipExports($thisMrpData);
    $self->WriteRelData($thisMrpData, $versionInfo);
    $self->WriteManifest($thisMrpData);

    # This line must come after the others, because with a project-based archive path configuration it relies on
    # LocalArchivePathForNewOrExistingComponent finding the directories created above.
    my $comp = $thisMrpData->Component();
    my $extVer = $thisMrpData->ExternalVersion();
    my $intVer = $thisMrpData->InternalVersion();
    unless (defined $intVer) {
      $intVer = '';
    }
    my $relDir = $self->LocalArchivePath($thisMrpData);
    Utils::SetFileReadOnly($relDir);
    print "Made $comp $extVer $intVer\n";
  }
}

sub ComponentDir {
  require Carp;
  confess("Obsolete method called");
}

sub ReleaseDir {
  require Carp;
  confess("Obsolete method called");
}

sub CheckDirs {
  my $self = shift;
  my $mrpData = shift;
  my $relDir = $self->LocalArchivePath($mrpData);
  if (-e $relDir) {
    print STDERR "Error: $relDir already exists\n";
    return 0;
  }
  return 1;
}

sub MakeDirs {
  my $self = shift;
  my $mrpData = shift;
  my $relDir = $self->LocalArchivePath($mrpData);
  unless (-e $relDir) {
    Utils::MakeDir($relDir);
  }
}

sub ZipSource {
  my $self = shift;
  my $mrpData = shift;
  my @categories = @{$mrpData->SourceCategories()};
  my $zipName;

  foreach my $category (@categories) {
    my @sourceFiles = @{$mrpData->Source($category)};
    if (@sourceFiles) {
      $zipName = $self->LocalArchivePath($mrpData) . "\\source".uc($category).".zip";

      Utils::ZipSourceList($zipName, \@sourceFiles, $self->{verbose}, Utils::SourceRoot(), $self->{iniData});

      Utils::SetFileReadOnly($zipName);
    }
  }
  if ($self->{verbose} > 1 and not defined $zipName) {
    print "No source for " . $mrpData->Component() . "\n";
  }
}

sub ZipBinaries {
  my $self = shift;
  my $mrpData = shift;
  foreach my $thisBinCat (@{$mrpData->BinaryCategories()}) {
    my $bins = $mrpData->Binaries($thisBinCat);
    if ($bins and scalar(@$bins) > 0) {
      my $zipName;
      if ($thisBinCat eq 'unclassified') {
        $zipName = $self->LocalArchivePath($mrpData) . "\\binaries.zip";
      }
      else {
        $zipName = $self->LocalArchivePath($mrpData) . "\\binaries_$thisBinCat.zip";
      }
      Utils::ZipList($zipName, $bins, $self->{verbose}, 0, Utils::EpocRoot());
      Utils::SetFileReadOnly($zipName);
    }
  }
}

sub ZipExports {
  my $self = shift;
  my $mrpData = shift;

  foreach my $thisExportCat (@{$mrpData->ExportCategories()}) {
    my $exports = $mrpData->Exports($thisExportCat);
    if ($exports and scalar(@$exports) > 0) {
      my $zipName = $self->LocalArchivePath($mrpData) . "\\exports".uc($thisExportCat).".zip";
      Utils::ZipList($zipName, $exports, $self->{verbose}, 0, Utils::EpocRoot());
      Utils::SetFileReadOnly($zipName);
      # Need to create an exports<CAT>.txt file which details necessary info...
      my $txtName = $self->LocalArchivePath($mrpData) . "\\exports".uc($thisExportCat).".txt";
      CatData->New($self->{iniData}, $txtName, $mrpData, uc($thisExportCat));
    }
  }
}

sub WriteRelData {
  my $self = shift;
  my $mrpData = shift;
  my $versionInfo = shift;

  my $notesSource = $self->{notesSrc};
  if (defined $notesSource) {
    Utils::CheckExists($notesSource);
    Utils::CheckIsFile($notesSource);
  }
  else {
    $notesSource = Utils::PrependSourceRoot($mrpData->NotesSource());
  }
  my $relData = RelData->New($self->{iniData}, $mrpData, $notesSource, $versionInfo, $self->{toolName}, $self->{verbose}, undef, $self->{project}); # undef = dontPersist
}

sub WriteManifest {
  my $self = shift;
  my $mrpData = shift;
  my $componentName = $mrpData->Component();
  my $manifest = undef;
  
  
  if ($self->{useCachedManifest}) {
    #Check if manifest file is available in temp location
    my $manifestTempFile = File::Spec->catfile( File::Spec->tmpdir(), "manifest_".$componentName.".xml" );
    
    if (-e $manifestTempFile ) {
      #Construct manifest object from the manifest file
      $manifest = Symbian::CBR::Component::Manifest->new( $manifestTempFile );
      
      #Delete the temp manifest file
      my $unlinkCount = 100;
      while(-e $manifestTempFile and $unlinkCount > 0){
        unlink($manifestTempFile) or print "Warning: unlink $manifestTempFile failed[$unlinkCount].\n";
        $unlinkCount--;
      }
      if ( $unlinkCount == 0 ) {
        die "Error: unlink $manifestTempFile failed.\n";
      }
    }
  }
  
  if (!defined $manifest) {
    my $mrpName = Utils::RelativeToAbsolutePath( $mrpData->MrpName(), $mrpData->{iniData}, SOURCE_RELATIVE );
    
    #Construct manifest object from MRP file
    $manifest = Symbian::CBR::Component::Manifest->new( $mrpName );
  }
  
  #Save the manifest file to the archive release location for the component
  $manifest->Save ( $self->LocalArchivePath($mrpData) );
}

sub Cleanup {
  my $self = shift;
  if ($self->{verbose}) { print "Cleaning up...\n"; }
  foreach my $thisMrpData (@{$self->{mrpData}}) {
    my $relDir = $self->LocalArchivePath($thisMrpData);
    if (-e $relDir) {
      if ($self->{verbose}) { print "Deleting $relDir...\n"; }
      my $origDir = cwd();
      
      chdir(dirname($relDir)); #If you try to rmtree a UNC path the cwd must also be a UNC path
      rmtree ($relDir);
      chdir($origDir);
    }
  }
}

sub LocalArchivePath {
  my $self = shift;
  my $mrpData = shift;
  my $name = $mrpData->Component();
  my $ver = $mrpData->ExternalVersion();

  if (not exists $self->{pathCache}->{$name}->{$ver}) {
    $self->{pathCache}->{$name}->{$ver} = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($name, $ver, $self->{project});
  }

  return $self->{pathCache}->{$name}->{$ver};
}

1;

=head1 NAME

MakeRel.pm - Provides an interface for making releases.

=head1 INTERFACE

=head2 MakeReleases

Expects to be passed an C<IniData> reference, an C<EnvDb> reference, a reference to a list of C<MrpData> objects, the name of a notes source file, the name of the tool using C<MakeRel> and a verbosity level. Firstly, the binary files referred to by the C<MrpData> objects are cross checked to ensure that more than one component isn't attempting to release the same file. Dies if this is the case. Secondly, generates release directories and files for each C<MrpData> object. Thirdly, updates local signature files and the environment database.

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
