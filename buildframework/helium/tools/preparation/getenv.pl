#============================================================================ 
#Name        : getenv.pl 
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
#Description: Cleaned version.
#============================================================================

use strict;                 # strict naming rules
use Cwd;                        # figuring out directories
use Data::Dumper;       # debugging purposes
use XML::Simple;        # for using xml parser
use File::Copy;         # for copying files
use SOAP::Lite;         # SOAP interface for s60build server
use Getopt::Long;       # parameter handling
Getopt::Long::Configure( "bundling_override","ignore_case_always" );
# uncomment to get SOAP debug traces
# use SOAP::Lite +trace => 'debug';

# variables for commandline params
my( $param_help,                    # print help
        $param_server,              # manually select server
        $param_release_path,    # where are the releases located in the server
        $param_debug,                   # parameter for controlling extra debug prints
        $param_latest,              # just grab the latest build (requires product name)
        $param_keepgoing,           # continue even if dependency is missing
        $param_print_only,      # do nothing but print system calls
        $param_skipITD,             # do not extract internal, testsources and documentation
        $param_emuenv,              # extract only emulator environment
        $param_start_directly,# starts extracting directly without waiting user acceptance
        $param_product,             # manually insert product name
        $param_skip_deps,           # do not extract dependencies
        $param_grace,                   # do not check for grace access
        $param_no_soap,             # dont use soap connection
        @param_exclude,             # exclude list
        @param_include );           # include list

# read commandline parameters
my $result = GetOptions('help'          => \$param_help,                        # print help
                                                'h'                 => \$param_help,                        # print help
                                                'latest'        => \$param_latest,                  # just grab the latest build (requires product name)
                                                'server=s'  => \$param_server,                  # manually select server
                                                'path=s'        => \$param_release_path,        # extract this release directly
                                                'verbose'       => \$param_debug,                       # verbose debug print
                                                'k'                 => \$param_keepgoing,               # continue even if there is any problems
                                                'p'                 => \$param_print_only,          # do nothing but print system calls
                                                'skipitd'       => \$param_skipITD,                 # Deprecated: do not extract internal, testsources and documentation
                                                'emu'               => \$param_emuenv,                  # Deprecated: extract only emulator environment
                                                'start'         => \$param_start_directly,  # starts extracting directly without waiting user acceptance
                                                'product=s' => \$param_product,                 # manually insert product name
                                                'x=s'               => \@param_exclude,                 # filer list for excluding zips
                                                'exclude=s' => \@param_exclude,                 # filer list for excluding zips
                                                'i=s'               => \@param_include,                 # filer list for including zips
                                                'include=s' => \@param_include,                 # filer list for including zips
                                                'nodeps'        => \$param_skip_deps,               # do not extract dependencies
                                                'grace'         => \$param_grace,                       # try to DL from GRACE
                                                'nosoap'        => \$param_no_soap );               # dont try using SOAP for s60builds server

# enums for error situations
my $warning = 1;
my $promptUser = 2;
my $dependencyMissing = 3;
my $cannotContinue = 4;

# common global variables
my $metaDataXml;                    # path to metadata file
my $currentReleaseXml;      # path to currentRelease.xml if exists
my $pathToReleaseFolder;    # path to server that has releases
my $defaultServiceName;     # default name for service (s60rnd)
my $pathToUnzip;                    # path to unzip tool
my $tmpDlDir;                           # path to temp dir where we'll DL packages to
my $tmpDir;                             # path to temp dir where we extract packages from
my $returnValue;                    # holds the error codes coming from 7-zip
my $graceServer;                    # path to local grace server if accessible
my $logFile;                            # log file for troubleshooting
my %packageHash;                    # hash containing zips to extract
my @finalZipList;                   # contains final list of files to unzip
my $getEnvVersion;              # version of this getenv script
my $soapConnection;             # holding boolean value wheter we have connection s60builds server
my $soapSessionID;              # holds the session ID received from SOAP server
my $defaultPathToServer;    # default value for the server
my $soapServiceURL = undef;

# list of GRACE samba shares - must match to @graceNameList
my @graceList = ();
# must match to @graceList
my @graceNameList = ();

#these 2 lists need to match                    
my @serviceList = ();
my @serviceNameList = ();

# default values
$tmpDir = FixPaths( getcwd )."temp";
$tmpDlDir = FixPaths( getcwd )."DlTemp";
$defaultServiceName = undef;
#$logFile = getcwd."/getenv.log";
$pathToReleaseFolder = undef;
$defaultPathToServer = undef;
$pathToUnzip = "7za";
$getEnvVersion = "2.4.0";

# first open/create log file
#open( LOGFILE, ">> $logFile" ) or handleError( "cant create log file: $!", $warning );
eval {
  open( LOGFILE, ">> getcwd.'/output/logs/getenv.log'" );
}; 
  if ($@) #if exception
  {
     open( LOGFILE, ">> getcwd.'/getenv.log'" ) ; 
  }
  
print "S60 RnD environment getter v.$getEnvVersion\n\n";
printLog( "getenv.pl version $getEnvVersion" );

# The actual functionality
if( $param_grace ) {
# ToDo: find more clever way to figure out access
    $graceServer = FindGraceServer( );
}
else {
#   print "GRACE access is temporary disabled due to access problems\nEnable GRACE access by running getenv.pl -grace\n";
}
ValidateInputs( );
printLog( "Following release we will extract: $metaDataXml" );
PrintFinalWarning( );
DownloadRelease( );
# if we have SOAP connection we should end it
if( $soapConnection ) {
    my $sessionInfo = EndSoapConnection( );
    print "\n\n".$sessionInfo->{'Info'}."\n\n" if( $sessionInfo->{'Info'} );
}

exit 0;


