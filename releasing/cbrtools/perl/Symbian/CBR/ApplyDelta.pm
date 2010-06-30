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
# Symbian::CBR::ApplyDelta.pm
#

package Symbian::CBR::ApplyDelta;

use strict;
use File::Basename;
use FindBin qw($Bin);
use File::Spec;
use Symbian::CBR::Component::Manifest;
use Symbian::CBR::DeltaRelease::Manifest qw(META_FILES DELTA_MANIFEST_FILE);
use ExportData;
use EnvDb;
use Utils;
use File::Path;
use File::Temp;
use XML::Simple;
use File::Copy;
use Carp;
use Cwd;


sub new {
  my $pkg = shift;
  my $iniData = shift;
  my $verbose = shift;
  my $self;
  $self->{iniData} = $iniData;
  $self->{verbose} = $verbose;
  bless $self, $pkg;
  return $self;
}


sub ReconstructEnv {
  my $self = shift;
  my $zipFile = shift;
  my $overwrite = shift;

  $self->{deltaManifest} = Symbian::CBR::DeltaRelease::Manifest->new($self->{verbose});
  Utils::InitialiseTempDir($self->{iniData});
  $self->{deltaDir} = Utils::TempDir();

  my $deltaManifestFile = File::Spec->catfile($self->{deltaDir}, DELTA_MANIFEST_FILE );
  print "Extracting delta release package.\n";
  eval {Utils::Unzip($zipFile,$self->{deltaDir},0,1);};
  croak "Error: Couldn't Extract File $zipFile $@\n" if($@);
  #Read delta manifest file.

  $self->{deltaManifest}->LoadManifest($deltaManifestFile);
  my $referenceBaseline = $self->{deltaManifest}->GetReferenceBaselineComp();
  my $referenceVersion = $self->{deltaManifest}->GetReferenceBaselineVer();
  my $destination =  $self->{iniData}->PathData->LocalArchivePathForExistingComponent($referenceBaseline, $referenceVersion);
  croak "Error: Reference baseline $referenceBaseline $referenceVersion does not exist.\n" unless (defined $destination);
  my $index = index($destination, $referenceBaseline);
  $destination = substr($destination, 0, ($index));
  foreach  my $comp (sort keys %{$self->{deltaManifest}->ListAllComponents()}) {
    my $compStatus = $self->{deltaManifest}->GetCompStatus($comp);
    my $hasError;
    if ($compStatus eq "modified") {
      $hasError = $self->ReconstructComp($comp, $destination, $overwrite); #Reconstruct modified component.
    }
    elsif ($compStatus eq "added") {
      $hasError = $self->CopyCompToBaseline($comp, $destination, $overwrite); #Directly copy component to baseline.
    }
    
    if ($hasError) {
      my $version = $self->{deltaManifest}->GetCompNominatedVer($comp);
      print "Error: Can't reconstruct component $comp, version $version\n";
      next;
    }
  }
  rmtree($self->{deltaDir}) or print "Warning: Couldn't delete temp directory ".$self->{deltaDir}.".\n";
}

sub CopyCompToBaseline {
  my $self = shift;
  my $comp = shift;
  my $destination = shift;
  my $overwrite = shift;

  print "$comp is newly added to the baseline.\n";
  my $tempNewCompPath = File::Spec->catfile($self->{deltaDir},"new", $comp);
  my $nomVersion = $self->{deltaManifest}->GetCompNominatedVer($comp);
  my $archiveCompPath = File::Spec->catdir($destination, $comp, $nomVersion);
  if (-d $archiveCompPath and !$overwrite) {
    print "Error: $comp already exists. Please use -o option to overwrite.\n";
    return 1;
  }
  mkpath($archiveCompPath) unless (-d $archiveCompPath);
  foreach my $thisFile (@{Utils::ReadDir($tempNewCompPath)}) {
    my $thisTempFile = File::Spec->catfile($tempNewCompPath, $thisFile);
    my $thisArchivepFile = File::Spec->catfile($archiveCompPath, $thisFile);
    if (-e $thisArchivepFile) {
      print "Overwriting $thisFile.\n " if ($self->{verbose});	
      unless (unlink($thisArchivepFile)) {
        print "Error: Couldn't delete $thisArchivepFile : $!\n";
	return 1;
      }
    }	  
    unless (copy($thisTempFile, $thisArchivepFile)) {
      print "Error: Couldn't copy file from $thisTempFile to $thisArchivepFile.\n";
      return 1;
    }
  }
  return 0;
}

