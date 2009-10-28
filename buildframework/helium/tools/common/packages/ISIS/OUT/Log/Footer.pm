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
#--------------------------------------------------------------------------------------------------
#
#   Log::Footer package.
#
#--------------------------------------------------------------------------------------------------
package OUT::Log::Footer;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '15/12/2005';

sub new
{
	warn "new OUT::Log::Footer( ".join(', ', @_)." )\n" if(DBG::LOG_FOOTER);
	my ($class) = (shift);
	
	bless { 'OUT::Log::Footer::Title'    => shift,
		      'OUT::Log::Footer::Subtitle' => shift,
		      _outputer                    => shift,
		    }, $class;
}

sub Print
{
	warn "OUT::Log::Footer::Print( ".join(', ', @_)." )\n" if(DBG::LOG_FOOTER);
	my $self     = shift;
	my $outputer = $self->{_outputer};
	
	$outputer->Print(
	  "<div id=\"f_wrapper\">\n",
	  "  <div class=\"f_elmt\">\n",
	  "    <div class=\"f_title\">", $self->{'OUT::Log::Footer::Title'}, "</div>\n",
	  "    <div class=\"f_subtitle\">", $self->{'OUT::Log::Footer::Subtitle'}, "</div>\n",
	  "  </div>\n",
	  "</div>\n"
	);
}

sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::LOG_FOOTER);
	return $self->{_outputer}->_Accessor($self, $method, @_);
}

1;

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
