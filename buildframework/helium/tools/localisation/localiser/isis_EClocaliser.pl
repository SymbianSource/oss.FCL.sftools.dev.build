#!/usr/bin/perl -w

#============================================================================ 
#Name        : isis_EClocaliser.pl 
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
use strict;
use FindBin;
use lib "$FindBin::Bin/.";
use POSIX qw(strftime);
use ECLocaliser;
use Getopt::Long;
use ISIS::Logger2;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.1.2';
use constant ISIS_LAST_UPDATE => '03/11/2006';

use constant ISIS_PREP_STATE    => 0;
use constant ISIS_BUILD_STATE    => 1;
use constant ISIS_CLEANUP_STATE    => 2;
#------------------------------------------------------------------------------
# Main script.
#------------------------------------------------------------------------------


my @locinfolist;
my @locinfoincludedir;
my $langs;
my $help = 0;
my $product = undef;
my $dolocal = 1;
my $keepgoing = 0;
my $s60locfiles = undef;
my $destdir = undef;
my $logname = "isis_localiser.html";
my @romflags;
my $dtdsupport = 1;
my $state = ISIS_PREP_STATE;
my $ecBuild = 0;
my $bldfileName = undef;

# To get -D option working
Getopt::Long::Configure ("pass_through");

# Reading command line
GetOptions( 'c=s' => \$langs,
					  'i=s'=> \@locinfolist,
					  'includepath=s' => \@locinfoincludedir,
					  'h!' => \$help,
					  'k' => \$keepgoing,
					  'p=s' => \$product,
					  'local!' => \$dolocal,
					  's60locfiles=s'	=> \$s60locfiles,
					  'dest=s'	=> \$destdir,
					  'dtd!' => \$dtdsupport,
					  'l=s' => \$logname,
					  'state=i'=> \$state,
					  'b=s' => \$bldfileName,
					  'ecbuild!' => \$ecBuild) or &Usage();					  

foreach(@ARGV)
{
	push @romflags, $1 if (/^-D(\S+)$/);
}


# Set S60LocFiles default location
&Localiser::DefaultLocPath($s60locfiles);

OUT2XML::SetXMLLogName( $logname );
OUT2XML::SetXMLLogInterface("http://fawww.europe.nokia.com/isis/isis_interface");
OUT2XML::SetXMLLogVerbose("on");
OUT2XML::OpenXMLLog();
OUT2XML::Header("ISIS Localiser");
OUT2XML::OpenMainContent("Localisation");