sub ValidateInputs {
    print_help( ) if ( $param_help );
    
    # try to get version info from s60builds SOAP server
    my $versionInfoFromServer = GetSoapVersion( ) if( !$param_no_soap );
    if( $versionInfoFromServer ) {
        # we have access to SOAP server
        printLog( "SOAP: access OK" );
        $soapConnection = 1;
        
        # lets not start soap if prompt only is defined
        $soapConnection = 0 if $param_print_only;
        
        printLog( "SOAP: latest OK version: ".$versionInfoFromServer->{'LatestOK'}->{'Version'} );
        printLog( "SOAP: latest OK date: ".$versionInfoFromServer->{'LatestOK'}->{'Date'} );
        printLog( "SOAP: latest version: ".$versionInfoFromServer->{'Latest'}->{'Version'} );
        printLog( "SOAP: latest date: ".$versionInfoFromServer->{'Latest'}->{'Date'} );
        
        # compare version nmbrs and prompt user if outdated getenv
        if( $getEnvVersion < $versionInfoFromServer->{'LatestOK'}->{'Version'} ) {
            HandleError( "Your getenv is outdated and can not be usedanymore\nPlease get newer from the server.", $cannotContinue );
        }       
    }
    else {
        printLog( "SOAP: we dont have SOAP access" );
        $soapConnection = 0;
    }

    if( @param_exclude and @param_include ) {
        HandleError( "you cant specify include and exclude lists at the same time!", $cannotContinue );
    }

    # checking wheter we are in root of the substituted drive (if -start param is not specified)
    if( ! $param_start_directly and
            !   getcwd =~ /[a-zA-Z]:\// and
                $param_keepgoing ) {
        HandleError( "You should run getenv only in root of the substituted drive\nYou can use -k as keep going parameter if you think it is ok to proceed", $cannotContinue );
    }

    # ok we are in root. Is the drive empty?
    my $xmlFile = 0;
    my $driveEmpty = 1;
    
    opendir( ROOT, "/" ) or HandleError( "cant read root dir: $!", $warning );
    my @filesFound = readdir( ROOT );
    closedir( ROOT );
    foreach my $file( @filesFound ) {
        next if $file =~ /^\.[\.]?$/;
        next if $file =~ /getenv/;
        $xmlFile = 1 if $file =~ /.*metadata.*\.xml/;
        $xmlFile = 1 if $file =~ /currentRelease\.xml/;
        $driveEmpty = 0;
    }
    
    printLog( "xml files: $xmlFile" );
    printLog( "drive empty: $driveEmpty" );

    # if drive is not empty and no xmls found ==> print warning (if -start param not specified)
    if( ! $param_start_directly and ! $xmlFile and ! $driveEmpty ) {
        HandleError( "The drive you are about to extract environment is not empty!\nHit CTRL-C to break now or <enter> to continue", $promptUser );
    }

    # if there is valid metadata.xml in root, params like path or latest doesn't make any sense
    if( $xmlFile ) {
        foreach my $file( @filesFound ) {
            if( $file =~ /.*metadata(_(\d*))?.xml$/i ) {
                print "metadata file found!\n";
                if( ValidateXmlFile( getcwd.$file ) ) {
                    $metaDataXml = getcwd.$file;
                    last;
                }
            }
        }
    }

    if( $metaDataXml ) {
        if( $param_latest or $param_release_path ) {
            print "It doesnt make sense to use 'path' or 'latest' parameter while having metadata.xml in root!\n\n";
            print_help( );
            exit 0;
        }

        # we should ask correct grace share if xmlfile !server !start       
        if( !$param_server and ! $param_start_directly ) {
            print "For your convenience it is recommended to use GRACE samba share close to you.\n";
            # prompt user wheter he wants to use GRACE
            my $networkAccessVerified = 0;
            while( $networkAccessVerified eq 0 ) {
                my $wantedServer = FixPaths( $graceList[ ReturnMenuIndex( "Please select share closest to you", @graceNameList ) ] );
        
                if( $wantedServer eq FixPaths( $graceList[0] ) ) {
                    HandleError( "Please notice that access to $graceList[0] will be removed from wk50 onwards. Now would be perfect time to get yourself a GRACE access.", $promptUser );
                }
            
                printLog( "selected: $wantedServer - accessing.." );
                if( opendir( GRACETEST, $wantedServer ) ) {
                    printLog( "connection tested OK" );
                    $networkAccessVerified = 1;
                    $pathToReleaseFolder = $wantedServer;
                }
                else {
                    print "Unable to access $wantedServer\nPlease select another network share.\n";
                }
            }
        }
        
        # in case we have metadata in \ and -start defined, look grace automatically
        elsif( !$param_server and $param_start_directly ) {
            $pathToReleaseFolder = FindGraceServer( );
        }
    }
    
    # ToDo: if there is not metadata.xml in root check if we have already env. Possibly update?
    
    # is 'path' parameter is used, find out (wheter there exists) valid metadata.xml
    if( $param_release_path ) {
        if( $param_latest or $param_product ) {
            print "It doesnt make sense to use 'path' or 'latest' parameter while having metadata.xml in root!\n\n";
            print_help( );
            exit 0;
        }
        $metaDataXml = FixPaths( $param_release_path );
        $metaDataXml .= SearchValidXml( $metaDataXml );
        printLog( "setting metadata: $metaDataXml" );
    }
    
    # handle server parameter
    # simply just verify accessablility and fix path
    if( $param_server ) {
        $pathToReleaseFolder = FixPaths( $param_server );
        opendir( OPENTEST, $pathToReleaseFolder ) or HandleError( "Unable to access given server path: $pathToReleaseFolder\n$!", $cannotContinue );
        closedir( OPENTEST );
    }
    
    # param_latest is used to just get latest release - requires product
    if( $param_latest ) {
        if( $param_product ) {
            $param_product = FixPaths( $param_product );
            
            # once the network share is unavailable then tries to find grace share
            $pathToReleaseFolder = FindGraceServer( );
            
            opendir( RELDIR, $pathToReleaseFolder.$defaultServiceName.$param_product ) or die "unable to open $pathToReleaseFolder$defaultServiceName$param_product\n$!";
            # scan all xml files to @files_found
# salmarko starts
            my @files_found = grep { /^pf_|^S60_|^dfs_/i } readdir RELDIR;
# salmarko ends
            close RELDIR;

            if( @files_found ) {
                foreach( reverse sort ( @files_found ) ) {
                    # we only want to get the last dir name..
                    s/.*\///i;
                    my $productToDl = $pathToReleaseFolder.$defaultServiceName.$param_product;
                    $productToDl .= FixPaths( $_ );
                    print "Searching metadata.xml files from $productToDl\n" if $param_debug;

                    $metaDataXml = SearchValidXml( $productToDl ) ;
                    if( $metaDataXml ) {
                        $metaDataXml = $productToDl.$metaDataXml;
                        printLog( "selected xml: $metaDataXml" );
                        last;
                    }
                }
            }
            else {
                HandleError( "cannot find releases from $pathToReleaseFolder$defaultServiceName$param_product", $cannotContinue );
            }
        }
        else {
            die "If you specify -latest parameter you have to define -product also!\n";
        }
    }
    
    # use wizard to find out what to DL
    if( ! $metaDataXml ) {
        printLog( "Not enought valid inputs provided - running wizard..." );
        RunWizard( );
    }
    
    # check wheter metadata and currentRelease adds up
    if( -e FixPaths( getcwd )."currentRelease.xml") {
        printLog( "CurrenRelease.xml exists. Checking wheter update is possible" );
        
        # compare service, product and release with xml files
        my $CurrentRelXmlParser = new XML::Simple( );
        my $currentReleaseData = $CurrentRelXmlParser->XMLin( FixPaths( getcwd )."currentRelease.xml" );
        
        my $xmlParser = new XML::Simple( );
        my $xmlData = $xmlParser->XMLin( $metaDataXml );

# salmarko starts
        my $currentRelease = '';
        my $newRelease = '';

        if ( !defined $xmlData->{releaseDetails}->{dependsOf}->{service}->{name} ) { # no dependencies, lets compare current to new
            # compare services
            if( $currentReleaseData->{releaseDetails}->{releaseID}->{service}->{name} ne
                    $xmlData->{releaseDetails}->{releaseID}->{service}->{name} ) {
                HandleError( "Can not extract ".$xmlData->{releaseDetails}->{releaseID}->{service}->{name} .
                " release on top of ".$currentReleaseData->{releaseDetails}->{releaseID}->{service}->{name}, $cannotContinue );
            }
            # compare products
            if( $currentReleaseData->{releaseDetails}->{releaseID}->{product}->{name} ne
                    $xmlData->{releaseDetails}->{releaseID}->{product}->{name} ) {
                HandleError( "Can not extract ".$xmlData->{releaseDetails}->{releaseID}->{product}->{name} .
                " release on top of ".$currentReleaseData->{releaseDetails}->{releaseID}->{product}->{name}, $cannotContinue );
            }
            printLog( "service and product matches.. checking release" );

            $currentRelease = $currentReleaseData->{releaseDetails}->{releaseID}->{release}->{name};
            $newRelease = $xmlData->{releaseDetails}->{releaseID}->{release}->{name};
        }
        else{
            # compare services
            if( $currentReleaseData->{releaseDetails}->{releaseID}->{service}->{name} ne
                    $xmlData->{releaseDetails}->{dependsOf}->{service}->{name} ) {
                HandleError( "Can not extract ".$xmlData->{releaseDetails}->{dependsOf}->{service}->{name} .
                " release on top of ".$currentReleaseData->{releaseDetails}->{releaseID}->{service}->{name}, $cannotContinue );
            }
            # compare products
            if( $currentReleaseData->{releaseDetails}->{releaseID}->{product}->{name} ne
                    $xmlData->{releaseDetails}->{dependsOf}->{product}->{name} ) {
                HandleError( "Can not extract ".$xmlData->{releaseDetails}->{dependsOf}->{product}->{name} .
                " release on top of ".$currentReleaseData->{releaseDetails}->{releaseID}->{product}->{name}, $cannotContinue );
            }
            printLog( "service and product matches.. checking release" );
            
            # compare releases
            $currentRelease = $currentReleaseData->{releaseDetails}->{releaseID}->{release}->{name};
            $newRelease = $xmlData->{releaseDetails}->{dependsOf}->{release}->{name};

            if ( $currentRelease =~ m/^(S60_\d_\d+_\d{6})/i or $currentRelease =~ m/^(pf_\d{4}_\d{6})/ ) {
                $currentRelease = $1;
            }
            else {
                HandleError( "Current release info unknown or missing: $currentRelease", $cannotContinue );
            }

            if ( $newRelease =~ m/^(S60_\d_\d+_\d{6})/i or $newRelease =~ m/^(pf_\d{4}_\d{6})/ ) {
                $newRelease = $1;
            }
            else {
                HandleError( "New release info unknown or missing: $newRelease", $cannotContinue );
            }
        }

        printLog( "current release: $currentRelease" );
        printLog( "release to extract: $newRelease" );
# salmarko ends

        if( $currentRelease ne $newRelease ) {
            HandleError( "Can not extract $newRelease release on top of $currentRelease", $cannotContinue );
        }
        printLog( "release matches - update possible" );
        
        $currentRelease = FixPaths( getcwd )."currentRelease.xml";
    }
}