sub ReconstructComp {
  my $self = shift;
  my $comp = shift;
  my $destination = shift;
  my $overwrite = shift;

  my $refVersion =  $self->{deltaManifest}->GetCompReferenceVer($comp);
  my $nomVersion = $self->{deltaManifest}->GetCompNominatedVer($comp);
  print "Reconstructing $comp component.\n";
  my $refCompVer = File::Spec->catdir($destination, $comp, $refVersion);
  my $nomCompVer = File::Spec->catdir($destination, $comp, $nomVersion);
  if (-d $nomCompVer and !$overwrite) {
    print "Error: $comp of $nomVersion version already exists. Please use -o option to overwrite.\n";
    return 1;
  }
  if (-d $nomCompVer) {
    print "Overwriting $comp\n" if($self->{verbose});
    my $origDir = cwd();

    chdir(dirname($nomCompVer)); #If you try to rmtree a UNC path the cwd must also be a UNC path
    unless (rmtree($nomCompVer)) {
      print "Error: Couldn't delete $nomCompVer directory\n";
      return 1;
    }
    chdir($origDir);
  }
  mkpath($nomCompVer);
  #Make copy of reference version.
  foreach my $thisFile (@{Utils::ReadDir($refCompVer)}) {
    my $thisRefFile = File::Spec->catfile($refCompVer, $thisFile);
    my $thisNomFile = File::Spec->catfile($nomCompVer, $thisFile);
    unless (copy($thisRefFile, $thisNomFile)) {
      print "Error: Couldn't copy file from $thisRefFile to $thisNomFile. $!\n";
      return 1;
    }
  }

  #Reconstruct modified zip files, copy newly added zip files and delete deleted zip files.
  foreach  my $zipfile (keys  %{$self->{deltaManifest}->GetZipFilesForComp($comp)}) {
    my $zipStatus = $self->{deltaManifest}->GetZipStatus($comp, $zipfile);
    my $nomZipFile = File::Spec->catfile($nomCompVer, $zipfile);
    if ($zipStatus eq "modified") {
      my $hasError = $self->ReconstructZipFile($comp, $zipfile, $nomCompVer); #If zip file is modified, then reconstruct it.
      return $hasError if($hasError);
    }
    
    elsif ($zipStatus eq "added") {
      my $tempZipFile = File::Spec->catfile(Utils::TempDir(),"modified","addedZips",$comp,$zipfile);
      if (-e $nomZipFile) {
        print "Overwriting $nomZipFile.\n " if ($self->{verbose});
        unless (unlink($nomZipFile)) {
          print "Error: Couldn't delete $nomZipFile : $!\n";
	  return 1;
	}
      }
      unless (copy($tempZipFile, $nomZipFile)) {
        print "Error: Couldn't copy $tempZipFile to $nomZipFile. $!\n";
	return 1;
      }
    }
    elsif ($zipStatus eq "deleted") {
      if (-e $nomZipFile) {
        unless (unlink($nomZipFile)) {
          print "Error: Couldn't delete $nomZipFile : $!\n";
	  return 1;
        }
      }
    }
    elsif ($zipStatus eq "identical") {
      print "$zipfile is not modified.\n" if($self->{verbose} > 1);
    }
    else {
      print "Error: Unknown zip file status \"$zipStatus\" for $zipfile of $comp component in delta manifest file.\n";
      return 1;
    }
  }
  #Reconstruct reldata, manifest.xml and exports.txt files.
  my $deltaFilePath = File::Spec->catdir($self->{deltaDir}, META_FILES);
  foreach my $metafile (keys %{$self->{deltaManifest}->GetMetaFiles($comp)}) {
    my $nomFile = File::Spec->catfile($nomCompVer, $metafile);
    my $deltaFile = $comp."_".$metafile;
    $deltaFile = File::Spec->catfile($deltaFilePath, $deltaFile);
    #retry 10 times
    my $retries = 10;
    while ($retries > 0) {
      if (-e $nomFile) {
        unlink($nomFile) or print "Warning: delete file $nomFile failed. $?, $!\n";
      }
      print "Copying $metafile.\n" if( -e $metafile and $self->{verbose});
      if (copy($deltaFile, $nomFile) == 0) {
        #copy failed, warning and try again
        print "Warning: Couldn't copy file from $deltaFile to $nomFile. $!\n";
        $retries--;
      }
      else {
        #copy successfully, jump out of the loop
        last;
      }
    }
    if ($retries<=0) {
      print "Error: Couldn't copy file $deltaFile to $nomFile. $!\n";
      return 1;
    }
  }
  
  return 0;
}


