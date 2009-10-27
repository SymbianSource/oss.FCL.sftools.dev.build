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
# Perl script to check that import stubs go to the right place
#

my $symbolfile="ba_001.engbuild.symbol";
my $imagefile="ba_001.engbuild.img";
my $imageoffset=0;	# will be read from the image header

die "Usage: checkstubs [imagefile]\n" if (@ARGV>1);
if (@ARGV==1)
	{
	$imagefile = @ARGV[0];
	$symbolfile = $imagefile;
	$symbolfile =~ s/img$/symbol/i;
	}

# 1. Read in the SYMBOL information
#
# From    \epoc32\release\ARM4\urel\netdial.agt
# 50989f5c    00c0    CImap4Utils::SendLogMessageL(int, TRequestStatus &)
# 5098a01c    000c    stub UserSvr::DllGlobalAlloc(int, int)

my %stubs;		# stub names, by address
my %funcs;		# function names, by address
my %knownfuncs;	# function names which are reported in symbol file
my $line;

open SYMBOL, "<$symbolfile" or die "Cannot open $symbolfile";
while ($line=<SYMBOL>)
	{
	if ($line =~ /^([0-9a-f]{8})\s+[0-9a-f]+\s+(.*)$/i)
		{
		my $address = hex($1);
		my $name = $2;

		$funcs{$address} = $name;
		$knownfuncs{$name} = 1;
		if ($name =~/^stub (.*)$/)
			{
			$stubs{$address} = $1;	# lots of stubs, but only one address!
			}
		}
	}
close SYMBOL;

# 2. Understand the ROM structure
#

open IMAGE, "<$imagefile" or die "Cannot open $imagefile";
binmode IMAGE;

my $stubaddress;
my $stubdata;
my $stubcount=0;
my $errors=0;
my $uncheckable=0;

read IMAGE, $stubdata, 20;
if ($stubdata =~ /^EPOC....ROM/)
	{
	$imageoffset -= 256;	# compensate for REPRO header
	}

# Read the image header to determine ROM linear address

sub read_imageword
    {
    my $imagedata;
	read IMAGE, $imagedata, 4;
    return unpack "V", $imagedata;
    }

seek(IMAGE, 0x8c-$imageoffset, 0);
my $romlinearbase = read_imageword();
my $romsize = read_imageword();
$imageoffset += $romlinearbase;

my %areas;
my %area_offsets;
$areas{$romlinearbase} = $romlinearbase+$romsize;
$area_offsets{$romlinearbase} = $imageoffset;

# Check for the extension ROM

if (seek(IMAGE, $romlinearbase+$romsize+0xC-$imageoffset,0))
	{
	my $extensionlinearbase = read_imageword();
	my $extensionsize = read_imageword();

	$areas{$extensionlinearbase} = $extensionlinearbase+$extensionsize;
	$area_offsets{$extensionlinearbase} = 
		$imageoffset+($extensionlinearbase - $romlinearbase -$romsize);
	}

sub image_seek
	{
	my ($runaddress) = @_;
	my $offset = 0;

	# Scan list of area mappings to determine correct offset
	my $areabase;
	foreach $areabase (keys %areas)
		{
		if ($areabase <= $runaddress && $areas{$areabase} > $runaddress)
			{
			$offset = $area_offsets{$areabase};
			last;
			}
		}
	if ($offset==0)
		{
		printf "Can't find area for address 0x%x\n", $runaddress, $runaddress-$imageoffset;
		$errors++;
		return 0;
		}
	#
	if (!seek(IMAGE, $runaddress-$offset, 0))
		{
		printf "Can't seek to address 0x%x => offset 0x%x\n", $runaddress, $runaddress-$imageoffset;
		$errors++;
		return 0;
		}
	return 1;
	}

# Read the area relocation information (if any)

image_seek($romlinearbase+0xd4);
my $areaptr = read_imageword();
if ($areaptr != 0)
	{
	image_seek($areaptr);
	my $areasize=0;
	while ($areasize=read_imageword())
		{
		my $srcbase=read_imageword();
		my $areabase=read_imageword();
		$areas{$areabase} = $areabase+$areasize;
		$area_offsets{$areabase} = $imageoffset+($areabase-$srcbase);
		}
	}

