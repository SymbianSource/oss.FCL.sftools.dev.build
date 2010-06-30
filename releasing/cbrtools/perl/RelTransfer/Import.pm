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
# Description:
# RelTransfer::Import.pm
#

package RelTransfer::Import;

use strict;
use Utils;
use File::Copy;
use File::Basename;
use File::Path;
use Cwd;
use RelTransfer;
use vars qw(@ISA);
@ISA=("RelTransfer");

#
# Constructor
#

sub Initialize {
  my $self = shift;

  $self->SUPER::Initialize();

  #set the passphrase for decryption
  $self->SetPgpPassPhrase();
}

#
# Public methods
#

sub TransferRelease {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $noPassphraseRetry = shift;

  print "\nImporting $comp $ver...\n" if ($self->{verbose});

  #check to see if ok to import
  if ($self->ReleaseExistsInLocalArchive($comp, $ver) and not $self->{force}) {
    my $localReleaseDir = $self->PathData->LocalArchivePathForExistingComponent($comp, $ver);
    my $reldatafile = File::Spec->catfile( $localReleaseDir,"reldata");
    if (-f $reldatafile) {
      print "$comp $ver already exists in local archive\n" if ($self->{verbose});
      return 0;
    }
    print "$comp $ver is corrupted - attempting to remove and re-import.\n";
    my $origDir = cwd();

    chdir(dirname($localReleaseDir)); #If you try to rmtree a UNC path the cwd must also be a UNC path
    rmtree ($localReleaseDir) or die "$localReleaseDir can't be deleted\n";
    chdir($origDir);
  }
  unless ($self->ReleaseExistsOnRemoteSite($comp, $ver)) {
    die "Error: $comp $ver does not exist on remote site\n";
  }

  my $excludeRelease = 0;

  #Get remote release file, unzip, decrypt and move to local archive
  # We pass around the remote archive path because with the project-based
  # PathData scheme, the remote location might affect which local location
  # to put it in.
  my $remoteDir = $self->PathData->RemoteArchivePathForExistingComponent($comp, $ver, $self->{remoteSite});
  eval {
    $self->GetZippedReleaseFile($comp, $ver, $remoteDir);
    select STDOUT;$|=1;
    $self->UnzipReleaseFile($comp, $ver);
    select STDOUT;$|=1;
    $self->DecryptReleaseFiles($comp, $ver, $noPassphraseRetry);
    
    # DEF104279 - If the users key can decrypt the exclude.txt then the user is not able to recieve this release.  
    opendir(DIR, Utils::TempDir()) or die "Error: cannot open Utils::TempDir()\n";
    $excludeRelease = 1 if (grep /exclude.txt$/, readdir DIR);
    closedir(DIR);
    
    $self->MoveDecryptedFilesToArchive($comp, $ver, $remoteDir) if (!$excludeRelease);
  };
  if ($@) {
    my $error = $@;
    $self->CleanupTempDir();
    my $localReleaseDir = $self->PathData->LocalArchivePathForImportingComponent($comp, $ver, $remoteDir);
    if (-d $localReleaseDir) {
      my $origDir = cwd();

      chdir(dirname($localReleaseDir)); #If you try to rmtree a UNC path the cwd must also be a UNC path
      rmtree ($localReleaseDir) or die "$localReleaseDir can't be deleted\n";
      chdir($origDir);
    }
    die $error;
  }
  $self->CleanupTempDir();

  print "$comp $ver successfully imported from remote site.\n" if ($self->{verbose} && !$excludeRelease);
  return 1;
}

#
# Private methods
#

sub GetZippedReleaseFile {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $remoteDir = shift;

  my $localFile = Utils::TempDir()."/$comp$ver.zip";
  my $remoteFile = "$remoteDir/$comp$ver.zip";

  $self->{remoteSite}->GetFile($remoteFile, $localFile);
}

sub UnzipReleaseFile {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  if ($self->{verbose}) {
    print "Unzipping $comp$ver.zip ...\n";
  }	
  my $tempDir = Utils::TempDir();
  $tempDir =~ s/[\/\\]$//;
  $tempDir .= "/";
  my $zipName = File::Spec->catfile("$tempDir","$comp$ver.zip");

  my $zip = Archive::Zip->new($zipName);
  foreach my $member ($zip->members()) {
    my $filename=$member->fileName();
    eval {Utils::ExtractFile($tempDir, $filename,$member, 0, 1, $self->{verbose})};  # 0 is being passed in because we are not validating 1 = Overwrite.
    die "$@\n" if ($@); 
  }
  unlink $zipName;
}

