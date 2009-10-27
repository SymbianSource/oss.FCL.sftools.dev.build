#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#

package spitool;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(createSpi);

sub binarize { #converts decimal number to 4 byte litte endian format
	my $value = shift;
	my $remainder;
	my $returnValue;
	for(my $i=0;$i<4;$i++) {
		$remainder=$value % 256;
		$returnValue.=chr($remainder);
		$value = ($value-$remainder)/256;
	}
	return $returnValue;
}

sub convertUidFromText { #converts UID from hexadeciaml text value to decimal value, passes decimal value unchanged, returns -1 if invalid UID
	my $value = shift;
	if($value =~ /^0x([\da-fA-F]{1,8})$/i) {
		return hex $1;
	} elsif ($value =~ /^\d*$/) {
		return $value;
	} else {
		return -1;
	}
}

sub bin2hex { #converts 4 byte little endian value to 0x... hex text value
	my $value=shift;
	my $byte;
	my $quotient;
	my $remainder;
	my $hexValue="";
	for(my $i=0;$i<4;$i++) {
		$byte=ord(substr($value,$i,1));
		$remainder=$byte%16;
		$quotient=($byte-$remainder)/16;
		if($remainder>9) {
			$remainder= chr($remainder+55);
		}
		if($quotient>9) {
			$quotient= chr($quotient+55);
		}		
		$hexValue=$quotient . $remainder . $hexValue;
	}
	return "0x" . $hexValue;
}

sub uidcrc { #returns decimal UID checksum value for the three inputs
	my $output = `uidcrc $_[0] $_[1] $_[2]`;
	if($output =~ /([^ ]*)$/i) {
		$output =$1;
		chomp $output;
		return hex($output);
	}	
}

sub printZeroes { #prints as many hexadecimal zeroes to OUTPUTFILE as specified by input
	my $numberOfZeroes=shift;
	for(my $i=0;$i<$numberOfZeroes;$i++) {
		print OUTPUTFILE chr(0);
	}
}

sub bytes2dec { #calculates decimal value from inputted 4 byte little endian value 
	my $bytes=shift;
	my @byteArray;
	for(my $i=0;$i<length $bytes;$i++) {
		$byteArray[$i]=ord(substr($bytes,$i,1));
	}
	my $decValue;
	for(my $i=0;$i<scalar @byteArray;$i++) {
		$decValue+=($byteArray[$i]*(2**($i*8)));
	}
	return $decValue;
}

sub print_usage
	{
#........1.........2.........3.........4.........5.........6.........7.....
	print <<USAGE_EOF;

Usage:
  spitool.pl [options] files directories   

Create an SPI file by concatenating the files and contents of directories,
based on the options passed. 

The available options are:

-tSPIFileName       -- SPIFileName is the name the produced SPI file will 
                       have (i.e. ecom-0-0.spi). If not specified, the name 
                       will be ecom-0-0.spi by default
-dTargetDir         -- TargetDir is the directory where the SPI file should
                       be created, ending with a \
-iExisting          -- Existing is address and name of existing SPI file to
                       concatenate specified files to 
-uid<x>=<y>         -- <x> has value 1, 2 or 3, <y> is an UID value in
                       decimal or 0x... hexadecimal
-existinguid<x>=<y> -- <x> has value 1, 2 or 3, <y> is an UID value in 
                       decimal or 0x... hexadecimal
-existinguidcrc=<x> -- <x> is an UID value in decimal or 0x.. hexadecimal
-hide<ResourceFileNames> -- <ResourceFileNames> is the list of the resource files
			    that are to be hidden in the SPI file separated by
			    space or comma.
  
If an existing SPI file is specified with the -i option then this file is
used as a base and other data files are added to the end of this file,
otherwise a new SPI file is created. In either case the produced SPI file
is placed in the directory specified by the -d option and given the name 
specified with the -t option.

Files which are to be concatenated into the SPI file should be specified
on the command line by either specifying the file's name (and location), or
by including a directory name, in which case all files from that directory
will be included.

The -uid options can be used to filter files for inclusion in the SPI file.
This option can be included multiple times, so a list of UID1 values can be
built up, and the same for UID2 and UID3 values. Each file on the command
line is compared with this list, and if any of its UID values match a
relevant value in the UID lists then that file will be included in the SPI
file. If the file does not match any values it will be excluded.

The -existinguid options allow the UID values that an existing SPI file
should have to be specified. This will allow the possibility of checking
that the correct type of files are being concatenated together.

The -hide option can be used to mark a resource file as hidden in the SPI file.
To mark a resource file as a hidden entry in the SPI file, the resource data 
length will be written as 0.

USAGE_EOF
	}