# 3. Scan the stubs
#

foreach $stubaddress (sort keys %stubs)
	{
	my $stub = $stubs{$stubaddress};
	$stubcount++;
	if (!image_seek($stubaddress))
		{
		printf "Can't seek to %s at x%x\n", $stub, $stubaddress;
		$errors++;
		next;
		}
	read IMAGE, $stubdata, 20;

	my @arm_instructions = (unpack "V4", $stubdata);
	my @thumb_instructions = (unpack "v6", $stubdata);

	my $address = $stubaddress;
	my $indirections =-1;
	my $finalbx = 1;

	if (@arm_instructions[0] == 0xe59fc000 &&
		@arm_instructions[1] == 0xe59cf000)
		{
		# arm4 stub
		$indirections=2;
		$address+=8;
		$finalbx = 0;
		}
	if (@arm_instructions[0] == 0xe59fc004 &&
		@arm_instructions[1] == 0xe59cc000 &&
		@arm_instructions[2] == 0xe12fff1c)
		{
		# armi stub
		$indirections=2;
		$address+=12;
		}
	if (@arm_instructions[0] == 0xe59fc004 &&
		@arm_instructions[1] == 0xe12fff1c)
		{
		# fast armi stub
		$indirections=1;
		$address+=12;
		}
	if (@thumb_instructions[0] == 0xb440 &&
		@thumb_instructions[1] == 0x4e02 &&
		@thumb_instructions[2] == 0x6836 &&
		@thumb_instructions[3] == 0x46b4 &&
		@thumb_instructions[4] == 0xbc40 &&
		@thumb_instructions[5] == 0x4760)
		{
		# thumb stub
		$indirections=2;
		$address+=12;
		}
	if (@thumb_instructions[0] == 0xb440 &&
		@thumb_instructions[1] == 0x4e02 &&
		@thumb_instructions[2] == 0x46b4 &&
		@thumb_instructions[3] == 0xbc40 &&
		@thumb_instructions[4] == 0x4760)
		{
		# fast thumb stub
		$indirections=1;
		$address+=12;
		}
	if (@thumb_instructions[0] == 0x4b01 &&
		@thumb_instructions[1] == 0x681b &&
		@thumb_instructions[2] == 0x4718)
		{
		# thumb r3unused stub
		$indirections=2;
		$address+=8;
		}
	if (@thumb_instructions[0] == 0x4b01 &&
		@thumb_instructions[1] == 0x4718)
		{
		# fast thumb r3unused stub
		$indirections=1;
		$address+=8;
		}

	if ($indirections < 0)
		{
		printf "At %08x unrecognised stub %s = %08x %08x %08x %08x\n", $stubaddress, $stub,
			@arm_instructions[0], @arm_instructions[1], @arm_instructions[2], @arm_instructions[3];
		$errors++;
		next;
		}

	my $indirection_count = $indirections;
	while ($indirection_count > 0)
		{
		if (!image_seek($address))
			{
			printf "Failed to follow %s to address 0x%x\n", $stub, $address;
			$errors++;
			last;
			}
		my $data;
		read IMAGE, $data, 4;
		$address = unpack "V", $data;
		$indirection_count -= 1;
		}
	next if ($indirection_count != 0);

	if ($finalbx)
		{
		$address &= 0xfffffffe;	# clear THUMB mode indicator
		}

	if (!defined($funcs{$address}))
		{
		if (!defined($knownfuncs{$stub}))
			{
			# we don't have a map file for the provider of this function anyway
			$uncheckable++;
			next;
			}
		printf "At %08x stub %s points to %08x, which is not a known function\n", $stubaddress, $stub, $address;
		$errors++;
		next;
		}
	if ($funcs{$address} ne $stub)
		{
		printf "At %08x stub %s points to %08x, which is %s\n", $stubaddress, $stub, $address, $funcs{$address};
		$errors++;
		next;
		}
	# Hurrah - it goes to the right place...
	}
close IMAGE;

print "Checked $symbolfile and $imagefile\n";
if ($errors==0 && $uncheckable==0)
	{
	print "All $stubcount stubs passed\n";
	}
else
	{
	print "Tested $stubcount stubs, $uncheckable couldn't be verified, found $errors errors\n";
	}
exit ($errors);
