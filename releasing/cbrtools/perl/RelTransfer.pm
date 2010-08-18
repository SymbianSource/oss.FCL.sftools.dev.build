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

package RelTransfer;

use strict;
use Utils;

#
# Constructor
#

sub New {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  my %args = @_;
  my $self = {iniData => $args{ini_data},
	      verbose => $args{verbose},
	      force => $args{force},
        dummy => $args{dummy},
	excludeSource => $args{excludeSource},
        pgpPassPhrase => $args{passphrase}
	     };
  
  if($self->{excludeSource}){
    PrintHeinousWarning();
  }
  
  $self->{verbose} ||= 1 if $self->{dummy};
  bless $self, $class;
  $self->Initialize();
  return $self;
}

sub Initialize {
  my $self = shift;
  
  Utils::InitialiseTempDir($self->{iniData});   #create and initialize temp dir
  $self->{crypt} = $self->CreateCrypt();            #create a Crypt:: object
  $self->{remoteSite} = $self->CreateRemoteSite();  #create a RemoteSite:: object
}

sub PrintHeinousWarning {
  Utils::QueryUnsupportedTool(<<GUILTY, 0);  # Set $reallyrun as 0
Warning: The use of the -e flag is for internal use only. Using the -e flag can corrupt an export archive if used incorrectly. Please ensure that the target export archive is specifically for non source releases. Export archives should not contain releases which contain both source and non source.

Do you want to continue? (y/n)
GUILTY
}

sub CreateCrypt {
  my $self = shift;

  my $module = 'Crypt::'.$self->{iniData}->PgpTool;
  eval "require $module";
  my $crypt = $module->New(default_path => $self->{iniData}->PgpConfigPath(),
			   verbose => $self->{verbose});
  return $crypt;
}

sub CreateRemoteSite {
  my $self = shift;

  my $module = 'RemoteSite::'.$self->{iniData}->RemoteSiteType();
  eval "require $module";  
  my $remote = $module->New(host => $self->{iniData}->RemoteHost(),
			    username => $self->{iniData}->RemoteUsername(),
			    password => $self->{iniData}->RemotePassword(),
			    passive_mode => $self->{iniData}->PasvTransferMode(),
			    resume_mode => $self->{iniData}->FtpServerSupportsResume(),
			    proxy => $self->{iniData}->Proxy(),
			    proxy_username => $self->{iniData}->ProxyUsername(),
			    proxy_password => $self->{iniData}->ProxyPassword(),
			    timeout => $self->{iniData}->FtpTimeout(),
			    reconnects => $self->{reconnects},
			    max_export_volume_size => $self->{iniData}->MaxExportVolumeSize(),
			    verbose => $self->{verbose});
  return $remote;
}

#
# Abstract methods
#

sub TransferRelease {
  my $self = shift;
  $self->HandleError("Call to abstract method ".ref($_[0])."::TransferRelease");
}

#
# Private
#

sub PathData {
  my $self = shift;
  return $self->{iniData}->PathData;
}

sub ReleaseExistsInLocalArchive {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  my $path = $self->PathData->LocalArchivePathForExistingComponent($comp, $ver); # undef if component doesn't exist
  return ($path && -d $path);
}

sub ReleaseExistsOnRemoteSite {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  
  my $relDir = $self->PathData->RemoteArchivePathForExistingComponent($comp, $ver, $self->{remoteSite});
  return 0 unless $relDir;
  return 1; # if RemoteArchivePathForExistingComponent returns a true value, then it exists
}

sub CleanupTempDir {
  my $self = shift;
  my $tempDir = Utils::TempDir();

  print "Cleaning \"$tempDir\"...\n" if ($self->{verbose} > 1);

  opendir(DIR, $tempDir) or die "Error: cannot open $tempDir\n";
  my @allFiles = grep {$_ ne '.' and $_ ne '..'} map {"$tempDir/$_"} readdir DIR;
  closedir(DIR);
  unlink @allFiles;
}

sub HandleError {
  my $self = shift;
  my $errorString = shift;
  
  die "Error: $errorString\n";
}

#
# Destructor
#

sub DESTROY {
  my $self = shift;

  if (-e Utils::TempDir()) {
    Utils::RemoveTempDir();
  }
}

1;

__END__

=head1 NAME

RelTransfer.pm - Base class for modules used to export and import releases

=head1 DESCRIPTION

A typical project involves many development teams working at different locations. To share releases between the various sites a central repositry (e.g typically an FTP server) is setup with each team transferring releases to and from this remote site.

This module is the base class for modules used to export and import single releases between the local archive and the remote site.

The export and import subclass modules must implement the abstract method C<TransferRelease> to perform the actual export/import of the release. 

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
