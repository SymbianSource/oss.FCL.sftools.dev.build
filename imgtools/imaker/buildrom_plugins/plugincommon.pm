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
# Description:
# Common buildrom plugin methods, for parsing Symbian IBY entries etc.
#



package plugincommon;

use strict;
use warnings;
use Cwd;
use File::Basename;

use constant FILESPECSTATEMENT => qr/^\s*(\S+?)\s*[=\s]\s*(?:"(.+?)"|(\S+))\s+(?:"(.+?)"|(\S+))(\s+.+?)?\s*$/;

use constant FILESPECKEYWORD =>
    qr/^(?:data|file|primary|secondary|variant|device|extension|dll|filecompress|fileuncompress)/i;

use constant FILEBITMAPSPECKEYWORD =>
    qr/^(?:data|file|primary|secondary|variant|device|extension|dll|filecompress|fileuncompress|BITMAP|AUTO-BITMAP|COMPRESSED-BITMAP)/i;

use constant ROFSFILESPECKEYWORD => qr/^(?:data|file|filecompress|fileuncompress)/i;

use constant ROFSBITMAPFILESPECKEYWORD => qr/^(?:data|file|filecompress|fileuncompress|BITMAP|AUTO-BITMAP|COMPRESSED-BITMAP)/i;

use constant HIDESTATEMENT => qr/^\s*(hide\S*?)\s*[=\s]\s*(?:"(.+?)"|(\S+))()\s*$/;

use constant DIRECTORYKEYWORD => qr/^(?:alias|hide|rename)/i;


BEGIN
{
    use Exporter();
    our ($VERSION, @ISA, @EXPORT);
    $VERSION = 1.00;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(
        FILESPECSTATEMENT FILESPECKEYWORD FILEBITMAPSPECKEYWORD ROFSFILESPECKEYWORD ROFSBITMAPFILESPECKEYWORD
        HIDESTATEMENT DIRECTORYKEYWORD
        &abspath &dprint &plugin_reset &plugin_init &plugin_start &plugin_end &parse_keyline &parse_obyline
        &is_entry &get_type_from_entry &get_source_from_entry &get_target_from_entry
        $gPluginname $gImgid $gLogfile $gWorkdir $gDebug $gFeatvar $gHandlestr
        $gLine $gLnum $gRomid $gRomidCmp $gKeyword $gSource $gTarget $gAttrib $gSrcCmp $gTgtCmp);
    $| = 1;
}

our ($gPluginname, $gImgid, $gLogfile, $gWorkdir, $gDebug, $gFeatvar, $gHandlestr);
our ($gLine, $gLnum, $gRomid, $gRomidCmp, $gKeyword, $gSource, $gTarget, $gAttrib, $gSrcCmp, $gTgtCmp);
my  $duration = 0;

sub abspath($)
{
    my $path = shift();
    eval { local $SIG{__DIE__}; $path = Cwd::abs_path($path) };
    return($path);
}

sub dprint($$;$)
{
    my ($log, $str, $nonl) = @_;
    ($str = ($log < 0 ? "Warning: " : "") . $str) =~ s/\n//g;
    $str .= "\n" if !$nonl;
    $log = abs($log);
    print($str) if (($log == 1) && !$gDebug) || (($log == 2) && $gDebug) || ($log > 2);
    print(LOG $str) if $gLogfile && ($log > 1);
}

sub plugin_reset()
{
    ($gLine, $gLnum, $gRomid, $gRomidCmp, $gKeyword, $gSource, $gTarget, $gAttrib, $gSrcCmp, $gTgtCmp) =
        ("", 0, 0, 0, "", "", "", "", "", "");
}

