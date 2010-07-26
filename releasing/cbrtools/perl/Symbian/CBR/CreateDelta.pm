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
# Symbian::CBR::CreateDelta.pm
#

package Symbian::CBR::CreateDelta;

use File::Basename;
use File::Spec;
use File::Path;
use File::Copy;
use XML::Simple;
use Carp;
use Digest::Md5;
use ExportData;
use EnvDb;
use Utils;
use Symbian::CBR::DeltaRelease::Manifest qw(ADDED_ZIPS META_FILES);
use Symbian::CBR::Component::Manifest;


sub new {
  my $pkg = shift;
  my $iniData = shift;
  my $pgpkey = shift;
  my $releaseManifest = shift;
  my $verbose = shift;
  my $noevalid = shift;
  my $nodelta = shift;
  my $maxdelta = shift;

  my $self;
  $self->{iniData} = $iniData;
  $self->{pgpKey} = $pgpkey;
  $self->{releaseManifest} = $releaseManifest;
  $self->{verbose} = $verbose;
  $self->{noevalid} = $noevalid;
  $self->{nodelta} = $nodelta;
  $self->{maxdelta} = $maxdelta;
  bless $self, $pkg;
  return $self;
}

sub compareEnvironments {
  my $self = shift;
  my $referenceComp = shift;
  my $referenceVer = shift;
  my $nominatedComp = shift;
  my $nominatedVer = shift;

  print "Comparing reldata files\n" if($self->{verbose});
  my $referenceRelData = RelData->Open($self->{iniData}, $referenceComp, $referenceVer, $self->{verbose});
  my $nominatedRelData = RelData->Open($self->{iniData}, $nominatedComp, $nominatedVer, $self->{verbose});

  my $referenceEnv = $referenceRelData->Environment();
  my $nominatedEnv = $nominatedRelData->Environment();

  foreach my $thisComp ( sort keys %{$nominatedEnv}){
    if (defined $referenceEnv->{$thisComp}) {
      if ($referenceEnv->{$thisComp} ne $nominatedEnv->{$thisComp}) {
        $self->{diffComps}{modified}{$thisComp}{$referenceEnv->{$thisComp}} = $nominatedEnv->{$thisComp};
      }
      else {
        $self->{diffComps}{identical}{$thisComp} = $nominatedEnv->{$thisComp};
      }
    }
    else {
      $self->{diffComps}{added}{$thisComp} = $nominatedEnv->{$thisComp};
    }
  }
  foreach my $thisComp( sort keys %{$referenceEnv}){
    unless (defined $nominatedEnv->{$thisComp}) {
      $self->{diffComps}{deleted}{$thisComp} = $referenceEnv->{$thisComp};
    }
  }
}

sub compareFiles {
  my $self = shift;
  my $comp = shift;
  my $referenceVersion = shift;
  my $nominatedVersion = shift;
  my $diffFiles;
  my $referenceComp = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($comp, $referenceVersion);
  my $nominatedComp = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($comp, $nominatedVersion);
  my $referenceManifest = File::Spec->catdir($referenceComp,MANIFEST_FILE);
  my $nominatedManifest = File::Spec->catdir($nominatedComp,MANIFEST_FILE);
  if (-e $referenceManifest and -e $nominatedManifest) {
    $diffFiles =   $self->compareManifestFiles($referenceManifest,$nominatedManifest);
  }
  else {
    $diffFiles =   $self->compareAllZipFiles($comp, $nominatedComp, $referenceComp);
  }
  #List meta files (reldata, manifest and exports.txt files).
  foreach my $thisFile (@{Utils::ReadDir($nominatedComp)}) {
    unless ($thisFile =~ /\.zip$/) {
      $diffFiles->{$comp}{files}{$thisFile} = 1;
    }
  }
  return $diffFiles;
}

