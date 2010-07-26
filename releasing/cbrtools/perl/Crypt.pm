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

package Crypt;

use strict;

#
# Constructor
#

sub New {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  my %args = @_;
  my $self = {
	      defaultPath => $args{default_path},
	      verbose => $args{verbose}
	     };
  bless $self, $class;
  $self->Initialize();
  return $self;
}

sub Initialize {
  my $self = shift;
  
  #convert defaultPath attribute to correct format
  if ($self->{defaultPath}) {
    $self->DefaultPath($self->{defaultPath});
  }
}

#
# Public getters/setters
#

sub DefaultPath {
  my $self = shift;
  
  if (defined $_[0]) {
    my $defaultPath = shift;
    $defaultPath =~ s/\\/\//g;  #replace '\'s with / 
    $defaultPath =~ s/\/+$//;   #remove trailing '/'s  
    $self->{defaultPath} = $defaultPath;
    delete $self->{publicKeys};   #new default path implies new keyring files so delete  
    delete $self->{secretKeys};   #the current key lists
  }
  return $self->{defaultPath};
}

#
# Public methods
#

sub Encrypt {
  my $self = shift;
  my $plainText = shift;
  my $cipherText = shift;
  my @recipientKeys = @{$_[0]};

  unless (defined $plainText and defined $cipherText and @recipientKeys) {
    die "Error: Incorrect arguments for encryption.\n";
  }
  $plainText=~ s/\\/\//g;  #replace '\'s with /`s
  $cipherText=~ s/\\/\//g;

  if ($self->{verbose} > 1) {
    print "Encrypting $plainText with key(s) ".join(", ",@recipientKeys)."\n";
  }

  unless (-e $plainText) {
    die "Error: Encryption aborted. $plainText does not exist.\n";
  }
  #check to see if all the recipient keys exist on the public keyring
  foreach my $recipientKey (@recipientKeys) {
    $self->PublicKeyExists($recipientKey) 
      or die "Error: Encryption failed. $recipientKey not in keyring.\n";
  }
  
  #call subclass method to actually encrypt file
  $self->DoEncrypt($plainText, $cipherText, \@recipientKeys);
  
  #throw an error if encrypted file not created
  unless (-e $cipherText) {
    die "Error: Encryption of $plainText failed.\n";
  }
}

sub Decrypt {
  my $self = shift;
  my $cipherText = shift;
  my $plainText = shift;
  my $passPhrase = shift;

  unless (defined $plainText and defined $cipherText and defined $passPhrase) {
    die "Error: Incorrect arguments for decryption.\n";
  }
  $plainText=~ s/\\/\//g;  #replace '\'s with /`s
  $cipherText=~ s/\\/\//g;

  if ($self->{verbose} > 1) {
    print "Decrypting $cipherText\n";    
  }

  unless (-e $cipherText) {
    die "Error: Decryption aborted. $cipherText does not exist.\n";
  }
  #call subclass method to actually decrypt file
  $self->DoDecrypt($cipherText, $plainText, $passPhrase);
  
  #throw an error if decrypted file not created
  unless (-e $plainText) {
    die "Error: Decryption of $cipherText failed.\n";
  }	
}

sub PublicKeyList {
  my $self = shift;

  unless (exists $self->{publicKeys}) {
    #call subclass method to get key list
    foreach my $key (@{$self->GetPublicKeyList()}) {
      $self->{publicKeys}->{uc($key)} = 1;
    }	
  }
  my @keys = keys %{$self->{publicKeys}};
  return \@keys;
}

sub SecretKeyList {
  my $self = shift;

  unless (exists $self->{secretKeys}) { 
    #call subclass method to get key list 
    foreach my $key (@{$self->GetSecretKeyList()}) {
      $self->{secretKeys}->{uc($key)} = 1;
    }
  }
  my @keys = keys %{$self->{secretKeys}};
  return \@keys;
}


sub PublicKeyExists {
  my $self = shift;
  my $requiredKey = shift;

  unless (exists $self->{publicKeys}) {
    $self->PublicKeyList();
  }
  return ($self->{publicKeys}->{uc($requiredKey)});
}

