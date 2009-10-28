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
# Name   : Outputer.pm
# Use    : Contains all debug constant symbols - Activates tracing in OUT packages.

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
#   OUT::Debug package.
#
#--------------------------------------------------------------------------------------------------

package DBG;

use strict;
use warnings;

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '13/12/2005';

use constant _DEBUG => 0;
                              
use constant OUTPUTER           => _DEBUG && 0; # OUT/Outputer.pm
use constant LOG_DOCUMENT       => _DEBUG && 0; # OUT/LogDocument.pm
use constant LOG_HEADER         => _DEBUG && 0; # OUT/Log/Header.pm
use constant LOG_FOOTER         => _DEBUG && 0; # OUT/Log/Footer.pm
use constant LOG_MAINCONTENT    => _DEBUG && 0; # OUT/Log/MainContent.pm
use constant LOG_SUMMARY        => _DEBUG && 0; # OUT/Log/Summary.pm
use constant LOG_SUMMARYCONTENT => _DEBUG && 0; # OUT/Log/SummaryContent.pm
use constant BOX1               => _DEBUG && 0; # OUT/Box1.pm
use constant NODE               => _DEBUG && 0; # OUT/Node.pm
use constant RAWTEXT            => _DEBUG && 0; # OUT/RawText.pm
use constant TEXT               => _DEBUG && 0; # OUT/Text.pm
use constant TITLE1             => _DEBUG && 0; # OUT/Title1.pm
use constant IMAGE              => _DEBUG && 0; # OUT/Image.pm
use constant TABLE2D            => _DEBUG && 0; # OUT/Table2D.pm
use constant SEPARATOR          => _DEBUG && 0; # OUT/Separator.pm

1;

__END__

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::Debug - Definition of all debug symbols used to (de)activate tracing in the OUT module.

=head1 SYNOPSIS

Setting a constant value to 1 will activate tracing for all instances of the package. each call
to a member subroutine of that package will be displayed on the terminal/sheel output.

The package influenced by the symbol is written as a comment beside each constant.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