sub compareAllZipFiles {
  my $self = shift;
  my $comp = shift;
  my $nominatedComp = shift;
  my $referenceComp = shift;
  my $tempRefPath = File::Spec->catdir($self->{tempDir},"ref");
  my $tempNomPath = File::Spec->catdir($self->{tempDir},"nom");
  print "Manifest file is not available for $comp\n";
  my $nominatedCompFiles = Utils::ReadDir($nominatedComp);
  my $referenceCompFiles = Utils::ReadDir($referenceComp);
  my $nominatedZipFiles ;
  my $referenceZipFiles ;
  my %diffFiles;
  foreach  my $thisFile (@{$nominatedCompFiles}) {
    $nominatedZipFiles->{$thisFile} = 1 if ($thisFile =~ /\.zip$/) ;
  }
  foreach  my $thisFile (@{$referenceCompFiles}) {
    $referenceZipFiles->{$thisFile} = 1 if ($thisFile =~ /\.zip$/) ;
  }
  foreach  my $thisZip (keys %{$nominatedZipFiles}) {
    next unless ( $self->isExportableCat($comp, $thisZip) );
    if (defined $referenceZipFiles->{$thisZip}) {
      #Modified zip file
      my $refZipFile = File::Spec->catdir($referenceComp, $thisZip);
      my $nomZipFile = File::Spec->catdir($nominatedComp, $thisZip);
      print "Extracting $thisZip.\n" if($self->{verbose});
      Utils::Unzip($refZipFile ,$tempNomPath,0,1); # 0 = verbose, 1 = overwrite.
      Utils::Unzip($nomZipFile,$tempRefPath,0,1);
      my @referenceFiles;
      my @nominatedFiles;
      Utils::ListAllFiles($tempRefPath, \@referenceFiles);
      Utils::ListAllFiles($tempNomPath, \@nominatedFiles);
      foreach my $thisnomFile (@nominatedFiles) {
        my $file1 = $thisnomFile;
        $thisnomFile = substr($thisnomFile, (length( $tempNomPath)+1));
        my $file2 = File::Spec->catfile($tempRefPath,$thisnomFile);
        if (-e $file2) {
          unless ($self->compareFile($file1 ,$file2)) {
            $diffFiles->{$comp}{zips}{$thisZip}{modified}{$thisnomFile} = 1; #modified file.
            unlink($file1) or print "Warning: Couldn't delete $file1 : $!\n";
            unlink($file2) or print "Warning: Couldn't delete $file2 : $!\n";
          }
        }
        else {
          $diffFiles{$comp}{zips}{$thisZip}{added}{$thisnomFile} = 1; #added file.
          unlink($file1) or print "Warning: Couldn't delete $file1 : $!\n";
        }
      }
      foreach my $thisFile (@referenceFiles) {
        my $file1 = substr($thisFile, (length( $tempRefPath)+1));
        $file1  = File::Spec->catfile($tempNomPath,$file1);
        unless (-e $file1) {
          $diffFiles{$comp}{zips}{$thisZip}{deleted}{$file1} = 1 ; #deleted file for zip file.
          unlink($thisFile) or print "Warning: Couldn't delete $thisFile : $!\n";
        }
      }
    }
    else {
      #Newly added zip file.
      my $nomZipFile = File::Spec->catdir($nominatedComp, $thisZip);
      print "Extracting $thisZip.\n" if($self->{verbose});
      Utils::Unzip($nomZipFile,$tempNomPath,0,1); # 0 = verbose, 1 = overwrite.
      my @nominatedCompFiles;
      Utils::ListAllFiles($tempNomPath, \@nominatedCompFiles);
      foreach my $thisFile (@nominatedCompFiles) {
        my $file = substr($thisFile, (length( $tempNomPath)+1));
        $diffFiles{$comp}{zips}{$thisZip}{added}{$thisFile} = 1;
        unlink($thisFile) or print "Warning: Couldn't delete $thisFile : $!\n";
      }
    }
  }
  #check for deleted zip files.
  foreach  my $thisZip (keys %{$referenceZipFiles}) {
    unless (defined $nominatedZipFiles->{$thisZip}) {
      my @referenceCompFiles;
      my $refZipFile = File::Spec->catdir($referenceComp, $thisZip);
      print "Extracting $thisZip.\n" if($self->{verbose});
      Utils::Unzip($refZipFile ,$tempRefPath,0,1); # 0 =  verbose, 1 = overwrite.
      Utils::ListAllFiles($tempRefPath, \@referenceCompFiles);
      foreach my $thisFile (@referenceCompFiles) {
        my $file = substr($thisFile , (length( $tempRefPath)+1));
        $diffFiles{$comp}{zips}{$thisZip}{deleted}{$file} = 1;
        unlink($thisFile) or print "Warning: Couldn't delete $thisFile : $!\n";
      }
    }
  }
  return \%diffFiles;
}