sub plugin_init($$$)
{
    my ($pluginfo, $opt, $start) = @_;
    $gPluginname = "$pluginfo->{name}.pm";
    plugin_reset();
    ($gImgid, $gLogfile, $gWorkdir, $gDebug, $gFeatvar, my $warn) = (0, "", undef, 0, "", "");
    foreach (split(/;+/, $opt)) {
        if    (s/^\s*-i//i) { $gImgid   = (/^CORE$/ ? 0 : (/^ROFS(\d)$/ ? $1 : -1)) }
        elsif (s/^\s*-l//i) { $gLogfile = abspath(File::Basename::dirname($_)) . "/" . File::Basename::basename($_) }
        elsif (s/^\s*-w//i) { $gWorkdir = abspath($_)  }
        elsif (s/^\s*-d//i) { $gDebug   = ($_ ? 1 : 0) }
        elsif (s/^\s*-f//i) { $gFeatvar = $_ }
        else  { $warn .= ", `$_'" }
    }
    $warn = "Unknown parameter(s):$warn." if ($warn =~ s/^,//);
    (open(LOG, ">>$gLogfile") or
        (($warn .= ($warn ? " " : "") . "Can't write to `$gLogfile'."), $gLogfile = "")) if $gLogfile;
    dprint(3, "$gPluginname: " . ($start ? "-" x (77 - length($gPluginname)) :
        "Initializing; $pluginfo->{invocation}, image id = " . ($gImgid < 0 ? "d" : $gImgid) .
        ", logfile = `$gLogfile'" . (defined($gWorkdir) ? ", workdir = `$gWorkdir'" : "") .
        ", debug = $gDebug" . ($gFeatvar ne "" ? ", feature variant = `$gFeatvar'" : "")));
    dprint(-3, $warn) if $warn;
    close(LOG) if !$start;
}

sub plugin_start($$)
{
    $duration = time();
    plugin_init(shift(), shift(), 1);
    $gHandlestr = "REM handled $gPluginname:";
}

sub plugin_end()
{
    my $msg = "$gPluginname: Duration: " . (time() - $duration) . " seconds ";
    dprint(3, $msg . "-" x (79 - length($msg)));
    close(LOG);
}

sub parse_keyline(;$)
{
    ($gLine = shift()) =~ s/^\s+|\s+$//g if defined($_[0]);
    return(-1) if ($gLine !~ FILESPECSTATEMENT) && ($gLine !~ HIDESTATEMENT);
    ($gKeyword, $gSource, $gTarget, $gAttrib) =
        ($1, defined($2) ? $2 : $3, defined($4) ? $4 : $5, defined($6) ? $6 : "");
    ($gSrcCmp, $gTgtCmp) = (lc($gSource), lc($gTarget));
    ($gTgtCmp = ($gKeyword =~ DIRECTORYKEYWORD ? $gSrcCmp : $gTgtCmp)) =~ tr/\\/\//;
    $gTgtCmp =~ s/^\/+//;
    return(2);
}

sub parse_obyline($)
{
    ($gLine = shift()) =~ s/^\s+|\s+$//g;
    $gLnum++;
    if ($gLine =~ /^REM\s+(ROM|DATA)_IMAGE\[(\d+)\]/i) {
        $gRomid = $2;
        $gRomidCmp = ($gImgid >= 0 ? ($1 eq "ROM" ? ($2 != 1 ? $2 : 0) : 99) : ($1 eq "DATA" ? -$2 - 1 : 99));
        return(1);
    }
    return(0) if ($gLine =~ /^(?:#|REM\s)/i) || ($gLine eq "");
    return(parse_keyline());
}


###############################################################################
#

sub is_entry
{
  my $entry = shift;
  if ($entry =~ /\s*(\S+)\s*=\s*(?:"(.+?)"|(\S+))\s+(?:"(.+?)"|(\S+))/i)
  {
    return 1;
  }
  return 0;
}

# get the type from an iby entry
sub get_type_from_entry($)
{
  my $entry = shift;
  if ($entry =~ /\s*(\S+)\s*=\s*(?:"(.+?)"|(\S+))\s+(?:"(.+?)"|(\S+))/i)
  {
    return $1;
  }
  return "";
}

# get the source file from an iby entry
sub get_source_from_entry($)
{
  my $entry = shift;
  if ($entry =~ /\s*(\S+)\s*=\s*(?:"(.+?)"|(\S+))\s+(?:"(.+?)"|(\S+))/i)
  {
    return defined($2) ? "\"$2\"" : $3;
  }
  return "";
}

# get the target file from an iby entry
sub get_target_from_entry($)
{
  my $entry = shift;
  if ($entry =~ /\s*(\S+)\s*=\s*(?:"(.+?)"|(\S+))\s+(?:"(.+?)"|(\S+))/i)
  {
    return defined($4) ? "\"$4\"" : $5;
  }
  return "";
}

1;

__END__ # OF PLUGINCOMMON.PM