# Make sure paths are as perl likes 'em
# change '\' ==> '/' and make sure last char is /
sub FixPaths {
    my $tmpParam = shift;
    $tmpParam =~ s/\\/\//g;
    
    if( substr( $tmpParam, -1 ) eq "/" ) {
        return $tmpParam;
    }
    else {
        return $tmpParam."/";
    }
}

# smarter handling of logging
sub printLog {
    foreach my $trace ( @_ ) {
        if( $param_debug ) {
            # we should print traces for STDOUT as well
            my ($sec,$min,$hr) = localtime();
        printf( "%02d:%02d:%02d: ", $hr, $min, $sec );
            print $trace."\n";
        }
    
        # we should print traces for log file
        my ($sec,$min,$hr) = localtime();
      printf LOGFILE ( "%02d:%02d:%02d: ", $hr, $min, $sec );
        print LOGFILE $trace."\n";
    }
}

sub HandleError {
    my( $errorString, $errorType ) = @_;
    printLog( "HandleError: $errorString, type: $errorType" );
    
    if( $errorType eq $warning ) {
        print "\nWARNING: $errorString\n";
    }
    if( $errorType eq $promptUser ) {
        print "\nWARNING: $errorString\n\n";
        print "Press <enter> to continue..\n" if( ! $param_start_directly );
        my $selection = <STDIN> if( ! $param_start_directly );
    }
    elsif( $errorType eq $dependencyMissing ) {
        if( $param_keepgoing ) {
            print "\nERROR: Required dependency missing: $errorString\n\n";
        }
        else {
            die "ERROR: all the needed dependencies doesn't exist!\n$errorString\nIf you think it is ok to ignore this error you can use -k as keep-going parameter\nYou should report this to administrator of the server\n\ngetenv will now exit\n\n";
        }
    }
    elsif( $errorType eq $cannotContinue ) {
        if( $param_keepgoing ) {
            print "\nWARNING: $errorString\n\n";
        }
        else {
            die "\nERROR:\n============\n$errorString\ngetenv will now exit\nIf you think it is ok to ignore this error you can use -k as keep going parameter\n\n";
        }
    }
}

# checks wheter the xml file seems sane (has service, product and name set)
sub ValidateXmlFile {
    my $xmlFile = shift( @_ );
    printLog( "Validating $xmlFile" );

    # open the xml file and check wheter it is something we want
    my $dependencyXmlParser = new XML::Simple( );
    my $dependencyData = $dependencyXmlParser->XMLin( $xmlFile );
    
    # if releaseDetails->releaseID->service&product&release are found consider this as valid file
    if( $dependencyData->{releaseDetails}->{releaseID}->{service}->{name} and
            $dependencyData->{releaseDetails}->{releaseID}->{product}->{name} and
            $dependencyData->{releaseDetails}->{releaseID}->{release}->{name} ) {
        # return xml file with path
        printLog( "xml file OK" );
        return 1;
    }
    else {
        printLog( "xml file doesn't seem to be sane!" );
        return 0;
    }
}

sub print_help {
    print "
usage
=====
getenv.pl [params]
  getenv.pl             use no parameters to run small wizard
  getenv.pl -h(elp)     print help
  getenv.pl -k          keep going even when errors occurs
  getenv.pl -p          do nothing, but print system calls
  getenv.pl -emu        DEPRECATED - prefer filtering: get only emulator environment
  getenv.pl -start      starts extracting without user confirmation (nice for scripts)
  getenv.pl -nodeps     do not download dependencies for the release
  getenv.pl -nosoap     dont try to use SOAP connection for s60builds server
  getenv.pl -skipitd    DEPRECATED - prefer filtering: skips useless doc, internal, tsrc zips
  getenv.pl -verbose    print debug traces
  getenv.pl -Include    include only some types of packages (emu, src, tsrc)
  getenv.pl -eXclude    exclude some types of packages (emu, src, tsrc)

examples
========
  get latest PRODUCT release:
      getenv.pl -latest -product PRODUCT
  get s60 release from server \\\\SERVER\\LOCATION:
      getenv.pl -server \\\\SERVER\\LOCATION
  get s60 release located in \\\\SERVER\\LOCATION\\BUILDS\\PRODUCT\\RELEASE:
      getenv.pl -path \\\\SERVER\\LOCATION\\BUILDS\\PRODUCT\\RELEASE
  get s60 release pointed with -path and print verbose messages:
      getenv.pl -path \\\\SERVER\\LOCATION\\BUILDS\\PRODUCT\\RELEASE -verbose

Filtering
=========
  You can include or exclude certain types of packages to unzip.
  For example you can unzip only emulator binaries with -include emu (or -i emu)
  Or if you don't want test sources and documents use -exclude tsrc (or -x tsrc)
  Possible filters are emu, src, tsrc and we can put plenty more into metadata.xml if needed
  To get latest PRODUCT emulator environment use
      getenv.pl -latest -product PRODUCT -i emu
  To get only custom build without winscw binaries use
      getenv.pl -path \\\\SERVER\\LOCATION\\BUILDS\\PRODUCT\\RELEASE -x emu
";
    exit 0;
}

    
    
    
    
# returns file name of correct xml file in given directory
sub SearchValidXml {
    my $searchDir = shift @_;
    printLog( "finding valid xml files from: $searchDir" );

    # validate xml files from selected directory
    opendir( XMLDIR, $searchDir ) or die "can't open $searchDir: $!";
    # scan all xml files to @xmlFiles
    my @xmlFiles = grep /\.xml$/, readdir XMLDIR;
    close XMLDIR;
#   print Dumper( @xmlFiles );

    # sort files in ascenting order (so latest comes first: _001
    @xmlFiles = sort {$b cmp $a} (@xmlFiles);

    foreach my $xmlCandidate ( @xmlFiles ) {
        printLog( "xmlfile: $xmlCandidate" );
        # open the xml file and check wheter it is something we want
        my $xmlParser = new XML::Simple( );
        my $releaseData = $xmlParser->XMLin( $searchDir."/".$xmlCandidate );
        
        # if releaseDetails->releaseID->service&product&release are found consider this as valid file
        if( $releaseData->{releaseDetails}->{releaseID}->{service}->{name} and
                $releaseData->{releaseDetails}->{releaseID}->{product}->{name} and
                $releaseData->{releaseDetails}->{releaseID}->{release}->{name} ) {
            # return xml file with path
            return $xmlCandidate;
        }
    }
    
    # in case we came until here the xml file is not found
    HandleError( "Valid release_metadata.xml file was not found from $searchDir", $cannotContinue );
}

