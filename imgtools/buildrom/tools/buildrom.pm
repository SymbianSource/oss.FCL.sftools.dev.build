#
# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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

package buildrom;

require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
	image_content_processing_phase
	process_cmdline_arguments
	preprocessing_phase
	substitution_phase
	reorganize_phase
	plugin_phase
	multlinguify_phase
	spi_creation_phase
	suppress_phase
	bitmap_aif_converison_phase
	cleaning_phase
	create_dumpfile
	create_dirlisting
	suppress_image_generation
	invoke_rombuild
	getOBYDataRef
	isobystatement
	isdatastatement
	isspidatastatement
	isexecutablefile
	isdirectorymetadata
	isbitmap
	isaif
	isresource
	hardwarevariant
	executableextension
	executabletype
	getSourceFile
	getDestFile
	getOBYAttributes
	getHardwareVariant
	getObyCommand
	process_dlldata
	featurefile_creation_phase
	processData
	create_smrimage
);

my $enforceFeatureManager = 0; # Flag to make Feature Manager mandatory if SYMBIAN_FEATURE_MANAGER macro is defined. 

my $BuildromMajorVersion = 3 ;
my $BuildromMinorVersion = 17;
my $BuildromPatchVersion = 0;

sub print_usage
{

	# Option "-fm" will be supported instead of option "-f|fr" if SYMBIAN_FEATURE_MANAGER macro is defined.
	my $featuresOptionUsage = "-ffeatureuids or -fr=featureuids -- feature registry database XML file name";
	if ($enforceFeatureManager) 
	{
		$featuresOptionUsage = "-fm=featuredatabasefile          -- feature manager/feature registry database XML file name.\n".
							   "\t\t\t\t    Multiple XML files can be passed seperated by commas.\n".
							   "   -nofm=featuresdatafile           -- don't generate features data file.".
							   " Instead use pre-built features data file.";
	}

#........1.........2.........3.........4.........5.........6.........7.....
	print <<USAGE_EOF;

BUILDROM - ROM configuration tool V$BuildromMajorVersion.$BuildromMinorVersion.$BuildromPatchVersion

Usage:
  buildrom [options] obyfile [obyfile2 ...]   

Build a ROM according to the specification defined by concatenating the
specified obyfiles.

The initial specification is modified by C++ preprocessor directives,
and subsequently adjusted by statements in the ROM specification language.
The final specification is in the subset of the specification language
which is understood directly by ROMBUILD.

Each obyfile parameter specifies a file via a search path: if the
filename is not matched then buildrom will look in \\epoc32\\rom\\include.

Buildrom invokes ROMBUILD to generate the ROM image, and produces a
number of related files such as the ROM symbol file. The name of the
image file is specified directly by the -o option, or determined by 
scanning the final specification for the "romname" keyword. If there is 
more than one "romname" statement, the last one takes precedence.

The available options are

   -Dxxx                            -- C++ preprocessor arguments
   -oimagename                      -- ROM image name, overriding any ROMNAME statement
   -s                               -- strict option, any missing files will stop buildrom 
   -p                               -- preserves the intermediate files pertaining to data drive, Z drive and BMCONV
   -spi                             -- enable producing SPI files
   -spiplacement                    -- enable positioning of spi file
   -w                               -- warn if file has been selected from a different directory 
   $featuresOptionUsage
   -etool                           -- external tool specification (xx is tool's perl module)
   -compress                        -- compression type of ROM image:
                                       -compress compress whole ROM image.
                                       -compress=paged compress paged section in the ROM image only.
                                       -compress=unpaged compress unpaged section in the ROM image only. 
   -ccomprmethod                    -- compression method: none|inflate|bytepair
   -geninc                          -- generate INC file
   -gendep                          -- generate dependence graph for rom image
   -nosymbols                       -- disable creation of symbol file
   -noimage                         -- disable creation of ROM/ROFS/DataDrive Image
   -fastcompress                    -- compress files with faster bytepair and tradeoff of compress ratio
   -j<digit>                        -- do the main job with <digit> threads
   -loglevel<level>                 -- Level of information logging where loglevel is 0,1,2
                                       0 default level of information
                                       1 host/ROM filenames, file size and the hidden attribute along with level0 log
                                       2 E32 file header attributes along with level1 log
   -z=xxx or -zdrivepath=xxx        -- specify a location to create Z drive directory. 
   -d=xxx or -datadrivepath=xxx     -- specify a location to create data drive directory.
   -k or -keepgoing                 -- enable keepgoing,continue to create the data drive image even
                                    if the non-sis, sis or zdrive image file(s) are missing or corrupt.
   -r or -retainfolder              -- enable retainfolder,would retain pre-existence of z & data drive folder. 
   -zdriveimage=xxx                 -- specify Z drive image (ROM, CORE, ROFS or Ext-ROFS image).
   -pfile=xxx                       -- specify a parameter file for interpretsis to take additional parameters.
   -argforinterpretsis=xxx          -- specify command line argument(s) for interpretsis which will override the 
                                    parameter file contents.
   -l=xxx or -logimagecontents=xxx  -- extract all stub-sis and SWI certificate store file(s) only 
                                    and log all the file(s) that are part of the Z drive image on to a log file.  
   -I<directory>                    -- Use <directory> for the referenced IBY/OBY files
   -argfile=xxx                     -- specify argument-file name containing list of command-line arguments to buildrom   
   -lowmem                          -- use memory-mapped file for image build to reduce physical memory consumption   

Popular -D defines to use include

   -D_DEBUG         -- select debug versions of some files
   -D_FULL_DEBUG    -- select debug versions of all files
   -D_ARM4          -- specify the target platform

   -D_EABI=xxxx     -- specify target for all files (e.g. ARMV5)
   -D_KABI=xxxx     -- specify the target platform for the Kernel (e.g. ARMV5)

Other defines may be useful for particular OBY files.

USAGE_EOF
}

use strict;
my $PerlLibPath;    # fully qualified pathname of the directory containing our Perl modules
# establish the path to the Perl libraries
$PerlLibPath = $FindBin::Bin;	# X:/epoc32/tools
$PerlLibPath =~ s/\//\\/g;	# X:\epoc32\tools
$PerlLibPath .= "\\";
sub ExportDirs ($);

use BPABIutl; # for BPABIutl::BPABIutl_Plat_List

my $xmlrequired = 0; # assume xml required is false. Used to determine if xml
                     # modules should be loaded.

use Modload;	     # To load modules dynamically

# Work out the relative path to the epoc32 directory
use spitool qw(&createSpi);
use Cwd;
use Pathutl;
use E32Variant;
use E32Plat;
use Genutl;
use BPABIutl;		# for BPABIutl::BPABIutl_Plat_List
use externaltools; 	#To invoke External Tools

my @tempfiles;  	
my $preserve = 0; 	#flag to indicate if temporary files should be preserved
my $uppath="x";	    	# will be initialised when first needed

my $epocroot = $ENV{EPOCROOT};
die "ERROR: Must set the EPOCROOT environment variable\n" if (!defined($epocroot));
$epocroot =~ s-/-\\-go;	# for those working with UNIX shells
die "ERROR: EPOCROOT must not include a drive letter\n" if ($epocroot =~ /^.:/);
die "ERROR: EPOCROOT must be an absolute path without a drive letter\n" if ($epocroot !~ /^\\/);
die "ERROR: EPOCROOT must not be a UNC path\n" if ($epocroot =~ /^\\\\/);
die "ERROR: EPOCROOT must end with a backslash\n" if ($epocroot !~ /\\$/);
die "ERROR: EPOCROOT must specify an existing directory\n" if (!-d $epocroot);

my $epoc32 = relative_path("${epocroot}epoc32");
$epoc32 =~ s-\\-/-go;

my @obyfiles;
my $cppargs = "-nostdinc -undef";
my $opt_v = 0;
my $opt_o = "";
my $strict = 0;
my $warnSelection = 0; # default is not warn about selecting files from 
		       # different directories when the file is missing from
		       # the specified directory

my $createspi = 0; # don't create SPI files by default
my $spiset=0;
my $spiplacement = 0; # enable the placement of spi file
my %spipositionflag = (); # map of Image index at which the keyword SPI_POSITION is used.

use constant NONE => 0;
use constant INFLATE => 1;
use constant BYTEPAIR => 2;
my $opt_compression;  # Default compression method parameter undefined

use constant UNCOMPRESSED   => 0;        # Indicates the ROM image will not be compressed.
use constant ALLSECTIONS    => 1;        # Indicates both paged section and unpaged section will be compressed.
use constant PAGEDSECTION   => 2;        # Indicates only paged section will be compressed.
use constant UNPAGEDSECTION => 3;        # Indicates only unpaged section will be compressed.
my $opt_compression_type = UNCOMPRESSED; # Leave the ROM image uncompressed by default.

my $thisdir=cwd;
$thisdir=~s-/-\\-go;		    # separator from Perl 5.005_02+ is forward slash
$thisdir=~s-^(.*[^\\])$-$1\\-o;	    # ensure path ends with a backslash
$thisdir=~s-^.:\\--o;		    # remove drive letter and leading backslash

my $rominclude = "$epoc32/rom/include";
my %plugintypes; #hash of plugin types and their SPI files' destinations in ROM
$plugintypes{"ECOM"} = "\\private\\10009d8f\\"; #ECOM SPI files' destination in ROM image

my @obydata;
my @newobydata;
my %substitutionData;
my @substitutionOrder;
my %languageCodes;
my $defaultLanguageCode;
my %multiLinguifyAlias;  # to by-pass the 'mustbesysbin' option for multilinguify 'alias'es. 
my $abiDowngrade;
my @binarySelectionOrder;
my $fromDIR;
my %rombuildOptions = ("-type-safe-link" => 1 );
my $enforceSysBin = 0;

my $line;
my $errors = 0;
my @romimage;
my $rombasename;

my $sourcefile;
my $sourceline;
my ($line);
my %romfiles;

# To handle BINARY_SELECTION_ORDER macro.
my $firstDIR;
my $binarySelectionOrderFlag = 0;

my %DllDataMap = ();	#Map to keep track of DLL Data patch statements.
my $patchDataStmtFlag = 0;

my $featuremanager = 0; #Flag to enable support for feature manager database XML file and to generate  
			# features data file.
my $noFeatureManager = 0; # Flag to stop the generation of features.dat file and use pre-built features.dat if provided.
my $preBuiltFeaturesDataFile  = ''; # To store the name of pre-built features.dat file provided with "-nofm" option.

#Image Content XML file that supports specific feature to be added
my $image_content = undef;
#Feature list XML file that acts as database containing all features details
my $featureXml = undef;
my $geninc = "";
my $gendep = "";
my $nosymbols = "";
my $noimage = "";
my $customizedPlat = undef;
my $opt_fastcompress = "";
my $opt_jobs= "";

#Summary of files(both executables and data files) currently includes 
#	host and ROM file names, 
#	size of the file in ROM
#	whether the file is hidden
# This option is added so that the above additional information is emitted by rombuild/rofsbuild tools
# only when supplied with this option so that the existing tools don't get affected.
my $logLevel="";

# This option is used to pass -lowmem argument to rombuild/rofsbuild tools
my $lowMem="";

# Feature Variation modules and data
use featurevariantparser;
use featurevariantmap;
my %featureVariant;

# global variables specific to data drive image generation. 
use File::Path;					# Module to provide functions to remove or create directories in a convenient way.
use File::Copy;					# Module to provide functions to copy file(s) from source to destination.
use File::Find;
use datadriveimage;				# module which provides all necessary functions to create data drive image.
my $ZDirloc = "";				# location of Z drive directory.
my $DataDriveDirloc = "";		# location of data drive directory.
my @sisfilelist;				# an array to hold sis file(s).
my @zDriveImageList;			# an array to hold z drive image name.
my @datadiveobydata;			# an array to hold data drive oby data.
my @datadriveimage;				# array which holds data drive image attribute.
my $rootdir = "";				# which holds root directory information.
my @datadrivedata;				# array to maintain list of lines taken from processed data drive oby file.
my @nonsisFilelist;				# array to maintain list of nonsis file(s). 
my @sisobydata;					# array to maintain all list of files(s) got by installing sis files. 
my @renameList;					# array to maintain list of file(s) that has to be renamed.
my @aliaslist;					# array to maintain list of file(s) that has to be made alias.
my @hideList;					# array to maintain list of file(s) that has to be made hidden.
my $sisfilepresent = 0;			# enable if sis file(s) are present.
my $stubsisfilepresent = 0;		# enable if stub-sis file(s) are present.
my $opt_k = 0;					# enable if keepgoing option is specified by the user.
my $opt_r = 0;					# enable if retain pre-existence of folder is specified by the user.
my $dataImageCount = 0;			# no of data drive image that has to generated.
my @zdriveImageName;			# list of Z drive image name(s) specified using zdriveimagename in oby/iby file.
my $opt_zimage = 0;				# enable if z drive image is found.
my $zDrivePresent = 0;			# flag to check whether Z drive needs to be created.
my @dataDriveFileList;			# list of processed data drive related files.
my $paraFile = undef;			# parameter file for interpretsis.
my @romImages;					# list of generated z drive image(s)(rom/rofs). 
my $imageEntryLogFile = undef;	# a log file to log all the z drive image contents.
my $opt_logFile = 0;			# enable if z drive entries has to be logged on to a log file.
my %dataIndexHash = ();			# a hash which holds key-value pair between datadrive index and datadrive image count.
my $interpretsisOpt = undef;	# enable if command line arguments are specified by the user to INTERPRETSIS.
my @interpretsisOptList;		# an array which holds all the list of option(s) that needs to passed to INTERPRETSIS. 
my @Global_BPABIPlats;
my @Global_PlatList;
my @smrImageFileList;
my $needSmrImage = 0;
my %smrPartitions;
my %smrNameInfo;
my @obeyFileList;
my $smrNoImageName = 0;
my $onlysmrimage = 1;

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
		if (-f "$dir/$obyfile")
		{
		    push @obyfiles, "$dir/$obyfile";
		    return 1;
		}
	}
	return 0;
}


# This function invokes ROFSBUILD tool with appropriate parameters to generate data drive image.
# It also deletes zdrive and datadrive folder after all the image has been processed and generated
# if and only if preserve(-p) option is disabled.
sub create_datadriveImage
{
	for (my $dataidx=0; $dataidx < $dataImageCount; $dataidx++)
	{
		my $driveIndex = $dataIndexHash{$dataidx};

		if(defined($driveIndex))
		{
			my $obeyfile=$datadriveimage[$driveIndex]{obeyfile};
			my $compress=$datadriveimage[$driveIndex]{compress};
			my $uncompress=$datadriveimage[$driveIndex]{uncompress};

			if ($obeyfile)
			{
				if(!defined $opt_compression)
				{
					if ($compress ne 0)
					{
						$compress=" -compress";
					}
					elsif($uncompress ne 0)
					{
						$compress=" -uncompress";
					}
					elsif($compress eq 0)
					{
						$compress=" ";
					}
				}
				else
				{
					$compress = $opt_compression;
					$compress =~m/\s-(compression)(method)\s(none|inflate|bytepair)/;
					print "* ".$1." ".$2.": ".$3;
				}
				my $command = "rofsbuild -slog".$compress." -datadrive=$obeyfile.oby";
				print "* Executing $command\n" if ($opt_v);
				system($command);
				if ($? != 0)
				{
					&datadriveimage::reportError("* ROFSBUILD failed to generate data drive image",$opt_k);
				}
				else
				{
					push(@dataDriveFileList,$obeyfile.".img");
				}
			}
		}
	}
	# after processing all the data drive image(s) delete zdrive and datadrive directory 
	# if and only if preserve(-p) option is disabled.
	if($dataImageCount)
	{
		# delete Z drive directory if and only if preserve(-p) option is disabled.
		my $retVal = &deleteDirectory($ZDirloc,$opt_v)if(!($preserve));
		if($retVal)
		{
			&datadriveimage::reportError("* Warning could not delete $ZDirloc",$opt_k);
		}
		# delete data drive directory if and only if preserve(-p) option is disabled.
		my $retVal = &deleteDirectory($DataDriveDirloc,$opt_v)if(!($preserve));
		if($retVal)
		{
			&datadriveimage::reportError("* Warning could not delete $DataDriveDirloc",$opt_k);
		}
		# reset image count to zero.
		$dataImageCount = 0;
		# reset z drive present to zero.
		$zDrivePresent = 0;
	}
}

sub tidy_exit
{
	#-------------------------------------------------------
	# Tidy and exit
	
	if (!$preserve)
	{
	    foreach my $tempfiles (@tempfiles)
	    {
			unlink "$tempfiles";
	    }
	}
	if($rombasename)
	{
		system("dir $rombasename.*");
	}
	if(@dataDriveFileList)
	{
		print "\n";
		print " ----------------------------------------------------------\n";
		print "| List of file(s) generated pertaining to data drive image |\n";
		print " ----------------------------------------------------------\n";
		my $arraySize = scalar(@dataDriveFileList);
		for( my $i=0; $i < $arraySize; $i++ )
		{
			# remove the first element from an array and return it 
			my $element = shift(@dataDriveFileList);
			# get the size of the file.
			my $size = -s $element;
			print "Size = ".$size." bytes"."\t"."File = ".$element."\n";
		}
	}
	exit(0);
}

