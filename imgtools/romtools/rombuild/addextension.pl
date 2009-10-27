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
# Concatenate an extension ROM onto the core ROM.
# Works for ROMBUILD XIP ROMs and ROFSBUILD non-XIP ROMs
#

use strict;

if (@ARGV<2 || @ARGV>3)
	{
#........1.........2.........3.........4.........5.........6.........7.....
	print <<USAGE_EOF;

Usage:
  addextension  <kernelRom> <extensionRom> [<outputfile>]

If <extensionRom> doesn\'t exist, addextension will try concatenating
the <kernelrom> and <extensionrom> names.
If no <outputfile> is specified, the default is sys\$rom.bin

USAGE_EOF
	exit(1);
	}

my $kernelROM = @ARGV[0];
my $extensionROM = @ARGV[1];
my $outputfile = "sys\$rom.bin";
$outputfile = @ARGV[2] if (@ARGV==3);

open KERNEL, "<$kernelROM" or die "Cannot open $kernelROM";
binmode KERNEL;

if (!open EXTENSION, "<$extensionROM")
    {
    open EXTENSION , "<$kernelROM$extensionROM" or
	die "Cannot open $extensionROM or $kernelROM$extensionROM";
    $extensionROM = $kernelROM.$extensionROM;
    }
binmode EXTENSION;

open RESULT, ">$outputfile" or die "Cannot open $outputfile for output";
binmode RESULT;

print "Writing $kernelROM + $extensionROM to $outputfile\n";

my $reproheader = "";
read KERNEL, $reproheader, 256;
if ($reproheader !~ /^EPOC....ROM/)
	{
	seek KERNEL, 0, 0;  # No REPRO header, rewind back to the start
	$reproheader = "";
	}

my $kerneldata;
read KERNEL, $kerneldata, 4096;

my $kernelsize;
my $imagesize;
if ($kerneldata =~ /^ROFS/)
	{
	$imagesize = unpack "V", substr($kerneldata, 0x24, 4);
	$kernelsize = unpack "V", substr($kerneldata, 0x2c, 4);
	printf "ROFS size:              0x%08x ", ($imagesize);
	}
else
	{
	$kernelsize = unpack "V", substr($kerneldata, 0x90, 4);
	}
printf "\nCore ROM maximium size: 0x%08x", $kernelsize;


if ($reproheader ne "")
	{
	# Add REPRO header to output, but update image size
	my $tmp;
	read(EXTENSION, $tmp, 128);
	seek EXTENSION, 0, 0;

	my $extensionsize = unpack "V", substr($tmp, 0x10, 4);
	substr($reproheader, 0x18, 4) = pack "V", $extensionsize+$kernelsize;

	syswrite RESULT, $reproheader;
	}

$kernelsize -= syswrite RESULT, $kerneldata;
while (read(KERNEL, $kerneldata, 4096))
    {
    $kernelsize -= syswrite RESULT, $kerneldata, $kernelsize;
    }
close KERNEL;

# Pad the data to the full size of the kernel ROM image

$kerneldata = "\377\377\377\377";				# 4
$kerneldata = $kerneldata.$kerneldata.$kerneldata.$kerneldata;	# 16
$kerneldata = $kerneldata.$kerneldata.$kerneldata.$kerneldata;	# 64
$kerneldata = $kerneldata.$kerneldata.$kerneldata.$kerneldata;	# 256
$kerneldata = $kerneldata.$kerneldata.$kerneldata.$kerneldata;	# 1024
$kerneldata = $kerneldata.$kerneldata.$kerneldata.$kerneldata;	# 4096

while ($kernelsize > 0)
    {
    $kernelsize -= syswrite RESULT, $kerneldata, $kernelsize;
    }

# Stick the extension ROM on the end

my $extensiondata;
while (read(EXTENSION, $extensiondata, 4096))
    {
    syswrite RESULT, $extensiondata;
    }
close RESULT;