sub compareFile {
  my $self = shift;
  my $file1 = shift;
  my $file2 = shift;
  my $Checksum1;
  my $Checksum2;
  unless ($self->{noevalid}) {
    my $type1;
    my $type2;
    ($Checksum1, $type1) = EvalidCompare::GenerateSignature($file1);
    ($Checksum2, $type2) = EvalidCompare::GenerateSignature($file2);
  }
  else {
    open(FILEHANDLE1,"$file1");
    open(FILEHANDLE2,"$file2");
    my $ctx1 = Digest::MD5->new;
    my $ctx2 = Digest::MD5->new;
    $ctx1->addfile(FILEHANDLE1);
    $ctx2->addfile(FILEHANDLE2);
    $Checksum1 = $ctx1->hexdigest;
    $Checksum2 = $ctx2->hexdigest;
    close FILEHANDLE1;
    close FILEHANDLE2;
  }
  return 1 if ($Checksum1 eq $Checksum2);
  return 0;
}


sub compareManifestFiles {
  my $self = shift ;
  my $referenceManifest = shift;
  my $nominatedManifest = shift;
  my %diffFiles;
  my $referenceManifestObj = Symbian::CBR::Component::Manifest->new($referenceManifest);
  my $nominatedManifestObj = Symbian::CBR::Component::Manifest->new($nominatedManifest);
  my $comp = lc($referenceManifestObj->{componentName});
  $nominatedManifestObj->Compare($referenceManifestObj,1,1); # 1 = validatesource, 1 = keepgoing
  foreach my $zipName (keys %{$nominatedManifestObj->GetDiffZipFiles()}) {
    foreach my $thisFile (keys %{$nominatedManifestObj->GetDiffFilesForZip($zipName)}) {
      my $fileStatus = $nominatedManifestObj->GetFileStatus($zipName, $thisFile);
      $diffFiles{$comp}{zips}{$zipName}{$fileStatus}{$thisFile} = 1;
    }
  }
  return  \%diffFiles;
}

sub isExportableCat {
  my $self = shift;
  my $comp = shift;
  my $zipFile = shift;
  my $exportPgp = [ ];
  return 1 if($self->{exportAll});
  if ($zipFile =~ /^source([a-z])\.zip$/i) {
    $exportPgp  = $self->{exportData}->PgpKeysForSource($comp,$1);
  }
  elsif ($zipFile =~ /^exports([A-Z])\.zip$/i) {
    $exportPgp  = $self->{exportData}->PgpKeysForExports($comp,$1);
  }
  elsif ($zipFile =~ /^binaries/i) {
    $exportPgp  = $self->{exportData}->PgpKeysForBinaries($comp);
  }
  if (scalar @{$exportPgp} > 0) {
    foreach  my $thisKey (@{$exportPgp}) {
      return 1 if ($self->{pgpKey} eq $thisKey);
    }
  }
  return 0;
}

