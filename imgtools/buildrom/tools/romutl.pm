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
# Collection of utilitiy functions which is copied from Symbian OS perl modules. 
# It provides platform related information to ROM Tools including buildrom, 
# features.pl, etc.
# 

package romutl;

require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(
  init_plat
  init_bsfs
  init_platwithbpabi
  
  get_epocroot
  get_drive
  get_epocdrive
  get_versionedname
  get_bpabiplatlist
  get_platlist
  get_platcustomizes
  get_platroot
  get_makeeabspath
  get_variantmacrolist  
  get_variantmacroHRHfile
  get_abiv2mode
  get_variantfullpath
  get_BVbinname
  get_variant
  
  is_existinpath
  
  set_verbose
  
  check_varfile
  split_path
  append_driveandquote  
  write_32bit
);


# EPOCROOT with proper format 
my $epocroot;
my $epocdrive = "";
my $drive = "";

BEGIN {
    require 5.005_03;       # check user has a version of perl that will cope
    
    $epocroot = $ENV{EPOCROOT};
    $epocroot = "\/" if (!$epocroot); # use "\" if EPOCROOT is not specified
    $epocroot =~ s/\\/\//g;
    $epocroot .= "\/" unless $epocroot =~ /\/$/;
}

use strict;
use Cwd;
use File::Spec;
use romosvariant;

my $verbose=0;

########################
#Init
#

#die "ERROR: EPOCROOT must specify an existing directory." if (!-d $epocroot);
#die "ERROR: EPOCROOT must not be a UNC path\n" if ($epocroot =~ /^\\\\/);

$drive=$1 if (cwd =~ /^(.:)/);

if ($epocroot =~ /^(.:)/)
{
    $epocdrive=$1;
}
else
{
# current working directory is different to SDK's
    $epocdrive=$drive
}

#####################################
# General functions
#

sub get_epocroot
{
    return $epocroot;
}

sub get_epocdrive
{
    return $epocdrive;
}

sub get_drive
{
    return $drive;
}

sub set_verbose
{
    $verbose = shift;
}

use constant QUIET_NOT_FOUND => 0; #  return 0 if file not found in the PATH
use constant DIE_NOT_FOUND => 1; #  issue error and die if file not found in the PATH
use constant ERROR_NOT_FOUND => 2; #  issue error and return 0 if file not found in the PATH

# Simulate shell to locate executable file in the PATH
#
# WARNING: don't use this func in a deep loop because of the
#          less efficient implementation
#
# usage:  is_existinpath <filename> [<flag>]
#
#   flag == DIE_NOT_FOUND    die and display error when not found
#   flag == ERROR_NOT_FOUND  display error and return 0 when not found
#   else return 0 when not found
#   return 1 when found     

