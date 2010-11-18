#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
# This package is to build rom image
#

use FindBin;		# for FindBin::Bin
my $PerlLibPath;    # fully qualified pathname of the directory containing our Perl modules
my $PerlEPOCPath;

BEGIN {
# check user has a version of perl that will cope
	require 5.005_03;
# establish the path to the Perl libraries
    $PerlLibPath = $FindBin::Bin;	
#    $PerlLibPath =~ s/\//\\/g;
    $PerlLibPath .= "\\";
    $PerlLibPath =~ s/\\/\//g;
    
    $PerlEPOCPath = $ENV{EPOCROOT};
    $PerlEPOCPath =~ s/\\/\//g;
    $PerlEPOCPath .= "\/" unless $PerlEPOCPath =~ /\/$/;
    $PerlEPOCPath .= "epoc32\/tools\/";
}
use lib $PerlEPOCPath."build/lib/";
use lib $PerlEPOCPath;
use lib $PerlLibPath;
use strict;
use romutl;
use romosvariant;
# Work out the relative path to the epoc32 directory 
use Cwd; 
use File::Basename;
# global variables specific to data drive image generation. 
use File::Path ;					# Module to provide functions to remove or create directories in a convenient way.
use File::Find; 
use features;
use flexmodload;	     # To load modules dynamically

my $enforceFeatureManager = 0; # Flag to make Feature Manager mandatory if SYMBIAN_FEATURE_MANAGER macro is defined. 

my $BuildromMajorVersion = 0 ;
my $BuildromMinorVersion = 2;
my $BuildromPatchVersion = 0;

my $outputoby = "output.oby" ;


