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
# fcw.pl - compare two files as 32-bit words
#

use strict;

if (@ARGV!=2)
	{
#........1.........2.........3.........4.........5.........6.........7.....
	print <<USAGE_EOF;

Usage:
  fcw file1 file2     -- compare two files

USAGE_EOF
	exit 1;
	}

my $left=@ARGV[0];
my $right=@ARGV[1];

open LEFT, $left or problem("Cannot open $left") and return;
open RIGHT, $right or problem("Cannot open $right") and return;

binmode LEFT;
binmode RIGHT;

if (compare_streams())
	{
	print "Files are identical\n";
	}

sub compare_streams
	{
	my $same = 1;
	my $offset = 0;
	my $leftbuf;
	my $rightbuf;

	BINARY_COMPARISON: while (1)
		{
		my $leftlen = read LEFT,  $leftbuf,  4096;
		my $rightlen= read RIGHT, $rightbuf, 4096;
		if ($rightlen == 0 && $leftlen == 0)
			{
			return $same;
			}
		if ($leftbuf eq $rightbuf)
			{
			$offset += $leftlen;
			}
		else
			{
			my @leftwords = unpack "V*", $leftbuf;
			my @rightwords = unpack "V*", $rightbuf;
			foreach $_ (@leftwords)
				{
				if ($_ != @rightwords[0])
					{
					printf "%06x: %08x != %08x\n", $offset, $_, @rightwords[0];
					}
				shift @rightwords;
				$offset+=4;
				}
			$same=0;
			}
		}
	}



