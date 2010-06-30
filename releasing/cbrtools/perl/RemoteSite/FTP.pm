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
# RemoteSite::FTP.pm
#

package RemoteSite::FTP;

use strict;
use Net::FTP;
use File::Basename;
use IO::File;

use RemoteSite;
use vars qw(@ISA);
@ISA=("RemoteSite");

#
# Constants
#

use constant DEFAULTRECONNECTS => 5;
use constant DEFAULTTIMEOUT => 30;
use constant BLOCKSIZE => 32768;

#
# Initialization
#

sub Initialize {
  my $self = shift;

  my %args = @_;
  $self->{username} = $args{username};
  $self->{password} = $args{password};
  $self->{passiveMode} = $args{passive_mode};
  $self->{resumeMode} = $args{resume_mode};
  $self->{timeout} = $args{timeout};
  $self->{reconnects} = $args{reconnects};

  #call base class initialization
  $self->SUPER::Initialize(@_);

  #if username or password not defined ask for them interactively
  unless ($self->Username()) {
    $self->HandleError("No remote host defined.") unless $self->Host();
    print 'FTP username: ';
    my $userName = <STDIN>;
    if ($userName) {
      chomp ($userName);
      $self->Username($userName);
    }
  }
  unless ($self->Password()) {
    print 'FTP password: ';
    $self->Password(Utils::QueryPassword());
  }

  #set timeout to default value if not set or not a positive integer
  unless (defined $self->{timeout} and $self->{timeout} =~ /^\d+$/) {
    $self->{timeout} = DEFAULTTIMEOUT;
  }

  #set reconnects to default value if not set or not a positive integer
  unless (defined $self->{reconnects} and $self->{reconnects} =~ /^\d+$/) {
    $self->{reconnects} = DEFAULTRECONNECTS;
  }

  #connect to FTP site, login and set to binary mode
  $self->Connect();
}

#
# Public getters/setters
#

sub Username {
  my $self = shift;
  if (defined $_[0]) {$self->{username} = shift;}
  return $self->{username};
}

sub Password {
  my $self = shift;
  if (defined $_[0]) {$self->{password} = shift;}
  return $self->{password};
}

sub PassiveMode {
  my $self = shift;
  if (defined $_[0]) {$self->{passiveMode} = shift;}
  return $self->{passiveMode};
}

sub ResumeMode {
  my $self = shift;
  if (defined $_[0]) {$self->{resumeMode} = shift;}
  return $self->{resumeMode};
}

sub Timeout {
  my $self = shift;
  return $self->{timeout};
}

sub Reconnects {
  my $self = shift;
  return $self->{reconnects};
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
  $remoteFile =~ s{\\}{\/}g;   #convert back slashes to forward slashes

  my $localFileSize = Utils::FileSize($localFile);

  if ($self->{verbose}) {
    print 'Uploading '.basename($localFile).' to FTP site '.$self->Host()." ...\n";
  }
  elsif ($localFileSize) {
    print 'Uploading '.basename($localFile).':    ';
  }

  #check the file to upload exists
  unless (-e $localFile) {
    $self->HandleError("Local file $localFile does not exist");
  }

  #check remote dir exists and create it if it doesn't
  my $remoteDir = dirname($remoteFile);
  unless ($self->DirExists($remoteDir)) {
    $self->MakeDir($remoteDir);
  }

  #if a file with same name as the remote file already exists delete it (even if it has different case)
  if (my $actualFileName = $self->FileExists($remoteFile)) {
    $self->DeleteFile($actualFileName);
  }

  #create a temporary file name in the remote directory for uploading to
  my $tmpFile = $self->CreateTemporaryFile($remoteDir);

  #send the file
  if ($self->ResumeMode()) {
    $self->SendFileWithResume($localFile, $tmpFile);
  }
  else {
    if ($self->{verbose} and $localFileSize) {
      print "Upload progress: ";
    }
    $self->DisplayProgress($localFileSize);
    $self->SendFileWithoutResume($localFile, $tmpFile);
  }

  #rename the temporary file to the final remote file name
  $self->MoveFile($tmpFile, $remoteFile);

  if ($self->{verbose} > 1) {
    print "Upload successful. Stored as $remoteFile on FTP site.\n";
  }
}