# This is the main function which is responsible for processing data drive image.
# This function internally calls other functions to create datadrive folder,zdrive folder
# and external tools such as INTERPRETSIS, READIMAGE and finally ROFSBUILD to generate 
# appropriate data drive image.
sub processData		
{
	if($dataImageCount)
	{
		# set the default path for Z drive and Data drive directory,
		# if and only if, path is not specified by the user. 
		$ZDirloc = &datadriveimage::setPath("zdrive") unless ($ZDirloc);
		$DataDriveDirloc = &datadriveimage::setPath("datadrive") unless ($DataDriveDirloc);
		#delete any existing Z drive directory.
		my $retVal = &datadriveimage::deleteDirectory($ZDirloc,$opt_v)if(!$opt_r);
		if($retVal)
		{
			exit(1) if(!$opt_k);
		}
		# delete pre-existence of data drive folder, if and only if -r option is not enabled.
		my $retVal = &datadriveimage::deleteDirectory($DataDriveDirloc,$opt_v) if(!$opt_r);
		if($retVal)
		{
			exit(1) if(!$opt_k);
		}
		if($opt_logFile)
		{
			# clean any pre-existance of log file.
			unlink($ZDirloc."\\".$imageEntryLogFile);
		}
		
		for (my $datadriveidx=0; $datadriveidx < $dataImageCount; $datadriveidx++)
		{
			my $driveIndex = $dataIndexHash{$datadriveidx};
			# get the data drive name.
			if( defined( $driveIndex ) )
			{
				my $datadrivename=$datadriveimage[$driveIndex]{obeyfile};
				# get the size of the data drive.
				my $size = $datadriveimage[$driveIndex]{size};
				if( $datadrivename )
				{
					# set data drive oby file.
					my $datadriveobyfile = $datadrivename.".oby";
					# final location of prototype data drive.
					my $proDataDriveDirloc;
					# Location of stub-sis file(s) inside Z Drive folder.
					my $zDriveSisFileLoc;
					# check if more than one data drive image needs to be generated. 
					if( $dataImageCount > 1 )
					{
						# if yes, then set the location of prototype data drive folder as 
						# DataDriveDirloc + datadrivename
						$proDataDriveDirloc = $DataDriveDirloc."\\".$datadrivename;
					}
					else
					{
						# else, then set the location of prototype data drive folder as DataDriveDirloc 
						$proDataDriveDirloc = $DataDriveDirloc;
					}

					# create prototype data drive folder.
					print "creating data drive folder\n" if ($opt_v);
					&datadriveimage::createDirectory($proDataDriveDirloc);

					# check for sis file keyword in ROM description file.
					# if found,then locate for stub-sisfile.
					# create Z drive( if and only if stub-sis files are present in ROM description file )
					# and dump all the non-sis files on to the Z drive folder. 
					if(&datadriveimage::checkForSisFile($datadriveobyfile,\@sisfilelist,\$sisfilepresent))
					{
						my $zDriveImagePresent = 0; # flag to check whether z drive image is Present;
						if(&datadriveimage::checkForZDriveImageKeyword($datadriveobyfile,\@zDriveImageList,\$zDriveImagePresent) )
						{
							# find out size of the array
							my $arraysize = scalar(@zDriveImageList);
							for( my $i=0; $i < $arraysize; $i++ )
							{
								$zDriveSisFileLoc =  $ZDirloc."\\".$datadrivename;
								&datadriveimage::invokeReadImage(pop(@zDriveImageList),$zDriveSisFileLoc,$opt_v,$imageEntryLogFile,$opt_k);
							}
						}
						else
						{
							$zDriveSisFileLoc = $ZDirloc;
							# locate and copy stub-sis file(s),for the first time.
							if( !$zDrivePresent )
							{
								# check for image file.
								if( $opt_zimage )
								{
									# image(s)supplied to BUILDROM(like rom,rofs,extrofs or core) using "-zdriveimage" option, 
									# are maintained in a seperate array and the element from the array is fetched one by one and is 
									# fed to READIMAGE as an input.
									foreach my $element (@zdriveImageName)
									{
										# invoke READIMAGE to extract all /swi stub sis file(s) from the given image.
										$zDrivePresent = &datadriveimage::invokeReadImage($element,$zDriveSisFileLoc,$opt_v,$imageEntryLogFile,$opt_k);
									}
								}
								else
								{
									# if zdrive image(s) such as (rom,core,rofs or extrofs) are generated ealier to the data drive image processing
									# then these images are maintained in an array and the element from the array is fetched one by one and is 
									# fed to READIMAGE as an input.
									foreach my $element (@romImages)
									{
										# invoke READIMAGE to extract all /swi stub sis file(s) from the given image.
										$zDrivePresent = &datadriveimage::invokeReadImage($element,$zDriveSisFileLoc,$opt_v,$imageEntryLogFile,$opt_k);
									}
								}
							}
						}
						# invoke INTERPRETSIS tool with z drive folder location.
						&datadriveimage::invokeInterpretsis( \@sisfilelist,$proDataDriveDirloc,$opt_v,$zDriveSisFileLoc,$paraFile,$opt_k,\@interpretsisOptList)if($sisfilepresent);
					}

					# create an oby file by traversing through upated prototype data drive directory.
					&datadriveimage::dumpDatadriveObydata( $proDataDriveDirloc,$datadriveobyfile,$size,\@nonsisFilelist,
										\@renameList,\@aliaslist,\@hideList,\@sisobydata,\@datadrivedata,$opt_k,$opt_v );
					#reset sisfilepresent flag to zero;
					$sisfilepresent =0;
				}
			}
		}
		create_datadriveImage();
	}
	tidy_exit;
}
#Parse and process image content xml file
#Gets the oby files listed in the xml file
# Pushes all the oby files found to an array

sub image_content_processing_phase
{
	if(!defined ($image_content))
	{
		return;
	}
	&ImageContentHandler::ParseImageContentXML($image_content);
	&ImageContentHandler::ProcessImageContent;

	if(defined ($image_content) )
	{
#		Collect the oby files if any in the Image content file
		my $files = &ImageContentHandler::GetObyFiles;
		foreach my $obeyfile (@$files)
		{
			next if match_obyfile($obeyfile);
			next if (match_obyfile("$obeyfile.oby"));
		}
	}
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
   	my %tmpBldRomOpts;

	my ($paramFileFlag, @argList); 

	if (defined @_)
	{
		($paramFileFlag, @argList) = @_;
	}
	else
	{
		@argList = @ARGV;
	}

	if (!defined $paramFileFlag) 
	{
		# Enforce Feature Manager if macro SYMBIAN_FEATURE_MANAGER is defined in the HRH file.
		my @hrhMacros = &Variant_GetMacroList;	
		if (grep /^SYMBIAN_FEATURE_MANAGER\s*$/, @hrhMacros)
		{
			$enforceFeatureManager = 1;
		}
		
		# Process the parameters of parameter-file if passed.
		foreach my $arg (@argList)
		{
			if ($arg =~ /^-argfile=(.*)/) 
			{
				&parameterFileProcessor($1);				
			}
		}
	}

	foreach my $arg (@argList)
	{
	    if ($arg =~ /^-argfile=(.*)/) 
		{
			&parameterFileProcessor($1) if (defined $paramFileFlag);						
			next;			
		}
		if ($arg =~ /^-[DI]/)
	    {
		$cppargs .= " $arg";
		#Set 'udeb' for debug option 
		if($arg =~ /^-D_FULL_DEBUG/)
		{
		    $tmpBldRomOpts{"BUILD_DIR"} = "udeb";
		}
		#Set specific platform supplied from the command option 
		elsif($arg =~ /^-D_PLAT=(.*)/)
		{
		    $tmpBldRomOpts{"ABI_DIR"} = $1;
		}
		# Check for a Feature Variant
		elsif ($arg =~ /^-DFEATUREVARIANT=(.*)/)
		{
			my $varname = $1;
			
			if ($varname =~ /^\.(.*)$/)
			{
				# for testing, locate the VAR file in the current directory
				%featureVariant = featurevariantparser->GetVariant($1, ".");
			}
			else
			{
				%featureVariant = featurevariantparser->GetVariant($varname);
			}
			if (!$featureVariant{'VALID'})
			{
			    print "FEATUREVARIANT $varname is not VALID\n";
				$errors++;
			}
			if ($featureVariant{'VIRTUAL'})
			{
			    print "FEATUREVARIANT $varname is VIRTUAL\n";
				$errors++;
			}
			addDrivesToFeatureVariantPaths();
		}
		next;
	    }
	    if ($arg =~ /^-o(.*)/i)
	    {
		$opt_o = $1;
		next;
	    }
	    if ($arg =~ /^-fastcompress$/i)
	    {
		    $opt_fastcompress = "-fastcompress";
		    next;
	    }
	    if ($arg =~ /^-j(\d+)$/i)
	    {
		    $opt_jobs = "-j".$1;
		    next;
	    }
	    if ($arg =~ /^-v$/)
	    {
		$opt_v =1;
		next;
	    }
	    if ($arg =~ /^-s$/)
	    {
		$strict = 1;
		next;
	    }
	    if ($arg =~ /^-w$/)
	    {
		$warnSelection = 1;
		next;
	    }
	    if ($arg =~ /^-p$/)
	    {
		$preserve = 1;
		next;
	    }
	    if ($arg =~ /^-nospi$/)
	    {
		$createspi=0;
		$spiset=1;
		next;
	    }
	    if ($arg =~ /^-spi$/)
	    {
		$createspi=1;
		$spiset=1;
		next;
	    }	
	    #Process External Tool
	    if ($arg =~/^-e(.*)/)#Match to get the tool perl module files
	    {
		&externaltools::loadTools($1);
		next;
	    }
   		#Process imagecontent file 
	    if( $arg =~ /^-i(.*)/)
	    {
# Disabling -i option
		print "Warning: Ignoring invalid Option $arg \n";
		next;
	    }
		#Process feature manager database xml file 
	    if($arg =~ /^-fm=(.*)/)
	    {
			if (!$enforceFeatureManager) 
			{
				print "Unknown arg: $arg\n";
				$errors++;
				next;
			}
			$featureXml = $1;
			$xmlrequired = 1;
			$featuremanager = 1;
			if ($featureXml =~ /^$/) 
			{
				print "Error: No filename specified with \"-fm=\" option.\n";
			}			
			next;
	    }
	    #Process ROM image compression type if it's specified through command line option.
	    if($arg =~ /^-compress(.*)/)
	    {
	    	if($1 eq '')
	    	{
	    		$opt_compression_type = ALLSECTIONS;
	    		print "Whole ROM image will be compressed.\n";
	    	}
	    	elsif($1 eq '=paged')
	    	{
	    		$opt_compression_type = PAGEDSECTION;
	    		print "Paged section of the ROM image will be compressed.\n";
	    	}
	    	elsif($1 eq '=unpaged')
	    	{
	    		$opt_compression_type = UNPAGEDSECTION;
	    		print "Unpaged section of the ROM image will be compressed.\n";
	    	}
	    	else
	    	{
	    		print "Unknown compression type: $1\n";
	    		$errors++;
	    	}
	    	next;
	    }
		if ($arg =~ /^-nofm(=(.*))?$/)
		{
			if (!$enforceFeatureManager) 
			{
				print "Unknown arg: $arg\n";
				$errors++;
				next;
			}
   			$noFeatureManager = 1;
            #DEF125375 If caller is simply giving -nofm without any parameter, a warning message will be given.
            if(!$2)
            {
                print "Warning: No filename specified with \"-nofm=\" option, feature data file might not be included.\n";
            }
            else
            {
                $preBuiltFeaturesDataFile = $2;						
            }
			next;	
		}
		#Process feature registry database xml file 
	    if($arg =~ /^-fr=(.*)/ || $arg =~ /^-f(.*)/)
	    {
			if ($enforceFeatureManager)
			{
				print "Error: Option \"-f|-fr\" is no longer supported.\n";
				$errors++;
				next;
			}			
			$featureXml = $1;
			$xmlrequired = 1;			
			if ($featureXml =~ /^$/) 
			{
				print "Error: No filename specified with \"-f|-fr\" option.\n";				
			}
			next;
	    }
	    if ($arg =~ /^-spiplacement$/)
	    {
			$spiplacement = 1;
			next;
	    }
		if ($arg =~ /^-noimage$/)
		{
			$noimage=1;
			next;	
		}
		if ($arg =~ /^-nosymbols$/)
		{
			$nosymbols=1;
			next;	
		}
		if ($arg =~ /^-geninc$/)
		{
			$geninc=1;
			next;	
		}
		if($arg =~ /^-gendep$/)
		{
			$gendep=1;
			next;
		}
        if($arg =~/^-c(.*)/)
        {
          if($1 eq 'none' )
          {
              $opt_compression = " -compressionmethod none";
          }
          elsif($1 eq 'inflate' )
          {
              $opt_compression = " -compressionmethod inflate";
          }
          elsif($1 eq 'bytepair' )
          {
              $opt_compression = " -compressionmethod bytepair";
          }
          else
          {
              print "Unknown compression method: $1\n";
              $errors++;
          }
          next;
        }
		if( $arg =~ /^-loglevel\d+$/)
		{
			$logLevel= $arg;
			next;
		}
		# get Z directory location if specified by the user.
		# if yes, then extract directory location from the given array element. 
		if( $arg =~ /^-z=(.*)/  || $arg =~ /^-zdrivepath=(.*)/i )
		{
			# check for white space in the specified folder path
			# if "yes" then warn the user saying folder will be created under default location.
			# else set the path specified by the user.
			if(&datadriveimage::checkForWhiteSpace($1,"zdrive"))
			{
				next;
			}
			else
			{
				$ZDirloc  = $1;
				if( $ZDirloc !~ m/\\(\Z)/)
				{ 
					$ZDirloc .= "\\"; 
				}
				if( $ZDirloc !~ m/:/)
				{
					print "drive letter not specified\n";
					$ZDirloc = &datadriveimage::setPath($ZDirloc);
				}
				print "Z Drive directory location = $ZDirloc\n";
				#set the location of Z Drive directory.
				$ZDirloc .= "zdrive";
			}
			next;
		}
		# get data directory location if specified by the user.
		# if yes, then extract directory location from the given array element. 
		if( $arg =~ /^-d=(.*)/ || $arg =~ /^-datadrivepath=(.*)/i )
		{
			# check for white space in the specified folder path
			# if "yes" then warn the user saying folder will be created under default location.
			# else set the path specified by the user.
			if(&datadriveimage::checkForWhiteSpace($1,"datadrive"))
			{
				next;
			}
			else
			{
				$DataDriveDirloc = $1;
				if( $DataDriveDirloc !~ m/\\(\Z)/)
				{ 
					$DataDriveDirloc .= "\\"; 
				}
				if( $DataDriveDirloc !~ m/:/)
				{
					print "drive not specified\n";
					$DataDriveDirloc = &datadriveimage::setPath($DataDriveDirloc);
				}
				print "Data Drive directory location = $DataDriveDirloc\n";
				#set the location of Data Drive directory.
				$DataDriveDirloc .= "datadrive";
			}
			next;
		}
		# get Z dive image if specified by the user.
		if( $arg =~ /^-zdriveimage=(.*)/i )	
		{
			my $imageName = $1;
			if( $imageName =~ m/\,/)
			{
				@zdriveImageName = split(/\,/,$imageName);
			}
			else
			{
				push(@zdriveImageName,$imageName);
			}
			$opt_zimage = 1;
			next;
		}
		# get command line arguments which needs to be passed to INTERPRETSIS, if specified by the user.
		if( $arg =~ /^-argforinterpretsis=(.*)/i )	
		{
			my $interpretsisOpt = $1;
			if( $interpretsisOpt =~ m/\,/)
			{
				@interpretsisOptList = split(/\,/,$interpretsisOpt);
			}
			else
			{
				push(@interpretsisOptList,$interpretsisOpt);
			}
			next;
		}
		if ( $arg =~ /^-k$/i || $arg =~ /^-keepgoing$/i )
	    {
			$opt_k = 1;
			next;
	    }
		if ( $arg =~ /^-r$/i || $arg =~ /^-retainfolder$/i )
	    {
			$opt_r = 1;
			next;
	    }
		if ( $arg =~ /^-pfile=(.*)/i )
	    {
			$paraFile = $1;
			next;
	    }
		if ( $arg =~ /^-l=(.*)/i || $arg =~ /^-logimageentry=(.*)/i )
	    {
			if( $1 =~/\\/ || $1 =~ m/:/)
			{
				print "* Warning: Invalid log file extension try filename.txt\n";
				next;
			}
			else
			{
				$opt_logFile = 1;
				$imageEntryLogFile = $1;
			}
			next;
	    }
		if ( $arg =~ /^-lowmem/i )
		{
			$lowMem = $arg;
			next;
		}
	    if ($arg =~ /^-/)
	    {
		print "Unknown arg: $arg\n";
		$errors++;
		next;
	    }
	    # It's an OBY file
	    next if (match_obyfile($arg));
	    next if (match_obyfile("$arg.oby"));

	    print "Cannot find oby file: $arg\n";
	    $errors++;
	}

	if (defined $paramFileFlag) 
	{
		return;
	}
	
	if (@obyfiles<1)
	{
	    print "Missing obyfile argument\n";
	    $errors++;
	}

	if ($errors)
	{
	    print_usage();
	    exit 1;
	}
	
	if ($noFeatureManager && $featuremanager) 
	{
		print "Warning: Ignoring \"-nofm\" option, as both \"-nofm\" and \"-fm\" options are provided.\n";			
		$noFeatureManager = 0;
	}

	# Adding variant specific macros by including a HRH file
	# (only required if no Feature Variant is used)
	if (!$featureVariant{'VALID'})
	{
	    my $variantMacroHRHFile = Variant_GetMacroHRHFile();
	    if($variantMacroHRHFile){

	        my $variantFilePath = Path_Split('Path',$variantMacroHRHFile);
	        $cppargs .= " -I \"" . &Path_RltToWork($variantFilePath) . "\" -include \"" . &Path_RltToWork($variantMacroHRHFile) . "\""; 
	    }
	}
	# load the required modules if xml is required
	if ($xmlrequired == 1)
	{
	    my $epocToolsPath = $ENV{EPOCROOT}."epoc32\\tools\\";
	    Load_SetModulePath($epocToolsPath);
	    if (defined ($featureXml))
	    {
			load_featuresutil();
	    }
	
	    if ($image_content)
	    {
	    	&Load_ModuleL("ImageContentHandler");
	    	# some variables for ImageContentHandler may have been setup
	    	my ($key, $value);
	    	&ImageContentHandler::SetBldRomOpts; # Defaults to ARMV5 platform
	    	while (($key,$value) = each %tmpBldRomOpts)
	    	{
			&ImageContentHandler::SetBldRomOpts($key, $value);
	    	}
	    }
	    
	}
}

#----------------------------------------------------------------------------------
# Preprocessing phase
#
# Concatentate the specified .oby files and pass them through cpp
# to get the raw ROM specification in tmp1.oby

sub preprocessing_phase
{
	unlink "tmp1.oby";

#	Macro "ROM_FEATURE_MANAGEMENT" is defined when "-f|fr" or "-fm" is used
	if (defined ($featureXml))
	{
		$cppargs .= " -DROM_FEATURE_MANAGEMENT ";
	}

	# add pre-include file and include directories for feature variants
	if ($featureVariant{'VALID'})
	{
		$cppargs .= " -I.";
		my $incRef = $featureVariant{'ROM_INCLUDES'};
		if ($incRef)
		{
			foreach (@$incRef)
			{
		    	$cppargs .= " -I \"$_\"";
			}
		}
		my $HRH = $featureVariant{'VARIANT_HRH'};
		if ($HRH)
		{
		    $cppargs .= " -include \"$HRH\"";
		}
	}
	else
	{
		# no feature variant so use the standard includes
		$cppargs .= " -I. -I$rominclude";
	}

	print "* cpp -o tmp1.oby $cppargs\n" if ($opt_v);
	
	$errors = 0;
	open CPP, "| cpp -o tmp1.oby $cppargs" or die "* Can't execute cpp";
	foreach my $arg (@obyfiles)
	{
		print CPP "\n#line 1 \"$arg\"\n";
	
		open OBY, $arg or die "* Can't open $arg";
		print "* reading $arg\n" if ($opt_v);
		while ($line=<OBY>)
		{
			print CPP $line;
		}
		close OBY;
	}
	close CPP;
	my $cpp_status = $?;
	die "* cpp failed\n" if ($cpp_status != 0 || !-f "tmp1.oby");

	my $temp1OBYFile = "tmp1.oby";
	if( defined ($image_content))
	{
		#Read the OBY file that was generated by the pre-processor
		&ReadPreprocessedFile($temp1OBYFile);

#		Check if the static dependencies of the OBY binaries are resolved.
		&ImageContentHandler::UpdateObyBinaryStaticDep();
		
		#Now append the files collected from cdfs.
		&ImageContentHandler::GenObyFile($temp1OBYFile);
	}

	# Setup default rom configuration
	$romimage[0] = {xip=>1, compress=>0, extension=>0, composite=>"none",uncompress=>0 };
}

