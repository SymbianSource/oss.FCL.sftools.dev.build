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
# RemoteSite::FTP::Proxy.pm
#

package RemoteSite::FTP::Proxy;

use strict;
use Net::FTP;

use RemoteSite::FTP;
use vars qw(@ISA);
@ISA=("RemoteSite::FTP");

#
# Initialization 
#

sub Initialize {
  my $self = shift;

  my %args = @_;
  $self->{proxy} = $args{proxy};
  $self->{proxyUsername} = $args{proxy_username};
  $self->{proxyPassword} = $args{proxy_password};

  #if proxy username or password not defined ask for them interactively
  unless ($self->ProxyUsername()) {
    print 'Proxy FTP username: ';
    my $userName = <STDIN>;
    if ($userName) {
      chomp ($userName);
      $self->ProxyUsername($userName);
    }
  }
  unless ($self->ProxyPassword()) {
    print 'Proxy FTP password: ';
    $self->ProxyPassword(Utils::QueryPassword());
  }
  
  #call base class initialization
  $self->SUPER::Initialize(@_);
}

#
# Public getters/setters
#

sub Proxy {
  my $self = shift;
  if (defined $_[0]) {$self->{proxy} = shift;}
  return $self->{proxy};
}

sub ProxyUsername {
  my $self = shift;
  if (defined $_[0]) {$self->{proxyUsername} = shift;}
  return $self->{proxyUsername};
}

sub ProxyPassword {
  my $self = shift;
  if (defined $_[0]) {$self->{proxyPassword} = shift;}
  return $self->{proxyPassword};
}

#
# Private
#

sub Connect {
  my $self = shift;

  unless ($self->Proxy()) {
    $self->HandleError("Cannot connect to proxy, host name not defined");
  }
  unless ($self->Host()) {
    $self->HandleError("Cannot connect to FTP site from proxy, host name not defined");
  } 

  my $debug = (($self->{verbose} > 1) ? 1 : 0);

  #Attempt to connect (or reconnect of connection fails)
  for (1..$self->Reconnects()) {
    $self->{ftp} = undef;    
    if ($self->{verbose}) {
      print "Connecting to proxy server ".$self->Proxy()."...\n";
    }
    $self->{ftp} = Net::FTP->new($self->Proxy(),
				 Passive => $self->PassiveMode(),
				 Debug => $debug,
				 Timeout => $self->Timeout());
    if (defined $self->{ftp}) {
      # code to support Blue Coat proxy ftp server

      if ($self->{ftp}->message =~ /Blue Coat Ftp Service/) {
      # do BC login
      $self->{ftp}->login($self->Username().'@'.$self->Host()." ".$self->ProxyUsername(),
        $self->Password(),
        $self->ProxyPassword())
        or $self->HandleError("FTP via Blue Coat proxy login failed");
      }
      else {
        #login to proxy server
        $self->{ftp}->login($self->ProxyUsername(), $self->ProxyPassword())
          or $self->HandleError("Proxy server login failed");

        #login to ftp site from proxy server
        $self->{ftp}->login($self->Username().'@'.$self->Host(), $self->Password())
          or $self->HandleError("FTP login failed");
        }
      #change transfer mode to binary
      $self->{ftp}->binary()
        or $self->HandleError("Failed to set FTP server to binary transfer mode");
      return; 
    }
  }
  $self->HandleError("Cannot connect to proxy server ".$self->Proxy());
}  

1;

=head1 NAME

RemoteSite::FTP::Proxy.pm - Access a remote FTP site via a proxy.

=head1 SYNOPSIS

 use RemoteSite::FTP::Proxy;

 $ftp = RemoteSite::FTP::Proxy->New(host => 'ftp.somehost.com',
				    username => 'myusername',
				    password => 'mypassword',
				    proxy => 'ftp.proxyhost.com',
				    proxy_username => 'myproxyuser',
				    proxy_password => 'myproxypass',
				    verbose => 1);

 if ($ftp->FileExists('/somedir/someremotefile')) {
   do something...
 }
 $ftp->SendFile('somelocalfile', 'someremotefile');
 $ftp->GetFile('someremotefile', 'somelocalfile'); 

=head1 DESCRIPTION

C<RemoteSite::FTP::Proxy> is inherited from C<RemoteSite::FTP>, it modifies base module methods to implement accessing an FTP site via a proxy server

=head1 INTERFACE

=head2 New

Passed an argument list in the form of hash key value pairs. The supported arguments are...

  host           => $host_address_string
  username       => $user_name_string
  password       => $pass_word_string
  proxy          => $proxy_address_string
  proxy_username => $proxy_username_string
  proxy_password => $proxy_password_string
  verbose        => $verbosity_integer

Returns a reference to a C<RemoteSite::FTP::Proxy> object

=head2 Proxy

Returns the current value of the C<proxy> attribute which contains the proxy FTP address. If passed an argument sets the attribute to this new value.

=head2 ProxyUsername

Returns the current value of the C<proxyUsername> attribute which stores the user name required to access the proxy FTP site. If passed an argument sets the attribute to this new value.

=head2 ProxyPassword

Returns the current value of the C<proxyPassword> attribute which stores the password required to access the proxy FTP site. If passed an argument sets the attribute to this new value.

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
