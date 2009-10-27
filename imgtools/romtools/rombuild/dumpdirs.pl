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
# Perl script to dump the ROM root directory
#

my $imagefile="ba_001.engbuild.img";
my $imageoffset=0;

die "Usage: checkstubs [imagefile]\n" if (@ARGV>1);
if (@ARGV==1)
	{
	$imagefile = @ARGV[0];
	$symbolfile = $imagefile;
	}

# 1. Read the root directory list
#

open IMAGE, "<$imagefile" or die "Cannot open $imagefile";
binmode IMAGE;

my $imagedata;
my $errors=0;
my $romrootdirectory;

read IMAGE, $imagedata, 20;
if ($imagedata =~ /^EPOC....ROM/)
	{
	$imageoffset -= 256;	# compensate for REPRO header
	}

sub readimage
    {
    my ($length, $linaddr) = @_;
    my $imagedata;
    if ($linaddr != 0)	# read from next address
	{
	if (!seek(IMAGE, $linaddr-$imageoffset, 0))
	    {
	    printf "Can't seek to address 0x%x\n", $linaddr;
	    $errors++;
	    return "";
	    }
	}
    read IMAGE, $imagedata, $length;
    return $imagedata;
    }

sub readword
    {
    my ($linaddr) = @_;
    return unpack "V", readimage(4, $linaddr);
    }

# really want read from address 0, but readword does not allow it
# so need to read from word 1 and mask out extra byte read
if ((readword(1) & 0x00ffffff) == 0x00EA0000)
    {
    printf "Kernel ROM image: %s\n\n", $imagefile;
    $imageoffset += readword(0x8c);
    readword();	# image size
    $romrootdirectory = readword();
    }
else
    {
    printf "Extension ROM image: %s\n\n", $imagefile;
    $imageoffset += readword(0x0c);
    readword();	# image size
    $romrootdirectory = readword();
    }

my $numroots = readword($romrootdirectory);
printf "Rom Root Directory List at 0x%08x - %d entries\n", $romrootdirectory, $numroots;

my @directories;
my $root;
while ($numroots)
    {
    my $variant = readword();
    $root = readword();
    $numroots -= 1;
    printf "Variant 0x%08x @ 0x%08x\n", $variant, $root;
    push @directories, $root;
    }

foreach $root (@directories)
    {
    printf "\nDirectory @ 0x%08x:\n", $root;
    print_directory($root, "");
    }

my %seen_before;

sub print_directory
    {
    my ($dir, $prefix) = @_;
    if ($seen_before{$dir} == 1)
	{
	printf "%s ...\n", $prefix;
	return;
	}
    $seen_before{$dir} = 1;
    my $entry = $dir+4;
    my $end = $entry+readword($dir);

    while ($entry < $end)
	{
	my $size = readword($entry);
	my $linaddr = readword();
	my $attributes = unpack "C", readimage(1);
	my $namelen = unpack "C", readimage(1);
	my $name = readimage($namelen*2);
	$name =~ s/(.)./$1/g;	# drop high byte of Unicode characters

	if ($attributes & 0x10)
	    {
	    printf "%s %08x %02x %s\\\n", $prefix, $linaddr, $attributes, $name;
	    print_directory($linaddr, "$prefix |");
	    }
	else
	    {
	    printf "%s %08x %02x %6d %s%s\n", $prefix, $linaddr, $attributes, $size,
		($seen_before{$linaddr}==1?" *":""), $name;
    	    $seen_before{$linaddr} = 1;
	    }
	$entry += 10 + $namelen*2;
	$entry = ($entry+3)&~3;
	}
    }
