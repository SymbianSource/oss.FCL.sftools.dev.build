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
# Name   : LogDocument.pm
# Use    : Creates a HTML document instance.

#
# Synergy :
# Perl %name: Document.pm % (%full_filespec:  Document.pm-3:perl:fa1s60p1#1 %)
# %derived_by:  oligrant %
# %date_created:  Thu Apr  6 10:52:15 2006 %
#
# Version History :
# v1.0.1 (05/04/2006)
#  - Updated CSS and JS file dependancy printout to match new storage in Outputer.
#
# v1.0 (13/12/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   OUT::Document package.
#
#--------------------------------------------------------------------------------------------------

package OUT::Log::Document;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => '1.0.1';
use constant ISIS_LAST_UPDATE => '05/04/2006';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
	warn "new OUT::Log::Document( ".join(', ', @_)." )\n" if(DBG::LOG_DOCUMENT);

	my ($outputer) = $_[$#_];

	bless { 'OUT::Log::Document::Header'  => undef,
          'OUT::Log::Document::Footer'  => undef,
          'OUT::Log::Document::Menu'    => undef,
          'OUT::Log::Document::Summary' => undef,
          _childs                       => undef,
          _outputer                     => $outputer
				}, shift;
}

#--------------------------------------------------------------------------------------------------
# Push Child.
#--------------------------------------------------------------------------------------------------
sub PushChild
{
	warn "OUT::Log::Document::PushChild( ".join(', ', @_)." )\n" if(DBG::LOG_DOCUMENT);
  my $self = shift;
  push @{$self->{_childs}}, shift if(@_);
}

#--------------------------------------------------------------------------------------------------
# Accessor for header, footer and menu.
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
  my ($self, $method) = (shift, our $AUTOLOAD);
  warn "$method( ".join(', ', @_)." )\n" if(DBG::LOG_DOCUMENT);
  return if($method =~ /::DESTROY$/ or not exists $self->{$method});
  
  $self->{$method} = shift if (@_);
  return $self->{$method};
}

#--------------------------------------------------------------------------------------------------
# Print.
#--------------------------------------------------------------------------------------------------
sub Print
{
	warn "OUT::Log::Document::Print( ".join(', ', @_)." )\n" if(DBG::LOG_DOCUMENT);
  my $self     = shift;
  my $outputer = $self->{_outputer};
  my $indent   = $outputer->Indent();
  my $iface    = $outputer->Interface();
  my $id       = $outputer->Id();

  $outputer->Print(  
  	"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
    "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n",
    "<html xmlns=\"http://www.w3.org/1999/xhtml\">\n\n",
    "<head>\n",
    "  <title>Nokia Automated Build</title>\n"
  );
  
	foreach my $css (@{$outputer->CSSFiles()}, @{$outputer->UserCSSFiles()})
	{ $outputer->Print("  <link href=\"", $iface, $css, "\" rel=\"stylesheet\" type=\"text/css\" />\n"); }
	
	foreach my $js (@{$outputer->JSFiles()}, @{$outputer->UserJSFiles()})
	{ $outputer->Print("  <script type=\"text/javascript\" src=\"", $iface, $js, "\"></script>\n"); }

  $outputer->Print(
    "</head>\n\n",
    "<body>\n\n",
  );
  
  $outputer->Indent($indent . '  ');
  $self->{'OUT::Log::Document::Header'}->Print() if($self->{'OUT::Log::Document::Header'});
  $outputer->Indent($indent);
  
  $outputer->Indent($indent . '  ');
  $self->{'OUT::Log::Document::Summary'}->Print() if($self->{'OUT::Log::Document::Summary'});
  $outputer->Indent($indent);
  
  $outputer->Print("  <div id=\"mb\">\n");
  
  $outputer->Id($id + 1);
  $outputer->Indent($indent . '    ');
  if(defined $self->{_childs})
  { foreach (@{$self->{_childs}}) { $_->Print(); } }
  $outputer->Indent($indent);
  
  $outputer->Print("  </div>\n");

	$outputer->Indent($indent . '  ');
	$self->{'OUT::Log::Document::Footer'}->Print() if ($self->{'OUT::Log::Document::Footer'});
	$outputer->Indent($indent);

	$outputer->Print(
    "</body>\n\n",
    "</html>\n"
  );
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::Log::Document - A simple HTML template document for log files.

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
