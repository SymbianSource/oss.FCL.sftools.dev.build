#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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

use strict;
use FindBin;
use Getopt::Long qw(:config no_auto_abbrev no_bundling pass_through);

my $path = $FindBin::Bin;
my $cmdLine = "$path/imgcheck.exe @ARGV"  ;
system ($cmdLine);
