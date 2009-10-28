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
# Description:
# Common buildrom plugin methods, for parsing Symbian IBY entries etc.
#



package plugincommon;

use strict;
use warnings;

use constant FILESPECSTATEMENT => qr/^\s*(\S+?)\s*[=\s]\s*(?:"(.+?)"|(\S+))\s+(?:"(.+?)"|(\S+))(\s+.+?)?\s*$/;

use constant FILESPECKEYWORD =>
    qr/^(?:data|file|primary|secondary|variant|device|extension|dll|filecompress|fileuncompress)/i;

use constant FILEBITMAPSPECKEYWORD =>
    qr/^(?:data|file|primary|secondary|variant|device|extension|dll|filecompress|fileuncompress|BITMAP|AUTO-BITMAP|COMPRESSED-BITMAP)/i;

use constant ROFSFILESPECKEYWORD => qr/^(?:data|file|filecompress|fileuncompress)/i;

use constant ROFSBITMAPFILESPECKEYWORD => qr/^(?:data|file|filecompress|fileuncompress|BITMAP|AUTO-BITMAP|COMPRESSED-BITMAP)/i;


BEGIN
{
    use Exporter();
    our ($VERSION, @ISA, @EXPORT);
    $VERSION = 1.00;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(
        FILESPECSTATEMENT FILESPECKEYWORD FILEBITMAPSPECKEYWORD ROFSFILESPECKEYWORD ROFSBITMAPFILESPECKEYWORD
        &dprint &plugin_init &plugin_start &plugin_end &parse_keyline &parse_obyline
        &is_entry &get_type_from_entry &get_source_from_entry &get_target_from_entry
        $gPluginname $gLogfile $gDebug $gHandlestr
        $gLine $gLnum $gRomid $gKeyword $gSource $gTarget $gAttrib);
    $| = 1;
}

our ($gPluginname, $gLogfile, $gDebug, $gHandlestr) = ("", "", "", 0);
our ($gLine, $gLnum, $gRomid, $gKeyword, $gSource, $gTarget, $gAttrib) = ("", 0, 0, "", "", "", "");
my  $duration = 0;

sub dprint($$)
{
    my ($log, $str) = @_;
    $str =~ s/\n//g;
    $str = ($log < 0 ? "Warning: " : "") . "$str\n";
    $log = abs($log);
    print($str) if (($log == 1) && !$gDebug) || (($log == 2) && $gDebug) || ($log > 2);
    print(LOG $str) if $gLogfile && ($log > 1);
}

sub plugin_init($$;$)
{
    ($gPluginname, $gDebug, my $start) = @_;
    $gDebug = "" if !defined($gDebug);
    $gDebug =~ s/^(?:(.*?);|(.*))//;
    $gLogfile = (defined($1) ? $1 : $2);
    my $warn = "";
    (open(LOG, ">>$gLogfile") or
        ($warn = "Can't write to `$gLogfile'.", $gLogfile = "")) if $gLogfile;
    dprint(3, "$gPluginname: " . ($start ? "-" x (77 - length($gPluginname)) :
        "Initializing; logfile = `$gLogfile', debug = " . ($gDebug ? 1 : 0)));
    dprint(-3, $warn) if $warn;
    close(LOG) if !$start;
}

sub plugin_start($$)
{
    $duration = time();
    plugin_init(shift(), shift(), 1);
    ($gHandlestr, $gLnum, $gRomid) = ("REM handled $gPluginname:", 0, 0);
}

sub plugin_end()
{
    my $msg = "$gPluginname: Duration: " . (time() - $duration) . " seconds ";
    dprint(3, $msg . "-" x (79 - length($msg)));
    close(LOG);
}

sub get_keyline($)
{
    my $quote = shift();
    ($gKeyword, $gSource, $gTarget, $gAttrib) =
        ($1, defined($2) ? ($quote ? "\"$2\"" : $2) : $3, defined($4) ? ($quote ? "\"$4\"" : $4) : $5, defined($6) ? $6 : "");
}

sub parse_keyline($;$)
{
    ($gLine = shift()) =~ s/^\s+|\s+$//g;
    get_keyline(shift()), return(1) if $gLine =~ FILESPECSTATEMENT;
    return(0);
}

sub parse_obyline($;$)
{
    ($gLine = shift()) =~ s/^\s+|\s+$//g;
    $gLnum++;
    $gRomid = $1, return(2) if $gLine =~ /^REM\s+ROM_IMAGE\[(\d+)\]/i;
    return(-1) if $gLine eq "" || $gLine =~ /^(?:#|REM\s)/i;
    return(parse_keyline($gLine, shift()));
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