sub createDeltaEnv {
  my $self = shift;
  my $referenceComp = shift;
  my $referenceVersion = shift;
  my $nominatedComp = shift;
  my $nominatedVersion = shift;
  my $destination = shift;
  Utils::InitialiseTempDir($self->{iniData});
  $self->{tempDir} = Utils::TempDir();
  my $deltaDestination = File::Spec->catdir($self->{tempDir},"modified");
  my $newCompPath = File::Spec->catdir($self->{tempDir}, "new");
  $self->{exportData} = ExportData->New(exports_file => $self->{iniData}->ExportDataFile(),verbose => $self->{verbose}) unless ($self->{exportAll});
  my $referenceRelData = RelData->Open($self->{iniData}, $referenceComp, $referenceVersion, $self->{verbose});
  my $nominatedRelData = RelData->Open($self->{iniData}, $nominatedComp, $nominatedVersion, $self->{verbose});
  my $referenceEnv = $referenceRelData->Environment();
  my $nominatedEnv = $nominatedRelData->Environment();
  unless ($self->{exportAll}) {
    my $foundPgpKey = 0;
    foreach my $thisPgpKeys (@{$self->{exportData}->AllPgpKeys()}) {
      if ($thisPgpKeys eq $self->{pgpKey}) {
        $foundPgpKey = 1;
        last;
      }
    }
    croak "Error: PGP key ".$self->{pgpKey}." is not defined in ".$self->{iniData}->ExportDataFile()." file.\n" unless($foundPgpKey);

    foreach  my $thisComp (keys %{$nominatedEnv}) {
      unless ($self->{exportData}->ComponentIsExportable($thisComp)) {
        print "Warning: component \"$thisComp\" is not defined in export table.\n";
      }
    }
  }

  unless ($self->{noevalid} or eval { require EvalidCompare }) {
    print "Warning: EvalidCompare is not installed. Setting --noevalid option. ($@)\n";
    $self->{noevalid} = 1;
  }

  $self->{DeltaManifest} = Symbian::CBR::DeltaRelease::Manifest->new();

  $self->{DeltaManifest}->SetReferenceBaselineComp($referenceComp);
  $self->{DeltaManifest}->SetReferenceBaselineVer($referenceVersion);
  $self->{DeltaManifest}->SetNominatedBaselineComp($nominatedComp);
  $self->{DeltaManifest}->SetNominatedBaselineVer($nominatedVersion);
 
  $self->compareEnvironments($referenceComp,$referenceVersion,$nominatedComp,$nominatedVersion);

  foreach my $thisComp ( sort keys %{$self->{diffComps}{modified}} ) {
    eval{ $self->createDeltaForComp($thisComp,$$referenceEnv{$thisComp},$$nominatedEnv{$thisComp}, $deltaDestination) };
    print "Error: Unable to create Deltas for $thisComp,$$referenceEnv{$thisComp},$$nominatedEnv{$thisComp} $@\n" if($@);
  }

  foreach my $thisComp (sort keys %{$self->{diffComps}{added}}) {
    $self->addComponent($thisComp, $newCompPath);
  }

  foreach my $thisComp (sort keys %{$self->{diffComps}{identical}}) {
    $self->recordIdenticalOrDeletedComponent($thisComp, "identical");
  }
  foreach my $thisComp (sort keys %{$self->{diffComps}{deleted}}) {
    $self->recordIdenticalOrDeletedComponent($thisComp, "deleted");
  }
  $self->{DeltaManifest}->Save($self->{tempDir}); # Write delta manifest file.

  #Package modified, new directories and delta manifest file into zip files
  my @filesToBeZipped ;
  my @allFiles;
  my $tempRefPath = File::Spec->catdir($self->{tempDir},"ref");
  my $tempNomPath = File::Spec->catdir($self->{tempDir},"nom");
  rmtree($tempRefPath) if($tempRefPath);
  rmtree($tempNomPath) if($tempNomPath);
  Utils::ListAllFiles($self->{tempDir}, \@allFiles);
  foreach  my $thisFile (@allFiles) {
    my $file = substr($thisFile, (length($self->{tempDir})+1));
    push @filesToBeZipped, $file;
  }
  my $tempPackageZipFile = $referenceVersion."_".$nominatedVersion.".tmp";
  $tempPackageZipFile = File::Spec->catfile($destination, $tempPackageZipFile );
  my $packageZipFile = $referenceVersion."_".$nominatedVersion.".zip";
  $packageZipFile = File::Spec->catfile($destination, $packageZipFile );
  if (-e $packageZipFile) {
    print "Overwriting $packageZipFile.\n";
    unlink ($packageZipFile);
  }
  print "Packaging all files into $packageZipFile.\n";
  Utils::ZipList( $tempPackageZipFile, \@filesToBeZipped, $self->{verbose}, 0,$self->{tempDir});
  rename ($tempPackageZipFile, $packageZipFile) or croak "Error: Couldn't rename $tempPackageZipFile to $packageZipFile.\n ";
  rmtree ($self->{tempDir});
}

