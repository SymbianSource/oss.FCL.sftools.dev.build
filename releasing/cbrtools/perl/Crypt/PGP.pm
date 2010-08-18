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
# Crypt::PGP.pm
#

package Crypt::PGP;

use strict;

use Crypt;
use vars qw(@ISA);
@ISA=("Crypt");

# Overidden methods from Crypt.pm
 
sub Initialize {
  my $self = shift;

  #check to see if the pgp executable exists
  grep {-x "$_/pgp.exe"} split /;/, $ENV{PATH}
    or die "Error: The PGP executable \"pgp.exe\" does not exist in users path\n";
  
  #call super class method
  $self->SUPER::Initialize();
 
  #check for existence of keyrings and keys
  $self->CheckKeyRings();
}

#
# Implemented abstract methods from Crypt.pm
#

sub DoEncrypt {
  my $self = shift;
  my $plainText = shift;
  my $cipherText = shift;
  my @recipientKeys = @{$_[0]};

  $self->CheckKeyRings();

  #build options list
  my @options = qw(+force +batchmode +verbose=2);
  push @options, '-o '.$self->Quoted($cipherText);
  if ($self->DefaultPath()) {
    push @options, '+PUBRING='.$self->Quoted($self->DefaultPath().'/pubring.pkr');
  }
  my @command = '-e '.$self->Quoted($plainText);
  push @command, @recipientKeys;

  #do encryption
  open PGP, "pgp @options @command 2>NUL |" or die "Error: Encrypt command failed.\n";
  my $unsignedKeyError;
  while (my $line = <PGP>) {
    if ($self->{verbose} > 1) {print $line;}
    if ($line =~ /skipping userid/i) { #check for unsigned key errors
      $unsignedKeyError = 1;
    }	
  }
  close PGP;
  if ($unsignedKeyError) {
    die "Error: Encryption failed. Public keys must be signed with the default signing key\n";
  }
}

sub DoDecrypt {
  my $self = shift;
  my $cipherText = shift;
  my $plainText = shift;
  my $passPhrase = shift;
  
  $self->CheckKeyRings();

  #build options list
  my @options =qw(+force +batchmode +verbose=2);
  push @options, '-o '.$self->Quoted($plainText);
  if ($self->DefaultPath()) {
    push @options, '+SECRING='.$self->Quoted($self->DefaultPath().'/secring.skr');
  }
  push @options, '-z'.$self->Quoted($passPhrase);

  my @command = ('-d '.$self->Quoted($cipherText));

  #do decryption
  open PGP, "pgp @options @command 2>NUL |" or die "Error: Decrypt command failed.\n";
  my ($errorCode, $exitCode);
  while (my $line = <PGP>) {
    if ($self->{verbose} > 1) {print $line;}
    if ($line =~ /error.*?-(\d+)/i) {
      $errorCode = $1;
    } 
    elsif ($line =~ /exitcode.*?(\d+)/i) {
      $exitCode = $1;
    }
  }
  close PGP;

  #handle specific decryption errors
  if (defined $errorCode) {
    if ($errorCode == 11477) {
      die "Error: Decryption of $cipherText failed. No decrypting key available. NO_SECKEY\n";
    } 
    elsif ($errorCode == 11489) {
      die "Error: Decryption of $cipherText failed. BAD_PASSPHRASE\n";
    }
  }	
}

sub GetPublicKeyList {
  my $self = shift;

  my @options = qw(+verbose=2);
  if ($self->DefaultPath()) {
    push @options, '+PUBRING='.$self->Quoted($self->DefaultPath().'/pubring.pkr');
  } 
  my @command = qw(-kv);

  #list and extract keyids
  open PGP, "pgp @options @command 2>NUL |" or die "Error: List keys command failed.\n";
  my @keys;
  while (my $line = <PGP>) {
    if ($line =~ /(0x[0-9a-fA-F]{8})/i) {
      push @keys, $1;
    }
  }
  close PGP;
  return \@keys;
}

sub GetSecretKeyList {
  my $self = shift;

  my @options = qw(+verbose=2);
  if ($self->DefaultPath()) {
    push @options, '+SECRING='.$self->Quoted($self->DefaultPath().'/secring.skr');
  } 
  my @command = qw(-kv);

  #list and extract keyids
  open PGP, "pgp @options @command 2>NUL |" or die "Error: List keys command failed.\n";
  my @keys;
  while (my $line = <PGP>) {
    if ($self->{verbose} > 1) {print $line;}
    if ($line =~ /(0x[0-9a-fA-F]{8})/i) {
      push @keys, $1;
    }
  }
  close PGP;
  return \@keys;
}

#
# Private
#

sub CheckKeyRings {
  my $self = shift;

  if ($self->DefaultPath) {
    unless (-e $self->DefaultPath.'/pubring.pkr') {
      die "Error: PGP public keyring does not exist\n";
    }
    unless (-e $self->DefaultPath.'/secring.skr') {
      die "Error: PGP secret keyring does not exist\n";
    }
  }
  unless (@{$self->PublicKeyList}) {
    die "Error: PGP public keyring is empty\n";
  }
  unless (@{$self->SecretKeyList}) {
    die "Error: PGP secret keyring is empty\n";
  }
}


1;

__END__

=head1 NAME

Crypt::PGP.pm - A wrapper over Network Associates command line PGP tool

=head1 DESCRIPTION

C<Crypt::PGP> is inherited from the abstract base class C<Crypt>, implementing the abstract methods required for PGP encryption, decryption, etc... by calling NAI Inc. PGP command line tool (tested with version 6). For this module to work the PGP executable must have the name C<pgp.exe> and exist in one of the directories defined in the users path.

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
