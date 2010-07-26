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
# RemoteSite::NetDrive::MultiVolumeExport.pm
#

package RemoteSite::NetDrive::MultiVolumeExport;

use strict;
use File::Copy;
use File::Basename;

use RemoteSite;
use RemoteSite::NetDrive;
use vars qw(@ISA);
@ISA=("RemoteSite::NetDrive");


#
# Constants,
#

use constant KLogDirName => '\sent_log';


#
# Initialization
#

sub Initialize {
  my $self = shift;
  my %args = @_;
  $self->{maxExportVolumeSize} = $args{max_export_volume_size};
  $self->SUPER::Initialize(@_);
  $self->Connect();
  $self->InitNextExportVolume();
}


#
# Public (from RemoteSite)
#

sub SendFile {
  my $self = shift;
  my $localFile = shift;
  my $remoteFile = shift;

  unless ($localFile and $remoteFile) {
    $self->HandleError("Incorrect args passed to ".ref($self)."::SendFile");
  }
  unless (-e $localFile) {
    $self->HandleError("Local file $localFile does not exist");
  }

  my $fileSize = Utils::FileSize($localFile);
  if ($fileSize > $self->{maxExportVolumeSize}) {
    die "Error: \"$localFile\" is larger than the maximum export volume size ($self->{maxExportVolumeSize})\n";
  }
  $self->{currentExportVolumeSize} += $fileSize;
  if ($self->{currentExportVolumeSize} > $self->{maxExportVolumeSize}) {
    $self->InitNextExportVolume();
    $self->{currentExportVolumeSize} = $fileSize;
  }
  $self->SUPER::SendFile($localFile, Utils::ConcatenateDirNames($self->CurrentExportVolumeName(), $remoteFile));
  $self->WriteIndexEntry($remoteFile);
}

sub GetFile {
  my $self = shift;
  $self->HandleError("Function 'GetFile' not supported by ".ref($self)."\n");
}