sub recordIdenticalOrDeletedComponent {
  my $self = shift;
  my $comp = shift;
  my $compStatus = shift;
  $self->{DeltaManifest}->SetComponentDetails($comp, $compStatus, $self->{diffComps}{$compStatus}{$comp}, undef); # undef for nominated version.
  print "$comp is $compStatus.\n" if ($self->{verbose});
}

sub addComponent {
  my $self = shift;
  my $comp = shift;
  my $newCompPath = shift;
  print "$comp is newly added.\n";
  $self->{DeltaManifest}->SetComponentDetails($comp, "added", undef, $self->{diffComps}{added}{$comp}); # undef for reference version.

  $newCompPath = File::Spec->catdir($newCompPath,$comp);
  mkpath($newCompPath) unless (-e $newCompPath);

  my $archiveForComp = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($comp, $self->{diffComps}{added}{$comp});
  my $archiveFiles = Utils::ReadDir($archiveForComp);

  foreach my $thisFile (@{$archiveFiles}) {
    my $archiveFilePath = File::Spec->catdir($archiveForComp,$thisFile);
    my $destFilePath = File::Spec->catfile($newCompPath,$thisFile);
    if ($thisFile =~ /\.zip$/) {
      if ($self->isExportableCat($comp,$thisFile)) {
        $self->{DeltaManifest}->SetZipfileDetails($comp, $thisFile, "added");
        eval{ copy($archiveFilePath,$destFilePath) ;};
		croak "Error: File $archiveFilePath cannot be copied to $destFilePath. $@" if($@);
      }
    }
    else {
     eval{ copy($archiveFilePath,$destFilePath) ;};
	 croak "Error: File $archiveFilePath cannot be copied to $destFilePath. $@" if($@);
      $self->{DeltaManifest}->RecordMetaFile($comp, $thisFile);
    }
  }
}

sub createDeltaForComp {
  my $self = shift;
  my $comp = shift;
  my $referenceVersion = shift;
  my $nominatedVersion = shift;
  my $deltaDestination = shift;
  print "Creating Delta for $comp component.\n";

  my $referenceCompPath = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($comp, $referenceVersion);
  my $nominatedCompPath = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($comp, $nominatedVersion);

  my $relDataManifestDestination = File::Spec->catdir($self->{tempDir},META_FILES);
  $self->{DeltaManifest}->SetComponentDetails($comp, "modified", $referenceVersion, $nominatedVersion);
  my $filesList = $self->compareFiles($comp,$referenceVersion,$nominatedVersion);
  foreach my $zipFile (keys %{$filesList->{$comp}{zips}}) { #Iterate through all zip files.
    if ($self->isExportableCat($comp,$zipFile)) {
      if ($self->{deltaAllFiles} or $self->{releaseManifest}->FileExists($comp, $zipFile)) { #Check whether zip file is present at receiving site or.
        $self->{DeltaManifest}->SetZipfileDetails($comp, $zipFile, "modified");
        $self->createDeltaForZip($comp, $referenceCompPath, $nominatedCompPath, $zipFile, $deltaDestination, $filesList);
      }
      else {
        $self->{DeltaManifest}->SetZipfileDetails($comp, $zipFile, "added"); #added zip file for the component.
        my $newZipFilePath = File::Spec->catdir($deltaDestination, ADDED_ZIPS, $comp);
        mkpath ($newZipFilePath) unless(-d $newZipFilePath);
        my $addedZipFile = File::Spec->catfile($newZipFilePath, $zipFile);
        my $archiveFile = File::Spec->catfile($nominatedCompPath,$zipFile);
        copy($archiveFile,$addedZipFile) or print "Warning: Couldn't copy $zipFile\n";
      }
    }
    else {
      print "Warning: $zipFile is not exportable.\n" if ($self->{verbose});
    }
  }
  foreach my $thisFile (@{Utils::ReadDir($referenceCompPath)}) {
    if ($thisFile =~/\.zip$/ and $self->isExportableCat($comp,$thisFile)) {
      unless (defined $filesList->{$comp}{zips}{$thisFile}) {
        $self->{DeltaManifest}->SetZipfileDetails($comp, $thisFile, "identical");
      }
    } 
  }

  #Process reldata manifest and export.txt files.
  foreach my $thisFile (keys %{$filesList->{$comp}{files}}) {
    $self->{DeltaManifest}->RecordMetaFile($comp, $thisFile);
    my $archiveFile = File::Spec->catfile($nominatedCompPath, $thisFile);
    my $destinationFile = $comp."_".$thisFile;
    mkpath($relDataManifestDestination) unless(-d $relDataManifestDestination);
    $destinationFile = File::Spec->catfile($relDataManifestDestination, $destinationFile);
    copy($archiveFile,$destinationFile) or print "Warning: Couldn't copy $thisFile\n";
  }
}

