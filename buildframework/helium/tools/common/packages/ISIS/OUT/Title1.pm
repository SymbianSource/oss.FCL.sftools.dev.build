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
# Name   : Title1.pm
# Use    : Normal HTML title with optional icon.

#
# Synergy :
# Perl %name: Title1.pm % (%full_filespec:  Title1.pm-1:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Thu Jan 12 10:14:06 2006 %
#
# Version History :
#
# v1.0 (12/11/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   Title1 package.
#
#--------------------------------------------------------------------------------------------------
package OUT::Title1;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '21/12/2005';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::Title1( <text> )\n" if(DBG::TITLE1);

  my $class    = shift;
	my $outputer = pop;
	my $text     = join('', @_);
	
  bless { icon      => undef,
  	      content   => $text,
          _outputer => $outputer,
        }, $class;
}

#--------------------------------------------------------------------------------------------------
# Print function.
#--------------------------------------------------------------------------------------------------
sub Print
{
	warn "OUT::Title1::Print( ".join(', ', @_)." )\n" if(DBG::TITLE1);
  my $self     = shift;
  my $outputer = $self->{_outputer};
  my $indent   = $outputer->Indent();
  my $icon     = $self->{icon};
  
  $self->{content} =~ s/\n//g;

	if(defined $icon and ref $icon eq 'OUT::Image')
	{
		$outputer->Indent($indent . '        ');
	 	$icon->Print();
	 	$outputer->Indent($indent);
	}

 	$outputer->Print("<h1>", $self->{content}, "</h1>\n");
}

sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::TITLE1);
	$self->{_outputer}->_Accessor($self, $method, @_);
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::Title1 - A simple title using the <h1> HTML element.

=head1 SYNOPSIS

	use ISIS::HTMLManip;

	open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;
	my $outputer = new HTMLManip($ostream, 'configuration.xml', 'isis_interface');
	my $title = $outputer->Create('Title1');

=head1 DESCRIPTION

This module creates a simple text HTML element encapsulated in a HTML <div> element.

=head2 Title( [TITLE] ) :

Creates a new title element. An optional image type that will be looked up in the configuration XML
file will be used. See C<L<ISIS::HTMLManip>> for more information. This constructor should not be
called directly and should be created via the outputer factory available from the C<L<ISIS::HTMLManip>>
module. For more information, see the perl documentation of C<L<ISIS::HTMLManip>>.

=head2 Icon( [ICON] ) :

Sets or returns the current icon attached to the text. By default, there is no icon set.
Icons should be set only by passing a reference to a C<L<OUT::Image>> instance.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