sub RunWizard {
    print "Server is heavily loaded and therefore also download times might be drawn out.\nFor your convenience it is recommended to use samba share close to you.\n";
# salmarko starts
    if( !$param_server ) {
# salmarko ends
        # prompt user wheter he wants to use GRACE
        my $wantedServer;
        my $networkAccessVerified = 0;
        while( $networkAccessVerified eq 0 ) {
            $wantedServer = FixPaths( $graceList[ ReturnMenuIndex( "Please select share closest to you", @graceNameList ) ] );
            
            if( $wantedServer eq FixPaths( $graceList[0] ) ) {
                HandleError( "Please notice that access to $graceList[0] will be removed from wk50 onwards. Now would be perfect time to get yourself GRACE access.", $promptUser );
            }
        
            printLog( "selected: $wantedServer - accessing.." );
            if( opendir( GRACETEST, $wantedServer ) ) {
                printLog( "connection tested OK" );
                $networkAccessVerified = 1;
                $pathToReleaseFolder = $wantedServer;
            }
            else {
                print "Unable to access $wantedServer\nPlease select another network share.\n";
            }
        }
        my $wantedService = $serviceList[ ReturnMenuIndex( "Please select GRACE Service.", @serviceNameList)];
        printLog( "selected: $wantedServer.$wantedService - accessing.." );
        local *GRACETEST2;
        if( opendir( GRACETEST2, $wantedServer.$wantedService ) ) {
            printLog( "serviceconnection tested OK" );
            $defaultServiceName = $wantedService
            }
            else {
            print "Unable to access $wantedServer.$wantedService\nPlease select another network share or service.\n";
            }
    }

    # find & select correct product from the server
    my @productFiles = FindAvailableProducts( );
    if( ! @productFiles ) {
        HandleError( "Server seem to be empty!\nPlease check the server path: $pathToReleaseFolder$defaultServiceName\n$!", $cannotContinue );
    }
    my $product = PrintSelectMenu( "Products found from server", @productFiles );
    $product = FixPaths( $product );
    printLog( "selected product: $product" );
    
    # find & select correct release from above selected path
    my @releaseFiles = FindAvailableReleases( $product );
    if( ! @releaseFiles ) {
        HandleError( "Cant find any releases from: $pathToReleaseFolder$defaultServiceName.$product\n$!", $cannotContinue );
    }
    my $release = PrintSelectMenu( "Releases found from server", @releaseFiles );
    $release = FixPaths( $release );
    printLog( "selected release: $release" );
    
    # select correct xml file from selected release
    $metaDataXml = SearchValidXml( $pathToReleaseFolder.$defaultServiceName.$product.$release );
    $metaDataXml = $pathToReleaseFolder.$defaultServiceName.$product.$release.$metaDataXml;
    printLog( "selected metadata: $metaDataXml" );
}

# check what products is there under servers release path
sub FindAvailableProducts {
    opendir( DIR, $pathToReleaseFolder.$defaultServiceName )
        or HandleError( "Can't open directory: $pathToReleaseFolder$defaultServiceName\n$!", $cannotContinue );
#change to match only for directories
#   my @productFiles = grep { /s(eries_)?60_\d_\d/i } readdir (DIR);
# salmarko starts
    my @productFiles = grep /^pf_|^S60_|^DFS/i, readdir (DIR);
# salmarko ends
    printLog( @productFiles );
    closedir( DIR );
    
    # return found releases sorted
    return sort( @productFiles );
}

# print selection menus
sub PrintSelectMenu {
    my( $topic, @inputArray ) = @_;
    
    # print topic line
    print "\n\n$topic:\n";
    for( my $i = length( $topic ); $i>=0; $i-- ) {
        print "=";
    }
    print "\n";
    
    # print actual selections
    my $counter = 0;
    foreach my $line( @inputArray ) {
        $counter ++;
        print "$counter:\t$line\n";
    }

    print "\n\nx:\texit\n";
    print "\nselection: ";
    my $selection = <STDIN>;
    chop( $selection );
    
    exit 1 if( $selection eq 'x' );
    
    # check user input
    while( ! $selection =~ /\d*/ and
                    $selection > $counter )
        {
            if( $selection =~ /\d*/ ) {
                print "Invalid selection. Please check value from the list above\n";
            }
            else {
                print "Please insert numerical value from the list\n";
            }
            print "\nselection: ";
            $selection = <STDIN>;
            chop( $selection );
            
            exit 1 if( $selection eq 'x' );
        }

    # return array index
    $selection--;
    return( $inputArray[$selection] );
}

# print selection menus
sub ReturnMenuIndex {
    my( $topic, @inputArray ) = @_;
    
    # print topic line
    print "\n\n$topic:\n";
    for( my $i = length( $topic ); $i>=0; $i-- ) {
        print "=";
    }
    print "\n";
    
    # print actual selections
    my $counter = 0;
    foreach my $line( @inputArray ) {
        $counter ++;
        print "$counter:\t$line\n";
    }

    print "\n\nx:\texit\n";
    print "\nselection: ";
    my $selection = <STDIN>;
    chop( $selection );
    
    exit 1 if( $selection eq 'x' );
    
    # check user input
    while( ! $selection =~ /\d*/ and
                    $selection > $counter )
        {
            if( $selection =~ /\d*/ ) {
                print "Invalid selection. Please check value from the list above\n";
            }
            else {
                print "Please insert numerical value from the list\n";
            }
            print "\nselection: ";
            $selection = <STDIN>;
            chop( $selection );
            
            exit 1 if( $selection eq 'x' );
        }

    # return array index
    $selection--;
    return $selection;
}

# check what releases are there under selected product
sub FindAvailableReleases {
    my $selectedProduct = shift( @_ );
    printLog( "searching available releases from $selectedProduct" );
#   print $serverPath.$selectedProduct."\n";
    opendir( DIR, $pathToReleaseFolder.$defaultServiceName .$selectedProduct ) or die "Can't open dir: $!\n";
#   my @releaseFiles = grep { /S60_\d_\d.*/ } readdir (DIR);
# salmarko starts
    my @releaseFiles = grep /^pf_|^S60/i, readdir (DIR);
# salmarko ends
#   print Dumper( @releaseFiles );
    closedir (DIR);
#TODO: maybe we should also check wheter xml files exists in release
    return sort {$b cmp $a} ( @releaseFiles );
}

# maybe we should print warning only 
sub PrintFinalWarning {
    if( ! $param_start_directly ) {
        # we'll print warnings only if extracting on top of something else (aka not empty dir)
#       print "About to start extracting\n$metaDataXml";
#       print "\nHit ctrl-C now to abort, otherwise press enter to continue\n\n";
#       my $selection = <STDIN>;
        print scalar(localtime). ": start fetching environment\n";
    }
}

# handles controlled downloading of the environment pointed by $metaDataXml
sub DownloadRelease {
    # open wanted metadata.xml file
    my $xmlParser = new XML::Simple( );
    my $data = $xmlParser->XMLin( $metaDataXml );
    
    # parse download directory based on given arguments and xml file to $releaseLocationInServer
    my $releaseLocationInServer;
    if( ! $param_release_path ) {
        $releaseLocationInServer = ParseDownloadDir( $data );
    }
    else {
        $releaseLocationInServer = $param_release_path;
    }
    
    # read files from the xml to %packageHash
    GeneratePackageHash( $data, $releaseLocationInServer );
    printLog( "package hash generated" );
    
    # insert needed files to @finalZipList
    SortFilesToFinalLists( );
    printLog( "files sorted to final zip list" );
    
    # check if there is dependencies we need to extract as well
    if( ! $param_skip_deps and
            $data->{releaseDetails}->{dependsOf}->{service} ) {
        # read from xml where can we get dependeny
        my $dependsOfService = $data->{releaseDetails}->{dependsOf}->{service}->{name};
        my $dependsOfProduct = $data->{releaseDetails}->{dependsOf}->{product}->{name};
        my $dependsOfRelease = $data->{releaseDetails}->{dependsOf}->{release}->{name};
    
        printLog( "First dl: $dependsOfService $dependsOfProduct $dependsOfRelease" );
        
        # add dependency files to finalLists
        AddDependencies( $dependsOfService, $dependsOfProduct, $dependsOfRelease );
    }
    
    # we should check wheter there already exists old build (currentRelease.xml) and reduct the files
    if( -e FixPaths( getcwd )."currentRelease.xml" ) {
        # reduct old DL'd files (currentrelease.xml and it's dependencies)
        # passing param '1' as for printing
        RemoveThisXmlFromFinalList( FixPaths( getcwd )."currentRelease.xml", 1 );
    }
    if( VerifyFinalZipList( ) or $param_keepgoing ) {
        # start SOAP session
        if( $soapConnection ) {
            my $soapSessionInfo = StartSoapSession( );
            printLog( "SOAP: note ".$soapSessionInfo->{'HelloNote'} );
            printLog( "SOAP: sessionid ".$soapSessionInfo->{'SessionID'} );
            
            print "\n".$soapSessionInfo->{'HelloNote'}."\n\n" if( $soapSessionInfo->{'HelloNote'} );
            $soapSessionID = $soapSessionInfo->{'SessionID'};
            printLog( "SOAP: soapSessionID set: $soapSessionID" );
        }
        
        # extract the environment
        GetEnv( );
    }
}

