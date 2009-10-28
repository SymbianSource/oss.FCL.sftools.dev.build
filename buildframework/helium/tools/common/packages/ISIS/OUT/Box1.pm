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
# Name   : Box1.pm
# Use    : Creates a rounded box container in HTML.

#
# Synergy :
# Perl %name: Box1.pm % (%full_filespec:  Box1.pm-1:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Thu Jan 12 10:13:35 2006 %
#
# Version History :
#
# v1.0 (12/11/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   Box package.
#
#--------------------------------------------------------------------------------------------------
package OUT::Box1;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '12/11/2005';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::Box1( ".join(', ', @_)." )\n" if(DBG::BOX1);

	my $outputer = pop;
	$outputer->RequireCSSFile('css/box1.css');
	$outputer->RequireJSFile('javascript/box1.js');
	
  bless { _childs   => undef,
          _outputer => $outputer,
        }, shift;
}

#--------------------------------------------------------------------------------------------------
# Push Data Element.
#--------------------------------------------------------------------------------------------------
sub PushChild
{
	warn "OUT::Box1::PushChild( ".join(', ', @_)." )\n" if(DBG::BOX1);
  my ($self, $child) = (shift, shift);
  warn "pushing undefined value in child array (Box1)\n" unless(defined $child);
  push @{$self->{_childs}}, $child;
}

#--------------------------------------------------------------------------------------------------
# Print function.
#--------------------------------------------------------------------------------------------------
sub Print
{
	warn "OUT::Box1::Print( ".join(', ', @_)." )\n" if(DBG::BOX1);
  my $self     = shift;
  my $outputer = $self->{_outputer};
  my $indent   = $outputer->Indent();

  $outputer->Print(
  	"<div class=\"box1\">\n",
  	"  <div class=\"box1_content\">\n",
  	"    <table width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">\n",
  );

  my $indent2 = $outputer->Indent();
  $outputer->Indent($indent2 . '      ');

  foreach (@{$self->{_childs}})
  {
  	$outputer->_PreArray();
    $_->Print();
    $outputer->_PostArray();
  }
  
  $outputer->Indent($indent2);
  
  $outputer->Print(
    "    </table>\n",
  	"  </div>\n",
  	"</div>\n"
  );
}

sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::BOX1);
	$self->{_outputer}->_Accessor($self, $method, @_);
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::Box1 - HTML element - A simple blue box with round corners.

=head1 SYNOPSIS

	use ISIS::HTMLManip;

	open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;
	my $outputer = new HTMLManip($ostream, 'configuration.xml', 'isis_interface');
	my $box = $outputer->Create('Box1');

=head1 DESCRIPTION

This module creates a blue bordered HTML box with rounded corners. It requires the box1.css and
box1.js files that can be found in the isis_interface.

=head2 Box1(  ) :

Create a new box. This constructor should not be called directly and should be created via the
outputer factory available from the C<L<ISIS::HTMLManip>> module. For more information, see the
perl documentation of C<L<ISIS::HTMLManip>>.

=head2 PushChild( CHILD ) :

Adds a HTML element to the box instance. These elements will be encapsulated in this box1 element
and printed automatically when box1 is printed.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
