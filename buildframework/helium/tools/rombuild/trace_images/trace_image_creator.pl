#============================================================================ 
#Name        : trace_image_creator.pl 
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

#######################
# Creates trace images 
#######################

#use strict;
use Getopt::Long;
use File::Copy;

my ($phone,$k,$sos,$production,$backup,$dir_value,$create_core,$myvariant,$merge,$tracetype,$variant,$command,$name102,$product,$platform,$hid);
my (@cores,$image_path,$backup_core_zip,$drive);

my ($test,$cmd,$RetVal,$ORIGINAL_FILENAME);
my ($script_path);

# If $test=0, files are not backed up in ReplaceStringInFile(). If $test=1, files are backed up in ReplaceStringInFile().
$test=1;
# Setting default value for tracetype (All)
$tracetype = "all";

#location of this script and other related files
$script_path = $ENV['HELIUM_HOME']."/tools/rombuild/trace_images";

################## BEGIN ##################

GetOptions(
    "tracetype=s", => \$tracetype,
    "norestore" => \$norestore,
    "restore" => \$restore,
    "platform=s" => \$platform,
    "product=s" => \$product,
    "variant=s" => \$variant,
    "drive=s" => \$drive
    );
	
## Option info
print"\n=== Variant(s)           : ",uc($variant);
print"\n=== Tracetype            : ",uc($tracetype);

if ($norestore)
{
	print "\n\n=== Environment will not be restored after image creation\n";
}

if ($restore)
{
    restore_environment();
}
	
check();

create_images();




############### SUBROUTINES ###############

sub show_error
{
    print"\n\n\n   ***********  T R A C E  I M A G E  C R E A T O R  H E L P **********\n";

	print"    \n		Creates trace images\n";

    print"    \n   ***********  O P T I O N S   D E S C R I P T I O N *****************\n";
    print  "  \n[-p]   Mandatory Parameter   Specifies Product. PRODUCT";
    print    "\n[-platform]                  Specifies Platform. PLATFORM";
    print    "\n[-v]   Mandatory Parameter   Specifies variant. flashuirnd";
    print    "\n[-t]   Mandatory Parameter   Specifies which trace images are created";
    print    "\n                             all     = create all trace images ";
    print    "\n                             general = create general trace image";
    print    "\n                             phone   = create phone trace image";
    print    "\n[-d]   Mandatory Parameter   Specifies output drive";
    print  "\n\n(-n)   Optional Parameter    Does not restore the environment after";
    print    "\n                             trace image creation";
    print  "  \n(-r)   Optional Parameter    Does an environment restore only";

    print"\n\n\n   ******************************* U S A G E ********************************\n";
    print    "\n  Trace_image_creator.pl -product PRODUCT -tracetype all -drive q: -variant flashuirnd";
    print    "\n  Trace_image_creator.pl -p PRODUCT -t all -d q: -v flashuirnd \n";
    exit();
}


sub check
{
    if (! defined $variant)
    {
        print STDERR "\n\n **** Variant is not defined! ****\n\n";
        show_error(); 
    } 
}


sub create_images
{
    print "\n\n--- Backing up myTraces.txt";
    system ("copy /y \\epoc32\\rombuild\\myTraces.txt $script_path\\myTraces.txt.orig");
    
    print "create images...\n";
    
    $command = "";
    
    #set traces
    if (($tracetype eq "all") or ($tracetype eq "general"))
    {
        system ("title Creating general trace image");
        system ("copy /y $script_path\\myTraces_general.txt \\epoc32\\rombuild\\myTraces.txt");        
        
        #create images
        $command = "imaker -c$platform -p$product -k -f /epoc32/rom/config/$platform/$product/mc_imaker.mk $variant USE_UDEB=1 WORKDIR=$drive\\output\\development_flash_images\\traces\\general";
        print "\n $command \n";
        system ($command);
    }

    if (($tracetype eq "all") or ($tracetype eq "phone"))
    {    
        system ("title Preparing environment for phone traces");
        PrepareBuildEnv();
        BuildFiles();        

        system ("title Creating phone trace image");
		system ("copy /y $script_path\\myTraces_phone.txt \\epoc32\\rombuild\\myTraces.txt");        
		
		#create images
		$command = "imaker -c$platform -p$product -k -f /epoc32/rom/config/$platform/$product/mc_imaker.mk USE_UDEB=1 WORKDIR=$drive\\output\\development_flash_images\\traces\\phone $variant";
        system ($command);
    }
    
    if ($restore)
    {
        restore_environment();
    }
}