sub is_existinpath
{
    my ($filename, $flag)=@_;
    return 0 unless defined $filename;
    return 0 if ($filename =~ /\\/);
    return 0 if ($filename =~ /\//); 
    
    my @paths;
    my $delimiter = &env_delimiter;
 		@paths = split(/$delimiter/, $ENV{PATH});
    unshift @paths, "\.";
    
    foreach my $path (@paths)
    {
        next if ($path =~ /^\s*$/);
        chomp $path;
        $path =~ s/\\/\//g;
        $path .= "\/" unless ($path =~ /\/$/);
        $path = $path.$filename;
        foreach my $ext ("", ".bat", ".cmd", ".exe", ".com", ".pl", ".py")
        {
            return 1 if (-e $path.$ext);
        }
    }
    die "Error: Cannot found \"$filename\" in the PATH.\n" if ($flag == DIE_NOT_FOUND);
    print "Error: Cannot found \"$filename\" in the PATH.\n" if ($flag == ERROR_NOT_FOUND);
    return 0;
} 

#########################################
# Symbian variant functions and variables
# 
# copy from e32variant.pm
#

my $toolspath = $epocroot . "epoc32\/tools\/";
# SPPR begin
# enable includation of spp_variant.cfg if it exist
my $spp_cfgFile = $toolspath . "variant\/spp_variant.cfg";
my $cfgFile = $toolspath . "variant\/variant.cfg"; # default location
$cfgFile = $spp_cfgFile if -e $spp_cfgFile; # use spp_variant.cfg
# SPPR End

my $variantABIV2Keyword = &get_abiv2mode;    # if variant ABIv2 mode enabled

my $hrhdrive = $epocdrive;   # variant hrh drive
my $hrhfile;    # variant hrh file
my @macros;     # variant macros

if ($cfgFile =~ /^(.:)/i)
{
   $hrhdrive = lc($1); 
}

# returns the variant specific macro definitions as a list
sub get_variantmacrolist{
    
    return @macros if (@macros);
    
    my $vfile = get_variantmacroHRHfile();
    
    if($vfile)
    {
        my $VariantFilePath = split_path('Path',$vfile);
        chop( $VariantFilePath );
        $VariantFilePath = &append_driveandquote($VariantFilePath);
        $vfile = &append_driveandquote($vfile);
        my $e32Path = &append_driveandquote($epocroot."epoc32\/include");
        
        open CPPPIPE,"cpp -I $e32Path -I $VariantFilePath -undef -dM $vfile |" or die "ERROR: Can't invoke CPP.EXE\n";
        while(<CPPPIPE>){
            if($_ =~ /(\#define)(\s+)(.+)/){
                push @macros, $3;
            }
        }
        close CPPPIPE;
    }
    return @macros;
}

# return hrh filename defined in variant cfg file
# notice: abort if hrh file located in different drive to cfg file
sub get_variantmacroHRHfile{
    
    return $hrhfile if ($hrhfile);
    if(-e $cfgFile){
        open(FILE, $cfgFile) || die "\nCould not open: " . $cfgFile ."\n";
        while (<FILE>) {
            # strip comments
            s/^([^#]*)#.*$/$1/o;
            # skip blank lines
            if (/^\s*$/o) {
                next;
            }
            # get the hrh file
            if($_ =~ /\.hrh/xi){
                $hrhfile = $_; 
                last;
            }
        }
        close FILE;
        die "\nERROR: No variant file specified in $cfgFile!\n" unless $hrhfile;
        $hrhfile =~ s/\s+//g;
        $hrhfile=~s/^(.:)//io;    # remove drive letter
        my $paths_drive = lc($1);
        
        chomp $hrhfile;
        $hrhfile = get_makeeabspath($epocroot."epoc32\/", $epocroot, $hrhfile); # assume relative to EPOCROOT
        
        
        if($paths_drive){
            die "\nERROR: Variant file specified in $cfgFile is not on the same drive as \/epoc32\/\n" 
            unless ($paths_drive eq $hrhdrive);
        }
        die "\nERROR: $cfgFile specifies $hrhfile which doesn't exist!\n" unless (-e $hrhfile);
        
        # make sure it is in unix syntax
        $hrhfile=~ s/\\/\//g;
    }
    return $hrhfile;
}

# get status of EANBLE_ABIV2_MODE
# 1=enabled 0=disabled
sub get_abiv2mode{

    return $variantABIV2Keyword if (defined $variantABIV2Keyword);

    $variantABIV2Keyword=0;
    if(-e $cfgFile){
        open(FILE, $cfgFile) || die "\nCould not open: " . $cfgFile ."\n";
        while (<FILE>) {
            # strip comments
            s/^([^#]*)#.*$/$1/o;
            # skip blank lines
            if (/^\s*$/o) {
            next;
            }
            # get the hrh file
            if($_ =~ /^ENABLE_ABIV2_MODE$/xi){
                $variantABIV2Keyword=1;
                last;
            }
        }
        close FILE;
    }

    return $variantABIV2Keyword;
}

#############################
# Path utilities
#
# copy from pathutl.pm
#

#args: $_[0] Start EPOCPath Abs FilePath/Path $_[1]... list of (Abs/Rel FilePath/Path)
# Variant of MakAbs which also maps "+\\" to "${EPOCPath}"
sub get_makeeabspath ($@) {    
    return undef unless $_[0]=~m-^(.:)?[\\\/]-o;
    my ($EPOCPath,$Path,@List)=@_;
    my $BasePath=&split_path("Path",$Path);
    undef $Path;
    my $p;
    foreach $p (@List) {
    		$p =~ s-\\-\/-g;
        if ($p=~m-^\/?epoc32\/(.*)$-io) {    # change - special case for existing \\epoc32 references
            $p=$EPOCPath.$1;
            next;
        }
        if ($p=~m-^\s*\+\/(.*)$-o) {
            $p=$EPOCPath.$1;
            next;
        }
        if ($p=~m-^\.{2}-o) {
            $p=&strip_path($BasePath.$p);
            next;
        }
        if ($p=~m-^[^\.\/]-o) {
            $p=$BasePath.$p unless ($p =~ m-^.:-o);
            next;
        }
        if ($p=~m-^(.:)?\/-o) {
            next;
        }
        if ($p=~m-^\.\/(.*)$-o) {
            $p=&strip_path($BasePath.$1);
            next;
        }
        return undef;
    }
    return wantarray ? @List : $List[0];
}

#args: $_[0] Abs FilePath/Path
# Remove excess occurrences of '..' and '.' from a path
sub strip_path ($) {   
    return undef unless $_[0]=~m-^(.:)?[\/\\]-o;
    my $P=$_[0];
    while ($P=~s-([\/\\])\.[\/\\]-$1-go) { }
    while ($P=~s-[\\](?!\.{2}\\)[^\\]*\\\.{2}(?=\\)--go) { }
    $P;
}

#args: $_[0] 'Path' or 'Base' or 'Ext' $_[1] Abs/Rel FilePath/Path
# return the section of a file path required - Path, Base, Ext or File
sub split_path ($$) { 
    my ($Sect,$P)=@_;
    
    return '' if !$P;    
    $Sect= ucfirst lc $Sect;
    if ($Sect eq 'Path') {
        if ($P=~/^(.*[\\\/])/o) {
            return $1;
        }
        return '';
    }
    undef;
}

sub append_driveandquote ($) {
# Take a path, or list of paths, and prefix with drive based on 1. epocroot, 2.CWD.
# Relative paths are just quoted.
    my @List=@_;
    my $Path;

    
    foreach $Path (@List) {
        next if ($Path !~ /^[\/\\]/); # skip prefix with drive letter or relative path
        $Path=$epocdrive.$Path;
    }

    foreach $Path (@List) {
        chomp $Path;
        $Path="\"".$Path."\"";
    }
    
    return wantarray ? @List : $List[0];
}


###############################
# General Utilities
#
# copy from genutl.pm
#

# return name with well formated version id in hex
sub get_versionedname($) {
    my ($name) = @_;
    if ($name =~ /(.*)\{\s*(\d+)\s*\.\s*(\d+)\s*\}(.*?)$/i) {
        my $a = $1;
        my $b = $4;
        my $major = $2;
        my $minor = $3;
        return $a.sprintf("{%04x%04x}",$major,$minor).$b if ($major<32768 and $minor<32768);
    }
    return $name;
}


###############################
# BPABI Platform Utilities
#
# copy from bpabiutl.pm
#

my @BPABIPlats;


# Identify the BPABI platforms to be supported based on the compiler configuration files
# present in the location specified by the environment variable "SYMBIAN_COMPILATION_CONFIG_DIR"
# and in the directory $EPOCROOT\epoc32\tools\compilation_config
sub get_bpabiplatlist 
{
    return @BPABIPlats if (scalar(@BPABIPlats));
    
    my @CompilerConfigPath;

    if (exists($ENV{'SYMBIAN_COMPILATION_CONFIG_DIR'})) 
    {
        my $Path = $ENV{SYMBIAN_COMPILATION_CONFIG_DIR};
        @CompilerConfigPath = split(/;/, $Path);
    }

    push @CompilerConfigPath, "${epocroot}epoc32\/tools\/compilation_config";

    my $ConfigDir;

    foreach $ConfigDir (@CompilerConfigPath)
    {
        opendir DIR, "$ConfigDir";
        my @Plats=grep /\.mk$/i, readdir DIR;
        my $Plat;
        foreach $Plat (@Plats) 
        {
# The platform name will be same as the name of the configuration file <config.mk>
# with the suffix '.mk' removed
            $Plat =~ s/\.mk//;
            if ($variantABIV2Keyword) {
                if ($Plat =~ /^armv5_abiv2$/i) {
                    $Plat = "ARMV5";
                }
            }
            else {
                if ($Plat =~ /^armv5$/i) {
                    $Plat = "ARMV5_ABIV2";
                }
            }
            unless (grep /$Plat$/i, @BPABIPlats) {
                $Plat = uc $Plat;
                push @BPABIPlats, $Plat;
            }
        }
    }
    closedir DIR;
    return @BPABIPlats;
}

#############################
# Platform Utilities
#
# copy from e32plat.pm
#
my %Plat=(
    ARM4=>{
        ABI=>'ARM4',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
    },
    ARM4SMP=>{
        ABI=>'ARM4',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        SMP=>1,
        StatLink=>'ARM4SMP',
    },
    ARM4T=>{
        ABI=>'ARM4T',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
    },
    ARMI=>{
        ASSP=>'MARM',
        Generic=>1,
        ASSPABI=>'',
    },
    SARM4=>{
        ABI=>'ARM4',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        Single=>1,
    },
    SARMI=>{
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        Single=>1,
    },
    STHUMB=>{
        ABI=>'THUMB',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        Single=>1,
    },
    THUMB=>{
        ABI=>'THUMB',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
    },
    TOOLS=>{
        ABI=>'TOOLS',
        ASSPABI=>'',
        Compiler=>'VC32',
        CPU=>'TOOLS',
        OS=>'TOOLS',
        MakeMod=>'Cl_win',
        MakeCmd=>'nmake',
    },
    TOOLS2=>{
        ABI=>'TOOLS2',
        ASSPABI=>'',
        Compiler=>'GCC32',
        CPU=>'TOOLS2',
        OS=>'TOOLS2',
        MakeMod=>'Cl_mingw',
        MakeCmd=>'make',
    },
    CWTOOLS=>{
        ABI=>'TOOLS',
        ASSPABI=>'',
        Compiler=>'CW32',
        CPU=>'TOOLS',
        OS=>'TOOLS',
        MakeMod=>'Cl_tools',
        MakeCmd=>'make',
    },
    VC6TOOLS=>{
        ABI=>'TOOLS',
        ASSPABI=>'',
        Compiler=>'VC32',
        CPU=>'TOOLS',
        Ext=>'.DSP',
        MakeMod=>'Ide_vc6',
        MakeCmd=>'nmake',
        OS=>'TOOLS',
        Real=>'TOOLS',
        UsrHdrsOnly=>1,
    },
    WINS=>{
        ABI=>'WINS',
        ASSPABI=>'',
        Compiler=>'VC32',
        CPU=>'WINS',
        MakeMod=>'Cl_win',
        MakeCmd=>'nmake',
        OS=>'WINS',
    },
    VC6=>{
        ABI=>'WINS',
        ASSPABI=>'',
        Compiler=>'VC32',
        CPU=>'WINS',
        Ext=>'.DSP',
        MakeMod=>'Ide_vc6',
        MakeCmd=>'nmake',
        OS=>'WINS',
        Real=>'WINS',
        UsrHdrsOnly=>1,
    },
    WINSCW=>{
        ABI=>'WINSCW',
        ASSPABI=>'',
        Compiler=>'CW32',
        CPU=>'WINS',
        MakeMod=>'Cl_codewarrior',
        OS=>'WINS',
        DefFile=>'WINS',    # use the MSVC def files
    },
    CW_IDE=>{
        ABI=>'WINSCW',
        ASSPABI=>'',
        Compiler=>'CW32',
        CPU=>'WINS',
        Ext=>'.xml',
        MakeMod=>'Ide_cw',
        MakeCmd=>'make',
        OS=>'WINS',
        Real=>'WINSCW',
        DefFile=>'WINS',    # use the MSVC def files
        UsrHdrsOnly=>1,
        SupportsMultiplePlatforms=>1,   # supports more than one real platform
    },
    X86=>{
        ABI=>'X86',
        ASSPABI=>'',
        Compiler=>'VC32',
        CPU=>'X86',
        MakeMod=>'Cl_x86',
        MakeCmd=>'nmake',
        OS=>'EPOC32',
        DefFile=>'X86',
        Generic=>1,
    },
    X86SMP=>{
        ABI=>'X86',
        ASSPABI=>'',
        Compiler=>'VC32',
        CPU=>'X86',
        MakeMod=>'Cl_x86',
        MakeCmd=>'nmake',
        OS=>'EPOC32',
        DefFile=>'X86',
        Generic=>1,
        SMP=>1,
        StatLink=>'X86SMP',
    },
    X86GCC=>{
        ABI=>'X86gcc',
        ASSPABI=>'',
        Compiler=>'X86GCC',
        CPU=>'X86',
        MakeMod=>'Cl_x86gcc',
        OS=>'EPOC32',
        DefFile=>'x86gcc',
        Generic=>1,
    },  
    X86GMP=>{
        ABI=>'X86gcc',
        ASSPABI=>'',
        Compiler=>'X86GCC',
        CPU=>'X86',
        MakeMod=>'Cl_x86gcc',
        OS=>'EPOC32',
        DefFile=>'x86gcc',
        Generic=>1,
        SMP=>1,
        StatLink=>'X86GMP',
    },  
    ARMV4=>{
        ABI=>'ARMV4',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        MakeMod=>'Cl_arm',
        Compiler=>'ARMCC',
        DefFile=>'EABI',
        EABI=>1,
    },
    ARMV4SMP=>{
        ABI=>'ARMV4',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        MakeMod=>'Cl_arm',
        Compiler=>'ARMCC',
        DefFile=>'EABI',
        EABI=>1,
        SMP=>1,
        StatLink=>'ARMV4SMP',
    },
    ARMV5_ABIV1=>{
        ABI=>'ARMV5',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        MakeMod=>'Cl_arm',
        Compiler=>'ARMCC',
        DefFile=>'EABI',
        EABI=>1,
        SupportsFeatureVariants=>1,
    },
    ABIV2=>{
        ABI=>'ARMV5',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        MakeMod=>'Cl_bpabi',
        DefFile=>'EABI',
        EABI=>1,
        SupportsFeatureVariants=>1,
    },
    GCCXML=>{
        ABI=>'ARM4',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        MakeMod=>'cl_gccxml',
    },
    VS6=>{
        ABI=>'WINSCW',
        ASSPABI=>'',
        Compiler=>'CW32',
        CPU=>'WINS',
        MakeMod=>'Cl_vscw',
        OS=>'WINS',
        Real=>'WINSCW',
        DefFile=>'WINS',    # use the MSVC def files
        Ext=>'.mak'     
    },
    VS2003=>{
        ABI=>'WINSCW',
        ASSPABI=>'',
        Compiler=>'CW32',
        CPU=>'WINS',
        MakeMod=>'Cl_vscw',
        OS=>'WINS',
        Real=>'WINSCW',
        DefFile=>'WINS',    # use the MSVC def files
        Ext=>'.mak'
    },
    EDG=>{
        ABI=>'ARMV5',
        ASSP=>'MARM',
        ASSPABI=>'',
        Generic=>1,
        MakeMod=>'cl_edg',
    },

    # ASSP platforms should be described using .ASSP files
    # Do not add additional ASSP platforms to this file.
);

my $init_bsfs_done = 0;
my $init_plat_done = 0;
my @PlatList;       # Platlist returned by list_plat()

# initialize BSF platforms into %Plat
sub init_bsfs($) {
    return $init_bsfs_done if ($init_bsfs_done);
        
    my ($Path)=@_;  
#   get a list of modules
    opendir DIR, $Path;
    my @BSFs=grep s/^([^\.].*)\.BSF$/$1/, map { uc $_ } sort readdir DIR;
    closedir DIR;

    my $BSF;
    foreach $BSF (@BSFs) {
        my $File=$Path.lc($BSF).'.bsf';
#       check whether the assp is already defined
        if (defined %{$Plat{$BSF}}) {
            warn(
                "$File : warning: Platform \"$BSF\" already defined\n",
                " ... skipping this spec\n"
            );
            delete $Plat{$BSF};
            next;
        }
#       open the module
        unless (open FILE, $File) {
            delete $Plat{$BSF};
            warn "warning: Can't open BSF specification \"$File\"\n";
            next;
        }
        my $line1 = <FILE>;
        $line1 = uc($line1);
        unless ($line1 =~ /^\#\<BSF\>\#/) {
            warn "warning: \"$File\" Invalid BSF specification - missing #<bsf>#\n";
            delete $Plat{$BSF};
            close FILE;
                  next;
        }
        my $custom;
        while ($custom = <FILE>) {
            #skip blank lines and comments
            delete $Plat{$BSF};
            last unless ($custom =~ /^$|^\#/);
        }
        $custom = uc $custom;
        unless ($custom =~ /^\s*CUSTOMIZES\s+(\S+)/) {
            warn "warning: \"$File\" Invalid BSF specification - 'customizes' missing\n";
            delete $Plat{$BSF};
            close FILE;
            next;
        }
        my $root = $1;
        my $platname = '';
        my $CustomizedPlatName = '';        

        # In v1 mode, ARMV5 platform implies ARMV5_ABIV1 platform listed in the platlist        
        my $Armv5Flag = 0;
        if (!$variantABIV2Keyword && $root =~ /^ARMV5$/i) {
            $Armv5Flag = 1;
        }

        # Support for Hierarchy of Customizations (BSF file customization of another BSF file)
        # 1. Check whether the BSF file customizes another BSF file.
        # 2. If so, check whether the root BSF file has already been read.
        # 3. If not read, then defer the current BSF file reading until the root file is read.
        my $rootPlatFound = 0;
        if (defined %{$Plat{$root}} || $Armv5Flag) 
        {
            # BSF platform customizes another valid BSF platform
            if (defined $Plat{$root}{'CUSTOMIZES'}) 
            {
                $rootPlatFound = 1;
                $platname = $root;
                $CustomizedPlatName = $root;

                # Set the root platform name which is same as of customizes platform
                $Plat{$BSF}{'ROOTPLATNAME'} = $Plat{$root}{'ROOTPLATNAME'};
            }
            # BSF platform customizes to one of the existing ABI platforms
            else
            {
                # All BPABI platforms inherits from ABIV2 platform listed in the platlist
                if (grep /^$root$/i, @BPABIPlats) {
                    $platname = "ABIV2";
                }
                elsif ($Armv5Flag) {
                # In v1 mode, ARMV5 platform implies ARMV5_ABIV1 platform listed in the platlist
                    $platname = "ARMV5_ABIV1";  
                }
                else {
                    $platname = $root;
                }
                
                $CustomizedPlatName=$root;

                # BSF File check Begins 
                # The following check is included to handle the existing BSF files which has to behave in different manner
                # in default v1 mode and v2 mode. The following code changes the BSF name and the custmoized platform name
                # to the implied names. This is done to support switching between v1 and v2 modes by enabling the keyword in
                # the variant configuration file.
                # In v1 mode, the ARMV6_ABIV1 => ARMV6 platform and ARMV6 => ARMV6_ABIV2 platform.
                if (!$variantABIV2Keyword) {
                    if ($BSF =~ /^ARMV6_ABIV1$/i) {
                        $BSF = "ARMV6"; 
                        $CustomizedPlatName = "ARMV5";  
                    }
                    elsif ($BSF =~ /^ARMV6$/i) {
                        $BSF = "ARMV6_ABIV2";   
                        $CustomizedPlatName = "ARMV5_ABIV2";
                        $platname = "ABIV2";
                    }
                }
                # BSF File check Ends

                # Set the root platform name
                $Plat{$BSF}{'ROOTPLATNAME'} = $CustomizedPlatName;
            }           
        }
        else
        {
            my $rootbsf = $Path.$root.".bsf";           
            if ( -e $rootbsf ) {
                # BSF file customizes another BSF file which has not been read yet.
                # So defer current BSF file reading until the root BSF file is read.                
                delete $Plat{$BSF};
                push(@BSFs, $BSF);
                next;       
            }
        }
        # If the customizes platform is not a valid BSF platform or BPABI platorm or ARMV5 or ARMV5_ABIV1,
        # then throw warning.
        unless ($rootPlatFound || $root =~ /^ARMV5(_ABIV1)?$/ || (grep /^$root$/i, @BPABIPlats)) {
            warn "warning: \"$File\" Invalid BSF specification - customization restricted to ARMV5, ABIv2 and valid BSF platforms\n";
            close FILE;
            delete $Plat{$BSF};
            next;
        }
            
        my ( $key, $value);
        while (($key, $value) = each %{$Plat{$platname}}) {
            $Plat{$BSF}{$key}=$value;
        }
        
        push @{$Plat{$CustomizedPlatName}{'CUSTOMIZATIONS'}}, $BSF;
        $Plat{$BSF}{'CUSTOMIZES'} = $CustomizedPlatName;
        while (<FILE>) {
            next if (/^$|^\#/);
            if (/^\s*SMP\s*$/i) {
                $Plat{$BSF}{'SMP'} = 1;
                $Plat{$BSF}{'StatLink'} = lc $BSF;
                next;
            }
            $Plat{$BSF}{'CUSTOMIZATION_DATA'} .= $_;
        }
        # BSF file statements will have newline character("\n") at the end, except for the last statement.
        # So append "\n" for the last BSF file statement.
        # "\n" will be used to split BSF statements to support hierarchy of customizations.
        $Plat{$BSF}{'CUSTOMIZATION_DATA'} .= "\n";
        close FILE;
    }
    $init_bsfs_done = 1;
}

# setup Plat with bpabi platforms
sub init_platwithbpabi() 
{
    foreach my $Candidate (&get_bpabiplatlist)
    {
# All BPABI platforms inherit from ABIV2 properties as listed in the platlist
# and Platlist is updated to include the BPABI platforms.
        my ( $key, $value);
        while (($key, $value) = each %{$Plat{ABIV2}}) {
            $Plat{$Candidate}{$key}=$value;
        }
    }
}

# initialize %Plat with BSF/Bpabi/ASSP
sub init_plat ($) { # takes path to ASSP modules
    
    return $init_plat_done if ($init_plat_done);
    
    my ($Path)=@_;

    my %PlatHashKeys=(
        ABI=>1,
        ASSPABI=>1,
        SINGLE=>1,
        Compiler=>1,
        CPU=>1,
        MakeMod=>1,
        MakeCmd=>1,
        OS=>1,
        DefFile=>1,
        ASSP=>1,
    );

#   Include the list of BPABI platforms
    &init_platwithbpabi;

    init_bsfs($Path);

#   get a list of modules
    opendir DIR, $Path;
    my @_ASSPs=grep s/^([^\.].*)\.ASSP$/$1/, map { uc $_ } readdir DIR;
    closedir DIR;

    my @ASSPs;
    foreach (@_ASSPs) {
        next if (!$ENV{USEARMCC} and /EDG$/i);
        push @ASSPs, $_;
    }

#   open each module in turn, and add it to the array
    my $ASSP;
    foreach $ASSP (@ASSPs) {
        my $File=$Path.$ASSP.'.assp';
#       check whether the assp is already defined
        if (defined %{$Plat{$ASSP}}) {
            warn(
                "$File : warning: ASSP \"$ASSP\" already defined\n",
                " ... skipping this module\n"
            );

            next;
        }
#       open the module
        unless (open FILE, $File) {
            warn "warning: Can't open assp module \"$File\"\n";
            next;
        }
        my %Data=();
        my %SingleData=();
        my $MatchingSingle="";
        my @Errors=();
        while (<FILE>) {
#           strip comments
            s/^([^#]*)#.*$/$1/o;
#           skip blank lines
            if (/^\s*$/o) {
                next;
            }
#           get the key-value pair
            unless (/^\s*(\w+)\s+(\w+)\s*$/o) {
                push @Errors, "$File($.) : warning: syntax error - only key-value pairs allowed\n";
                next;
            }
            my ($Key, $Val)=($1, $2);
            if ($PlatHashKeys{$Key}!=1) {
                push @Errors, "$File($.) : warning: unrecognized keyword - $Key\n";
                next;
            }
            if ($Key eq "SINGLE") {
                $SingleData{Single} = 1;
                $SingleData{ASSP} = $ASSP;
                $MatchingSingle = uc $2;
            } else {
                $Data{$Key}=$Val;
                $SingleData{$Key}=$Val;
            }
        }
        close FILE;
        if (@Errors) {
            warn(
                @Errors,
                " ... skipping this module\n"
            );
            next;
        }
# change -  Allow ASSPs to pick up all the options of the ABI they specify, 
# in particular the compiler they need.
            $Data{'ASSP'} = $ASSP unless $Data{'ASSP'};
            if ($Plat{$Data{'ABI'}}) {
            foreach (keys %{$Plat{$Data{'ABI'}}}) {
            $Data{$_} = $Plat{$Data{'ABI'}}{$_} unless ($_ =~ /^GENERIC$/i) or $Data{$_};
            }
        }

        %{$Plat{$ASSP}}=%Data;
        if ($MatchingSingle ne "") {
            foreach (keys %Data) {
            $SingleData{$_} = $Data{$_} unless ($_ =~ /^GENERIC$/i) or $SingleData{$_};
            }
            %{$Plat{$MatchingSingle}}=%SingleData;
        }           
    }
    $init_plat_done=1;
}

#   return list of supported platforms
#   should be invoked atfer init_plat
sub get_platlist () {

    return @PlatList if (scalar(@PlatList));

    &init_plat;

    my $Key;
    foreach $Key (keys %Plat) {
        if (!$variantABIV2Keyword && $Key =~ /^armv5_abiv1$/i) {
            $Key = 'ARMV5';
        }
        unless (grep /^$Key$/i, @PlatList) {
            push @PlatList, $Key;
        }
    }
    return @PlatList
}

# return customizes BSF plat if any
sub get_platcustomizes($) {
    my ($plat) = @_;
    return $Plat{$plat}{'CUSTOMIZES'} ? $Plat{$plat}{'CUSTOMIZES'} : "";
}

# return root of a specific plat
sub get_platroot($) {
    my ($plat) = @_;

    my $RootName = $Plat{$plat}{'ROOTPLATNAME'};

    if ($RootName) {
        return $RootName;
    }
    else {
        # A non-BSF platform is its own root.
        return $plat;
    }
}

#################################
# featurevariant map functions
#
# copy from featurevariantmap.pm

my $featureListDir = "${epocroot}epoc32\/include\/variant\/featurelists";

# Usage:    get_BVbinname("my.dll", "myvar")
#
# Look for a binary using its "final" name. We will use the feature
# variant map and the feature variant name to deduce the "variant"
# binary name and test for its existence.
#
# "my.dll"  - the final target (full path)
# "myvar"   - the feature variant name
#
# returns the file name if found, or "" otherwise.

sub get_BVbinname
{
    my $binName = shift;
    my $varName = shift;

    # look for the vmap file
    my $vmapFile = "$binName.$varName.vmap";
    
    if (! -e $vmapFile)
    {
    	# compatible to old BV
    	$vmapFile = "$binName.vmap";
    }
    
    if (-e $vmapFile)
    {
        my $key = get_vmapkey($varName, $vmapFile);

        if ($key)
        {
            $binName =~ /^(.*)\.([^\.]*)$/;
            $binName = "$1.$key.$2";
        }
        else
        {
            print "ERROR: No \'$varName\' variant for $binName in $vmapFile\n";
            return "";  # file not found
        }
    }

    # check that the actual binary exists
    if (-e $binName)
    {
        return $binName;
    }
    return "";  # file not found
}

# internal functions
sub get_vmapkey
{
    my @res = get_vmapdata(@_);
    return $res[0];
}

# Usage:    featurevariantmap->GetDataFromVMAP("myvar", "mydll.vmap")
#
# Opens the vmap file indicated and returns the data for the requested variant
#
# "myvar"   - the feature variant name
# "my.vmap" - the final target vmap file (full path)
#
# Returns a list ( hash, features ) for the variant in the vmap or undef if not found

sub get_vmapdata
{
    my $varName = shift;
    my $fileName = shift;

    if (!open(VMAP, $fileName))
    {
        print "ERROR: Could not read VMAP from $fileName\n";
        return "";
    }
    while (<VMAP>)
    {
        chomp;
        if (/(\w{32})\s+$varName\s+(.*)$/i or /(\w{32})\s+$varName$/i)
        {
            my ( $hash, $features ) = ( $1, $2 ? $2 : '' );
            close(VMAP);
            return ( $hash, $features );
        }
    }
    close(VMAP);
    return;
}

######################################
# Feature variant parser
#
# copy from featurevariantparser.pm
#


# Parses .VAR files and returns key variables.
# The following hashes can be used with this module:
# NAME              -> Returns the name of the variant file (without the extension)
# FULLPATH          -> Returns the full path of the variant file (including the extension)
# VALID             -> Set to 1 if the variant file is valid, otherwise set to 0
# VIRTUAL           -> Set to 1 if the variant is a grouping node, otherwise set to 0
# ROM_INCLUDES      -> Returns a pointer to the list of ROM_INCLUDES (including Parent nodes).
# VARIANT_HRH       -> Returns the full VARIANT_HRH file path used by the VAR file.


my $defaultDir = "${epocroot}epoc32\/tools\/variant";
my $pathregex = '.+[^\s]'  ;   # Regex to match all characters (including \ or /), excluding whitespaces.

my @rominclude;
my @parents;
my @childNodes;
my $virtual;
my $childNodeStatus;
my $varianthrh;

my $dir;        #var directory
my $fullpath;   #full path of var file
my $fulldir;    #

# Wrapper function to return all the correct variables
# Arguments : (Variant Name, Variant Directory(optional))
# Returns a Hash.
sub get_variant
{
    @rominclude      = ();
    @parents         = ();
    @childNodes      = ();
    $dir             = "";
    $fullpath        = "";
    $varianthrh      = "";
    $virtual         = 0;
    $childNodeStatus = 0;
    
    
    my %data;
    my $romincs   = "";
    
    $data{'VALID'} = 0;

    my ( $varname, $dirname ) = @_;

    my $fullvarpath = get_variantfullpath( $varname, $dirname );

    if ( $dirname )
    {
        $fulldir = $dirname;
    }
    else
    {
        $fulldir = $defaultDir;
    }

    $data{'FULLPATH'} = "$fullvarpath";
    $data{'NAME'}     = "$varname";

    # If the variant file exists, check the syntax and setup variables.
    if ( -e $fullvarpath )
    {
        if ( check_varfile( $fullvarpath, $varname ) )
        {
            $data{'VALID'} = 1;
        }
    }
    else
    {
        print "ERROR: $fullvarpath" . " does not exist\n";
    }

    my $count = 0;

    # If VAR file is valid, setup all other variables.
    if ( $data{'VALID'} )
    {

        $romincs   = find_varrominc($fullvarpath);
        
        # Remove empty elements from the ROM_INCLUDE list
        @$romincs = grep /\S/, @$romincs;

        # Fix paths for all ROM_INCLUDES
        for ( my $i = 0 ; $i < scalar(@$romincs) ; $i++ )
        {
            @$romincs[$i] = get_fixpath( @$romincs[$i] );
        }

        $data{'ROM_INCLUDES'}   = clone_list($romincs);
        $data{'VARIANT_HRH'}    = $varianthrh;
        $data{'VIRTUAL'}        = $virtual;
    }

    # If variant file is not valid, return reference to a blank array
    else
    {
        $data{'ROM_INCLUDES'}   = [];
        $data{'VARIANT_HRH'}    = "";
    }

    return %data;
}

# Method to construct a full variant path from the variant file and directory
sub get_variantfullpath
{

    my $vardirectory = $_[1];
    my $varname      = $_[0];
    
    my $dir;
    
    # Check if a directory is supplied
    if ($vardirectory)
    {
        $dir = "$vardirectory";
    }

    else
    {
        $dir = $defaultDir;
    }
    my $filename = "$varname" . "\.var";
    $fullpath = File::Spec->catfile( File::Spec->rel2abs($dir), $filename );

    if ( !File::Spec->file_name_is_absolute($fullpath) )
    {
        $fullpath = File::Spec->rel2abs($fullpath);
    }

    return $fullpath;
}

# Checks the variant file for the correct syntax and reports any errors
# Also sets up some variables(VIRTUAL ,VARIANT_HRH and VARIANT) whilst file is being parsed.

# Usage: check_varfile(<fullpath>,<varfile>) . Note: <varfile> without .var
sub check_varfile
{

    my $fullpath          = $_[0];
    my $varname           = $_[1];
    my $varianthrhpresent = 0;

    open( READVAR, "<$fullpath" );
    my $exp  = "#";
    my $line = "";

    while (<READVAR>)
    {
        s/\r\n/\n/g;

        $line = $.;

    # Checks for a valid argument supplied to EXTENDS keyword. Checks for one and only one argument supplied.
        if (/^EXTENDS/)
        {
            if ( !m/^EXTENDS\s+./ )
            {
                print "\nERROR: Invalid format supplied to argument EXTENDS on line "
                  . "$."
                  . " in file "
                  . "$fullpath";
                return 0;
            }
            my $str = get_extends($_);
            if ( $str =~ /\s+/ )
            {
                print "\nERROR: Cannot extend from two nodes. Error in line "
                  . "$."
                  . " in file "
                  . "$fullpath";
                return 0;
            }

            $childNodeStatus = 1;
        }

        # Checks for the grammar of BUILD_INCLUDE, i.e. KEYWORD MODIFIER VALUE
        elsif (/^BUILD_INCLUDE/)
        {
            # skip build inc checking
        }

        # Checks for the grammar of ROM_INCLUDE, i.e. KEYWORD MODIFIER VALUE
        elsif (/^ROM_INCLUDE/)
        {

            if (!m/^ROM_INCLUDE\s+(append|prepend|set)\s+$pathregex/)
            {
                print "\nERROR: Invalid syntax supplied to keyword ROM_INCLUDE on line "
                  . "$."
                  . " in file "
                  . "$fullpath";
                return 0;
            }

            if (m/^ROM_INCLUDE\s+(append|prepend|set)\s+$pathregex\s+$pathregex/)
            {
                print "\nERROR: Too many arguments supplied to keyword ROM_INCLUDE on line "
                  . "$."
                  . " in file "
                  . "$fullpath";
                return 0;
            }
        }

        # Checks for a valid VARIANT name
        elsif (/^VARIANT[^_HRH]/)
        {
            if ( !m/^VARIANT\s+\w+/ )
            {
                print "\nERROR: VARIANT name not specified on line " . "$."
                  . " in file "
                  . "$fullpath";
                return 0;
            }
            if ( uc("$varname") ne uc( get_variantname($_) ) )
            {
                print "\nERROR: VARIANT filename does not match variant name specified on line "
                  . "$line"
                  . " in file "
                  . "$fullpath"
                  . "\nVariant value extracted from the VAR file is " . "$_";
            }

        }

        # Checks that keyword VIRTUAL is declared correctly
        elsif (/^VIRTUAL/)
        {
            if (m/^VIRTUAL\s+\w+/)
            {
                print "\nERROR: Invalid declaration of VIRTUAL on line " . "$."
                  . " in file "
                  . "$fullpath";
                return 0;
            }

            $virtual = 1;
        }

        # Checks if VARIANT_HRH is declared correctly.
        elsif (/^VARIANT_HRH/)
        {
            $varianthrhpresent = 1;
            my $lineno = $.;
            if ( !m/^VARIANT_HRH\s+./ )
            {
                print "\nERROR: Invalid format supplied to argument VARIANT_HRH on line "
                  . "$lineno"
                  . " in file "
                  . "$fullpath";
                return 0;
            }

            my $str = get_hrhname($_);
            if ( $str =~ /\s+/ )
            {
                print "\nERROR: Cannot have 2 or more hrh files. Error in line "
                  . "$lineno"
                  . " in file "
                  . "$fullpath";
                return 0;
            }

            unless( -e get_fixpath($str) )
            {
                print "\nERROR: VARIANT HRH file : "
                  . get_fixpath($str)
                  . " specified on line "
                  . "$lineno"
                  . " does not exist";
                return 0;
            }

            $varianthrh = get_fixpath( get_hrhname($_) );

        }
        
        # If none of the valid keywords are found
        else
        {

            # Do nothing if a comment or blank line is found
            if ( (m/$exp\s+\S/) || (m/$exp\S/) || ( !m/./ ) || (m/^\n/) )
            {
            }

            # Unsupported keyword
            else
            {

                print "\nERROR: Invalid keyword " . '"' . "$_" . '"'
                  . " found on line " . "$."
                  . " in file "
                  . "$fullpath";
                return 0;
            }
        }
    }

    close(READVAR);

    # If no HRH file defined, check if the default one exists
    if ( !$varianthrhpresent )
    {
        print "\nINFO: No VARIANT_HRH defined in VAR file, using ${epocroot}epoc32\/include\/variant\/$varname\.hrh" if ($verbose);
        my $str =
          get_hrhname(
            "VARIANT_HRH ${epocroot}epoc32\/include\/variant\/$varname\.hrh"
          );

        if ( ! -e $str )
        {
            print "\nERROR: VARIANT HRH file : " . "$str " . "does not exist\n";
            return 0;
        }
        else
        {
            $varianthrh = $str;
        }
    }
    return 1;
}

# Extract the value of the VARIANT keyword
sub get_variantname
{

    $_[0] =~ m/^VARIANT\s+(\w+)/i;
    return $1;
}

# Extracts the value of the HRH file from the VARIANT_HRH line supplied
sub get_hrhname
{

    $_[0] =~ m/^VARIANT_HRH\s+($pathregex)/;
    return $1;

}

# Method to find the immediate parent node of a child node
sub get_extends
{

    $_[0] =~ m/^EXTENDS\s+(\w+)/;
    return $1;
}


# Method to correct all the slashes, and also append EPOCROOT if the path begins with a \ or /
# If path doesn't start with \ or /, returns an abosulte canonical path
sub get_fixpath
{

    my $arr = $_[0];

    if ( $arr =~ m/^\// )
    {
       $arr =~ s/^\/?//;
        return File::Spec->canonpath( "$epocroot" . "$arr" );
    }

    elsif ( $arr =~ m/^\\/ )
    {
        $arr =~ s/^\\?//;
        return File::Spec->canonpath( "$epocroot" . "$arr" );
    }

    else
    {
        return File::Spec->rel2abs( File::Spec->canonpath("$arr") );
    }

}

# Method to find the ROMINCLUDE values of the VAR file.
sub find_varrominc
{

    my $filename = $_[0];

    my $parentNodes;

    # Construct a list of parent nodes if node is a child
    if ($childNodeStatus)
    {
        $parentNodes = find_varparentnode("$filename");
    }

    if ($parentNodes)
    {

        # Go through and build the list of all parent ROM_INCLUDES
        for ( my $i = scalar(@$parentNodes) - 1 ; $i >= 0 ; $i-- )
        {
            my $t = get_variantfullpath( @$parentNodes[$i], $fulldir );
            open( NEWHANDLE, "<$t" );

            while (<NEWHANDLE>)
            {
                if (/ROM_INCLUDE/)
                {
                    get_varrominc($_);
                }
            }
            close(NEWHANDLE);
        }
    }

    # Append the ROM_INCLUDES of the VAR file in the end
    open( NEWHANDLE, "<$filename" );

    while (<NEWHANDLE>)
    {
        if (/ROM_INCLUDE/)
        {
            get_varrominc($_);
        }
    }

    undef(@parents);    # Flush out parent array;
    return \@rominclude;

}

# Constructs a list of Parent nodes for a given Child node.
sub find_varparentnode
{

    my $filename   = $_[0];
    my $hasparents = 0;

    open( READHANDLE, "<$filename" );
    while (<READHANDLE>)
    {
        if (/EXTENDS/)
        {
            $hasparents = 1;
            push( @parents, get_extends($_) );

        }
    }

    close(READHANDLE);

    if ( $hasparents == 1 )
    {
        find_varparentnode(
            get_variantfullpath( @parents[ scalar(@parents) - 1 ], $fulldir )
        );
    }
    else
    {
        return \@parents;
    }

}

# Method to extract the ROM_INCLUDE value of a node.
sub get_varrominc
{

# If modifier append is found, push the rominclude to the end of the array list.
    if (/^ROM_INCLUDE\s+append\s+($pathregex)/)
    {
        push( @rominclude, ($1) );
    }

# If modifier prepend is found, push the rominclude to the beginning of the array list.
    if (/^ROM_INCLUDE\s+prepend\s+($pathregex)/)
    {
        unshift( @rominclude, ($1) );
    }

# If keyword set is found, then empty the rominclude variable and push the new value
    if (/^ROM_INCLUDE\s+set\s+($pathregex)/)
    {
        undef(@rominclude);
        push( @rominclude, ($1) );
    }

}

# Helper method that clones a reference to a simple list
sub clone_list
    {
    my $ref = shift;
    
    # Check the reference is a list
    die "Not a list ref" if ref($ref) ne 'ARRAY';
    
    # Create a new list object
    my @list;
    foreach my $entry ( @$ref )
        {
        # Only clone lists of scalars
        die "Not a scalar" if ref($entry);
        
        # Add the entry to the new list
        push @list, $entry;
        }
    
    # return a reference to the copy    
    return \@list;
    }
    
##############################
#  write helper
#
# copy from writer.pm
sub write_32bit # little-endian
{
    my $fileHandle=shift;
    my $integer=shift;
    &write_8bit($fileHandle, $integer&0x000000ff);
    &write_8bit($fileHandle, ($integer>>8)&0x000000ff);
    &write_8bit($fileHandle, ($integer>>16)&0x000000ff);
    &write_8bit($fileHandle, ($integer>>24)&0x000000ff);
}

sub write_8bit
{
    my $fileHandle=shift;
    my $integer=shift;
    if ($integer&0xffffff00)
    {
        die("Error: the integer ".sprintf("0x%08x", $integer)." is too large to write into 8 bits\n");
    }
    printf $fileHandle "%c", $integer;
}


1;