sub createDeltaForZip {
  my $self = shift;
  my $comp = shift;
  my $referenceCompPath = shift;
  my $nominatedCompPath  = shift;
  my $zipFile = shift;
  my $deltaDestination = shift;
  my $filesList = shift;

  my $refZipFilePath = File::Spec->catfile($referenceCompPath, $zipFile);
  my $nomZipFilePath = File::Spec->catfile($nominatedCompPath, $zipFile);
  my $tempRefPath = File::Spec->catdir($self->{tempDir},"ref");
  my $tempNomPath = File::Spec->catdir($self->{tempDir},"nom");
  print "Creating delta for $zipFile\n" if($self->{verbose});

  #Process all files of a zip file.
  foreach my $file (keys %{$filesList->{$comp}{zips}{$zipFile}{'modified'}}) {
    #create delta for a file if it is modified.
    unless ($self->{nodelta}) {
      #Extract and create delta for a file.
      print "Extracting $file from nominated $zipFile.\n" if($self->{verbose});
      eval{Utils::UnzipSingleFile($nomZipFilePath,$file,$tempNomPath,0,1, $comp)};  # 0 = verbose. 1 = overwrite.
      croak "Error: Couldn't Extract File $file $@\n" if($@);
      my $file2 = File::Spec->catfile($tempNomPath,$file);

      my $outputDeltaPath = File::Spec->catdir($deltaDestination, dirname($file));

      my $size = -s $file2;
      if (!defined $self->{maxdelta} or $size <= $self->{maxdelta}) {
        print "Extracting $file from reference $zipFile.\n" if($self->{verbose});
        eval{Utils::UnzipSingleFile($refZipFilePath,$file,$tempRefPath,0,1, $comp)};
        croak "Error: Couldn't Extract File $file $@\n" if($@);
        my $file1 = File::Spec->catfile($tempRefPath,$file);

        $self->{DeltaManifest}->SetFileDetails($comp, $zipFile, $file, "modified", "delta");

        $self->generateFileDelta($file1,$file2,$outputDeltaPath);
      } else {
        # File is too big to delta
        $self->{DeltaManifest}->SetFileDetails($comp, $zipFile, $file, "modified", "file");
        print "Not creating a delta of $file due to it being $size bytes\n" if ($self->{verbose});
        if (! -d $outputDeltaPath) {
          mkpath($outputDeltaPath) or croak "Error: Couldn't create directory for large file $file2 in delta\n";
        }
        system("move /Y \"".$file2."\" \"".$outputDeltaPath."\"") and croak "Error: Couldn't move large file $file2 into delta\n";
      }
    } else {
      #add file to output delta package.
      $self->{DeltaManifest}->SetFileDetails($comp, $zipFile, $file, "modified", "file");
      print "Extracting $file from $zipFile.\n" if($self->{verbose});
      eval{Utils::UnzipSingleFile($nomZipFilePath,$file,$deltaDestination,0,1, $comp); # 0 = verbose. 1 = overwrite.
      };
      croak "Error: Couldn't Extract File $file $@\n" if($@);
    }
  }

  foreach my $file (keys %{$filesList->{$comp}{zips}{$zipFile}{'added'}}) {
    #Newly added file to component.
    print "$file is newly added.\n" if ($self->{verbose});
    $self->{DeltaManifest}->SetFileDetails($comp, $zipFile, $file, "added", "file"); 
    print "Extracting $file from $zipFile\n" if($self->{verbose});
    eval{Utils::UnzipSingleFile($nomZipFilePath,$file,$deltaDestination,0, 1, $comp)};
    croak "Error: Couldn't Extract File $file:$@\n" if($@);
  }

  foreach my $file (keys %{$filesList->{$comp}{zips}{$zipFile}{'deleted'}}) {
    #deleted file.
    print "$file is deleted.\n" if ($self->{verbose});
    $self->{DeltaManifest}->SetFileDetails($comp, $zipFile, $file, "deleted", "file"); 
  }
}