sub restore_environment
{
	if (-e "\\phone_trace_backup.zip")
	{
		print"\n\n=== Restoring environment after phone traces";
		chdir "\\";
		system ('unzip -q -o \phone_trace_backup.zip');
		system ('del /q \phone_trace_backup.zip');
	}
	elsif (-e "$script_path\\myTraces.txt.orig")
	{
		print"\n\n=== Restoring myTraces.txt";
		system ("move /y $script_path\\myTraces.txt.orig \\epoc32\\rombuild\\myTraces.txt");
	}
	else
	{
		print STDERR "\n\n=== Can not restore, nothing to restore!\n\n";
		show_error();
	}
	exit();
}

sub PrepareBuildEnv
{
    # S60 Phone Engine Traces
    # =======================
    #
    #define __PHENG_DEBUG_INFO__
    #define __PHENG_DEBUG_ENABLE_ALL_AREAS__
    #define __PHENG_PRINT_DEBUG_INFO__    
    #
    
    $test=1;
    $ORIGINAL_FILENAME='\s60\app\telephony\s60cstelephonyengines\Phoneengine\Inc\EngineBase\KPhEngConfigure.h';
    $OLD='//#define __PHENG_DEBUG_INFO__';
    $NEW='#define __PHENG_DEBUG_INFO__';
    ReplaceStringInFile();
    
    $test=0;
    $OLD='//#define __PHENG_DEBUG_ENABLE_ALL_AREAS__';
    $NEW='#define __PHENG_DEBUG_ENABLE_ALL_AREAS__';
    ReplaceStringInFile();

    $OLD='//#define __PHENG_PRINT_DEBUG_INFO__';
    $NEW='#define __PHENG_PRINT_DEBUG_INFO__';
    ReplaceStringInFile();
    
    $test=1;    
    
    # Phone App Engine Traces
    # =======================
    #
    #define _PHAPE_DEBUG_INFO_
    #
    
    $ORIGINAL_FILENAME='\s60\app\telephony\cstelephonyuis\PhoneAppEngine\inc\Common\KPhApEConfigure.h';
    $OLD='//#define _PHAPE_DEBUG_INFO_';
    $NEW='#define _PHAPE_DEBUG_INFO_';
    ReplaceStringInFile();
    
    # Changing TSY logging from FLogger to RDEBUG
    # ===========================================
    #
    #define TF_LOGGING_METHOD  2
    #
    
    #Change logging for UDEB build
    $ORIGINAL_FILENAME='\s60\osext\telephonyservices\telsrv_dom\common_tsy_service_api\inc\tflogger.h';
    $OLD='#define TF_LOGGING_METHOD  1';
    $NEW='#define TF_LOGGING_METHOD  2';
    ReplaceStringInFile();
    
    #Change logging for UREL build
    $test=0;
    $OLD='#define TF_LOGGING_METHOD  0';
    $NEW='#define TF_LOGGING_METHOD  2';
    ReplaceStringInFile();
    
    $test=1;

    # Changing SAT logging from FLogger to RDEBUG
    # ===========================================
    #
    #define LOGGING_ENABLED
    #

    $ORIGINAL_FILENAME='\s60\app\telephony\satui\satapp\SATShellControllerInc\tflogger.h';
    $OLD='//#define LOGGING_ENABLED';
    $NEW='#define LOGGING_ENABLED';
    ReplaceStringInFile();    
    
    $ORIGINAL_FILENAME='\s60\app\telephony\satui\satapp\SATUIInc\tflogger.h';
    $OLD='//#define LOGGING_ENABLED';
    $NEW='#define LOGGING_ENABLED';
    ReplaceStringInFile();        

    $ORIGINAL_FILENAME='\s60\app\telephony\satui\satplugin\aisatplugininc\tflogger.h';
    $OLD='//#define LOGGING_ENABLED';
    $NEW='#define LOGGING_ENABLED';
    ReplaceStringInFile();        
    
    # Enabling debugging in SATServer
    # ===============================
    #
    #define ENABLE_SAT_LOGGING
    #MACRO ENABLE_SAT_LOGGING
    #

    $ORIGINAL_FILENAME='\s60\app\telephony\satengine\SatServer\inc\SatMacroes.h';
    $OLD='// #define ENABLE_SAT_LOGGING';
    $NEW='#define ENABLE_SAT_LOGGING';
    ReplaceStringInFile();            
    
    $test=0;
    $OLD='// MACRO ENABLE_SAT_LOGGING';
    $NEW='MACRO ENABLE_SAT_LOGGING';
    ReplaceStringInFile();         
    
    $test=1;
    
    # CBS logs
    # ========
    #
    #define CBS_LOGGING_METHOD  2
    #

    $ORIGINAL_FILENAME='\s60\app\telephony\cbsengine\CbsServer\ServerInc\CbsLogger.h';
    $OLD='#define CBS_LOGGING_METHOD  0';    
    $NEW='#define CBS_LOGGING_METHOD  2';
    ReplaceStringInFile();       

    $test=0;
    $OLD='#define CBS_LOGGING_METHOD  1';    
    $NEW='#define CBS_LOGGING_METHOD  2';
    ReplaceStringInFile();              
    
    $test=1;
}    

