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
# Name   : HttpServer.pm
# Use    : description.

#
# Synergy :
# Perl %name: HttpServer.pm % (%full_filespec:  HttpServer.pm-2.1.2:perl:fa1s60p1#1 %)
# %derived_by:  oligrant %
# %date_created:  Wed Apr  5 13:29:26 2006 %
#
# Version History :
#
# v1.0.0 (07/02/2006) :
#  - Manage resources from ISIS http server.
#------------------------------------------------------------------------------

package HttpServer;

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;

# ISIS constants.
use constant ISIS_VERSION     => '1.0.0';
use constant ISIS_LAST_UPDATE => '07/02/2006';

use constant ISIS_HTTP_SERVER => "http://fawww.europe.nokia.com/isis";

#------------------------------------------------------------------------------
# GetAddress
# return default ISIS server
#------------------------------------------------------------------------------
sub GetAddress
{
	return ISIS_HTTP_SERVER;
}

#------------------------------------------------------------------------------
# GetFile
# src			source url
# dst			destination path
# return 1 on success or 0 on failure
#------------------------------------------------------------------------------
sub GetFile($$)
{
	my ($src, $dst) = @_;
	
	# if the path is not an http url then append server url
	$src = ISIS_HTTP_SERVER."/$src" if ( $src !~ /^http:\/\// );
	
	# Get the file
	my $request = HTTP::Request->new( GET => "$src" );
	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($request);
	if ($response->is_success)
	{
		# if success writing the content to the dest file
		open(FILE, '>'.$dst) or return 0;
		binmode FILE;
		print FILE $response->content;
		close(FILE);	
		return 1;
	}	
	# else return error!
	return 0;
}

1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------