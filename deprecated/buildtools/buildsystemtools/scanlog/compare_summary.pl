#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
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
# usage:
# perl compare_summary.pl new_build.summary last_build.summary > summary.summary
#

sub usage
	{
	print "syntax: perl compare_summary.pl new_build.summary last_build.summary\n";
	exit 1;
	}

sub showtable
	{
	my $f=$_[0];
	my $s=$_[1];
	my %first=%$f;
	my %second=%$s;

	my %comps;
	my $key,$n,$n2,$temp;

	while ($key = each %first) {
		$comps{$key}++;}
	while ($key = each %second){
		$comps{$key}++;}

	foreach $key (sort keys %comps)
		{
		$n=$first{$key}; if ($n==0) {$n="0";}
		$n2=$second{$key}; if ($n2==0) {$n2="0";}
		$d=$n-$n2;
		if ($d==0) {$d="";}
		if ($d > 0) { $d="+$d";}

		$temp=sprintf "(%s)",$n2;
		printf "%-24.24s   %-5.5s%-7.7s\t\t%s\n", $key, $n, $temp, $d;
		}
	}



$summaryfile1=$ARGV[0];
$summaryfile2=$ARGV[1];

if (($summaryfile1 eq "") or ($summaryfile2 eq "")) { usage() };

open(FILE1, "< $summaryfile1") || die ("can't open summary file: $!");
open(FILE2, "< $summaryfile2") || die ("can't open summary file: $!");

# find the start of the error summary in file 1
while (<FILE1>)
	{
	if (/Total+\s+(\S+)+\s+(\d+)+\s+(\d+)/)
		{
		$build1time=$1;
		$build1errors=$2;
		$build1warnings=$3;
		last;
		}
	}
# find the start of the error summary in file 2
while (<FILE2>)
	{
	if (/Total+\s+(\S+)+\s+(\d+)+\s+(\d+)/)
		{
		$build2time=$1;
		$build2errors=$2;
		$build2warnings=$3;
		last;
		}
	}

print "Total\t\t$build1time($build2time)\t$build1errors($build2errors)\t$build1warnings($build2warnings)\n\n";

# compare builds
$build1haserrors=0;
$build2haserrors=0;

# find the "Fatal errors" line
$dummy=<FILE1>;$dummy=<FILE1>;
if ($dummy =~ /Fatal Errors by Component/) { $build1haserrors=1;}
$dummy=<FILE2>;$dummy=<FILE2>;
if ($dummy =~ /Fatal Errors by Component/) { $build2haserrors=1;}

if ($build1haserrors)
	{
	while (<FILE1>)
		{
		if (/^(\S+)+\s+(\d+)/)
			{
			$theerrors1{$1}="$2";
			}
		else
			{
			last;
			}
		}
	}
if ($build2haserrors)
	{
	while (<FILE2>)
		{
		if (/^(\S+)+\s+(\d+)/)
			{
			$theerrors2{$1}="$2";
			}
		else
			{
			last;
			}
		}
	}

if ($build1haserrors || $build2haserrors)
	{
	print "Fatal Errors by Component\n";
	showtable(\%theerrors1, \%theerrors2);
	print;
	}


# do the warnings now
$build1haswarnings=0;
$build2haswarnings=0;
seek FILE1,0,0;
seek FILE2,0,0;
while (<FILE1>)
	{
	if (/Warnings by Component/)
		{
		$build1haswarnings=1;
		last;
		}
	}

while (<FILE2>)
	{
	if (/Warnings by Component/)
		{
		$build2haswarnings=1;
		last;
		}
	}

# compare builds
if ($build1haswarnings || $build2haswarnings)
	{


if ($build1haswarnings)
	{
	while (<FILE1>)
		{
		if (/^(\S+)\s+(\d+)/)
			{
			$thewarnings1{$1}=$2;
			}
		else
			{
			last;
			}
		}
	}
if ($build2haswarnings)
	{
	while (<FILE2>)
		{
		if (/^(\S+)\s+(\d+)/)
			{
			$thewarnings2{$1}=$2;
			}
		else
			{
			last;
			}
		}
	}

	print "Warnings by Component\n";
	print "                          this (last)\n";
	showtable(\%thewarnings1, \%thewarnings2);
	}




close FILE1;
close FILE2;