sub ReplaceStringInFile
{
    if ( $test ) 
    {
        system("zip \\phone_trace_backup.zip $ORIGINAL_FILENAME");
    }
  
    open (SYMBOL_FILE, "<$ORIGINAL_FILENAME") || die $ORIGINAL_FILENAME," not found\n";
    open (NF, ">>$ORIGINAL_FILENAME.new")|| die $ORIGINAL_FILENAME," not found\n";

    while ($line = <SYMBOL_FILE>)
    {
        $line =~ s/$OLD/$NEW/;
        print NF $line;
    };
  
    close SYMBOL_FILE;
    close NF;
  
    $cmd = "move $ORIGINAL_FILENAME $ORIGINAL_FILENAME.bak";
    system($cmd);
    $cmd = "move $ORIGINAL_FILENAME.new $ORIGINAL_FILENAME";
    system($cmd);
}

sub AddLine
{
    open (SYMBOL_FILE, "<$ORIGINAL_FILENAME") || die $ORIGINAL_FILENAME," not found\n";
    open (NF, ">>$ORIGINAL_FILENAME.new")|| die $ORIGINAL_FILENAME," not found\n";
    
    while ($line = <SYMBOL_FILE>)
    {
        #print $line;
        #$line =~ s/$OLD/$NEW/;
        print NF $line;
    };
    print NF "\n";
    print NF $LINE_TO_ADD;
    close SYMBOL_FILE;
    close NF;
    
    $cmd = "move $ORIGINAL_FILENAME $ORIGINAL_FILENAME.bak";
    system($cmd);
    $cmd = "move $ORIGINAL_FILENAME.new $ORIGINAL_FILENAME";
    system($cmd);
}

sub SearchStringInFile
{
    open (SYMBOL_FILE, "<$ORIGINAL_FILENAME") || die $ORIGINAL_FILENAME," not found\n";

    while ($line = <SYMBOL_FILE>)
    {
        $SetVar = $line =~ /$LINE_TO_ADD/;
        if ($SetVar eq 1)
        {
            return $SetVar;
        }
    };

    close SYMBOL_FILE;
    return 0;
}

