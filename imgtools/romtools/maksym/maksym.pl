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

my $PerlLibPath;    # fully qualified pathname of the directory containing our Perl modules

BEGIN {
    # check user has a version of perl that will cope require 5.005_03;
    # establish the path to the Perl libraries: currently the same directory as this script
    $PerlLibPath = $FindBin::Bin; # X:/epoc32/tools
    $PerlLibPath =~ s/\//\\/g;	# X:\epoc32\tools
    $PerlLibPath .= "\\";
}

use lib $PerlLibPath;
use Modload;
Load_SetModulePath($PerlLibPath);

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
  my $file;
  my $mapfile;
  my $mapfile2;
  my $text;
  my $data;
  my $bss;
  my $textsize;
  my $datasize;
  my $bsssize;
  my $totaldatasize;
  my $totalsize;

  open (ROM, "<$rombuild")
    or die "ERROR: Can't open rombuild log file \"$rombuild\"\n";
  if ($maksym ne "") {
    open (SYM, ">$maksym")
      or die "ERROR: Can't open output file \"$maksym\"\n";
    print "Creating $maksym...\n";
  }

  while (<ROM>) {
    # Start of ROM
    if (/^Creating Rom image (\S*)/) {
      if ($maksym eq "") {
	# For backwards compatibility, replace trailing .img with .symbol
	# if no trailing .img, just append .symbol anyway
	$maksym = $1;
	$maksym =~ s/(\.img)?$/.symbol/i;
	close SYM;
	open (SYM, ">$maksym")
	  or die "ERROR: Can't open output file \"$maksym\"\n";
	print "\nCreating $maksym...\n";
      }
      next;
    }
    # end of ROM
    if (/^Writing Rom image/) {
      close SYM;
      $maksym = "";
      next;
    }
    # Data file
    if (/^Reading resource (.*) to rom linear address (.*)/) {
      $file = $1;
      my $data = hex($2);
      $file =~ /([^\\]+)$/;
      printf SYM "\nFrom    $file\n\n%08x    0000    $1\n", $data;
    }
    # Executable file
    elsif (/^Processing file (.*)/) {
      $file = $1;
      $text = 0;
      $data = 0;
      $bss = 0;
      $textsize = 0;
      $datasize = 0;
      $bsssize = 0;
      $totaldatasize = 0;

      # Work out final addresses of sections
      while (defined($_=<ROM>) && !/^$/) {
	if (/^Size:\s+(\w+)/) {
	  $totalsize = hex($1);
	} elsif (/^Code start addr:\s+(\w+)/) {
	  $text = hex($1);
	} elsif (/^Data start addr:\s+(\w+)/) {
	  $data = hex($1);
	} elsif (/^DataBssLinearBase:\s+(\w+)/) {
	  $bss = hex($1);
	} elsif (/^Text size:\s+(\w+)/) {
	  $textsize = hex($1);
	} elsif (/^Data size:\s+(\w+)/) {
	  $datasize = hex($1);
	} elsif (/^Bsssize:\s+(\w+)/) {
	  $bsssize = hex($1);
	} elsif (/^Total data size:\s+(\w+)/) {
	  $totaldatasize = hex($1);
	}
      }

      # Sanity check - text section can't be zero
      die "ERROR: Can't find rombuild info for \"$file\"\n"
	if (!$text);

      print SYM "\nFrom    $file\n\n";

      # Look in map file for symbols in .text and relocate them
      $mapfile2 = $file.".map";
      $mapfile = $file;
      $mapfile =~ s/\.\w+$/\.map/;
      if (!(open (MAP, "$mapfile2") || open (MAP, "$mapfile"))) {
	print "$file\nWarning: Can't open \"$mapfile2\" or \"$mapfile\"\n";
	$file =~ /([^\\]+)$/;
	printf SYM "%08x    %04x    $1\n", $text, $totalsize;
      } else {
	local $/ = undef;
	my (@maplines) = split(/\n/, <MAP>);
	close MAP;
	# See if we're dealing with the RVCT output
	if ($maplines[0] =~ /^ARM Linker/) {
	  print "$file\n";
	 
		my %syms;
		my @hasharray;
		# Starts from begining of map file.		
		while (@maplines) {
		  $_ = shift @maplines;
		  if (/Global Symbols/) {
		    last;
		  } elsif (!/(ARM Code|Thumb Code)/) {
		    next;
		  }
		# name address type size section
		if (/^\s*(.+)\s*(0x\S+)\s+(ARM Code|Thumb Code)\s+[^\d]*(\d+)\s+(.*)$/) {
			# Check for static methods in local symbols section.
			my $sym = $1;
			my $addr = hex($2);
			my $size = sprintf("%04x",$4);
			my $section = $5;
			$size = sprintf("%04x", 8) if ($section =~ /\(StubCode\)/);
			if(exists($syms{$addr})) {
				push @{ $syms{$addr} }, "$size    $sym $section";	   
			}
			elsif ($addr > 0){
				@hasharray = "$size    $sym $section";
				$syms{$addr} = [@hasharray];
			}
		}
		}	
	
	  foreach (@maplines) {
	    # name address ignore size section
	    if (/^\s*(.+)\s*(0x\S+)\s+[^\d]*(\d+)\s+(.*)$/) {
	      my $sym = $1;
	      my $addr = hex($2);
	      my $size = sprintf("%04x",$3);
	      my $section = $4;
	      $size = sprintf("%04x", 8) if ($section =~ /\(StubCode\)/);
		  if(exists($syms{$addr})) {
			push @{ $syms{$addr} }, "$size    $sym $section";	   
		  }
	      elsif ($addr > 0) {
			@hasharray = "$size    $sym $section"; 
			$syms{$addr} = [@hasharray];
		  }
	    }
	  } # end of foreach

	  # .text gets linked at 0x00008000
	  # .data gets linked at 0x00400000
	  my $srctext = hex(8000);
	  my $srcdata = hex(400000);
	  my $j; 
	  # Write symbols in address order
	  my @addrs = sort CompareAddrs keys %syms;
	  for ($i = 0; $i < @addrs ; $i++) {
	    my $thisaddr = $addrs[$i];
	    my $romaddr = 0;
	    # see if its in the text segment
		if ($thisaddr >= $srctext && $thisaddr <= ($srctext+$textsize)) {
	      $romaddr = $thisaddr-$srctext+$text;
	    } elsif ( $data && ( $thisaddr >= $srcdata && $thisaddr <= ($srcdata+$datasize))) {
	      # its in the data segment
	      # is it from .data or .bss

  			# confusingly (?) $bss is the right value to use here
			# since we're interested in where the data gets copied to
			# in RAM rather than where it sits in ROM
		$romaddr = $thisaddr-$srcdata+$bss;
	      } elsif ( $bss && ( $thisaddr >= $srcdata && $thisaddr <= ($srcdata+$totaldatasize))) {
				# its BSS
		$romaddr = $thisaddr-$srcdata+$bss;
	      } else {
		my $errsym = $syms{$thisaddr}[0];
		my $erraddr = sprintf("%08x", $thisaddr);
		print "WARNING: Symbol $errsym @ $erraddr not in text or data segments\n";
		print "WARNING: The map file for binary $file is out-of-sync with the binary itself\n\n";
		next;
	      }

	    printf SYM "%08x    %s\n", $romaddr, $_ for @{$syms{$addrs[$i]}};
	  } # end of for.
        # See if we're dealing with the GCC output
	} elsif ($maplines[0] =~ /^Archive member included/) {
	  
	  my $imgtext;
	  my $textlen;
	  my %syms;
	  my $stubhex=1;

	  # Find text section
	  while (@maplines) {
	      $_ = shift @maplines;
	      last if /^\.text\s+/;
	  }

	  /^\.text\s+(\w+)\s+(\w+)/
			or die "ERROR: Can't get .text section info for \"$file\"\n";

		    $imgtext=hex($1);
		    $textlen=hex($2);

		    print "$file\n";

		# Slurp symbols 'til the end of the text section
		foreach (@maplines) {

			# blank line marks the end of the text section
			last if (/^$/);

			# .text <addr> <len>  <library(member)>
			# .text$something
			#       <addr> <len>  <library(member)>
			#       <addr> <len>  LONG 0x0

			if (/^\s(\.text)?\s+(0x\w+)\s+(0x\w+)\s+(.*)$/io) {
				my $address = hex($2);
				my $length = hex($3);
				my $libraryfile = $4;
				next if ($libraryfile =~ /^LONG 0x/);
				$syms{$address+$length} = ' ';	# impossible symbol as end marker

				# EUSER.LIB(ds01423.o)
				# EUSER.LIB(C:/TEMP/d1000s_01423.o)
				if ($libraryfile =~ /.*lib\(.*d\d*s_?\d{5}.o\)$/io) {
					$stubhex=$address;
				}
				next;
			}

			#  <addr>  <symbol name possibly including spaces>
			if (/^\s+(\w+)\s\s+([a-zA-Z_].+)/o) {
				my $addr = hex($1);
				my $symbol = $2;
				$symbol = "stub $symbol" if ($addr == $stubhex);
				$syms{$addr} = $symbol;
				next;
			}
		}

		# Write symbols in address order
		@addrs = sort CompareAddrs keys %syms;
		for ($i = 0; $i < @addrs - 1; $i++) {
			my $symbol = $syms{$addrs[$i]};
			next if ($symbol eq ' ');
			printf SYM "%08x    %04x    %s\n",
			$addrs[$i]-$imgtext+$text, $addrs[$i+1]-$addrs[$i], $symbol;
		}
		# last address assumed to be imgtext+lentext

		close MAP;
	}
	# Must be x86 output
	else {
		while (@maplines) {
	      $_ = shift @maplines;
	      last if /^  Address/;
		}
	    shift @maplines;
	    
	    my ($lastname, $lastaddr);
		while (@maplines) {
	      $_ = shift @maplines;
	      last unless /^ 0001:(\w+)\s+(\S+)/;
		  my ($addr, $name) = (hex $1, $2);
		  if ($lastname) {
			  my $size = $addr - $lastaddr;
			  printf SYM "%08x    %04x    %s\n", $lastaddr + $text, $size, $lastname;
		  }
		  ($lastname, $lastaddr) = ($name, $addr);
	    }	    
	    printf SYM "%08x    %04x    %s\n", $lastaddr + $text, 0, $lastname if $lastname;
	}
	
	    }
	  }
	}
    close SYM;
    close ROM;
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

	if ($arg=~/^[\-\/](\S*)$/) {
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

    &Load_ModuleL('E32TPVER');
    print "\nmaksym - Produce symbolic information given a ROM image (Build ",
	&E32tpver, ")\n";
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
