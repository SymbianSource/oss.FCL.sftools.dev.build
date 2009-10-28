#============================================================================ 
#Name        : ImageCreation.pl 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description: 
#============================================================================

use warnings;
#use strict;
use IPC::Open2;
use FileHandle;
use File::Copy;
use Cwd;
use Getopt::Long;

my($copyto,$MyTraces,$Drive,$product,$type);
my $result = GetOptions(
        "copyto=s"  => \$copyto,
        "mytraces=s"  => \$Mytraces,
        "Drive=s"=> \$Drive,
        "product=s"=> \$product,
        "type=s"=> \$type
        );
if((!$copyto) or (!$product) or (!$type))
  {
    &Usage;
    }

my $imagedes=$copyto;
my $Traces="\\epoc32\\rombuild";
my $pid;

if($Drive)
{
	chdir "$Drive" or die "Cannot change Directory to $Drive\n";
}

chdir ("/epoc32/rom/") or die "Cannot Change Directory to /epoc32/rom/";

if($Mytraces)
	{
		print "Removing $Traces \n";
		print unlink "$Traces\\mytraces.txt";
    `echo " " > $Traces\\mytraces.txt`;
	}
AGAIN:
#system("del *$product* 2>&1");


print system("perl BuildS60Rom.pl -product $product -type $type -b -dir $imagedes") or die "cannot open BuildS60Rom.pl";

#system("move *$product*.* $copyto");
system("move \\flash_temp\\*erase_userdisk.fpsx $copyto");
if($Mytraces)
  {
    print copy ($Mytraces,"$Traces\\myTraces.txt");;
    
    $imagedes="$copyto\\udeb";
    system ("mkdir $copyto");
    $Mytraces=();
    goto AGAIN;
  }

#system("7za a $copyto\\images.zip  $copyto\\*%USERNAME%*.*");

sub Usage
{
  print "Usage:
              imagecreation.pl -copyto <1> -MyTraces <2> -Drive <3> -product <4> -type <5>
              
                <1> Create images to specified directory [Mandatory]
                <2> Location to Mytraces.txt or any other file to-be used as mytraces
                <3> Drive where SDK is Istalled on which Image needs to be created
                <4> Supported for particular release [Mandatory]
                <5> [rnd|prd|subcon]  Set the image type [Mandatory]
        ";
        exit 0
  }
