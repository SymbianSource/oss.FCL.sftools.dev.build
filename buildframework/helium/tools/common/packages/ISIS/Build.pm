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
# Name   : Build.pm
# Use    : Build an TBS xml using specific tools

#
# Version History :
#
# v1.0 (25/05/2006) :
#  - Fist version of the script.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# package Build::TBS;
#------------------------------------------------------------------------------
package Build::TBS;
use strict;
use ISIS::GenBuildTools;

sub Build
{
	my ($xml, $logname) = (shift, shift);
	&GenBuildTools::BuildTBS($xml, $logname);
}

sub IsAvailable()
{
	# TBS is always available
	return 1;
}
1;

#------------------------------------------------------------------------------
# package Build::EC;
#------------------------------------------------------------------------------
package Build::EC;
use strict;
use ISIS::ECloud;

sub Build
{
	my ($xml, $logname) = (shift, shift);
	my $ec = new ECloud();
	$ec->Execute( $xml );	
}

sub IsAvailable()
{
	return (-e "C:\\ECloud\\i686_win32\\bin\\emake.exe");
}
1;

#------------------------------------------------------------------------------
# package Build;
#------------------------------------------------------------------------------
package Build;
use strict;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.0.0';
use constant ISIS_LAST_UPDATE => '25/05/2006';

#------------------------------------------------------------------------------
# Package Function
#------------------------------------------------------------------------------
my %__tools;
BEGIN {
%__tools = (  'ec'  => 'Build::EC',
							'tbs' => 'Build::TBS');
}


sub Build
{
	my ( $xml, $logname, $buildtool ) = (shift, shift, shift || 'auto');
	
	$buildtool = &GetFirstAvailableBS() if ($buildtool eq "auto");
	
	# default is TBS if build tool not found
	$buildtool = 'tbs' unless ( exists( $__tools{ $buildtool } ) );
	
	no strict 'refs';
	my $method = $__tools{$buildtool}."::Build";
	return &$method($xml, $logname);	
}

sub GetFirstAvailableBS()
{
	foreach my $tool ( keys (%__tools) )
	{
		no strict 'refs';
		my $method = $__tools{$tool}."::IsAvailable";
		return $tool if ( &$method() );
	}
	return 'tbs';
}

sub GetSupportedTools()
{
	return keys (%__tools);
}

1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
