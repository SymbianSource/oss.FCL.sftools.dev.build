#
# Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Add up the codesize lines
# Code size:               00028f4c
#

while ($line=<>)
	{
	if ($line =~ /^Code size:\s+(\S+)/i)
		{
		$totalcode += hex($1);
		$count++;
		}
	}

print "$count binaries totalling $totalcode\n";