sub DecryptReleaseFiles {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $noPassphraseRetry = shift;

  #build up list of pgp encrypted files in TEMP_DIR 
  my $tempDir = Utils::TempDir();
  opendir(TEMPDIR, $tempDir);
  my @encryptedFiles = grep {/\.pgp$/} readdir TEMPDIR;
  closedir(TEMPDIR);

  my $noFilesDecrypted = 1;
 TRYAGAIN:
  foreach my $encryptedFile (@encryptedFiles) {
    my ($decryptedFile) = ($encryptedFile =~ /(.+).pgp$/);

    #set the passphrase for decryption
    $self->SetPgpPassPhrase();
    # returns if it's already set

    if ($self->{verbose}) {
      print "Decrypting $encryptedFile ... \n";
    }
    eval {
      $self->{crypt}->Decrypt("$tempDir/$encryptedFile", "$tempDir/$decryptedFile", $self->{pgpPassPhrase});
    };
    if ($@) {
      if ($@ =~ /BAD_PASSPHRASE/i) {
	$@ =~ s/BAD_PASSPHRASE//;
	print "Incorrect PGP passphrase\n";

        if ($noPassphraseRetry) {
          die "\n";
        }

	$self->{pgpPassPhrase} = undef;
	redo TRYAGAIN;
      }
      elsif ($@ =~ /NO_SECKEY/i) {
	# Do nothing - it's perfectly possible that we don't have access to certain release files, particularly
	# since the addition of 'exclude' keyword to ExportData.
      }	
      else {
	die $@;
      }	
    }
    else {
      $noFilesDecrypted = 0;
    }
    unlink "$tempDir/$encryptedFile";
  }

  if ($noFilesDecrypted) {
    die "Error: Unable to decrypt any part of $comp $ver (see FAQ for more detail)\n";
  }
}

sub MoveDecryptedFilesToArchive {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $remotedir = shift;

  if ($self->{verbose}) {
    print "Moving release files to local archive ... \n";
  }
  my $tempDir = Utils::TempDir(); 
  opendir(DIR, $tempDir) or die "Error: cannot open $tempDir\n";
  my @releaseFiles = grep {$_ ne '.' and $_ ne '..'} readdir DIR;
  closedir(DIR);
  if (grep(lc($_) eq "reldata", @releaseFiles)) {
    # Move the 'reldata' entry to the end
    @releaseFiles = grep(lc($_) ne "reldata", @releaseFiles);
    push @releaseFiles, "reldata";
  }
  unless (@releaseFiles) {
    die; # If we've got this far, there should have been some files decyrpted.
  }

  #create release directory if doesnot exist
  my $localReleaseDir = $self->PathData->LocalArchivePathForImportingComponent($comp, $ver, $remotedir);
  unless (-e $localReleaseDir) {
    Utils::MakeDir($localReleaseDir);
  }
  else {
    #clean the local release directory if it already exists
    opendir(DIR, $localReleaseDir) or die "Error: cannot open $localReleaseDir\n";
    my @allFiles = grep {$_ ne '.' and $_ ne '..'} map {"$localReleaseDir/$_"} readdir DIR;
    closedir(DIR);
    unlink @allFiles;
  }
  foreach my $releaseFile (@releaseFiles) {
    move("$tempDir/$releaseFile", "$localReleaseDir/$releaseFile") or die "Error: Unable to move $tempDir/$releaseFile to $localReleaseDir/$releaseFile: $!";

    Utils::SetFileReadOnly("$localReleaseDir/$releaseFile");
  }
}

sub SetPgpPassPhrase {
  my $self = shift;

  return if ($self->{pgpPassPhrase});
  print "PGP passphrase: \n";
  $self->{pgpPassPhrase} = Utils::QueryPassword();
}

1;

__END__

=head1 NAME

RelTransfer::Import.pm - Import releases from the remote site

=head1 SYNOPSIS

 use RelTransfer::Import;

 $importer = RelTransfer::Import->New(ini_data => $iniData,
				      force => 1,
				      verbose => 1);

 $importer->TransferRelease('componentname', 'componentversion');

=head1 DESCRIPTION

Implements the abstract TransferRelease method from the C<RelTransfer> base class module which transfers a release from the remote site to the local archive.

=head1 INTERFACE

=head2 New

Passed an argument list in the form of hash key value pairs. The supported arguments are...

 ini_data    =>  $iniData_object
 force       =>  $force_integer
 verbose     =>  $verbosity_integer

Returns a reference to a C<RelTransfer::Import> object.

=head2 TransferRelease

Passed a component name and version number. Performs the following steps:

=over 4

=item *

Check to see if the release can or needs to be imported. If the release already exists on the local archive or does not exist on the remote site then do not attempt to import 

=item *

Get the release zip from the remote site

=item *

Unzip the release zip

=item *

Decrypt the release files (ie the reldata, source and binary zips)

=item *

Move the release files to the local archive

=back

=head1 KNOWN BUGS

None

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