sub BuildFiles
{
    #export tflogger.h
    print "\n\n --- Exporting flogger.h --- \n";
    chdir '\s60\osext\telephonyservices\telsrv_dom\common_tsy_service_api\group';
    system('bldmake bldfiles');
    system('abld export');
    
    #Building PhoneEngine
    print "\n\n --- Backing up PhoneEngine...\n";
    chdir '\s60\app\telephony\s60cstelephonyengines\Phoneengine\Group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building PhoneEngine...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');

    #Building PhoneAppEngine
    print "\n\n --- Backing up PhoneAppEngine...\n";
    chdir '\s60\app\telephony\cstelephonyuis\PhoneAppEngine\group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building PhoneAppEngine...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');
   
    #Building PhoneServer
    print "\n\n --- Backing up PhoneServer...\n";
    chdir '\s60\app\telephony\phoneclientserverengine\Group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building PhoneServer...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');

    #Building Phone
    print "\n\n --- Backing up Phone...\n";
    chdir '\s60\app\telephony\cstelephonyuis\phone\Group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building Phone...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');

    #Building edge variant of phone	
	print "\n\n --- Backing up Phone, Edge...\n";
	chdir '\psw\s60_32_psw\bin_var\edge_var\group\phone';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building Phone...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');
	
    #Building CustomApiExt
    print "\n\n --- Backing up CustomApiExt...\n";         
    chdir '\ncp_sw\corecom\CASW_Adaptation\NokiaTSY\CustomAPIExt\group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building CustomApiExt...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');
	
    #Building CommonTSY
    #Building CustomAPI
    #Building phonetsy
    print "\n\n --- Backing up CommonTSY...\n";
    chdir '\psw\s60_32_psw\bin_var\commontsy_var\group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building CommonTSY...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');
	
    #Building NokiaTSY
    print "\n\n --- Backing up NokiaTSY...\n";
    chdir 'ncp_sw\corecom\CASW_Adaptation\NokiaTSY\NokiaTSY\group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building NokiaTSY...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');

    #Building SimAtkTSY
    print "\n\n --- Backing up SIM_ATK_TSY...\n";
    chdir '\ncp_sw\corecom\CASW_Adaptation\SIM_ATK_TSY\SimAtkTSY\group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building SIM_ATK_TSY...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');
    
    #Building SatServer
    print "\n\n --- Backing up SATServer...\n";
    chdir '\s60\app\telephony\satengine\group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building SATServer...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');

    #Building SatUI
    print "\n\n --- Backing up SatUI...\n";
    chdir '\s60\app\telephony\satui\group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building SatUI...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');    

    #Building CBS server    
    print "\n\n --- Backing up CBS server...\n";
    chdir '\s60\app\telephony\cbsengine\CbsServer\Group';
    system('bldmake bldfiles');
    system('abld build -w armv5 udeb | zip -@ -q \phone_trace_backup.zip');
    print "\n --- Building CBS server...\n";
    system('abld reallyclean armv5 udeb');
    system('bldmake bldfiles');
    system('abld build armv5 udeb');        
}

sub replacestring 
{
    my ($targetfile, $fromstring, $tostring) = @_;
    if ($targetfile ne "" && $fromstring ne "" && $tostring ne "") 
    {
        open(IN, "<$targetfile");
        open(OUT, ">$targetfile\__TEMP");
        @lines = <IN>;
        foreach $line (@lines) 
        {
            $line =~ s/$fromstring/$tostring/g;
            print OUT $line;
        }
        close IN; close OUT;
        move("$targetfile\__TEMP", "$targetfile") or warn "Can't replace file contents!\n";
        if (!-f "$targetfile\__TEMP") 
        {
            print "Replacement of ", $targetfile, " ok.\n";	
        }
    }
}

sub run_cmd 
{
    my $cmd = shift; my $output = "";
    open CMD, "$cmd |";
    while (<CMD>) 
    {
        $output .= $_;
        print $_;
    }
    close CMD;
    return $output;
}

sub RestoreBuildEnvironment
{
    print "\n\nRestoring the build environment.\n";
    foreach $k (@files)
    {
        print "Restoring $k file...\n";
        $FILENAME=$k;
        $cmd = "move $FILENAME.orig $FILENAME";
        system($cmd);
    }
}