# return download directory from the metadata.xml
sub ParseDownloadDir {
    my $data = shift( @_ );
    my $releaseLocationInServer;
    
    # parse dl directory into $releaseDirectory
    $releaseLocationInServer = $data->{releaseDetails}->{releaseID}->{service}->{name} . "/";
    $releaseLocationInServer .= $data->{releaseDetails}->{releaseID}->{product}->{name} ."/";
    $releaseLocationInServer .= $data->{releaseDetails}->{releaseID}->{release}->{name} ."/";
    local *DEPTEST;
    
    # check if we can find this release from GRACE
    if( $graceServer ) {
        if( -e $graceServer.$releaseLocationInServer."grace.txt" ) {
            printLog( "dl dir: $graceServer$releaseLocationInServer" );
            return $graceServer.$releaseLocationInServer;
        }
        else {
            printLog( "dl dir: $pathToReleaseFolder$releaseLocationInServer" );
            return $pathToReleaseFolder.$releaseLocationInServer;
        }
    }
    else {
        # while call to remove dependency xmls is recursive, we dont know actual DL path

        if( opendir( DEPTEST, $pathToReleaseFolder.$releaseLocationInServer ) ) {
            return $pathToReleaseFolder.$releaseLocationInServer;
        }
        else {
            return $defaultPathToServer.$releaseLocationInServer;
        }
    }
}

# generates %packageHash that contains data about needed files
# param: xml data handle
sub GeneratePackageHash {
    my( $xmlDataHandle, $releaseInServer )  = @_;
    my $finalState = 0;
    printLog( "parse filenames to extract to packageHah" );
    no strict 'refs';
        
# Incase if we have only one package in the release to extract, then in the case
# the Xml::Simple::XMLin is not creating keys inside $xmlDataHandle->{releaseFiles}->{package}
# with package names. So to address it, the below part of code is done..
####
    if(exists $xmlDataHandle->{releaseFiles}->{package}->{name}){
        my $pkgName = $xmlDataHandle->{releaseFiles}->{package}->{name};
        my $tmphash = $xmlDataHandle->{releaseFiles}->{package};
        delete $tmphash->{name} ;
        delete $xmlDataHandle->{releaseFiles}->{package};
        $xmlDataHandle->{releaseFiles}->{package}->{$pkgName} = $tmphash;
    }
#####

    # generate new hash of zips to DL for %packageHash
    # foreach my $key( sort { $xmlDataHandle{a}->{'state'} <=> $xmlDataHandle{b}->{'state'} } %{$xmlDataHandle->{releaseFiles}->{'package'} } ){
    foreach my $key( keys(%{$xmlDataHandle->{releaseFiles}->{package} } ) ) {
        printLog( "adding $key to packageHash" );
        ${packageHash}{$key}{path} = FixPaths( $releaseInServer );
        ${packageHash}{$key}{type} = $xmlDataHandle->{releaseFiles}->{package}->{$key}->{'type'};
        ${packageHash}{$key}{state} = $xmlDataHandle->{releaseFiles}->{package}->{$key}->{'state'};
        ${packageHash}{$key}{extract} = $xmlDataHandle->{releaseFiles}->{package}->{$key}->{'extract'};
        ${packageHash}{$key}{default} = $xmlDataHandle->{releaseFiles}->{package}->{$key}->{'default'};
        
        # added 31.7.2007 : check filters -attribute
        if ($xmlDataHandle->{releaseFiles}->{package}->{$key}->{'filters'}){
            ${packageHash}{$key}{s60filter} = $xmlDataHandle->{releaseFiles}->{package}->{$key}->{'filters'};
        }
        elsif ($xmlDataHandle->{releaseFiles}->{package}->{$key}->{'s60filter'}) {;
            ${packageHash}{$key}{s60filter} = $xmlDataHandle->{releaseFiles}->{package}->{$key}->{'s60filter'};
        }   

        # find out what is the latest state
        if( $finalState < $xmlDataHandle->{releaseFiles}->{package}->{$key}->{'state'} ) {
            $finalState = $xmlDataHandle->{releaseFiles}->{package}->{$key}->{'state'};
        }
    }
    
    # we should check wheter this xml has servicepacks
    my $spName = $xmlDataHandle->{servicePacks}->{servicePack}->{name};
    # always increase final state
    $finalState ++;
    if( $spName ) {
        printLog( "spname: $spName" );
        $finalState ++;
        my $spFileName = $xmlDataHandle->{servicePacks}->{servicePack}->{file}->{name};
        # if we get spFileName we should extract SP zip
        if( $spFileName ) {
            printLog( "spFileName: $spFileName" );
            ${packageHash}{$spFileName}{path} = FixPaths( $releaseInServer );
            ${packageHash}{$spFileName}{type} = "zip";
            ${packageHash}{$spFileName}{state} = $finalState;
            ${packageHash}{$spFileName}{extract} = "single";
            ${packageHash}{$spFileName}{default} = "true";
            $finalState ++;
        }
        # if there is servicePack->instructions we should read specianInstructions file
        my $specialInstructions = $xmlDataHandle->{servicePacks}->{servicePack}->{instructions};
        if( $specialInstructions ) {
            printLog( "read special instructions" );
        }
    }
    # this is needed due to SymSEE's obsolete xml library
    # in case there is > 1 SP's in one XML file
    else {
        foreach( keys(%{$xmlDataHandle->{servicePacks}->{servicePack} } ) ) {
#       foreach my $tmparray( $xmlDataHandle->{servicePacks}->{servicePack} ) {
            printLog( "spname: $_" );
            my $spFileName = $xmlDataHandle->{servicePacks}->{servicePack}->{$_}->{file}->{name};
            printLog( "spFileName: $spFileName" );
            ${packageHash}{$spFileName}{path} = FixPaths( $releaseInServer );
            ${packageHash}{$spFileName}{type} = "zip";
            ${packageHash}{$spFileName}{state} = $finalState;
            ${packageHash}{$spFileName}{extract} = "single";
            ${packageHash}{$spFileName}{default} = "true";
            $finalState ++;
        }
    }
}

# inserts files on beginning of @finalZipList so they are readable in correct order when extracting (dependencies first)
sub SortFilesToFinalLists {
    foreach my $zips( sort { $packageHash{$b}->{'state'} <=> $packageHash{$a}->{'state'} } keys %packageHash ) {
        if( $packageHash{$zips}->{'default'} eq 'true' ) {
            my $tmpHash = $packageHash{$zips};
            $tmpHash->{'filename'} = $zips;
            unshift @finalZipList, $tmpHash;
        }
    }
    %packageHash = 0;
}