sub ReadPreprocessedFile
{
#	Read the OBY file that was generated by the pre-processor. This OBY is a conglomeration of all the OBYs
#	passed directly to buildrom and/or the ones passed through Image Content XML.
#	It marks the binaries coming from OBY. This is required to be able to point out the binaries that are 
#	mentioned neither in the OBY nor in the CDF. Such binaries are arrived at through static dependencies
#	and need to be included in ROM.

	my $temp1OBYFile = shift;
	my $tmpline;
	my $srcFileName;
	my $srcFilePath;
	my $dstFileName;
	my $dstFilePath;
	open (OBYFH, "$temp1OBYFile") or die("* Can't open $temp1OBYFile\n");
	while($tmpline =<OBYFH>) {
		if ($tmpline=~/(\S+)\s*=\s*(\S+)\s+(\S+)/) {#Get the first parameter (source File path) from oby line
			$srcFilePath = $2;
			$dstFilePath = $3;

			if ($srcFilePath=~/.*\\(\S+)/) {
				$srcFileName = $1;
			}
			if ($dstFilePath=~/.*\\(\S+)/) {
				$dstFileName = $1;
			}
			my $binaryInfoRef = &cdfparser::GetBinaryInfo($dstFileName);

			if(defined($binaryInfoRef)) 
			{
				#Found in CDF file
				if($binaryInfoRef->{IsFoundInCDF})
				{
					print "Warning: File $srcFileName mentioned in OBY as well as CDF file\n";
				}
			}
			else
			{
				#Found in OBY file
				&ImageContentHandler::AddBinaryFromOby($dstFileName, $srcFilePath);
			}
		}
	}
	close OBYFH;
}


#----------------------------------------------------------------------------------
# Substitution phase
#
# Handle the "define XXX YYY" lines, perform the substitutions.
# Print out any ECHO lines or ERROR lines. 
#

# Predefined substitutions: 
#   TODAY means todays' date
#   RIGHT_NOW means the exact time
#   EPOCROOT taken from the environment

