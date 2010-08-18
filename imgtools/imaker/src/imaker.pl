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
# Description: iMaker main Perl script & common routines
#



#
$(error |MAKE=$(MAKE)|MAKE_VERSION=$(MAKE_VERSION)|SHELL=$(SHELL)|MAKECMDGOALS=$(MAKECMDGOALS)|)
#
#!perl
#line 24

use subs qw(CORE::GLOBAL::die);

use strict;
use warnings;
use Cwd;
use Digest::MD5 qw(md5_hex);
use File::Basename;
use File::Copy;
use File::Find;
use File::Path;
use File::Spec;
use File::Temp qw(tempfile);
use POSIX qw(strftime);
use Text::ParseWords;
use Time::Local;

sub InitMkglobals();
sub PrintEnv($);
sub Max(@);
sub Min(@);
sub Trim($;$);
sub Quote($);
sub Unquote($);
sub Int2Hex($;$);
sub Byte2Str($@);
sub Str2Byte($);
sub Str2Xml($);
sub Ascii2Uni($);
sub Uni2Ascii($);
sub GetTimestamp();
sub Sec2Min($);
sub Wcard2Restr($);
sub Wcard2Regex($);
sub ParseCmdWords($);
sub DPrint($@);
sub Echo($$$);
sub PathConv($;$$$);
sub ParseFiles($);
sub GlobFiles($;$);
sub GetBasename($);
sub GetDirname($);
sub GetAbsDirname($;$$$);
sub GetAbsFname($;$$$);
sub GetRelFname($;$$);
sub GetWriteFname($);
sub GetFreeDrive(;$);
sub SubstDrive($$);
sub UnsubstDrive($);
sub Search($$$$$$\@\$);
sub Find($$$$$\$);
sub ChangeDir($);
sub DeleteDir($;$);
sub FindDir($$$$);
sub MakeDir($);
sub MakeChangeDir($);
sub SetWorkdir($);
sub OpenFile(*$$;$);
sub Test($);
sub CutFile($$$$$);
sub Copy($$;$);
sub CopyIby($$);
sub DeleteFile($;$);
sub FindFile($$$$);
sub HeadFile($$$);
sub TailFile($$$);
sub TypeFile($;$);
sub ReadFile($$);
sub WriteFile($$$;$$);
sub UnzipFile($$);
sub Zip($$$$@);
sub Move($$);
sub Touch($@);
sub SetLogfile($);
sub RunSystemCmd($;$$$);
sub ParseSystemCmd($$$$$);
sub GenExclfile($$$$$);
sub GenIbyfile($$$);
sub GenObyfile($$$$@);
sub GenMakefile($$$$$);
sub GenWidgetConf($$$$);
sub AddImageHeader($$$$$);
sub Sleep($);
sub FindSOSFiles($$$$);
sub CheckTool(@);
sub OpCacheInstall($$$);
sub SisInstall($$$$$$$$);
sub GetIPar(;$);
sub PEval($);
sub PeekICmd($);
sub SkipICmd();
sub GetICmd();
sub EndICmd();
sub SplitStep($);
sub RunStep($);
sub RunIExtCmd($);
sub GetConfmkList(;$);
sub GetFeatvarIncdir($);
sub SetVerbose($;$);
sub CloseLog();
sub RunIMakerCmd($$$$$@);
sub RunMakeCmd($$);
sub HandleCmdArg($);
sub HandleExtCmdArg($);
sub MenuRuncmd($);
sub Menu($);
sub Install($$$);

use constant READBUFSIZE => 2097152;  # 2 MB
use constant STARTSTR => '>>>[START]=========8<==========8<==========8<==========8<==========8<==========';
use constant ENDSTR   => '==========>8==========>8==========>8==========>8==========>8===========[END]<<<';

# device[VARID]==... !!
#
use constant BOOTBINARYSTATEMENT => qr/^\s*bootbinary\s*(?:=+|\s)\s*(?:"(.+?)"|(\S+))/i;

use constant FILESPECSTATEMENT =>
    qr/^\s*(?:data|device|dll|extension|file|primary|secondary|variant)\S*?\s*(?:=+|\s)\s*(?:"(.+?)"|(\S+))\s+(?:"(.+?)"|(\S+))(\s+.+?)?\s*$/i;

our ($gArgv, $gCmdcnt, @gCmdoutbuf, %gConfmkList, $gEpocdrive, $gEpocroot, $gError, $gErrwarn, $gEvalerr,
    %gExportvar, $gFiltercmd, @gFindresult, $gICmd, @gIcmd, $gImakerext, $gImgtype, $gKeepgoing, @gLogbuf,
    $gLogfile, %gLogfiles, $gMakecmd, @gMakeinfo, $gOutfilter, $gParamcnt, $gPrintcmd, @gReport, $gStartmk,
    $gStarttime, $gStep, @gStepDur, %gStepIcmd, %gSubstdrv, $gTgterr, %gTool, $gVerbose, $gWinOS, $gWorkdir,
    $gWorkdrive, @iVar);


###############################################################################
#

sub InitMkglobals()
{
    $gCmdcnt     = 0;
    @gCmdoutbuf  = ();
    $gFiltercmd  = qr/\S/;
    @gFindresult = ();
    $gICmd       = "";
    @gIcmd       = ();
    $gImgtype    = "";
    $gOutfilter  = "";
    $gParamcnt   = 0;
    $gPrintcmd   = 0;
    $gStep       = "";
    @gStepDur    = ();
    %gStepIcmd   = ();
    @iVar        = ();  # General purpose variable to be used from $(call peval,...)
}

