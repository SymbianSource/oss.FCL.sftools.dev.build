#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Symbian Foundation License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: iMaker common Perl routines
#



use subs qw(CORE::GLOBAL::die);

package imaker;

use strict;
use warnings;
use Archive::Zip qw(:ERROR_CODES);
use Archive::Zip::Tree;
use Cwd;
use Digest::MD5 qw(md5_hex);
use File::Basename;
use File::Copy;
use File::Find;
use File::Path;
use File::Spec;
use POSIX qw(strftime);
use Time::Local;
use XML::Simple;

sub Max(@);
sub Min(@);
sub Quote($);
sub Unquote($);
sub Byte2Str($@);
sub Str2Byte($);
sub Str2Xml($);
sub Ascii2Uni($);
sub Uni2Ascii($);
sub GetTimestamp();
sub Sec2Min($);
sub Wcard2Restr($);
sub Wcard2Regex($);
sub DPrint($@);
sub Echo($$$);
sub PathConv($;$$);
sub ParseFiles($);
sub GlobFiles($);
sub GetBasename($);
sub GetDirname($);
sub GetAbsDirname($;$$);
sub GetAbsFname($;$$);
sub GetRelFname($;$$$);
sub GetWriteFname($);
sub GetFreeDrive();
sub Search($$$$$\@\$);
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
sub DeleteFile($;$);
sub FindFile($$$$);
sub HeadFile($$$);
sub TailFile($$$);
sub TypeFile($;$);
sub WriteFile($$$;$);
sub UnzipFile($$);
sub Zip($$$$@);
sub Move($$);
sub Touch($$);
sub SetLogfile($);
sub WidgetUnzip($$$);
sub RunSystemCmd($$;$);
sub ParseSystemCmd($$$);
sub GenExclfile($$$$$);
sub GenIbyfile($$$@);
sub GenMakefile($$$$$);
sub AddImageHeader($$$$$);
sub Sleep($);
sub FindSOSFiles($$$$$);
sub CheckTool(@);
sub GetIPar();
sub PeekICmd($);
sub GetICmd();
sub EndICmd();
sub RunICmd();
sub RunIExtCmd($);
sub GetFeatvarIncdir($;$);
sub SetVerbose($);
sub ReadICmdFile($);
sub CloseLog();
sub MakeStep($$$$$$);
sub HandleCmdArg($);
sub HandleExtCmdArg($);
sub MenuRuncmd($);
sub Menu($$$);

use constant READBUFSIZE => 2097152;  # 2 MB

our $STARTSTR = '>>>[START]=========8<==========8<==========8<==========8<==========8<==========';
our $ENDSTR   = '==========>8==========>8==========>8==========>8==========>8===========[END]<<<';

our $gBuflog     = 1;
our $gCmdcnt     = 0;
our @gCmdoutbuf  = ();
our $gEpoc32;
our @gFindresult = ();
our $gError      = 0;
our @gIcmd       = ();
our $gImakerext  = 0;
our $gKeepgoing  = 0;
our @gLogbuf     = ();
our $gLogfile    = "";
our $gMakestep   = "";
our $gOutfilter  = "";
our $gParamcnt   = 0;
our $gPrintcmd   = 0;
our @gStepDur    = ();
our %gStepIcmd   = ();
our $gVerbose    = 1;
our $gWarn       = 0;
our $gWinOS      = ($^O =~ /win/i);
our $gWorkdir    = "";
our $gWorkdrive  = (Cwd::cwd() =~ /^([a-z]:)/i ? $1 : "");
our @iVar        = ();  # General purpose variable to be used from $(call peval,...)

BEGIN {
    ($gEpoc32 = "$ENV{EPOCROOT}epoc32") =~ tr/\\/\//;
    push(@INC, "$gEpoc32/tools");
    eval { require featurevariantparser };
}


###############################################################################
#

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
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec, int(($yday + 1) / 7) + 1));
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


###############################################################################
#

