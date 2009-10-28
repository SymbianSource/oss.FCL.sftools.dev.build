#============================================================================ 
#Name        : evalid_multiple.pl 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description: 
#============================================================================

#BEGIN {
#	push (@INC, "\\epoc32\\tools");
#}

use strict;
use EvalidCompare;
use Getopt::Long;

my $inputfile;
GetOptions( "f=s"=>\$inputfile) or die "/!\\ Error parsing command line.";

my $time1 = time();
open(IN,"<$inputfile") or die "/!\\ Can't open $inputfile";
foreach my $file (<IN>)
{
	chomp($file);
	if (-f $file)
	{
		my ($MD5, $type) = &EvalidCompare::GenerateSignature($file);
		print $file." TYPE=".$type." MD5=".$MD5."\n";
	}
	else
	{
		print $file." not found\n";
	}
}
close IN;

my $time2 = time();