sub substitution_phase
{
	{
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
		$substitutionData{"TODAY"} = sprintf("%02d/%02d/%04d", $mday, $mon+1, $year+1900);
		$substitutionData{"RIGHT_NOW"} = sprintf("%02d/%02d/%04d %02d:%02d:%02d", $mday, $mon+1, $year+1900, $hour, $min, $sec);
		$substitutionData{"EPOCROOT"} = $epocroot;
		@substitutionOrder = ("TODAY", "RIGHT_NOW", "EPOCROOT");
	}

	
	open TMP1, "tmp1.oby" or die("* Can't open tmp1.oby\n");
	while ($line=<TMP1>)
	{

		if(($line =~ /^\s*romsize\s*=/i) || ( $line=~ /^\s*rom_image/i) || ($line =~ /^\s*data_image/i))
		{
			$onlysmrimage = 0;
			last;
		}
	}
	close TMP1;	
	if ($enforceFeatureManager && (!$featuremanager) && (!$noFeatureManager) )
	{
		my $defaultFeatureDbFlag = 0;
		open TMP1, "tmp1.oby" or die("* Can't open tmp1.oby\n");
		while ($line=<TMP1>)
		{
			if ($line=~/^\s*defaultfeaturedb\s*=?\s*(\S+)/i)
			{	
				# Get the default value for featuredatabasefile
                
				$featureXml = "$epocroot$1";
				$featuremanager = 1;				
				$defaultFeatureDbFlag = 1;
				load_featuresutil();				
				last;
			}
		}
		close TMP1;

		if(!$defaultFeatureDbFlag && !$onlysmrimage)
		{
			print "Error: Neither option \"-fm|-nofm\" nor default value for featuredatabase file is provided.\n";
			exit(1);			
		}
	}

	open TMP1, "tmp1.oby" or die("* Can't open tmp1.oby\n");
	while ($line=<TMP1>)
	{
		track_source($line);
		#
		# Recognise keywords in lines that we process before substitution
		#
		# # lineno "file" flagno
		# DEFINE name replacement-with-0-spaces
		#
		if($line=~/^\s*$/)
		{
			next;
		}
		if ($line=~/^# (\d+) "(.*)" (\d+)/)
		{
			push @obydata, $line;
			next;
		}

		if ($line=~/^\s*defaultfeaturedb\s*=?\s*(\S+)/i)
		{	
			push @obydata, "REM $line";
			next;
		}		
		#process the External tool invocation using IBY file
		if ($line=~/externaltool=(.*),?/i)
		{
			&externaltools::loadTools($1);
			next;
		}

		#Process the patch statement
		if($line =~ /^\s*patchdata\s*(.*)/i)
		{
			$patchDataStmtFlag = 1;
			my $new_line = $1;
 			# syntax "<DLLnamewithpath> addr <variableaddress> <variablesize> <newvalue>"
 			# If the line matches with above syntax, just add the line into oby file.
 			if($new_line !~ /^\s*(\S+)\s+addr\s+(\S+)\s+(\S+)\s+(\S+)\s*$/i)
 			{
 				if(AddDllDataInfo($new_line))
 				{
 					$line = "REM $line";
 				}
 			}
		}

		if($line =~ /^\s*FEATURE\s*(.*)/i || $line =~ /^\s*EXCLUDE_FEATURE\s*(.*)/i)
		{
			# Process the feature keywords only when "-f|fr" or "-fm" is passed to buildrom
			if(defined ($featureXml))
			{
				push @obydata, "$line";
			}
			else
			{
				push @obydata, "REM handled $line";
			}
			next;
		}

		if ($line=~/^\s*DEFINE\s+(\w+)\s+(\S+)/i)
		{
			my $key=$1;
			my $value=$2;
			foreach my $wordToSubstitute (@substitutionOrder)
			{
				my $whatToSubstituteItWith=$substitutionData{$wordToSubstitute};
				$value=~s/$wordToSubstitute/$whatToSubstituteItWith/g;
			}
			$value=~s/##//g;
			if (defined $substitutionData{$key})
			{
				# If the key is redefined, apply it at the new position rather
				# than the old one.
				push @obydata, "REM redefined $key as $value\n";# Leave a record of the definition
				@substitutionOrder = grep !/^$key$/, @substitutionOrder;
			}
			else
			{
				push @obydata, "REM defined $key as $value\n";	# Leave a record of the definition
			}
			$substitutionData{$key}=$value;
			
			foreach my $wordToSubstitute (@substitutionOrder)
		    {
	   	        if ($key =~ /$wordToSubstitute/)
	   	        {
				   print_source_error("Warning: $key is masked by earlier definition of $wordToSubstitute");
			 	}
			}
	
			push @substitutionOrder, $key;
			next;
		}
		#
		# Do the substitutions in strict order of definition, 
		# then eliminate any old-fashioned ## things which may be left
		#
		foreach my $wordToSubstitute (@substitutionOrder)
		{
			my $whatToSubstituteItWith=$substitutionData{$wordToSubstitute};
			$line=~s/$wordToSubstitute/$whatToSubstituteItWith/g;
		}
		$line=~s/##//g;
		#
		# Recognise keywords in lines that we process after substitution
		#
		# ECHO  anything at all
		# WARNING anything at all
		# ERROR anything at all
		# LANGUAGE_CODE nnn
		# DEFAULT_LANGUAGE nnn
		# ABI_DOWNGRADE from to
		# ROMBUILD_OPTION command-line-option
		# ROM_IMAGE
		# PlatSecEnforceSysBin on|off
		# ENABLE_SPI/DISABLE_SPI
		#
		if ($line=~/^\s*ECHO\s+(.*?)\s*$/i)
		{
			print "$1\n";
			push @obydata, "REM handled $line";
			next;
		}
		if ($line=~/^\s*(ERROR|WARNING)\s+(.*?)\s*$/i)
		{
			print_source_error("$1 $2");
			$errors++ if ($1 =~ /ERROR/i);
			push @obydata, "REM handled $line";
			next;
		}
		if ($line=~/^\s*(PlatSecEnforceSysBin)\s+(\S+)\s*$/i)
		{
			$enforceSysBin = ($2 =~ /ON/i);
			push @obydata, $line;
			next;
		}
		if ($line=~/^\s*LANGUAGE_CODE\s+(\S+)\s*/i)
		{
			my $code = $1;
			if ($code !~ /^\d\d+$/)
			{
				print_source_error("bad language code $code");
				$errors++;
			}
			else
			{
				$languageCodes{$code} = 1;
			}
			push @obydata, "REM handled $line";
			next;
		}
		if ($line=~/^\s*DEFAULT_LANGUAGE\s+(\S+)\s*/i)
		{
			my $code = $1;
			if ($code !~ /^\d\d+$/)
			{
				print_source_error("bad default language code $code");
				$errors++;
			}
			else
			{
				$defaultLanguageCode = $code;
			}
			push @obydata, "REM handled $line";
			next;
		}
		
		if ($line=~/^\s*ABI_DOWNGRADE\s*/i)
		{
			if ($line =~ /\s(.+)\s*->\s*(.+)\s*$/)
			{
				$abiDowngrade = "$1 $2";
			}
			else
			{
				print_source_error("bad ABI downgrade : $line");
				$errors++;
			}
			push @obydata, "REM handled $line";
			next;
		}
		if ($line=~/^\s*BINARY_SELECTION_ORDER\s*/i)
		{
	 		if ($line =~ /\s([^,]+)\s*,\s*(.+)\s*$/)
   			{
  				$binarySelectionOrderFlag = 1;
 				$firstDIR = $1;
   				# remove whitespaces
 				$firstDIR = trim($firstDIR); 
   				@binarySelectionOrder = split(',', $2);
   				@binarySelectionOrder = trim(@binarySelectionOrder);

			}
			else
			{
				print_source_error("bad order specified: $line");
				$errors++;
			}
			push @obydata, "REM handled $line";
			next;
		}
		
		if ($line=~/^\s*ROMBUILD_OPTION\s+(\S+)\s*/i)
		{
			$rombuildOptions{$1} = 1;
			push @obydata, "REM handled $line";
			next;
		}
		
		if ($line=~/^\s*enable_spi\s*$/i)
		{
			if(!($spiset)) {
				$createspi=1;
			}
			push @obydata, "REM handled $line";
			next;
		}
		
		if ($line=~/^\s*disable_spi\s*/i)
		{
			if(!($spiset)) {
				$createspi=0;
			}
			push @obydata, "REM handled $line";
			next;
		}

		if ($line=~/^\s*DATA_IMAGE\s+/i)
		{
			if ($line =~ /\s+(\d+)\s+(\S+)\s+/i)
			{
				my $datadriveidx = $1;
				my $datadriveimagename = $2;
				# have a count on number of data drive images that needs to be created
				print "data drive partion name = $datadriveimagename\n " if($opt_v);
				my $dataimagesize = 0;
				if ($line =~ /\s+size=(\S+)\s*/i)
				{ 
					$dataimagesize=$1; 
				}
				my $fstype = "";
				my $compress=0;
				my $uncompress=0;
				if ($line =~ /\s+compress\s*/i)
				{ 
					$compress=1;
				}
				elsif($line =~ /\s+uncompress\s*/i)
				{ 
					$uncompress=1;
				}
				if ($line =~ /\s+fat16\s*/i)
				{ 
					$fstype = "fat16"; 
				}
				if ($line =~ /\s+fat32\s*/i)
				{ 
					$fstype = "fat32"; 
				}
				
				$datadriveimage[$datadriveidx] = {name=>$datadriveimagename, size=>$dataimagesize, compress=>$compress, uncompress=>$uncompress, fstype=>$fstype};
				print "DATA_IMAGE[$datadriveidx] $datadriveimage[$datadriveidx]{name} size=$datadriveimage[$datadriveidx]{size} compress=$compress uncompress=$uncompress fstype=$fstype\n" if ($opt_v);
			}
			else
			{
				print_source_error("bad DATA_IMAGE specification : $line");
				$errors++;
			}
			push @obydata, "REM handled $line";
			next;
		}
		if ($line=~/^\s*ROM_IMAGE\s+/i)
		{
			if ($line =~ /\s+(\d+)\s+(\S+)\s+/i)
			{
				my $romidx=$1;
				my $rompartitionname=$2;
				my $rompartitionsize=0;
				if ($line =~ /\s+size=(\S+)\s*/i)
					{ $rompartitionsize=$1; }
				my $xip=1;
				my $compress=0;
				my $uncompress=0;
				my $extend=0;
				my $composite="none";
				if ($line =~ /\s+non-xip\s*/i)
					{ $xip=0; }
				if ($line =~ /\s+compress\s*/i)
					{ $compress=1; }
				elsif($line =~ /\s+uncompress\s*/i)
					{ $uncompress=1;} # This option is passed to rofsbuild. For rombuild, not saying --compress means to uncompress
				if ($line =~ /\s+extension\s*/i)
					{ $extend=1; }
				if ($line =~ /\s+composite_primary\s*/i) # added to support new composite_primary keyword in obey files
				{	if (!($extend))
						{ $composite="composite_primary"; }
					else
						{ print "Error: composite_primary keyword must be used with a core image\n"; }
				}
				if ($line =~ /\s+composite_secondary\s*/i) # added to support new composite_secondary keyword in obey files
				{ if (!($extend))
						{ $composite="composite_secondary"; }
					else
						{ print "Error: composite_secondary keyword must be used with core image\n"; }
				}
	
				#	Compress and Uncompress are 2 different options and
				#	not mentioning one of them doesn't necessarily mean the other.
	
				$romimage[$romidx] = {name=>$rompartitionname, size=>$rompartitionsize, xip=>$xip, compress=>$compress, extension=>$extend, composite=>$composite, uncompress=>$uncompress};
				print "ROM_IMAGE[$romidx] $romimage[$romidx]{name} size=$romimage[$romidx]{size} xip=$xip compress=$compress extension=$extend composite=$composite uncompress=$uncompress \n" if ($opt_v);
				check_romimage($romidx, $line);
			}
			else
			{
				print_source_error("bad ROM_IMAGE specification : $line");
				$errors++;
			}
			push @obydata, "REM handled $line";
			next;
		}
	
		push @obydata, $line;
	}

	close TMP1;
	exit(1) if ($errors);
	
	dump_obydata("tmp2.oby", "result of substitution phase") if ($opt_v);
}

sub check_romimage
{
	my ($idx, $line) = @_;
	if ($idx gt 7)
	{
		print_source_error("too many roms : $line");
		$errors++;
	}
	if ($romimage[$idx]{xip} eq 0)
	{
		if ($romimage[$idx]{size} eq 0)
		{
			print_source_error("must specify a size for non-xip ROM : $line");
			$errors++;
		}
	}
	if ($romimage[$idx]{extension} ne 0)
	{
		if ($romimage[$idx-1]{extension} ne 0)
		{
			print_source_error("cannot extend ROM image multiple times : $line");
			$errors++;
		}
	}
}

sub dump_obydata
{
	my ($dumpfile, $comment) = @_;
	unlink($dumpfile);
	open DUMPFILE, ">$dumpfile" or die("* Can't create $dumpfile\n");
	print "* Writing $dumpfile - $comment\n";
	my $line;
	foreach $line (@obydata)
	{
		print DUMPFILE $line;
	}
	close DUMPFILE;
}

sub track_source
{
	my ($line) = @_;
	if ($line=~/^# (\d+) "(.*)"/)
	{
		$sourceline=$1-1;
		$sourcefile=$2;
		$sourcefile=~ s/\//\\/g;
		$sourcefile=~ s/\\\\/\\/g;
		return;
	}
	$sourceline++;
}

sub print_source_error
{
	my ($message) = @_;
	print "$sourcefile($sourceline): $message\n";
}

sub reassert_sourceline
{
	my ($offset) = @_;
	return sprintf "# %d \"$sourcefile\" \n", $sourceline+1+$offset;
}


#----------------------------------------------------------------------------------
# Reorganisation phase
#
# Group lines beginning with "rom_image[<id>]" and deposit them in the appropriate
# order.  Truncate the description at the "stop" line, if there is one.

sub reorganize_phase
{
	
	undef @newobydata;
	my @section2;
	my @part3;
	my @part4;
	my @part5;
	my @part6;
	my @part7;
	my @part8;
	my @partitions = ( \@newobydata, \@section2, \@part3, \@part4, \@part5, \@part6, \@part7, \@part8 );
	my @currentpartition;	# partition stack

	my @processedImageIdx;		# list of proccesed data drive image index. 
	my $dataDriveStartRegion = 0;
	my $dataDriveEndRegion = 0;
	my $dataDriveIdx;
	my @datapartition;
	my @linesArray;
	my $curlyBraceShouldFollow;

	my $collect_section2=1;
	my $smrImageStartRegion = 0;
	my $smrImageEndRegion = 0;
	my $smrImageIndex = 0;
	
	foreach $line (@obydata)
	{
		track_source($line);
		if ($line=~/^\s*stop/i)
		{
			last;
		}
		if ($line =~ /^\s*ROM_IMAGE\[(\S+)\]\s+\{(.*)$/i)
		{
			# ROM_IMAGE[n] {
			my $idx=$1;
			my $partition=$partitions[$idx];
			push @currentpartition, $partition;
			$line="REM handled $line";
		}
		elsif( ($line =~ /^\s*DATA_IMAGE\[(\S+)\]\s*$/i) || ($line =~ /^\s*DATA_IMAGE\[(\S+)\]\s*\{\s*$/i))
		{
			# DATA_IMAGE[n] or DATA_IMAGE[n] {  is specified.
			# get the index.
			$dataDriveIdx=$1;
 			if($line !~ /\s*\{\s*/i)
 			{
 				$curlyBraceShouldFollow = 1;
 			}
			# make a check if dataDriveIdx exists in the processedImageIdx array.
			# if no, then push the dataDriveIdx on the processedImageIdx array.
			# if yes,then dont execute the loop.
			if(&datadriveimage::checkInArray(\@processedImageIdx,$dataDriveIdx))
			{
				# push the index on to the array.
				push(@processedImageIdx,$dataDriveIdx);
				# increment the image count. 
				++$dataImageCount;
			}

			$dataIndexHash{($dataImageCount-1)} = $dataDriveIdx;
			# set start of the image section.
			$dataDriveStartRegion = 1;
			# set end of image section to zero.
			$dataDriveEndRegion = 0;
			push (@linesArray,"\n");
			$line="REM handled $line";
		}
		elsif( $line =~ /^\s*SMR_IMAGE\s*\{\s*$/i)
		{
			$smrImageStartRegion = 1;
			$smrImageEndRegion = 0;
			$needSmrImage = 1;
			push (@linesArray, "\n");
			$line="REM handled $line";
		}
 		elsif((defined $curlyBraceShouldFollow) && ($line !~ /^\s*$/i))
 		{
			undef $curlyBraceShouldFollow;
 			if($line !~ /^\s*\{\s*/i)
 			{
 				print "Error: Symbol '{' not followed after the keyword DATA_IMAGE\[".$dataDriveIdx."\]\n";
 				$errors++;
 			}
 			next;
 		}
		# data drive specific keywords.
		elsif( $line =~/^\s*dataimagename\s*\=\s*(\S+)/i )
		{
			# set the name for the image, if image name is specified using driveimagename keyword.
			$datadriveimage[$dataDriveIdx]{name} = $1 if($dataDriveStartRegion && !$dataDriveEndRegion);
			print"datadriveimagename = $datadriveimage[$dataDriveIdx]{name}\n" if($dataDriveStartRegion && !$dataDriveEndRegion && $opt_v);
			# skip the line.
			next;
		}
		elsif( $line =~/^\s*dataimagesize\s*\=\s*(\S+)/i )
		{
			# set the size for the image, if image size is specified using driveimagesize keyword.
			$datadriveimage[$dataDriveIdx]{size} = $1 if($dataDriveStartRegion && !$dataDriveEndRegion);
			print"datadriveimagesize = $datadriveimage[$dataDriveIdx]{size}\n" if($dataDriveStartRegion && !$dataDriveEndRegion && $opt_v);
			# skip the line.
			next;
		}
		elsif( $line =~/^\s*dataimagefilesystem\s*\=\s*(\S+)/i )
		{
			# set the file system type for the image, if image file system is specified using dataimagefilesystem keyword.
			$datadriveimage[$dataDriveIdx]{fstype} = $1 if($dataDriveStartRegion && !$dataDriveEndRegion);
			print"datadriveimagefstype = $datadriveimage[$dataDriveIdx]{fstype}\n" if($dataDriveStartRegion && !$dataDriveEndRegion && $opt_v);
			# skip the line.
			next;
		}
		elsif( $line =~/^\s*compress/i )
		{
			# Compresses the resulting data drive image using the Deflate, Huffman+LZ77 algorithm.
			if($dataDriveStartRegion && !$dataDriveEndRegion)
			{
				$datadriveimage[$dataDriveIdx]{compress} = 1;
				$datadriveimage[$dataDriveIdx]{uncompress} = 0;
				print"datadriveimage[$dataDriveIdx] compress = $datadriveimage[$dataDriveIdx]{compress}\n" if($opt_v);
			}
		}
		elsif( $line =~/^\s*uncompress/i )
		{
			# Uncompresses the resulting data drive image.
			if($dataDriveStartRegion && !$dataDriveEndRegion)
			{
				$datadriveimage[$dataDriveIdx]{uncompress} = 1;
				$datadriveimage[$dataDriveIdx]{compress} = 0;
				print"datadriveimage[$dataDriveIdx] uncompress = $datadriveimage[$dataDriveIdx]{uncompress}\n" if($opt_v);
			}
		}
		elsif ($line =~ /^\s*ROM_IMAGE\[(\S+)\](.*)$/i)
		{
			# ROM_IMAGE[n] file=...
			my $origline=$line;
			$line="$2\n";	# remove the ROM_IMAGE[.] keyword
			my $idx=$1;
			my $partition=$partitions[$idx];
			push @$partition, reassert_sourceline(-1);
			push @$partition, $line;
			$line="REM handled $origline";
		}
		elsif ($line =~ /^\s*DATA_IMAGE\[(\S+)\](.*)$/i)
		{
			# DATA_IMAGE[n] file=...
			my $origline=$line;
			# remove the DATA_IMAGE[.] keyword
			$line="$2\n";
			# get the index value
			my $idx=$1;
			# iterate through the hash to get corresponding 
			# key from the value(i.e idx) 
			while (my($key, $value) = each(%dataIndexHash))
			{
				if ($value eq $idx ) 
				{
					$idx = $key;
				}
			}
			push @{$datapartition[$idx]}, reassert_sourceline(-1);
			push @{$datapartition[$idx]}, $line;
			$line="REM handled $origline";
		}
		elsif ($line =~ /^\s*\}.*$/i)
		{
			if($dataDriveStartRegion)
			{
				# since "}" brace is encountered
				# reset the start of DATA_IMAGE to zero.
				$dataDriveStartRegion = 0;
				# mark the the end of the DATA_IMAGE.
				$dataDriveEndRegion = 1;
				if(!$datadriveimage[$dataDriveIdx]{name})
				{
					# image name is not defined, define a default name.
					$datadriveimage[$dataDriveIdx]{name} = "dataImage".$dataDriveIdx;
				}
				if(!$datadriveimage[$dataDriveIdx]{fstype})
				{
					# image name is not defined, define a default name.
					$datadriveimage[$dataDriveIdx]{fstype} = "fat16";
				}
				foreach my $file (@linesArray)
				{
					push @{$datapartition[($dataImageCount-1)]},$file;
				}
				## if end of the DATA_IMAGE is true,
				## make room for next DATA_IMAGE if any.
				undef(@linesArray); 
				#un define $dataDriveIdx;
				undef($dataDriveIdx);
			}
			elsif($smrImageStartRegion)
			{
				$smrImageStartRegion = 0;
				$smrImageEndRegion = 1;
				foreach my $file (@linesArray)
				{
					push @{$smrPartitions{$smrImageIndex}}, $file;
				}
				undef(@linesArray);
				$smrImageIndex++;
			}
			elsif (scalar @currentpartition > 0)
			{ 
				pop @currentpartition; 
			}
			else
			{ 
				print "WARNING: closing '}' found with no matching 'ROM_IMAGE[<n>]/DATA_IMAGE[<n>] {'\n";
			}
			$line="REM handled $line";
		}
		elsif ($line=~/^\s*section2(.*)$/i)
		{
			my $origline=$line;
			$line="$1\n";	# remove the section2 keyword
			if ($collect_section2)
			{
				push @section2, reassert_sourceline(-1);
				push @section2, $line;
				$line="REM handled $origline";
			}
		}
		elsif ($line=~/^\s*section/i)
		{
			push @newobydata, $line;		# insert the section statement
			if (@section2 != 0)
			{
				push @newobydata, "REM accumulated section2 lines\n";
			}
			foreach $line (@section2)
			{
				push @newobydata, $line;	# insert accumulated section2 lines
			}
			$collect_section2=0;
			$line = reassert_sourceline();
		}
		
		elsif ($line=~/^\s*extensionrom/i)
		{
			# end of ROM description, so deposit accumulated lines
			if (@section2 != 0)
			{
				push @newobydata, "REM accumulated section2 lines\n";
			}
			foreach $line (@section2)
			{
				push @newobydata, $line;	# insert accumulated section2 lines
			}
			$collect_section2=0;
			push @newobydata, reassert_sourceline();
		}
		
		elsif ( scalar(@linesArray) )
		{
			if($dataDriveStartRegion && !$dataDriveEndRegion)
			{
				my $modifiedLine = $line;
				push @linesArray, $modifiedLine;
				$line = "REM handled $line";
			}
			elsif($smrImageStartRegion && !$smrImageEndRegion)
			{
				if($line =~ /^\s*IMAGENAME\s*=\s*(\S+)/i)
				{
					my $smrimagename = $1;
					$smrimagename =~s/(\.img)//i;
					if(exists($smrNameInfo{$smrimagename}))
					{
						$smrNameInfo{$smrimagename}++;
					}
					else
					{
						$smrNameInfo{$smrimagename} = 1;
					}
					$line =~s/(\.img)//i;
				}
				push @linesArray, $line;
				$line = "REM handled $line";
			}
		}
		elsif (scalar @currentpartition)
		{
			my $modifiedLine = $line;
			if ($line =~ /^\s*SPI_POSITION/i)
			{
				if(!($createspi && $spiplacement))
				{
					# comment the line if the spi placement flag is not enabled or if the spi creation is not enabled.
					$modifiedLine = "REM SPI creation/placement flag not enabled. Ignoring SPI_POSITION\n";
					print ("Warning: SPI creation/placement flag not enabled. Ignoring SPI_POSITION\n" ) if ($opt_v);
				}
			}
			# a partition is specified
			# push this line into the currently selected partition
			my $partition=@currentpartition[-1];
			push @$partition, $modifiedLine;
			$line="REM handled $line";
		}
		elsif ($line =~ /^\s*SPI_POSITION/i)
		{
			if(!($createspi && $spiplacement))
			{
                # comment the line if the spi placement flag is not enabled or if the spi creation is not enabled.
                $line = "REM SPI creation/placement flag not enabled. Ignoring SPI_POSITION\n";
                print ("Warning: SPI creation/placement flag not enabled. Ignoring SPI_POSITION\n" ) if ($opt_v);
			}
		}
		push @newobydata, $line;
	}

	# output the grouped data
	my $partitionidx=2;
	if ($collect_section2)
		{ $partitionidx=1; } # output old "section2" if not done already
	for (; $partitionidx<8; $partitionidx++)
	{
		my $partition=$partitions[$partitionidx];
		if (@$partition != 0)
		{
			push @newobydata, "REM ROM_IMAGE[$partitionidx]\n";
			foreach $line (@$partition)
			{
				push @newobydata, $line;	# insert accumulated section2 lines
			}
		}
	}
	
	for ( my $datapartitionidx=0; $datapartitionidx < $dataImageCount; $datapartitionidx++ )
	{
		if( defined( @{ $datapartition[$datapartitionidx] } ) )
		{
			push @newobydata, "REM DATA_IMAGE[$dataIndexHash{$datapartitionidx}]\n" ;
			foreach my $file (@{$datapartition[$datapartitionidx]})
			{
				push @newobydata, $file;
			}
		}
	}

	
	foreach my $imageIndex (keys(%smrPartitions))
	{
		my $imagename;
		my @obeyfile;

		foreach (@{$smrPartitions{$imageIndex}})
		{
			if(/^\s*imagename\s*=\s*(\S+)/i)
			{
				$imagename = $1;
			}
			push @obeyfile, $_;
		}
		if($smrNameInfo{$imagename} == 1)
		{
			push @obeyFileList, $imagename;
			push @newobydata, "REM SMR_IMAGE \n";
			push @newobydata, @obeyfile;
		}
		if(! defined($imagename))
		{
			$smrNoImageName = 1;
		}
		undef $imagename;
		undef @obeyfile;
	}

	@obydata = @newobydata;
	exit(1) if ($errors);
	dump_obydata("tmp3.oby", "result of reorganisation phase") if ($opt_v);
}


#----------------------------------------------------------------------------------
# Plugin phase
#
# Process any plugin annotation lines
# Note: This expands resource lines to include MULTI_LINGUIFY so must be done before
# the Multilinguify phase

# hash of SPI file target directories is located near the start of this file, before sub match_obyfile

sub plugin_phase
{
	undef @newobydata;
	foreach $line (@obydata)
	{
		track_source($line);
	 	if ($line =~ /^\s*REM/i)
		{
		# ignore REM statements, to avoid processing "REM ECOM_PLUGIN(xxx,yyy)"
		}
		elsif(plugin_match($line)) {
			$line = reassert_sourceline();		
		}
		push @newobydata, $line;
	}
		
	@obydata = @newobydata;
	dump_obydata("tmp4.oby", "result of Plugin stage") if ($opt_v);
}

sub plugin_match ()
{
	my ($line) = @_;
	foreach my $plugintype (keys(%plugintypes)) {
	  if ($line =~ m/^.*__$plugintype\_PLUGIN\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/i)
	  	# __<plugin-type>_PLUGIN(emulator directory, file rom dir, dataz_, resource rom dir, filename, resource filename)
	  {
		    my $emulatorDir=$1;
		    my $fileRomDir=$2;
		    my $dataz_= $3;
		    my $resourceDir=$4;
		    my $pluginFileName=$5;
		    my $pluginResourceName=$6;
		    my $spidatahide = 0;
			my $paged_data = "";
  
			if ($line =~ m/paged\s*$/i)
			{
				$line =~ m/\s+(\S+)\s*$/;
				$paged_data = $1;
			}

		    if ($line =~ m/^\s*(_hide)/i )
		    {
		    	$spidatahide = 1;
		    }

		    # for resource files strip the .rsc or .dll from the end   (will be .dll where we use
		    # SYMBIAN_SECURE_ECOM and are building resources to  the same name as ecom plugin dlls)
		    
		    if ($pluginResourceName =~ m/^(.+)\./)
		    {
		      $pluginResourceName = $1;
		    }
		    else
		    {
		      print_source_error("Invalid Resource name: $pluginResourceName in " . $plugintype . "_PLUGIN :$line");
		      #treat as error if strict option selected;
		      $errors++ if ($strict);
		    }

		    if ($spidatahide)
		    {
			push @newobydata, "hide=$fileRomDir\\$pluginFileName\n";
		    }
		    else
		    {
		    	push @newobydata, "file=$emulatorDir\\$pluginFileName $fileRomDir\\$pluginFileName $paged_data\n";
		    }

		    if($createspi) {
		    	    if ($spidatahide)
			    {
			    	push @newobydata, "spidatahide=MULTI_LINGUIFY(RSC $dataz_\\$resourceDir\\$pluginResourceName $resourceDir\\$pluginResourceName) " . lc($plugintype) . "\.spi " . $plugintypes{$plugintype} . "\n";      
			    }
			    else
			    {
			    	push @newobydata, "spidata=MULTI_LINGUIFY(RSC $dataz_\\$resourceDir\\$pluginResourceName $resourceDir\\$pluginResourceName) " . lc($plugintype) . "\.spi " . $plugintypes{$plugintype} . "\n";      
			    }
		  	} else {
		    	    if ($spidatahide)
			    {
			    	push @newobydata, "hide=MULTI_LINGUIFY(RSC $dataz_\\$resourceDir\\$pluginResourceName $resourceDir\\$pluginResourceName)\n";
			    }
			    else
			    {
			    	push @newobydata, "data=MULTI_LINGUIFY(RSC $dataz_\\$resourceDir\\$pluginResourceName $resourceDir\\$pluginResourceName)\n";
			    }
			}
				return 1; #successful match
	   }
     }
}


#----------------------------------------------------------------------------------
# Multilinguify phase
#
# Process the MULTILINGUIFY() lines

sub multlinguify_phase
{
	if ((scalar keys %languageCodes) == 0)
	{
		print "* No language codes specified, defaulting to 01\n";
		$defaultLanguageCode = "01";
	}
	$languageCodes{$defaultLanguageCode} = 1;
	
	undef @newobydata;
	foreach $line (@obydata)
	{
		track_source($line);
		if ($line =~ /^\s*REM/i)
		{
			# ignore REM statements, to avoid processing "REM data=xxx yyy"
		}
		elsif ($line=~/^(.*?)\bMULTI_LINGUIFY\s*\(\s*(\S+)\s+(\S+)\s+(\S+)\s*\)(.*)$/i)
		{
			my $initialStuff=$1;
			my $defaultFileNameExtension=$2;
			my $sourceFileNameWithoutExtension=$3;
			my $targetFileNameWithoutExtension=$4;
			my $finalStuff=$5;
			my $spidataflag = 0;
			my $spidatahide = 0;
			my $datahide = 0;

			if ($initialStuff=~/\w$/)
			{
				$initialStuff.=" ";
			}
			if ($finalStuff=~/^\w/)
			{
				$finalStuff=" ".$finalStuff;
			}
			if ($initialStuff =~ /^\s*spidata/i)
			{
				$spidataflag = 1;
			}
			if ($initialStuff =~ /^\s*spidatahide/i)
			{
				$spidataflag = 1;
				$spidatahide = 1;
			}
			if ($initialStuff =~ /^\s*hide/i)
			{
				$datahide = 1;
			}


# ecom.spi should contain the .RSC files
			if ($spidataflag)
			{
				my $sourceFileNameExtension = $defaultFileNameExtension;
				my $targetFileNameExtension = $defaultFileNameExtension;
				if (-e "$sourceFileNameWithoutExtension.$sourceFileNameExtension")
				{
					if ($spidatahide)
					{
						push @newobydata, "$initialStuff$sourceFileNameWithoutExtension.$sourceFileNameExtension$finalStuff\n";
					}
					else
					{
						push @newobydata, "$initialStuff$sourceFileNameWithoutExtension.$sourceFileNameExtension $targetFileNameWithoutExtension.$targetFileNameExtension$finalStuff\n";
					}
				}
			}
			my $useDefaultFileNameExtension=1;
			foreach my $languageCode (keys %languageCodes) {
				my $sourceFileNameExtension=$defaultFileNameExtension;
				$sourceFileNameExtension=~s/^(.*).{2}$/$1$languageCode/;
				if (! -e "$sourceFileNameWithoutExtension.$sourceFileNameExtension")
				{
					if (!$spidataflag)
					{
						next if (!$useDefaultFileNameExtension);
						next if (defined $defaultLanguageCode and !($languageCode eq $defaultLanguageCode));
						$useDefaultFileNameExtension=0;
						if (!$datahide)
						{
							print "Converting >$sourceFileNameWithoutExtension.$sourceFileNameExtension< to $defaultFileNameExtension\n";
							$sourceFileNameExtension=$defaultFileNameExtension;
						}
					}
					else
					{
						next;
					}
				}

				my $targetFileNameExtension;
# ecom.sNN should contain the corresponding language code .RNN files
				if(!$spidataflag and (defined $defaultLanguageCode and ($languageCode eq $defaultLanguageCode)))
				{
					$targetFileNameExtension = $defaultFileNameExtension;
				}
				else
				{
					$targetFileNameExtension = $sourceFileNameExtension;
				}
				my $modifiedfinalStuff = $finalStuff;
				$modifiedfinalStuff =~ s/\.spi/\.s$languageCode/i;

				if ($spidatahide)
				{
					push @newobydata, "$initialStuff$sourceFileNameWithoutExtension.$sourceFileNameExtension$modifiedfinalStuff\n";
				}
				elsif ($datahide)
				{
					push @newobydata, "$initialStuff$targetFileNameWithoutExtension.$targetFileNameExtension$modifiedfinalStuff\n";
					if(!($sourceFileNameExtension eq $targetFileNameExtension))
					{
						push @newobydata, "$initialStuff$targetFileNameWithoutExtension.$sourceFileNameExtension$modifiedfinalStuff\n";
					}
				}
				else
				{
					push @newobydata, "$initialStuff$sourceFileNameWithoutExtension.$sourceFileNameExtension $targetFileNameWithoutExtension.$sourceFileNameExtension$modifiedfinalStuff\n";
					if(!($sourceFileNameExtension eq $targetFileNameExtension))
					{
						push @newobydata, "alias $targetFileNameWithoutExtension.$sourceFileNameExtension $targetFileNameWithoutExtension.$targetFileNameExtension $modifiedfinalStuff\n";
						$multiLinguifyAlias{"$targetFileNameWithoutExtension.$sourceFileNameExtension"} = 1;
					}
				}
			}
			$line = reassert_sourceline();
		}
		push @newobydata, $line;
	}
		
	@obydata = @newobydata;
	dump_obydata("tmp5.oby", "result of choosing language-specific files") if ($opt_v);
	undef @newobydata;

}

my @featurefilearray; #2d array storing names and locations of feature files in each rom image
my @featureslist; #array of hashes, stores all the features which are to go into the feature files
my $featurefilecount=0; #counts number of feature files in each rom image
my $featurescount=0; #counts number of features
my $dir; # Stores the ROM image location of features.dat/featreg.cfg files
my $featurefilename; # Stores the name of feature file to be generated(i.e. "features.dat" or "featreg.cfg")
my @spiarray; #2d array storing names and locations of spi files in each rom image
my @datafiles; #array of hashes, stores all the data files which are to go into the spi files
my @hidedatafiles; #array of hashes, stores all the data files which are to be hidden in the spi files
my $spicount=0; #counts number of spi files in each rom image
my $filescount=0; #counts number of data files
my $hidefilescount=0; #counts number of data files to be hidden
my $romimage=0; #number of rom image currently working with

sub locateexisting 
{ # if an SPI file of this type exists in a base image then returns name of SPI file from the array
	my ($romimage, $spifile, $base) =@_;
	my $i=0;
	while(defined $spiarray[$base][$i]) {
		if($spiarray[$base][$i]{spi} eq $spiarray[$romimage][$spifile]{spi}) {
			my $spiname;
			my $spiextension;
			if($spiarray[$base][$i]{spifile} =~ /(.*)\.(.*)$/) {
				$spiname=$1;
				$spiextension=$2;
			}
			if(-e "$spiname-$base-$i\.$spiextension") {
					return "$spiname-$base-$i\.$spiextension";
			}
		}
		$i++;
	}
	return "";
}

sub create 
{ #called to create SPI file and store in specified directory
	my ($romimage, $spifile, $base) =@_; #$romimage = current rom image number, $spifile = current spifile number, $base=number of rom image basing on
	my $existingspi = "";
	if(defined($base)) { # checks core image for an existing SPI file of this type, if an existing file exists then $existingspi is set to -i<name of existing spi file> which will later be passed to spitool.pm
		$existingspi = locateexisting($romimage, $spifile, $base);
		if($existingspi ne "") {
			$existingspi = "-i$existingspi";
			
		}
	}
	if($spiarray[$romimage][$spifile]{spifile} =~ /(.+)\.(.*)$/) {
		my $targetspi="$1-$romimage-$spifile\.$2"; #add romimage number and identifier for spi file to spi file name to distinguish from other spi files
		my @dataforspi; # array to store names of data files to include in spi file
		my @hidedatainspi; # array to store names of data files that are to be hidden in spi file
		for(my $k=0;$k<scalar @datafiles;$k++) {
			if($datafiles[$k]{rom}==$romimage && $datafiles[$k]{spifile} == $spifile) {
				push @dataforspi, $datafiles[$k]{data}; #push name of data file onto array if correct romimage and spi type
			}
		}

		for(my $j=0;$j<scalar @hidedatafiles;$j++) {
			if($hidedatafiles[$j]{rom}==$romimage && $hidedatafiles[$j]{spifile} == $spifile)
			{
				push @hidedatainspi, $hidedatafiles[$j]{data}; #push name of data file to be hidden onto array if correct romimage and spi type
			}
		}
		my @spiargs; #arguments passed to createSpi
		push @spiargs, ("-t$targetspi", "-d\\$thisdir", "-hide@hidedatainspi");
		if($existingspi ne "") { push @spiargs, $existingspi; }
		&spitool::createSpi(@spiargs, @dataforspi); # external call to 
	}
}

#----------------------------------------------------------------------------------
# SPI file creation phase
#
# If SPI files for resource (.rsc) are required then creates SPI files for each ROM image
#
sub spi_creation_phase
{
	my $composite_secondary=-1;
	if($createspi) { 
		my $secondary=0;
		for (my $i=1; $i<8; $i++)
		{
			if($romimage[$i]{composite} eq "composite_secondary") 
				{ $secondary++; }
		}
		if(!$secondary) 
			{ $romimage[0]{composite} = "composite_secondary"; }
		if($secondary>1)
			{ print "Warning, more than one composite_primary specified, using image with lowest ROM_IMAGE number\n"; }
	
		foreach $line (@obydata)
		{
			if ($line=~/^\s*REM \s*ROM_IMAGE\[(\d)\]/) # specify which romimage following lines are part of
			{
				$romimage=$1;
				$spicount=0;
			}	elsif ($line =~ /^\s*REM/i)
			{
				# ignore any other REM statements
			} elsif ($line=~/^\s*spidata\s*=\s*(\S+)\s+(\S+)\s+(\S+)\s(\S+)\s*$/)	{
				#spidata=\epoc32\data\Z\Resource\Plugins\Obexclasscontroller.RSC Resource\Plugins\Obexclasscontroller.RSC ecom.spi \private\10003a3f\
				my $targetspi=$4.$3;
				my $flag=1;
				my $i;
				for($i=0;$i<$spicount && $flag;$i++) { #loop to see if name of spi file already added to this romimage in array
					if($spiarray[$romimage][$i]{spi} eq $targetspi) {
						$flag=0;
					}
				}
			
				if($flag) { # adds spi file if not yet listed for this romimage in array
					$spiarray[$romimage][$spicount++]={spifile=>$3, spidir=>$4, spi=>$4.$3};
					$i=$spicount;
				}
					$datafiles[$filescount++]= {data=>$1, rom=>$romimage, spifile=>$i-1}; 
                        } elsif ($spiplacement && $line =~/^\s*SPI_POSITION/i){
        			# mark the image index at which the SPI_POSITION keyword has occured in order to avoid writing duplicate
        			# entries of the spi file.
        			$spipositionflag{$romimage} = 1;
        		} elsif ($line=~/^\s*spidatahide\s*=\s*(\S+)\s+(\S+)\s(\S+)\s*$/)	{
				#spidatahide=\epoc32\data\Z\Resource\Plugins\Obexclasscontroller.RSC ecom.spi \private\10003a3f\
				my $targetspi=$3.$2;
				my $flag=1;
				my $i;
				for($i=0;$i<$spicount && $flag;$i++) { #loop to see if name of spi file already added to this romimage in array
					if($spiarray[$romimage][$i]{spi} eq $targetspi) {
						$flag=0;
					}
				}
			
				if($flag) { # adds spi file if not yet listed for this romimage in array
					$spiarray[$romimage][$spicount++]={spifile=>$2, spidir=>$3, spi=>$3.$2};
					$i=$spicount;
				}
					$hidedatafiles[$hidefilescount++]= {data=>$1, rom=>$romimage, spifile=>$i-1}; 
			}

		}
		
		for(my $i=0;$i<8 && $composite_secondary<0;$i++) { # loop to set $composite_secondary value
			if($romimage[$i]{composite} eq "composite_secondary") {
				$composite_secondary=$i;
			}
		}	
	
		for(my $i=0;$i<8;$i++) { #loop to add any spi files to composite_primary roms which are present in composite_secondary rom. spi files in secondary ROMs must be present in primary ROMS, this check rules out the possibility of the spi file in the primary rom not being created because it has no data files to add
			if($romimage[$i]{composite} eq "composite_primary") {
				my $j=0;
				while(defined $spiarray[$composite_secondary][$j]) {
					my $flag=1;
					my $k=0;
					while(defined $spiarray[$i][$k] && $flag) {
						if($spiarray[$composite_secondary][$j]{spi} eq $spiarray[$i][$k]{spi}) {
							$flag=0;
						}
						$k++;
					}
					if($flag) {
						$spiarray[$i][$k]{spifile}=$spiarray[$composite_secondary][$j]{spifile};
						$spiarray[$i][$k]{spidir}=$spiarray[$composite_secondary][$j]{spidir};
						$spiarray[$i][$k]{spi}=$spiarray[$composite_secondary][$j]{spi};
					}
					$j++;
				}
			}
		}
		
		for(my $i=0;$i<8;$i++) { #loop to add any spi files to extension roms which are present in core rom, same situation as in previous loop could potentially occur here
			if($romimage[$i]{extension}) {
				my $j=0;
				while(defined $spiarray[$i-1][$j]) {
					my $flag=1;
					my $k=0;
					while(defined $spiarray[$i][$k] && $flag) {
						if($spiarray[$i-1][$j]{spi} eq $spiarray[$i][$k]{spi}) {
							$flag=0;
						}
						$k++;
					}
					if($flag) {
						$spiarray[$i][$k]{spifile}=$spiarray[$i-1][$j]{spifile};
						$spiarray[$i][$k]{spidir}=$spiarray[$i-1][$j]{spidir};
						$spiarray[$i][$k]{spi}=$spiarray[$i-1][$j]{spi};
					}
					$j++;
				}
			}
		}
	
		for(my $i=0;$i<scalar @spiarray;$i++) { #create SPI files for ROMs which are neither composite_primary nor extensions
			if(!($romimage[$i]{extension}) && $romimage[$i]{composite} ne "composite_primary") {
				my $j=0;
				while(defined $spiarray[$i][$j]) { 
					create($i,$j++);
				}
			}
		}	
	
		for(my $i=0;$i<8;$i++) { #create SPI files for ROMs marked as composite_primary
			if($romimage[$i]{composite} eq "composite_primary") {
				my $j=0;
				while(defined $spiarray[$i][$j]) {
					create($i,$j++,$composite_secondary);
				}
			}
		}	
		for(my $i=0;$i<8;$i++) { #create SPI files for ROMs marked as extension
			if($romimage[$i]{extension}) {
				my $j=0;
				while(defined $spiarray[$i][$j]) {
					create($i,$j++,$i-1);
				}
			}
		}
			
		undef @newobydata;
		my $flag=1;
        	my $imageIdx=0;
		foreach $line (@obydata) { #add SPI files to ROM image, adds lines to obey file to specify existing locations of SPI files and target locations.

                        if($spiplacement){
                                $flag = 0;	# Reset the flag since the spi file must be added to the final OBY only on finding SPI_POSITION 
                                                        # keyword when the spiplacement flag is set. If the spiplacement flag is set but SPI_POSITION
                                                        # is not found in the oby files, then no spi entry is emitted.
                                if($line =~ /^\s*SPI_POSITION/i){
                                        next if (!$spipositionflag{$imageIdx});#This spi has already been entered into OBY.
                                        my $spiIdx=0;
                                        while(defined $spiarray[$imageIdx][$spiIdx]) {
                                                if($spiarray[$imageIdx][$spiIdx]{spifile} =~ /(.+)\.(.*)$/) {
                                                        my $targetspi="$1-$imageIdx-$spiIdx\.$2";
                                                        push @newobydata, "data=" . "\\$thisdir" . $targetspi . " \"" . $spiarray[$imageIdx][$spiIdx]{spi} . "\"\n";
                                                }
                                                $spiIdx++;
                                        }
                                        if($spiIdx == 0){
                                                # If there is no plugin in this image, the SPI_POSITION statement is ignore.
                                                print ("Warning: statement SPI_POSTION ignored as no plugin was found at ROM_IMAGE[${imageIdx}]\n");
                                        }
                                        $spipositionflag{$imageIdx} = 0;
                                }
                                elsif( $line =~ /REM ROM_IMAGE\[(\d)\]/i){
                                        $imageIdx = $1;
                                        push @newobydata, $line;
                                }
                                elsif($line =~ /^\s*spidata/i) {
                                } else {
                                        push @newobydata, $line;
                                }
                        }
			elsif($line =~/REM ROM_IMAGE\[(\d)\]/) {
				my $romimage=$1;
				if($flag) { #put in SPI files for ROM_IMAGE[0]
					$flag=0;
					my $k=0;
					while(defined $spiarray[0][$k]) {
						if($spiarray[0][$k]{spifile} =~ /(.+)\.(.*)$/) {
							my $targetspi="$1-0-$k\.$2";
							push @newobydata, "data=" . "\\$thisdir" . $targetspi . " \"" . $spiarray[0][$k]{spidir} . $targetspi .  "\"\n";
						}
						$k++;
					}
				}
				my $j=0;
				push @newobydata, "\n" . $line . "\n";			
				while(defined $spiarray[$romimage][$j]) { #put in SPI files for current ROM_IMAGE
					if($spiarray[$romimage][$j]{spifile} =~ /(.+)\.(.*)$/) {
						my $targetspi="$1-$romimage-$j\.$2";
						push @newobydata, "data=" . "\\$thisdir" . $targetspi . " \"" . $spiarray[$romimage][$j]{spidir} . $targetspi .  "\"\n";
					}
					$j++;
				}
			} elsif($line =~ /^\s*extensionrom/i) {
				if($flag) { #put in SPI files
					my $k=0;
					while(defined $spiarray[0][$k]) {
						if($spiarray[0][$k]{spifile} =~ /(.+)\.(.*)$/) {
							my $targetspi="$1-0-$k\.$2";
							push @newobydata, "data=" . "\\$thisdir" . $targetspi . " \"" . $spiarray[0][$k]{spidir} . $targetspi . "\"\n";
						}
						$k++;
					}
					$flag = 0;
				}
				push @newobydata, $line;
			} elsif($line =~ /^\s*spidata/i) {;
			} else {
				push @newobydata, $line;
			}
		}
		if($flag) { #put in SPI files for ROM_IMAGE[0] if it is the only ROM_IMAGE
			my $k=0;
			while(defined $spiarray[0][$k]) {
				if($spiarray[0][$k]{spifile} =~ /(.+)\.(.*)$/) {
					my $targetspi="$1-0-$k\.$2";
					push @newobydata, "data=" . "\\$thisdir" . $targetspi . " \"" . $spiarray[0][$k]{spidir} . $targetspi . "\"\n";
				}
				$k++;
			}
		}
		@obydata=@newobydata;
	}	
	dump_obydata("tmp6.oby", "result of SPI stage") if ($opt_v);
}

sub load_featuresutil
{
	&Load_ModuleL("featuresutil");
			
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
	if($onlysmrimage)
	{
		return;
	}
	# Set the name and Rom Image location of feature file.
	if ($enforceFeatureManager) 
	{
		# features data file location
		$dir = "private\\10205054\\";
		$featurefilename = "features.dat";
	}
	else
	{
		# feature registry configuration file location
		$dir = "private\\102744CA\\"; 
		$featurefilename = "featreg.cfg";
	}		
	if (defined ($featureXml)) 
	{
		my $featurefilecount=0;
		my $romimage=0;

		foreach $line (@obydata)
		{
			# specify which romimage following lines are part of
			if ($line=~/^\s*REM \s*ROM_IMAGE\[(\d)\]/) 
			{
				$romimage=$1;
				$featurefilecount=0;
			}
			elsif ($line =~ /^\s*REM/i)
			{
				# ignore any other REM statements
			}
			elsif($line =~ /^\s*(FEATURE)\s*(\S*)\s*(.*)/i
					|| $line =~ /^\s*(EXCLUDE_FEATURE)\s*(\S*)\s*(.*)/i)
			{				
				# FEATURE  <feature_name>  [ SF  <status falgs> ] [ UD  <user data> ]
				my $feature = $1;
				my $featurevalue = $2;
				my $featureargs = $3;
				my $reservedbit = 0;
				my %featureflags=();				
				
				# Options 'SF' and 'UD' will be supported only for "-fm" option
				if ($featuremanager) 
				{
					# [ SF  <status falgs> ] [ UD  <user data> ]
					$featureargs =~	/(\S*)\s*(\S*)\s*(\S*)\s*(\S*)\s*/ ;

					# Store the values of 'SF' and 'UD', or any invalid option, if provided					
					if ($1) 
					{	
						$featureflags{uc($1)} = $2;						
					}
					if ($3) 
					{
						$featureflags{uc($3)} = $4;									
					}

					# Generate a warning if the option provided with Feature/Exclude_Feature keyword is  
					# not 'SF' or 'UD'.
					foreach my $Key (keys %featureflags)
					{						
						if ($Key !~ /^(SF|UD)$/)
						{
							print "Warning: Invalid argument \"$Key\" specified for feature $featurevalue\n";
							delete $featureflags{$Key};
							next;
						}						
					}							
				}				
				# In verbose mode, generate warning if "SF|UD" arguments or invalid arguments are specified
				# for "-f|fr" option.
				elsif ($featureargs && $opt_v)
				{
					print "Invalid argument(s) \"$featureargs\" provided for feature \"$featurevalue\"\n";
					foreach my $Key (keys %featureflags)
					{
						delete $featureflags{$Key};
					}
				}				
				
				# The feature file name is of the format featreg.cfg[x-y] or features.dat[x-y] 
				# where x is the romimage id, y is always 0, reserved for future use.
				my $targetfeaturefile;
				if (($romimage == 0) && ($reservedbit == 0))
				{

					# Core image will not have the mangled name
				 	$targetfeaturefile = $featurefilename;
				}
				else
				{
				 	$targetfeaturefile = $featurefilename . "\[". $romimage . "\-$reservedbit\]";
				}
				my $flag=1;
				my $featureflag;
				if ($feature =~ /^FEATURE$/i)
				{
					$featureflag = 1;
				}
				else
				{
					$featureflag = 0;
				}

				my $i;
 				# loop to see if name of feature file already added to this romimage in array
				for($i=0;$i<$featurefilecount && $flag;$i++)
				{
					if($featurefilearray[$romimage][$i]{cfgfile} eq $targetfeaturefile)
					{
						$flag=0;
					}
				}
			
				if($flag) { # adds feature file if not yet listed for this romimage in array
					$featurefilearray[$romimage][$featurefilecount++]={cfgfile=>$targetfeaturefile, cfgdir=>$dir};
					$i=$featurefilecount;
				}

				$featureslist[$featurescount]= {feature=>$featurevalue, include=>$featureflag, rom=>$romimage, cfgfile=>$i-1};
				
				# Store the value of 'SF' in 'featureslist' array
				if (defined $featureflags{SF}) 
				{
					$featureslist[$featurescount]->{SF} = $featureflags{SF};						
				}
				# Store the value of 'UD' in 'featureslist' array
				if (defined $featureflags{UD}) 
				{
					$featureslist[$featurescount]->{UD} = $featureflags{UD};
				}				
				$featurescount++;
			}
		}

		# Create Feature File
		for(my $i=0;$i<scalar @featurefilearray;$i++)
		{
			my $j=0;
			while(defined $featurefilearray[$i][$j])
			{
				my $targetfeaturefile = $featurefilearray[$i][$j]{cfgfile};
				if (!(&featuresutil::createFeatureFile($i,$j,$targetfeaturefile,\@featureslist,$featuremanager))) 
				{
					$featurefilearray[$i][$j]{cfgfile}= undef;
					exit(1) if($strict);					
				}
				$j++;
			}
		}
	
		undef @newobydata;
		my $flag=1;
        	my $imageIdx=0;

		# Add feature files to ROM image, adds lines to obey file to specify existing locations
		# of feature files and target locations.
		foreach $line (@obydata)
		{
			if($line =~/REM ROM_IMAGE\[(\d)\]/i)
			{
				my $romimage=$1;
				if($flag)
				{
					# Put in feature files for ROM_IMAGE[0]
					$flag=0;
					my $k=0;
					while(defined $featurefilearray[0][$k])
					{
						my $targetfeaturefile=$featurefilearray[0][$k]{cfgfile};
						if (defined $targetfeaturefile) 
						{
							push @newobydata, "data=" . "\\$thisdir" . $targetfeaturefile . " \"" . $featurefilearray[0][$k]{cfgdir} . $targetfeaturefile .  "\"\n";							
						}
						$k++;
					}
				}
				push @newobydata, "\n" . $line . "\n";			

				my $j=0;
				while(defined $featurefilearray[$romimage][$j])
				{
					# Put in feature files for current ROM_IMAGE
					my $targetfeaturefile=$featurefilearray[$romimage][$j]{cfgfile};
					
					# Rom images will not have mangled name for feature files
				 	my $destinationfeaturefile = $featurefilename;
					
					# Rofsbuild will set attribute 'exattrib=U' in the entry record when this field is used.
					# File Server when asked for a directory listing would notice the attribute and will return the 
					# list with mangled names. Hence, mangled name for feature files should not be put in ROM_IMAGE.
					my $exattribute = "exattrib=U";

					if (defined $targetfeaturefile)
					{
						push @newobydata, "data=" . "\\$thisdir" . $targetfeaturefile . " \"" . $featurefilearray[$romimage][$j]{cfgdir} . $destinationfeaturefile .  "\"\t\t" . $exattribute . "\n";
					}
					$j++;
				}
			}
			elsif($line !~ /^\s*(FEATURE)\s*/i && $line !~ /^\s*(EXCLUDE_FEATURE)\s*/i)
			{
				# Put in all other lines except the FEATURE and EXCLUDE_FEATURE keywords
				push @newobydata, $line;
			}
		}

		if($flag)
		{ 
			# Put in feature files for ROM_IMAGE[0] if it is the only ROM_IMAGE
			my $k=0;
			while(defined $featurefilearray[0][$k])
			{
				my $targetfeaturefile = $featurefilearray[0][$k]{cfgfile};
				if (defined $targetfeaturefile)
				{
					push @newobydata, "data=" . "\\$thisdir" . $targetfeaturefile . " \"" . $featurefilearray[0][$k]{cfgdir} . $targetfeaturefile . "\"\n";
				}
				$k++;
			}
		}
		@obydata=@newobydata;
	}
	elsif ($enforceFeatureManager && $noFeatureManager && $preBuiltFeaturesDataFile)
	{
        print "Valid: $preBuiltFeaturesDataFile\n";
		if (-e $preBuiltFeaturesDataFile) 
		{			
			my @newobydata = ();
			my $flag = 1;
			foreach my $line (@obydata)
			{
				# Put in the pre-built features data file in ROM_IMAGE[0] 
				if($line =~/REM ROM_IMAGE\[1\]/i)
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
			@obydata =  @newobydata;
		}
		else
		{
			print "Error: File \"$preBuiltFeaturesDataFile\" doesn't exist.\n";
			exit(1);
		}
	}
	elsif ($enforceFeatureManager)
	{
	    print "Error: no feature data file or pre-built feature data file is provided!";
	    exit(1);
	}
}
my ($fromABI,$toABI) = split / /,$abiDowngrade;

#----------------------------------------------------------------------------------
# Problem suppression phase
#
# Downgrade files which don't exist for the ABI (if a downgrade path is specified)
# Comment out missing files or report errors if strict option enabled
#
# Detect any references to Feature Variant binaries and substitute in the
# correct source binary name using the VMAP file mechanism.

sub suppress_phase
{
	undef @newobydata;
	Plat_Init($PerlLibPath);

	# use the "default" feature variant by default.
	my $varname = $featureVariant{'VALID'} ? $featureVariant{'NAME'} : "default";

	foreach $line (@obydata)
	{
		track_source($line);
		if ($line =~ /^\s*REM/i)
		{
			# ignore REM statements, to avoid processing "REM data=xxx yyy"
		}
		# 
		# thing=some\file 
		#
		elsif ($line =~ /(\S+)\s*=\s*"?(\S+\\\S+)"?/)
		{
			my $what = $1;
			my $filename = $2;
			if ($line =~ /(\S+)\s*=\s*"([^"]+)"/)
			{
				$filename = $2;
			}
			my $normedFilename = &Genutl_NormaliseVersionedName($filename);

			# find all the alternative file locations
			my @alternatives = fallback($normedFilename);
			# test the original location first
			unshift(@alternatives, $normedFilename);

			# choose the first file location that actually exists
			my $fileExists = 0;
			foreach my $altFile (@alternatives)
			{
			    my $tmpPath;
			    my $tmpFile;
				if($altFile =~ /"?(.*\\arm\w+_?\w+)\\([^"]+)/i)
				{
					$tmpPath = $1;
					$tmpFile = $2;
				}
				$tmpPath .= "\.$varname";
				if (-d $tmpPath){
				  if (-e $tmpPath ."\\$tmpFile"){
				   $fileExists = $tmpPath . "\\$tmpFile";
				  }
				  elsif (-e $altFile){
				   $fileExists = $altFile;
				  }
				}
				else {
				  $fileExists = featurevariantmap->Find($altFile, $varname);
				}
				last if $fileExists;
			}

			# edit the OBY line to use the actual file name which we found.
			# (maybe) warn if an alternative to the original was selected.
			if ($fileExists)
			{
				my $from = $filename;
				$from =~ s/\\/\\\\/g;		# need to escape backslashes
				$from =~ s/(\[|\])/\\$1/g;	# need to escape square brackets for file names like "featreg.cfg[x-y]",etc.
				my $into = $fileExists;

 				$line =~ s/$from/$into/;

 				if ($warnSelection && ($fileExists ne $normedFilename))
				{
			    	print "replaced $filename with $fileExists\n";
				}
			}
			else
			{
   				# No suitable alternative was found, so comment out the line unless
				# it is a manatory ROMBUILD keyword, in which case it is better
				# to let ROMBUILD report the missing file rather than report the
				# missing keyword.
   				if ($what !~ /^bootbinary|variant|primary|secondary|hide/i)
				{
   					$line = "REM MISSING " . $line;
   					print_source_error("Missing file: '$filename' in statement '$what='");
					print "\ttried @alternatives\n"  if ($opt_v && @alternatives > 1);
   					# treat as an error if the strict option is selected.
   					$errors++ if ($strict);
				}
			}

			# Once the binary is located in the appropriate ABI directory (e.g.,following the binary 
			# selection order), check if the binary has been used in a patch dll statement. This is
			# required to find out the source file. In ABIv1, the source file is required to find the
			# .map file, while, in ABIv2, the destination file gives the dso file name.
			if($line =~ /(\S+)\s*=\s*(\S+)\s+(\S+)\s*(.*)?/)
			{
				my $aSrcfile = $2;
				my $dstFile = $3;
				my $dstPath = "";

				if($aSrcfile =~ /"?([^"]+)/){
				$aSrcfile = $1;
				}

				$aSrcfile = &Genutl_NormaliseVersionedName($aSrcfile);
				if($dstFile =~ /"?(.*)\\([^"]+)/)
				{
					$dstPath = $1;
					$dstFile = $2;
				}
				my $dllMapKey = lc ($dstFile);
				if(exists $DllDataMap{$dllMapKey}) {
					my $dllSymInfo = \%{$DllDataMap{$dllMapKey}};
					$dllSymInfo->{srcfile} = $aSrcfile;
					$dllSymInfo->{dstpath} = $dstPath;
				}
			}

		}
		push @newobydata, $line;
	}
	@obydata = @newobydata;
	dump_obydata("tmp7.oby", "result of problem-suppression phase") if ($opt_v);
	die "ERROR: $errors missing file(s) detected\n" if ($strict && $errors );
}

