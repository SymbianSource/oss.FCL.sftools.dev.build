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
# Crypt::GPG.pm
#

package Crypt::GPG;

use strict;
use File::Basename;
use IPC::Open2;
use IO::Handle;

use Crypt;
use vars qw(@ISA);
@ISA=("Crypt");

# Overidden methods from Crypt.pm

sub Initialize {
  my $self = shift;

  #check to see if the pgp executable exists
  grep {-x "$_/gpg.exe"} split /;/, $ENV{PATH}
    or die "Error: The PGP executable \"gpg.exe\" does not exist in users path\n";

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
  my @options = qw(--batch --no-tty --yes --always-trust);
  push @options, '--status-fd 1';
  push @options, '-o '.$self->Quoted($cipherText);
  if ($self->DefaultPath()) {
    push @options, '--homedir '.$self->Quoted($self->DefaultPath());
  }
  foreach my $key (@recipientKeys) {
    if ($key =~ /^0x([0-9a-fA-F]{8})$/i) {
      push @options, '-r '.$1;
    }
  }
  my @command = '-e '.$self->Quoted($plainText);

  # Do encryption. This occasionally fails due to GPG failing to read
  # the random_seed file when we get a return value of 2. Until we get
  # a later version of gpg checked as compatible, just retry if this happens.
  my $retries = 2;
  my $retval;
  do {
      my $cmd = "gpg @options @command";
      print "Executing command: $cmd\n" if $self->{verbose} > 1;
      open GPG, "$cmd 2>&1 |" or die "Error: Encrypt command failed.\n";
      my $error;
      while (my $line = <GPG>) {
        if ($self->{verbose} > 1) {
          print "\t$line";
        }
      }
      close GPG;
      $retval = $? >> 8;
      $retries = 0 unless( $retval == 2 );  # Only retry if retval is 2.
      if( $retval ) {
        print "WARNING: GPG failure. Error code $retval. ";
        print "Retrying GPG..." if( $retries > 0 );
        print "\n";
      }
  } while( $retries-- > 0 );
  die "ERROR: GPG returned error code $retval.\n" if ($retval > 0);
}

