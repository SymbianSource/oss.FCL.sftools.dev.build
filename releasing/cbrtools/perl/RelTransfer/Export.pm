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
# RelTransfer::Export.pm
#

package RelTransfer::Export;

use strict;
use ExportData;
use Utils;
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
  $self->{exportData} = ExportData->New(exports_file => $self->{iniData}->ExportDataFile(),
					verbose => $self->{verbose});

  #check to see if all the pgp keys used for exporting exist on the public keyring
  my @pgpKeys = @{$self->{iniData}->PgpEncryptionKeys};
  unless (@pgpKeys) {
    die "Error: No PGP encrypting keys defined in reltools.ini\n";
  }
  push @pgpKeys, @{$self->{exportData}->AllPgpKeys};
  foreach my $pgpKey (@pgpKeys) {
    unless ($self->{crypt}->PublicKeyExists($pgpKey)) {
      die "Error: PGP key $pgpKey is required for exporting but does not exist on public keyring\n";
    }
  }	
}

#
# Public methods
#

sub CheckExportable {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  unless ($self->ReleaseExistsInLocalArchive($comp, $ver)) {
    die "Error: $comp $ver does not exist in local archive\n";
  }
  unless ($self->{exportData}->ComponentIsExportable($comp)) {
    print "Warning: component \"$comp\" is not defined in export table.\n";
  }
}

sub TransferRelease {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  if ($self->{verbose}) {
    print "\nExporting $comp $ver...\n";
  }

  #check to see if ok to export
  unless ($self->ReleaseExistsInLocalArchive($comp, $ver)) {
    die "Error: $comp $ver does not exist in local archive\n";
  }

  my $releaseExists = $self->ReleaseExistsOnRemoteSite($comp, $ver);
  unless ($self->{exportData}->ComponentIsExportable($comp)) {
    if (not $releaseExists or $self->{force}) {
      die "Error: cannot export $comp: not defined in export table\n";
    }
    else {
      if ($self->{verbose}) {
	print "$comp $ver already exported to remote site\n";
      }	
      return 0;
    }
  }
  else {
    if ($releaseExists and not $self->{force}) {
      if ($self->{verbose}) {
	print "$comp $ver already exported to remote site\n";
      }	
      return 0;
    }
  }

  #encrypt, zip and then send release to remote site
  eval {
    my $localdir = $self->PathData->LocalArchivePathForExistingComponent($comp, $ver);
    print "Local directory for \"$comp\" \"$ver\" is \"$localdir\"\n" if ($self->{verbose});
    $self->EncryptReleaseFiles($comp, $ver, $localdir);
    $self->ZipEncryptedReleaseFiles($comp, $ver);
    $self->SendZippedReleaseFile($comp, $ver, $localdir);
    return 1 if ($self->{dummy});
    my $localsize = $self->SizeOfNewlyZippedFile($comp, $ver);
    my $remotesize = $self->SizeOfRemoteFile($comp, $ver);
    $self->CompareSizes($localsize, $remotesize, $comp, $ver);
  };
  if ($@) {
    my $error = $@;
    $self->CleanupTempDir();
    die $error;
  }

  #optionally send a log file to the remote site
  if (defined $self->{iniData}->RemoteLogsDir) {
    eval {
      $self->SendLogFile($comp, $ver);
    };
    if ($@) {
      print "Warning: Export of log file failed. $@\n";
    }
  }

  #delete all the files in the temporary directory
  $self->CleanupTempDir();

  if ($self->{verbose}) {
    print "$comp $ver successfully exported to remote site.\n";
  }
  return 1;
}

sub ExamineExportedRelease {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  unless ($self->ReleaseExistsInLocalArchive($comp, $ver)) {
    die "Error: $comp $ver does not exist in local archive\n";
  }

  eval {
    my $localdir = $self->PathData->LocalArchivePathForExistingComponent($comp, $ver);
    my $remotesize = $self->SizeOfRemoteFile($comp, $ver);
    $self->EncryptReleaseFiles($comp, $ver, $localdir);
    $self->ZipEncryptedReleaseFiles($comp, $ver);
    my $localsize = $self->SizeOfNewlyZippedFile($comp, $ver);
    $self->CompareSizes($localsize, $remotesize, $comp, $ver);
  };
  if ($@) {
    my $error = $@;
    $self->CleanupTempDir();
    die $error;
  }

  $self->CleanupTempDir();
}

#
# Private methods
#