sub generateFileDelta {
  my $self = shift;
  my $file1 = shift;
  my $file2 = shift;
  my $destination = shift;
  my $deltaFile = shift;
  mkpath($destination) unless (-e $destination);
  $deltaFile =  basename($file2).".delta" unless(defined $deltaFile);
  $deltaFile = File::Spec->catfile($destination,$deltaFile);

  $file1  =~ s/^\\/\\\\/g; # Replace leading \ by \\.
  $file2  =~ s/^\\/\\\\/g;

  print "Creating delta for file ". basename($file1). "\n" if ($self->{verbose});
  my $status = system "zdc \"$file1\" \"$file2\"  \"$deltaFile\"" ;
  if( $status != 0 ) {
    $status = system "zdc" ;
    $! = $? >> 8;
    if ($status != 0) {
      $! = $? >> 8;
      print "Error: The zdelta tool is not installed. Please install zdelta, or use the --nodelta option to skip delta creation.\n";
      croak;
    }
    else {
      print "Error: The zdelta tool is not installed properly. Please install zdelta once again, or use the --nodelta option to skip delta creation.\n";
      croak;
    }
  }
}

1;

__END__


=head1 NAME

Symbian::CBR::CreateDelta.pm - Creates deltas for modified files from reference baseline to the nominated baseline.

=head2 new

Creates a CreateDelta object. Expects to be passed:

=over 4

=item *
an C<IniData> reference

=item *
a C<Release manifest> reference

=item *
a verbosity level

=item *
a flag to indicate not to use evalid for comparision

=item *
a flag to skip delta creation

=item *
a maximum file size (in bytes) above which the tool won't create a delta of the file (assuming the flag to skip delta creating in all cases is not used).  

=back

=head2 compareEnvironments

Expects to be passed a reference component name, a reference component version, a nominated component name and a nominated component version. Compares these environments to list identical, modified, added and deleted components.

=head2 compareFiles

Expects to be passed a full path for a reference version and a nominated version of a component. Lists modified, added and deleted files for the component between the two versions. If the manifest file is present for both versions, then it compares using manifest objects. Otherwise it extracts all zip files and compares each file, one at a time.

=head2 compareFile

Expects to be passed full paths for two versions of a file. Compares them using EvalidCompare if noevalid is not specified, otherwise uses Digest::MD5 for the file comparison. Returns 1 if checksum for both the files matches, otherwise 0.

=head2 createDeltaEnv

Expects to be passed a reference component name, a reference component version, a nominated component name, a nominated component version, and a destination. Creates the deltas for the modified files between two baselines, adds newly added files and components and packages these files into a zip file at the path provided as a destination. 

=head2 createDeltaForComp

Expects to be passed a component name, reference version of component, nominated version of a component, and path where deltas to be stored. Compares the modified, added and deleted files from reference version to nominated version and creates the deltas for modified files, then copies the newly added files.

=head2 generateFileDelta 

Expects to be passed a full path for two versions of a file, destination path where delta file should be stored, and optionally delta file name. Makes use of zdelta third party tool to create delta for a file.

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