sub DPrint($@)
{
    my ($verbose, @outlist) = @_;
    map { tr/\x00\x1F/#/ } @outlist;
    print(@outlist) if !$verbose || ($verbose & $gVerbose);
    push(@gLogbuf, @outlist) if ($verbose < 32) || ($verbose & $gVerbose);
    return if $gBuflog && !$gLogfile;
    print(LOG @gLogbuf) if $gBuflog;
    @gLogbuf = ();
}

sub Echo($$$)
{
    return if $gPrintcmd;
    my ($verbose, $str) = (shift(), shift());
    DPrint($verbose, shift() ? "$str\n" : Unquote($str));
}


###############################################################################
#

# Overload die
*CORE::GLOBAL::die = sub {
    $gError = 1;
    return if PeekICmd("iferror");
    CORE::die(@_) if !$gKeepgoing;
    warn(@_);
};

# Handler for __DIE__ signal
$SIG{__DIE__} = sub {
    select(STDERR);
    DPrint(0, "*** Error: " . ($gMakestep ? "($gMakestep): " : "") . $_[0]);
    select(STDOUT);
    exit(1);
};

# Handler for __WARN__ signal
$SIG{__WARN__} = sub {
    select(STDERR);
    my $msg = ($gMakestep ? "($gMakestep): " : "") . $_[0];
    if ($gError) { DPrint(0, "*** Error: $msg") }
    else { DPrint(127, "Warning: $msg") }
    select(STDOUT);
    $gError = $gWarn = 0;
};


###############################################################################
# File operations

sub PathConv($;$$)
{
    my $path = shift();
    if (shift()) { $path =~ tr-\/-\\- }
    else { $path =~ tr-\\-\/- }
    if (shift()) { $path =~ s/^(?![a-z]:)/$gWorkdrive/i }
    else { $path =~ s/^$gWorkdrive//i }
    $path =~ s/^([a-z]:)/\u$1/;
    return($path);
}

sub ParseFiles($)
{
    my ($file, @files) = (shift(), ());
    push(@files, defined($1) ? $1 : (defined($2) ? $2 : ())) while $file =~ /""|"+(.+?)"+|((\\\s|\S)+)/g;
    return(@files);
}

sub GlobFiles($)
{
    return(@gFindresult) if (my $file = shift()) =~ /^__find__$/i;
    return(map(/[\*\?]/ ? glob(/\s/ ? "\"$_\"" : $_) : $_, ParseFiles($file)));
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

sub GetAbsDirname($;$$)
{
    (my $dir = shift()) =~ s/^>>?(?!>)//;
    my $absdir = "";
    eval { local $SIG{__DIE__}; $absdir = Cwd::abs_path($dir) };
    return(PathConv($absdir || File::Spec->rel2abs($dir,
        $dir !~ /^$gWorkdrive/i && $dir =~ /^([a-z]:)/i ? "$1/" : ""), shift(), shift()));
}

sub GetAbsFname($;$$)
{
    my $file = shift();
    return($file) if $file eq "" || $file =~ /STD(IN|OUT|ERR)$/;
    my $append = ($file =~ s/^>>(?!>)// ? ">>" : "");
    return($append . PathConv(File::Spec->catpath("", GetAbsDirname(GetDirname($file)), GetBasename($file)), shift(), shift()));
}

sub GetRelFname($;$$$)
{
    my ($file, $base) = (shift(), shift());
    my $append = ($file =~ s/^>>(?!>)// ? ">>" : "");
    return($append . PathConv(File::Spec->abs2rel($file, GetAbsDirname(defined($base) && ($base ne "") ? $base : ".")), shift(), shift()));
}

sub GetWriteFname($)
{
    (my $file = shift()) =~ s/^>?/>/;
    return($file);
}

sub GetFreeDrive()
{
    for my $drive ("F", "A".."E", "G".."Z") {
        return("$drive:") if
            !system("subst $drive: . >nul") and !system("subst $drive: /d >nul");
    }
    die("No free drive letter available.\n");
}

sub Search($$$$$\@\$)
{
    my ($dir, $inclre, $exclre, $subdir, $finddir, $files, $total) = @_;
    my @dir = ();

    map {
        my $isfile = -f();
        my $isdir  = !$isfile && -d();
        if ($finddir ? $isdir : $isfile) {
            ++$$total;
            my $fname = File::Basename::basename($_);
            push(@$files, $_) if ($fname =~ /$inclre/ && $fname !~ /$exclre/);
        }
        push(@dir, $_) if $isdir && $subdir;
    } sort({lc($a) cmp lc($b)} ($dir =~ /\s/ ? <"$dir/*"> : <$dir/*>));

    map { Search($_, $inclre, $exclre, 1, $finddir, @$files, $$total) } @dir;
}

sub Find($$$$$\$)
{
    my ($dir, $inclpat, $exclpat, $subdir, $finddir, $total) = @_;
    ($dir, $$total) = (GetAbsDirname($dir), 0);
    my ($inclre, $exclre, @files) = ("", "", ());
    if ($inclpat =~ /^\//) {
        $inclre = eval("qr$inclpat");
        $inclpat = "";
    } else {
        $inclre = join("|", map(Wcard2Restr($_), split(/\s+/, $inclpat)));
        $inclre = qr/^($inclre)$/i;
    }
    if ($exclpat =~ /^\//) {
        $exclre = eval("qr$exclpat");
        $exclpat = "";
    } else {
        $exclre = join("|", map(Wcard2Restr($_), split(/\s+/, $exclpat)));
        $exclre = qr/^($exclre)$/i;
    }
    DPrint(16, "Find" . ($finddir ? "Dir" : "File") . ": Directory `$dir'" . ($subdir ? " and subdirectories" : "") .
        ", pattern `" . ($inclpat ne "" ? "$inclpat' $inclre" : "$inclre'") .
        ($exclre eq qr/^()$/i ? "" : " excluding `" . ($exclpat ne "" ? "$exclpat' $exclre" : "$exclre'")));
    Search($dir, $inclre, $exclre, $subdir, $finddir, @files, $$total);
    DPrint(16, ", found " . @files . "/$$total " . ($finddir ? "directories\n" : "files\n"));
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
        eval { local $SIG{__DIE__}; local $SIG{__WARN__} = sub{}; File::Path::rmtree($dir) };
        return if !-d($dir);
    }
    $dir = "Can't delete directory `$dir'.\n";
    shift() ? warn($dir) : die($dir);
}

sub FindDir($$$$)
{
    my ($dir, $inclpat, $exclpat, $opt) = @_;
    @gFindresult = () if (($opt = (defined($opt) ? $opt : "")) !~ /a/);
    push(@gFindresult, Find($dir, $inclpat, $exclpat, $opt =~ /r/, 1, local $_));
}

sub MakeDir($)
{
    my $dir = GetAbsDirname(shift());
    return if -d($dir);
    eval { local $SIG{__DIE__}; File::Path::mkpath($dir) };
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
    $gWorkdrive = (Cwd::cwd() =~ /^([a-z]:)/i ? $1 : "");
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
    my ($buf, $srctmp) = (undef, "$src.CUT");

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
    my $append = ($dest =~ /^>>[^>]/);
    $dir  = defined($dir) && $dir || !$append && -d($src);
    $src  = ($dir ? GetAbsDirname($src)  : GetAbsFname($src));
    $dest = ($dir ? GetAbsDirname($dest) : GetAbsFname($dest));
    if ($append) {
        my $buf;
        OpenFile(*INFILE, $src, 1, "AppendFile: `$src' => `$dest'\n") or die("Can't read file `$src'.\n"), return;
        OpenFile(*OUTFILE, $dest, 1, "") or die("Can't write to `$dest'.\n"), return;
        print(OUTFILE $buf) while read(INFILE, $buf, READBUFSIZE);
        return if close(INFILE) && close(OUTFILE);
    }
    elsif (!$dir) {
        DPrint(16, "CopyFile: `$src' => `$dest'\n");
        warn("CopyFile: Destination file `$dest' already exists\n") if -f($dest);
        File::Copy::copy($src, $dest) and return;
    } else {
        DPrint(16, "CopyDir: `$src' => `$dest'\n");
#        warn("CopyDir: Destination directory `$dest' already exists\n") if -d($dest);
        !RunSystemCmd('xcopy "' . PathConv($src, 1) . '" "' . PathConv("$dest/" . GetBasename($src), 1) . '" /e /i /y /z', "") and return;
    }
    die("Can't copy `$src' to `$dest'.\n");
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
    @gFindresult = () if (($opt = (defined($opt) ? $opt : "")) !~ /a/);
    push(@gFindresult, Find($dir, $inclpat, $exclpat, $opt =~ /r/, 0, local $_));
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
    DPrint(8, "$STARTSTR\n");
    read(FILE, $str, -s($file));
    if ($mode eq "b") {
        DPrint(1, Byte2Str(0, map(ord(), split(//, $str))));
    } else {
        $str = Uni2Ascii($str) if $mode eq "u";
        DPrint(1, map("$_\n", grep(!$gOutfilter || /$gOutfilter/i, split(/\n/, $str))));
        $gOutfilter = "";
    }
    DPrint(8, "$ENDSTR\n");
    close(FILE);
}

sub WriteFile($$$;$)
{
    my ($file, $str, $mode) = (GetAbsFname(shift()), shift(), shift() || "");
    OpenFile(*FILE, GetWriteFname($file), $mode) or
        die("Can't write to `$file'.\n"), return;
    if ($mode eq "b") {
        my @byte = Str2Byte($str);
        DPrint(64, Byte2Str($file =~ s/^>>(?!>)// ? -s($file) : 0, @byte));
        print(FILE map(chr(), @byte));
    } else {
        $str = Unquote($str) if !shift();
        $str = Ascii2Uni($str) if $mode eq "u";
        print(FILE $str);
    }
    close(FILE);
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
        eval { local $SIG{__DIE__}; $error = ($zip->extractMember($file, "$dir/$file") != AZ_OK) };
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
    map {
        my $key = lc();
        $files{$key} = $_ if !exists($files{$key});
    } ($dir ? map(GetAbsDirname($_), grep(-d(), @_)) : map(GetAbsFname($_), grep(-f(), @_)));

    DPrint(16, ($dir ? "ZipDir: `$zipfile'$opt, " . keys(%files) . " directories" :
        "ZipFile: `$zipfile'$opt, " . keys(%files) . " files") . ($prefix ? ", prefix: $prefix\n" : "\n"));

    Archive::Zip::setErrorHandler(sub{});
    my ($error, $zip) = (0, Archive::Zip->new());
    $zip->zipfileComment("iMaker-created zip archive `$zipfile'$opt.");

    foreach my $file (sort({lc($a) cmp lc($b)} values(%files))) {
        my $newfile = $file;
        if ($opt !~ /j/) {
            $newfile =~ s/^.*?\/+/$prefix\// if $prefix ne "";
        } else {
            $newfile = ($dir ? "" : GetBasename($file)) if ($prefix eq "") || ($newfile !~ s/^$prefix//);
        }
        DPrint(16, "Add" . ($dir ? "Dir" : "File") . ": `$file'" . ($file ne $newfile ? " => `$newfile'" : "")) if $opt !~ /q/;
        eval {
            local $SIG{__DIE__}; local $SIG{__WARN__} = sub{ $gWarn = 1 };
            $error = ($dir ? $zip->addTree($file, $newfile) != AZ_OK :
                !$zip->addFile($file, $newfile)) || $gWarn;
        };
        DPrint(16, $error ? " Failed\n" : "\n") if $opt !~ /q/;
        warn("Can't add " . ($dir ? "directory tree" : "file") . "`$file' to zip archive `$zipfile'.\n") if $error;
        $error = 0;
    }
    ($zip->writeToFileNamed($zipfile) == AZ_OK) or
        die("Can't create zip archive `$zipfile'.\n");
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

sub Touch($$)
{
    my ($file, $time) = (shift(), shift() =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/ ?
        Time::Local::timelocal($6, $5, $4, $3, $2 - 1, $1 - 1900) : time);
    my $dir = -d($file);
    $file = ($dir ? GetAbsDirname($file) : GetAbsFname($file));
    DPrint(16, "Touch" . ($dir ? "Dir" : "File") . ": `$file': " .
        POSIX::strftime("%Y-%m-%d,%H:%M:%S", localtime($time)) . "\n");
    utime($time, $time, $file) or
        die("Can't touch " . ($dir ? "directory" : "file") . " `$file'.\n");
}

sub SetLogfile($)
{
    $gBuflog = 0, return if !(my $file = GetAbsFname(shift()));
    CloseLog();
    OpenFile(*LOG, GetWriteFname($file), 0) or
        warn("Can't log to file `$file'.\n"), return;
    $gLogfile = $file;
}


###############################################################################
#

sub WidgetUnzip($$$)
{
    my ($wgzfile, $outdir, $plist) = (GetAbsFname(shift()), GetAbsDirname(shift()), shift());

    my $tmpdir = "$outdir/wgz_unzip_temp";
    DeleteDir($tmpdir);
    UnzipFile($wgzfile, $tmpdir);

    for my $dir (Find($tmpdir, "*", "", 0, 1, local $_)) {
        my $xml = undef;
        eval { local $SIG{__DIE__}; local $SIG{__WARN__} = sub{}; $xml = XMLin("$dir/$plist") };
        die("Can't find/parse XML file `$dir/$plist'.\n"), next if !defined($xml);
        my $id = "";
        for my $ind (0 .. @{$xml->{dict}{key}} - 1) {
            $id = $xml->{dict}{string}[$ind], last if $xml->{dict}{key}[$ind] =~ /^\s*Identifier\s*$/i;
        }
        die("Can't find Identifier from XML file `$dir/$plist'.\n"), next if $id eq "";
        Move($dir, "$outdir/$id/" . GetBasename($dir));
    }
    DeleteDir($tmpdir);
}


###############################################################################
#

sub RunSystemCmd($$;$)
{
    my ($cmd, $file, $ignorerr) = @_;
    DPrint(1, "$cmd\n"), return if $gPrintcmd;
    my $null = ($file =~ /^null$/i);
    $file = ($null ? "" : GetAbsFname($file));
    @gCmdoutbuf = ();
    DPrint(4, "RunSystemCmd(" . GetAbsDirname(".") . "): `$cmd'" .
        ($file ? ", redirect to: `$file'" : ($null ? ", redirect to null" : "")) .
        ($gOutfilter ? ", filter: `/$gOutfilter/i'" : "") . "\n");
    OpenFile(*FILE, GetWriteFname($file), 0) or
        (die("Can't write to `$file'.\n"), $file = "") if $file;
    my $dur = time();
    open(CMD, "$cmd 2>&1 |");
    DPrint(8, "$STARTSTR\n");
    while (my $line = <CMD>) {
        chomp($line);
        push(@gCmdoutbuf, $line);
        DPrint(8, "$line\n") if !$null && (!$gOutfilter || ($line =~ /$gOutfilter/i));
        print(FILE "$line\n") if $file;
    }
    close(CMD);
    close(FILE) if $file;
    push(@gStepDur, $dur = time() - $dur);
    $gOutfilter = "";
    my $error = ($? >> 8) && !$ignorerr && !$null;
    print(map("$_\n", @gCmdoutbuf)) if $error && $gVerbose && !($gVerbose & 8);
    $dur = Sec2Min($dur);
    DPrint(8, substr($ENDSTR, 0, -16) . $dur . substr($ENDSTR, length($dur) - 16) . "\n");
    die("Command `$cmd' failed (" . ($? >> 8). ").\n") if $error;
}


###############################################################################
#

sub ParseSystemCmd($$$)
{
    return if $gPrintcmd;
    my ($title, $regex, $file) = @_;
    $regex = ($regex =~ /^\// ? eval("qr$regex") : Wcard2Regex($regex));
    return if !(my @parse = grep(/$regex/, @gCmdoutbuf));
    if (!$file) {
        Echo(1, $title, 0);
        DPrint(1, map(sprintf("%" . length(@parse) . "s", $_) . ") $parse[$_ - 1]\n", 1 .. @parse));
        return;
    }
    OpenFile(*FILE, GetWriteFname($file = $title), 0) or
        die("Can't write to `$file'.\n"), return;
    print(FILE join("\n", @parse));
    close(FILE);
}


###############################################################################
#

sub GenExclfile($$$$$)
{
    return if $gPrintcmd;

    my ($exclfile, $base, $prefix, $addfiles) = (shift(), shift(), shift(), shift());
    my ($file, $rmfiles, %files) = ("", "", ());

    WriteFile($exclfile, "", "");
    $base = GetAbsDirname($base);

    foreach $file (ParseFiles(shift())) {
        $file =~ tr/\\/\//;
        $file =~ s/^\///;
        $file =~ s/\/$/\/\*/;
        $rmfiles .= ($rmfiles eq "" ? "" : "|") . Wcard2Restr($file);
    }
    $rmfiles = qr/^(?:$rmfiles)$/i;

    foreach $file (ParseFiles($addfiles)) {
        $file =~ tr/\\/\//;
        $file =~ /^\/?(?:(.*)\/)?(.+?)$/;
        (my $dir, $file) = ($base . (defined($1) ? "/$1" : ""), $2);
        map {
            $files{$_} = 1 if ($_ = GetRelFname($_, $base)) !~ $rmfiles;
        } ($file =~ /[\*\?]/ ? Find($dir, $file, "", 1, 0, local $_) : "$dir/$file");
    }

    map {
        $files{"$_/"} = 1 while (s/^(.*)\/.*?$/$1/) && !exists($files{"$_/"});
    } keys(%files);
    $files{""} = 1;

    WriteFile($exclfile, join("", map(($_ = "$prefix$_\n") =~ tr/\//\\/ ? $_ : $_, sort({lc($a) cmp lc($b)} keys(%files)))), "u", 1);
}

sub GenIbyfile($$$@)
{
    return if $gPrintcmd;

    my ($ibyfile, $srcdir, $subdir) = (GetAbsFname(shift()), shift(), shift());
    my ($header, $footer, $body, %files) = ("", "", "", ());

    foreach my $dir (split(/\s+/, $srcdir)) {
        $dir = GetAbsDirname($dir);
        my ($found, $total, $lines) = (0, 0, "");
        my @param = @_;
        while (@param) {
            my ($filepat, $format, @lines) = (shift(@param), shift(@param), ());
            $header = $format, next if $filepat =~ /^__header__$/i;
            $footer = $format, next if $filepat =~ /^__footer__$/i;
            foreach my $src (Find($dir, $filepat, "", $subdir, 0, $total)) {
                next if $files{$src};
                $files{$src} = 1;
                (my $line = $format) =~ s/%1/$src/g;
                $line =~ s/%2/GetRelFname($src, $dir, 1)/ge;
                $line =~ s/%3/GetRelFname($src, GetDirname($ibyfile))/ge;
                push(@lines, $line);
            }
            $found += @lines;
            $lines .= "//\n// Format: `$format', " . @lines . " files: `$filepat'\n" .
                (@lines ? "//\n" . join("\n", @lines) . "\n" : "");
        }
        $body .= "\n// Collected files $found/$total from directory `$dir'" .
            ($subdir ? " and subdirectories" : "") . "\n$lines";
    }

    my $append = ($ibyfile =~ s/^>>(?!>)// && -f($ibyfile) && ">>" || "");
    (my $fname = "__" . uc(GetBasename($ibyfile)) . "__") =~ s/\W/_/g;
    my @previby = ();

    if ($append) {
        OpenFile(*FILE, $ibyfile, 0) or die("Can't read file `$ibyfile'.\n"), return;
        @previby = <FILE>;
        close(FILE);
        $previby[0] =~ s/(, collected )(\d+)( files)$/$1.($2 + keys(%files)).$3/e;
        $previby[@previby - 1] = "";
    }

    OpenFile(*FILE, GetWriteFname($ibyfile), 0) or
        die("Can't write to `$ibyfile'.\n"), return;
    print(FILE @previby, ($append ? "// Appended" : "// Generated") . " `$append$ibyfile', " .
        "collected " . keys(%files) . " files\n" .
        ($append ? "" : "\n#ifndef $fname\n#define $fname\n") .
        ($header ? Unquote("\\n$header\\n") : "") . $body . ($footer ? Unquote("\\n$footer\\n") : "") .
        "\n#endif // $fname\n");
    close(FILE);
}


###############################################################################
#

sub GenMakefile($$$$$)
{
    return if $gPrintcmd;
    my ($hdrfile, $mkfile, $filter, $prepros, $assignop) =
        (GetAbsFname(shift()), GetAbsFname(shift()), shift(), shift(), shift());
    ChangeDir(GetDirname($hdrfile));
    RunSystemCmd("$prepros " . GetBasename($hdrfile), "");
    my $maxdef = Max(map(/^\s*\#define\s+($filter)/ && length($1), @gCmdoutbuf));
    WriteFile($mkfile, join('\n',
        map(/^\s*\#define\s+($filter)\s*(.*?)\s*$/ ? sprintf("%-${maxdef}s $assignop %s", $1, $2 eq "" ? 1 : $2) : (), sort(@gCmdoutbuf))) . '\n', "");
}


###############################################################################
#

sub AddImageHeader($$$$$)
{
    return if $gPrintcmd;
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
    sleep(shift()) if !$gPrintcmd;
}


###############################################################################
#

sub FindSOSFiles($$$$$)
{
    my ($dirs, $tmpoby, $imgoby, $pluglog, $opt) = @_;
    my ($file, %files) = ("", ());
    local $_;

    foreach my $dir (GlobFiles($dirs)) {
        $dir = GetAbsDirname($dir);

        foreach $file (Find($dir, $tmpoby, "", 1, 0, $_)) {
            OpenFile(*FILE, $file, 0) or warn("Can't read file `$file'.\n"), last;
            (my $dir = GetDirname($file) . "/") =~ s/\/+$/\//;
            while (<FILE>) {
                next if !/^#\s+\d+\s+"(.+?)"/;
                $_ = $1;
                $file = GetAbsFname(/^(?:[a-z]:)?[\/\\]/i ? $_ : "$dir$_");
                $files{lc($file)} = $file if !exists($files{lc($file)});
            }
            close(FILE);
        }

        foreach $file (Find($dir, $imgoby, "", 1, 0, $_)) {
            OpenFile(*FILE, $file, 0) or warn("Can't read file `$file'.\n"), last;
            while (<FILE>) {
                next if !/^\s*(?:bootbinary|data|device|dll|extension|file|primary|secondary|variant)\S*?\s*[=\s]\s*(?:"(.+?)"|(\S+))/i;
                $file = GetAbsFname(defined($1) ? $1 : $2);
                $files{lc($file)} = $file if !exists($files{lc($file)});
                next if ($file !~ s/\.[0-9a-f]{32}\./\./i);
                $file .= ".vmap";
                $files{lc($file)} = $file if !exists($files{lc($file)});
            }
            close(FILE);
        }

        my ($plugfile, $patched) = (0, 0);
        foreach $file (Find($dir, $pluglog, "", 1, 0, $_)) {
            OpenFile(*FILE, $file, 0) or warn("Can't read file `$file'.\n"), last;
            while (<FILE>) {
                $plugfile = 1, next if /^Reading (ROM|ROFS1|UDEB|UREL) files$/;
                $plugfile = 0, next if ($plugfile && /^Found \d+ entries$/);
                if ($plugfile) {
                    next if !/`(.+)'$/;
                    $file = GetAbsFname($1);
                    $files{lc($file)} = $file if !exists($files{lc($file)});
                    next;
                }
                $patched = $1, next if /^Found (\d+) ROM-patched components:$/;
                next if (!$patched || !/^`(.+)'$/);
                $patched--;
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
    return if $gPrintcmd;
    my ($maxtlen, $maxvlen, @tools) = (4, 9, ());
    while (@_) {
        my ($tool, $vquery, $getver, $version, $md5sum) = (shift(), shift(), shift(), " -", " ?");
        if (length($vquery) > 1) {
            RunSystemCmd($vquery, "null");
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

sub GetIPar()
{
    local $_ = shift(@gIcmd);
    $_ = "<UNDEFINED>" if (my $empty = !defined());

    while (/\@PEVAL{.*}LAVEP\@/) {
        my $start = rindex($_, '@PEVAL{', my $end = index($_, '}LAVEP@') + 7);
        my ($expr, $eval, $evalerr) = (substr($_, $start + 7, $end - $start - 14), undef, "");
        eval {
            local ($_, $SIG{__DIE__});
            local $SIG{__WARN__} = sub{} if $gPrintcmd;
            $eval = eval($expr);
            ($evalerr = $@) =~ s/^(.+?) at .*/$1/s;
        };
#        DPrint(64, "GetIPar: Evaluate `$expr' = `" . (defined($eval) ? $eval : "") . "'\n");
        if (!defined($eval)) {
            $eval = "";
            warn("GetIPar: Evaluation `$expr' failed: $evalerr.\n") if !$gPrintcmd;
        }
        substr($_, $start, $end - $start) = $eval;
    }
    DPrint(32, "iPar: $gParamcnt. `$_'\n") if $gParamcnt;
    $gParamcnt++;
    return($empty ? undef : $_);
}

sub PeekICmd($)
{
    return(defined($gIcmd[0]) && $gIcmd[0] =~ /^$_[0]$/i);
}

sub GetICmd()
{
    $gParamcnt = 0;
    my $cmd = GetIPar();
    DPrint(32, "iCmd: " . ++$gCmdcnt . ". `$cmd'\n") if defined($cmd) && $cmd ne "";
    return($cmd);
}

sub EndICmd()
{
    GetICmd(), return(1) if !defined($gIcmd[0]) || PeekICmd("end");
    return(0);
}

sub RunICmd()
{
    my ($cmd, $file, $iferror) = ("", "", 0);
    while (defined($cmd = GetICmd())) {
        next if $cmd eq "";
        local $_ = lc($cmd);
        if (/^(error|warning)$/) {
            my ($errwarn, $msg) = (GetIPar(), Unquote(GetIPar()));
            die($msg)  if $errwarn && /e/;
            warn($msg) if $errwarn && /w/;
        }
        elsif (/^echo(\d+)?(-q)?$/) {
            my ($verbose, $quote) = (defined($1) && ($1 < 128) ? $1 : 1, defined($2));
            Echo($verbose, GetIPar(), $quote);
        }
        elsif (/^filter$/) {
            $gOutfilter = GetIPar();
        }
        elsif (/^cmd(tee)?$/) {
            $file = $1;
            RunSystemCmd(GetIPar(), $file ? GetIPar() : "");
        }
        elsif (/^parse(f)?$/) {
            $file = $1;
            ParseSystemCmd(GetIPar(), GetIPar(), $file);
        }
        elsif (/^(cd|copy(dir)?|del(dir)?|find(dir)?(-[ar]+)?|headb|logfile|mkcd|mkdir|move|tailb|test|touch|type[bu]?|unzip|workdir|write[bu]?(-q)?|zip(dir)?(-[jq]+)?)$/) {
            my @files = GlobFiles(GetIPar());
            my $par1 = GetIPar() if /^(?:copy|find|head|move|tail|touch|(un)?zip|write)/;
            my $par2 = GetIPar() if /^(?:find|head|tail|zip)/;
            next if $gPrintcmd;
            foreach $file (@files) {
                ChangeDir($file)                           if /^cd/;
                DeleteDir($file)                           if /deldir/;
                FindDir($file, $par1, $par2, $1)           if /finddir(-[ar]+)?/;
                MakeDir($file)                             if /mkdir/;
                MakeChangeDir($file)                       if /mkcd/;
                SetWorkdir($file)                          if /workdir/;
                Zip($file, 1, $1, $par2, GlobFiles($par1)) if /zipdir(-[jq]+)?/;
                DeleteFile($file)                          if /del/;
                FindFile($file, $par1, $par2, $1)          if /find(-[ar]+)?$/;
                HeadFile($file, $par1, $par2)              if /headb/;
                SetLogfile($file)                          if /logfile/;
                TailFile($file, $par1, $par2)              if /tailb/;
                TypeFile($file, $1)                        if /type(b|u)?/;
                UnzipFile($file, $par1)                    if /unzip/;
                WriteFile($file, $par1, $1, $2)            if /write(b|u)?(-q)?/;
                Zip($file, 0, $1, $par2, GlobFiles($par1)) if /^zip(-[jq]+)?$/;
                Copy($file, $par1, $1)                     if /copy(dir)?/;
                Move($file, $par1)                         if /move/;
                Test($file)                                if /test/;
                Touch($file, $par1)                        if /touch/;
            }
        }
        elsif (/^genexclst$/) {
            GenExclfile(GetIPar(), GetIPar(), GetIPar(), GetIPar(), GetIPar());
        }
        elsif (/^geniby(-r)?$/) {
            my ($sub, $iby, $dir, @par) = ($1, GetIPar(), GetIPar(), ());
            push(@par, GetIPar(), GetIPar()) while !EndICmd();
            GenIbyfile($iby, $dir, $sub, @par);
        }
        elsif (/^genmk$/) {
            GenMakefile(GetIPar(), GetIPar(), GetIPar(), GetIPar(), GetIPar());
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
            FindSOSFiles(GetIPar(), GetIPar(), GetIPar(), GetIPar(), $opt);
        }
        elsif (/^toolchk$/) {
            my @tools = ();
            push(@tools, GetIPar(), GetIPar(), GetIPar()) while !EndICmd();
            CheckTool(@tools);
        }
        elsif (/^wgunzip$/) {
            ($file, my $dir, my $fname) = (GetIPar(), GetIPar(), GetIPar());
            map { WidgetUnzip($_, $dir, $fname) } GlobFiles($file);
        }
        elsif (!$gImakerext || !RunIExtCmd($_)) {
            die("Unknown iMaker command `$cmd'.\n");
        }
    }
}


###############################################################################
#

sub GetFeatvarIncdir($;$)
{
    my ($varname, $nbv) = @_;
    my %featvar = ();
    my @incdir  = ("Invalid SBV feature variant");
    my $valid   = 0;
    local $_;

    open(OLDERR, ">&STDERR");
    open(STDERR, $gWinOS ? ">nul" : ">/dev/null");
    select(STDERR);
    eval {
        local $SIG{__DIE__};
        %featvar = featurevariantparser->GetVariant($varname);
        $valid = $featvar{VALID};
    };
    close(STDERR);
    open(STDERR, ">&OLDERR");
    close(OLDERR);
    select(STDOUT);

    return(grep(tr/\\/\// || 1, @{$featvar{ROM_INCLUDES}})) if $valid;
    return(@incdir) if !$nbv;

    # N*kia Binary Variation
    foreach my $file (<$gEpoc32/tools/*.bsf>) {
        (my $varname = lc($file)) =~ s/^.*\/(.+?)\.bsf$/$1/;
        open(FILE, $file);
        while (my $line = <FILE>) {
            $featvar{$varname}{CUSTOMIZES} = lc($1) if $line =~ /^\s*CUSTOMIZES\s+(\S+)\s*$/i;
            $featvar{$varname}{VARIANT} = (uc($1) || 1) if $line =~ /^\s*(VIRTUAL)?VARIANT\s*$/i;
        }
        close(FILE);
    }
    $varname = lc($varname);
    my @variant = ();
    while ($featvar{$varname}{VARIANT}) {
        unshift(@variant, $varname) if $featvar{$varname}{VARIANT} ne "VIRTUAL";
        $varname = $featvar{$varname}{CUSTOMIZES};
    }
    while (@variant) {
        map { push(@incdir, join("/", $_, @variant)) } ("$gEpoc32/rom", "$gEpoc32/include");
        pop(@variant);
    }
    return(@incdir);
}


###############################################################################
#

sub SetVerbose($)
{
    my $verbose = shift();
    return($gVerbose = int($1)) if ($verbose =~ /^(\d+)$/) && ($1 < 128);
    $gVerbose = 1;
    warn("Verbose level `$verbose' is not integer between 0 - 127\n");
    return(1);
}

sub ReadICmdFile($)
{
    my ($file, $steps) = (GetAbsFname(shift()), "");
    OpenFile(*FILE, $file, 0) or
        die("Can't read iMaker command file `$file'.\n"), return;
    while (<FILE>) {
        DPrint(2, $_), next if /^\s*#/;
        next if !/^\s*(\S+?)\s*=(.*)$/;
        $gStepIcmd{my $step = $1} = (my $icmd = $2);
        $steps .= ($steps ? ", " : "") . $step . ($icmd =~ /^\s*$/ ? " (empty)" : "");
    }
    close(FILE);
    DPrint(2, "Steps: $steps\n");
}

sub CloseLog()
{
    close(LOG) if $gLogfile;
    $gLogfile = "";
}

sub MakeStep($$$$$$)
{
    (my $step, my $clean, my $build, $gKeepgoing, my $verbose, $gPrintcmd) = @_;
    (my $dur, @gStepDur) = (time(), ());

    SetVerbose($verbose);
    ChangeDir($gWorkdir);

    $gMakestep = "S:$step,C:" . ($clean ? 1 : 0) . ",B:" . ($build ? 1 : 0) .
        ",K:" . ($gKeepgoing ? 1 : 0) . ",V:$gVerbose";
    DPrint(2, "=" x 79 . "\nENTER: `$gMakestep'\n");
    map {
        if (defined($gStepIcmd{$_})) {
            DPrint(64, "$_ = `$gStepIcmd{$_}'\n");
            $gStepIcmd{$_} =~ s/(?<!(\\|\s))\|/ \|/g;  # ???
            @gIcmd = map((s/^\s+|(?<!\\)\s+$//g, s/\\\|/\|/g) ? $_ : $_, split(/(?<!\\)\|/, "$gStepIcmd{$_} "));
            RunICmd();
        } else {
            warn("Step `$_' is undefined.\n");
        }
    } ($clean ? "CLEAN_$step" : (), $build ? "BUILD_$step" : ());

    DPrint(2, "EXIT: `$gMakestep', duration: " . Sec2Min($dur = time() - $dur) . "\n");
    return((@gStepDur, $dur));
}


###############################################################################
#

sub HandleCmdArg($)
{
    my $arg = (defined($_[0]) ? $_[0] : "");
    return($gImakerext ? HandleExtCmdArg($arg) : $arg);
}


###############################################################################
#

sub MenuRuncmd($)
{
    ($ENV{IMAKER_MAKECMD}, my @menubuf) = (shift(), ());
    map {
        chomp();
        push(@menubuf, $_);
    } qx($ENV{IMAKER_MAKECMD});
    return(@menubuf);
}

sub Menu($$$)
{
    my ($makecmd, $mainmk, $cmdarg) = @_;
    my $quietopt = 'LOGFILE= PRINTCMD=0 VERBOSE=1 WORKDIR=$(CURDIR)';
    my ($prodind, $prodmk, @product) = (0, "", ());
    my ($targind, $target, $targcols, $targrows, @target)  = (0, "", 4, 0, ());
    my ($vartype, $varudeb, $varsym) = ("", 0, 0);
    my $cfgfile = "./imaker_menu.cfg";

    $cmdarg =~ s/^\s+|\s+$//g;
    $cmdarg = " $cmdarg" if $cmdarg ne "";
    open(FILE, "<$cfgfile") and
        (($prodind, $targind, $vartype, $varudeb, $varsym) = map(chomp() ? $_ : $_, <FILE>)) and close(FILE);

    while (1) {
        system($gWinOS ? "cls" : "clear");

        print("\nPRODUCTS\n--------\n");
        #
        if (!@product) {
            map {
                push(@product, [ucfirst($1), $_]) if /image_conf_(.+?)\./;
            } MenuRuncmd("$makecmd $mainmk $quietopt help-config");
        }
        $prodmk = ($prodind ? " -f $product[$prodind - 1][1]" : "");
        my $maxlen = Max(map(length(@$_[0]), @product));
        map {
            printf(" %" . (length(@product)) . "s) %-${maxlen}s  %s\n", $_ + 1, $product[$_][0], $product[$_][1]);
        } (0 .. $#product);
        print(" NO PRODUCTS FOUND!\n") if !@product;

        print("\nTARGETS\n-------\n");
        #
        if (!@target) {
            @target = MenuRuncmd("$makecmd$prodmk $mainmk $quietopt help-target-*-list");
            $targrows = int($#target / $targcols + 1);
            my $maxind = 0;
            map {
                if (!($_ % $targrows)) {
                    $maxind = length(Min($_ + $targrows, $#target + 1)) + 1;
                    $maxlen = Max(map(length(), @target[$_ .. Min($_ + $targrows - 1, $#target)]));
                }
                $target[$_] = sprintf("%${maxind}s) %-${maxlen}s", "t" . ($_ + 1), $target[$_]);
            } (0 .. $#target);
        }
        ($target = ($targind ? $target[$targind - 1] : "")) =~ s/^.+?(\S+)\s*$/$1/;
        foreach my $row (1 .. $targrows) {
            foreach my $col (1 .. $targcols) {
                my $ind = ($col - 1) * $targrows + $row - 1;
                print(($ind < @target ? " $target[$ind]" : "") . ($col != $targcols ? " " : "\n"));
            }
        }
        print(" NO TARGETS FOUND!\n") if !@target;

        print("\nCONFIGURATION\n-------------\n");
        #
        if (!$vartype) {
            ($vartype, $varudeb, $varsym) = map(/^\S+\s+=\s+`(.*)'$/ ? $1 : (),
                MenuRuncmd("$makecmd$prodmk $mainmk $quietopt TIMESTAMP=" . GetTimestamp() .
                    " $target print-TYPE,USE_UDEB,USE_SYMGEN"));
            $varudeb =~ s/0//g;
            $varsym  =~ s/0//g;
        }
        print(
          " Product: " . ($prodind ? $product[$prodind - 1][0] : "NOT SELECTED!") . "\n" .
          " Target : " . ($targind ? $target : "NOT SELECTED!") . "\n" .
          " Type   : " . ucfirst($vartype) . "\n" .
          " Tracing: " . ($varudeb ? ($varudeb =~ /full/i ? "Full debug" : "Enabled") : "Disabled") . "\n" .
          " Symbols: " . ($varsym ? "Created\n" : "Not created\n"));

        print("\nOPTIONS\n-------\n");
        #
        print(
          " t) Toggle between rnd/prd/subcon\n" .
          " u) Toggle between urel/udeb/udeb full\n" .
          " s) Toggle symbol creation on/off\n" .
          " r) Reset configuration\n" .
          " h) Print usage information\n" .
          " x) Exit\n\n" .
          "Hit Enter to run: imaker$prodmk$cmdarg TYPE=$vartype USE_UDEB=$varudeb USE_SYMGEN=$varsym $target\n");

        print("\nSelection: ");
        #
        (my $input = <STDIN>) =~ s/^\s*(.*?)\s*$/\L$1\E/;

        if ($input =~ /^(\d+)$/ && ($1 > 0) && ($1 <= @product) && ($1 != $prodind)) {
            $prodind = $1;
            ($targind, @target) = (0, ());
        }
        elsif ($input =~ /^t(\d+)$/ && ($1 > 0) && ($1 <= @target) && ($1 != $targind)) {
            $targind = $1;
        }
        elsif ($input eq "t") {
            $vartype = ($vartype =~ /rnd/i ? "prd" : ($vartype =~ /prd/i ? "subcon" : "rnd"));
        }
        elsif ($input eq "u") {
            $varudeb = (!$varudeb ? 1 : ($varudeb !~ /full/i ? "full" : 0));
        }
        elsif ($input eq "s") {
            $varsym = !$varsym;
        }
        elsif ($input eq "r") {
            ($prodind, @product) = (0, ());
            ($targind, @target)  = (0, ());
            ($vartype, $varudeb, $varsym) = ("", 0, 0);
        }
        elsif ($input eq "h") {
            print("\nTODO: Help");
            sleep(2);
        }
        elsif ($input =~ /^(x|)$/) {
            open(FILE, ">$cfgfile") and
                print(FILE map("$_\n", ($prodind, $targind, $vartype, $varudeb, $varsym))) and close(FILE);
            return($input eq "x" ? ("", "menu") :
                ("$prodmk$cmdarg TYPE=$vartype USE_UDEB=$varudeb USE_SYMGEN=$varsym", $target));
        }
    }
}


###############################################################################
#

die($@) if !defined($gImakerext = do("imaker_extension.pm")) && $@;

1;

__END__ # OF IMAKER.PM