BEGIN {
    ($gArgv, $gEvalerr, $gStarttime, $gWinOS) = (scalar(@ARGV), 0, time(), $^O =~ /MSWin/i);
    $_ = "default input and pattern-searching space";
    eval("use Archive::Zip qw(:ERROR_CODES)");
    eval("use constant AZ_OK => -1") if $@;
    eval("use Archive::Zip::Tree");
    if ($gWinOS) { eval("
        use Win32API::File qw(:DDD_);
        use Win32::File;
        use constant WIN32_FILE_HIDDEN => Win32::File::HIDDEN");
    } else { eval("
        use constant DDD_REMOVE_DEFINITION => -1;
        use constant WIN32_FILE_HIDDEN => -1");
    }
}

INIT {
    $gWorkdir   = Cwd::cwd();
    $gWorkdrive = ($gWorkdir =~ /^([a-z]:)/i ? uc($1) : "");
    $ENV{EPOCROOT} = ($gWinOS ? "\\" : "$gWorkdir/") if !$ENV{EPOCROOT};
    $ENV{IMAKER_CMDARG} = "" if !defined($ENV{IMAKER_CMDARG});
    $ENV{IMAKER_CYGWIN} = 0 if !$ENV{IMAKER_CYGWIN};

    InitMkglobals();
    %gConfmkList = ();
    $gEpocdrive  = ($ENV{EPOCROOT} =~ /^([a-z]:)/i ? uc($1) : $gWorkdrive);
    ($gEpocroot  = GetAbsDirname($ENV{EPOCROOT})) =~ s/\/+$//;
    $gError      = 0;
    $gErrwarn    = 0;
    %gExportvar  = (); $gExportvar{""} = 0;
    $gKeepgoing  = 0;
    @gLogbuf     = ();
    $gLogfile    = "";
    %gLogfiles   = ();
    $gMakecmd    = "";
    @gMakeinfo   = ("?", "?", "?");
    @gReport     = ();
    $gStartmk    = 0;
    %gSubstdrv   = ();
    $gTgterr     = 0;
    %gTool       = (); map{ $gTool{$_} => $_ } ("cpp", "elf2e32", "interpretsis", "opcache", "unzip");
    $gVerbose    = 1;

    select(STDERR); $|++;
    select(STDOUT); $|++;

    # Overload die
    *CORE::GLOBAL::die = sub {
        $gError = 1 if !$gEvalerr;
        return if (PeekICmd("iferror") && !$gEvalerr);
        CORE::die(@_) if ($gEvalerr || !$gKeepgoing);
        $gErrwarn = 1;
        warn(@_);
    };

    # Handler for __DIE__ signal
    $SIG{__DIE__} = sub {
        return if $gEvalerr;
        $gErrwarn = 1;
        warn(@_);
        exit(1);
    };

    # Handler for __WARN__ signal
    $SIG{__WARN__} = sub {
        if (($gEvalerr != 1) && ($gKeepgoing < 3) && ($_[0] ne "\n")) {
            select(STDERR);
            my $msg = ($gStep ? "($gStep): " : "") . $_[0];
            if ($gErrwarn && ($gKeepgoing < 2)) {
                   DPrint(0, "*** Error: $msg") }
            else { DPrint(127, "Warning: $msg") }
            select(STDOUT);
        }
        $gErrwarn = 0;
    };

    if (!$gArgv) {
        warn("iMaker is running under Cygwin!\n")
            if (!$ENV{IMAKER_CYGWIN} && $^O =~ /cygwin/i);
        my $perlver = sprintf("%vd", $^V);
        warn("iMaker uses Perl version $perlver! Recommended versions are 5.6.1, 5.8.x and 5.10.x.\n")
            if ($perlver !~ /^5\.(?:6\.1|(?:8|10)\.\d+)$/);
    }
}


###############################################################################
# Main program

{
    if ($gArgv) {
        my $iopt = shift(@ARGV);
        print(map("$_\n", GetFeatvarIncdir("@ARGV"))), exit(0) if ($iopt eq "--incdir");
        print(map("$_\n", @ARGV)), exit(0) if ($iopt eq "--splitarg");
        die("Unknown internal imaker.pl option: `$iopt'.\n");
    }

    delete($ENV{MAKE}) if $gWinOS;
    map { delete($ENV{$_}) } qw(MAKECMDGOALS MAKEFILES MAKEFLAGS MAKELEVEL MAKE_VERSION);

    $ENV{CONFIGROOT} = GetAbsDirname($ENV{CONFIGROOT} || "$gEpocroot/epoc32/rom/config");
    $ENV{ITOOL_DIR}  = GetAbsDirname($ENV{ITOOL_DIR}  || "$gEpocroot/epoc32/tools/rom");
    $ENV{IMAKER_DIR} = GetAbsDirname($ENV{IMAKER_DIR});

    $ENV{IMAKER_EXPORTMK}  = "";
    $ENV{IMAKER_MAKE}      = ($gWinOS ? "$ENV{IMAKER_DIR}/mingw_make.exe" : $ENV{MAKE} || "make") if !$ENV{IMAKER_MAKE};
    $ENV{IMAKER_MAKESHELL} = ($ENV{COMSPEC} || "cmd.exe") if (!$ENV{IMAKER_MAKESHELL} && $gWinOS);
    $ENV{IMAKER_MKCONF}    = $ENV{CONFIGROOT} . ',image_conf_(.+?)\.mk$,_(?:ncp)?\d+\.mk$,1' if !$ENV{IMAKER_MKCONF};

    my $pathsep = ($gWinOS ? ";" : ":");
    $ENV{PATH}  = join(";", grep(!/[\\\/]cygwin[\\\/]/i, split(/;+/, $ENV{PATH}))) if (!$ENV{IMAKER_CYGWIN} && $gWinOS);
    ($ENV{PATH} = Trim($ENV{PATH})) =~ s/"$/";/ if $gWinOS;  # http://savannah.gnu.org/bugs/index.php?25412
    $ENV{PATH}  = PathConv("$ENV{ITOOL_DIR}", $gWinOS) . $pathsep . PathConv("$gEpocroot/epoc32/tools", $gWinOS) .
        $pathsep . ($gWinOS ? PathConv("$gEpocroot/epoc32/gcc/bin", 1) . ";" : "") . $ENV{PATH};

    $ENV{PERL5LIB} = $ENV{IMAKER_DIR} . ($ENV{PERL5LIB} ? "$pathsep$ENV{PERL5LIB}" : "");

    die($@) if !defined($gImakerext = do("$ENV{IMAKER_DIR}/imaker_extension.pm")) && $@;

    my ($version, $verfile) = ("", "$ENV{IMAKER_DIR}/imaker_version.mk");
    open(FILE, "<$verfile") and map { $version = $1 if /^\s*IMAKER_VERSION\s*[+:?]?=\s*(.*?)\s*$/ } <FILE>;
    close(FILE);
    if ($version) { DPrint(1, "$version\n") }
    else { warn("Can't read iMaker version from `$verfile'.\n") }

    if ($ENV{IMAKER_CMDARG} =~ /^\s*--?(install|clean)=?(.*?)\s*$/i) {
        Install(lc($1) eq "clean", "$ENV{IMAKER_DIR}/../group/bld.inf", $2);
        exit(0);
    }

    $gMakecmd = "$ENV{IMAKER_MAKE} -R --no-print-directory" .
        ($ENV{IMAKER_MAKESHELL} ? " SHELL=\"$ENV{IMAKER_MAKESHELL}\"" : "");
    my $cmdout = qx($gMakecmd -f "$0" 2>&1);
    ($cmdout = (defined($cmdout) ? $cmdout : "")) =~ s/\n+$//;
    die("Can't run Make properly: `$cmdout'\n")
        if ($cmdout !~ /\|MAKE=(.*?)\|MAKE_VERSION=(.*?)\|SHELL=(.*?)\|/);
    @gMakeinfo = ($1, $2, $3);
    warn(($gMakeinfo[1] eq "" ? "Can't resolve Make version" : "iMaker uses Make version $gMakeinfo[1]") .
        ", recommended version is 3.81.\n") if ($gMakeinfo[1] !~ /^\s*3\.81/);

    RunIMakerCmd("$gMakecmd TIMESTAMP=" . GetTimestamp() .
        " -I \"$ENV{CONFIGROOT}\" -f \"$ENV{IMAKER_DIR}/imaker.mk\"", $ENV{IMAKER_CMDARG}, "", 0, 0, ());
}


###############################################################################
#

sub PrintEnv($)
{
    return if !@gMakeinfo;
    DPrint(shift(), "=" x 79 . "\n" .
        "User        : " . (getlogin() || "?") . "@" . ($ENV{HOSTNAME} || $ENV{COMPUTERNAME} || "?") . " on $^O\n" .
        "Time        : " . localtime() . "\n" .
        "Current dir : `$gWorkdir'\n" .
        "iMaker tool : `$ENV{IMAKER_TOOL}' -> `$0'\n" .
        "Cmdline args: `$ENV{IMAKER_CMDARG}'\n" .
        "Perl        : `$^X' version " . sprintf("%vd\n", $^V) .
        "PERL5LIB    : `$ENV{PERL5LIB}'\n" .
        "PERL5OPT    : `" . (defined($ENV{PERL5OPT}) ? "$ENV{PERL5OPT}'\n" : "'\n") .
        "Make        : `$gMakeinfo[0]' version $gMakeinfo[1]\n" .
        "Make shell  : `$gMakeinfo[2]'\n" .
        "EPOCROOT    : `$ENV{EPOCROOT}'\n" .
        "CONFIGROOT  : `$ENV{CONFIGROOT}'\n" .
        "PATH        : `$ENV{PATH}'\n");
    @gMakeinfo = ();
}

sub Max(@)
{
    my $max = (shift() || 0);
    map { $max = $_ if $_ > $max } @_;
    return($max);
}

sub Min(@)
{
    my $min = (shift() || 0);
    map { $min = $_ if $_ < $min } @_;
    return($min);
}

sub Trim($;$)
{
    (my $str = shift()) =~ s/^\s+|\s+$//g;
    $str =~ s/\s+(?=\s)//g if shift();
    return($str);
}

sub Quote($)
{
    local $_ = shift();
    return("") if !defined();
    s/\\( |n|t)/\\\\$1/g;
    return($_);
}

sub Unquote($)
{
    local $_ = shift();
    return("") if !defined();
    s/(?<!\\)(?<=\\n)\s+(\\n)?//g;
    s/(?<!\\)\s+(?=\\n)//g;
    s/(?<!\\)\\ / /g;
    s/(?<!\\)\\n/\n/g;
    s/(?<!\\)\\t/\t/g;
    s/\\\\( |n|t)/\\$1/g;
    s/\x00//g;
    return($_);
}

sub Int2Hex($;$)
{
    my ($int, $len) = @_;
    return((defined($len) ? $len : ($len = ($int < 4294967296 ? 8 : 16))) < 9 ? sprintf("%0${len}X", $int) :
        sprintf("%0" . ($len - 8) . "X%08X", int($int / 4294967296), $int % 4294967296));  # 4294967296 = 4 G
}

sub Byte2Str($@)
{
    my ($base, @byte) = @_;
    return(join("", map(($_ % 16 ? "" : sprintf("%04X:", $base + $_)) . sprintf(" %02X", $byte[$_]) .
        (!(($_ + 1) % 16) || ($_ == (@byte - 1)) ? "\n" : ""), (0 .. (@byte - 1)))));
}

sub Str2Byte($)
{
    my ($str, $ind, @byte) = (shift(), 0, ());
    $str =~ s/,$/, /;
    map {
        $ind++;
        s/^\s+|\s+$//g;
        if (/^\d+$/ && $_ < 256) {
            push(@byte, $_);
        } elsif (/^0x[0-9A-F]+$/i && hex() < 256) {
            push(@byte, hex());
        } else {
            die("Invalid $ind. byte: `$_'.\n");
            return;
        }
    } split(/,/, $str);
    return(@byte);
}

sub Str2Xml($)
{
    my $str = shift();
    $str =~ s/(.)/{'"'=>'&quot;', '&'=>'&amp;', "'"=>'&apos;', '<'=>'&lt;', '>'=>'&gt;'}->{$1} || $1/ge;
    return($str);
}

sub Ascii2Uni($)
{
    (local $_ = shift()) =~ s/(?<!\r)\n/\r\n/g;  # Use CR+LF newlines
    s/(.)/$1\x00/gs;
    return("\xFF\xFE$_");
}

sub Uni2Ascii($)
{
    (local $_ = shift()) =~ s/(.)\x00/$1/gs;
    s/\r\n/\n/g;
    return(substr($_, 2));
}

sub GetTimestamp()
{
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = localtime();
    return(sprintf("%04d%02d%02d%02d%02d%02d%02d",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec, int(($yday + ($year == 109 ? 3 : -3)) / 7) + 1));
}

sub Sec2Min($)
{
    my $sec = shift();
    return(sprintf("%02d:%02d", $sec / 60, $sec % 60));
}

sub Wcard2Restr($)
{
    (my $wcard = shift()) =~ s/(.)/{"*"=>".*", "?"=>"."}->{$1} || "\Q$1\E"/ge;
    return($wcard);
}

sub Wcard2Regex($)
{
    my $restr = Wcard2Restr(shift());
    return(qr/$restr/i);
}

sub ParseCmdWords($)
{
    my $line = Trim(shift());
    $line =~ s/\\/\\\\/g if $gWinOS;
    return(Text::ParseWords::parse_line('\s+', 0, $line));
}


###############################################################################
#

sub DPrint($@)
{
    my ($verbose, @outlist) = @_;
    map { tr/\x00\x1F/#/ } @outlist;
    print(@outlist) if !$verbose || ($verbose & $gVerbose);
    push(@gLogbuf, @outlist) if ($verbose < 32) || ($verbose & $gVerbose);
    return if ($gLogfile eq "" || !@gLogbuf);
    print(LOG @gLogbuf);
    @gLogbuf = ();
}

sub Echo($$$)
{
    return if SkipICmd();
    my ($verbose, $str) = (shift(), shift());
    DPrint($verbose, shift() ? "$str\n" : Unquote($str));
}


###############################################################################
# File operations

sub PathConv($;$$$)
{
    my $path = shift();
    if (shift()) { $path =~ tr-\/-\\- }
    else { $path =~ tr-\\-\/- }
    return($path) if (!$gWinOS || $path =~ /^(?:\/\/|\\\\)/);
    my $drive = shift();
    return(ucfirst(($path =~ /^[a-z]:/i ? "" : ($_[0] ? $_[0] : $gWorkdrive)) . $path))
        if !$drive;
    $drive = $gWorkdrive if !($drive = shift());
    $path =~ s/^$drive//i;
    return($path);
}

sub ParseFiles($)
{
    my ($file, @files) = (" " . shift() . " ", ());
    push(@files, defined($1) ? $1 : (defined($2) ? $2 : ())) while ($file =~ /\s(?:"\s*"|"+(.+?)"+|((\\\s|\S)+))(?=\s)/g);
    return(@files);
}

sub GlobFiles($;$)
{
    return(@gFindresult) if (my $file = shift()) =~ /^__find__$/i;
    return(map(/[\*\?]/ ? sort({lc($a) cmp lc($b)} grep(!/[\/\\]\.\.?$/,
        glob(scalar(s/\*/\{\.\*\,\*\}/g, /\s/) ? "\"$_\"" : $_))) : $_, (shift() ? $file : ParseFiles($file))));
}

sub GetBasename($)
{
    return((File::Basename::fileparse(shift()))[0]);
}

sub GetDirname($)
{
    (my $dir = shift()) =~ s/^>>?(?!>)//;
    return((File::Basename::fileparse($dir))[1]);
}

sub GetAbsDirname($;$$$)
{
    (my $dir = shift()) =~ s/^>>?(?!>)//;
    $dir = "." if ($dir eq "");
    my $absdir = "";
    eval { local $gEvalerr = 1; $absdir = Cwd::abs_path($dir) };
    return(PathConv($absdir || File::Spec->rel2abs($dir,
        $dir !~ /^$gWorkdrive/i && $dir =~ /^([a-z]:)/i ? "$1/" : ""), shift(), shift(), shift()));
}

sub GetAbsFname($;$$$)
{
    my $file = shift();
    return($file) if ($file eq "" || $file =~ /STD(IN|OUT|ERR)$/);
    my $append = ($file =~ s/^>>(?!>)// ? ">>" : "");
    return($append . PathConv(File::Spec->catpath("", GetAbsDirname(GetDirname($file)), GetBasename($file)), shift(), shift(), shift()));
}

sub GetRelFname($;$$)
{
    my ($file, $base) = (shift(), shift());
    my $append = ($file =~ s/^>>(?!>)// ? ">>" : "");
    ($file = PathConv(File::Spec->abs2rel($file, GetAbsDirname(defined($base) && ($base ne "") ? $base : ".")),
        shift(), 1, "[a-z]:")) =~ s/^[\/\\]+//;
    return("$append$file");
}

sub GetWriteFname($)
{
    (my $file = shift()) =~ s/^>?/>/;
    return($file);
}

sub GetFreeDrive(;$)
{
    my $drives = Win32API::File::GetLogicalDrives();
    for my $drive ("F".."Z", "A".."E") {
        return("$drive:") if !($drives & (2 ** (ord($drive) - ord("A"))));
    }
    return("") if shift();
    die("GetFreeDrive: No free drive available.\n");
}

sub SubstDrive($$)
{
    my ($drive, $path) = (uc(shift()), GetAbsDirname(shift()));
    DPrint(16, "SubstDrive: `$drive' => `$path'\n");
    $gSubstdrv{$drive} = 1, return if !(Win32API::File::GetLogicalDrives() & (2 ** (ord($drive) - ord("A")))) &&
        Win32API::File::DefineDosDevice(0, $drive, $path);
    die("Can't substitute `$drive' => `$path'\n");
}

sub UnsubstDrive($)
{
    return if (my $drive = uc(shift())) eq "";
    DPrint(16, "UnsubstDrive: `$drive'\n");
    delete($gSubstdrv{$drive}), return if Win32API::File::DefineDosDevice(DDD_REMOVE_DEFINITION, $drive, []) &&
        !(Win32API::File::GetLogicalDrives() & (2 ** (ord($drive) - ord("A"))));
    warn("Can't remove substituted drive `$drive'\n");
}

sub Search($$$$$$\@\$)
{
    my ($dir, $basere, $inclre, $exclre, $subdir, $finddir, $files, $total) = @_;
    my @dir = my @file = ();

    opendir(SDIR, $dir) or warn("Can't open directory `$dir'.\n");
    while (local $_ = readdir(SDIR)) {
        next if ($_ eq ".") || ($_ eq "..");
        push(@dir, $_) if ((my $isdir  = !(my $isfile = -f($_ = "$dir/$_")) && -d()) && $subdir);
        next if ($finddir ? $isfile : $isdir);
        ++$$total;
        (my $fname = $_) =~ s/$basere//;
        push(@file, $_) if ($fname =~ /$inclre/) && ($fname !~ /$exclre/) &&
            (($finddir != 2) || !@{[glob((/\s/ ? "\"$_\"" : $_) . "/{[^.],.[^.],.??*,*}")]});
    }
    closedir(SDIR);
    push(@$files, sort({lc($a) cmp lc($b)} @file));

    foreach (sort({lc($a) cmp lc($b)} @dir)) {
        Search($_, $basere, $inclre, $exclre, 1, $finddir, @$files, $$total);
    }
}

sub Find($$$$$\$)
{
    my ($dur, $dir, $inclpat, $exclpat, $subdir, $finddir, $total) = (time(), @_);
    ($dir, $$total) = (GetAbsDirname($dir), 0);
    my ($inclre, $exclre, @files) = ("", "", ());
    if ($inclpat =~ /^\//) {
        $inclre = eval("qr$inclpat");
        $inclpat = "";
    } else {
        $inclre = join("|", map(Wcard2Restr($_), split(/\s+/, $inclpat)));
        $inclre = qr/\/(?:$inclre)$/i;
    }
    if ($exclpat =~ /^\//) {
        $exclre = eval("qr$exclpat");
        $exclpat = "";
    } else {
        $exclre = join("|", map(Wcard2Restr($_), split(/\s+/, $exclpat)));
        $exclre = qr/\/(?:$exclre)$/i;
    }
    DPrint(16, "Find" . ($finddir == 2 ? "EmptyDir" : ($finddir ? "Dir" : "File")) . ": Directory `$dir'" .
        ($subdir ? " and subdirectories" : "") . ", pattern `" . ($inclpat ne "" ? "$inclpat' $inclre" : "$inclre'") .
        ($exclre eq qr/\/(?:)$/i ? "" : " excluding `" . ($exclpat ne "" ? "$exclpat' $exclre" : "$exclre'")));
    foreach (GlobFiles($dir, 1)) {
        Search($_, qr/^$_/i, $inclre, $exclre, $subdir, $finddir, @files, $$total) if -d();
    }
    DPrint(16, ", found " . @files . "/$$total " . ($finddir ? "directories" : "files") .
        ", duration: " . Sec2Min(time() - $dur) . "\n");
    return(@files);
}

sub ChangeDir($)
{
    if ((my $dir = GetAbsDirname(shift())) ne GetAbsDirname(".")) {
        DPrint(16, "ChangeDir: `$dir'\n");
        chdir($dir) or die("Can't change to directory `$dir'.\n");
    }
}

sub DeleteDir($;$)
{
    return if !-d(my $dir = GetAbsDirname(shift()));
    DPrint(16, "DeleteDir: `$dir'\n");
    for my $sec (0, 2, 5) {
        warn("Can't delete directory `$dir', retrying in $sec seconds...\n"), sleep($sec) if $sec;
        eval { local $gEvalerr = 1; File::Path::rmtree($dir) };
        return if !-d($dir);
        RunSystemCmd($gWinOS ? 'rmdir /q /s "' . PathConv($dir, 1) . '"' :
            "rm -fr '$dir'", 2);
        sleep(1);
        return if !-d($dir);
    }
    $dir = "Can't delete directory `$dir'.\n";
    shift() ? warn($dir) : die($dir);
}

sub FindDir($$$$)
{
    my ($dir, $inclpat, $exclpat, $opt) = @_;
    $opt = "" if !defined($opt);
    push(@gFindresult, Find($dir, $inclpat, $exclpat, $opt =~ /r/, 1, local $_));
}

sub MakeDir($)
{
    return if -d(my $dir = shift());
    eval { local $gEvalerr = 1; File::Path::mkpath($dir = GetAbsDirname($dir)) };
    if (-d($dir)) {
        DPrint(16, "MakeDir: `" . GetAbsDirname($dir) ."'\n");
    } else {
        DPrint(16, "MakeDir: `$dir'\n");
        die("Can't create directory `$dir'.\n");
    }
}

sub MakeChangeDir($)
{
    MakeDir(my $dir = shift());
    ChangeDir($dir);
}

sub SetWorkdir($)
{
    MakeChangeDir(shift());
    $gWorkdrive = (Cwd::cwd() =~ /^([a-z]:)/i ? uc($1) : "");
    $gWorkdir   = GetAbsDirname(".");
}

sub OpenFile(*$$;$)
{
    my ($fhandle, $file, $binmode, $print) = @_;
    MakeDir(GetDirname($file)) if $file =~ /^>/;
    DPrint(16, defined($print) ? $print : ($file =~ /^>/ ? "Write" : "Read") . "File: `$file'\n");
    return(open($fhandle, $file)) if !$binmode;
    return(open($fhandle, $file) and binmode($fhandle));
}

sub Test($)
{
    if (-d(my $file = shift())) {
        DPrint(16, "TestDir: `" . GetAbsDirname($file) . "'\n");
    } elsif (-f($file)) {
        DPrint(16, "TestFile: `" . GetAbsFname($file) . "'\n");
    } else {
        DPrint(16, "Test: `$file'\n");
        die("File or directory `$file' doesn't exist.\n");
    }
}

sub CutFile($$$$$)
{
    my ($msg, $src, $dest, $head, $len) = @_;
    my ($buf, $srctmp) = (undef, "$src.tmp");

    OpenFile(*INFILE, $src, 1, $msg) or
        die("Can't read file `$src'.\n"), return;

    my $out = GetWriteFname($head ? $dest : $srctmp);
    OpenFile(*OUTFILE, $out, 1) or die("Can't write to `$out'.\n"), return;
    while ($len > 0) {
        read(INFILE, $buf, $len < READBUFSIZE ? $len : READBUFSIZE);
        print(OUTFILE $buf);
        $len -= READBUFSIZE;
    }
    close(OUTFILE);

    $out = GetWriteFname($head ? $srctmp : $dest);
    OpenFile(*OUTFILE, $out, 1) or die("Can't write to `$out'.\n"), return;
    print(OUTFILE $buf) while read(INFILE, $buf, READBUFSIZE);
    close(OUTFILE);
    close(INFILE);
    Move($srctmp, $src);
}

sub Copy($$;$)
{
    my ($src, $dest, $dir) = @_;
    $dir = defined($dir) && $dir;
    my $file = !($dir || -d($src));
    $src  = ($file ? GetAbsFname($src) : GetAbsDirname($src));
    $dest = ($file ? GetAbsFname(-d($dest) ? "$dest/" . GetBasename($src) : $dest) :
        GetAbsDirname($dir ? $dest : "$dest/" . GetBasename($src)));
    if ($file && ($dest =~ /^>>[^>]/)) {
        OpenFile(*FILE, $dest, 1, "AppendFile: `$src' => `$dest'\n")
            or die("Can't append to `$dest'.\n"), return;
        File::Copy::copy($src, *FILE) and
            close(FILE) and return;
    }
    elsif ($file) {
        MakeDir(GetDirname($dest));
        DPrint(16, "CopyFile: `$src' => `$dest'\n");
        warn("CopyFile: Destination file `$dest' already exists\n") if -f($dest);
        File::Copy::copy($src, $dest) and return;
    } else {
        DPrint(16, "CopyDir: `$src' => `$dest'\n");
        return if !RunSystemCmd(!$gWinOS ? "cp \"$src\"/* \"$dest\" -frv" :
            'xcopy "' . PathConv($src, 1) . '" "' . PathConv($dest, 1) . '" /e /h /i /q /y /z', 2);
    }
    die("Can't copy `$src' to `$dest'.\n");
}

sub CopyIby($$)
{
    my ($file, $dir) = (GetAbsFname(shift()), shift());
    OpenFile(*FILE, $file, 0) or die("Can't read file `$file'.\n"), return;
    map {
        Copy(defined($1) ? $1 : $2, "$dir/" . (defined($3) ? $3 : $4)) if $_ =~ FILESPECSTATEMENT;
    } <FILE>;
    close(FILE);
}

sub DeleteFile($;$)
{
    return if !-f(my $file = GetAbsFname(shift()));
    DPrint(16, "DeleteFile: `$file'\n");
    for my $sec (0, 1, 2) {
        warn("Can't delete file `$file', retrying in $sec second(s)...\n"), sleep($sec) if $sec;
        unlink($file);
        return if !-f($file);
    }
    $file = "Can't delete file `$file'.\n";
    shift() ? warn($file) : die($file);
}

sub FindFile($$$$)
{
    my ($dir, $inclpat, $exclpat, $opt) = @_;
    $opt = "" if !defined($opt);
    my @find = Find($opt !~ /f/ ? $dir : GetDirname($dir), $opt !~ /f/ ? $inclpat : GetBasename($dir),
        $exclpat, $opt =~ /r/, 0, local $_);
    push(@gFindresult, $opt !~ /f/ ? @find : map("|$_|$inclpat", @find));
}

sub HeadFile($$$)
{
    my ($src, $dest, $len) = (GetAbsFname(shift()), GetAbsFname(shift()), shift());
    $len = hex($len) if $len =~ /^0x/;
    CutFile("HeadFile: Cut first $len bytes from `$src' => `$dest'\n", $src, $dest, 1, $len);
}

sub TailFile($$$)
{
    my ($src, $dest, $len) = (GetAbsFname(shift()), GetAbsFname(shift()), shift());
    $len = hex($len) if $len =~ /^0x/;
    CutFile("TailFile: Cut last $len bytes from `$src' => `$dest'\n", $src, $dest, 0, (-s($src) ? -s($src) : 0) - $len);
}

sub TypeFile($;$)
{
    my ($file, $str, $mode) = (GetAbsFname(shift()), "", shift() || "");
    OpenFile(*FILE, $file, $mode, "TypeFile: `$file'" .
        ($gOutfilter && ($mode ne "b") ? ", filter: `/$gOutfilter/i'" : "") . "\n") or
            die("Can't read file `$file'.\n"), return;
    DPrint(8, STARTSTR . "\n");
    read(FILE, $str, -s($file));
    if ($mode eq "b") {
        DPrint(1, Byte2Str(0, map(ord(), split(//, $str))));
    } else {
        $str = Uni2Ascii($str) if $mode eq "u";
        DPrint(1, map("$_\n", grep(!$gOutfilter || /$gOutfilter/i, split(/\n/, $str))));
        $gOutfilter = "";
    }
    DPrint(8, ENDSTR . "\n");
    close(FILE);
}

sub ReadFile($$)
{
    my ($file, $warn) = (GetAbsFname(shift()), shift());
    OpenFile(*RFILE, $file, 0) or
        ($warn ? (warn("Can't read file `$file'.\n"), return(())) : die("Can't read file `$file'.\n"));
    my @file = map(chomp() ? $_ : $_, grep(!/^\s*$/, <RFILE>));
    close(RFILE);
    return(@file);
}

sub WriteFile($$$;$$)
{
    my ($file, $str, $mode, $opt) = (GetAbsFname(shift()), shift(), shift() || "", shift());
    OpenFile(*WFILE, GetWriteFname($file), $mode) or
        die("Can't write to `$file'.\n"), return;
    if ($mode eq "b") {
        my @byte = Str2Byte($str);
        DPrint(64, Byte2Str($file =~ s/^>>(?!>)// ? -s($file) : 0, @byte));
        print(WFILE map(chr(), @byte));
    } else {
        $opt = "" if !defined($opt);
        $str = Unquote($str) if ($opt !~ /q/);
        $str =~ s/(?<=\S)\/\//\//g if ($opt =~ /c/);
        DPrint(16, $str) if shift();
        $str = Ascii2Uni($str) if ($mode eq "u");
        print(WFILE $str);
    }
    close(WFILE);
}

sub UnzipFile($$)
{
    my ($zipfile, $dir) = (GetAbsFname(shift()), GetAbsDirname(shift()));
    DPrint(16, "UnzipFile: `$zipfile'");
    Archive::Zip::setErrorHandler(sub{});
    my ($error, $zip) = (0, Archive::Zip->new());
    if ($zip->read($zipfile) != AZ_OK) {
        DPrint(16, " to directory `$dir'\n");
        die("Can't read zip archive `$zipfile'.\n");
        return;
    }
    my @files = map($_->fileName(), grep(!$_->isDirectory(), $zip->members()));
    DPrint(16, ", " . @files . " files to directory `$dir'\n");
    foreach my $file (@files) {
        DPrint(16, "ExtractFile: `$dir/$file'");
        eval { local $gEvalerr = 1; $error = ($zip->extractMember($file, "$dir/$file") != AZ_OK) };
        DPrint(16, $error ? " Failed\n" : "\n");
        die("Can't extract file `$file' to directory `$dir'.\n") if $error;
        $error = 0;
    }
}

sub Zip($$$$@)
{
    my ($zipfile, $dir, $opt, $prefix) = (GetAbsFname(shift()), shift(), shift(), shift());

    $opt = (defined($opt) ? ", options: `$opt'" : "");
    $prefix = GetAbsDirname($prefix) if $prefix ne "";
    my %files = ();
    foreach my $file (@_) {
        my $zname = "";
        ($file, $zname) = ($1, $2) if ($file =~ /^\|(.*)\|(.*)$/);
        next if !($file = (!$dir ? (-f($file) ? GetAbsFname($file) : "") : (-d($file) ? GetAbsDirname($file) : "")));
        ($zname = ($zname eq "" ? $file : (!$dir ?
            GetAbsFname($zname) : GetAbsDirname($zname)))) =~ s/^(?:$gEpocroot|[a-z]:)?\/+//i;
        if ($opt !~ /j/) {
            $zname =~ s/^.*?\/+/$prefix\// if ($prefix ne "");
        } else {
            $zname = ($dir ? "" : GetBasename($file)) if ($prefix eq "") || !s/^$prefix//;
        }
        $files{lc($zname)} = [$file, $zname];
    }

    DPrint(16, ($dir ? "ZipDir: `$zipfile'$opt, " . keys(%files) . " directories" :
        "ZipFile: `$zipfile'$opt, " . keys(%files) . " files") . ($prefix ? ", prefix: $prefix\n" : "\n"));

    Archive::Zip::setErrorHandler(sub{});
    my ($error, $zip) = (0, Archive::Zip->new());
    $zip->read($zipfile) if (my $ziptmp = ($zipfile =~ s/^>>(?!>)// ? "$zipfile.tmp" : ""));
    $zip->zipfileComment("iMaker-generated zip archive `$zipfile'$opt.");

    foreach my $file (sort({lc($$a[0]) cmp lc($$b[0])} values(%files))) {
        DPrint(16, "Add" . ($dir ? "Dir" : "File") . ": `$$file[0]' => `$$file[1]'") if ($opt !~ /q/);
        eval {
            my $warn = 0;
            local $gEvalerr = 1; local $SIG{__WARN__} = sub{ $warn = 1 };
            $error = ($dir ? $zip->addTree($$file[0], $$file[1]) != AZ_OK :
                !$zip->addFile($$file[0], $$file[1])) || $warn;
        };
        DPrint(16, $error ? " Failed\n" : "\n") if ($opt !~ /q/);
        warn("Can't add " . ($dir ? "directory tree" : "file") . "`$$file[0]' to zip archive `$zipfile'.\n") if $error;
        $error = 0;
    }
    ($zip->writeToFileNamed($ziptmp ? $ziptmp : $zipfile) == AZ_OK) or
        die("Can't create zip archive `$zipfile'.\n");
    Move($ziptmp, $zipfile) if $ziptmp;
}

sub Move($$)
{
    my ($src, $dest) = @_;
    my $dir = -d($src);
    $src = ($dir ? GetAbsDirname($src) : GetAbsFname($src));
    MakeDir(GetDirname($dest));
    $dest = ($dir ? GetAbsDirname($dest) : GetAbsFname($dest));
    DPrint(16, "Move" . ($dir ? "Dir" : "File") . ": `$src' => `$dest'\n");
    File::Copy::move($src, $dest) or
        die("Can't move `$src' to `$dest'.\n");
}

sub Touch($@)
{
    my $time = (shift() =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/ ?
        Time::Local::timelocal($6, $5, $4, $3, $2 - 1, $1 - 1900) : time);
    if (@_ != 1) {
        DPrint(16, "Touch: " . scalar(@_) . " files/dirs, " .
            POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($time)) . "\n");
        utime($time, $time, @_) == @_ or
            die("Can't touch all the " . scalar(@_) . " files/dirs.\n");
        return;
    }
    my $file = shift();
    my $dir = -d($file);
    $file = ($dir ? GetAbsDirname($file) : GetAbsFname($file));
    DPrint(16, "Touch" . ($dir ? "Dir" : "File") . ": `$file', " .
        POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($time)) . "\n");
    utime($time, $time, $file) == 1 or
        die("Can't touch " . ($dir ? "directory" : "file") . " `$file'.\n");
}

sub SetLogfile($)
{
    return if !(my $file = GetAbsFname(shift()));
    my $append = (($file =~ s/^>>(?!>)//) || exists($gLogfiles{$file}) ? ">>" : "");
    CloseLog();
    OpenFile(*LOG, GetWriteFname($file = "$append$file"), 0) or
        warn("Can't log to file `$file'.\n"), return;
    $gLogfiles{$gLogfiles{__prev__} = $gLogfile = $file} = 1;
}


###############################################################################
#

sub RunSystemCmd($;$$$)
{
    return if ($gICmd !~ $gFiltercmd);
    my ($cmd, $keepgoing, $null, $file) = @_;
    DPrint(1, "$cmd\n"), return if $gPrintcmd;
    local $gError = 0 if ($keepgoing = (defined($keepgoing) && ($keepgoing =~ /^[123]$/) ? $keepgoing : 0));
    local $gKeepgoing = Max($gKeepgoing, $keepgoing) if $keepgoing;
    $file = (defined($file) ? GetAbsFname($file) : "");
    @gCmdoutbuf = ();
    DPrint(4, local $_ = "RunSystemCmd(" . GetAbsDirname(".") . "): `$cmd'" .
        ($keepgoing ? ", keep going" . ($keepgoing > 1 ? "($keepgoing)" : "") : "") .
        ($file ? ", redirect to `$file'" : "") . ($null ? ", redirect stdout to null" : "") .
        ($gOutfilter ? ", filter: `/$gOutfilter/i'" : "") . "\n");
    OpenFile(*CMDFILE, GetWriteFname($file), 0) or
        (die("Can't write to `$file'.\n"), $file = "") if $file;
    print(CMDFILE $_) if $file;
    my $dur = time();
    open(CMD, "$cmd 2>&1 |");
    DPrint(8, STARTSTR . "\n");
    while ($_ = <CMD>) {
        chomp();
        push(@gCmdoutbuf, $_);
        next if ($gOutfilter && !/$gOutfilter/i);
        DPrint(8, "$_\n") if !$null;
        print(CMDFILE "$_\n") if $file;
    }
    close(CMD);
    my $error = ($? >> 8);
    close(CMDFILE) if $file;
    push(@gStepDur, $dur = time() - $dur);
    $gOutfilter = "";
    print(map("$_\n", @gCmdoutbuf)) if ($error && !$gKeepgoing && !$null && $gVerbose && !($gVerbose & 8));
    $dur = Sec2Min($dur);
    DPrint(8, substr(ENDSTR, 0, -16) . $dur . substr(ENDSTR, length($dur) - 16) . "\n");
    die("Command `$cmd' failed ($error) in `" . GetAbsDirname(".") . "'.\n") if $error;
    return($error);
}


###############################################################################
#

sub ParseSystemCmd($$$$$)
{
    return if SkipICmd();
    my ($title, $inclre, $exclre, $file, $lines) = @_;
    ($inclre, $exclre) = (eval("qr$inclre"), $exclre ne "" ? eval("qr$exclre") : qr/^$/);
    $lines = ($lines ? $lines - 1 : 0);

    my @parse = ();
    for (my $i = 0; $i < @gCmdoutbuf; $i++) {
        next if ($gCmdoutbuf[$i] !~ $inclre);
        push(@parse, join(" | ", @gCmdoutbuf[$i .. $i + $lines])) if ($gCmdoutbuf[$i] !~ $exclre);
        $i += $lines;
    }
    return if !@parse;
    if (!$file) {
        DPrint(1, "$title\n", map(sprintf("%" . length(@parse) . "s", $_) . ") $parse[$_ - 1]\n", 1 .. @parse));
    } else {
        WriteFile($title, join("\n", @parse), "", "q");
    }
}


###############################################################################
#

sub GenExclfile($$$$$)
{
    return if SkipICmd();

    my ($exclfile, $base, $prefix, $exclfiles, @exclfiles) = (shift(), GetAbsDirname(shift()), shift(), "", ());

    if (!-f($exclfile)) {
        WriteFile($exclfile, "", "");
    } else {
        OpenFile(*FILE, $exclfile, 1) or die("Can't read file `$exclfile'.\n"), return;
        read(FILE, $exclfiles, -s($exclfile));
        close(FILE);
        @exclfiles = split(/\n/, Uni2Ascii($exclfiles));
    }

    my $findfiles = 0;
    my @addfiles = map($_ ne "**" ? $_ : "*", grep(!(($_ eq "*") && ++$findfiles),
        map(Trim(Unquote(Trim($_))), grep(!/^\s*(?:#.*)?$/, split(/(?<!\\)\\n/, shift())))));

    if ($findfiles) {
        $exclfiles = "";
        foreach (@exclfiles, @addfiles, map(Trim(Unquote(Trim($_))), grep(!/^\s*(?:#.*)?$/, split(/(?<!\\)\\n/, shift())))) {
            (my $file = $_) =~ tr/\\/\//;
            $file =~ s/^(?:[a-z]:)?\/*//i;
            $exclfiles .= ($exclfiles ne "" ? "|" : "") . Wcard2Restr($file);
        }
        push(@addfiles, map(GetRelFname($_, $base), Find($base, "*", "/^\\/(?:$exclfiles)\$/i", 1, 0, local $_)));
    }

    $prefix =~ s/[\/\\]+$//;
    WriteFile($exclfile, join("", map("$_\n", @exclfiles,
        map(s/^(?:[a-z]:)?\\*/$prefix\\/i ? $_ : $_, map(tr/\//\\/ ? $_ : $_, @addfiles)))), "u", "q");
}

sub GenIbyfile($$$)
{
    return if SkipICmd();
    my ($ibyfile, $ibystr, $oride, $prevoride) = (shift(), "", "", "");

    map {
        die("GenIbyfile: Invalid file list configuration: `$_'\n"), return
            if !/^\s*(?:"(.+?)"|(\S+))\s+(?:"(.+?)"|(\S+))\s*$/;
        $_ = [defined($1) ? $1 : $2, defined($3) ? $3 : $4];
    } (my @files = map(Unquote($_), grep(!/^\s*(?:#.*)?$/, split(/(?<!\\)\\n/, shift()))));

    my @ibyconf = map(Unquote($_), grep(!/^\s*(?:#.*)?$/, split(/(?<!\\)\\n/, shift())));

    foreach (@ibyconf) {
        die("GenIbyfile: Invalid configuration: `$_'\n"), return
            if !/^\s*(?:"(.+?)"|(\S+))\s+(hide|remove|(?:replace|udeb|urel)(?:-add)?)\s+(\*|core|rofs[2-6])\s*$/i;
        next if ($4 ne "*") && (uc($4) ne $gImgtype);
        my $action = lc($3);
        my $file = Wcard2Restr(defined($1) ? $1 : $2);
        $file = qr/(?:^|\\|\/)$file$/i;
        foreach (@files) {
            next if (@$_[1] !~ $file);
            $oride = ($action =~ /add$/ ? "ADD" : ($action eq "hide" ? "" : "SKIP"));
            my $src = ($action eq "remove" ? "empty" : @$_[0]);
            if ($action =~ /^udeb/) {
                $src =~ s/(?<=[\/\\])urel(?=[\/\\])/udeb/i;
            } elsif ($action =~ /^urel/) {
                $src =~ s/(?<=[\/\\])udeb(?=[\/\\])/urel/i;
            }
            $ibystr .= ($prevoride && ($oride ne $prevoride) ? "OVERRIDE_END\n" : "") .
                ($oride && ($oride ne $prevoride) ? "OVERRIDE_REPLACE/$oride\n" : "") .
                ($oride ? "override=\"$src\"  " : "hide=") . "\"@$_[1]\"\n";
            $prevoride = $oride;
        }
    }
    WriteFile($ibyfile, ($ibyfile =~ /^>>([^>].*)$/ && -f($1) ? "" : "// Generated `$ibyfile'") .
        "\n\n/* Custom override configuration\n" . join("\n", @ibyconf) . "\n*/\n$ibystr" .
        ($oride ? "OVERRIDE_END\n" : ""), "", "q");
}

sub GenObyfile($$$$@)
{
    return if SkipICmd();

    my ($ibyfile, $srcdir, $subdir, $finddir) = (GetAbsFname(shift()), shift(), shift(), shift());
    my ($header, $footer, $body, %files) = ("", "", "", ());

    foreach my $dir (split(/\s+/, $srcdir)) {
        $dir = GetAbsDirname($dir);
        my ($found, $total, $lines) = (0, 0, "");
        my @param = @_;
        while (@param) {
            my ($filepat, $format, @lines) = (shift(@param), shift(@param), ());
            $header = $format, next if $filepat =~ /^__header__$/i;
            $footer = $format, next if $filepat =~ /^__footer__$/i;
            foreach my $src (Find($dir, $filepat, "", $subdir, $finddir, $total)) {
                next if $files{$src};
                $files{$src} = 1;
                (my $line = $format) =~ s/%1/$src/g;
                $line =~ s/%2/GetRelFname($src, $dir, 1)/ge;
                $line =~ s/%3/GetAbsFname($src)/ge;
                if ($line =~ /%4/) {
                    my $attrib = "";
                    if ($gWinOS) {
                        Win32::File::GetAttributes($src, $attrib);
                        $attrib = (($attrib & WIN32_FILE_HIDDEN) ? "attrib=H" : "");
                    }
                    $line =~ s/%4/$attrib/ge;
                }
                push(@lines, Trim($line));
            }
            $found += @lines;
            $lines .= "//\n// Format: `$format', " . @lines . ($finddir ? " empty directories" : " files") .
                 ": `$filepat'\n" . (@lines ? "//\n" . join("\n", @lines) . "\n" : "");
        }
        $body .= "\n// Collected entries $found/$total from directory `$dir'" .
            ($subdir ? " and subdirectories" : "") . "\n$lines";
    }

    my $append = ($ibyfile =~ s/^>>(?!>)// && -f($ibyfile) && ">>" || "");
    (my $fname = "__" . uc(GetBasename($ibyfile)) . "__") =~ s/\W/_/g;
    my @previby = ();

    if ($append) {
        OpenFile(*FILE, $ibyfile, 0) or die("Can't read file `$ibyfile'.\n"), return;
        @previby = <FILE>;
        close(FILE);
        $previby[0] =~ s/(, collected )(\d+)( entries)$/$1.($2 + keys(%files)).$3/e;
        $previby[@previby - 1] = "";
    }
    WriteFile($ibyfile, join("", @previby) . ($append ? "// Appended" : "// Generated") .
        " `$append$ibyfile', collected " . keys(%files) . " entries\n" .
        ($append ? "" : "\n#ifndef $fname\n#define $fname\n") .
        ($header ? Unquote("\\n$header\\n") : "") . $body . ($footer ? Unquote("\\n$footer\\n") : "") .
        "\n#endif // $fname\n", "", "q");
}

sub GenWidgetConf($$$$)
{
    return if SkipICmd();
    my ($wgzini, $ini, $dir) = (shift(), GetAbsFname(shift()), GetAbsDirname(shift()));
    my @ini   = ($ini eq "" ? () : ReadFile($ini,  0));
    my $files = ($dir eq "" ? "" : join("\n", Find($dir, "*", '/\/(?:' . join("|",
        map(GetBasename($_), ($ini, map(!/^\s*[#[]/ && /^\s*(?:"(.+?)"|(\S+))/ &&
            -e(local $_ = (defined($1) ? $1 : $2)) ? $_ : (), @ini)))) . ')$/i', 0, 0, local $_)));

    WriteFile($wgzini, Unquote(shift()) .
        (@ini ? "# Copied lines from `$ini':\n" . join("\n", @ini) : "") . "\n" .
        ($files ? (@ini ? "\n" : "") . "# Collected files from `$dir':\n$files\n" : ""), "", "q");
}


###############################################################################
#

sub GenMakefile($$$$$)
{
    return if SkipICmd();
    my ($hdrfile, $mkfile, $filter, $prepros, $assignop) =
        (GetAbsFname(shift()), GetAbsFname(shift()), shift(), shift(), shift());
    ChangeDir(GetDirname($hdrfile));
    RunSystemCmd("$prepros " . GetBasename($hdrfile));
    my $maxdef = Max(map(/^\s*\#define\s+($filter)/ && length($1), @gCmdoutbuf));
    WriteFile($mkfile, join('\n',
        map(/^\s*\#define\s+($filter)\s*(.*?)\s*$/ ? sprintf("%-${maxdef}s $assignop %s", $1, $2 eq "" ? 1 : $2) : (), sort(@gCmdoutbuf))) . '\n', "");
}


###############################################################################
#

sub AddImageHeader($$$$$)
{
    return if SkipICmd();
    my ($file, $hdrfile, $hdrstr, $hdrsize, $align) =
        (GetAbsFname(shift()), GetAbsFname(shift()), shift(), shift(), shift());

    $hdrstr =~ s/\/\*.*?\*\///g;
    $hdrstr =~ s/,\s*$//;
    WriteFile($hdrfile, $hdrstr, "b");
    die("Invalid image header size: " . sprintf("0x%X", -s($hdrfile)) . " (!=$hdrsize).\n"), return
        if -s($hdrfile) ne hex($hdrsize);

    $align = Max(hex($align), hex($hdrsize)) - hex($hdrsize);
    WriteFile(">>$hdrfile", ("0," x ($align - 1)) . "0", "b") if $align;
    Copy($file, ">>$hdrfile") if $file ne "";
}


###############################################################################
#

sub Sleep($)
{
    return if SkipICmd();
    sleep(shift());
}


###############################################################################
#

sub FindSOSFiles($$$$)
{
    return if SkipICmd();

    my ($dirs, $imgoby, $pluglog, $opt) = @_;
    my ($file, %files) = ("", ());
    local $_;

    foreach my $dir (GlobFiles($dirs)) {
        my ($featvar, @pluglog) = ("", Find($dir = GetAbsDirname($dir), $pluglog, "", 1, 0, $_));

        foreach $file (@pluglog) {
            OpenFile(*FILE, $file, 0) or warn("Can't read file `$file'.\n"), last;
            while (<FILE>) {
                last if !/^.+?\.pm: Initializing; /;
                $featvar = $1, last if / feature variant = `(.+)'$/;
            }
            close(FILE);
            last if ($featvar ne "");
        }

        foreach $file (Find($dir, $imgoby, "", 1, 0, $_)) {
            OpenFile(*FILE, $file, 0) or warn("Can't read file `$file'.\n"), last;
            while (<FILE>) {
                next if ($_ !~ FILESPECSTATEMENT) && ($_ !~ BOOTBINARYSTATEMENT);
                $file = GetAbsFname(defined($1) ? $1 : $2);
                $files{lc($file)} = $file if !exists($files{lc($file)});
                next if ($file !~ s/\.[0-9a-f]{32}\./\./i);
                $file .= (-f("$file.$featvar.vmap") ? ".$featvar.vmap" : ".vmap");
                $files{lc($file)} = $file if !exists($files{lc($file)});
            }
            close(FILE);
        }

        my ($incfile, $spifile, $plugfile, $patchfile) = (0, 0, 0, 0);
        foreach $file (@pluglog) {
            OpenFile(*FILE, $file, 0) or warn("Can't read file `$file'.\n"), last;
            while (<FILE>) {
                $incfile   = 1, next if /^Finding include hierarchy from /;
                $incfile   = 0, next if ($incfile && /^Found \d+ different include files$/);
                $spifile   = 1, next if /^Finding SPI input files from /;
                $spifile   = 0, next if ($spifile && /^Found \d+ SPI input files$/);
                $plugfile  = 1, next if /^Reading (ROM|ROFS1|UDEB|UREL) files from /;
                $plugfile  = 0, next if ($plugfile && /^Found \d+ entries$/);
                $patchfile = 1, next if /^Finding ROM-patched components$/;
                $patchfile = 0, next if ($patchfile && /^Found \d+ ROM-patched components$/);
                $files{lc($file)} = $file, next
                    if (($incfile || $spifile || $plugfile) && /`(.+)'$/ && !exists($files{lc($file = GetAbsFname($1))}));
                next if (!$patchfile || !/^`(.+)'$/);
                $file = GetAbsFname($1) . ".map";
                $files{lc($file)} = $file, next if -f($file);
                $file =~ s/(\..*?\.map)$/\.\*$1/;
                foreach (glob($file =~ /\s/ ? "\"$file\"" : $file)) {
                    ($file = lc()) =~ s/\.map$//;
                    $files{lc()} = $_, last if exists($files{$file});
                }
            }
            close(FILE);
        }

        $dir .= "/" if $dir !~ /\/$/;
        foreach $file (keys(%files)) {
            delete($files{$file}) if ($file =~ /^$dir/i);
        }
    }

    @gFindresult = () if (!defined($opt) || $opt !~ /a/);
    push(@gFindresult, values(%files));
}


###############################################################################
#

sub CheckTool(@)
{
    return if SkipICmd();
    my ($maxtlen, $maxvlen, @tools) = (4, 9, ());
    while (@_) {
        my ($tool, $vquery, $getver, $version, $md5sum) = (shift(), shift(), shift(), " -", " ?");
        if (length($vquery) > 1) {
            RunSystemCmd($vquery, 3, 1);
            $version = (join("\n", @gCmdoutbuf) =~ eval($getver =~ /^\// ? "qr$getver" : "qr/$getver/ims") ?
                (defined($1) && defined($2) && "`$1 $2'" || defined($1) && "`$1'" || " ?") : " ?");
        }
        OpenFile(*FILE, $tool, 1) and $md5sum = "`" . md5_hex(<FILE>) . "'";
        close(FILE);
        $maxtlen = Max($maxtlen, length($tool));
        $maxvlen = Max($maxvlen, length($version));
        push(@tools, "`$tool'", $version, $md5sum);
    }
    $maxtlen += 2;
    @_ = (" Tool", " Version", " MD5 Checksum", "-" x $maxtlen, "-" x $maxvlen, "-" x 34, @tools);
    DPrint(1, sprintf("%-${maxtlen}s %-${maxvlen}s ", shift(), shift()) . shift() . "\n") while(@_);
}


###############################################################################
#

sub OpCacheInstall($$$)
{
    return if SkipICmd();
    my ($ini, $conf, $tmpdir) = @_;
    my %opt = (-e => "", -i => "", -m => "", -o => "", -u => "");

    foreach $conf ("opcache_config=$conf", ($ini ne "" ? grep(!/^\s*#/, ReadFile($ini, 0)) : ())) {
        (local $_, my $error, my %tmpopt) = ($conf, 0, %opt);
        if (!($error = !(s/^\s*opcache_config\s*[=\s]//i || s/^\s*opcache_content\s*[=\s]/-i /i))) {
            my @opt = ParseCmdWords($_);
            while (@opt) {
                last if ($error = ((($_ = shift(@opt)) !~ /^-[eimou]$/i) ||
                    !defined($tmpopt{$_} = shift(@opt))));
                $tmpopt{$_} =~ s/EPOCROOT/$gEpocroot/g;
            }
        }
        die("OpCacheInstall: Invalid configuration entry: `$conf'\n"), next if $error;
        %opt = %tmpopt;
    }
    if (-d($opt{-i})) {
        $opt{-i} = GetAbsDirname($opt{-i});
    } elsif (-f($opt{-i})) {
        DeleteDir($tmpdir);
        MakeDir($tmpdir);
        RunSystemCmd("$gTool{unzip} x -y \"" . GetAbsFname($opt{-i}) . "\"" .
            " -o\"" . ($tmpdir = GetAbsDirname($tmpdir)) . "\"", 0, 1);
        $opt{-i} = $tmpdir;
    }
    RunSystemCmd("$gTool{opcache} -u \"$opt{-u}\" -e \"$opt{-e}\" -m \"" .
        GetAbsFname($opt{-m}) . "\" -i \"$opt{-i}\" -o \"" . GetAbsDirname($opt{-o}) . "\"");
}


###############################################################################
#

sub SisInstall($$$$$$$$)
{
    return if SkipICmd();

    my ($ini, $intini, $conf, $hda, $hdata, $idata, $outdir, $log) =
        (GetAbsFname(shift()), GetAbsFname(shift()), shift(), GetAbsFname(shift()),
            shift(), shift(), GetAbsDirname(shift()), shift());
    my %gopt = (-d => "C", -k => "5.4", -w => "info", '--ignore-err' => 0);

    my %haldata = ();
    map { $haldata{uc($1)} = $2 if /^\s*(\S+)\s+(\S+)\s*$/ } split(/(?<!\\)\\n/, $hdata);
    $gOutfilter = '\S';
    RunSystemCmd("$gTool{cpp} -nostdinc -undef \"$hda\"", 1, 1, $log) if ($hda ne "");

    local @_ = (map(!/^\s*E(\S+)\s*=\s*(\S+)\s*$/ ? () : (uc($1) . " = " .
        (exists($haldata{uc($2)}) ? $haldata{uc($2)} : (exists($haldata{uc("E$1_$2")}) ?
            $haldata{uc("E$1_$2")} : $2)) . "\n"), @gCmdoutbuf),
        map(/^\s*$/ ? () : Trim($_) . "\n", split(/(?<!\\)\\n/, $idata)));

    WriteFile($intini, join("", @_), "", "q");
    RunSystemCmd("$gTool{interpretsis} -i \"$intini\"", 3, 1);
    map { $_[$1 - 1] = undef if /Unsupported keyword.+?(\d+)/i } @gCmdoutbuf;
    WriteFile($intini, join("", grep(defined(), @_)), "", "q");

    my ($clean, @dir) = (0, Find($outdir, "*", "", 1, 1, $_));
    @_ = ("sis_config=$conf", ($ini ne "" ? grep(!/^\s*#/, ReadFile($ini, 0)) : ()), "sis_content=");

    for (my $i = 0; $i < @_; $i++) {
        local $_ = $_[$i];
        my ($error, $global, $runtool, %opt) = (0, 0, 0, %gopt);
        if (!($error = !(s/^\s*sis_(config)\s*[=\s]//i || s/^\s*sis_(content)\s*[=\s]/-s /i))) {
            $global = ($1 =~ /config/i);
            my @opt = ParseCmdWords($_);
            while (@opt) {
                $_ = shift(@opt);
                shift(@opt) if ((my $next = (@opt ? ($opt[0] !~ /^!?[-+]/ ? $opt[0] : "") : "")) ne "");
                next if /^!?-[cilwx]$/;
                if (s/^!//) { delete($opt{$_}) }
                else {
                    $_[$#_]  .= "\"$next\"", next if (!$i && /^-s$/);
                    ($opt{$_} = $next) =~ s/EPOCROOT/$gEpocroot/g;
                    $runtool  = ($next !~ /^\s*$/) if /^-s$/;
                }
            }
        }
        die("SisInstall: Invalid configuration entry: `$_[$i]'\n"), next if $error;
        %gopt = %opt if $global;
        next if !$runtool;

        foreach (-d($opt{-s}) ? Find($opt{-s}, '/\.sisx?$/i', "", 0, 0, $_) : (GetAbsFname($opt{-s}))) {
            ($opt{-s}, my $puid) = ($_, "?");
            OpenFile(*SISFILE, $_, 1, "") and sysread(SISFILE, $puid, 3 * 4) and
                $puid = sprintf("%08X", unpack("V", substr($puid, 8, 4)));
            close(SISFILE);
            DPrint(16, "SisInstall: `$_', pUID: $puid" . ($opt{'--ignore-err'} ? ", ignore errors\n" : "\n"));

            my $icmd = $gTool{interpretsis} . (join("", map(($opt{$_} ne "" ? " $_ \"$opt{$_}\"" : " $_"),
                sort({lc($a) cmp lc($b)} grep(/^-[^s]/ && !/^--ignore-err$/, keys(%opt)))))) .
                " -c \"" . (GetAbsDirname($outdir)) . "\" -i \"" . (GetAbsFname($intini)) . "\"";
            $error = RunSystemCmd("$icmd -s \"$opt{-s}\"" . join("", map(" $_",
                sort({lc($a) cmp lc($b)} grep(/^\+/, keys(%opt))))), 1, 1, ">>$log");
            my $errmsg = join(" | ", grep(s/^ERR\s*:\s*//, @gCmdoutbuf));

            $_ = join(", ", map(/^INFO:\s+Installing file:\s+\w:\\sys\\bin\\(.+?.exe)\s*$/io &&
                ($_ = $1) && (qx($gTool{elf2e32} --dump=h --e32input "$outdir/sys/bin/$_") =~
                    /^Uids:\s+.+?\s+([0-9a-f]+)\s+\(/imo) ? "$_: " . uc($1) : (), @gCmdoutbuf));
            DPrint(16, "SisInstall: `" . GetBasename($opt{-s}) . "', exe UIDs: $_\n")
                if ($_ && (!($error ||= $errmsg) || $opt{'--ignore-err'}));

            warn("Installation of SIS file `$opt{-s}' failed" . ($errmsg ? ": `$errmsg'.\n" : ".\n"))
                if ($gErrwarn = $error);
            next if (!$error || $opt{'--ignore-err'});
            $clean = 1;
            warn("Removing installation of SIS file `$opt{-s}'.\n");
            RunSystemCmd("$icmd -x $puid", 3, 1, ">>$log");
        }
    }
    return if !$clean;
    my $i = 0;
    foreach (Find($outdir, "*", "", 1, 1, $_)) {
        if (($i <= $#dir) && ($_ eq $dir[$i])) { $i++ }
        else { DeleteDir($_) }
    }
}


###############################################################################
#

sub GetIPar(;$)
{
    my $par = shift(@gIcmd);
    $par = ((my $empty = !defined($par)) ? "<UNDEFINED>" : PEval($par));
    $gParamcnt = 0 if shift();
    DPrint(32, "iPar: $gParamcnt. `$par'\n") if $gParamcnt && ($gICmd =~ $gFiltercmd);
    $gParamcnt++;
    return($empty ? undef : $par);
}

sub PEval($)
{
    local $_ = shift();
    while (/\@PEVAL{.*}LAVEP\@/) {
        my $start = rindex($_, '@PEVAL{', my $end = index($_, '}LAVEP@') + 7);
        my ($expr, $eval, $evalerr) = (substr($_, $start + 7, $end - $start - 14), undef, "");
        eval {
            local $_;
            local $gEvalerr = (SkipICmd() ? 1 : 2);
            $eval = eval($expr);
            ($evalerr = $@) =~ s/^(.+?) at .*/$1/s;
        };
#        DPrint(64, "PEval: Evaluate `$expr' = `" . (defined($eval) ? $eval : "") . "'\n");
        if (!defined($eval)) {
            $eval = "";
            warn("PEval: Evaluation of `$expr' failed: $evalerr.\n") if !SkipICmd();
        }
        substr($_, $start, $end - $start) = $eval;
    }
    return($_);
}

sub PeekICmd($)
{
    return(defined($gIcmd[0]) && $gIcmd[0] =~ /^$_[0]$/i);
}

sub SkipICmd()
{
    return($gPrintcmd || defined($gICmd) && ($gICmd !~ $gFiltercmd));
}

sub GetICmd()
{
    $gICmd = GetIPar(1);
    DPrint(32, "iCmd: " . ++$gCmdcnt . ". `$gICmd'\n") if defined($gICmd) && ($gICmd ne "") && ($gICmd =~ $gFiltercmd);
}

sub EndICmd()
{
    GetICmd(), return(1) if !defined($gIcmd[0]) || PeekICmd("end");
    return(0);
}


###############################################################################
#

sub SplitStep($)
{
    (my $step = shift()) =~ s/(?<!(\\|\s))\|/ \|/g;  # ???
    return(map((s/^\s+|(?<!\\)\s+$//g, s/\\\|/\|/g) ? $_ : $_, split(/(?<!\\)\|/, "$step ")));
}

sub RunStep($)
{
    ($gStep, my $dur, @gStepDur) = (shift(), time(), ());
    ChangeDir($gWorkdir);
    DPrint(2, "=" x 79 . "\nENTER: `$gStep'\n");

    push(@gReport, $gLogfile ? ("iMaker log", $gLogfile =~ /^>>?([^>].*)$/ ? $1 : $gLogfile, "f") : (),
        SplitStep($gStepIcmd{"REPORT_$gStep"})) if exists($gStepIcmd{"REPORT_$gStep"});

    foreach my $step ("INIT_$gStep", "CLEAN_$gStep", "BUILD_$gStep") {
        next if (!exists($gStepIcmd{$step}) || $gStepIcmd{$step} =~ /^\s*$/);
        DPrint(64, "$step = `$gStepIcmd{$step}'\n");
        @gIcmd = SplitStep($gStepIcmd{$step});
        my ($file, $iferror, @iffi) = ("", 0, ());

        while (GetICmd(), defined($gICmd)) {
            next if (local $_ = lc($gICmd)) eq "";
            if (/^if$/) {
                push(@iffi, (my $if = GetIPar()), $gFiltercmd);
                $gFiltercmd = qr/^X$/ if !$if;
            }
            elsif (/^else$/) {
                $gFiltercmd = ($iffi[$#iffi - 1] ? qr/^X$/ : $iffi[$#iffi]);
            }
            elsif (/^fi$/) {
                $gFiltercmd = pop(@iffi);
                pop(@iffi);
            }
            elsif (/^(error|warning)$/) {
                my ($errwarn, $msg) = (GetIPar(), GetIPar() . "\n");
                next if SkipICmd();
                die($msg)  if $errwarn && /e/;
                warn($msg) if $errwarn && /w/;
            }
            elsif (/^echo(\d+)?(-q)?$/) {
                Echo((defined($1) && ($1 < 128) ? $1 : 1), GetIPar(), defined($2));
            }
            elsif (/^filter$/) {
                $gOutfilter = GetIPar();
            }
            elsif (/^cmd(tee)?(-(k[0123]?|n)+)?$/) {
                RunSystemCmd(GetIPar(), (/k(\d)/ ? int($1) : (/k/ ? 1 : 0)), /n/, /tee/ ? GetIPar() : "");
            }
            elsif (/^parse(f)?(?:-(\d+))?$/) {
                ParseSystemCmd(GetIPar(), GetIPar(), GetIPar(), $1, $2);
            }
            elsif (/^(cd|copy(dir|iby)?|del(dir)?|find(dir)?(-[afr]+)?|headb|logfile|mkcd|mkdir|move|tailb|test|touch|type[bu]?|unzip|workdir|write[bu]?(-[cq]+)?|zip(dir)?(-[jq]+)?)$/) {
                my @files = GlobFiles(GetIPar());
                my $par1 = GetIPar() if /^(?:copy|find|head|move|tail|touch|(un)?zip|write)/;
                my $par2 = GetIPar() if /^(?:find|head|tail|zip)/;
                next if SkipICmd();
                @gFindresult = () if /find(?:dir)?(-[afr]+)?/ && (!defined($1) || ($1 !~ /a/));
                Touch($par1, @files), next                     if /touch/;
                foreach $file (@files) {
                    ChangeDir($file)                           if /^cd/;
                    DeleteDir($file)                           if /deldir/;
                    FindDir($file, $par1, $par2, $1)           if /finddir(-[ar]+)?/;
                    MakeDir($file)                             if /mkdir/;
                    MakeChangeDir($file)                       if /mkcd/;
                    SetWorkdir($file)                          if /workdir/;
                    Zip($file, 1, $1, $par2, GlobFiles($par1)) if /zipdir(-[jq]+)?/;
                    DeleteFile($file)                          if /del/;
                    FindFile($file, $par1, $par2, $1)          if /find(-[afr]+)?$/;
                    HeadFile($file, $par1, $par2)              if /headb/;
                    SetLogfile($file)                          if /logfile/;
                    TailFile($file, $par1, $par2)              if /tailb/;
                    TypeFile($file, $1)                        if /type(b|u)?/;
                    UnzipFile($file, $par1)                    if /unzip/;
                    WriteFile($file, $par1, $1, $2)            if /write(b|u)?(-[cq]+)?/;
                    Zip($file, 0, $1, $par2, GlobFiles($par1)) if /^zip(-[jq]+)?$/;
                    Copy($file, $par1, $1)                     if /copy(dir)?$/;
                    CopyIby($file, $par1)                      if /copyiby/;
                    Move($file, $par1)                         if /move/;
                    Test($file)                                if /test/;
                }
            }
            elsif (/^filtercmd$/) {
                $gFiltercmd = GetIPar();
                $gFiltercmd = ($gFiltercmd eq "" ? qr/\S/ : qr/$gFiltercmd/i);
            }
            elsif (/^genexclst$/) {
                GenExclfile(GetIPar(), GetIPar(), GetIPar(), GetIPar(), GetIPar());
            }
            elsif (/^geniby(-[dr]+)?$/) {
                my ($opt, $iby, $dir, @par) = ($1 || "", GetIPar(), GetIPar(), ());
                push(@par, GetIPar(), GetIPar()) while !EndICmd();
                GenObyfile($iby, $dir, $opt =~ /r/, $opt =~ /d/ ? 2 : 0, @par);
            }
            elsif (/^genorideiby$/) {
                GenIbyfile(GetIPar(), GetIPar(), GetIPar());
            }
            elsif (/^genmk$/) {
                GenMakefile(GetIPar(), GetIPar(), GetIPar(), GetIPar(), GetIPar());
            }
            elsif (/^genwgzcfg$/) {
                GenWidgetConf(GetIPar(), GetIPar(), GetIPar(), GetIPar());
            }
            elsif (/^iferror$/) {
                $iferror++;
                $gError = 0, next if $gError;
                while (defined($gIcmd[0])) {
                    GetICmd(), last if PeekICmd("endif") && !--$iferror;
                    $iferror++ if shift(@gIcmd) =~ /^iferror$/i;
                }
            }
            elsif (/^endif$/ && $iferror--) {
            }
            elsif (/^imghdr$/) {
                AddImageHeader(GetIPar(), GetIPar(), GetIPar(), GetIPar(), GetIPar());
            }
            elsif (/^pause$/) {
                DPrint(0, "Press Enter to continue...\n");
                getc();
            }
            elsif (/^sleep$/) {
                Sleep(GetIPar());
            }
            elsif (/^sosfind(-a)?$/) {
                my $opt = $1;
                FindSOSFiles(GetIPar(), GetIPar(), GetIPar(), $opt);
            }
            elsif (/^tool-(\w+)$/) {
                $gTool{$1} = GetIPar();
#                DPrint(2, "SetTool: $1: `$gTool{$1}'\n");
            }
            elsif (/^toolchk$/) {
                my @tools = ();
                push(@tools, GetIPar(), GetIPar(), GetIPar()) while !EndICmd();
                CheckTool(@tools);
            }
            elsif (/^opcache$/) {
                OpCacheInstall(GetIPar(), GetIPar(), GetIPar());
            }
            elsif (/^sisinst$/) {
                SisInstall(GetIPar(), GetIPar(), GetIPar(), GetIPar(),
                    GetIPar(), GetIPar(), GetIPar(), GetIPar());
            }
            elsif (!$gImakerext || !RunIExtCmd($_)) {
                die("Unknown iMaker command `$gICmd'.\n");
            }
        }
    }
    DPrint(2, "EXIT: `$gStep', duration: " . Sec2Min($dur = time() - $dur) . "\n");
    push(@gStepDur, $dur);
}


###############################################################################
#

sub GetConfmkList(;$)
{
    if (!%gConfmkList) {
        my ($dir, $incl, $excl, $depth) = split(/,/, $ENV{IMAKER_MKCONF});
        $dir = GetAbsDirname($dir, 0, 1, $gEpocdrive);
        ($incl, $excl) = (qr/$incl/, qr/$excl/);
        local $_;
        DPrint(16, "FindFile: GetConfmkList: `$ENV{IMAKER_MKCONF}'");
        find(sub { $gConfmkList{$1} = $File::Find::name
            if (/$incl/ && !/$excl/ && (($File::Find::name =~ tr/\///) > (($dir =~ tr/\///) + $depth)));
        }, $dir);
        DPrint(16, ", found " . keys(%gConfmkList) . " files\n");
        $gConfmkList{""} = "" if !%gConfmkList;
    }
    return(sort({lc($a) cmp lc($b)} grep($_ ne "", values(%gConfmkList)))) if shift();
}

sub GetFeatvarIncdir($)
{
    open(FILE, "$gEpocroot/epoc32/tools/variant/" . shift() . ".var") or
        return("Invalid SBV feature variant");
    my @featdata = <FILE>;
    close(FILE);
    my @incdir = ("@featdata" =~ /^\s*EXTENDS\s+(.+?)\s*$/m ? GetFeatvarIncdir($1) : ());
    @incdir = () if ("@incdir" =~ /^Invalid/);
    foreach (@featdata) {
        next if !/^\s*ROM_INCLUDE\s+(\S+)\s+(.+?)\s*$/;
        if ($1 eq "set")        { @incdir = ($2) }
        elsif ($1 eq "prepend") { unshift(@incdir, $2) }
        elsif ($1 eq "append")  { push(@incdir, $2) }
    }
    return(map("$_/" =~ /^$gEpocroot\// ? $_ : $gEpocroot . PathConv($_, 0, 1, $gEpocdrive),
        map(PathConv($_, 0, 0, $gEpocdrive), @incdir)));
}


###############################################################################
#

sub SetVerbose($;$)
{
    my $verbose = Trim(shift());
    $verbose = 127 if $verbose =~ /^debug$/i;
    $gVerbose = int($1), return if ($verbose =~ /^(\d+)$/) && ($1 < 128);
    $gVerbose = 1;
    warn("Verbose level `$verbose' is not integer between 0 - 127\n") if !shift();
}

sub CloseLog()
{
    close(LOG) if $gLogfile;
    $gLogfile = "";
}


###############################################################################
#

sub RunIMakerCmd($$$$$@)
{
    my ($makecmd, $cmdarg, $tgtext, $mklevel, $skipsteps, %prevtgt) = @_;
    $ENV{IMAKER_MKLEVEL} = $mklevel;

    ($cmdarg, my $hptgt, my @targets) = HandleCmdArg($cmdarg);

    foreach my $tgt (@targets) {
        my $skipstep = ($tgt =~ s/#$//) || $skipsteps;
        (my $target = "$tgt$tgtext") =~ s/(\[\d+\])(.+)$/$2$1/;
        if ($target eq "menu") {
            ($cmdarg, $target) = Menu($cmdarg);
            next if ($target eq "menu");
            ($cmdarg) = HandleCmdArg($cmdarg);
        }
        $prevtgt{$target =~ /^([^-]+)/ ? $1 : $target} = 1;
        push(@gReport, Trim((($target !~ /^(.+)\[\d+\]$/) || ($gVerbose & 64) ? $target : $1) .
            ($skipstep ? "#" : "") . " $hptgt"), -1, -$mklevel - 1);
        my $tgtind  = $#gReport;
        my @targets = RunMakeCmd("$makecmd $cmdarg" . ($target eq "defaultgoals" ? "" : " \"$target\"") .
            join("", map(" \"$_\"", split(/\s+/, $hptgt))), $skipstep);
        $gReport[$tgtind - 2] .= " (intermediate)" if @targets;
        $gReport[$tgtind - 1] = pop(@gStepDur);
        $gReport[$tgtind] = $mklevel + 1 if !$gError;
        delete(@gReport[$tgtind - 2 .. $tgtind]) if (@targets && !$gError && !($gVerbose & 64));
        map {
            RunIMakerCmd($makecmd, "$cmdarg $_ $hptgt", $target =~ /(-.*)$/ ? $1 : "", $mklevel + 1, $skipstep, %prevtgt)
                if !exists($prevtgt{$_});
        } @targets;
    }
}

sub RunMakeCmd($$)
{
    ($gStartmk, $gMakecmd, $gError) = (time(), Trim(shift()), 0);
    my ($skipstep, $mkstart, $start, $restart, $cwd, %env) = (shift(), 0, 0, 0, Cwd::cwd(), %ENV);
    my @stepdur = my @targets = ();
    $ENV{IMAKER_MKRESTARTS} = -1;

    do {
        InitMkglobals();
        ($gTgterr, my $printvar, my @steps) = (1, "", ());
        $ENV{IMAKER_MKRESTARTS}++;

        if ($gExportvar{""}) {
            if (!$ENV{IMAKER_EXPORTMK}) {
                (my $tmpfh, $ENV{IMAKER_EXPORTMK}) = File::Temp::tempfile(
                    File::Spec->tmpdir() . "/imaker_temp_XXXXXXXX", SUFFIX => ".mk", UNLINK => 1);
                close($tmpfh);
                $ENV{IMAKER_EXPORTMK} =~ tr-\\-\/-;
            }
            WriteFile($ENV{IMAKER_EXPORTMK}, "# Generated temporary makefile `$ENV{IMAKER_EXPORTMK}'\n" .
                "ifndef __IMAKER_EXPORTMK__\n__IMAKER_EXPORTMK__ := 1\n" .
                join("", map(/^([^:]+)(?:\:(.+))?$/ && !defined($2) ? "$1=$gExportvar{$_}\n" :
                    "ifeq (\$(filter $1,\$(TARGETNAME)),)\n$2=$gExportvar{$_}\nendif\n",
                        sort({($a =~ /([^:]+)$/ && uc($1)) cmp ($b =~ /([^:]+)$/ && uc($1))}
                            grep(!/^(?:|.*[+:?])$/, keys(%gExportvar))))) .
                "else\n" .
                join("", map(/^\d{3}(.+[+:?])$/ ? "$1=$gExportvar{$_}\n" : (), sort({$a cmp $b} keys(%gExportvar)))) .
                "endif # __IMAKER_EXPORTMK__\n", "", "q", 1);
            $gExportvar{""} = 0;
        }

        open(MCMD, "$gMakecmd 2>&1 |");
        while (local $_ = <MCMD>) {
            chomp();
            DPrint(1, "$_\n"), next if !s/^#iMaker\x1E//;
#           DPrint(64, "#iMaker#$_\n");

            if (/^BEGIN$/) {
                $mkstart = time();
                $start = $mkstart if !$start;
                next;
            }
            if (/^STEPS=(.*)$/) {
                my $steps = $1;
                @steps = split(/\s+/, $steps), next if ($steps !~ s/^target://);
                @targets = grep($_ ne "", map(Trim($_), split(/(?<!\\)\|/, $steps)));
                next;
            }
            $gImgtype   = $1,    next if /^IMAGE_TYPE=(.*)$/;
            $gKeepgoing = $1,    next if /^KEEPGOING=(.*)$/;
            $gPrintcmd  = $1,    next if /^PRINTCMD=(.*)$/;
            SetVerbose($1),      next if /^VERBOSE=(.*)$/;
            $gStepIcmd{$1} = $2, next if /^((?:BUILD|CLEAN|INIT|REPORT)_\S+?)=(.*)$/;

            if (/^env (\S+?)=(.*)$/) {
                DPrint(64, "$1 = `" . ($ENV{$1} = $2) . "'\n")
                    if (!defined($ENV{$1}) || ($ENV{$1} ne $2));
                next;
            }
            if (/^var (\S+?)=(.*)$/) {
                my ($var, $val) = ($1, $2);
                my $upd = ($var !~ s/\?$//);
                $gExportvar{$var} = $val, $gExportvar{""}++
                    if (!exists($gExportvar{$var}) || ($upd && $gExportvar{$var} ne $val));
                next;
            }
            if (/^print (\d+) (\S+?)=(.*)$/) {
                $printvar  = ("=" x 79) . sprintf("\n%-$1s = `$gMakecmd'\n", "Make command") if ($printvar eq "");
                $printvar .= sprintf("%-$1s = `$3'\n", $2);
                next;
            }

            push(@stepdur, [$restart ? "ReMake" : "Make", Sec2Min(time() - $mkstart)]) if /^END$/;
            PrintEnv(2);
            DPrint(2, $printvar);
            die("Unknown iMaker entry: `$_'\n"), next if !/^END$/;

            pop(@steps) if ($restart = (@steps && $steps[$#steps] eq "RESTART"));
            my $durstr = "";
            foreach my $step (@steps) {
                next if $skipstep;
                RunStep($step);
                my ($cmddur, $stepdur) = (0, pop(@gStepDur));
                $durstr = Sec2Min($stepdur);
                if (@gStepDur) {
                    $durstr .= " (";
                    foreach my $dur (@gStepDur) {
                        $cmddur += $dur;
                        $durstr .= Sec2Min($dur) . " + ";
                    }
                    $durstr .= Sec2Min($stepdur - $cmddur) . ")";
                }
                push(@stepdur, [$step, $durstr]);
            }

            $printvar = "";
            my @env = ($ENV{IMAKER_EXPORTMK}, $ENV{IMAKER_MKRESTARTS});
            %ENV = %env;
            ($ENV{IMAKER_EXPORTMK}, $ENV{IMAKER_MKRESTARTS}) = @env;
            InitMkglobals();
            ChangeDir($cwd);

            last if $restart;

            my ($maxilen, $maxslen, $maxdlen) = (length(@stepdur . ""),
                Max(map(length(@$_[0]), @stepdur)), Max(8, map(length(@$_[1]), @stepdur)));
            DPrint(2, "=" x 79 . "\nStep" . " " x ($maxilen + $maxslen - 1) . "Duration\n" .
                "=" x ($maxilen + $maxslen + 2) . " " . "=" x $maxdlen . "\n",
                map(sprintf("%${maxilen}s. %-${maxslen}s", $_ + 1, $stepdur[$_][0]) .
                    " $stepdur[$_][1]\n", 0 .. $#stepdur),
                "-" x ($maxilen + $maxslen + 2) . " " . "-" x $maxdlen . "\n" .
                "Total" . " " x ($maxilen + $maxslen - 2) . Sec2Min(time() - $start) . "\n");
            ($start, @stepdur) = (time(), ());
        }
        close(MCMD);
        die("\n") if ($? >> 8);
        die("Command `$gMakecmd' failed in `" . GetAbsDirname(".") . "'.\n") if ($gTgterr = $gError);
        CloseLog();
    } until !$restart;
    push(@gStepDur, time() - $gStartmk);
    return(@targets);
}


###############################################################################
#

sub HandleCmdArg($)
{
    my $cmdarg = shift();
    my $origarg = $cmdarg = (defined($cmdarg) ? $cmdarg : "");

    my @cmdout = qx($ENV{PERL} -x $0 --splitarg $cmdarg);
    die("Can't parse Make arguments: `$cmdarg'.\n") if $?;

    map {
        chomp();
        s/ /\x1E/g;
        s/\"/\\\"/g;
        s/(\\+)$/$1$1/;
    } @cmdout;
    $cmdarg = " " . join(" ", @cmdout) . " ";

    if ($cmdarg =~ /^.* VERBOSE\x1E*=(\S*) /) {
        (my $verbose = $1) =~ s/\x1E/ /g;
        SetVerbose($verbose, 1);
    }

    if ($cmdarg =~ /\s+--?conf=(\S*)\s+/) {
        (my $prj = $1) =~ /(.*?)(?:;(.*))?$/;
        ($prj, my $conf) = ($1, defined($2) ? $2 : "");
        $cmdarg =~ s/\s+--?conf=\S*\s+/ USE_CONE=mk CONE_PRJ=$prj CONE_CONF=$conf cone-pre defaultgoals /;
    }

    $cmdarg = " " . HandleExtCmdArg($cmdarg) . " " if $gImakerext;

    $gMakecmd = "$ENV{IMAKER_MAKE} -f $0" . join("", map(" \"$_\"", split(/\s+/, Trim($cmdarg))));
    warn("Can't parse Make targets.\n")
        if (!(my $targets = (qx($gMakecmd 2>&1) =~ /\|MAKECMDGOALS=(.*?)\|/ ? " $1 " : "")) &&
            ($cmdarg !~ /\s-(?:-?v(?:ersion?|ersi?|er?)?|versio\S+)\s/));

    GetConfmkList() if
        grep(!/^(help(-.+)?|print-.+)$/ || /^help-config$/, my @targets = split(/\s+/, Trim($targets)));

    my ($mkfile, $mkfiles, $hptgt) = ("", "", "");
    map {
        $cmdarg =~ s/\s+\Q$_\E\s+/ /;
        if (exists($gConfmkList{$_})) {
            ($mkfile = $gConfmkList{$_}) =~ s/ /\x1E/g;
            $mkfiles .= " -f $mkfile";
            $targets =~ s/\s+\Q$_\E\s+/ /;
        }
    } @targets;
    $cmdarg = "$mkfiles$cmdarg";

    map { $targets =~ s/\s\Q$_\E\s/ /; $hptgt .= " $_" }
        grep(/^help-.+$/ && !/^help-config$/, @targets);
    map { $targets =~ s/\s\Q$_\E\s/ /; $hptgt .= " $_" }
        grep(/^print-.+$/, @targets);
    $hptgt = Trim($hptgt);

    if ($targets =~ s/ default(?= )//g) {
        ($targets = Trim($targets)) =~ s/ /\x1E/g;
        $cmdarg .= "TARGET_DEFAULT=$targets" if ($targets ne "");
        $targets = "default";
    }
    @targets = ("defaultgoals@targets") if
        !(@targets = map(s/\x1E/ /g ? $_ : $_, split(/\s+/, Trim($targets)))) || ("@targets" eq "#");

    $mkfiles = "";
    while ($cmdarg =~ s/\s+(-f\s?|--(?:file?|fi?|makefile?|makefi?|make?)[=\s]|IMAKER_CONFMK\x1E*=)(\S+)\s+/ /) {
        $mkfile = $2;
        ($mkfile = GetAbsFname(scalar($mkfile =~ s/\x1E/ /g, $mkfile))) =~ s/ /\\\x1E/g
            if ($1 !~ /^IMAKER_CONFMK/);
        $mkfiles .= ($mkfiles eq "" ? "" : chr(0x1E)) . $mkfile;
    }
    while ($cmdarg =~ s/\s+(\S+?)\x1E*([+:?])=\x1E*(\S+?)\s+/ /) {
        ($gExportvar{sprintf("%03s", ++$gExportvar{""}) . "$1$2"} = $3) =~ s/\x1E/ /g;
    }
    $cmdarg = join(" ", map(scalar(s/\x1E/ /g, "\"$_\""), split(/\s+/, Trim($cmdarg .
        ($mkfiles eq "" && ($ENV{IMAKER_MKLEVEL} || grep(/^default$/, @targets)) ? "" : " IMAKER_CONFMK=$mkfiles")))));

    DPrint(2, "HandleCmdArg: `$origarg' => `$cmdarg', `" . join(" ", @targets) . "', `$hptgt'\n");
    return($cmdarg, $hptgt, @targets);
}


###############################################################################
#

sub MenuRuncmd($)
{
    $ENV{IMAKER_CMDARG} = shift();
    return(map(chomp() ? $_ : $_, qx($ENV{PERL} -x $0 2>&1)));
}

sub Menu($)
{
    (my $cmdarg = " " . shift() . " ") =~ s/\s+"IMAKER_CONFMK="\s+/ /;
    my ($prodind, $product, @product) = (0, "", ());
    my ($tgtind, $target, $tgtcols, $tgtrows, @target)  = (0, "", 4, 0, ());
    my ($vartype, $varudeb, $varsym);
    my $cfgfile = "./imaker_menu.cfg";

    $cmdarg = ($cmdarg =~ /^\s*$/ ? "" : " " . Trim($cmdarg));
    open(FILE, "<$cfgfile") and
        (($prodind, $tgtind, $vartype, $varudeb, $varsym) = map(chomp() ? $_ : $_, <FILE>)) and close(FILE);
    ($prodind, $tgtind, $vartype, $varudeb, $varsym) =
        ($prodind || 0, $tgtind || 0, $vartype || "rnd", $varudeb || 0, $varsym || 0);

    while (1) {
        print("\nPRODUCTS\n--------\n");
        #
        if (!@product) {
            @product = sort({lc($a) cmp lc($b)} grep($_ ne "", keys(%gConfmkList)));
            $prodind = 0 if ($prodind > @product);
        }
        $product = ($prodind ? " $product[$prodind - 1]" : "");
        my $maxlen = Max(map(length($_), @product));
        map {
            printf(" %" . (length(@product)) . "s) %-${maxlen}s  %s\n", $_ + 1, $product[$_], $gConfmkList{$product[$_]});
        } (0 .. $#product);
        print(" NO PRODUCTS FOUND!\n") if !@product;

        print("\nTARGETS\n-------\n");
        #
        if (!@target) {
            @target = grep(s/^== (.+) ==$/$1/, MenuRuncmd("$product PRINTCMD=0 VERBOSE=1 help-target-*-wiki"));
            $tgtind = 0 if ($tgtind > @target);
            $tgtrows = int($#target / $tgtcols + 1);
            my $maxind = 0;
            map {
                if (!($_ % $tgtrows)) {
                    $maxind = length(Min($_ + $tgtrows, $#target + 1)) + 1;
                    $maxlen = Max(map(length(), @target[$_ .. Min($_ + $tgtrows - 1, $#target)]));
                }
                $target[$_] = sprintf("%${maxind}s) %-${maxlen}s", "t" . ($_ + 1), $target[$_]);
            } (0 .. $#target);
        }
        ($target = ($tgtind ? $target[$tgtind - 1] : "")) =~ s/^.+?(\S+)\s*$/$1/;
        foreach my $row (1 .. $tgtrows) {
            foreach my $col (1 .. $tgtcols) {
                my $ind = ($col - 1) * $tgtrows + $row - 1;
                print(($ind < @target ? " $target[$ind]" : "") . ($col != $tgtcols ? " " : "\n"));
            }
        }
        print(" NO TARGETS FOUND!\n") if !@target;

        print("\nCONFIGURATION\n-------------\n");
        #
        print(
          " Product: " . ($prodind ? $product[$prodind - 1] : "NOT SELECTED!") . "\n" .
          " Target : " . ($tgtind ? $target : "NOT SELECTED!") . "\n" .
          " Type   : " . ucfirst($vartype) . "\n" .
          " Debug  : " . ($varudeb ? ($varudeb =~ /full/i ? "Full debug" : "Enabled") : "Disabled") . "\n" .
          " Symbols: " . ($varsym ? "Created\n" : "Not created\n"));

        print("\nOPTIONS\n-------\n");
        #
        print(
          " t) Toggle type between rnd/prd/subcon\n" .
          " u) Toggle debug between urel/udeb/udeb full\n" .
          " s) Toggle symbol creation on/off\n" .
          " r) Reset configuration\n" .
          " h) Print usage information\n" .
          " x) Exit\n\n" .
          "Hit Enter to run: imaker$product$cmdarg TYPE=$vartype USE_UDEB=$varudeb USE_SYMGEN=$varsym $target\n");

        print("\nSelection: ");
        #
        my $input = <STDIN>;
        ($input = (defined($input) ? $input : "?")) =~ s/^\s*(.*?)\s*$/\L$1\E/;

        if ($input =~ /^(\d+)$/ && ($1 > 0) && ($1 <= @product) && ($1 != $prodind)) {
            $prodind = $1;
            ($tgtind, @target) = (0, ());
        }
        elsif ($input =~ /^t(\d+)$/ && ($1 > 0) && ($1 <= @target) && ($1 != $tgtind)) {
            $tgtind = $1;
        }
        elsif ($input eq "t") {
            $vartype = ($vartype =~ /rnd/i ? "prd" : ($vartype =~ /prd/i ? "subcon" : "rnd"));
        }
        elsif ($input eq "u") {
            $varudeb = (!$varudeb ? 1 : ($varudeb !~ /full/i ? "full" : 0));
        }
        elsif ($input eq "s") {
            $varsym = ($varsym ? 0 : 1);
        }
        elsif ($input eq "r") {
            ($prodind, @product) = (0, ());
            ($tgtind, @target)  = (0, ());
            ($vartype, $varudeb, $varsym) = ("rnd", 0, 0);
        }
        elsif ($input eq "h") {
            print("\nTODO: Help");
            sleep(2);
        }
        elsif ($input =~ /^(x|)$/) {
            open(FILE, ">$cfgfile") and
                print(FILE map("$_\n", ($prodind, $tgtind, $vartype, $varudeb, $varsym))) and close(FILE);
            return(("", "menu")) if ($input eq "x");
            $cmdarg = "$product$cmdarg TYPE=$vartype USE_UDEB=$varudeb USE_SYMGEN=$varsym";
            $ENV{IMAKER_CMDARG} = Trim("$cmdarg $target");
            return(($cmdarg, $target eq "" ? "defaultgoals" : $target));
        }
    }
}


###############################################################################
#

sub Install($$$)
{
    my ($clean, $bldinf, $destdir) = @_;
    my $srcdir = GetDirname($bldinf = GetAbsFname($bldinf));
    $destdir = GetAbsDirname($destdir) if $destdir;

    print(($clean ? "\nCleaning" : "\nInstalling") . " `$bldinf'" . ($destdir ? " to `$destdir'\n" : "\n"));

    my $export = 0;
    foreach (grep(!/^\s*\/\//, ReadFile($bldinf, 0))) {
        $export = 1, next if /^\s*PRJ_EXPORTS\s*$/i;
        next if !$export;
        Install($clean, "$srcdir$1", $destdir), next if /^\s*#include\s+"(.+)"\s*$/;
        die("Unknown line `$_'.\n") if !/^\s*(\S+)\s+(.+?)\s*$/;
        my ($src, $dest) = ("$srcdir$1", $2);
        $dest = "$gEpocroot/epoc32$dest" if ($dest =~ s/^\+//);
        $dest .= GetBasename($src) if ($dest =~ s/\s+\/\/$//);
        ($src, $dest) = (GetAbsFname($src), GetAbsFname($dest));
        next if ($destdir && ($dest !~ /^$gEpocroot\/epoc32\/tools\//i));
        $dest = "$destdir/" . GetBasename($dest) if $destdir;
        print(($clean ? "Delete" : "Copy `$src' =>") . " `$dest'\n");
        unlink($dest);
        die("Deletion failed.\n") if ($clean && -e($dest));
        next if $clean;
        File::Path::mkpath(GetDirname($dest));
        File::Copy::copy($src, $dest) or die("Copying failed.\n");
        chmod(0777, $dest);
    }
}


###############################################################################
#

END {
    if (!$gArgv) {
        (my $keepgoing, $gStartmk) = ($gKeepgoing, time() - $gStartmk);
        $gKeepgoing = 1;
        SetLogfile($gLogfiles{__prev__}) if %gLogfiles;
        PrintEnv(0) if $gError;
        die("Command `$gMakecmd' failed in `" . GetAbsDirname(".") . "'.\n")
            if ($gTgterr && !$keepgoing);

        map { UnsubstDrive($_) } sort({$a cmp $b} keys(%gSubstdrv));

        @gIcmd = @gReport;
        (my $report, @gReport) = (2, ());
        my ($maxtlen, $maxvlen, %uniq) = (0, 0, ());
        while (@gIcmd) {
            my ($tgtvar, $durval, $type) = (GetIPar(1), GetIPar(1), GetIPar(1));
            if ($type =~ /^-?\d+$/) {
                push(@gReport, [$tgtvar, $durval, $type]);
                ($maxtlen, %uniq) = (Max($maxtlen, length($tgtvar)), ());
            } else {
                $report = 1, push(@gReport, [$tgtvar, $durval, $type])
                    if ($tgtvar ne "") && !($uniq{"$tgtvar|$durval"}++);
                $maxvlen = Max($maxvlen, length($tgtvar));
            }
        }

        my ($tgtcnt, $warn) = (0, 0);
        DPrint($report, "=" x 79 . "\n" . join("\n", map(@$_[2] =~ /^-?\d+$/ ?
            ($tgtcnt++ ? "-" x 79 . "\n" : "") .
            "Target: " . sprintf("%-${maxtlen}s", @$_[0]) .
            "  Duration: " . Sec2Min(@$_[1] < 0 ? $gStartmk : @$_[1]) .
            "  Status: " . (@$_[2] < 0 ? ($warn = "FAILED") : "OK")
            : sprintf("%-${maxvlen}s", @$_[0]) . " = `@$_[1]'" .
                ((@$_[2] =~ /^[fd]$/i) && !-e(@$_[1]) ? " - DOESN'T EXIST" : ""), @gReport)) .
            (@gReport ? "\n" . "-" x 79 . "\n" : "") .
            "Total duration: " . Sec2Min(time() - $gStarttime) .
            "  Status: " . ($gError && !$keepgoing ? "FAILED" : "OK" .
                ($warn ? " (with keep-going)" : "")) .
            "\n" . "=" x 79 . "\n");

        warn("\$_ has been changed in an uncontrolled manner!\n")
            if !/^default input and pattern-searching space$/;
        CloseLog();
        exit(1) if ($gError && !$keepgoing);
    }
}


__END__ # OF IMAKER.PL