# Remove leading and trailing whitespaces from a list of strings or a single string
sub trim 
{
	my @out = @_;
	for (@out) {
		s/^\s+//;
		s/\s+$//;
	}
	return wantarray ? @out : $out[0];
}

# Generate a list of alternative locations for the given filename
sub fallback
{
   	my $file = shift;
   	my @alternatives = CheckCustomization($file);
 
 	# If BINARY_SELECTION_ORDER macro is specified in the oby file
 	if ($binarySelectionOrderFlag)
   	{
 		# Search in the specified binary order 
 		if(!defined(@Global_PlatList))
		{
			@Global_PlatList = Plat_List();
		}
 		my $b;
 		my $e;
 		foreach my $plat (@Global_PlatList) 
  		{
  			if ($file =~ /^(.*)\\$plat\\(.*)$/i) 
  			{
  				$b = $1;
  				$e = $2;
 				last;
 			}
 		}
 		push(@alternatives, "$b\\$firstDIR\\$e");
 			
 		foreach my $toDIR (@binarySelectionOrder)
   		{
 			push(@alternatives, "$b\\$toDIR\\$e");
   		}
   	}
  	
 	# If the file is not found in the specified ABIV2 platform, then select from ARMV5 directory.
 	# This is necessary as some of the runtime DLLs will be present only in ARMV5 directory. 
	# Add the BPABI Platforms to be added
	if(!defined(@Global_BPABIPlats))
	{
		@Global_BPABIPlats = &BPABIutl_Plat_List;
	}

 	foreach my $BpabiPlat (@Global_BPABIPlats)
 	{
 		if ($fromABI eq "" && $file =~ /^(.*)\\$BpabiPlat\\(.*)$/)
   		{
 			push(@alternatives, "$1\\armv5\\$2");
   		}
   	}

	if ($customizedPlat && $fromABI eq "" && $file =~ /^(.*)\\$customizedPlat\\(.*)$/)
	{
		my $b = $1;
		my $e = $2;
		# if platform customization 
		my $rootPlat = Plat_Root($customizedPlat);		
        
   		#Check in ARMV7 folder for binaries in case GCCEV7 is used [DEF128457 ]
   		if($customizedPlat == "GCCEV7")
   		{
   			push(@alternatives,"$b\\armv7\\$e");
   		}

		if( grep /$rootPlat/, @Global_BPABIPlats)
		{
 			push(@alternatives, "$b\\armv5\\$e");
		}
	}

	if ($fromABI eq "" && $file =~ /^(.*)\\ARMV5_ABIV1\\(.*)$/i)
   	{
 		push(@alternatives, "$1\\armv5\\$2");
   	}
  		
   	if ($fromABI ne "" && $file =~ /^(.*)\\$fromABI\\(.*)$/)
	{
 		push(@alternatives, "$1\\$toABI\\$2");
	}
   
   	return @alternatives;
}