if($state == ISIS_PREP_STATE ){

	my $time1 = time();

	if (not defined($langs) or scalar (@locinfolist)==0)
	{
		&Usage();
		exit 0;
	}
	
	print "ecbuild......$ecBuild";

	OUT2XML::OpenEvent ("Previous cleanup if any!\n");
	Localiser::DeleteOriginalLocFiles();
	OUT2XML::CloseEvent ();
	
	if ( -e "LocEE.zip" )
	{
		OUT2XML::OpenEvent ("Unzip EE!\n");
		OUT2XML::Print (scalar(`unzip -o -d \\ LocEE.zip 2>&1`));
		unlink ("LocEE.zip");
		OUT2XML::CloseEvent ();
	}

	# Get the language list
	my @languagelist = split(/\s+/, $langs);
	
	
	my $localiser = new Localiser(\@locinfolist, \@languagelist, \@locinfoincludedir, $bldfileName, $destdir);
	
	# Set keepgoing option
	$localiser->Keepgoing($keepgoing);
	
	$localiser->SetLoggerPackage( "OUT2XML" );
	$localiser->Initialise();
	
	OUT2XML::OpenEvent ("Checking configuration\n");
	unless ( $localiser->CheckConfig() )
	{
		OUT2XML::Error ("Config uncorrect!\n");
		OUT2XML::Die ( 0 );
	}
	OUT2XML::CloseEvent ();
	
	
	
	if ($dtdsupport)
	{
		OUT2XML::OpenEvent ("Copy DTDs\n");
		DTDHandler::HandleDTD(&Localiser::DefaultLocPath(),);
		foreach my $lid (@languagelist)
		{
			DTDHandler::CopyDTDFiles($lid, &Localiser::DefaultLocPath());
		}
		OUT2XML::CloseEvent ();
	}
	
	OUT2XML::OpenEvent ("Preparing localisation Build Area\n");
	$localiser->PrepareLocalisation( "LocEE.zip");
	OUT2XML::CloseEvent ();

	OUT2XML::OpenEvent ("Generating build files\n");
	if($ecBuild){
		$localiser->GenerateMakefiles( );
	}else {
		$localiser->GenerateXMLFiles( );
	}
	my $time2 = time();

	print ("Total Time 1 state:" .($time2-$time1)."\n");	
}elsif($state == ISIS_BUILD_STATE){
	
	
	OUT2XML::OpenEvent ("Building\n");
	LocaliseTBS::Localise($bldfileName);
	#$localiser->Localise();
	OUT2XML::CloseEvent ();
}elsif($state eq ISIS_CLEANUP_STATE){

	my $time1 = time();
	Localiser::SaveGeneratedResources($destdir,$bldfileName);
	Localiser::DeleteOriginalLocFiles();
	# Get the language list
	my @languagelist = split(/\s+/, $langs);

	if ($help)
	{
		OUT2XML::OpenEvent ("Coping helps!\n");
			HelpManagement::Copy( \@languagelist, "\\s60\\S60Helps\\Data", $destdir);
		OUT2XML::CloseEvent ();
	}
	
	
	if ($dolocal)
	{
		OUT2XML::OpenEvent ("Generating locales_xx.iby!\n");
			Locales::CreatesLocales( \@languagelist, $product, \@romflags, $destdir );
		OUT2XML::CloseEvent ();
	}	
	my $time2 = time();

	print ("Total Time 3 state:" .($time2-$time1)."\n");

	#OUT2XML::OpenEvent ("Cleaning up!\n");
	#$localiser->Cleanup( );
	#OUT2XML::CloseEvent ();
	
	OUT2XML::OpenEvent ("Unzip EE!\n");
	OUT2XML::Print (scalar(`unzip -o -d \\ LocEE.zip 2>&1`));
	unlink ("LocEE.zip");
	OUT2XML::CloseEvent ();
}



#my $seconds = ($time2-$time1);
#OUT2XML::OpenSummary("Localiser");
#OUT2XML::SummaryElmt("Input list", join(' ',@locinfolist));
#OUT2XML::SummaryElmt("Include path", join(' ',@locinfoincludedir));
#OUT2XML::SummaryElmt("Language list", $langs);
#OUT2XML::SummaryElmt("Custom destination directory", $destdir) if ($destdir);
#OUT2XML::SummaryElmt("Total time", scalar(@languagelist). " language(s) built in ".strftime ("%H:%M:%S", localtime($seconds)));
#OUT2XML::SummaryElmt("Time per language", $seconds/scalar(@languagelist). "s/language");
#OUT2XML::CloseSummary();


OUT2XML::CloseMainContent();
OUT2XML::CloseXMLLog();

#------------------------------------------------------------------------------
# Script usage.
#------------------------------------------------------------------------------
sub Usage
{
	print " isis_localiser.pl - v".ISIS_VERSION." - ".ISIS_LAST_UPDATE."\n";
	print " Usage : isis_localiser.pl [-c=\"01 02...\"] [-i=\\locinfo_xxx.txt]\n\n";
  print " Main flags:\n";
	print "    -c=\"01 02\"                       specify the language list of language to build.\n";
	print "    -i=locinfo_xxx.txt                 specify a loc info file to use, can be use more that once.\n";
	print "    -h                                 enable help management.\n";
	print "    -k                                 keepgoing, do not leave if error.\n";
	print "    -s60locfiles=\\s60\\s60locfiles    set a different default delivery.\n";
	print "    -dest=\\path                       set default destination configuration (default /zips).\n";
	print "    -nolocal                           do not create locales ibys.\n";
	print "    -l=logname.html                    change the logger output to logname.html(isis_logger.html).\n";
	print "\n Optional flags:\n";                 
	print "    -p=product                         used to rename locales iby in product_locales_xx.iby.\n";
	print "    -DFLAG                             used to parse locales iby.\n";
	exit 0;
}

#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
