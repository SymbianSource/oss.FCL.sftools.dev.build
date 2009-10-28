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
#------------------------------------------------------------------------------
# Name   : LogoHeader.pm
# Use    : description.

#
# Synergy :
# Perl %name: LogoHeader.pm % (%full_filespec:  LogoHeader.pm-1:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Thu Mar 16 12:49:17 2006 %
#
# Version History :
#
# v1.0 (16/03/2006) :
#  - Fist version of the package.
#------------------------------------------------------------------------------

package OUT::Log::LogoHeader;
use ISIS::HttpServer;


#------------------------------------------------------------------------------
# Package's subroutines
#------------------------------------------------------------------------------
sub new 
{
	warn "new OUT::Log::LogoHeader( ".join(', ', @_)." )\n" if(DBG::LOG_HEADER);
	my ($class) = (shift);
	
	bless { 'OUT::Log::LogoHeader::Title'    => shift,
		      'OUT::Log::LogoHeader::Subtitle' => shift,
		      'OUT::Log::LogoHeader::Config'   => shift,
		      _outputer                    => shift,
		    }, $class;
}

sub Print
{
	warn "OUT::Log::LogoHeader::Print( ".join(', ', @_)." )\n" if(DBG::LOG_HEADER);
	my $self     = shift;
	my $outputer = $self->{_outputer};

	my @pics;
	push @pics, "<div align=\"right\" style=\"position: absolute; top: 0px; right: 0px;\">";
	foreach my $logo ( @{ $self->{'OUT::Log::LogoHeader::Config'}->Child('__logo') } )
	{
		my $param = '';		
		$param .= "width=\"".$logo->Attribute('width')."\"" if ($logo->Attribute('width'));
		$param .= "height=\"".$logo->Attribute('height')."\"" if ($logo->Attribute('height'));
		if ($logo->Attribute('name') and $logo->Attribute('name')=~/^http:\/\//)
		{			
			push @pics, "    <img src=\"".$logo->Attribute('name')."\" $param />\n";
		}
  	elsif ($logo->Attribute('name'))
  	{
			push @pics, "<img src=\"".HttpServer::GetAddress().$logo->Attribute('name')."\" $param />\n";
  	}
  }

	push @pics, "</div>";
	
	# May put the max size
	$outputer->Print(
	  "<div id=\"h_wrapper\" style=\"height: 128px;\">\n",
	  "  <div class=\"h_elmt\">\n",
	  "    <div class=\"h_title\">", $self->{'OUT::Log::LogoHeader::Title'}, "</div>\n",
	  "    <div class=\"h_subtitle\">", $self->{'OUT::Log::LogoHeader::Subtitle'}, "</div>\n",
	  join("\n", @pics),
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
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