sub ReconstructZipFile {
  my $self = shift;
  my $comp = shift;
  my $zipfile = shift;
  my $releaseFolder = shift;
  
  my $nomZipFile = File::Spec->catfile($releaseFolder, $zipfile);
  my $tempCompPath = mkdtemp($self->{iniData}->TempDir().'\_XXXX');
  mkpath ($tempCompPath) unless(-d $tempCompPath);
  my $tempCompZips = File::Spec->catdir($self->{deltaDir}, "TempZips");
  mkpath($tempCompZips) unless(-d $tempCompZips);
  my $tempCompZipFile = File::Spec->catdir($tempCompZips, $zipfile);
  #Move zip file to temporary location.
  unless (move($nomZipFile, $tempCompZipFile)) {
    print "Error: Couldn't move $zipfile to temp directory. $!\n";
    return 1;
  }
  print "Extracting $zipfile file.\n" if($self->{verbose} > 1);
  Utils::Unzip($tempCompZipFile,$tempCompPath,0,1);
  unless (unlink($tempCompZipFile)) {
    print "Error: Couldn't delete $tempCompZipFile : $!\n";
    return 1;
  }

  foreach my $file (keys %{$self->{deltaManifest}->GetFilesForZip($comp, $zipfile)}) {
    my $deltaFilePath = File::Spec->catfile($self->{deltaDir},"modified",$file);
    my $tempCompFilePath = File::Spec->catfile($tempCompPath,$file);
    my $fileStatus = $self->{deltaManifest}->GetFileStatus($comp, $zipfile, $file);
    my $type = $self->{deltaManifest}->GetFileType($comp, $zipfile, $file );

    if ($fileStatus eq "added") {
      print "Copying $file\n" if($self->{verbose});
      my $tempFilePath = dirname ($tempCompFilePath);
      unless (-e $tempFilePath) {
        unless (mkpath ($tempFilePath)) {
          print "Error: Unable to create $tempFilePath path.\n";
	  return 1;
	}
      }
      unless (-e $deltaFilePath) {
        print "Error: $deltaFilePath file doesn't exists.\n";
	return 1;
      }
      unless (copy($deltaFilePath, $tempCompFilePath)) {
        print "Error: Couldn't copy file from $deltaFilePath to $tempCompFilePath\n";
	return 1;
      }
    }
    elsif ($fileStatus eq "modified") {
      if ($type eq "file") {
        if (-e $tempCompFilePath) {
          unless (unlink($tempCompFilePath)) {
            print "Error: Couldn't delete $tempCompFilePath : $!\n";
	    return 1;
	  }
        }
        my $tempFilePath = dirname ($tempCompFilePath);
        unless (-e $tempFilePath) {
          mkpath ($tempFilePath) or croak "Error: Unable to create $tempFilePath path.\n";
        }		  
        unless (-e $deltaFilePath) {
          print "Error: $deltaFilePath file doesn't exist.\n";
	  return 1;
	}
        unless (copy ($deltaFilePath, $tempCompFilePath)) {
          print "Error: Couldn't copy file from $deltaFilePath to $tempCompFilePath\n";
	  return 1;
	}
      }
      elsif ($type eq "delta") {
        my $deltaFile = $deltaFilePath.".delta";
        $self->ReconstructFile($tempCompFilePath, $deltaFile, $tempCompFilePath);
      }
      else {
        print "Error: Unknown file type \"$type\" in delta manifest file.\n";
	return 1;
      }
    }
    elsif ($fileStatus eq "deleted") {
      if (unlink($tempCompFilePath) == 0) {
        if (-e $tempCompFilePath) {
          print "Error: Couldn't delete $tempCompFilePath : $!\n";
	  return 1;
        }
        else {
          print "Warning: Expecting to delete $tempCompFilePath, but it does not exist.\n";
        }
      }
    }
    else {
      print "Error: Unknown file status \"$fileStatus\" for \"$file\" file.\n";
      return 1;
    }
  }
  #Pack all files of a zipfile to form a category.zip file.
  my @allFiles;
  my @filesToBeZipped;
  Utils::ListAllFiles($tempCompPath, \@allFiles);
  foreach  my $thisFile (@allFiles) {
    my $file = substr($thisFile, (length($tempCompPath)+1));
    push @filesToBeZipped, $file;
  }
  Utils::ZipList( $nomZipFile, \@filesToBeZipped, $self->{verbose}, undef,$tempCompPath);
  unless (rmtree ($tempCompPath)) {
    print "Error: Couldn't delete $tempCompPath directory.\n"; 
    return 1;
  }
  
  return 0;
}

