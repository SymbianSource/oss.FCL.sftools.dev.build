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
# Name   : RawText.pm
# Use    : Creates a preformatted text using a <PRE> HTML element.

#
# Synergy :
# Perl %name: RawText.pm % (%full_filespec:  RawText.pm-1:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Thu Jan 12 10:13:56 2006 %
#
# Version History :
#
# v1.0 (12/11/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   RawText package.
#
#--------------------------------------------------------------------------------------------------
package OUT::RawText;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '20/12/2005';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::RawText( <text> )\n" if(DBG::RAWTEXT);

  my $class    = shift;
	my $outputer = pop;
	my $text     = join('', @_);
	
  bless { content   => $text,
          _outputer => $outputer,
        }, $class;
}

#--------------------------------------------------------------------------------------------------
# Print function.
#--------------------------------------------------------------------------------------------------
sub Print
{
	warn "OUT::RawText::Print( ".join(', ', @_)." )\n" if(DBG::RAWTEXT);
  my $self     = shift;
  my $outputer = $self->{_outputer};
  my $indent   = $outputer->Indent();

  $outputer->Print("<PRE class=\"raw_text\">\n");
  $outputer->Indent('');
  $outputer->Print($self->{content});
  $outputer->Indent($indent);
  $outputer->Print("</PRE>\n");
}

sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::RAWTEXT);
	$self->{_outputer}->_Accessor($self, $method, @_);
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::RawText - HTML element - A simple raw text for displaying preformatted text.

=head1 SYNOPSIS

	use ISIS::HTMLManip;

	open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;
	my $outputer = new HTMLManip($ostream, 'configuration.xml', 'isis_interface');
	my $rawtext = $outputer->Create('RawText');

=head1 DESCRIPTION

This module creates a simple raw text HTML element using the <pre> HTML element.

=head2 RawText( [TEXT1, [TEXT2, ...]], OUTPUTER ) :

Creates a new raw text html element. This constructor should not be called directly and should be
created via the outputer factory available from the C<L<ISIS::HTMLManip>> module. For more
information, see the perl documentation of C<L<ISIS::HTMLManip>>.

=head2 Content( [TEXT] ) :

Sets or returns the current text associated to the raw text element.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
