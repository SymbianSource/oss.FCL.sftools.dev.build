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
# Name   : EmbeddedXMLLog.pm
# Use    : description.

#
# Version History :
#
# v1.0.0 (30/05/2006) :
#  - First version of the script.
#------------------------------------------------------------------------------
package EmbeddedXMLLog;
use strict;
use ISIS::XMLManip;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.0.0';
use constant ISIS_LAST_UPDATE => '30/05/2006';

#------------------------------------------------------------------------------
# Package Function
#------------------------------------------------------------------------------

sub IncludeXMLLog
{
	my ($xmllog) = @_;
	return 0 unless ( -e $xmllog );
		
	my $node = XMLManip::ParseXMLFile( $xmllog );
	return 0 unless ( $node );
	foreach my $sn ( @{$node->Child("__maincontent")} )
	{		
		foreach my $n (@{$sn->Childs()})
		{
			OUT2XML::AppendXmlNode( $n );
		}
	}
	return 1;
}

1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