# Generate a list of alternative locations for the given filename which
# result from the possible platform customizations.
sub CheckCustomization
{
 	my $file = shift;
 	my @alternatives;
	$customizedPlat = undef;	# global (used in feedback)

 	if(!defined(@Global_PlatList))
	{
		@Global_PlatList = Plat_List();
	}
 	foreach my $plat (@Global_PlatList) 
	{
 		if ($file =~ /^(.*)\\$plat\\(.*)$/i) 
		{
 			my $b = $1;
 			my $e = $2;
 			my $root = Plat_Customizes($plat);
 			if ($root) 
			{
				# Preserve the plat that is customized
				$customizedPlat = $plat;

				# If a BSF platform customizes another BSF platform (i.e. a
				# BSF hierarchy exists), look for the file starting from the
				# child BSF platform and working back to the root BSF platform
				while ($root)
				{
					push(@alternatives, "$b\\$root\\$e");

					# Temporary special case for ARMV5_ABIV1 and ARMV5_ABIV2
					if ($root =~ /^armv5_abiv[12]$/i)
					{
						push(@alternatives, "$b\\armv5\\$e");
 					}

					$root = Plat_Customizes($root);
				}
 			}
			return @alternatives;
 		}
 	}
	return @alternatives;
}		
   
#----------------------------------------------------------------------------------
# Bitmap and aif conversion phase
#
# Convert any "bitmap=" or "compressed-bitmap=" files into ROM format bitmaps
# Convert any "auto-bitmap=" to handle bitmap appropriately for xip and non-xip images
# Convert "aif=" files appropriately for xip and non-xip images
sub bitmap_aif_converison_phase
{
	my $is_xip=1;
	undef @newobydata;
	foreach $line (@obydata)
	{
		track_source($line);
		# keep track of the XIP-ness of this rom partition
		if ($line =~ /^\s*REM ROM_IMAGE\[(\d+)\]\s+(.*)$/i)
		{ $is_xip=$romimage[$1]{xip}; }
		#
		# aif=source dest 
		# include aif file - use XIP version for XIP roms if it exists, otherwise use the file specified
		#
		if ($line =~ /^\s*aif=/i)
		{
			my $xip="_xip";
			my @aif= split(/\s+/,$line);
			my $path=Path_Split('Path',"$aif[0]");
			my $base=Path_Split('Base',"$aif[0]");
			$path =~ s/^....//;
			my $ext=Path_Split('Ext',"$aif[0]");
			if ($is_xip && (-e "$path$base$xip$ext"))
			{ $line="data=$path$base$xip$ext\t\t$aif[1]\n"; }
			else
			{ $line="data=$path$base$ext\t\t$aif[1]\n"; }
		}
		#
		# auto-bitmap=
		#
		# if currently in XIP image, then use a compressed-bitmap
		# otherwise use a RAM format bitmap
		#
		if ($line =~ /^\s*auto-bitmap=/i)
		{
			if ($is_xip)
			{ $line =~ s/auto-bitmap=/compressed-bitmap=/i }
			else
			{ $line =~ s/auto-bitmap=/data=/i }
		}
		#
		# uncompressed-bitmap
		#
		# this is currently just a synonym for 'bitmap'
		$line =~ s/uncompressed-bitmap=/bitmap=/i;
	
		# 
		# bitmap=source dest 
		#
		if ($line =~ /^\s*bitmap=\s*"?(\S+)"?\s+"?(\S+)"?/i)
		{
			my $mbm = $1;
			my $dest = $2;
			my $rom_mbm = "$1_rom";
			if ($is_xip eq 0)
			{
				# non-XIP rom - just include the mbm file
				$line = "data=\"$mbm\"\t\"$dest\"\n";
			}
			else
			{	
		        if (! -e $rom_mbm || -M $rom_mbm >= -M $mbm)
			    {
				    system "bmconv /q /r $rom_mbm /m$mbm";
				    my $bmconv_status = $?;
				    die "* bmconv failed\n" if ($bmconv_status != 0 || !-f $rom_mbm);
			    }
				$line = "data=\"$rom_mbm\"\t\"$dest\"\n";
				push @tempfiles, $rom_mbm;
			}
		}
		#
		# compressed-bitmap=
		#
		# if file is a compressed ROM image file
		elsif ($line =~ /^\s*compressed-bitmap=\s*"?(\S+)"?\s+"?(\S+)"?/i)
		{
			my $mbm = $1;
			my $dest = $2;
			my $cmprssd_rom_mbm = "$1_rom";
			if ($is_xip eq 0)
			{
				# non-XIP rom - just include the mbm file
				$line = "data=\"$mbm\"\t\"$dest\"\n";
			}
			else
			{
				if (! -e $cmprssd_rom_mbm || -M $cmprssd_rom_mbm >= -M $mbm)
			    {
				    system "bmconv /q /s $cmprssd_rom_mbm /m$mbm";
				    my $bmconv_status = $?;
				    die "* bmconv failed\n" if ($bmconv_status != 0 || !-f $cmprssd_rom_mbm);
				}
				$line = "data=\"$cmprssd_rom_mbm\"\t\"$dest\"\n";
				push @tempfiles, $cmprssd_rom_mbm;			    
			}
		}
		push @newobydata, $line;
	}
	@obydata = @newobydata;
	dump_obydata("tmp8.oby", "result of bitmap conversion phase") if ($opt_v);
}