sub ReconstructFile {
  my $self = shift;
  my $referenceFile = shift;
  my $deltaFilePath = shift;
  my $destination = shift;

  my $destinationDir = dirname($destination);
  mkpath($destinationDir) unless(-d $destinationDir);
  print "Reconstructing ".basename($referenceFile)." file.\n" if($self->{verbose} > 1);
  my $status = system "zdu \"$referenceFile\" \"$deltaFilePath\"  \"$destination\"" ;
  if( $status != 0 ) {
    $status = system "zdu" ;
    $! = $? >> 8;
    if( $status != 0 ) {
      print "Error: The zdelta tool is not installed. Please install zdelta.\n";
      croak;
    }
    else {
      print "Error: The zdelta tool is not installed properly. Please install zdelta once again.\n";
      croak;
    }
  }
}

1;

__END__


=head1 NAME

Symbian::CBR::ApplyDelta.pm - Reconstructs the nominated baseline using deltas and reference version of baseline.

=head2 new

Expects to be passed an C<IniData> reference and verbosity level. Creates an ApplyDelta object. 

=head2 ReconstructEnv

Expects to be passed a delta zip file path, a destination archive where the environment is to be created, and an overwrite flag specifying whether existing components should be overwritten or not. It makes use of the delta zip file and a reference baseline (specified by the delta manifest file) and reconstructs the originally nominated baseline.

=head2 ReconstructComp

Expects to be passed a component name, a destination and an overwrite flag specifying whether existing component should be overwritten or not. It makes use of the delta for a component and a reference version of a component (specified by the delta manifest file) and reconstructs the originally nominated version of a component.

=head2 ReconstructFile

Expects to be passed a reference file, path to a delta file and a destination path. Makes use of the zdelta third party tool to reconstruct the originally nominated version of the file from the inputs.

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
