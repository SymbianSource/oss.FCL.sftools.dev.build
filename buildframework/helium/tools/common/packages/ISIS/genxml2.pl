#!/usr/bin/perl -w

#============================================================================ 
#Name        : genxml2.pl 
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

#------------------------------------------------------------------------------
# Name   : genxml2.pl
# Use    : description.
#
# Synergy :
# Perl %name: genxml2.pl % (%full_filespec:  genxml2.pl-1:perl:fa1s60p1#2 %)
# %date_created:  Thu Jan 12 10:13:06 2006 %
#
# Version History :
#
# 1 (19/09/2005) :
#  - Fist version of the script.
#  - This script takes a text input file and translate it to a TBS XML compliant file.
#------------------------------------------------------------------------------

use strict;
use Getopt::Long;
use ISIS::GenXML2;
Getopt::Long::Configure ("bundling_override");

# ISIS constants.
use constant ISIS_VERSION 		=> '1.0';
use constant ISIS_LAST_UPDATE => '19/09/2005';

#------------------------------------------------------------------------------
# Main script.
#------------------------------------------------------------------------------


my $input = undef;
my $help = 0;
my @defines = ();
GetOptions("D=s@" => \@defines,"i|input=s" =>\$input,"h|help" => \$help );

&Usage() if ($help);
unless ($input) { print "You must specify an input file.\n"; &Usage();	 }

my $parser = new GenXML2();
my @args;
foreach(@defines)
{
	push @args, "-D$_";
}

my $output = $input;
$output  =~ s/\..*$/\.xml/;
print "Output file: $output\n";
$parser -> parseFile("$input", @args);
$parser -> generateTBSXML("$output");



#------------------------------------------------------------------------------
# Script usage.
#------------------------------------------------------------------------------
sub Usage
{
	print " genxml2.pl - v".ISIS_VERSION." - ".ISIS_LAST_UPDATE."\n";
	print " Usage : genxml2 \n";
	print <<EOC;
	
	-h, -help        this help screen
	-i               an input file
	-DXXX            a define
	
	Input file specification
		Keywords:
			- 'NEWSTEP' Increment step ID
		
		line format is the following:
		name,path,"cmd"
			name is a display name,
			path to the location you want to execute the command 'cmd'
			cmd is the command to execute.
			
EOC
	exit 0;
}

#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