sub reformat_line($)
{
	my ($line) = @_;
	my $type = "";
	my $variant = "";
	my $pcfile = "";
	my $romfile = "";
	my $tail = "";
	
	# time=21/07/1999 12:00:00
	# primary[0x09080004]   =\epoc32\release\misa\udeb\ekern.exe
	# data=\epoc32\wins\C\System\Alarms\churchbell.snd    "System\Alarms\Church bell"
	# file[0x07060001]=\epoc32\release\MAWD\urel\cAkyb1.dll          System\Libs\EKeyb.dll
	# file=\epoc32\release\marm\urel\eikcore.dll 			System\Libs\Eikcore.dll
	# alias \System\Bin\DRTRVCT2_2.dll 			\System\Bin\DRTRVCT2_1.dll
	#
	if ($line =~ /^\s*TIME\s*=\s*/i)
	{
		return $line;
	}
  	elsif($line =~ /^\s*volume\s*=.*/i)
  	{
  		return $line;		
  	}
	elsif($line =~ /^\s*kerneltrace\s*=.*/i)
	{
		return $line;
	}
	if ($line =~ /^\s*(\S+)\s*=\s*(\S+)\s+"\\?(.*)"(.*)$/)
	{
		$type = $1;
		$variant = "";
		$pcfile = $2;
		$romfile = $3;
		$tail = $4;
	}
	elsif ($line =~ /^\s*(\S+)(\[\S+\])\s*=\s*(\S+)\s+\\?(\S+)(.*)$/)
	{
		$type = $1;
		$variant = $2;
		$pcfile = $3;
		$romfile = $4;
		$tail = $5;
	}
	elsif ($line =~ /(\S+)\s*=\s*"([^"]+)"\s+"\\?(.*)"(.*)$/)
	{
		if ($line !~ /^REM MISSING/i)
		{
			$type = $1;
			$variant = "";
			$pcfile = "\"$2\"";
			$romfile = $3;
			$tail = $4;
		}
		else{
			return $line;
		}
	}
	elsif ($line =~ /^\s*(\S+)\s*=\s*(\S+)\s+\\?(\S+)(.*)$/)
	{
		$type = $1;
		$variant = "";
		$pcfile = $2;
		$romfile = $3;
		$tail = $4;
	}
	elsif($line =~ /^\s*(patchdata)\s*(\S+)\s*\@\s*(\S+)\s+(\S+)/i)
	{
		# Reformat the patchdata statement
		my $romfilename = $2;
		my $patchdlldatamap_key = lc ($romfilename);
		my $symbolname = $3;
		my $value = $4;
		my ($index, $elementSize);		# For when the symbol is an array, and we're patching one element
		my $scalarSize;
		
		if(!defined $DllDataMap{$patchdlldatamap_key}->{dstpath}){
			print_source_error(" File $romfilename has not been included into ROM image");
			$errors++ if($strict);
			$line = "REM $line\n";
			return $line;
		}
	
		if ($enforceSysBin)
		{
			if ($DllDataMap{$patchdlldatamap_key}->{dstpath} !~ /^sys\\bin/i 
			 && $DllDataMap{$patchdlldatamap_key}->{dstpath} !~ /^sys\/bin/i)
			{
				$DllDataMap{$patchdlldatamap_key}->{dstpath} = "sys\\bin";
			}
		}
		
		my $dllfile = $DllDataMap{$patchdlldatamap_key}->{dstpath} . "\\". $romfilename;
		
		$line = "$1  ";
		$line .= "$dllfile ";
 
		# Convert value into decimal (used to be done in AddDllDataInfo, but that limited us to
		# one value per symbol, and we now support patching arrays, e.g. the Hal's InitialValue[],
		# so we can't do it that way any more.)
		if ($value =~ /^0x([0-9a-f]+)$/i) {
			$value = hex($1);
		}
		elsif ($value =~ /^(-?\d+)$/) {
			$value = $1;
		}
		else {
			print_source_error("Attempt to set $symbolname to illegal value $value");
			$errors++ if($strict);
			$line = "REM $line\n";
			return $line;
		}

		if ($symbolname =~ s/:(\d+)\[((0x)?[0-9a-f]+)\]$//i) {
			($index, $elementSize) = ($2, $1);
			$index = hex($index) if $index =~ /^0x/i;
		}

		my $DllSymInfoRef = $DllDataMap{$patchdlldatamap_key}->{$symbolname};
 
		if (!defined($DllSymInfoRef->{size})) {
			print_source_error("Size for symbol $symbolname not found");
			$errors++ if($strict);
			$line = "REM $line\n";
			return $line;
		}

		if (defined($elementSize)) {
			$scalarSize = $elementSize / 8;
			if ($scalarSize != 1 && $scalarSize != 2 && $scalarSize != 4) {
				print_source_error("Invalid bit size $elementSize for array $symbolname in $romfilename");
				$errors++ if($strict);
				$line = "REM $line\n";
				return $line;
			}
			if (($index + 1) * $scalarSize > $DllSymInfoRef->{size}) {
				print_source_error("Invalid index $index into array $symbolname in $romfilename");
				$errors++ if($strict);
				$line = "REM $line\n";
				return $line;
			}
		} else {
			$scalarSize = $DllSymInfoRef->{size};
		}

		my $max_value = 0xffffffff;

		if ($scalarSize == 1) {
			$max_value = 0xff;
		}
		elsif ($scalarSize == 2) {
			$max_value = 0xffff;
		}

		if ($value > $max_value) {
			$value &= $max_value;
			print "$DllSymInfoRef->{obyfilename}($DllSymInfoRef->{lineno}): Warning:Value overflow of $symbolname\n";
			$errors++ if($strict);
		}

		if(defined $DllSymInfoRef->{ordinal}) {
			if (defined($elementSize)) {
				my $ord = $DllSymInfoRef->{ordinal};
				my $offset = $index * $scalarSize;
				$line .= "ordinal $ord+$offset ";
			} else {
				$line .= "ordinal ";
				$line .= $DllSymInfoRef->{ordinal} . " ";
			}
		}
		elsif(defined $DllSymInfoRef->{dataAddr}) {
			if (defined($elementSize)) {
				my $addr = $DllSymInfoRef->{dataAddr};
				$addr = hex($addr) if $addr =~ /^0x/i;
				$addr = sprintf("0x%08x", $addr + $index * $scalarSize);
				$line .= "addr $addr ";
			} else {
				$line .= "addr ";
				$line .= $DllSymInfoRef->{dataAddr} . " ";
			}
		}
		else
		{
			print_source_error("Ordinal or Address for exported symbol $symbolname in $romfilename couldn't be located");
			$errors++ if($strict);
			$line = "REM $line\n";
			return $line;
		};
		
		$line .= "$scalarSize $value\n";

		return $line;
	}
	elsif ($line =~ /^\s*(\S+)\s*(\S+)\s+\\?(\S+)(.*)$/)
	{
		$type = $1;
		$variant = "";
		$pcfile = $2;
		$romfile = $3;
		$tail = $4;

		if ($type !~ /^(alias)$/i)
		{
			# Return now, if it is not an 'alias'.
			return $line;
		}
		else
		{
			# There is no substitution needed for SysBin 'alias'es.
			if ($romfile =~ /^sys\\bin\\/i
			  ||$romfile =~ /^sys\/bin/i)
			{
				return $line;
			}
		}
	}
	else
	{
		return $line;
	}
 	# Buildrom should generate warning when destination path provided for a file 
 	# is not a standard path(as per platsec) and "PlatSecEnforceSysBin" is turned off. 
 	my $warnFlag = 1;
	my $mustBeSysBin = $enforceSysBin;
	if ($type =~ /^(data|compress|nocompress)$/i
		&& $romfile !~ /^system\\(bin|libs|programs)\\/i)
	{
		$mustBeSysBin = 0;
 		$warnFlag = 0;
	}
	
	if ($mustBeSysBin)
	{
		if ($type =~ /^(alias)$/i
			&& $romfile !~ /^sys\\bin\\/i
			&& $romfile !~ /^sys\/bin/i)
		{
			# for multilinguify 'alias'es (generally resource files) 'MustBeSysBin' should not be enforced.
			if(defined($multiLinguifyAlias{$pcfile})) {
				return $line;  
			}

			my $filename = "\\$romfile";	# in case no path is specified
			$filename = substr $filename, rindex($filename, "\\");
			$romfile = "sys\\bin".$filename;

			if ($pcfile !~ /^sys\\bin\\/i
			    && $pcfile !~ /^sys\/bin/i)
			{
				my $pcfilename = "\\$pcfile";	# in case no path is specified
				$pcfilename = substr $pcfilename, rindex($pcfilename, "\\");
				$pcfile = "sys\\bin".$pcfilename;
			}
			return "$type$variant $pcfile \t$romfile$tail\n";
		}

		if ($romfile !~ /^sys\\bin\\/i
		    && $romfile !~ /^sys\/bin/i)
		{
			my $filename = "\\$romfile";	# in case no path is specified
			$filename = substr $filename, rindex($filename, "\\");
			$romfile = "sys\\bin".$filename;
		}
	}
	else
	{
 		if ($warnFlag && $romfile !~ /^sys\\bin\\/i && $romfile !~ /^sys\/bin/i)
 		{
 			print "Warning: Outside standard path at \"$line\"\n";
 		}
		if ($type =~ /^(alias)$/i)
		{
			# Return the line as it is for non-MustBeSysBin 'alias'es.
			return $line;
		}
	}
	$romfiles{$romfile} = $variant.$pcfile;
	return "$type$variant=$pcfile \t\"$romfile\"$tail\n";
}

my @hidearray;

sub mark
{ # function to mark files in ROMs as hidden
	my ($base,$ext) = @_;
	my $i=0;
	my @coreimagerange = (-1,-1); #coreimagerange stores the places within @hidearray where the $base files start and end
	my @extensionimagerange = (-1,-1); #extensionimagerange stores the places within @hidearray where the $ext files start and end
	for(my $i=0;$i<scalar @hidearray;$i++) { #loop sets values in @coreimagerange and in @extensionimagerange
		if($hidearray[$i]{rom}==$base) {
			if($coreimagerange[0]<0) {
				$coreimagerange[0]=$i;
				$coreimagerange[1]=$i;
			} else {
				$coreimagerange[1]=$i;
			}
		} elsif($hidearray[$i]{rom}==$ext) {
			if($extensionimagerange[0]<0) {
				$extensionimagerange[0]=$i;
				$extensionimagerange[1]=$i;
			} else {
				$extensionimagerange[1]=$i;
			}
		}
	}
	
	for(my $i=$extensionimagerange[0];$i<=$extensionimagerange[1];$i++) { #loop marks files which need to be hidden based on the values in @coreimagerange and in @extensionimagerange
		for(my $j=$coreimagerange[0];$j<=$coreimagerange[1];$j++) {
			if($hidearray[$i]{dest} eq $hidearray[$j]{dest}) {
				$hidearray[$i]{hide}=1;
			}
		}
	}
}


