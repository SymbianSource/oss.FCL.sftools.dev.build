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
#!/usr/bin/perl -w
#--------------------------------------------------------------------------------------------------
# Name   : Summary.pm
# Use    : Creates a HTML log summary instance.

#
# Synergy :
# Perl %name: Summary.pm % (%full_filespec:  Summary.pm-1:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Mon Feb  6 14:32:00 2006 %
#
# Version History :
#
# v1.0 (13/12/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   OUT::Log::Summary package.
#
#--------------------------------------------------------------------------------------------------

package OUT::Log::Summary;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '13/12/2005';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
	warn "new OUT::Log::Summary( ".join(', ', @_)." )\n" if(DBG::LOG_SUMMARY);

	my ($outputer) = pop;
	$outputer->RequireCSSFile('css/logger2.css');

	bless { _childs   => undef,
          _outputer => $outputer
				}, shift;
}

#--------------------------------------------------------------------------------------------------
# Push Child.
#--------------------------------------------------------------------------------------------------
sub PushChild
{
	warn "OUT::Log::Summary::PushChild( ".join(', ', @_)." )\n" if(DBG::LOG_SUMMARY);
  my $self = shift;
  push @{$self->{_childs}}, shift if(@_);
}

#--------------------------------------------------------------------------------------------------
# Accessor for header, footer and menu.
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
  my ($self, $method) = (shift, our $AUTOLOAD);
  warn "$method( ".join(', ', @_)." )\n" if(DBG::LOG_SUMMARY);
  return if($method =~ /::DESTROY$/ or not exists $self->{$method});
  
  $self->{$method} = shift if (@_);
  return $self->{$method};
}

#--------------------------------------------------------------------------------------------------
# Print.
#--------------------------------------------------------------------------------------------------
sub Print
{
	warn "OUT::Log::Summary::Print( ".join(', ', @_)." )\n" if(DBG::LOG_SUMMARY);
  my $self     = shift;
  my $outputer = $self->{_outputer};
  my $indent   = $outputer->Indent();
  
  $outputer->Print("<div id=\"s_mb\">\n");

  $outputer->Indent($indent . '  ');
  if(defined $self->{_childs})
  { foreach (@{$self->{_childs}}) { $_->Print(); } }
  $outputer->Indent($indent);
  
  $outputer->Print("</div>\n");
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::Log::Summary - A simple HTML template document for log files.

=head1 SYNOPSIS

	use ISIS::HTMLManip;
	
	open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;
	my $outputer = new HTMLManip($ostream, 'configuration.xml', 'isis_interface');
	my $document = $outputer->Create('LogDocument');
	
	# add childs to the document ...
	
	$document->Print();
	close($ostream);

=head1 DESCRIPTION

This package provides a simple HTML template body for log files, with a header,
body, and footer parts as described below :

=begin text

	+--------------------+
	| header             |
	+--------------------+
	|                    |
	| main body          |
	|                    |
	+--------------------+
	| footer             |
	+--------------------+

=end text

=head2 Header(  ) :

Set or return the current header for the document. By default, the document doesn't
have any header.

=head2 Footer(  ) :

Set or return the current footer for the document. By default, the document doesn't
have any footer.

=head2 PushChild( CHILD ) :

Add a child to the document main body. The childs will be printed automatically in
the order they are pushed.

=head2 Print(  ) :

Prints the full HTML document to the output stream attached to the outputer created
with 'ISIS::HTMLManip'. This should be the only 'Print' subroutine called in the script
using 'ISIS::HTMLManip' since all sub elements' Print subourtine will be called
automatically. for more information, see its documentation.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
