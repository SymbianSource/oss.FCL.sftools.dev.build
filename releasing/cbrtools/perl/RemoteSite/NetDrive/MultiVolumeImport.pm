# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# RemoteSite::NetDrive::MultiVolumeImport.pm
#

package RemoteSite::NetDrive::MultiVolumeImport;

use strict;
use File::Copy;
use File::Basename;

use RemoteSite;
use RemoteSite::NetDrive;
use vars qw(@ISA);
@ISA=("RemoteSite::NetDrive");


#
# Initialization
#

sub Initialize {
  my $self = shift;
  $self->SUPER::Initialize(@_);
  $self->Connect();	
}


#
# Public (from RemoteSite)
#

sub SendFile {
  my $self = shift;
  $self->HandleError("Function 'SendFile' not supported by ".ref($self)."\n");
}

sub GetFile {
  my $self = shift;
  my $remoteFile = shift;
  my $localFile = shift;

  unless (defined $localFile and defined $remoteFile) {
    $self->HandleError("Incorrect args passed to ".ref($self)."::GetFile");
  }

  $self->InitAppropriateImportVolume($remoteFile);
  $self->SUPER::GetFile($remoteFile, $localFile);
}

sub FileExists {
  my $self = shift;
  my $remoteFile = shift;
  unless (defined $remoteFile) {
    return 0;
  }
  $self->Connect();
  return (defined $self->LookupIndexEntry($remoteFile));
}

sub DirList {
  my $self = shift;
  $self->HandleError("Function 'DirList' not supported by ".ref($self)."\n");
}

sub MakeDir {
  my $self = shift;
  $self->HandleError("Function 'MakeDir' not supported by ".ref($self)."\n");
}

sub FileSize {
  my $self = shift;
  $self->HandleError("Function 'FileSize' not supported by ".ref($self)."\n");
}

sub DeleteFile {
  my $self = shift;
  $self->HandleError("Function 'DeleteFile' not supported by ".ref($self)."\n");
}

sub MoveFile {
  my $self = shift;
  $self->HandleError("Function 'MoveFile' not supported by ".ref($self)."\n");
}

sub FileModifiedTime {
  my $self = shift;
  $self->HandleError("Function 'FileModifiedTime' not supported by ".ref($self)."\n");
}


#
# Private.
#

sub LookupIndexEntry {
  my $self = shift;
  my $file = lc(shift);
  Utils::TidyFileName(\$file);
  unless (exists $self->{index}) {
    $self->InternaliseIndex();
  }
  if (exists $self->{index}->{$file}) {
    return $self->{index}->{$file};
  }
  return undef;
}

sub InternaliseIndex {
  # Read the index created by MultiVolumeExport.
  my $self = shift;
  my $index = $self->Host(). '/index';
  unless (-e $index) {
    $self->ChangeImportVolume(0);
  }
  open (INDEX, $index) or die "Error: Couldn't open \"$index\": $!\n";
  while (my $line = <INDEX>) {
    (my $file, my $volume) = $line =~ /(.*)\t(.*)/;
    $self->{index}->{$file} = $volume;
  }
  close (INDEX);
}

sub InitAppropriateImportVolume {
  my $self = shift;
  my $file = shift;
  my $requiredVolume = $self->LookupIndexEntry($file);
  unless (defined $requiredVolume) {
    die "Error: \"$file\" not found in any volumes\n";
  }
  if ($requiredVolume == $self->{currentImportVolume}) {
    return;
  }
  else {
    $file = Utils::ConcatenateDirNames($self->Host(), $file);
  AGAIN:
    $self->ChangeImportVolume($requiredVolume);
    unless (-e $file) {
      print "Error: \"$file\" not found
       Try again? [y/n] ";
      my $response = <STDIN>;
      chomp $response;
      if ($response =~ /^y$/i) {
	goto AGAIN;
      }
      die "Aborting...\n";
    }
  }
}

sub ChangeImportVolume {
  my $self = shift;
  my $volume = shift;
  print "Insert import volume #$volume and hit return...\n";
  <STDIN>;
  $self->{currentImportVolume} = $volume;
}

1;

=head1 NAME

RemoteSite::NetDrive::MultiVolumeImport.pm - Import releases that were exported using RemoteSite::NetDrive::MultiVolumeExport

=head1 DESCRIPTION

The purpose of this remote site module is to allow releases that were exported using C<RemoteSite::NetDrive::MultiVolumeExport> to be imported. The export process writes a complete index into each volume. This is read to determine which volumes contain which files. The user is prompted to change volumes are necessary. Location of the import volume is specified using the C<IniData> keyword C<remote_host>.

=head1 INTERFACE

=head2 New

Passed an argument list in the form of hash key value pairs. The supported arguments are...

  host      => $host_address_string
  verbose   => $verbosity_integer

Returns a reference to a C<RemoteSite::NetDrive::MultiVolumeImport> object

=head2 SendFile

Not suppored, since this module may only be used for importing.

=head2 GetFile

Passed a remote and local file name. Finds out which volume the file lives on, and requests that the user changes volumes if necessary. Then differs to C<RemoteSite::NetDrive> to perform the copy.

=head2 FileExists

Passed a filename (with full path). Returns true if the file exists in the volume index, false otherwise.

=head1 KNOWN BUGS

None

=head1 COPYRIGHT

 Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
