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
use warnings;
use strict;
use FindBin;		# for FindBin::Bin
my $PerlLibPath;	# fully qualified pathname of the directory containing our Perl modules

BEGIN {
# check user has a version of perl that will cope
	require 5.005_03;
# establish the path to the Perl libraries
    $PerlLibPath = $FindBin::Bin;	# X:/epoc32/tools
    $PerlLibPath =~ s/\//\\/g;	# X:\epoc32\tools
    $PerlLibPath .= "\\";
}

use  lib $PerlLibPath;
use spitool qw(&createSpi);
createSpi(@ARGV);
