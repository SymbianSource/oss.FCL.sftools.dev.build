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
my $readsortedarrays = 1;
my $imagetype="none";

sub usage_and_die
{
die "Usage: $0 [-no-sorted-arrays] [imagefile]\n";
}

usage_and_die() if (@ARGV>2);

foreach(@ARGV)
	{
	if (uc($_) eq '-NO-SORTED-ARRAYS')
		{
		$readsortedarrays = 0;
		}
	else
		{
		$imagefile = $_;
		}
	}

#
#
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
else
	{
	# No REPRO header, rewind back to the start
	seek(IMAGE,0, 0)
	}

#
# identify the image type
#

my $coresize=0;
my $id=readword(0);
if ($id == 0x53464f52)	# ROFS
	{
	$coresize=readword(0x2c);	
	printf "Core ROFS ROM image: %s\n", $imagefile;
	$imagetype="ROFS";
	$romrootdirectory = readword(8);
	}
elsif ($id == 0x78464f52) # ROFx
	{
	printf "Extension ROFS ROM image: %s\n", $imagefile;
	$imagetype="ROFx";
	exit (1);
	}
else
    {
    printf "Unknown ROM image type: %s\n", $imagefile;
	exit (1);
    }

#
#
#

my @directories;
push @directories, $romrootdirectory;
if (seek(IMAGE, $coresize+8, 0))
	{
	my $extdir=0;
	$extdir=readword($coresize+8);
	if ($extdir) {
		push @directories, $extdir;
		printf "Extended ROFS @ %08x\n", $coresize;
		}
	}

my $root;
foreach $root (@directories)
    {
    printf "\n\nDirectory @ 0x%08x:\n", $root;
    print_directory($root, "");
    }

my %seen_before;

sub print_sortedarrays
{
	return if (!$readsortedarrays);
	my $entry = shift ;
	my $prefix = shift;
	my $sortedarrayptr=$entry+4;
	my $dircount=readshort($entry);
	my $filecount=readshort($entry+2);

	printf "%s dirs[%d]=[",$prefix, $dircount;
	while ($dircount--)
		{
		printf "%04x",readshort($sortedarrayptr);
		printf "," if $dircount;
		$sortedarrayptr+=2;
		}
	print "]\n";

	printf "%s files[%d]=[",$prefix,$filecount;
	while ($filecount--)
		{
		printf "%04x",readshort($sortedarrayptr);
		printf ","  if $filecount;
		$sortedarrayptr+=2;
		}
	print "]\n";

}

sub print_entry
	{
 	my ($entry, $prefix) = @_;
	
	my $size = readshort($entry);
	my $nameoffset = readbyte(-1);
	my $attributes = readbyte(-1);
	my $filesize = readword(-1);

	my $fileoffset = readword(-1); # fileaddr
	my $attributesextra = readbyte(-1);

	my $namelen = readbyte(-1);
	my $name = readimage($namelen*2, -1);
	$name =~ s/(.)./$1/g;	# drop high byte of Unicode characters

	printf "%s %s\t%08x %02x %3d %08x\n", $prefix,$name, $entry, 
				$attributes, $filesize, $fileoffset;

	}

sub print_directory
    {
    my ($dir, $prefix) = @_;
    if ($seen_before{$dir} == 1)
		{
		printf "%s ...\n", $prefix;
		return;
		}
    $seen_before{$dir} = 1;
	my $dirstructsize=readshort($dir);
	my $firstentryoffset=readbyte($dir+3);
	my $entry = $dir+$firstentryoffset;
	my $end = $dir+$dirstructsize;

	# print the files in this dir
	#
	my $fileblockoffset = readword($dir+4);
	my $fileblocksize	= readword($dir+8);
	while ($fileblocksize>0)
		{
		my $fileentrysize=readshort($fileblockoffset);
		print_entry($fileblockoffset, "$prefix");
		$fileblocksize-=$fileentrysize;
		$fileblockoffset+=$fileentrysize;
		}

	# print the sub dirs
	my $firstentry = $entry;
    while ($entry < $end)
		{
		my $size = readshort($entry);
		my $nameoffset = readbyte(-1);
		my $attributes = readbyte(-1);
		my $filesize = readword(-1);

		my $fileoffset = readword(-1); # fileaddr
		my $attributesextra = readbyte(-1);

		my $namelen = readbyte(-1);
		my $name = readimage($namelen*2, -1);
		$name =~ s/(.)./$1/g;	# drop high byte of Unicode characters

		printf "%s %s\\\t%08x \n", $prefix, $name, $entry;
		print_directory($fileoffset, "$prefix |");

		$entry += $size;
		$entry = ($entry+3)&~3;
		}

    }



#
# read image subroutines
#

sub readimage
    {
    my ($length, $linaddr) = @_;
    my $imagedata;

	if ($linaddr>=0)
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

sub readbyte
	{
	my ($linaddr) = @_;
    return unpack "C", readimage(1, $linaddr);
    }

sub readword
    {
    my ($linaddr) = @_;
    return unpack "V", readimage(4, $linaddr);
    }

sub readshort
	{
	my ($linaddr) = @_;
	return unpack "v", readimage(2, $linaddr); # unsigned short in little-endian
	}