sub FileExists {
  my $self = shift;
  my $remoteFile = shift;
  unless (defined $remoteFile) {
    return 0;
  }
  $self->Connect();
  $remoteFile = Utils::ConcatenateDirNames($self->LogDir(), $remoteFile);
  return (-e $remoteFile);
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
  my $file = shift;
  my $volume = $self->LookupIndexEntry($file);
  my $fullName = Utils::ConcatenateDirNames($self->Host(), $self->ExportVolumeName($volume));
  $fullName = Utils::ConcatenateDirNames($fullName, $file);
  return Utils::FileSize($fullName);
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

sub SetExportVolumePrefix {
  my $self = shift;
  $self->{exportVolumePrefex} = time . '__#';
}

sub CurrentExportVolumeName {
  my $self = shift;
  return $self->ExportVolumeName($self->{currentExportVolume});
}

sub ExportVolumeName {
  my $self = shift;
  my $volume = shift;
  my $name = "$self->{exportVolumePrefex}$volume";
  Utils::TidyFileName(\$name);
  return $name;
}

sub LookupIndexEntry {
  my $self = shift;
  my $file = lc(shift);
  Utils::TidyFileName(\$file);
  if (exists $self->{index}->{$file}) {
    return $self->{index}->{$file};
  }
  return undef;
}

sub WriteIndexEntry {
  # Index entries keep track of which volume of a set a particular release may be found in.
  my $self = shift;
  my $file = lc(shift);
  Utils::TidyFileName(\$file);
  $self->WriteLogEntry($file);
  $self->{index}->{$file} = $self->{currentExportVolume};
}

sub WriteLogEntry {
  # Log entries keep track of what has been sent. KLogDirName should not be deleted between exports.
  my $self = shift;
  my $file = shift;
  $file = Utils::ConcatenateDirNames($self->LogDir(), $file);
  Utils::MakeDir(dirname($file));
  $self->WriteLogReadMe();
  open (LOG, ">$file") or die "Error: Unable to write log entry \"$file\": $!\n";
  close (LOG);
}

sub WriteLogReadMe {
  my $self = shift;
  my $readMe = Utils::ConcatenateDirNames($self->LogDir(), 'readme.txt');
  unless (-e $readMe) {
    open (README, ">$readMe") or die "Error: Couldn't open \"$readMe\" for writing: $!\n";
    print README "This directory contains a log automatically written by the LPD Release Tools as a result of one
or more exports being performed to a remote site of type 'multi-volume'. It's purpose is to keep track of which
component releases have already been exported, so they don't get sent again. If you delete this directory, on next
export, all component releases will need to be sent.";
    close (README);
  }
}

sub ExternaliseIndex {
  # The index will later be interalised by MultiVolumeExport.
  my $self = shift;
  for (my $i = 0; $i <= $self->{currentExportVolume}; ++$i) {
    my $dir = Utils::ConcatenateDirNames($self->Host(), $self->ExportVolumeName($i));
    Utils::MakeDir($dir);
    open (INDEX, ">$dir/index") or die "Error: Couldn't open \"$dir/index\" for writing: $!\n";
    foreach my $file (sort keys %{$self->{index}}) {
      print INDEX "$file\t$self->{index}->{$file}\n";
    }
    close (INDEX);
  }
}

sub InitNextExportVolume {
  my $self = shift;
  $self->{currentExportVolumeSize} = 0;
  if (exists $self->{currentExportVolume}) {
    ++$self->{currentExportVolume};
  }
  else {
    $self->{currentExportVolume} = 0;
    $self->SetExportVolumePrefix();
  }
  my $exportVol = Utils::ConcatenateDirNames($self->Host(), $self->CurrentExportVolumeName());
  Utils::MakeDir($exportVol);
}

sub LogDir {
  my $self = shift;
  return Utils::ConcatenateDirNames($self->Host(), KLogDirName);
}

sub DESTROY {
  my $self = shift;
  if ($self->{currentExportVolume} == 0 and not exists $self->{index}) {
    # Nothing was exported, so cleanup.
    my $dir = Utils::ConcatenateDirNames($self->Host(), $self->CurrentExportVolumeName());
    rmdir ($dir) or die "Error: Couldn't remove directory \"$dir\": $!\n";
  }
  else {
    $self->ExternaliseIndex();
  }
}

1;

=head1 NAME

RemoteSite::NetDrive::MultiVolumeExport.pm - Export encyrpted releases to multiple fixed size volumes

=head1 DESCRIPTION

The purpose of this remote site module is to allow releases to be exported to directories to be stored on removable media such as writable CD ROMs. It is derived from C<RemoteSite::NetDrive> since a lot of the basic file manipulation is identical.

The maximum size of each export volume can be specified using the C<IniData> keyword C<max_export_volume_size>. This is used to determine when to start a new volume. At the end of the export process a set of uniquely named directories (the export volumes) will have been created in C<host> directory (specified using the C<IniData> keyword C<remote_host>). There will also be a directory called F<sent_log>, which should be retain between exports so the tools can work out which release have already been exported. Once the export volumes have been archived, they may be deleted.

=head1 INTERFACE

=head2 New

Passed an argument list in the form of hash key value pairs. The supported arguments are...

  host                   => $host_address_string
  max_export_volume_size => $max_export_volume_size_integer
  verbose                => $verbosity_integer

Returns a reference to a C<RemoteSite::NetDrive::MultiVolumeExport> object.

=head2 SendFile

Passed a local and a remote file name. Checks the file will fit in the current volume, if not creates a new volume. Logs the file and then differs to C<RemoteSite::NetDrive> to perform the copy.

=head2 GetFile

Not suppored, since this module may only be used for exporting.

=head2 FileExists

Passed a filename (with full path). Checks the F<sent_log> to see is this has already been exported. Returns true if it has, false otherwise.

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