sub createSpi 
	{
	my @resourceFiles=();
	my @hideresourceFiles=();
	my $spiFileName;
	my $targetDirectory;
	my $existingSpiFileName;
	my @uid;
	my @uidLengths = (0, 0, 0, 0);
	my @uid1;
	my @uid2;
	my @uid3;
	my @existingUid = (-1,-1,-1,-1);
	my $uidNumber;
	my $defaultSpiFileName = "ecom-0-0.spi";
	my $defaultTargetDirectory = "$ENV{EPOCROOT}epoc32\\tools\\";
	my @defaultUid = (-1,-1,-1,-1);
	
##########################################################################################
# Reading arguments phase
##########################################################################################

	foreach my $arg (@_) {
		if ($arg =~ /^-t(.*)/i) { # set target SPI file
			$spiFileName = $1;
			next;
			}
		if ($arg =~ /^-d(.*)/i) { # set target ouput directory
			my $tempDirectory=$1;
			if((-d $tempDirectory) ) {
				$targetDirectory = $tempDirectory;
				next;
				}
				else
				{
				 print "Output directory \'",$tempDirectory,"\' does not exist.\n";
				 exit(1);
				 }				
			}
		if ($arg =~ /^-i(.*)/i) { # existing SPI file to use as a base
			my $tempFileName = $1;
			if((-e $tempFileName) && (!(-d $tempFileName))) {
				$existingSpiFileName = $tempFileName;
				next;
				}
			}
		if ($arg =~ /^-uid([1-3])\=(.*)/i) {
			$uid[$1-1][$uidLengths[$1-1]++] = $2;
			next;
			}
		if($arg=~/^-existinguidcrc\=(.*)/i) {
			$existingUid[3]=$1;
			next;
			}
		if ($arg =~ /^-existinguid([1-3])\=(.*)/i) {
			$existingUid[$1-1]=$2;
			next;
			}
		if ($arg =~ /^-hide(.*)/i) { # Collect the files to be hidden
			my $line = $1;
			$line =~ s/,/ /g;
			my @files = split(' ' , $line);
			foreach my $file (@files)
			{
				push @hideresourceFiles, $file;
			}
			next;
			}
		if (-d $arg) {
			if(($arg =~ m-^.:-) && ($arg =~ m-\\$-)) {
				unless(opendir(DIRECTORY, $arg)) { print "Exiting: $arg"; exit; }
				while (my $file=readdir(DIRECTORY)) {
					my $newfile = $arg.$file;
					if(!(-d $newfile)) {
						push @resourceFiles, $newfile;
					}
				}
				close(DIRECTORY);
				next;
				}
			}
		if ((-e $arg) && (!(-d $arg))) {
			push @resourceFiles, $arg;
			next;
			}
		if ($arg eq "-h") {
			print_usage;
			exit(1);
		}	
		print "Unknown command: $arg\n";
	}

#####################################################################################
# UID phase
#####################################################################################
		
	if(!(defined $spiFileName)) { #use default file name if none passed on command line
		$spiFileName = $defaultSpiFileName;
	}
	if(!(defined $targetDirectory)) { #use default target dir if none passed on command line
		$targetDirectory = $defaultTargetDirectory;
	}
	for(my $i=0;$i<3;$i++) { #if default UIDs specified then added to UID match lists
		if($defaultUid[$i]>=0) {
			$uid[$i][$uidLengths[$i]++] = $defaultUid[$i];
		}
	}
	for(my $i=0;$i<3;$i++) { #makes sure UIDs are valid UIDs
		my @tempUidArray;
		my $iterator=0;
		while(defined $uid[$i][$iterator]) {
			my $convertedUid=convertUidFromText($uid[$i][$iterator]);
			if ($convertedUid != -1) {
				push @tempUidArray, binarize($convertedUid);
			} else {
				print "Invalid UID: $uid[$i][$iterator]\n";
			}
			$iterator++;
		}
		for(my $j=0;$i<scalar @tempUidArray;$j++) {
			$uid[$i][$j]=$tempUidArray[$j];
		}
		for(my $j=scalar@tempUidArray;defined $uid[$i][$j];$j++) {
			undef $uid[$i][$j];
		}
	}
#####################################################################################
# Phase to split up resource names
#####################################################################################

	my @resourceFilePaths;
	my @resourceFileNames;
	my @resourceExtensions;
	my @filestobehidden;

# To mark the resource files as hidden in the SPI file by writing the data length as zero
	foreach my $file (@hideresourceFiles)
	{
		my $matchfound =0;
		my $i=0;
		for(;$i<scalar @resourceFiles && !$matchfound;$i++)
		{
			if (lc($file) eq lc($resourceFiles[$i]))
			{
				$filestobehidden[$i] = 1;
				$matchfound =1;
			}
		}
		if (!$matchfound)
		{
# Those files that are to be hidden in the SPI file but not existing in the SPI
			if (! -e $file)
			{
				print "Warning: Hiding non-existent file $file\n";
			}
			push @resourceFiles,$file;
			$filestobehidden[$i] = 1;
		}
	}
	
	for(my $i=0;$i<scalar @resourceFiles;$i++) {
		if($resourceFiles[$i]=~m|\\|) {
			if($resourceFiles[$i]=~m|(.*)\\([^\\]*)$|) {
				$resourceFilePaths[$i]=$1;
				$resourceFileNames[$i]=$2;
			}
			if($resourceFileNames[$i]=~m|(.*)\.([^\.]*)|) {
				$resourceFileNames[$i]= $1;
				$resourceExtensions[$i]=$2;
			}
		} else {
			$resourceFilePaths[$i]="";
			if($resourceFiles[$i]=~m|(.*)\.([^\.]*)|) {
				$resourceFileNames[$i]= $1;
				$resourceExtensions[$i]=$2;
			}
		}
	}
	
	my %uid2values; #hash to hold UID2 values for each type of SPI file
	$uid2values{"ecom"} = 270556204;

##########################################################
# Existing file stage
##########################################################

	my @spiUid = (270556203, 0, 0); #holds spi values (including CRC value)
	foreach my $key (keys(%uid2values)) { #searches through SPI types to match UID2 value
		if($spiFileName =~/^$key/) {
			$spiUid[1]=$uid2values{$key};
		}
	}
	$spiUid[3] = uidcrc($spiUid[0], $spiUid[1], $spiUid[2]);
	my $total=0; #used to keep track of position in SPI file
	my $buffer;
	my $spifile=File::Spec->catpath( "", $targetDirectory, $spiFileName );
 	open OUTPUTFILE, ">$spifile" or die $!;
	binmode (OUTPUTFILE);
	if($existingSpiFileName) {
		open EXISTINGFILE, "$existingSpiFileName" or die $!;
		binmode (EXISTINGFILE);

		my @fileNameLengths;
		my @fileLengths;
		my @fileNames;
		my @fileContents;

		read(EXISTINGFILE,$buffer,4);
		read(EXISTINGFILE,$buffer,4);
		if(bytes2dec($buffer)!=$spiUid[1]) {
			print "Incompatible SPI files.\n";
		}
		read(EXISTINGFILE,$buffer,24);
		$total=32;
		my $existingSpiFileSize = (stat(EXISTINGFILE))[7];
		while($total<$existingSpiFileSize) { #loop to store information from files which are not being replaced
			read(EXISTINGFILE,$buffer,4);
			push @fileNameLengths, bytes2dec($buffer);
			read(EXISTINGFILE,$buffer,4);
			push @fileLengths, bytes2dec($buffer);
			read(EXISTINGFILE,$buffer,$fileNameLengths[$#fileNameLengths]);
			push @fileNames, $buffer;
			$total=$total+8+$fileNameLengths[$#fileNameLengths]+$fileLengths[$#fileLengths];
			my $padding = (4-(($fileNameLengths[$#fileNameLengths]+$fileLengths[$#fileLengths])%4))%4;
			read(EXISTINGFILE,$buffer,$fileLengths[$#fileLengths]+$padding);
			push @fileContents, $buffer;
			$total += (4-($total%4))%4;			
		}
		close EXISTINGFILE;	
		#next part prints to OUTPUTFILE the header and files which are not being replaced
		print OUTPUTFILE binarize($spiUid[0]) . binarize($spiUid[1]) . binarize($spiUid[2]) . binarize($spiUid[3]);
		printZeroes(16);
		$total=32;
		for(my $i=0; $i<scalar @fileNames; $i++) {
			my $flag=1;
			for(my $j=0; $j<scalar @resourceFileNames && $flag==1; $j++) {
				if($fileNames[$i] eq $resourceFileNames[$j]) {
					$flag=0;
				}
			}
			if($flag) {
				print OUTPUTFILE binarize($fileNameLengths[$i]) . binarize($fileLengths[$i]) . $fileNames[$i] . $fileContents[$i];
				$total=$total+8+length($fileNames[$i])+length($fileContents[$i]);
			}
		}
	} else { #prints header for target SPI file if there is no existing SPI file
		print OUTPUTFILE binarize($spiUid[0]) . binarize($spiUid[1]) . binarize($spiUid[2]) . binarize($spiUid[3]);
		printZeroes(16);
		$total=32;
	}

####################################################################
# Appending new data files to the SPI file
####################################################################

	my $resourceFileSize;
	my $resourceFileSizeInBinary;
	my $resourceFileNameSize;
	my $resourceFileNameSizeInBinary;
	for(my $i=0; $i<scalar @resourceExtensions;$i++) {
# To mark the resource files as hidden in the SPI file by writing the data length as zero
	   if ($filestobehidden[$i] == 1)
	   {
		$resourceFileNameSize = length($resourceFileNames[$i]);
		$resourceFileNameSizeInBinary = binarize($resourceFileNameSize);
		$resourceFileSize = 0;
		$resourceFileSizeInBinary = binarize($resourceFileSize);
		print OUTPUTFILE $resourceFileNameSizeInBinary . $resourceFileSizeInBinary . $resourceFileNames[$i];
		$total+=$resourceFileNameSize;
		my $padding = (4-(($resourceFileSize + $resourceFileNameSize)%4))%4;
		printZeroes($padding);
		$total+=$padding;
	   }
	   else
	   {
		open RESOURCEFILE, "<$resourceFiles[$i]";
		binmode(RESOURCEFILE);
		my @fileUid; #stores UIDs from particular data file
		my $fileUid1;
		my $fileUid2;
		my $fileUid3;
		read(RESOURCEFILE,$fileUid[0],4);
		read(RESOURCEFILE,$fileUid[1],4);
		read(RESOURCEFILE,$fileUid[2],4);
		my $uidFlag=0; #changes to 1 if a UID value in data file matches a specified UID value
		my $uidExists=1; #changes to 1 if there are specified UIDs to match to
		for(my $j=0;$j<3 && (!$uidFlag);$j++) {
			my $k=0;
			while(defined $uid[$j][$k] && (!$uidFlag)) {
				$uidExists=0;
				if($uid[$j][$k] eq bin2hex($fileUid[$j])) {
					$uidFlag=1;
				}
				$k++;
			}
		}	
		if(($uidFlag) || ($uidExists)) { #if suitable UIDs writes data file to SPI file
			$resourceFileSize = (stat(RESOURCEFILE))[7];
			$resourceFileNameSize = length($resourceFileNames[$i]);
			$resourceFileNameSizeInBinary = binarize($resourceFileNameSize);
			$resourceFileSizeInBinary = binarize($resourceFileSize);
			print OUTPUTFILE $resourceFileNameSizeInBinary . $resourceFileSizeInBinary . $resourceFileNames[$i];
			print OUTPUTFILE "$fileUid[0]$fileUid[1]$fileUid[2]";
			while(read(RESOURCEFILE,$buffer,1)) {
				print OUTPUTFILE $buffer;
			}
			$total+=$resourceFileSize;
			$total+=8;
			$total+=$resourceFileNameSize;
			my $padding = (4-(($resourceFileSize + $resourceFileNameSize)%4))%4;
			printZeroes($padding);
			$total+=$padding;
		}
	   }
	}
	print "Created $spiFileName\n";
}


1;
