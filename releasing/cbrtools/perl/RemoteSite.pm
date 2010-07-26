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

package RemoteSite;

use strict;
use File::Basename;
use Utils;

#
# Constructor
#

sub New {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  my $self = {
	      host => undef,
	      verbose => 0
	     };
  bless $self, $class;
  $self->Initialize(@_);
  return $self;
}

sub Initialize {
  my $self = shift;

  my %args = @_;
  $self->{host} = $args{host};
  $self->{verbose} = $args{verbose};
}

#
# Public getters/setters
#

sub Host {
  my $self = shift;
  if (defined $_[0]) {$self->{host} = shift;}
  return $self->{host};
}

#
# Private Methods
#

sub HandleError {
  my $self = shift;
  my $errorString = shift;

  die "Error: $errorString\n";
}

#
# Abstract methods (must be implemented in a subclass)
#

sub SendFile {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::SendFile.\n";
}

sub GetFile {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::GetFile.\n";
}

sub FileExists {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::FileExists.\n"; 
}

sub DirList {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::DirList.\n";
}

sub MakeDir {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::MakeDir.\n";
}

sub FileSize {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::FileSize.\n";
}

sub DeleteFile {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::DeleteFile.\n";
}

sub MoveFile {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::MoveFile.\n";
}

sub FileModifiedTime {
  die "Error: Call to unimplemented abstract method ".ref($_[0])."::FileModifiedTime.\n";
}



1;

=head1 NAME

RemoteSite.pm - Abstract base module for remote site access

=head1 DESCRIPTION

C<RemoteSite> is the abstract base module to a family of modules of the form C<RemoteSite::>F<HostType> which are used to transfer files to and from a remote site. Each module in the C<RemoteSite> directory must implement the following abstract interface...

=over 4

=item * SendFile($localFile, $remoteFile)

Should copy C<$localFile> from the local drive to C<$remoteFile> on the remote site.

=item * GetFile($remoteFile, $localFile)

Should copy C<$remoteFile> from the remote site to C<$localFile> on the local drive.

=item * bool FileExists($remoteFile)

Should return a non zero value if C<$remoteFile> exists or zero if not.

=back

If no connection can be made to the remote site then the module must throw an error containing the words C<"cannot connect">

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