#----------------------------------------------------------------------------------
# Cleaning phase
#
# Remove "REM defined", "REM handled"
# Remove the "# lineno" information
# Collapse multiple blank lines
# Apply the PlatSecEnforceSysBin setting
# Produce ROM directory listing
# Identify the ROM image name
sub cleaning_phase
{	
	my $romname;
	my $skippingBlanks=0;
	undef @newobydata;
	
    if($opt_v)
    {
	  my $logWin = "logwin.oby";
	  my $logLinux = "loglinux.oby";
	  unlink($logWin);
	  unlink($logLinux);
	  open LOGWIN, ">$logWin" or die("* Can't create $logWin\n");
	  open LOGLINUX, ">$logLinux" or die("* Can't create $logLinux\n");
    }	

	foreach $line (@obydata)
	{
		track_source($line);
		if ($line=~/^REM (defined|handled)/)
		{
			next;
		}
		if ($line=~/^# (\d+) "(.*)"/)
		{
			next;
		}
		#
		# Blank line compression
		#
		if ($line=~/^\s*$/)
		{
			if ($skippingBlanks==1)
			{
				next;
			}
			$skippingBlanks=1;
		}
		else
		{
			$skippingBlanks=0;
		}
		#
		# Track ROMNAME, allowing overrides
		#
		if ($line=~/romname\s*=\s*"?(\S+)\.(\S+)"?\s*/i)
		{
			if ($romname ne "" && $opt_o eq "")
			{
				print_source_error("Overrides previous ROM name $romname");
			}
			$rombasename = $1;
			$romname = "$1.$2";
			next;
		}
		#
		# ROM directory listing
		#
		    my $newline = reformat_line($line);
	    if( ($newline !~ /^\s*TIME\s*=\s*/i)
  	      &&($newline !~ /^\s*volume\s*=.*/i)
	      &&($newline !~ /^\s*kerneltrace\s*=.*/i))
	    {
	        my $tmpline = $newline;
	        if($^O =~ /^MSWin32$/i)
	        {
	          $newline =~ s-\/-\\-go;
	          if($opt_v)
	          {
                print LOGWIN $newline;
	            $tmpline =~ s-\\-\/-go;
	            print LOGLINUX $tmpline;
	          }
	        }else #unix os
	        {
	          $newline =~ s-\\-\/-go;
	          if($opt_v)
	          {
	            print LOGLINUX $newline;
	            $tmpline =~ s-\/-\\-go;
	            print LOGWIN $tmpline;
	          }
	        }
	    }
	    
		push @newobydata, $newline;
	}
	if($opt_v)
	{
	  close LOGWIN;
	  close LOGLINUX;
	}
	
	exit(1) if($errors && $strict);

	# Handle ROMNAME and possible -o override
	if ($opt_o ne "")
	{
		$romname=$opt_o;
		if ($opt_o=~/(\S+)\.(\S+)/)
		{
			$rombasename=$1;
		}
		else
		{
			$rombasename=$romname;
		}
	}
	if(!$onlysmrimage)
	{
		unshift @newobydata, "romname=$romname\n";	# first line of final OBY file
	}
	@obydata = @newobydata;
	
	print "* Removing previous image and logs...\n";
	unlink glob("$rombasename.*");
	
	my $obyrecordline;
	if($createspi) {# section added to mark SPI files in core images as hidden (if appropriate) if extension ROMs are being produced
		my $imagenum=0;
		my $count=0;
		foreach my $line (@obydata) { # fill @hidearray with all file= or data= entries from @obydata, recording which image they are in and their target destination
			if($line =~/^\s*(file|data)\s*=\s*(\S+)\s+(\S+)\s*$/gi) {
				$hidearray[$count] = {rom=>$imagenum, type=>$1, dest=>$3};
				$hidearray[$count]{dest} =~s/\"//g;
				$count++;
			} elsif($line =~/^\s*REM\s+ROM_IMAGE\[(\d)\]\s*$/i ) {
				$imagenum=$1;
			}
		}
		for(my $i=0;$i<8;$i++) { #loop to mark files in @hidearray as hidden, does not add the hide= lines to the obey files
			if($romimage[$i]{extension}) {
				mark($i-1,$i);
			}
		}
		undef @newobydata;
	
		my $hideflag=0; # is set to 1 if there are files which need to be hidden, determines whether to run next section of code 
		for(my $i=0;$i<scalar @hidearray;$i++) {
			if($hidearray[$i]{hide}==1) {
				$hideflag=1;
			}
		}
	
		my $obeyrom=0;	
		if($hideflag) { #if there exist files which need hiding
			my $i=0;
			my $exitflag=0;
			$obyrecordline=0;
			for(;$obyrecordline<scalar @obydata && !$exitflag;) { # nested for loops produce new obey file in @newobydata, including hide= lines
				print "Line = $obyrecordline $i " . scalar @hidearray . "\n";
				if($i==scalar @hidearray) {
					$exitflag=1;
				}
				for(;$i<scalar @hidearray;$i++) {
					if($hidearray[$i]{hide}==1) {
						my $rom=$hidearray[$i]{rom};
						my $destination=$hidearray[$i]{dest};
						while($obeyrom<$rom && $obyrecordline<scalar @obydata) { #pushes lines to @newobydata until specified rom is reached
							push @newobydata, $obydata[$obyrecordline];
							if($obydata[$obyrecordline] =~/^\s*REM\s+ROM_IMAGE\[(\d)\]\s*$/i){
								$obeyrom=$1;
							}
							$obyrecordline++;
						}
						my $flag=1; #get to here when $obeyrom==$rom
						while($flag && $obyrecordline<scalar @obydata) {
							$destination=~s|\\|/|g;
							my $obyline=$obydata[$obyrecordline];
							$obyline=~s|\\|/|g;			
							if($obyline=~m/$destination/) { # if the line in the obeyfile matches the destination of the specified spi file then a hide= line is added before the spi file's data= line
								push @newobydata, "hide=$hidearray[$i]{dest}\n$obydata[$obyrecordline]";
								$obyrecordline++;
								$flag=0;
							} else {
								push @newobydata, $obydata[$obyrecordline++];
							}
						}
					}
				}
			}		
		}		
		while($obyrecordline< scalar @obydata) { # add the rest of the lines from @obydata to @newobydata
			push @newobydata, $obydata[$obyrecordline++];
		}
		@obydata=@newobydata;
		undef @newobydata;	
	}
	dump_obydata("tmp9.oby", "result of cleaning phase") if ($opt_v);
}


#----------------------------------------------------------------------------------
#
# Divide the oby file into multiple sections - one for each rom image - ready
# for the appropriate rom builder.
#

sub generate_romheader
{
	my ($idx) = @_;
	if ($romimage[$idx]{xip} ne 0)
	{ 
		my $header = "\n";
		if ($romimage[$idx]{extension})
		{
			$header = "extensionrom=$rombasename.$romimage[$idx]{name}.img\n";
			$header .= "romsize=$romimage[$idx]{size}\n\n";
		}
		return $header; 
	}
	# non-xip
	my $header;
	if ($romimage[$idx]{extension})
	{
		$header =  "extensionrofs=$rombasename.$romimage[$idx]{name}.img\n";
		$header .= "rofssize=$romimage[$idx]{size}\n\n";
	}
	else
	{
		$header="rofsname=$rombasename.$romimage[$idx]{name}.img\n";
		$header .= "rofssize=$romimage[$idx]{size}\n\n";
	}
	return $header;
}

#----------------------------------------------------------------------------------
# Dump OBY file.
#
# Creates final OBY file.
#
sub create_dumpfile
{
	my $romimageidx;
	my $smrimageidx = 0;
	my $dumpfile="$rombasename";
	$romimage[0]{obeyfile}=$dumpfile;
	$dumpfile .= ".oby";
	unlink($dumpfile);
	if($rombasename && !$onlysmrimage)
	{
		open DUMPFILE, ">$dumpfile" or die("* Can't create $dumpfile\n");
		print "* Writing $dumpfile - final OBY file\n";
		$romimageidx=0;
		print DUMPFILE generate_romheader($romimageidx);
	}
	foreach $line (@obydata)
	{
		if ($line =~ /^\s*REM ROM_IMAGE\[(\d+)\]\s+(.*)$/i)
		{
			$romimageidx=$1;
			if ($romimage[$romimageidx]{extension} eq '0')
			{ # next rom oby file
				close DUMPFILE;
				$dumpfile="$rombasename.$romimage[$romimageidx]{name}";
				$romimage[$romimageidx]{obeyfile}=$dumpfile;
				$dumpfile .= ".oby";
				open DUMPFILE, ">$dumpfile" or die("* Can't create $dumpfile\n");		
				print "* Writing $dumpfile - final OBY file\n";
				# header
				print DUMPFILE $line;
				print DUMPFILE generate_romheader($romimageidx);
				next;
			}
			else
			{ # extension
				# header
				print DUMPFILE $line;
				print DUMPFILE generate_romheader($romimageidx);
				next;
			}
		}
		# write data drive oby file.
		elsif ($line =~ /^\s*REM DATA_IMAGE\[(\d+)\]\s+(.*)$/i)
		{
				my $dataimageidx=$1;
				close DUMPFILE;
				$dumpfile="$datadriveimage[$dataimageidx]{name}";
				$datadriveimage[$dataimageidx]{obeyfile}=$dumpfile;
				$dumpfile .= ".oby";
				open DUMPFILE, ">$dumpfile" or die("* Can't create $dumpfile\n");		
				print "* Writing $dumpfile - intermediate OBY file\n";
				# header
				print DUMPFILE $line;
				print DUMPFILE generate_datadriveheader($dataimageidx,\@datadriveimage);
				push(@dataDriveFileList,$dumpfile);
				next;
		}
		elsif ($line =~ /^\s*REM SMR_IMAGE\s*$/i)
		{
			close DUMPFILE;
			$dumpfile = $obeyFileList[$smrimageidx];
			$smrimageidx++;
			$dumpfile .= ".oby";
			open DUMPFILE, ">$dumpfile" or die("* Can't create $dumpfile\n");
			print "*Writing $dumpfile - intermediate OBY file\n";
			print DUMPFILE $line;
			push(@smrImageFileList, $dumpfile);
			next;
		}
		print DUMPFILE $line;
	}
	close DUMPFILE;
}

#----------------------------------------------------------------------------------
#
# Full ROM directory listing - use case-insensitive sort
#
sub create_dirlisting
{
	if($rombasename)
	{
		print "* Writing $rombasename.dir - ROM directory listing\n";
		open DIRFILE, ">$rombasename.dir" or die("* Can't create ROM directory listing\n");
	
		my $file;
		my $prevdir = "";
		foreach $file (sort {uc($a) cmp uc($b)} keys %romfiles)
		{
			my $dir = substr $file,0,rindex($file, "\\");
			if (uc $dir ne uc $prevdir)
			{
				$prevdir = $dir;
				print DIRFILE "\n";
			}
	
			my @sources = split /\n/,$romfiles{$file};
			printf DIRFILE "%-40s\t%s\n", $file, shift @sources;
			while (@sources)
			{
				printf DIRFILE "%39s+\t%s\n", "", shift @sources;
			}
		}
		close DIRFILE;
	}
}

#----------------------------------------------------------------------------------
#
# Suppress Rom/Rofs/DataDrive Image creation if "-noimage" option is provided.
#

sub suppress_image_generation
{
	if($noimage) 
	{
		&tidy_exit;		
	}
}

#----------------------------------------------------------------------------------
# Execute rombuild & maksym for each final XIP OBY file
# Execute rofsbuild for each non-XIP oby file
#

sub run_rombuilder
{
	my ($command, $obeyfile, $logfile) = @_;
	$command .= " $obeyfile.oby";
	#CR1258 test cases are depending on the following output.
	print "* Executing $command\n" if ($opt_v);

	open DATA, "$command 2>&1 |"   or die "Couldn't execute command: $command";
	while ( defined( my $line = <DATA> ) ) {
	chomp($line);
	print "$line\n";
	}
	close DATA;

	if ($? != 0)
	{
		$errors++;
		$command =~ /^\s*(\S+)\s+-slog/;
		print "* $1 failed\n";
	}
	else
	{
		push(@romImages,$obeyfile.".img");
	}
	print "\n";
	rename "$logfile","$obeyfile.log" or die("* Can't rename $logfile\n");
	exit(1) if ($errors);
}

#----------------------------------------------------------------------------------
# ROMBUILD AND ROFSBUILD
#
# Invokes rombuild and rofsbuild.
# Creates .log, .symbol files.
#
sub invoke_rombuild
{
	#For CR1258, -compress command line option is introduced, and it's being handled as following
	my $rom_compression_type;
	if($opt_compression_type eq ALLSECTIONS)
	{
		$rom_compression_type = "-compress";
	}
	elsif($opt_compression_type eq PAGEDSECTION)
	{
		$rom_compression_type = "-compress=paged";
	}
	elsif($opt_compression_type eq UNPAGEDSECTION)
	{
		$rom_compression_type = "-compress=unpaged";
	}
	else
	{
		$rom_compression_type = "";
	}
	
	my $rombuild;
	if(!$geninc)
	{
		$rombuild = "rombuild -slog $rom_compression_type $logLevel $lowMem $opt_fastcompress $opt_jobs";
	}
	else
	{
		$rombuild = "rombuild -slog $rom_compression_type -geninc $logLevel $lowMem $opt_fastcompress $opt_jobs";
	}
	if($gendep)
	{
		$rombuild .= " -gendep";
	}
	my $rofsbuild = "rofsbuild -slog $logLevel $lowMem $opt_fastcompress $opt_jobs";
	foreach my $arg (keys %rombuildOptions)
	{
		$rombuild .= " $arg";
	}
	        
	for (my $romidx=0; $romidx<8; $romidx++)
	{
		my $obeyfile=$romimage[$romidx]{obeyfile};
		my $xip=$romimage[$romidx]{xip};
		my $compress=$romimage[$romidx]{compress};
		my $uncompress=$romimage[$romidx]{uncompress};
		if ($obeyfile)
		{
			if(!defined $opt_compression)
			{
				if ($compress ne 0)
				{
					$compress=" -compress";
				}
				elsif($uncompress ne 0)
				{
					$compress=" -uncompress";
				}
 				elsif($compress eq 0)
 				{
 					$compress=" ";
				}
			}
			else
			{
				$compress = $opt_compression;
				$compress =~m/\s-(compression)(method)\s(none|inflate|bytepair)/;
				print "* ".$1." ".$2.": ".$3;
			}                        
			if ($xip)
			{
				run_rombuilder($rombuild.$compress, $obeyfile, "ROMBUILD.LOG");
				if(!$nosymbols){
				print "* Writing $obeyfile.symbol - ROM symbol file\n";
				print "* Executing maksym $obeyfile.log $obeyfile.symbol\n" if ($opt_v);
				system("maksym $obeyfile.log $obeyfile.symbol >maksym.out");
				exit(1) if (!-e "$obeyfile.symbol");
				}
			}
			else
			{
				# efficient_rom_paging.pm can move everything to core rom.
				# If that is the case, don't run rofsbuild at all to avoid errors.
				use constant TRUE => 1;
				use constant FALSE => 0;
				my $run_rofs_build = FALSE;
				
				open OBYFILE, "$obeyfile.oby";
				for (<OBYFILE>)
				{
					if (is_oby_statement($_))
					{
						$run_rofs_build = TRUE;
						last;
					}
				}
				close OBYFILE;
				if ($run_rofs_build)
				{
					run_rombuilder($rofsbuild.$compress, $obeyfile, "ROFSBUILD.LOG");
					if(!$nosymbols){
					print "* Writing $obeyfile.symbol - ROFS symbol file\n";
					print "* Executing maksymrofs $obeyfile.log $obeyfile.symbol\n" if ($opt_v);
					system("maksymrofs $obeyfile.log $obeyfile.symbol >maksym.out");
					exit(1) if (!-e "$obeyfile.symbol" );
					}			
				}
			}
			unlink "rombuild.log";
			unlink "maksym.out";
		}
	}
}

#-------------------------------------------------------
# Subroutine: check if current statement is a valid oby statement
#
sub is_oby_statement
{
	my ($li) = @_;
	if ($li =~ /\s*data\s*=/) { return 1;}
	if ($li =~ /\s*file\s*=/) { return 1;}
	if ($li =~ /\s*dll\s*=/) { return 1;}
	if ($li =~ /\s*secondary\s*=/) { return 1;}

	return 0;
}

#-------------------------------------------------------
# Subroutine: convert possibly absolute path into relative path
#

sub relative_path
{
    my ($arg) = @_;
    return $arg if ($arg !~ /^\\/);	# not an absolute path
    if ($uppath eq "x")
	{
		$uppath=cwd;
		$uppath=~s-/-\\-go;		    # separator from Perl 5.005_02+ is forward slash
		$uppath=~s-^(.*[^\\])$-$1\\-o;	    # ensure path ends with a backslash
		$uppath=~s-\\([^\\]+)-\\..-og;	    # convert directories into ..
		$uppath=~s-^.:\\--o;		    # remove drive letter and leading backslash
	}
    $arg=~s-^\\--o;	# remove leading backslash from original path
    return "$uppath$arg";
}

# Returns the global @obydata reference to support external tool invocation.
sub getOBYDataRef{
	return \@obydata;
}

#Match the blank or the comment
sub isobystatement
{
	my ($l) = @_;
	if ($l !~ /=/) { 
		return 0;
	}
	return 1;
}

#Match the data statements
sub isdatastatement {
	my ($l) = @_;
	if ($l !~ /data=/) 
	{ 
		return 0;
	}
	return 1;
}

#Match the spidata statements
sub isspidatastatement {
	my ($l) = @_;
	if ($l !~ /spidata=/) { 
		return 0;
	}
	return 1;
}

#Match the executable statements
sub isexecutablefile {
	my ($l) = @_;
	if (($l=~/file=/)||($l=~/dll=/)||($l=~/primary=/)||($l=~/secondary=/)||($l=~/variant=/)||($l=~/device=/)||($l=~/extension=/)){ 
		return 1;
	}
	return 0;
}

#Match the directory metadata statements
sub isdirectorymetadata {
	my ($l) = @_;
	if (($l=~/hide=/) || ($l=~/rename=/) || ($l=~/alias=/)){ 
		return 1;
	}
	return 0;
}

#Match the bitmap statements
sub isbitmap {
	my ($l) = @_;
	if ($l=~/bitmap=/){ 
		return 1;
	}
	return 0;
}


#Match the aif file
sub isaif {
	my ($l) = @_;
	if ($l=~/(.*)\.aif/){ 
		return 1;
	}
	return 0;
}


#Match the resource file
sub isresource {
	my ($l) = @_;
	if ($l=~/(.*)\.rsc/){ 
		return 1;
	}
	return 0;
}

#Returns the executable extensions
sub executableextension {
	my ($l) = @_;
	if ($l=~/file=(.*)\.exe$/){ 
		return "exe";
	}
	elsif ($l=~/file=(.*)\.dll$/){ 
		return "dll";
	}
	elsif ($l=~/file=(.*)\.ldd$/){ 
		return "ldd";
	}
	elsif ($l=~/file=(.*)\.fsy$/){ 
		return "fsy";
	}
}


#Returns all 3 UIDS
sub executabletype {
	my ($l) = @_;
	my $uid1;
	my $uid2;
	my $uid3;
	if ($l=~/uid1\s(0x[\d]*)/){ 
		$uid1=$1;
	}
	if ($l=~/uid2\s(0x[\d]*)/){ 
		$uid2=$1;
	}
	if ($l=~/uid3\s(0x[\d]*)/){ 
		$uid3=$1;
	}
	
	return $uid1." ".$uid2." ".$uid3."\n";
}


#Return source file name
sub getSourceFile {
	my ($line) = shift;
	if ($line=~/(\w*=)(\S*\s+\S*)\s+(\S*)\s+(\S*)?/) {
		return $2;
	}
}

#Return destination file name
sub getDestFile{
	my ($line) = shift;
	if ($line=~/(\w*=)(\S*\s+\S*)\s+(\S*)\s+(\S*)?/) {
		return $3;
	}
}

#Return the obycommand attributes
sub getOBYAttributes{
	my ($line) = shift;
	if ($line=~/(\w*=)(\S*\s+\S*)\s+(\S*)\s+(\S*)?/) {
		return $4;
	}
}

#Return the hardware variant delimiter
sub getHardwareVariant{
	my ($line) = shift;
	if ($line=~/(\w*[0x[\d]*]=)/) {
		return $1;
	}
}

#Return the hardware variant delimiter
sub getObyCommand{
	my ($line) = shift;
	if ($line=~/^[data=]/) {
		return "data";
	}

	if ($line=~/^[file=]/) {
		return "file";
	}

	if ($line=~/^[dll=]/) {
		return "dll";
	}
}

# Initialize the symbol info within the given DLL.
sub AddDllDataInfo
{
	my ($line) = @_;
	# syntax "<DLLname>@<symbolname> <newvalue>"
	if($line =~ /^\s*(\S+)\s*\@\s*(\S+)\s+(\S+)\s*$/)
	{
		my $dllName = lc ($1);
		my $symbolname = $2;
		my $intVal = $3;
		my $newVal = 0;
		if($intVal =~ /^0x([0-9a-fA-F]+)$/){
		$newVal = hex($1);
		}
		elsif($intVal =~ /^(-\d+)$/ or $intVal =~ /^(\d+)$/){		
			$newVal = $1;
		}
		else{
 			print "ERROR: Invalid patchable value at \"$line\"\n";
 			$errors++ if($strict);
 			return 1;
		}
		$symbolname =~ s/:(\d+)\[(0x)?[0-9a-f]+\]$//i;	# Remove array element specification (:ELEMENT_BIT_SIZE[INDEX]) to get symbol name

		my $DllMapRef = \%{$DllDataMap{$dllName}};

		my %DllSymInfo = ();
		$DllSymInfo{ordinal}	= undef;
		$DllSymInfo{dataAddr}	= undef;
		$DllSymInfo{size}		= undef;
		# We don't store the value here, since patchdata can be used on an array,
		# in which case we'll create another one of these, and lose the value.
		# Instead, the value is retrieved by re-parsing the command line later.
		$DllSymInfo{lineno}		= $sourceline;
		$DllSymInfo{obyfilename}= $sourcefile;

		$DllMapRef->{$symbolname} = \%DllSymInfo;
		return 0;
	}
		return 1;
}

sub process_dlldata
{
	if(!$patchDataStmtFlag){
		return;
	}
	my $symbolTblEntry;

	foreach my $dll (keys %DllDataMap){
		my $DllMapRef = $DllDataMap{$dll};
		if(!$DllMapRef->{srcfile}){
		next;
		}
		my $aDllFile = $DllMapRef->{srcfile};
		my $SymbolCount = scalar ( keys %{$DllMapRef}) - 2; #The map has 'srcfile' and 'dstpath' special keys besides the symbols.

		my $DllSymMapRef;

		my @BPABIPlats = &BPABIutl_Plat_List;
		my $matchedSymbols = 0;
		my $globalSyms = 0;
		my @platlist = &Plat_List();
		my $platName;
		my $rootPlatName;
		my $plat = "ARMV5";				
		$plat = &Variant_GetMacro() ? $plat."_ABIV1" : $plat."_ABIV2";		

		foreach my $plat(@platlist) 
		{
			if(($aDllFile =~ /\\($plat)\\/i) or ($aDllFile =~ /\\($plat\.\w+)\\/i ))
			{
				$platName = $1;
				last;
			}
		}		
		$rootPlatName =	&Plat_Customizes($platName) ? &Plat_Root($platName) : $platName;
		
		# Map files will be referred for all ARM platforms, 
		# and for BSF platforms which cutomizes ARM platforms.
		if($rootPlatName =~ /^ARMV5|$plat$/i){
			my $mapfile = "${aDllFile}.map";
			
			open MAPFILE, "$mapfile" or die "Can't open $mapfile\n";
			while(<MAPFILE>){
			my $line = $_;

				#Ignore Local symbols.
				if(!$globalSyms){
					if($line =~ /Global Symbols/){
						$globalSyms = 1;
						next;
					}
					else{
						next;
					}
				}

				$symbolTblEntry = $line;
				if($symbolTblEntry =~ /\s*(\S+)(?:\s+\(EXPORTED\))?\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/){
					my $symbol		= $1;
					my $symbolValue = $2;
					my $data		= $3;
					my $symbolSz	= $4;
					if(!exists $DllMapRef->{$symbol}){
						next;
					}
					$DllSymMapRef = $DllMapRef->{$symbol};
					if($data =~ /Data/){
					# Valid
					}
					else {
					#	Invalid to patch a code symbol.
						print( "$DllSymMapRef->{obyfilename}($DllSymMapRef->{lineno}): Warning: $symbol is not a data Symbol.Ignoring patch statement.\n");
						$errors++ if($strict);
						$DllMapRef->{$symbol} = undef;
						next;
					}

					
					# Record the address and the size of the symbol.
					$DllSymMapRef->{dataAddr} = $symbolValue;
					$DllSymMapRef->{size} = $symbolSz;

					$matchedSymbols++;
					if( $matchedSymbols >= $SymbolCount){
						last;
					}
				}
			}
			close MAPFILE;
		}
		# DSO files will be referred for BPABI platforms(excluding ARM platforms),
		# and for BSF platforms which cutomizes BPABI platforms.
		else {
			my $abiDir = undef;
			foreach my $bpabi (@BPABIPlats){
				if($rootPlatName =~ /^$bpabi$/i){
					$abiDir = $platName;
					last;
				}
			}

			if(!defined $abiDir){
				print("Can't locate the map or proxy dso file for $aDllFile\n");
				$errors++ if($strict);
				next; #go to the next patch dll data statement
			}
			if( $aDllFile =~ /(.*)\.[^.]+$/ ){
				my $proxydsofile = "$1.dso";
				$proxydsofile =~ s/$abiDir\\(.*)\\/ARMV5\\LIB\\/ig;
				open PIPE, "getexports -d $proxydsofile|" or die "Can't open file $proxydsofile\n";
				while (<PIPE>){
					my $line = $_;
					if($line =~ /\s*(\S+)\s+(\d+)\s+((\S+)\s+(\d+))?/){
						my $symbol = $1;
						my $ordinal = $2;
						my $data = $3;
						my $symbolSz = $5;

						if(!$data){
							next;
						}
						if(!exists $DllMapRef->{$symbol}){
							next;
						}

						$DllSymMapRef = $DllMapRef->{$symbol};

						# Record the ordinal and the size of the symbol.
						$DllSymMapRef->{ordinal} = $ordinal;
						$DllSymMapRef->{size} = $symbolSz;
						$matchedSymbols++;
						if( $matchedSymbols >= $SymbolCount){
						last;
						}
					}
				}

				close PIPE;
			}
		}
	}
	exit(1) if ($errors && $strict ) ;
}

# make sure that all the absolute feature variant paths include a
# drive letter. This is required because cpp will not work with
# absolute paths starting with slashes.
sub addDrivesToFeatureVariantPaths
{
	return unless $featureVariant{'VALID'};

	my $current = cwd();
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
sub create_smrimage
{
	if($needSmrImage)
	{
		foreach my $oby (@obeyFileList)
		{
			my $command = "rofsbuild -slog -smr=$oby.oby";
			print "* Executing $command\n" if($opt_v);
			system($command);
			if($? != 0)
			{
				print("* ROFSBUILD failed to generate SMR IMAGE\n") if($opt_v);
			}
			else
			{
				push(@smrImageFileList, $oby.".img");
			}
		}
	}
	if(@smrImageFileList)
	{
		print "\n";
		print "-------------------------------------------------------\n";
		print "| List of file(s) generated pertaining to SMR image |\n";
		print "-------------------------------------------------------\n";
		my $arraySize = scalar(@smrImageFileList);
		for(my $i=0; $i < $arraySize; $i++)
		{
			my $element = shift(@smrImageFileList);
			my $size = -s $element;
			print "Size = ".$size." bytes"."\t"."File = ".$element."\n";
		}
	}
	foreach my $errSmr (keys(%smrNameInfo))
	{
		if($smrNameInfo{$errSmr} > 1)
		{
			print "\n SMR image: $errSmr.img creating error for duplicated names!\n";
		}
	}
	if($smrNoImageName)
	{
		print "\n SMR image creating error for empty image name!\n";
	}
}

1;
