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
# Name   : HtmlManip.pm
# Use    : Contains an instanciable package to write complex html files.

#
# Synergy :
#
# Version History :
#
# v1.0 (12/11/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   HTMLManip package - Just a shortcut to load the main OUT module.
#
#--------------------------------------------------------------------------------------------------

package HTMLManip;

use strict;
use warnings;
use ISIS::OUT::Outputer;

use constant ISIS_VERSION     => 'v1.00';
use constant ISIS_LAST_UPDATE => '13/12/2005';

sub new
{
	shift;
	return new OUT::Outputer(@_);
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

ISIS::HTMLManip - Outputer for complex html files.

=head1 SYNOPSIS

	use ISIS::HTMLManip;

	open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;
	my $outputer = new HTMLManip($ostream, 'configuration.xml', 'isis_interface');

=head1 DESCRIPTION

The HTMLManip package provides only a constructor that returns a new L<OUT::Outputer>
instance from which all HTML generation is done.

=head2 HTMLManip( OSTREAM, CONFIGURATION_FILE, INTERFACE ) :

Returns a newly constructed L<OUT::Outputer> instance that will printout to the passed
output stream. The configuration file is used for generic values such as icons and 
colors. The interface determines the root directory from with all the HTML style information
will be taken.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