sub AddDependencies {
    # parameters contains info which release needs to be DL'd first
    my( $dependsOfService, $dependsOfProduct, $dependsOfRelease ) = @_;
    my $dependsOf = $dependsOfService ."/". $dependsOfProduct ."/". $dependsOfRelease ."/";
    
    # if we are here, dependecies really exists..
#   print "the package has dependency: $dependsOf\n";
#   print "so calling self with $serverPath and $dependsOf\n";

    # first we'll have to find correct xml file
    my $xmlPath;
    # if we are DL'ing from custom path ==> first check relative path
    if( $param_release_path ) {
        # best guess is $param_release_path\..\..\..\$dependsOf even though it is not very common situation
        my $dependencyPath = FixPaths( $param_release_path ) . "../../../" . FixPaths( $dependsOf );
        if( -e $dependencyPath."release_metadata.xml" ) {
            printLog( $dependencyPath ."release_metadata.xml exists - setting dependencyPath accordingly" );
            $xmlPath = $dependencyPath;
        }
        # in case it is not in relative path we should try finding it from release server
        elsif( -e $pathToReleaseFolder.$dependsOf."release_metadata.xml" ) {
            printLog( $dependencyPath ."release_metadata.xml not not exist - setting dependencyPath accordingly" );
            $xmlPath = $pathToReleaseFolder.$dependsOf;
        }
    }
    # param_release_path not defined
    else {
        $xmlPath = $pathToReleaseFolder.$dependsOf;
    }
    printLog( "xmlpath: $xmlPath" );
    
    if (!-e $xmlPath && $param_keepgoing) {return;}
    
    my $dependecyXml = SearchValidXml( $xmlPath );
    printLog( "xml candidate: $dependecyXml" );
    # open the xml file and check wheter it is the one we want
    my $dependencyXmlParser = new XML::Simple( );
    my $dependencyData = $dependencyXmlParser->XMLin( $xmlPath.$dependecyXml );
    
    # read releaseDetails from xml candidate
    my $tmpServiceName = $dependencyData->{releaseDetails}->{releaseID}->{service}->{name};
    my $tmpProductName = $dependencyData->{releaseDetails}->{releaseID}->{product}->{name};
    my $tmpReleaseName = $dependencyData->{releaseDetails}->{releaseID}->{release}->{name};
    
    
    printLog( "tmpServiceName:   $tmpServiceName tmpProductName:   $tmpProductName tmpReleaseName:   $tmpReleaseName" );
    printLog( "dependsOfService: $dependsOfService dependsOfProduct: $dependsOfProduct dependsOfRelease: $dependsOfRelease" );
    
    # compare xml candidate's data to dependency data
    if( $tmpServiceName eq $dependsOfService and
            $tmpProductName eq $dependsOfProduct and
            $tmpReleaseName eq $dependsOfRelease ) {
        printLog( "MATCH!" );
        
        my $dependencyLocationInServer;
        
        if(! $param_release_path ) {
            $dependencyLocationInServer = ParseDownloadDir( $dependencyData );
        }
        else {
            $dependencyLocationInServer = $xmlPath;
        }
        printLog( "So calling downloadRelease with serverpath: $dependencyLocationInServer, metadatafile: $dependsOf$dependecyXml" );
        
        # read files from dependency xml to %packageHash
        GeneratePackageHash( $dependencyData, $dependencyLocationInServer );
        printLog( "dependency package hash generated" );
    
        # insert needed files to @finalZipList
        SortFilesToFinalLists( );
        printLog( "dependency files sorted to final zip list" );
        
        # check if there is still dependencies we need to extract
        if( $dependencyData->{releaseDetails}->{dependsOf}->{service} ) {
            # read from xml where can we get dependeny
            my $dependsOfService = $dependencyData->{releaseDetails}->{dependsOf}->{service}->{name};
            my $dependsOfProduct = $dependencyData->{releaseDetails}->{dependsOf}->{product}->{name};
            my $dependsOfRelease = $dependencyData->{releaseDetails}->{dependsOf}->{release}->{name};
        
            printLog( "First dl: $dependsOfService $dependsOfProduct $dependsOfRelease" );
            
            # add dependency files to finalLists
            AddDependencies( $dependsOfService, $dependsOfProduct, $dependsOfRelease );
        }
    }
    else {
        HandleError( "Dependency release $xmlPath.$dependecyXml doesnt seem to match with actual downloadable", $cannotContinue );
    }
}

sub RemoveThisXmlFromFinalList {
    my( $xmlFileName, $printRemoving ) = @_;
    
    printLog( "Removing contents of $xmlFileName from finalziplist" );
    
    my $currentReleaseXmlParser = new XML::Simple( );
    my $currentReleaseXmlHandle = $currentReleaseXmlParser->XMLin( $xmlFileName );
    if( $printRemoving ) {
        print $currentReleaseXmlHandle->{releaseDetails}->{releaseID}->{release}->{name};
        print " exists already => extracting only delta\n\n";
    }
    
    # generate packageHash for old release
    my $location = ParseDownloadDir( $currentReleaseXmlHandle );
    GeneratePackageHash( $currentReleaseXmlHandle, $location );
    
    # remove files from @finalZipList
    ReductFilesFromFinalLists( );
    
    # remove already DL'd dependency zips
    if( $currentReleaseXmlHandle->{releaseDetails}->{dependsOf}->{service} ) {
        printLog( "already DL'd dependency needs to be removed as well:" );
        
        my $xmlToRemove;
        
        # parse $dependsOf from xml
        my $dependsOfServiceToRemove = FixPaths( $currentReleaseXmlHandle->{releaseDetails}->{dependsOf}->{service}->{name} );
        my $dependsOfProductToRemove = FixPaths( $currentReleaseXmlHandle->{releaseDetails}->{dependsOf}->{product}->{name} );
        my $dependsOfReleaseToRemove = FixPaths( $currentReleaseXmlHandle->{releaseDetails}->{dependsOf}->{release}->{name} );
        
        my $dependsOf = $dependsOfServiceToRemove.$dependsOfProductToRemove.$dependsOfReleaseToRemove;
        local *TMPTEST;
        
        # find out where the release came from
        if( $param_release_path ) {
            # best guess is $param_release_path\..\..\..\$dependsOf even though it is not very common situation
            my $dependencyPath = FixPaths( $param_release_path ) . "../../../" . FixPaths( $dependsOf );
            if( -e $dependencyPath."release_metadata.xml" ) {
                printLog( $dependencyPath ."release_metadata.xml exists - setting pathTo ReleaseFolder accordingly" );
                $xmlToRemove = $dependencyPath;
            }
            # in case it is not in relative path we should try finding it from release server
            elsif( -e $pathToReleaseFolder.$dependsOf."release_metadata.xml" ) {
                printLog( $dependencyPath ."release_metadata.xml not not exist - setting pathToReleaseFolder accordingly" );
                $xmlToRemove = $pathToReleaseFolder.$dependsOf;
            }
        }
        elsif( opendir( TMPTEST, $pathToReleaseFolder.$dependsOf ) ) {
            $xmlToRemove = $pathToReleaseFolder.$dependsOf;
        }
        else {
            $xmlToRemove = $defaultPathToServer.$dependsOf;
        }

        #my $xmlToRemove = $pathToReleaseFolder;
        
        $xmlToRemove .= SearchValidXml( $xmlToRemove );
        printLog( "following xml needs to be removed also: $xmlToRemove" );
        RemoveThisXmlFromFinalList( $xmlToRemove  );
    }
}

sub ReductFilesFromFinalLists {
    printLog( "reducting files from finalziplist" );
    foreach my $zips( sort { $packageHash{$b}->{'state'} <=> $packageHash{$a}->{'state'} } keys %packageHash ) {
        printLog( "matching $zips" );
        if( $packageHash{$zips}->{'default'} eq 'true' ) {
            my $tmpHash = $packageHash{$zips};
#           $tmpHash->{'filename'} = $zips;
#           unshift @finalZipList, $tmpHash;

            # if $tmpHash->{'filename'} eq can be found from finalziplist -> pop
            foreach my $finalZip( @finalZipList ) {
# path contains ../../../ so wont match ==>
#               if( $finalZip->{filename} eq $zips and
#                       $finalZip->{path} eq %packageHash->{$zips}->{'path'} ) {
                if( $finalZip->{filename} eq $zips ) {
                            printLog( "removing $finalZip->{path}/$finalZip->{filename} from dl list" );
                            $finalZip->{default} = "false";
                }
            }
        }
    }
    %packageHash = 0;
}