sub CompareSizes {
  my $self = shift;
  my $localsize = shift;
  my $remotesize = shift;
  my $comp = shift; # comp and ver are just used for error messages
  my $ver = shift;

  my $diff = abs ($remotesize - $localsize);
  if ($diff == 0) {
    return; # disappointingly rare
  } elsif ($diff <=8) {
    print "Warning: the size of the exported $comp $ver is slightly different ($remotesize) to the local copy ($localsize): difference $diff. This may be due to the way the remote site reports sizes, or the randomness of PGP encryption.\n" if ($self->{verbose});
  } else {
    die "Error: $comp $ver exported file size ($remotesize) differs from local copy ($localsize)\n";
  }
}

sub SizeOfNewlyZippedFile {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  my $tempDir = Utils::TempDir();
  my $zipName = "$tempDir/$comp$ver.zip";
  die "Error: newly zipped file \"$zipName\" for $comp $ver didn't exist\n" unless -e $zipName;
  return -s $zipName;
}

sub SizeOfRemoteFile {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  die "No component name provided to SizeOfRemoteFile" unless $comp;
  die "No version for $comp provided to SizeOfRemoteFile" unless $ver;

  my $remoteFile = $self->PathData->RemoteArchivePathForExistingComponent($comp, $ver, $self->{remoteSite})."/$comp$ver.zip";
  die "Error: $comp $ver didn't exist on the remote site\n" unless $remoteFile;
  return $self->{remoteSite}->FileSize($remoteFile);
}

sub EncryptReleaseFiles {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $relDir = shift;
  my $tempDir = Utils::TempDir();
  
  my %excludedKeys;
  @excludedKeys{@{$self->{exportData}->AllPgpKeys()}} = ();

  #encrypt release files using pgp keys from export table and reltools.ini
  opendir(RELDIR, $relDir) or die "Error: Cannot open $relDir\n";
  while (defined(my $file = readdir RELDIR)) {
    my @pgpKeys;
    next if ($file =~ /^\.\.?$/);
    
    if ($file =~ /^(exports)([a-z])\.zip$/i or $file =~ /^(exports)([a-z])\.txt$/i) {
      @pgpKeys = @{$self->{exportData}->PgpKeysForExports($comp, $2)};
    }
    elsif ($file =~ /^(source)([a-z])\.zip$/i or $file =~ /^(source)([a-z])\.txt$/i) {
      if($self->{excludeSource}) {
        print "Skipping the encryption of source file $file (in directory \"$relDir\")\n" if ($self->{verbose});	
        next;
      }
      @pgpKeys = @{$self->{exportData}->PgpKeysForSource($comp, $2)};
    }
    elsif ( $file =~ /^reldata$/i ){
      @pgpKeys = @{$self->{exportData}->PgpKeysForRelData($comp)};
    }
    elsif ($file =~ /^binaries.zip$/i or $self->IsBinaryZipRequired($comp, $ver, $file)) {
      @pgpKeys = @{$self->{exportData}->PgpKeysForBinaries($comp)};
    } 
    else { 
      die "Error: Unexpected release file \"$file\" in $comp $ver\n";
    }

    #do the encryption
    if (@pgpKeys) {
      push @pgpKeys, @{$self->{iniData}->PgpEncryptionKeys}; #encrypt with users keys aswell
      print "Encrypting \"$file\" (in directory \"$relDir\") to keys @pgpKeys\n" if ($self->{verbose});
        # Warning: productisation scripts may depend on the format of the above line.
      $self->{crypt}->Encrypt("$relDir/$file", "$tempDir/$file.pgp", \@pgpKeys) unless ($self->{dummy});
    
      #Remove the keys that have been used from the list of keys which have been excluded for this release
      delete @excludedKeys{@pgpKeys};
    }
  }
  closedir(RELDIR);
  
  # DEF104279 The exclude keyword in the CBR export table breaks the exported archive.
  # All keys which are not used for this release will be used to encrypt a file called exclude.txt
  # When the release is imported it will not give the unable to decrypt any part error
  # as it can decrypt the exclude.txt file.

  if (keys %excludedKeys) {
    # Create an exclude.txt in the reldir  
    open (EXCLUDE, ">$tempDir/exclude.txt");
    print EXCLUDE "If you can decrypt this file then this release has been excluded for you based on your PGP key\n";
    close EXCLUDE;    
    
    $self->{crypt}->Encrypt("$tempDir/exclude.txt", "$tempDir/exclude.txt.pgp", \@{[keys %excludedKeys]}) unless ($self->{dummy});
  }
}

