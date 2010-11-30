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

require 5.003_07;
no strict 'vars';
use English;
use FindBin;		# for FindBin::Bin

# Version
my $MajorVersion = 1;
my $MinorVersion = 1;
my $PatchVersion = 0;

# Globals
my $maksym = "";
my $rofsbuild;
my $debug = 0;

&args;
&main;
exit 0;

#
# main
#
sub main()
{
	my $symbolfile = $rofsbuild;
  	$symbolfile =~ s/\.log$/\.symbol/i;
  	my @cmdres = `rofsbuild -loginput=$rofsbuild`;
  	print "@cmdres\n";
	if(($maksym ne "") && ($maksym ne $symbolfile))
 	{
	 	rename($symbolfile, $maksym);
  	}
}
#
# args - get command line args
#
sub args
{
	my $arg;
	my @args;
	my $flag;

	&help if (!@ARGV);

	while (@ARGV) 
	{
		$arg = shift @ARGV;

		if ($arg=~/^[\-](\S*)$/) 
		{
			$flag=$1;

			if ($flag=~/^[\?h]$/i) 
			{
				&help;
			}
			elsif ($flag=~/^d$/i) 
			{
				$debug = 1;
			}
		       	else 
			{
				print "\nERROR: Unknown flag \"-$flag\"\n";
				&usage;
				exit 1;
			}
		}
		else 
		{
			push @args,$arg;
		}
	}

	if (@args)
	{
		$rofsbuild = shift @args;
		if (@args) 
		{
			$maksym = shift @args;
			if (@args) 
			{
				print "\nERROR: Incorrect argument(s) \"@args\"\n";
				&usage;
				exit 1;
			}
		}
	}
}

sub help ()
{
	my $build;

	print "\nmaksymrofs - Produce symbolic information given a ROFS image V${MajorVersion}.${MinorVersion}.${PatchVersion}\n";
	&usage;
	exit 0;
}

sub usage ()
{
    print <<EOF

Usage:
  maksymrofs <logfile> [<outfile>]

Where:
  <logfile>   Log file from rofsbuild tool.
  <outfile>   Output file. Defaults to imagename.symbol.
EOF
    ;
    exit 0;
}