sub DoDecrypt {
  my $self = shift;
  my $cipherText = shift;
  my $plainText = shift;
  my $passPhrase = shift;

  $self->CheckKeyRings();

  #build options list
  my @options = qw(--batch);
  push @options, '--status-fd 1';
  push @options, '--passphrase-fd 0';
  push @options, '-o '.$self->Quoted($plainText);
  if ($self->DefaultPath()) {
    push @options, '--homedir '.$self->Quoted($self->DefaultPath());
  }
  my @command = '-d '.$self->Quoted($cipherText);

  #do decryption reading passphrase from STDIN writing output to log file
  my $gpgOutput = '/gpg_output.log';
  my $cmd = "gpg @options @command";

  # retry 100 times of GPG and opening GPG output
  my $retries = 100;
  while ($retries > 0) {
    print "Executing command: $cmd\n" if $self->{verbose} > 1;
    if (open GPGIN, "| $cmd 2>NUL 1> $gpgOutput") {
      print GPGIN "$passPhrase\n";
      while (my $line  = <GPGIN>) {
      }
      close GPGIN;
	  
      #open output of gpg command from file for parsing
      if (open GPGOUT, "$gpgOutput") {
        #open output of gpg successfully, then jump out and go ahead
        last;
      }
      else {
        print "Warning: Cannot open gpg output file, $!\n";
      }
    }
    else {
      print "Warning: Error: Decrypt command failed, $!\n";
    }
    $retries--;

    # sleep 10 seconds for next try
    sleep(10);
  }
  die "Error: Cannot create or open output log file for $cipherText.\n" if ($retries<=0);
  
  my $badPassPhrase =0;
  my %enc_to;
  my %no_seckey;
  my $keyTally = 0;
  my $useKeyTally = 0; # Fallback for if parsing fails
  while (my $line = <GPGOUT>) {
    if ($self->{verbose} > 1) {
      print "\t$line";
    }
    next if ($line =~ /^\s*$/);
    if ($line =~ /BAD_PASSPHRASE/) {
      $badPassPhrase = 1;
    }
    elsif ($line =~ /GOOD_PASSPHRASE/) {
      $badPassPhrase = 0;
    }
    elsif ($line =~ /ENC_TO/) {
      if ($line =~ /ENC_TO\s+([\dA-F]*)/) {
        $enc_to{$1} = $1; # Value is unimportant
      } else {
        $useKeyTally = 1;
      }
      --$keyTally;
    }
    elsif ($line =~ /NO_SECKEY/) {
      if ($line =~ /NO_SECKEY\s+([\dA-F]*)/) {
        $no_seckey{$1} = $1; # Value is unimportant
      } else {
        $useKeyTally = 1;
      }
      --$keyTally;
    }
  }
  close GPGOUT;
  my $retval = $? >> 8;
  unlink $gpgOutput;

  if (!$useKeyTally) {
    foreach my $key (keys(%no_seckey)) {
      delete $no_seckey{$key};
      if (exists $enc_to{$key}) {
        delete $enc_to{$key};
      } else {
        die "Error: Parsing of GPG output failed. Got a NO_SECKEY for no corresponding ENC_TO.\n";
      }
    }
    $keyTally = scalar(keys(%enc_to)); # Number of private keys
  }

  #handle specific decryption errors
  if ($badPassPhrase and $keyTally != 0) {
    die "Error: Decryption of $cipherText failed. BAD_PASSPHRASE\n";
  }
  elsif ($keyTally == 0) {
    die "Error: Decryption of $cipherText failed. No decrypting key available. NO_SECKEY\n";
  }
  elsif ($keyTally < 0) {
    # Parsing failed, and we got spurious NO_SECKEY messages
    die "Error: Parsing of GPG output failed. Too many NO_SECKEYs\n";
  }
  die "Error code returned by gpg: $retval.\n" if ($retval > 0);
}

sub GetPublicKeyList {
  my $self = shift;

  my @options;
  if ($self->DefaultPath()) {
    push @options, '--homedir '.$self->Quoted($self->DefaultPath());
  }
  my @command = qw(--list-keys);

  #list and extract keyids
  open GPG, "gpg @options @command 2>&1 |" or die "Error: List keys command failed.\n";
  my @keys;
  while (my $line = <GPG>) {
    if ($line =~ /^pub.*?([0-9a-fA-F]{8})\b/i) {
      push @keys, '0x'.$1;
    }
  }
  close GPG;
  return \@keys;
}

sub GetSecretKeyList {
  my $self = shift;

  my @options;
  if ($self->DefaultPath()) {
    push @options, '--homedir '.$self->Quoted($self->DefaultPath());
  }
  my @command = qw(--list-secret-keys);

  #list and extract keyids
  open GPG, "gpg @options @command 2>&1 |" or die "Error: List keys command failed.\n";
  my @keys;
  while (my $line = <GPG>) {
    if ($line =~ /^sec.*?([0-9a-fA-F]{8})\b/i) {
      push @keys, '0x'.$1;
    }
  }
  close GPG;
  return \@keys;
}
#
# Private
#

sub CheckKeyRings {
  my $self = shift;

  if ($self->DefaultPath) {
    unless (-e $self->DefaultPath.'/pubring.gpg') {
      die "Error: PGP Public keyring does not exist\n";
    }
    unless (-e $self->DefaultPath.'/secring.gpg') {
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

Crypt::GPG.pm - A wrapper over the Gnu Privacy Guard command line PGP tool

=head1 DESCRIPTION

C<Crypt::GPG> is inherited from the abstract base class C<Crypt>, implementing the abstract methods required for PGP encryption, decryption, etc... by calling Gnu Privacy Guard PGP command line tool (tested with version 1.0.6). For this module to work the PGP executable must have the name C<gpg.exe> and exist in one of the directories defined in the users path.

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