sub GetFile {
  my $self = shift;
  my $remoteFile = shift;
  my $localFile = shift;

  unless (defined $localFile and defined $remoteFile) {
    $self->HandleError("Incorrect args passed to ".ref($self)."::GetFile");
  }

  $remoteFile =~ s{\\}{\/}g;     #convert back slashes to forward slashes

  if ($self->{verbose}) {
    print "Downloading ".$remoteFile." from FTP site ".$self->Host()." ...\n";
  }
  else {
    print "Downloading ".basename($remoteFile).":    ";
  }

  #check that the file to download exists
  my $actualFileName;
  unless ($actualFileName = $self->FileExists($remoteFile)) {
    $self->HandleError("Remote file $remoteFile does not exist");
  }

  $remoteFile = $actualFileName;  #handles case sensitivity correctly


  #check local dir exists and create it if it doesn't
  my $localDir = dirname($localFile);
  unless (-e $localDir) {
    Utils::MakeDir($localDir);
    if ($self->{verbose}) {
      print "Created directory $localDir on local drive\n";
    }
  }

  my $remoteFileSize = $self->FileSize($remoteFile);

  if ($self->{verbose} and $remoteFileSize) {
    print "Download progress: ";
  }

  #get the file
  if ($self->ResumeMode()) {
    $self->DisplayProgress($remoteFileSize);
    $self->GetFileWithResume($remoteFile, $localFile);
  }
  else {
    $self->DisplayProgress($remoteFileSize);
    $self->GetFileWithoutResume($remoteFile, $localFile);
  }

  if ($self->{verbose} > 1) {
    print "Download successful. Stored as $localFile on local site.\n";
  }
}

