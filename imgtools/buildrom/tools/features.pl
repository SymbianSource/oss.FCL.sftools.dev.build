#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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

# features tool version
use constant TOOL_VERSION=>"0.2";

# global variables
my $PerlLibPath;    # fully qualified pathname of the directory containing our Perl modules
my $ibyPath; # destination path for the iby files
my $hdrPath; # destination path for the header files
my $datPath; # destination path for the features.DAT file
my $convPath; # destination path for the feature registry database convertion
my $epocroot = $ENV{EPOCROOT}; # epcoroot directory

#
# xml database file name(s)
#
my @xmlDBFile;

#
# flags to suppress the output files
# 0x01 = generate header files only
# 0x02 = genereate iby files only
# 0x04 = generate dat files only
# 0x08 = convert feature registry database to feature manager database
#
use constant FLG_GENHDR=>0x01;
use constant FLG_GENIBY=>0x02;
use constant FLG_GENDAT=>0x04;
use constant FLG_CONVFR=>0x08;
my $flagOut = 0;

use FindBin;		# for FindBin::Bin
BEGIN {
# check user has a version of perl that will cope
	require 5.005_03;
# establish the path to the Perl libraries
    $PerlLibPath = $FindBin::Bin;	# X:/epoc32/tools
    $PerlLibPath .= "/";
}
use  lib $PerlLibPath;
# Includes the validation perl modules for XML validation against the given DTD.
use lib "$PerlLibPath/build/lib";
# Include routines to create the feature header and iby files.
use features;

#
# main - Tool entry function
#
{
	# Default path settings
	&processPath(\$epocroot);
	&features::set_DefaultPath($epocroot, \$hdrPath, \$ibyPath, \$datPath, \$convPath);
	
	# Process the command line arguments
	if(&process_cmdline_arguments()) {
		# Open the xml database
		if(&features::open_Database(@xmlDBFile)) {
		
			# Generate the header file in the appropriate format with the featureset attributes
			&features::generate_Headerfile($hdrPath) if($flagOut&FLG_GENHDR);
			
			# Generate the obey file in the appropriate format with the featureset attributes
			&features::generate_Obeyfile($ibyPath) if($flagOut&FLG_GENIBY);
			
			# Generate the feature dat file
			&features::generate_DATfile($datPath) if($flagOut&FLG_GENDAT);
			
			# Convert the feature registry database to feature manager database
			&features::convert_FeatRegToFeatMgr($convPath,@xmlDBFile) if($flagOut&FLG_CONVFR);
		}
	}
}

