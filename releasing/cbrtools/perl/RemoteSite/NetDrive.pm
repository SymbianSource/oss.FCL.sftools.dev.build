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
# RemoteSite::NetDrive.pm
#

package RemoteSite::NetDrive;

use strict;
use File::Copy;
use File::Basename;

use RemoteSite;
use vars qw(@ISA);
@ISA=("RemoteSite");

#
# Initialization 
#

sub Initialize {
  my $self = shift;
  $self->SUPER::Initialize(@_);

  #connect to network drive
  $self->Connect();	
}

#
# Public (from RemoteSite)
#

sub SendFile {
  my $self = shift;
  my $localFile = shift;
  my $remoteFile = shift;

  unless (defined $localFile and defined $remoteFile) {
    $self->HandleError("Incorrect args passed to ".ref($self)."::SendFile");
  }

  $remoteFile = Utils::ConcatenateDirNames($self->Host(), $remoteFile);
  $remoteFile =~ s{\\}{\/}g;

  if ($self->{verbose}) {
    print "Copying ".basename($localFile)." to network drive ".$self->Host()."...\n";
  }
  elsif (Utils::FileSize($localFile)) {
    print "Copying ".basename($localFile)."...\n";
  }

  unless (-e $localFile) {
    $self->HandleError("Local file $localFile does not exist");
  }

  $self->Connect();

  my $remoteDir = dirname($remoteFile);
  unless (-e $remoteDir) {
    eval {
      Utils::MakeDir($remoteDir);
    };
    if ($@) {
      $self->HandleError("Cannot make directory $remoteDir on network drive ".$self->Host());
    }
    if ($self->{verbose}) {
      print "Created directory $remoteDir on network drive\n";
    }
  } 	
 
  #use a temporary file during uploads
  my $tmpFile = $remoteDir.'/TMP_'.basename($remoteFile);

  unless (copy($localFile, $tmpFile)){
    my $flag = 0;
    my $errormessage = $!;
    
    if(-e $tmpFile) { 
      unlink $tmpFile or $flag=1;
    }

    if($errormessage =~ /No such file or directory/i) {
      $errormessage = "Unknown Error - Check disk space or missing file/directory";
    }
    
    if($flag) {
      $self->HandleError("Unable to cleanup $tmpFile, after the copy of $localFile failed : $errormessage");
    }
    $self->HandleError("Unable to copy $localFile to $tmpFile : $errormessage");
  }
  
  unless (move($tmpFile, $remoteFile)){
    unlink $tmpFile;    
    $self->HandleError("Unable to move $tmpFile to $remoteFile : $!");
  }
  
  if ($self->{verbose} > 1) {
    print "Copy successful. Stored as $remoteFile on network drive.\n";
  }  
}

sub GetFile {
  my $self = shift;
  my $remoteFile = shift;
  my $localFile = shift;

  unless (defined $localFile and defined $remoteFile) {
    $self->HandleError("Incorrect args passed to ".ref($self)."::GetFile");
  }

  my $host = $self->Host();
  $host =~ s{\\}{\/}g;
  $remoteFile =~ s{\\}{\/}g;

  if ($self->{verbose}) {
    print "Copying ".basename($remoteFile)." from network drive $host...\n";
  }
  else {
    print "Copying ".basename($remoteFile)."...\n";
  }

  $self->Connect();

  if ($self->{verbose}) {
    print "Checking whether \"$remoteFile\" exists...\n";
  }
  unless ($self->FileExists($remoteFile)) {
    $self->HandleError("Remote file $remoteFile does not exist on $host");
  }

  #check local dir exists and create it if it doesn't
  my $localDir = dirname($localFile);
  unless (-e $localDir) {
    Utils::MakeDir($localDir);
    if ($self->{verbose}) {
      print "Created directory $localDir on local drive\n";
    }
  }

  unless (copy($host.$remoteFile, $localFile)) {
    unlink $localFile;
    $self->HandleError("Transfer of $remoteFile from $host to local drive failed");
  }
  if ($self->{verbose} > 1) {
    print "Copy successful. Stored as $localFile on local drive.\n";
  }
}

sub FileExists {
  my $self = shift;
  my $remoteFile = shift;

  unless (defined $remoteFile) {
    return 0;
  }

  $self->Connect();

  $remoteFile = Utils::ConcatenateDirNames($self->Host(), $remoteFile);
  $remoteFile =~ s{\\}{\/}g; 
  return (-e $remoteFile);
}