sub FileExists {
  my $self = shift;
  my $remoteFile = shift;

  unless (defined $remoteFile) {
    return 0;
  }

  #use Carp qw/cluck/;
  #cluck "Called FileExists";

  # List the directory the file is in, and see if the file name is in it.
  $remoteFile =~ s{\/}{\\}g;     #convert forward slashes to back slashes
  (my $path, my $baseName, my $ext) = Utils::SplitFileName($remoteFile);
  my $fileName = $baseName . $ext;
  $path =~ s/\\$//;       #remove trailing slash
  $path =~ s/\\/\//g;     #convert back slashes to forward slashes
  my $ls = $self->DirList($path);
  print "Checking for existence of remote file \"$remoteFile\" by looking for \"$fileName\" in \"$path\".\n" if ($self->{verbose} && $ls);
  return 0 unless $ls; # definitely doesn't exist if nothing in the directory

  my @present = grep /(\/|\\|^\s*)\Q$fileName\E\s*$/i, @$ls;
  if (@present) {
    print "Have found file: YES\n" if ($self->{verbose});
    $present[0] = $path."/".$present[0] if ( $present[0] !~ /\// );
    return $present[0];
  }
  else {
    print "Have found file: NO\n" if ($self->{verbose});
    return 0;
  }
}

sub DirList {
  my $self = shift;
  my $remoteDir = shift;

  print "Listing FTP directory $remoteDir\n" if ($self->{verbose});

  my $dirlist_retries = 3;

  $remoteDir =~ s{\\}{\/}g;   #convert back slashes to forward slashes

  my $retry;
  for ($retry = 0; $retry < $dirlist_retries; $retry++) {

    unless ($self->Connected()) {
      $self->Connect();
    }

    # The Net::FTP module that we're using here has two options for listing the contents
    # of a directory. They are the 'ls' and 'dir' calls.
    # The 'ls' call is great, and just returns a list of the items. But, irritatingly, it
    # misses out directories: the returned list just contains names of *files*.
    # dir is better, in some ways, as it lists directories too, but its output format
    # varies from one FTP site to the next. So we have to stick with ls.
    print "About to call dir(\"$remoteDir\")\n" if ($self->{verbose});
    my $ls = $self->{ftp}->ls($remoteDir);
    my $resp = $self->{ftp}->message;
    print "FTP response to list command was \"$resp\"\n" if ($self->{verbose});
    if (ref $ls) {
      print "FTP dir returned \"$ls\" which is a ".(ref $ls)." containing ".(scalar @$ls)." items\n" if ($self->{verbose});
      $ls = undef if ($resp eq ""); # if we didn't get "Opening BINARY mode connection..." or something similar, then we've
        # come across the problem where Net::FTP says Net::FTP: Unexpected EOF on command channel at d:/reltools/2.6x/personal/bin/Net
        # /FTP/dataconn.pm line 73. Unfortunately, it doesn't die, and it returns an empty array, so the only way to find out this has
        # happened is to check message.
      $ls = undef if ($resp =~ m/^connection closed/i);
    }
    # $ls might now be undef
    if (ref($ls)) {
      return $ls;
    }
    else {
      if ($self->Connected()) {
        return undef;
      }
      else {
        print "Warning: Listing of \"$remoteDir\" failed due to an FTP site problem: " . $self->{ftp}->message . ". ";
        if ($self->PassiveMode()) {
          print "PASV mode FTP is currently enabled. This can cause connectivity issues under certain circumstances. ",
            "To disable, remove the pasv_transfer_mode directive from your reltools.ini file.\n";
        }
        else {
          print "PASV mode FTP is currently disabled. Enabling it can prevent connectivity issues under certain circumstances. ",
            "To enable, add the pasv_transfer_mode directive to your reltools.ini file.\n";
        }
        # Fall through to next loop iteration
      }
    }
  }
  die "Error: have tried to list \"$remoteDir\" $retry times with no success - giving up\n";
}

sub MakeDir {
  my $self = shift;
  my $remoteDir = shift;

  $remoteDir =~ s{\\}{\/}g;   #convert back slashes to forward slashes

  unless ($self->Connected()) {
    $self->Connect();
  }

  if ($self->{ftp}->mkdir($remoteDir, 1)) {
    if ($self->{verbose}) {
      print "Created directory $remoteDir on FTP site\n";
    }
  }
  else {
    if ($self->Connected()) {
      $self->HandleError("Cannot make directory $remoteDir on FTP site");
    }
    else {
      $self->MakeDir($remoteDir);
    }
  }
}

sub FileSize {
  my $self = shift;
  my $file = shift;

  $file =~ s{\\}{\/}g;   #convert back slashes to forward slashes

  unless ($self->Connected()) {
    $self->Connect();
  }

  my $size;
  if (defined($size = $self->{ftp}->size($file))) {
    return $size;
  }
  else {
    if ($self->Connected()) {
      return 0;
    }
    else {
      $self->FileSize($file);  #try to get the size again after reconnecting
    }
  }
}

sub DeleteFile {
  my $self = shift;
  my $file = shift;

  $file =~ s{\\}{\/}g;   #convert back slashes to forward slashes

  unless ($self->Connected()) {
    $self->Connect();
  }

  if ($self->{ftp}->delete($file)) {
    return;
  }
  elsif ($self->{ftp}->rmdir($file)) {
    return;
  }
  else {
    if ($self->Connected()) {
      $self->HandleError("Cannot delete $file on FTP site");
    }
    else {
      $self->DeleteFile($file);
    }
  }
}

sub MoveFile {
  my $self = shift;
  my $oldFile = shift;
  my $newFile = shift;

  $oldFile =~ s{\\}{\/}g;   #convert back slashes to forward slashes
  $newFile =~ s{\\}{\/}g;   #convert back slashes to forward slashes

  unless ($self->Connected()) {
    $self->Connect();
  }

  if ($self->{ftp}->rename($oldFile, $newFile)) {
    return;
  }
  else {
    if ($self->Connected()) {
      $self->HandleError("Cannot move $oldFile to $newFile on FTP site");
    }
    else {
      $self->MoveFile($oldFile, $newFile);
    }
  }
}

sub FileModifiedTime {
  my $self = shift;
  my $file = shift;

  $file =~ s{\\}{\/}g;   #convert back slashes to forward slashes

  unless ($self->Connected()) {
    $self->Connect();
  }

  my $modifiedTime;
  if (defined($modifiedTime = $self->{ftp}->mdtm($file))) {
    return $modifiedTime;
  }
  else {
    if ($self->Connected()) {
      print "Warning: failed to find modified time for file \"$file\"\n";
      return undef;
    }
    else {
      $self->FileModifiedTime($file);
    }
  }
}

#
# Private
#

sub Connect {
  my $self = shift;

  unless ($self->Host()) {
    $self->HandleError("Cannot connect FTP host name not defined");
  }
  my $debug = (($self->{verbose} && $self->{verbose} > 1) ? 1 : 0);

  #Attempt to connect (or reconnect if connection fails)
  for (1..$self->Reconnects()) {
    $self->{ftp} = undef;
    if ($self->{verbose}) {
      print "Connecting to FTP site ".$self->Host()."...\n";
    }
    $self->{ftp} = Net::FTP->new($self->Host(),
				 Passive => $self->PassiveMode(),
				 Debug => $debug,
				 Timeout => $self->Timeout());
    if (defined $self->{ftp}) {
      #login to FTP site
      $self->{ftp}->login($self->Username(), $self->Password())
	or $self->HandleError("FTP login failed");

      #change transfer mode to binary
      $self->{ftp}->binary()
	or $self->HandleError("Failed to set FTP server to binary transfer mode");
      return;
    }
  }
  $self->HandleError("Cannot connect to FTP site ".$self->Host());
}

sub Connected {
  my $self = shift;
  return (defined $self->{ftp} and defined $self->{ftp}->pwd);
}

sub SendFileWithResume {
  my $self = shift;
  my $localFile = shift;
  my $remoteFile = shift;

  #open the local file for reading
  $self->{localfh} = IO::File->new("< $localFile");
  binmode($self->{localfh});

  my $localFileSize = Utils::FileSize($localFile);

  my $buffer;
  my $bytesSent;
  my $totalBytesSent = 0;

 RESUME:
  #Open the temporary file on the FTP site for writing/appending
  $self->{dataconn} = $self->OpenRemoteFileForAppending($remoteFile);

  if ($self->{verbose} and $localFileSize) {
    print "Upload progress:    ";
  }

  #upload temporary file in blocks
  while ($self->{localfh}->read($buffer, BLOCKSIZE)) {
    eval {
      $bytesSent = $self->{dataconn}->write($buffer, length($buffer));
    };
    unless ($bytesSent) {
      if (my $ftpResponse = $self->{ftp}->getline()) {
        $self->{ftp}->ungetline($ftpResponse);
        next if ($ftpResponse !~ m/^(3|4|5)/);
        chomp $ftpResponse;
        print "\nError: The FTP server returned \'$ftpResponse\'\n";
      }
      
      if ($self->Connected()) {
	$self->HandleError("Cannot append to remote file $remoteFile");
      }
      else {
	#connection dropped. Reconnect and resume upload
	if ($self->{verbose}) {print "\n"}
	$self->Connect();
	$totalBytesSent = $self->FileSize($remoteFile);
	seek($self->{localfh}, $totalBytesSent, 0);
	goto RESUME;
      }
    }
    else {
      $totalBytesSent += $bytesSent;
      $self->UpdateProgress($totalBytesSent, $localFileSize);
    }
  }

  #close the remote and local files now the transfer has finished
  $self->CloseAllOpenFiles();
}

sub SendFileWithoutResume {
  my $self = shift;
  my $localFile = shift;
  my $remoteFile = shift;

  my $putSuccess;
  eval {
    $putSuccess = $self->{ftp}->put($localFile, $remoteFile);
  };
  unless ($putSuccess) {
    $self->HandleError("Problem occurred during FTP upload of $localFile");
  }
}

sub GetFileWithResume {
  my $self = shift;
  my $remoteFile = shift;
  my $localFile = shift;

  my $totalBytesReceived = 0;
  my $getSuccess;

 RESUME:
  unless ($self->Connected()) {
    $self->Connect();
  }

  eval {
    $getSuccess = $self->{ftp}->get($remoteFile, $localFile, $totalBytesReceived);
  };

  unless ($getSuccess or !$@) {
    if ($self->Connected()) {
      $self->HandleError("Problem occurred during FTP download of $remoteFile");
    }
    else {
      $totalBytesReceived = Utils::FileSize($localFile);
      goto RESUME;
    }
  }
}

sub GetFileWithoutResume {
  my $self = shift;
  my $remoteFile = shift;
  my $localFile = shift;

  unless ($self->Connected()) {
    $self->Connect();
  }

  my $getSuccess;
  eval {
    $getSuccess = $self->{ftp}->get($remoteFile, $localFile);
  };
  unless ($getSuccess) {
    $self->HandleError("Problem occurred during FTP download of $remoteFile");
  }
}

sub DirExists {
  my $self = shift;
  my $remoteDir = shift;

  $remoteDir =~ s{\\}{\/}g;     #convert back slashes to forward slashes

  unless ($self->Connected()) {
    $self->Connect();
  }

  my $pwd = $self->{ftp}->pwd() or $self->HandleError("Problem reading current working directory on FTP site\n");
  my $exists = 0;
  if ($self->{ftp}->cwd($remoteDir)) {
    $exists = 1;
    $self->{ftp}->cwd($pwd) or $self->HandleError("Problem changing current working directory back to $pwd on FTP site\n");
  }

  return $exists;
}


sub OpenRemoteFileForAppending {
  my $self = shift;
  my $remoteFile = shift;

  unless ($self->Connected()) {
    $self->Connect();
  }

  my $dataconn;
  if (defined($dataconn = $self->{ftp}->appe($remoteFile))) {
    return $dataconn;
  }
  else {
    if ($self->Connected()) {
      $self->HandleError("Cannot open $remoteFile for appending on FTP site");
    }
    else {
      $self->OpenRemoteFileForAppending($remoteFile);
    }
  }
}

sub CloseAllOpenFiles {
   my $self = shift;

  if ($self->{localfh}) {
    $self->{localfh}->close;
    $self->{localfh} = undef;
  }
  if ($self->{dataconn}) {
    $self->{dataconn}->close();
    $self->{dataconn} = undef;
  }
}

sub DisplayProgress {
  my $self = shift;
  my $total = shift;

  my $numHashes = 50;
  my $bytesPerHash = int $total / $numHashes;
  if ($total) {
    $self->{ftp}->hash(\*STDERR, $bytesPerHash);
  }
}

sub UpdateProgress {
  my $self = shift;
  my $current = shift;
  my $total = shift;

  my $bytesPerPercent = int $total/100;
  if ($current == $total) {
    print "\b\b\b100%\n";
  }
  elsif ($bytesPerPercent == 0) {
    print "\b\b0%";
  }
  else {
    my $percentComplete = int $current/$bytesPerPercent;
    if ($percentComplete < 10) {
      print "\b\b$percentComplete%";
    }
    else {
      print "\b\b\b$percentComplete%";
    }
  }
}

sub HandleError {
  my $self = shift;
  my $errorString = shift;

  if (defined $self->{ftp}) {
    $self->{ftp}->quit();
    $self->{ftp} = undef;
  }
  $self->CloseAllOpenFiles();

  #call the super class error handler
  $self->SUPER::HandleError($errorString);
}

sub CreateTemporaryFile {
  my $self = shift;
  my $remoteDir = shift;

  my $fileNum = 10000;
  my $tmpFile = $remoteDir.'/lpdrt'.$fileNum.'.tmp';
  while ($self->FileExists($tmpFile)) {
    ++$fileNum;
    $tmpFile = $remoteDir.'/lpdrt'.$fileNum.'.tmp';
  }
  return $tmpFile;
}


#
# Destructor
#

sub DESTROY {
  my $self = shift;

  $self->CloseAllOpenFiles();

  if (defined $self->{ftp}) {
    if ($self->{verbose}) {
      print "Dropping connection to FTP site ".$self->Host()."\n";
    }
    $self->{ftp}->quit();
    $self->{ftp} = undef;
  }
}

1;

=head1 NAME

RemoteSite::FTP.pm - Access a remote FTP site.

=head1 SYNOPSIS

 use RemoteSite::FTP;

 $ftp = RemoteSite::FTP->New(host => 'ftp.somehost.com',
	         	     username => 'myusername',
			     password => 'mypassword',
			     verbose => 1);

 if ($ftp->FileExists('/somedir/someremotefile')) {
   do something...
 }
 $ftp->SendFile('somelocalfile', 'someremotefile');
 $ftp->GetFile('someremotefile', 'somelocalfile');

=head1 DESCRIPTION

C<RemoteSite::FTP> is inherited from the abstract base class C<RemoteSite>, implementing the abstract methods required for transfer of files to and from a remote site when the remote site is an FTP server.

=head1 INTERFACE

=head2 New

Passed an argument list in the form of hash key value pairs. The supported arguments are...

  host             => $host_address_string
  username         => $user_name_string
  password         => $pass_word_string
  passiveMode      => $passive_mode_bool
  resumeTransfers  => $resume_transfers_bool
  timeout          => $timeout_integer
  reconnects       => $reconnects_integer
  verbose          => $verbosity_integer

Returns a reference to a C<RemoteSite::FTP> object

=head2 Host

Returns the current value of the C<host> attribute which contains the host FTP address. If passed an argument sets the attribute to this new value.

=head2 Username

Returns the current value of the C<username> attribute which stores the user name required to access the FTP site. If passed an argument sets the attribute to this new value.

=head2 Password

Returns the current value of the C<password> attribute which stores the password required to access the FTP site. If passed an argument sets the attribute to this new value.

=head2 SendFile

Passed a local and a remote file name. Uploads the local file to the FTP site. Dies if upload fails

=head2 GetFile

Passed a remote and local file name. Downloads the remote file from the FTP site and stores it on the local drive. Dies if download fails.

=head2 FileExists

Passed a filename (with full path) on the FTP site. Returns a non zero value if the file exists.

=head2 DirList

Passed a directory name. Returns a list of files contained in the directory or undef if fails to read directory

=head2 MakeDir

Passed a directory name. Creates the directory on the FTP site

=head2 DeleteFile

Passed a file name. Deletes the file on the FTP site. Dies if fails

=head2 FileSize

Passed a file name. Returns the size of the file. Returns 0 if fails.

=head2 FileModifiedTime

Passed a file name. Returns the last modified time stamp of the file. Returns undef if fails

=head2 MoveFile

Passed two file names. Renames the first file to the second file name. Dies if fails.

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