sub print_usage {

	# Option "-fm" will be supported instead of option "-f|fr" if SYMBIAN_FEATURE_MANAGER macro is defined.
	my $featuresOptionUsage = "-f<featureuids> or\n".
	"   -fr=<featureuids>            -- feature registry database XML file name\n";
	if ($enforceFeatureManager) {
		$featuresOptionUsage = "-fm=<featuredbfile>          -- feature manager/feature registry database XML file name.\n".
							   "                                   Multiple XML files can be passed seperated by commas.\n".
							   "   -nofm=<featuresdatafile>     -- don't generate features data file.\n".
							   "                                   Instead use pre-built features data file.\n";
	}

#........1.........2.........3.........4.........5.........6.........7.....
	print <<USAGE_EOF;

FEATURECONFIGURATOR - feature configuration tool V$BuildromMajorVersion.$BuildromMinorVersion.$BuildromPatchVersion

Usage:

  featureconfigurator [options] obyfile [obyfile2 ...]   

Configurate features from *.iby/*.oby files and output a 
consolidated obyfile for buildrom's use. 

This is a front end of buildrom, which partly implements 
functionalities of buildrom.



The available options are

   -h                           -- Print this message

   $featuresOptionUsage
   -oby-charset=<charset>       -- Used character set in which OBY was written

   -k or -keepgoing             -- Enable keepgoing,continue to config features
                                   and create oby file.

   -argfile=xxx                 -- Specify argument-file name containing list of 
                                   command-line arguments to featureconfigurator
   -workdir=xxx                 -- Specify a directory for generated files. 
                                   The working directory will not be changed even this option is used.
   
   -I<directory>                -- Use <directory> for the referenced IBY/OBY files
   -D<xxx>                      -- Define xxx for C++ preprocessor

   -stdcpp                      -- Ignore symbian customized cpp and try to find 
                                   another cpp in the PATH.(for Windows only)
   -cpp=<xxx>                   -- Use xxx as path of CPP preprocessor.
 
   -o<xxx.oby>                  -- Output oby file name is set to xxx.oby
                                   If this argument is not given, then output oby file is
                                   "output.oby". output files are placed under workdir.
								   
	-s                          -- strict option, any missing files will stop buildrom
	-v                          -- verbose
	-noiby[=<n>]                -- if n = 0, then create iby files, otherwise don't create iby files, "-noiby=0" is default
	-w                          -- suppress cpp warnings.

USAGE_EOF

}


my $PerlEPOCPath = &get_epocroot()."epoc32\/tools\/";   # fully qualified pathname of the directory containing EPOC Perl modules

 

my $xmlrequired = 0; # assume xml required is false. Used to determine if xml
                     # modules should be loaded.


my @tempfiles;  	
my $preserve = 0; 	#flag to indicate if temporary files should be preserved
my $uppath="x";	    	# will be initialised when first needed

my $epocroot = &get_epocroot;

my @obyfiles;
my $cppargs = "-nostdinc -undef";
my $opt_k = 0;
my $opt_v = 0; 
my $opt_w = 0 ;
my $strict = 0;
my $line;
my $errors = 0;
my $thisdir=cwd;
$thisdir=~s-\\-\/-go;		    # separator from Perl 5.005_02+ is forward slash
$thisdir.= "\/" unless $thisdir =~ /\/$/;
$thisdir =~ s-\/-\\-g if (&is_windows); 
my $workdir = $thisdir ;
my $rominclude = $epocroot."epoc32\/rom\/include\/";
$rominclude = &get_epocdrive().$rominclude unless $rominclude =~ /^.:/;
$rominclude =~s-\\-\/-g;

my @xmlDBFile = ();
my $noiby = 0;
my @obydata;

my @featurefilearray; #2d array storing names and locations of feature files in each rom image
my @featureslist; #array of hashes, stores all the features which are to go into the feature files
my $featurefilecount=0; #counts number of feature files in each rom image
my $featurescount=0; #counts number of features
my $dir; # Stores the ROM image location of features.dat/featreg.cfg files
my $featurefilename; # Stores the name of feature file to be generated(i.e. "features.dat" or "featreg.cfg")

my $featuremanager = 0; #Flag to enable support for feature manager database XML file and to generate  
			# features data file.
my $noFeatureManager = 0; # Flag to stop the generation of features.dat file and use pre-built features.dat if provided.
my $preBuiltFeaturesDataFile  = ''; # To store the name of pre-built features.dat file provided with "-nofm" option.

#Image Content XML file that supports specific feature to be added
my $image_content = undef;
#Feature list XML file that acts as database containing all features details
my $featureXml = undef; 
my $customizedPlat = undef; 

#Summary of files(both executables and data files) currently includes 
#	host and ROM file names, 
#	size of the file in ROM
#	whether the file is hidden
# This option is added so that the above additional information is emitted by rombuild/rofsbuild tools
# only when supplied with this option so that the existing tools don't get affected.
my $logLevel="";
 

# Feature Variation modules and data
my %featureVariant;


my $opt_workdir = 0; 
my $stdcpp = 0;
my $obycharset;
my $cppoption = 0;
my $preprocessor = "cpp"; 

sub is_fullpath {

my $path = shift ;
	if (&is_windows) {
		if( $path =~ /^[a-z]:/i) {
			return 1 ;
		}
		elsif($path =~ /^\\/) {
			return 1 ;
		}
		else {
			return 0 ;
		}			
	}
	else {
		return 1 if($path =~ /^\//) ;
		return 0;
	}

}

sub match_obyfile
{
	my ($obyfile) = @_;
	if (-f $obyfile)
	{
		push @obyfiles, $obyfile;
		return 1;
	}

	# search for the oby file in the list of include directories
	my @otherDirs = ($rominclude);

	if ($featureVariant{'VALID'})
	{
		my $dirRef = $featureVariant{'ROM_INCLUDES'};

		@otherDirs = @$dirRef if ($dirRef);
	}
	foreach my $dir (@otherDirs)
	{
		print "$dir/$obyfile\n" if ($opt_v);
		if (-f "$dir/$obyfile")
		{
		    push @obyfiles, "$dir/$obyfile";
		    return 1;
		}
	}
	return 0;
}
 
# Subroutine to process parameter-file
sub parameterFileProcessor
{
	my $paramFile = shift(@_);	
	my @paramFileParamaters = ();	

	my $fileOpenFlag = 1;
	open FILE,"<", $paramFile or $fileOpenFlag = 0;
	
	if(!$fileOpenFlag)
	{
		print "Error: Could not open parameter-file \"$paramFile\" for reading.\n";
		return;
	}
	
	# Parse parameter-file and collect all the parameters in an array
	while(my $line = <FILE>)
	{
		# Read the line till character ';'(used for providing comments in the file) or EOL
		$line = $1 if ($line =~ /(.*);/); 
		
		# Split the parameters specified in a line based on white-spaces		
		my @paramaters = split(/(\s)/,$line);	
		
		my $flag = 0;
		my $argWithQuotes='';

		foreach my $value (@paramaters) 
		{	
			# If the parameter doesn't conatian double quotes then push it 
			# to the list of parameters.
			if(($value !~ /\"/) && (!$argWithQuotes)) 
			{
				if ($value !~ /^\s*$/) 
				{
					push @paramFileParamaters,$value;
				}		
			}
			# If the parameter is in the form  -fm="faturedb.xml" then remove
			# double quotes and push it to the list of parameters.
			elsif(($value =~ /\".*\"/))
			{
				$value =~ s/\"//g;
				push @paramFileParamaters,$value;
			}
			# If the parameter is in the form  -fm="fature  db.xml" then read
			# the parameter starting from opening quote till the closing quote.
			elsif( ($value =~ /\"/) && $argWithQuotes) 
			{
				$argWithQuotes .= $value;
				$argWithQuotes =~ s/\"//g;
				push @paramFileParamaters,$argWithQuotes;
				$argWithQuotes='';		
			}
			else
			{
				$argWithQuotes .= $value;
			}
		}		
	}

	close FILE;	
	if (!@paramFileParamaters)
	{
		print "Warning: No parameters specified in paramer-file \"$paramFile\".\n";		
		return;
	}
	
	my $paramFileFlag = 1;

	# Invoke subroutine "process_cmdline_arguments" to process the parameters read from
	# the parameter file.
	&process_cmdline_arguments($paramFileFlag, @paramFileParamaters);

}

# Processes the command line arguments passed to buildrom tool

sub process_cmdline_arguments
{
 
	my ($paramFileFlag, @argList); 

	if (defined @_) {
		($paramFileFlag, @argList) = @_;
	}
	else {
		if(scalar(@ARGV) == 0){
			my @hrhMacros = &get_variantmacrolist;	
			$enforceFeatureManager = 1 if (grep /^SYMBIAN_FEATURE_MANAGER\s*$/, @hrhMacros);
			print_usage();
			exit 1;				
		}
		
		@argList = @ARGV;
	}

	if (!defined $paramFileFlag)  {
	
		# Enforce Feature Manager if macro SYMBIAN_FEATURE_MANAGER is defined in the HRH file.
		my @hrhMacros = &get_variantmacrolist;	
		$enforceFeatureManager = 1 if (grep /^SYMBIAN_FEATURE_MANAGER\s*$/, @hrhMacros);
		# Process the parameters of parameter-file if passed.
		foreach my $arg (@argList) {
			if ($arg =~ /^-h/i) {
				print_usage();
				exit 1;				
			}
		}
		# Process the parameters of parameter-file if passed.
		foreach my $arg (@argList) {
			&parameterFileProcessor($1) if ($arg =~ /^-argfile=(.*)/) ;
		}
	}
	# first searching argList for keepgoing option
	my @newArgList = () ;
	foreach my $arg (@argList) {
		if ( $arg =~ /^-k$/i || $arg =~ /^-keepgoing$/i ) {
			$opt_k = 1;	 
		}
		elsif ($arg =~ /^-s$/) {
			$strict = 1; 
	    }
		elsif ($arg =~ /^-v$/) {
			$opt_v =1; 
	    }
		elsif( $arg =~ /^-w$/) {
			$opt_w = 1 ;
		}
		elsif ($arg =~ /^-workdir=(.*)/) {			
			$workdir = $1;
			$workdir = $thisdir.$workdir unless(&is_fullpath($workdir)) ;
			$workdir.= "\/" unless $workdir =~ /\/$/;
			mkdir($workdir) unless (-d $workdir); 
		}else {
			push @newArgList, $arg ;
		}
	}
	foreach my $arg (@newArgList)
	{
	    if ($arg =~ /^-argfile=(.*)/)  {
			&parameterFileProcessor($1) if (defined $paramFileFlag); 
		}
		elsif ($arg =~ /^-DFEATUREVARIANT=(.*)/) {
			my $varname = $1;			
			if ($varname =~ /^\.(.*)$/) {
				# for testing, locate the VAR file in the current directory
				%featureVariant = get_variant($1, ".");
			}
			else {
				%featureVariant = get_variant($varname);
			}
			if (!$featureVariant{'VALID'}) {
			    print "FEATUREVARIANT $varname is not VALID\n";
				$errors++;
			}
			if ($featureVariant{'VIRTUAL'}) {
			    print "FEATUREVARIANT $varname is VIRTUAL\n";
				$errors++;
			}
			addDrivesToFeatureVariantPaths(); 
		}
		elsif ($arg =~ /^-[DI]/) {
			$cppargs .= " $arg";  
	    } 
	    elsif ($arg =~/^-oby-charset=(.*)$/i) {
		$obycharset = $1; 
	    }
		elsif($arg =~ /^-o(.*)/i)   {
			$outputoby = $1;  
		} 
		elsif ($arg =~ /^-noiby(=(\d))$/i ) {
			if(!$1) {
				$noiby = 1;
			}
			else {
				if(!$2) {
					print "Warning: No value for \"-noiby=\" option, use default.\n";
				}
				else {
					$noiby = $2 ;
				}
			}
		}
		#Process feature manager database xml file 
	    elsif($arg =~ /^-fm=(.*)/) {
			if (!$enforceFeatureManager) {
				print "Unknown arg: $arg\n";
				$errors++;
				next;
			}
			$featureXml = $1;			
			$xmlrequired = 1;
			$featuremanager = 1;
			if ($featureXml =~ /^$/)  {
				print "Error: No filename specified with \"-fm=\" option.\n";
			} 
			else {			
				@xmlDBFile = split /,/,$featureXml if($noiby == 0);
			} 
	    }
		elsif ($arg =~ /^-nofm(=(.*))?$/) {
			if (!$enforceFeatureManager)  {
				print "Unknown arg: $arg\n";
				$errors++;
				next;
			}
   			$noFeatureManager = 1; 
            if(!$2) {
                print "Warning: No filename specified with \"-nofm=\" option, feature data file might not be included.\n";
            }
            else {
                $preBuiltFeaturesDataFile = $2;						
            } 	
		}
		#Process feature registry database xml file 
	    elsif($arg =~ /^-fr=(.*)/ || $arg =~ /^-f(.*)/) {
			if ($enforceFeatureManager)
			{
				print "Error: Option \"-f|-fr\" is no longer supported.\n";
				$errors++;
				next;
			}			
			$featureXml = $1;
			$xmlrequired = 1;			
			print "Error: No filename specified with \"-f|-fr\" option.\n" if ($featureXml =~ /^$/) ;
	    } 
		elsif ($arg =~ /^-stdcpp$/i) {
			if (&is_linux) {
				print "Warning: option -stdcpp only apply for Windows\n"; 
			}
			if ($cppoption) {
				print "Error: -stdcpp option and -cpp=xxx option cannot be used at the same time.\n";
				exit (1);
			}
			$stdcpp = 1; 
		}
		elsif ($arg =~ /^-cpp=(.*)/) {
			if ($stdcpp) {
				print "Error: -stdcpp option and -cpp=xxx option cannot be used at the same time.\n";
				exit (1);
			}
			print "Warning: -cpp option has been set before. The previous configuration will be overwritten!\n" if ($cppoption);
			$cppoption = 1;
			$preprocessor = $1;
			$preprocessor =~ s-\\-\/-g;
			$preprocessor =~ s-EPOCROOT##\/?-$epocroot-g;
			if (-d $preprocessor) {
				$preprocessor .= "\/" unless $preprocessor =~ /\/$/;
				$preprocessor .= "cpp";
			} 
		} 
	    elsif ($arg =~ /^-/)  {
			print "Unknown arg: $arg\n";
			$errors++;
			next;
	    }
		else {
			# It's an OBY file
			next if (match_obyfile($arg));
			next if (match_obyfile("$arg.oby"));
			print "Cannot find oby file: $arg\n";
			$errors++ if(!$opt_k);
		}	    
	}

	return if (defined $paramFileFlag) ;
	if (@obyfiles<1 ) {
	    print "Missing obyfile argument\n";
	    $errors++ if(!$opt_k);
	}
	if(defined($obycharset)) {
		print "Warning: Ignoring not supportted charset $obycharset, local charset will be used as default!\n" unless($obycharset =~ /utf-?8/i);
	}

	if ($errors) {
	    print_usage();
	    exit 1;
	}
	
	if ($noFeatureManager && $featuremanager)  {
		print "Warning: Ignoring \"-nofm\" option, as both \"-nofm\" and \"-fm\" options are provided.\n";			
		$noFeatureManager = 0;
	}

	# Adding variant specific macros by including a HRH file
	# (only required if no Feature Variant is used)
	if (!$featureVariant{'VALID'}) {
	    my $variantMacroHRHFile = get_variantmacroHRHfile();
	    if($variantMacroHRHFile){
	        my $variantFilePath = split_path('Path',$variantMacroHRHFile);
	        $cppargs .= " -I " . &append_driveandquote($variantFilePath) . " -include " . &append_driveandquote($variantMacroHRHFile); 
	        print "in cmd process $cppargs\n" if ($opt_v);
	    }
	}
	# load the required modules if xml is required
	if ($xmlrequired == 1) {
	    load_featuresutil() if (defined ($featureXml));	    
	}
}

#----------------------------------------------------------------------------------
# Preprocessing phase	
#
# Concatentate the specified .oby files and pass them through cpp
# to get the raw ROM specification in tmp1.oby

sub preprocessing_phase
{
	 
	
	my $temp1OBYFile = $workdir."tmp1.oby";
	unlink "$temp1OBYFile";

#	Macro "ROM_FEATURE_MANAGEMENT" is defined when "-f|fr" or "-fm" is used
	$cppargs .= " -w" if($opt_w) ;
	$cppargs .= " -DROM_FEATURE_MANAGEMENT " if (defined ($featureXml));

	# add pre-include file and include directories for feature variants
	if ($featureVariant{'VALID'})
	{
		$cppargs .= " -I.";
		my $incRef = $featureVariant{'ROM_INCLUDES'};
		if ($incRef) {
			foreach (@$incRef) {
				$cppargs .= " -I \"$_\"";
			}
		}
		my $HRH = $featureVariant{'VARIANT_HRH'};
		$cppargs .= " -include \"$HRH\"" if ($HRH);
	}
	else {
		# no feature variant so use the standard includes
		$cppargs .= " -I. -I \"$rominclude\"";
	}

	$preprocessor = find_stdcpp() if ($stdcpp);
	print "* $preprocessor -Wno-endif-labels -o $temp1OBYFile $cppargs\n" if ($opt_v);
	
	is_existinpath("$preprocessor", romutl::DIE_NOT_FOUND);
	$errors = 0; 
	open CPP, "| $preprocessor -Wno-endif-labels -o $temp1OBYFile $cppargs" or die "* Can't execute cpp";
	foreach my $arg (@obyfiles) {
		print CPP "\n#line 1 \"$arg\"\n";
	
		if(open(OBY, $arg)) {
			print "* reading $arg\n" if ($opt_v);
			while ($line=<OBY>) {
				print CPP $line;
			}
			close OBY;
		}
		else {
			print STDERR "* Can't open $arg\n";
			if(!$opt_k){			
				close CPP;
				exit(1);
			}
		}
	}
	close CPP;
	my $cpp_status = $?;
	die "* cpp failed\n" if ($cpp_status != 0 || !-f "$temp1OBYFile");
	

	if( defined ($image_content)) {
		#Read the OBY file that was generated by the pre-processor
		&ReadPreprocessedFile($temp1OBYFile);

#		Check if the static dependencies of the OBY binaries are resolved.
		&ImageContentHandler::UpdateObyBinaryStaticDep();
		
		#Now append the files collected from cdfs.
		&ImageContentHandler::GenObyFile($temp1OBYFile);
	}

 
	if($obycharset =~ /utf-?8/i) {
		my $utf8file = $workdir."tmp1utf8.oby";
		open INFILE, "<$temp1OBYFile" or die "* Can't open file $temp1OBYFile";
		open CHARSETTRAN, "| charsettran -to=hostcharset > $utf8file" or die "* Can't execute charsetran";
		while(<INFILE>) {
			print CHARSETTRAN $_;
		}
		close CHARSETTRAN;
		close INFILE;	
		unlink $temp1OBYFile  or die "* Can't remove file $temp1OBYFile";
		rename 	$utf8file, $temp1OBYFile or die "* Can't rename file $utf8file to file $temp1OBYFile";
	}
	
	open TMPOBY, "<$temp1OBYFile" or die "*cpp output can not be read.\n"; 
	@obydata = <TMPOBY> ;
	close TMPOBY;
 

	
}
 
sub load_featuresutil
{
	&FlexLoad_ModuleL("featuresutil");
			
	# Parse the feature database XML file
	if(!&featuresutil::parseXMLDatabase($featureXml, $featuremanager, $strict))
	{
		$featureXml = undef;
		exit(1) if($strict);
	}
}

#----------------------------------------------------------------------------------
# Feature registry configuration file/Features data file generation phase
#
# If feature registry configuration files/features data files are required then creates these files for
# each ROM/ROFS image
#
sub featurefile_creation_phase
{
		# Set the name and Rom Image location of feature file.
	if ($enforceFeatureManager)  {
		# features data file location
		$dir = "private\/10205054\/";
		$featurefilename = "features.dat";
	}
	else {
		# feature registry configuration file location
		$dir = "private\/102744CA\/"; 
		$featurefilename = "featreg.cfg";
	}
	my $onlysmrimage  = 1 ;
	
	foreach $line(@obydata) {		
		if(($line =~ /^\s*romsize\s*=/i) || ( $line=~ /^\s*rom_image/i) || ($line =~ /^\s*data_image/i)) {
			$onlysmrimage = 0;
			last;
		}
	}	
	if ($enforceFeatureManager && (!$featuremanager) && (!$noFeatureManager) ) {
		my $defaultFeatureDbFlag = 0;
		foreach $line(@obydata) { 
			if ($line=~/^\s*defaultfeaturedb\s*=?\s*(\S+)/i) {	
				# Get the default value for featuredatabasefile
				
				$featureXml = "$epocroot$1";
				$featureXml =~ s-\\-\/-g;
				$featuremanager = 1;				
				$defaultFeatureDbFlag = 1;
				load_featuresutil();				
				last;
			}
		}
		if(!$defaultFeatureDbFlag && !$onlysmrimage)
		{
			print "Error: Neither option \"-fm|-nofm\" nor default value for featuredatabase file is provided.\n";
			exit(1);			
		}
	}
	my @newobydata = ();
	if (defined ($featureXml))  {
		my $featurefilecount=0;
		my $romimage=0;

		foreach $line (@obydata) {
			# specify which romimage following lines are part of
			if ($line=~/^\s*ROM_IMAGE\[(\d)\]/) {
				$romimage=$1;
				$featurefilecount=0;
			}
			elsif ($line =~ /^\s*REM/i || $line =~ /^\s*\r?\n$/ ){
				next ;
				# ignore empty
			}
			elsif($line =~ /^\s*(FEATURE)\s*(\S*)\s*(.*)/i || $line =~ /^\s*(EXCLUDE_FEATURE)\s*(\S*)\s*(.*)/i) {
				
				# FEATURE  <feature_name>  [ SF  <status falgs> ] [ UD  <user data> ]
				my $feature = $1;
				my $featurevalue = $2;
				my $featureargs = $3;
				my $reservedbit = 0;
				my %featureflags=();			 
				# Options 'SF' and 'UD' will be supported only for "-fm" option
				if ($featuremanager)  {
					# [ SF  <status falgs> ] [ UD  <user data> ]
					$featureargs =~	/(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*/ ;

					# Store the values of 'SF' and 'UD', or any invalid option, if provided					
					$featureflags{uc($1)} = $2 if ($1);  
					$featureflags{uc($3)} = $4 if ($3); 

					# Generate a warning if the option provided with Feature/Exclude_Feature keyword is  
					# not 'SF' or 'UD'.
					foreach my $Key (keys %featureflags) {						
						if ($Key !~ /^(SF|UD)$/) {
							print "Warning: Invalid argument \"$Key\" specified for feature $featurevalue\n";
							delete $featureflags{$Key};
							next;
						}						
					}							
				}				
				# In verbose mode, generate warning if "SF|UD" arguments or invalid arguments are specified
				# for "-f|fr" option.
				elsif ($featureargs && $opt_v) {
					print "Invalid argument(s) \"$featureargs\" provided for feature \"$featurevalue\"\n";
					foreach my $Key (keys %featureflags) {
						delete $featureflags{$Key};
					}
				}				
				
				# The feature file name is of the format featreg.cfg[x-y] or features.dat[x-y] 
				# where x is the romimage id, y is always 0, reserved for future use.
				my $targetfeaturefile;
				if (($romimage == 0) && ($reservedbit == 0)) {

					# Core image will not have the mangled name
				 	$targetfeaturefile = $featurefilename;
				}
				else {
				 	$targetfeaturefile = $featurefilename . "\[". $romimage . "\-$reservedbit\]";
				}
				my $flag=1;
				my $featureflag;
				if ($feature =~ /^FEATURE$/i) {
					$featureflag = 1;
				}
				else {
					$featureflag = 0;
				}

				my $i;
 				# loop to see if name of feature file already added to this romimage in array
				for($i=0;$i<$featurefilecount && $flag;$i++) {
					$flag=0 if($featurefilearray[$romimage][$i]{cfgfile} eq $targetfeaturefile);
				}
			
				if($flag) { # adds feature file if not yet listed for this romimage in array
					$featurefilearray[$romimage][$featurefilecount++]={cfgfile=>$targetfeaturefile, cfgdir=>$dir};
					$i=$featurefilecount;
				}

				$featureslist[$featurescount]= {feature=>$featurevalue, include=>$featureflag, rom=>$romimage, cfgfile=>$i-1};
				
				# Store the value of 'SF' in 'featureslist' array
				$featureslist[$featurescount]->{SF} = $featureflags{SF} if (defined $featureflags{SF}) ;
				# Store the value of 'UD' in 'featureslist' array
				$featureslist[$featurescount]->{UD} = $featureflags{UD} if (defined $featureflags{UD}) ;
				$featurescount++;
			}
		}

		# Create Feature File
		for(my $i=0;$i<scalar @featurefilearray;$i++) {
			my $j=0;
			while(defined $featurefilearray[$i][$j])
			{
				my $targetfeaturefile = $workdir.$featurefilearray[$i][$j]{cfgfile}; 
				if (!(&featuresutil::createFeatureFile($i,$j,$targetfeaturefile,\@featureslist,$featuremanager)))  {
					$featurefilearray[$i][$j]{cfgfile}= undef;
					exit(1) if($strict);					
				}
				$j++;
			}
		} 
		my $flag=1;
        	my $imageIdx=0;

		# Add feature files to ROM image, adds lines to obey file to specify existing locations
		# of feature files and target locations. 
		
		# features.dat will be written to the end of rom/rofs
		my @lastFLs = ();
		my $lastRomIndex = 0 ;
		
		foreach $line (@obydata) {
			if($line =~/^\s*ROM_IMAGE\[(\d)\]/i) {
				my $index=$1;
						
				if($lastRomIndex != $index) {
					foreach my $fl(@lastFLs) {
						push @newobydata,$fl ;
					}
					@lastFLs = ();
					$lastRomIndex = $index ;
				}
				push @newobydata, "\n" . $line . "\n";	
				my $j=0;
				while(defined $featurefilearray[$index][$j]) {
					$flag = 0 if($index == 0);
					# Put in feature files for current ROM_IMAGE
					my $targetfeaturefile = $featurefilearray[$index][$j]{cfgfile};
					# Rom images will not have mangled name for feature files
				 					
					# Rofsbuild will set attribute 'exattrib=U' in the entry record when this field is used.
					# File Server when asked for a directory listing would notice the attribute and will return the 
					# list with mangled names. Hence, mangled name for feature files should not be put in ROM_IMAGE.
					my $exattribute = "" ;					
					if (defined $targetfeaturefile ) {
						$exattribute = "exattrib=U" if($index > 0);
						push @lastFLs, "ROM_IMAGE[$index] data=" . $workdir . $targetfeaturefile . " \"". $featurefilearray[$index][$j]{cfgdir} .$featurefilename .  "\"\t\t" . $exattribute . "\n";
						$featurefilearray[$index][$j]{cfgfile} = undef ;
					}
					$j++;
				}
			}
			elsif($line !~ /^\s*(FEATURE)\s*/i && $line !~ /^\s*(EXCLUDE_FEATURE)\s*/i && $line !~/^\s*defaultfeaturedb\s*=?\s*(\S+)/i) {
				# Put in all other lines except the FEATURE and EXCLUDE_FEATURE keywords
				push @newobydata, $line;
			}
			else {
				push @newobydata, " "; 
			}
			 
		}
		foreach my $fl(@lastFLs) {
			push @newobydata,$fl ;
		}
		if($flag) { 
			# Put in feature files for ROM_IMAGE[0] if it is the only ROM_IMAGE
			my $k=0;
			while(defined $featurefilearray[0][$k])
			{ 
				my $targetfeaturefile = $featurefilearray[0][$k]{cfgfile};
				if (defined $targetfeaturefile)
				{
					push @newobydata, "data=" . $workdir . $targetfeaturefile . " \"" . $featurefilearray[0][$k]{cfgdir} . $targetfeaturefile . "\"\n";
					$featurefilearray[0][$k]{cfgfile} = undef ;
				}
				$k++;
			}
		}
	}
	elsif ($enforceFeatureManager && $noFeatureManager && $preBuiltFeaturesDataFile) {
        print "Valid: $preBuiltFeaturesDataFile\n";
		if (-e $preBuiltFeaturesDataFile)  { 
			my $flag = 1;
			foreach my $line (@obydata)
			{
				# Put in the pre-built features data file in ROM_IMAGE[0] 
				if($line =~/^\s*ROM_IMAGE\[1\]/i)
				{
					push @newobydata, "data=$preBuiltFeaturesDataFile" . " \"" . $dir . $featurefilename . "\"\n";
					$flag =0;
				}
				push @newobydata, $line;
			}
			if($flag)
			{ 
				# Put in the pre-built features data file in ROM_IMAGE[0] if it is the only ROM_IMAGE
				push @newobydata, "data=$preBuiltFeaturesDataFile" . " \"" . $dir . $featurefilename . "\"\n";
			}
		}
		else
		{
			print "Error: File \"$preBuiltFeaturesDataFile\" doesn't exist.\n";
			exit(1);
		}
	}
	elsif ($enforceFeatureManager) {
	    print "Error: no feature data file or pre-built feature data file is provided!";
	    exit(1);
	}
	
		my $output ;
	if(&is_windows) {
		if($outputoby =~ /^[\\\/]/ || $outputoby =~ /^[a-zA-Z]:/)  {
			$output = $outputoby ;
		}
		else {
			$output = $workdir.$outputoby;
		}
	}
	else {
		if($outputoby =~ /^[\/]/ )  {
			$output = $outputoby ;
		}
		else {
			$output = $workdir.$outputoby;
		}
	} 
	unlink $output if(-e $output);
	print "* Writing $output...\n" if($opt_v);
	unless(open FOUT, ">$output"){
		print "Error: Can not write to $output.\n";
		exit(1);
	}
	foreach(@newobydata){
		chomp ;
		print FOUT "$_\n";
	} 
	close FOUT ; 
	print "* Done.\n" if($opt_v);
}