# verifying that files in @finalZipList really exists
sub VerifyFinalZipList {
    print "Verifying all the zips exists... ";

    my $counter = 0;
    
    foreach my $file( @finalZipList ) {
        my $tmpFileName = $file->{path}.$file->{filename};
        printLog( "Checking $tmpFileName.." );
        opendir( VERIFYDIR, $file->{path} ) or HandleError( $file->{path}, $dependencyMissing );
        # scan all xml files to @xmlFiles
        my @matchingFiles = grep /$file->{filename}/i, readdir VERIFYDIR;
        
        if( ! @matchingFiles ) {
            HandleError( $file->{path}.$file->{filename}, $dependencyMissing );
            
            # if we are here there is missing file but keep_going defined
            $file->{default} = "false";
        }
        closedir VERIFYDIR;
        
        $counter++;
    }
    
    print "done\n";
}


sub GetEnv {
    # first thing is to copy 7zip
    if( ! $param_print_only ) {
        `7za --help`;
        HandleError( "couldnt copy 7zip! make sure you have it in your system path!", $warning ) if ($? != 0);
        mkdir $tmpDir;
        mkdir $tmpDlDir;
    }

    printLog( "final zip list:" );
    printLog( Dumper( @finalZipList ) );

    # symsee 3.3.0 contains obsolete archive::zip, so we'll have to use system calls
    foreach my $file( @finalZipList ) {
        $returnValue = 0;

        # skip not mandatory files
        next if( $file->{default} eq "false" );

        # DEPRECATED parameters just for compatibility
        # Filter out some not wanted zip files
        # skip internal, testsources, docs
        if( $param_skipITD ) {
            print "skipitd is deprecated and unmaintained parameter that will be removed in the future!\nInstead you should use \"getenv -x tsrc\"";

            printLog( "param skipITD used, checking wheter we have to skip: $file->{filename}" );
            # skip if zip filename matches _internal.zip, _tsrc.zip, _doc.zip
            next if $file->{filename} =~ /internal.zip/;
            next if $file->{filename} =~ /tsrc.zip/;
            next if $file->{filename} =~ /doc.zip/;
        }
        
        # DEPRECATED parameters just for compatibility
        # get only files needed for emulator and service packs
        if( $param_emuenv ) {
            print "emu is deprecated and unmaintained parameter that will be removed in the future!\nInstead you should use \"getenv -i emu\"";
            my $skip = 1;
            
            printLog( "param emu used, checking wheter we have to skip: $file->{filename}" );
            if( $file->{filename} =~ /winscw.zip/ or
                    $file->{filename} =~ /epoc32.zip/ or
                    $file->{filename} =~ /epoc32_tools.zip/ or
                    $file->{state} == 10 ) {
                $skip = 0;
            }
            next if $skip;
        }
        
        my $skipByFilter = 0;
        # exclude files that has s60filter matching with exclude array
        if( @param_exclude ) {
            foreach my $exclude( @param_exclude ) {
                if( $exclude eq $file->{s60filter} ) {
                    $skipByFilter = 1;
                    last;
                }
            }
        }
        # include only files that has s60filter matching with include array
        elsif( @param_include ) {
            $skipByFilter = 1;
            foreach my $include( @param_include ) {
                if( $include eq $file->{s60filter} ) {
                    $skipByFilter = 0;
                    last;
                }
            }
        }
        next if $skipByFilter;

        # let's do some forking
        # parent process unzips from tmpdir and child DL's new package from network

        # fork new process
        my $pid = myFork();
        if( $pid ) {
            # parent process copies/unzips packages to tmpDlDir
            printLog( "parent: extract packages to $tmpDlDir" );
            printLog( "parent: Processing: $file->{filename}... " );
            print "Processing: $file->{filename}... ";
            
            if( $file->{extract} eq 'single' ) {
                # copy single zipped packages to $tmpDlDir
                printLog( "parent: single zipped - copy to $tmpDlDir" );
                if( ! $param_print_only ) {
                    copy( $file->{path} . $file->{filename}, $tmpDlDir ) or
                        HandleError( "cant copy file $file->{path}$file->{filename} to $tmpDlDir", $cannotContinue);
                }
            }
            elsif( $file->{extract} eq 'double' ) {
                # unzip double zipped zips to $tmpDlDir
                # there shouldnt be much of these anymore
                printLog( "parent: double zipped - unzip to $tmpDlDir" );
                my $extrCmd = q{7za x -y "};
                $extrCmd .= $file->{path} . $file->{filename};
                $extrCmd .= q{" -o} . $tmpDlDir;
                if ( $^O =~ /linux/i){
                    $extrCmd .= " > /dev/null";
                }else{
                    $extrCmd .= " > NUL";
                }
                print "system: $extrCmd\n" if( $param_print_only );
                printLog( "parent: system: $extrCmd" );;
                system( $extrCmd ) if( !$param_print_only );
                if( $? ) {
                    printLog( "Problem processing $file->{path} $file->{filename}: $?" );;
                    $returnValue = $?;
                    HandleZipError( $file->{path} . $file->{filename}, $? );
                }
            }
            elsif( $file->{extract} eq 'save' ) {
                # copy non-zipped files directly to environment ( getcwd )
                print "pure copy\n" if( $param_print_only );
                printLog( "parent: pure copy from: ".$file->{path}.$file->{filename}." to: ".getcwd.$file->{filename} );
                copy( $file->{path}.$file->{filename}, getcwd.$file->{filename} ) if( ! $param_print_only );
            }
            else {
                HandleError( "unregocnised filetype: $file", $warning );
            }
            
            printLog( "parent: package in $tmpDlDir available.. waiting for child" );
            waitpid($pid, 0);
            printLog( "parent: finished" );
        }
        elsif( $pid == 0 ) {
# TODO: we should test wheter there is zips in $tmpDir
            printLog( "child: extract zips from $tmpDir to ".getcwd );
            
            # extract from temp to extractDir
            UnzipFromTempToEnv( );
            
            printLog( "child: finished" );
            exit( 0 );
        }
        else {
            # fork failed
            die "Cannot fork: $!\n";
        }
        
        # this is after forking
        # move files from tmpDlDir => tmpDir
        my $somethingToCopy = 0;
        opendir( DLTEMP, $tmpDlDir ) or HandleError( "cant read $tmpDlDir dir: $!", $warning );
        my @filesFound = readdir( DLTEMP );
        closedir( DLTEMP );
        foreach my $file( @filesFound ) {
            next if $file =~ /^\.[\.]?$/;
            $somethingToCopy = 1;
        }

        if( $somethingToCopy ) {
            printLog( "move everything from $tmpDlDir to $tmpDir" ); 
            opendir( DLTEMP , $tmpDlDir );
            for (grep( !/^\.\.?$/, readdir(DLTEMP))){
                move("$tmpDlDir/$_", $tmpDir) or die("$tmpDlDir/$_ move failed :$!");
            }
            closedir( DLTEMP );
        }
        
        if( $returnValue == 0 ) {
            print "done\n";
            printLog( "done" );
        }
        else {
            print "done, but errors occured!\n";
            printLog( "done, but errors occured" );
        }
    }
    
    # current forking mechanism is leaving last package(s) to $tmpDir
    opendir(TEMPDIR,  $tmpDir);
    UnzipFromTempToEnv() if(scalar(grep( !/^\.\.?$/, readdir(TEMPDIR))) > 0);
    closedir(TEMPDIR);

    if( -e FixPaths( getcwd )."currentRelease.xml" ) {
        unlink( FixPaths( getcwd )."currentRelease.xml" ) if( ! $param_print_only );
    }
    # copy the xml into $extractDir\buildData from $serverPath.$serviceName.$metaDataFile
    copy( $metaDataXml, FixPaths( getcwd )."currentRelease.xml" ) if( ! $param_print_only );
    
    # cover trails
    unlink( "/7za.exe" ) if( ! $param_print_only );
    if( ! $param_print_only ) {
        printLog( "removing temp dir... " );
        rmdir $tmpDir or HandleError( "Couldnt remove temp dir: $!", $warning );
        rmdir $tmpDlDir or HandleError( "Couldnt remove temp dir: $!", $warning );
        print scalar(localtime) . ": done fetching environment\n";
        printLog( "done" );
    }
}

sub UnzipFromTempToEnv {
    # extract from temp to extractDir
    printLog( "child: unzip from temp" );
    my $finalUnzipCmd = qq{7za x -y "$tmpDir/*.zip" -o"}.getcwd.q{"};
    if ( $^O =~ /linux/i){
        $finalUnzipCmd .= " > /dev/null";
    }else{
        $finalUnzipCmd .= " > NUL";
    }

    print "system: $finalUnzipCmd\n" if( $param_print_only );
    printLog( "child: system: $finalUnzipCmd" );
    system( $finalUnzipCmd ) if( !$param_print_only );
#           if( $? ) {
#               $returnValue = $?;
#               HandleZipError( $file->{path} . $file->{filename}, $? );
#           }
    
    # empty temp dir
    printLog( "child: empty temp dir" );
    printLog( "child: unlink: $tmpDir" );

    # dont handle errors - temp might be empty as well!
    opendir( TEMPDIR, $tmpDir );
    my @zipFiles = grep /zip/, readdir TEMPDIR;
    foreach my $myfile( @zipFiles ) {
        if( ! $param_print_only ) {
            printLog( "child: unlink: $myfile" );
            unlink( $tmpDir."/".$myfile );
        }
    }
    closedir TEMPDIR;
}

# handles return values coming from 7zip
#   0 No error 
#   1 Warning (Non fatal error(s)). For example, some files were locked by other application during compressing. So they were not compressed. 
#   2 Fatal error 
#   7 Command line error 
#   8 Not enough memory for operation 
#   255 User stopped the process 
sub HandleZipError {
    my( $filename, $errorCode ) = @_;
    
    if( $errorCode == 1 ) {
        # warning
        printLog( "7zip reported warning during unzipping of $filename" );
        print "Warning while unzipping $filename!\nSome files might be locked be other processes. It is possible that all the files werent extracted!\n";
    }
    elsif( $errorCode == 2 ) {
        # fatal error
        printLog( "possibly corrupted archive: $filename" );
        print "Fatal error occured while extracting $filename!!\nPlease check you have enough disk space on ".getcwd."\n";
        print "Otherwise you should report this problem for the build team. Please include ".getcwd."\\getenv.log to the mail.";
    }
    elsif( $errorCode == 7 ) {
        # commandline error
        printLog( "there is command line error while unzipping $filename" );
        print "7-zip is reporting command line error when unzipping $filename.";
        print "You should report this problem for the build team. Please include ".getcwd."\\getenv.log to the mail.";
    }
    elsif( $errorCode == 8 ) {
        # not enough memory
        printLog( "7zip reports not enough memory. Possibly disk full" );
        print "Not enough memory to extract $filename!!\nPlease check you have enough disk space on ".getcwd.". Otherwise please try again\n";
    }
    elsif( $errorCode == 255 ) {
        # user aborted
        printLog( "User aborted extraction!!" );
        print "User aborted extraction!\n$filename is not extracted completely and therefore your environment might not work as expected!";
    }
    else {
        # unspecified error
        printLog( "unspecified error: $errorCode while extracing: $filename\nPlease check you have enough free disk space" );
    }
}

# return path to accessible GRACE samba share
sub FindGraceServer {
# added 27.2.2007 : skip seeking if server has given from commandline
# salmarko starts
    if (defined $param_server) {return FixPaths( $param_server );}
# salmarko ends

    print "\nseeking possible grace accesses. This might take a while.. ";

        my @graceAccessArray;
        foreach my $address( @graceList ) {
            printLog( "accessing $address..." );
            if( opendir( GRACETEST, $address ) ) {
                push @graceAccessArray, $address;
                printLog( " success\n" );
                close GRACETEST;
            }
            else {
                printLog( " fail" );
            }
        }

    if( @graceAccessArray ) {
        print "done\nSelected GRACE server: ", $graceAccessArray[0];
        if( scalar( @graceAccessArray ) > 1 ) {
            
            # if start is defined && >1 grace shares available, we'll have to just guess correct share
            if( $param_start_directly ) {
                print( "More than one grace shares accessible\n" );
                print Dumper( @graceAccessArray );
                print "\nBecause -start parameter is provided we cant prompt user to select correct, lets pick first one from the list\n";
                print "You should use -server parameter to define the server\n";
                printLog( "-start defined and >1 grace shares accessible" );
                printLog( @graceAccessArray );
                printLog( "selecting first one: $graceAccessArray[0]" );
                return FixPaths( $graceAccessArray[0] );
            }
            else {
# salmarko starts
                return FixPaths( PrintSelectMenu( "Select reasonable GRACE share", @graceAccessArray ) );
# salmarko ends
            }
        }
        else {
# salmarko starts
            return FixPaths( $graceAccessArray[0] );
# salmarko ends
        }
    }
    print "none found\n";
    return 0;   
}

# return name of the release from metadata.xml
sub ReturnReleaseName {
    my $data = shift( @_ );
    
    my $tempXmlParser = new XML::Simple( );
    my $tempXmlHandle = $tempXmlParser->XMLin( $data );
    
    # parse dl directory into $releaseDirectory
    return $tempXmlHandle->{releaseDetails}->{releaseID}->{release}->{name};
}

# retrurn name of the product from metadata.xml
sub ReturnProductName {
    my $data = shift( @_ );
    
    my $tempXmlParser = new XML::Simple( );
    my $tempXmlHandle = $tempXmlParser->XMLin( $data );
    
    # parse dl directory into $releaseDirectory
    return $tempXmlHandle->{releaseDetails}->{releaseID}->{product}->{name};
}

sub GetSoapVersion {
    printLog( "Trying to access SOAP server" );
    
    my $soapVersion = eval { SOAP::Lite
                                                        ->uri('GetEnv')
                                                        ->on_action(sub{ sprintf('%s/%s', @_ )})
                                                        ->proxy($soapServiceURL)
                                                        ->GetVersionInfo( )
                                                        ->result } ;
    
    print Dumper( $soapVersion ) if( $param_debug );
    
    return $soapVersion;
}

sub StartSoapSession {
    printLog( "fetching session start info from SOAP" );
    my $netPath = FixPaths( $pathToReleaseFolder );
    $netPath .= FixPaths( $defaultServiceName );
    $netPath .= FixPaths( ReturnProductName( $metaDataXml ) );
    $netPath .= FixPaths( ReturnReleaseName( $metaDataXml ) );
#   $netPath .= $metaDataXml;
    printLog( "about to fetch: $netPath" );
    
    return SOAP::Lite
        ->uri('GetEnv')
        ->on_action(sub{ sprintf('%s/%s', @_ )})
        ->proxy($soapServiceURL)
        ->StartGetEnv( SOAP::Data->name( BuildName=> ReturnReleaseName( $metaDataXml ) )
                                            ->type('string')
                                            ->uri('GetEnv'),
                                        SOAP::Data->name( NetworkPath=> $netPath )
                                            ->type('string')
                                            ->uri('GetEnv'),
                                        SOAP::Data->name( UserName=> $ENV{'USERNAME'} )
                                            ->type('string')
                                            ->uri('GetEnv'),
                                        SOAP::Data->name( MachineName=> $ENV{'COMPUTERNAME'} )
                                            ->type('string')
                                            ->uri('GetEnv') )
        ->result;
}

sub EndSoapConnection {
    printLog( "SOAP: Finishing SOAP session: $soapSessionID" );
    printLog( "SOAP: release downloaded: $metaDataXml" );

    return SOAP::Lite
        ->uri('GetEnv')
        ->on_action(sub{ sprintf('%s/%s', @_ )})
        ->proxy($soapServiceURL)
        ->DoneGetEnv( SOAP::Data->name( ID=> $soapSessionID )
                                        ->type('string')
                                        ->uri('GetEnv'))
        ->result;

}


sub FindTempDir {
    # it'll speed up extraction if we put temp dir to separate disk
    
}

# finds first param from second param(comma separated list)
sub FindFromList {
    my( $itemToFind, $list ) = @_;
    my @itemList = split( /,/, $list );
    foreach( @itemList ) {
        return 1 if( $_ eq $itemToFind );
    }
    
    return 0;
}

sub myFork()
    {
    sleep(1);  #let buffers flush
    my $pid = fork();
    if(!defined($pid))
        {
        die "fork error\n";
        }
    return $pid;
    }