#
# Process the command line arguments
# 
sub process_cmdline_arguments
{
	my $helpCmd = 0;
	
	foreach my $arg (@ARGV)
	{
		if( ($arg =~ /^--(\S+)$/)  or ($arg =~ /^-([ridc]=.+)$/) )
		{
			$arg = $1;
			if( (($arg =~ /^hdrfile$/i) || ($arg =~ /^hdrfile=(.+)/i)) or ($arg =~ /^r=(.+)/) ) {
				# option to generate only header files
				if($1) {
					$hdrPath = $1;
					processPath(\$hdrPath);
				}
				$flagOut |= FLG_GENHDR;
			}
			elsif( (($arg =~ /^ibyfile$/i) || ($arg =~ /^ibyfile=(.+)/i)) or ($arg =~ /^i=(.+)/) ) {
				# option to generate only iby files
				if($1) {
					$ibyPath = $1;
					processPath(\$ibyPath);
				}
				$flagOut |= FLG_GENIBY;
			}
			elsif( (($arg =~ /^datfile$/i) || ($arg =~ /^datfile=(.+)/i)) or ($arg =~ /^d=(.+)/) ) {
				# option to generate only dat files
				if($1) {
					$datPath = $1;
					processPath(\$datPath);
				}
				$flagOut |= FLG_GENDAT;
			}
			elsif( (($arg =~ /^convert$/i) || ($arg =~ /^convert=(.+)/i)) or ($arg =~ /^c=(.+)/) ) {
				# option to convert feature registry database
				if($1) {
					$convPath = $1;
					processPath(\$convPath);
				}
				$flagOut |= FLG_CONVFR;
			}
			elsif( $arg =~ /^verbose$/i ) {
				# option to enable verbose mode
				&printTitle(); 
				&features::set_VerboseMode();
			}
			elsif( $arg =~ /^strict$/i ) {
				# option to enable strict mode
				&features::set_StrictMode();
			}
			elsif( $arg =~ /^help$/i ) {
				# print the usage on console
				$helpCmd = 1;
			}
			elsif( $arg =~ /^version$/i ) {
				# print the title on console
				&printTitle();
				return 1 if(scalar(@ARGV) == 1); # if this is the only option
			}
			else
			{
				print "Error: Unknown parameter $arg\n";
				return 0;
			}
			next;
		}
		elsif( $arg =~ /^-(\S+)$/ )
		{
			my @flags = split("",$1);
			
			foreach my $opt (@flags) {
				if( $opt =~ /^r/i ) {
					# option to generate only header files
					$flagOut |= FLG_GENHDR;
				}
				elsif( $opt =~ /^i/i ) {
					# option to generate only iby files
					$flagOut |= FLG_GENIBY;
				}
				elsif( $opt =~ /^d/i ) {
					# option to generate only dat files
					$flagOut |= FLG_GENDAT;
				}
				elsif( $opt =~ /^c/i ) {
					# option to convert feature registry database
					$flagOut |= FLG_CONVFR;
				}
				elsif( $opt =~ /^v/i ) {
					# option to enable verbose mode
					&printTitle(); 
					&features::set_VerboseMode();
				}
				elsif( $opt =~ /^s/i ) {
					# option to enable strict mode
					&features::set_StrictMode();
				}
				elsif( $opt =~ /^h/i ) {
					# print the usage on console
					$helpCmd = 1;
				}
				else
				{
					print "Error: Unknown option $opt\n";
					return 0;
				}
			}
			next;
		}
	
		next if(xmlfile($arg));
		next if(xmlfile("$arg.xml"));
		next if(xmlfile("$epocroot"."epoc32/rom/include/$arg"));
		
		print "Error: Cannot find xml file: $arg\n";
	}

	# process the help command
	if($helpCmd) {
		&print_usage();
		return 1 if(scalar(@ARGV) == 1); # if this is the only option
	}
	
	if(!@xmlDBFile) {
		# xml database is must here
		print "Error: No xml database given\n";
		&print_usage() if(!$helpCmd);
		return 0;
	}
	
	# if the suppress output option is not passed then generate both
	$flagOut = (FLG_GENHDR|FLG_GENIBY|FLG_GENDAT|FLG_CONVFR) if(!$flagOut);
	
	return 1;
}

# --Utility Functions

#
# check whether the given file exists
# @param - file name for the existance check
#
sub xmlfile
{
	my ($file) = shift;
	
	if(-e $file) {
		push @xmlDBFile, $file;
		return 1;
	}
	return 0;
}

#
# Process the given absolute path
# Add backslash at the end if required
# @param - path to be processed
#
sub processPath
{
	my ($path) = shift;
	
	return if( $$path =~ /(\\$)/ );
	return if( $$path =~ /(\/$)/ );
	$$path .= "/";
}

#
# Print the title
#
sub printTitle
{
	print "FEATURES - Features manager tool V".TOOL_VERSION."\n";
	print "Copyright (c) 2009 Nokia Corporation.\n\n"
}

#
# print the usage of this tool
#
sub print_usage
{
#........1.........2.........3.........4.........5.........6.........7.....
	&printTitle();
	print <<USAGE_EOF;
Usage:
  features [options] <xml database> [<xml database> <xml database> ...]

Generation of C++ header file and IBY file for the given featuremanger 
database file. It also generates features DAT file for the given 
featuemanager/featureregistry database file

Options:
   -r or --hdrfile[=<destination path>] - generates only header file
   -i or --ibyfile[=<destination path>] - generates only IBY file
   -d or --datfile[=<destination path>] - generates only features.DAT file
   -c or --convert[=<destination path>] - converts feature registry database
   
   -s or --strict        - enable strict mode
   -v or --verbose       - enable verbose mode
   -h or --help          - displays this help
   
   --version             - displays the tools version

Ex: option combination \"-ri\" generates header and IBY files
   
Default destination paths:
   <header file>         - $EPOCROOT\\epoc32\\include\\
   <iby file>            - $EPOCROOT\\epoc32\\rom\\include\\
   <features.dat file>   - generates in current directory
   
Note: The conversion(--convert) of feature registry database requires the 
feature registry dtd file(featureuids.dtd) in $EPOCROOT\\epoc32\\tools\\
USAGE_EOF
}
