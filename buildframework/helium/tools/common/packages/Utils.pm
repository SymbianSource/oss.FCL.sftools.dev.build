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
#!perl -w
# ==============================================================================
#  %name:            Utils.pm %
#  Part of:        juno_build
#  Requires:
#
#  %version:	     to1r1103#6 %
#  %date_modified:   Fri Oct  6 11:53:35 2006 %
#
#  See POD text at the end of this file for usage and other details.
# ==============================================================================

package Utils;

use strict;
use File::Copy;



BEGIN
{
    use Exporter ();
    our (@ISA, @EXPORT, @EXPORT_OK);
    @ISA    = qw(Exporter);
    @EXPORT =
      qw( &replace_env_vars &do_copy );

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK = qw();
}



# This will replace any text strings of the form:
#   ${<ENV_VARIABLE>} or
#   ${env.<ENV_VARIABLE>}
# with the corresponding value of the matching environment variable, i.e.
# ENV_VARIABLE.
sub replace_env_vars
{
    local $_ = shift;
    if ( defined( $_ ) )
    {
        foreach my $varname (keys %ENV)
        {
            s/\$\{${varname}\}/${ENV{$varname}}/g;
            s/\$\{env\.${varname}\}/${ENV{$varname}}/g;
        }
    }
    return $_;
}



sub do_copy
{
    my ( $from, $to ) = @_;
    print( "copy: $from -> $to\n" );
    copy( $from, $to ) or die "ERROR: Copy failed: $!";
}



1;

__END__


