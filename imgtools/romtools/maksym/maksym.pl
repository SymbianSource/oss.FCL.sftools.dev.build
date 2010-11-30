#
# Copyright (c) 1996-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Produces symbolic information given a ROM image
#

require 5.003_07;
no strict 'vars';
use English;
use FindBin;		# for FindBin::Bin
use File::Copy;

# Version
my $MajorVersion = 1;
my $MinorVersion = 1;
my $PatchVersion = 0;

# Globals
my $maksym = "";
my $rombuild;
my $debug = 0;

&args;
&main;

exit 0;

sub CompareAddrs()
{
    return -1 if ($a < $b);
    return 1 if ($a > $b);
    return 0;
}

#
# main
#
sub main()
{
  my $symbolfile = $rombuild;
  $symbolfile =~ s/\.log$/\.symbol/i;
  my @cmdres = `rombuild -loginput=$rombuild`;
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

    while (@ARGV) {
	$arg = shift @ARGV;

	if ($arg=~/^[\-](\S*)$/) {
	    $flag=$1;

	    if ($flag=~/^[\?h]$/i) {
		&help;
	    } elsif ($flag=~/^d$/i) {
		$debug = 1;
	    } else {
		print "\nERROR: Unknown flag \"-$flag\"\n";
		&usage;
		exit 1;
	    }
	} else {
	    push @args,$arg;
	}
    }

    if (@args) {
	$rombuild = shift @args;
	if (@args) {
	    $maksym = shift @args;
	    if (@args) {
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

    print "\nmaksym - Produce symbolic information given a ROM image V${MajorVersion}.${MinorVersion}.${PatchVersion}\n";
    &usage;
    exit 0;
}

sub usage ()
{
    print <<EOF

Usage:
  maksym <logfile> [<outfile>]

Where:
  <logfile>   Log file from rombuild tool.
  <outfile>   Output file. Defaults to imagename.symbol.
EOF
    ;
    exit 0;
}