sub IsBinaryZipRequired {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $zip = shift;

  # If the required_binaries keyword isn't used, we need all builds
  return 1 unless defined $self->{iniData}->RequiredBinaries($comp);

  unless ($zip =~ /^binaries_(.*)\.zip$/) {
    die "Error: Unexpected file \"$zip\" in $comp $ver\n";
  }
  my $category = $1;
  foreach my $requiredBinary (@{$self->{iniData}->RequiredBinaries($comp)}) {
    if ($category =~ /^$requiredBinary/) {
      return 1;
    }
  }
  return 0;
}

sub ZipEncryptedReleaseFiles {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  if ($self->{verbose}) {
    print "Zipping encrypted files to $comp$ver.zip ...\n";
  }
	
  #build up list of pgp encrypted files in TEMP_DIR 
  my $tempDir = Utils::TempDir();  
  opendir(TEMPDIR, $tempDir);
  my @encryptedFiles = grep {/\.pgp$/} readdir TEMPDIR;
  closedir(TEMPDIR);

  unless (@encryptedFiles || $self->{dummy}) {
    die "Error: No encrypted files exist in $tempDir\n";
  }	

  #zip list of pgp encrypted files (archive only, no compression)
  my $origDir = getcwd();
  chdir($tempDir);
  my $zipName = "$tempDir/$comp$ver.zip";
  print "Zipping @encryptedFiles to \"$zipName\"\n";
  eval {
    Utils::ZipList($zipName, \@encryptedFiles, $self->{verbose} > 1, 1) unless ($self->{dummy});
  };
  chdir ($origDir);
  if ($@) {
    die $@;
  }	 
}

sub SendZippedReleaseFile {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $localdir = shift;
  
  my $localFile = Utils::TempDir()."/$comp$ver.zip";
  my $remoteFile = $self->PathData->RemoteArchivePathForExportingComponent($comp, $ver, $localdir, $self->{remoteSite})."/$comp$ver.zip";

  print "Sending \"$localFile\" to \"$remoteFile\"\n" if ($self->{verbose});
  $self->{remoteSite}->SendFile($localFile, $remoteFile) unless ($self->{dummy});
}

sub SendLogFile {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  
  my $localLogFile = Utils::TempDir()."/$comp$ver.log";
  my $remoteLogFile = $self->{iniData}->RemoteLogsDir($comp)."/$comp$ver.log";

  if ($self->{verbose}) {
    print "Sending $comp $ver log file to remote site \"$remoteLogFile\"\n";
  }

  return if ($self->{dummy});

  #create empty log file
  open LOG, ">$localLogFile"  or die "Error: Cannot open $localLogFile for writing\n";
  close LOG;

  #send log file to the remote site
  $self->{remoteSite}->SendFile($localLogFile, $remoteLogFile);

  unlink $localLogFile;
}

1;

__END__

=head1 NAME

RelTransfer::Export.pm - Export releases to the remote site

=head1 SYNOPSIS

 use RelTransfer::Export;

 $exporter = RelTransfer::Export->New(ini_data => $iniData,
				      force => 1;
				      verbose => 1);

 $exporter->TransferRelease('componentname', 'componentversion');

=head1 DESCRIPTION

Implements the abstract TransferRelease method from the C<RelTransfer> base class module which transfers a release from the local archive to the remote site.

=head1 INTERFACE

=head2 New

Passed an argument list in the form of hash key value pairs. The supported arguments are...

 ini_data    =>  $iniData_object
 force       =>  $force_integer
 verbose     =>  $verbosity_integer

Returns a reference to a C<RelTransfer::Export> object.

=head2 TransferRelease

Passed a component name and version number. Performs the following steps:

=over 4

=item *

Check to see if the release can or needs to be exported. If the component does not exist in the users export table no attempt will be made to export it. If the component is listed in the export table but the release already exists on the remote site then, again, no attempt will be made to export it (unless the C<force> member variable is set to a nonzero value)

=item *

Encrypt the release files (ie source zips, binaries zip and reldata file). The keys used to encrypt the files depend on the data stored in the users export table 

=item *

Create a zip archive (without compression) of the encrypted files 

=item *

Send the release zip file to the remote site

=item *

If a remote logs dir is defined in the F<reltools.ini> file send an empty log file to the remote site 

=back

=head2 ExamineExportedRelease

This goes through most of the same stages above, but instead of actually transferring the zip file, it will ensure that the size of the existing file on the remote site matches that which is expected.

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
