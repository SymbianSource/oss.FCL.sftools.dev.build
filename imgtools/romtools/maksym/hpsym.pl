#
# Copyright (c) 1999-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# munge maksym.log into form suitable for an HP logic analyser
# History
# 0.1	08/06/99	First release.
# 0.2	09/06/99	Always include symbols from E32 and device drivers.
# 0.3	15/06/99	Added rombase flag & argument.
# 0.4	11/11/99	Remove c++filt step. Ensure symbols don't contain spaces.
#

# Globals
my $rombase = 0x50000000;
my @executables = ( 'euser' );

my $maksym = 'maksym.log';
my $gpa = 'symbols.gpa';
my $arg;
my $skip;

# Standard e32toolp path scanning
use FindBin;		# for FindBin::Bin

my $PerlLibPath;    # fully qualified pathname of the directory containing our Perl modules

BEGIN {
# check user has a version of perl that will cope
	require 5.005_03;
# establish the path to the Perl libraries: currently the same directory as this script
	$PerlLibPath = $FindBin::Bin;	# X:/epoc32/tools
	$PerlLibPath =~ s/\//\\/g;	# X:\epoc32\tools
	$PerlLibPath .= "\\";
}

use lib $PerlLibPath;
use Modload;
Load_SetModulePath($PerlLibPath);

if (@ARGV)
  {
	$maksym = shift;
	if ($maksym =~ /^-[h\?]$/i)
	  {
		&help;
	  }
	elsif ($maksym =~ /^(-r)/i)
	  {
		if (@ARGV)
		  {
			$rombase=hex(shift);
			if (@ARGV)
			  {
				$maksym = shift;
			  }
			else
			  {
				print "\nError: missing <infile> argument.\n";
				&usage;
				exit 1;
			  }
		  }
		else
		  {
			print "\nError: rombase flag '-r' requires an argument.\n";
			&usage;
			exit 1;
		  }
	  }
	elsif ($maksym =~ /^(-.*)/)
	  {
		print "\nError: invalid flag '$1'\n.";
		&usage;
		exit 1;
	  }

	if (@ARGV)
	  {
		my $file;

		$gpa = shift;
		
		foreach $file (@ARGV)
		  {
			push @executables, quotemeta($file);
		  }
	  }
  }
else
  {
	&help;
  }
		
open (GPA, ">$gpa") or die "Can't write to '$gpa'";
open (LOG, "$maksym") or die "Can't read '$maksym'";

while (<LOG>)
  {
	if (/^From\s+\S+\\(.+)\\.+\\(.+)$/)
	  {
		# Found a new file
		$abi = $1;
		$file = $2;

		# Decode this file if it's kernel-side or matches the supplied regexp
		if ($abi =~ /^(M|S)/i)
		  {
			$skip = 0;
		  }
		else
		  {
			$skip = 1;
			foreach $re (@executables)
			  {
				$skip = 0 if ($file =~ /$re/i);
			  }
		  }
		print "$file\n" if not $skip;
	  }
	elsif (!/^$/ && !$skip)
	  {
		/^(\S*)\s*(\S*)\s*(.*)$/;
		$addr=hex($1) - $rombase;
		$len=(hex($2)<0) ? 4 : hex($2);
		$name = $3;
		$name =~ s/\(.*//;		# remove arguments and any const qualifier

		# remove spaces from symbol names
		if ($name =~ 'global constructors keyed to (.*)')
		  {
			$name = $1.'_CTOR';
		  }
		elsif ($name =~ 'global destructors keyed to (.*)')
		  {
			$name = $1.'_DTOR';
		  }
		elsif ($name =~ '(.*) virtual table')
		  {
			$name = $1.'_VTBL';
		  }
		else
		  {
			$name =~ s/ /_/g;
		  }
		print GPA "$name\t", sprintf('%08x', $addr), '..',
		  sprintf('%08x', $addr+$len-1), "\n";
	  }
  }

close LOG;
close GPA;
exit 0;


sub help ()
  {
	my $build;

	&Load_ModuleL('E32TPVER');
	print "\nhpsym - Produce symbolic info in \"HP GPA Symbol File Format\"" .
	  " suitable for use\n        with a HP logic analyser (Build ",
	  &E32tpver, ")\n";
	&usage;
	exit 0;
  }

sub usage ()
  {
	print <<EOF

Usage:
  hpsym [-r <rombase>] <logfile> [<outfile> [<executables>]]

Where:
  <rombase>     Offset in hex of logical address from physical address of ROM.
                Defaults to 50000000. Use 0 for single-process builds.
  <logfile>     Log from maksym tool.
  <outfile>     Output filename. Default is 'symbols.gpa'. Use - for stdout.
  <executables> Names of additional executables to list the symbols of.
                ASSP-specific executables and EUSER are always included.

Example:
  hpsym maksym.log symbols.gpa efile efsrv .fsy

EOF
  }
