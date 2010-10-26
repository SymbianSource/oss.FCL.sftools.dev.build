#
# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Produces symbolic information given a ROFS log file and .map files for relevant binary files
#

shift @ARGV;
my $logfile = shift @ARGV;
my $command = "rofsbuild -loginput=$logfile";
system ($command);
exit 0;