sub DirExists {
  my $self = shift;
  my $remoteDir = shift;
  return $self->FileExists($remoteDir);
}

sub DirList {
  my $self = shift;
  my $remoteDir = shift;

  my $host = $self->Host();
  $host =~ s{\\}{\/}g;
  $remoteDir =~ s{\\}{\/}g;

  opendir(DIR, Utils::ConcatenateDirNames($host, $remoteDir)) or $self->HandleError("Cannot open $remoteDir on network drive ".$self->Host());
  my @dir = map {"$remoteDir/$_"} grep {$_ ne '.' and $_ ne '..'} readdir DIR;
  closedir(DIR);
  return \@dir;
}

sub MakeDir {
  my $self = shift;
  my $remoteDir = shift;

  $remoteDir = $self->Host().$remoteDir;
  $remoteDir =~ s{\\}{\/}g;

  eval {
    Utils::MakeDir($remoteDir);
  };
  if ($@) {
    $self->HandleError("Cannot make directory $remoteDir on network drive ".$self->Host());
  }
}

sub FileSize {
  my $self = shift;
  my $remoteFile = shift;

  $remoteFile = Utils::ConcatenateDirNames($self->Host(), $remoteFile);
  $remoteFile =~ s{\\}{\/}g; 

  return Utils::FileSize($remoteFile);
}

sub DeleteFile {
  my $self = shift;
  my $remoteFile = shift;

  $remoteFile = Utils::ConcatenateDirNames($self->Host(), $remoteFile);
  $remoteFile =~ s{\\}{\/}g; 
  
  rmdir $remoteFile or unlink $remoteFile or $self->HandleError("Cannot delete $remoteFile on network dirve ($!)");
}

sub MoveFile {
  my $self = shift;
  my $oldFile = shift;
  my $newFile = shift;

  $oldFile = Utils::ConcatenateDirNames($self->Host(), $oldFile);
  $oldFile =~ s{\\}{\/}g;
  $newFile = Utils::ConcatenateDirNames($self->Host(), $newFile);
  $newFile =~ s{\\}{\/}g;

  move($oldFile, $newFile) or $self->HandleError("Cannot move $oldFile to $newFile on network drive");
}

sub FileModifiedTime {
  my $self = shift;
  my $remoteFile = shift;

  $remoteFile = Utils::ConcatenateDirNames($self->Host(), $remoteFile);
  $remoteFile =~ s{\\}{\/}g; 

  return Utils::FileModifiedTime($remoteFile);
}


#
# Private
#

sub Connect {
  my $self = shift;

  unless ($self->Host()) {
    $self->HandleError("Network drive host name not defined");
  }
  my $hostName = $self->Host();
  unless (-e $hostName) {
    $self->HandleError("Cannot connect to network drive $hostName");
  }
}

1;

=head1 NAME

RemoteSite::NetDrive.pm - Access a remote network drive

=head1 SYNOPSIS

 use RemoteSite::NetDrive;

 $drive = RemoteSite::NetDrive->New(host => '\\server\share',
			            verbose => 1);

 if ($drive->FileExists('/somedir/someremotefile')) {
   do something...
 }
 $drive->SendFile('somelocalfile', 'someremotefile');
 $drive->GetFile('someremotefile', 'somelocalfile');

=head1 DESCRIPTION

C<RemoteSite::NetDrive> is inherited from the abstract base class C<RemoteSite>, implementing the abstract methods required for transfer of files to and from a remote site when the remote site is a network drive.

=head1 INTERFACE

=head2 New

Passed an argument list in the form of hash key value pairs. The supported arguments are...

  host      => $host_address_string
  verbose   => $verbosity_integer

Returns a reference to a C<RemoteSite::NetDrive> object

=head2 Host

Returns the current value of the C<host> attribute which contains the UNC path of the network drive. If passed an argument sets the attribute to this new value.

=head2 SendFile

Passed a local and a remote file name. Uploads the local file to the network drive.

=head2 GetFile

Passed a remote and local file name. Downloads the remote file from the network drive and stores it on the local drive.

=head2 FileExists

Passed a filename (with full path) on the network drive. Returns a non zero value if the file exists.

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
