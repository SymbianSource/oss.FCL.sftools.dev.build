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
# Name   : OutputParser.pm
# Use    : description.

#
# Synergy :
# Perl %name: OutputParser.pm % (%full_filespec:  OutputParser.pm-1:perl:fa1s60p1#2 %)
# %derived_by:  wbernard %
# %date_created:  Thu Feb  9 08:24:25 2006 %
#
# Version History :
#
# v1.0 (24/10/2005) :
#  - Fist version of the package.
#  - Based on localisation one.
#------------------------------------------------------------------------------

package ISIS::OutputParser;
use strict;
use ISIS::Logger2;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.0';
use constant ISIS_LAST_UPDATE => '24/10/2005';


#------------------------------------------------------------------------------
# Package's subroutines
#------------------------------------------------------------------------------

sub ParseMakeFPSX
{
	my ($output) = @_;
	my $buffer = "";
	foreach my $line ( split(/\n/, $output) )
	{
		
		if ( $line  =~ /ERROR:/i )
		{
			OUT2XML::Print ( $buffer );	$buffer = "";
			OUT2XML::Error ( $line  );
		}
		elsif ( $line  =~ /WARNING:/i )
		{
			OUT2XML::Print ( $buffer );	$buffer = "";
			OUT2XML::Warning ( $line  );
		}
		elsif ( $line  =~ /\s*Invalid\s+Image\s+name:/i )
		{
			OUT2XML::Print ( $buffer );	$buffer = "";
			OUT2XML::Warning ( $line  );
		}		
		elsif ( $line  =~ /\s*Missing\s+file:/i )
		{
			OUT2XML::Print ( $buffer );	$buffer = "";
			OUT2XML::Warning ( $line  );
		}
		elsif ( $line =~ /^#+/ )
		{
			OUT2XML::Print ( $buffer );	$buffer = "";
			OUT2XML::Print ( "<b>$line</b>" );
		}
		else
		{
			$buffer .= $line."\n"
		}
		
	}
}

sub ParseCopy
{
	my ( $output, $expected_result ) = @_;
	if ( ( $output =~ /(\d+) file\(s\) copied\./i ) and
			( (defined ($expected_result) and $1==$expected_result) or (not defined ($expected_result) and $1>0) ) )		
	{
		OUT2XML::Print ( $output );	
	}
	else
	{
		OUT2XML::Error ( $output );	
	}
}


1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
