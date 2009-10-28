#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#------------------------------------------------------------------------------
# Name   : Mailer.pm
# Use    : description.

#
# Synergy :
# Perl %name: Mailer.pm % (%full_filespec:  Mailer.pm-3:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Fri Mar 17 16:28:51 2006 %
#
# Version History :
#
# v1.0 (17/03/2006) :
#  - Fist version of the Mailer package.
#  - Only tested the sending of email with text content.
#------------------------------------------------------------------------------
package Mailer;
use strict;
use Net::SMTP;
use MIME::Base64;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.0';
use constant ISIS_LAST_UPDATE => '17/03/2006';


#------------------------------------------------------------------------------
# Package's subroutines
#------------------------------------------------------------------------------
#
# Create a Mailer object!
#
sub new
{
	my $class = shift;
	my @empty;
	bless {
		__sender => shift,
		__recipients => shift,
		__subject => shift || "no subject",
		__content => shift || "",
		__attach => shift || \@empty
		}, $class;
}

#
# Send the Email!
#
sub Send
{
	my ($self) = (shift);
	my $to = '';
	foreach my $item ( @{$self->{__recipients}} )
  {
	  $to = $to.$item.";";
  }
	$to =~ s/(\;)$//;
	
	my $boundary = "MailSend.Boundary.".time();

	my %email = (
            mailfrom => $self->{__sender},
            from => $self->{__sender},
            subject => $self->{__subject},
            mailto => [@{$self->{__recipients}}],
            to => "$to",
            attachments => [@{$self->{__attach}}],
            boundary => "$boundary",
            plaintext => $self->{__content},
            );

	my $service = Net::SMTP->new('mgw.nokia.com');

	if ( $service ) 
  {
  	foreach my $item ( @{$self->{__recipients}} )
    {
    	$self->__SendMail( $service, $item, \%email);
    }
  }
	else 
  {
  	print "Cannot create SMTP object!\n";
  }
}
 
sub __SendMail
{
  #Move call attributes to local attributes
  my ($self, $smtp, $mailto, $mail) = @_; 

  #Local variables
  my $encodedattachment;
  my $file;
  

  
  # Fill the sender's and recipient's address
  $smtp->mail($mail->{from});
  $smtp->to($mailto);

  # Start the mail
  $smtp->data();

  # Send the header
  $smtp->datasend("To: $mail->{to}\n");
  $smtp->datasend("From: $mail->{from}\n");
  $smtp->datasend("Subject: $mail->{subject}\n");
  # adding mime header
  $smtp->datasend("Mime-Version: 1.0\n");
  $smtp->datasend("Content-Type: multipart/mixed\; boundary=$mail->{boundary}\n");
  $smtp->datasend("\n");

  # Send the body - BEGIN
  $smtp->datasend("--$mail->{boundary}\n");
  $smtp->datasend("$mail->{plaintext}\n\n");
  # Send the body - END

  foreach $file (@{$mail->{attachments}})
  {
    # Open attachement
    if (open (FILE, "$file"))
    {
      binmode FILE;
      {
        # Read whole file to variable
        undef $/;
        $encodedattachment = encode_base64(<FILE>);
      }
      close FILE;
    }
    else
    {
      print " Cannot open attachement: $file!!\n"
    }

    # Attachement
    $smtp->datasend("--$mail->{boundary}\n");
    $smtp->datasend("Content-Type: application/octet-stream\; name=\"$file\"\n");
    $smtp->datasend("Content-Disposition: attachment\; filename=\"$file\"\n");
    $smtp->datasend("Content-Transfer-Encoding: base64\n");
    $smtp->datasend("\n");
    $smtp->datasend("$encodedattachment\n\n");
    
  }
  $smtp->datasend("--$mail->{boundary}--\n");
  
  # Finish sending the mail
  $smtp->datasend("\n");
  $smtp->dataend();

  # Close the SMTP connection
  $smtp->quit;

}
  
1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