# make sure that all the absolute feature variant paths include a
# drive letter. This is required because cpp will not work with
# absolute paths starting with slashes.
sub addDrivesToFeatureVariantPaths
{
	return unless $featureVariant{'VALID'};

	my $current = &get_epocdrive;
	my $drive = $1 if ($current =~ /^(.:)/);

	# pre-include file
	my $HRH = $featureVariant{'VARIANT_HRH'};
	$featureVariant{'VARIANT_HRH'} = $drive . $HRH if ($HRH =~ /^[\\\/]/);

	# ROM include path
	my $dirRef = $featureVariant{'ROM_INCLUDES'};
	return unless $dirRef;
	my $i = 0;

	foreach my $dir (@$dirRef)
	{
		$$dirRef[$i] = $drive . $dir if ($dir =~ /^[\\\/]/);
		$i++;
	}
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

# Main block for buildrom module invocation


# Processes the buildrom command line parameters.
&process_cmdline_arguments; 
if(scalar(@xmlDBFile) > 0) { 
	&processPath(\$epocroot);
	&processPath(\$thisdir);
	&features::set_DefaultPath($epocroot, \$thisdir, \$thisdir, \$thisdir, \$thisdir);
	if(&features::open_Database(@xmlDBFile)) {  
		&features::generate_Obeyfile($workdir);	 
	}
}
#Preprocessing phase
&preprocessing_phase; 
# Creates feature registry configuration file/features data file.
&featurefile_creation_phase;


1;
