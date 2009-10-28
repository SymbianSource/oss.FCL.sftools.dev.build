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
# Name   : Text.pm
# Use    : Normal HTML text with optional icon.

#
# Synergy :
# Perl %name: Text.pm % (%full_filespec:  Text.pm-10:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Fri Mar 31 14:04:50 2006 %
#
# Version History :
#
# v1.0 (12/11/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   Text package.
#
#--------------------------------------------------------------------------------------------------
package OUT::Text;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;
use HTML::Entities;

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '21/12/2005';

use overload q("") => \&_AsString;

sub _AsString
{
  my ($self) = (shift);
  return $self->{content};
}

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::Text( <text> )\n" if(DBG::TEXT);

  my $class    = shift;
	my $outputer = pop;
	my $text = join('', @_);
	$text =~ s/\n/<br\/>/g;
	&__String2XML($text);

  bless { style     => undef,
  	      content   => $text,
          _outputer => $outputer,
        }, $class;
}

#--------------------------------------------------------------------------------------------------
# Print function.
#--------------------------------------------------------------------------------------------------
sub Print
{
	warn "OUT::Text::Print( ".join(', ', @_)." )\n" if(DBG::TEXT);
  my $self     = shift;
  my $outputer = $self->{_outputer};
  my $indent   = $outputer->Indent();
  
  $self->{style} ||= 'text_default';
 	              
	$outputer->Print("<div class=\"".($self->{style})."\" >\n");
	$outputer->Indent($indent . '  ');
	$outputer->Print($self->{content});
	$outputer->Indent($indent);
	$outputer->Print("</div>\n");
}

sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::TEXT);
	$self->{_outputer}->_Accessor($self, $method, @_);
}

sub __String2XML
{
  my $str = shift || '';
  $str =~ s/\e/e/;
  $str = HTML::Entities::encode_entities($str);
  return $str;
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::Text - HTML element - A simple text element with optional icon.

=head1 SYNOPSIS

	use ISIS::HTMLManip;

	open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;
	my $outputer = new HTMLManip($ostream, 'configuration.xml', 'isis_interface');
	my $rawtext = $outputer->Create('RawText');

=head1 DESCRIPTION

This module creates a simple text HTML element encapsulated in a HTML <div> element.

=head2 Text( [TEXT1, [TEXT2, ...]], OUTPUTER ) :

Creates a new text html element. This constructor should not be called directly and should be
created via the outputer factory available from the C<L<ISIS::HTMLManip>> module. For more
information, see the perl documentation of C<L<ISIS::HTMLManip>>.

=head2 Icon( [ICON] ) :

Sets or returns the current icon attached to the text. By default, there is no icon set.
Icons should be set only by passing a reference to a C<L<OUT::Image>> instance.

=head2 Style( [STYLE] ) :

Sets or returns the current style that will be associated to the text. The style should be a
css class definition. By default, the class associated to the <div> element is 'text_default'.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
