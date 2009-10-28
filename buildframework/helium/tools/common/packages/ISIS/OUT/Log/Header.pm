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
#   Log::Header package.
#
#--------------------------------------------------------------------------------------------------
package OUT::Log::Header;

sub new 
{
	warn "new OUT::Log::Header( ".join(', ', @_)." )\n" if(DBG::LOG_HEADER);
	my ($class) = (shift);
	
	bless { 'OUT::Log::Header::Title'    => shift,
		      'OUT::Log::Header::Subtitle' => shift,
		      _outputer                    => shift,
		    }, $class;
}

sub Print
{
	warn "OUT::Log::Header::Print( ".join(', ', @_)." )\n" if(DBG::LOG_HEADER);
	my $self     = shift;
	my $outputer = $self->{_outputer};
	
	$outputer->Print(
	  "<div id=\"h_wrapper\">\n",
	  "  <div class=\"h_elmt\">\n",
	  "    <div class=\"h_title\">", $self->{'OUT::Log::Header::Title'}, "</div>\n",
	  "    <div class=\"h_subtitle\">", $self->{'OUT::Log::Header::Subtitle'}, "</div>\n",
	  "  </div>\n",
	  "</div>\n"
	);
}

sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::LOG_HEADER);
	return $self->{_outputer}->_Accessor($self, $method, @_);
}

1;

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
