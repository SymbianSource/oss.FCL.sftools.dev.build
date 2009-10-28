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
# Name   : Separator.pm
# Use    : Normal HTML separator.

#
# Synergy :
#
# Version History :
#
# v1.0.0 (16/03/2006) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   Separator package.
#
#--------------------------------------------------------------------------------------------------
package OUT::Separator;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => '1.0.0';
use constant ISIS_LAST_UPDATE => '16/03/2006';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::Separator( ", join(', ', @_), " )\n" if(DBG::SEPARATOR);

  my $class    = shift;
	my $outputer = pop;

  bless { style     => shift,
          _outputer => $outputer,
        }, $class;
}

#--------------------------------------------------------------------------------------------------
# Print function.
#--------------------------------------------------------------------------------------------------
sub Print
{
	warn "OUT::Separator::Print( ".join(', ', @_)." )\n" if(DBG::SEPARATOR);
  my $self     = shift;
  my $outputer = $self->{_outputer};
  my $indent   = $outputer->Indent();
 	              
	$outputer->Print("<div class=\"".($self->{style})."\" ></div>\n");
}

sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::SEPARATOR);
	$self->{_outputer}->_Accessor($self, $method, @_);
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::Separator - HTML element - A simple separator element.

=head1 SYNOPSIS

	use ISIS::HTMLManip;

	open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;
	my $outputer = new HTMLManip($ostream, 'configuration.xml', 'isis_interface');
	my $text = $outputer->Create('Separator', 'css_separator_style');

=head1 DESCRIPTION

This module creates a simple separator HTML element as an HTML <div> element.

=head2 Separator( <STYLE> ) :

Creates a new separator html element. This constructor should not be called directly and should be
created via the outputer factory available from the C<L<ISIS::HTMLManip>> module. For more
information, see the perl documentation of C<L<ISIS::HTMLManip>>.

=head2 Style( [STYLE] ) :

Sets or returns the current style that will be associated to the text. The style should be a
css class definition. By default, the class associated to the <div> element is 'text_default'.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