sub SecretKeyExists {
  my $self = shift;
  my $requiredKey = $_[0];

  unless (exists $self->{secretKeys}) {
    $self->SecretKeyList();
  }
  return ($self->{secretKeys}->{uc($requiredKey)});
}

#
# Abstract methods (must be implemented in a subclass)
#

sub DoEncrypt {
  die "Error: Call to abstract method ".ref($_[0])."::_DoEncrypt.\n";
}

sub DoDecrypt {
  die "Error: Call to abstract method ".ref($_[0])."::_DoDecrypt.\n";
}

sub GetPublicKeyList {
  die "Error: Call to abstract method ".ref($_[0])."::_GetPublicKeyList.\n";
}

sub GetSecretKeyList {
  die "Error: Call to abstract method ".ref($_[0])."::_GetSecretKeyList.\n";
}

#
# Private methods
#

sub Quoted {
  my $self = shift;
  my $string = $_[0];
  return ($string =~ /^\s*(\".*\")\s*$/) ? $1 : "\"$string\"";
}

1;

=head1 NAME

Crypt.pm - Abstract base class to crypt modules.

=head1 SYNOPSIS

 use Crypt::PGP;

 $crypt = Crypt::PGP->New(default_path => 'somePath/someDir',
                          verbose => 1);

 $crypt->DefaultPath('somedir/anotherdir');
 $defaultpath = $crypt->DefaultPath();

 @publickeys = @{$crypt->PublicKeyList()};
 @secretkeys = @{$crypt->SecretKeyList()};

 $crypt->Encrypt('somefile.txt', 'somefile.pgp', ['0x24534213', '0x1EA3B4DC', '0x8721DACE']);
 $crypt->Decrypt('somefile.pgp', 'somefile.txt', 'mypassphrase');


=head1 DESCRIPTION

C<Crypt> is the abstract base class to a family of modules of the form C<Crypt::>F<PGPTool> which are simple wrappers over PGP command line tools. Each module in the C<Crypt> directory must implement the following abstract interface...

=over 4

=item * DoEncrypt($plainText, $cipherText, \@recipientKeys)

Should encrypt the C<$plainText> file with the public keys C<@recipientKeys> and store the result in the C<$cipherText> file.

=item * DoDecrypt($cipherText, $plainText, $passPhrase)

Should decrypt the C<$cipherText> file using the secret key with pass phrase C<$passPhrase> and store the result in the C<$plainText> file. Must die with C<"BAD_PASSPHRASE"> if passphrase incorrect and C<"NO_SECKEY"> if secret key not available for decrypting file.

=item * array_ref GetPublicKeyList( )

Should return the list of keyids stored on the public keyring.

=item * array_ref GetSecretKeyList( )

Should return the list of keyids stored on the secret keyring.

=back

B<NOTE:> A key id is an 8 digit hexadecimal number preceeded by a zero and an x (or X) e.g 0x12345678, 0X3eDC2A82


=head1 INTERFACE

=head2 New

Passed an argument list in the form of hash key value pairs. The supported arguments are...

  default_path  => $path_string
  verbose       => $verbosity_integer

Returns a reference to an object derived from C<Crypt> (C<Crypt> is abstract so cannot be instantiated)

=head2 DefaultPath

Returns the current value of the C<defaultPath> attribute which stores the path to the users configuration and keyring files. If the C<defaultPath> is undefined then the tools default path is used. If passed a path as an argument sets the C<defaultPath> attribute to this value and updates the public and secret keyring file names. 

=head2 Encrypt

Passed a plain text file name, a cipher text file name and a reference to an array of recipients pgp keyids. Encrypts the plain text file with the recipients keys. Outputs the result to the cipher text file.

=head2 Decrypt

Passed a cipher text file name, a plain text file name and the users private key pass phrase. Decrypts the cipher text file with the users private key and outputs the result to the plain text file.

=head2 PublicKeyList

Returns a reference to an array of keyids for keys stored in the public keyring

=head2 SecretKeyList

Returns a reference to an array of keyids for keys stored in the secret keyring

=head2 PublicKeyExists

Passed a public key id. Returns true if the key exists in the public keyring

=head2 SecretKeyExists

Passed a secret key id. Returns true if the key exists in the secret keyring

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
