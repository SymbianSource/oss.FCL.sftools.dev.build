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
# Split core image components to ROM/ROFS1.
# Make UREL <-> UDEB conversions.
#



package obyparse;

use strict;
use warnings;
use plugincommon;

BEGIN
{
    use Exporter();
    our($VERSION, @ISA, @EXPORT);
    $VERSION = 1.00;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(&obyparse_info &obyparse_init &obyparse_process);
}

my $conf;

sub obyparse_info()
{
    return({
        name       => "obyparse",
        invocation => "InvocationPoint2",  # tmp6.oby
        initialize => "obyparse::obyparse_init",
        single     => "obyparse::obyparse_process"});
}

sub obyparse_init($)
{
    plugin_init(&obyparse_info, $conf = shift(), 0);
}

sub obyparse_readconffile($$$$$);
sub obyparse_findincfiles();
sub obyparse_findspifiles();

sub obyparse_process($)
{
    plugin_start(&obyparse_info, $conf);

    my ($obydata, $romfiles, $rofs1files, $udebfiles, $urelfiles, $fname) = (shift(), undef, undef, "", "", "");
    my %targets = my %patchdata = ();

    obyparse_findincfiles();
    obyparse_findspifiles();
    plugin_reset();

    foreach (@$obydata)
    {
        next if !(my $parse = parse_obyline($_));

        if (($parse == 2) && ($gKeyword =~ FILEBITMAPSPECKEYWORD)) {
            $targets{$gTgtCmp} = $targets{File::Basename::basename($gTgtCmp)} = [$gLnum - 1,
                !$gRomid && ($gKeyword =~ ROFSBITMAPFILESPECKEYWORD) && ($gAttrib !~ /paging_unmovable/i)]
                    if ($gImgid == $gRomidCmp);
            dprint(2, "Removed attribute paging_unmovable: `$_'")
                if ($gAttrib =~ /paging_unmovable/i) && (s/\s+paging_unmovable\s*(?=\s|^)//i);
            next;
        }

        next if !/^\s*OBYPARSE_(ROM|ROFS1|UDEB|UREL)\s+(.+?)\s*$/i;

        (my $rule, $fname) = (uc($1), $2);
        $_ = "$gHandlestr $_";
        next if $gRomid && ($gImgid != $gRomidCmp);

        dprint(2, "#$gLnum: `$gLine'");
        my $files = ($rule eq "ROM" ? \$romfiles : ($rule eq "ROFS1" ? \$rofs1files :
            ($rule eq "UDEB" ? \$udebfiles : \$urelfiles)));
        $$files = "" if !defined($$files);

        if ($fname ne "*") {
            my $basedir = "";
            ($basedir, $fname) = ($1, $2) if $fname =~ /^(.*[\/\\])(.+?)$/;
            dprint(3, "Found " . obyparse_readconffile($basedir, $fname, $rule, $files, 0) . " entries");
        } else {
            dprint(3, "Move/change all possible components to $rule");
            $$files = ".*";
        }
    }

    $romfiles   = qr/^($romfiles)$/i   if defined($romfiles);
    $rofs1files = qr/^($rofs1files)$/i if defined($rofs1files);
    ($udebfiles, $urelfiles) = (qr/^($udebfiles)$/i, qr/^($urelfiles)$/i);

    my ($rofs1ofs, $udebcnt, $urelcnt, @torofs1) = (0, 0, 0, ());
    plugin_reset();

    foreach (@$obydata)
    {
        my $parse = parse_obyline($_);
        $rofs1ofs++ if ($gRomid < 2);
        next if ($parse != 2) || ($gImgid != $gRomidCmp);

        if ($gKeyword =~ /^patchdata$/i) {
            $gSrcCmp =~ /^(.+?)(?:@.+)?$/;
            next if !exists($targets{$fname = $1});
            $patchdata{$fname} = $targets{$fname}[0] if !exists($patchdata{$fname});
            next if !$targets{$fname}[1];
        }
        elsif ($gKeyword =~ FILEBITMAPSPECKEYWORD) {
            $fname = File::Basename::basename($gTgtCmp);
            if ($fname =~ $urelfiles && s/(?<=[\/\\])udeb(?=[\/\\])/urel/i) {
                $urelcnt++;
                dprint(2, "Changed to UREL: `$_'");
            }
            elsif ($fname =~ $udebfiles && s/(?<=[\/\\])urel(?=[\/\\])/udeb/i) {
                $udebcnt++;
                dprint(2, "Changed to UDEB: `$_'");
            }
            next if !$targets{$gTgtCmp}[1];
        }
        elsif ($gKeyword =~ DIRECTORYKEYWORD) {
            $fname = File::Basename::basename($gTgtCmp);
            next if !(exists($targets{$gTgtCmp}) && $targets{$gTgtCmp}[1]) &&
                !(exists($targets{$fname}) && $targets{$fname}[1]);
        }
        else { next }

        if (!$gRomid && (defined($rofs1files) && ($fname =~ $rofs1files) || defined($romfiles) && ($fname !~ $romfiles))) {
            push(@torofs1, $_);
            $_ = "$gHandlestr $_";
        }
    }

    dprint(3, "Moved " . scalar(@torofs1) . " entries to ROFS1") if @torofs1;
    dprint(3, "Changed $udebcnt components to UDEB") if $udebcnt;
    dprint(3, "Changed $urelcnt components to UREL") if $urelcnt;

    dprint(3, "Finding ROM-patched components");
    foreach (sort({$a <=> $b} values(%patchdata))) {
        ${$obydata}[$_] =~ /^(?:$gHandlestr )?(.+)$/;
        parse_keyline($1);
        dprint(2, "`$gSource'");
    }
    dprint(3, "Found " . keys(%patchdata) . " ROM-patched components");

    splice(@$obydata, $rofs1ofs, 0, @torofs1) if @torofs1;

    plugin_end();
}

sub obyparse_findincfiles()
{
    my ($drive, $indent, $prev, $tmpoby, %files) =
        (Cwd::cwd() =~ /^([a-z]:)/i ? $1 : "", -2, "", "$gWorkdir/tmp1.oby", ());

    dprint(3, "Finding include hierarchy from `$tmpoby'");
    open(FILE, $tmpoby) or dprint(-3, "$gPluginname can't open `$tmpoby'"), return;

    while (my $line = <FILE>) {
        next if ($line !~ /^#\s+\d+\s+"(.+?)"(?:\s+(\d))?$/);
        my ($file, $flag) = ($1, defined($2) ? $2 : 0);
        next if ($file =~ /^<.*>$/);
        $indent -= 2, $prev = $file, next if ($flag == 2);
        next if (!$flag && $file eq $prev || $flag > 1);
        $indent += 2 if $flag;
        ($prev = $file) =~ /^(.*[\/\\])?(.+?)$/;
        (my $dir, $file) = ("", $2);
        $dir = abspath(defined($1) ? $1 : ".");
        dprint(2, ("." x $indent) . "`$prev' !!!"), next if ($dir eq "");
        $dir =~ s/^$drive|\/$//gi;
        $files{lc($file = "$dir/$file")} = 1;
        dprint(2, ("." x $indent) . "`$file'");
    }
    close(FILE);
    dprint(3, "Found " . keys(%files) . " different include files");
}

sub obyparse_findspifiles()
{
    my ($spicnt, $tmpoby) = (0, "$gWorkdir/tmp5.oby");

    dprint(3, "Finding SPI input files from `$tmpoby'");
    open(FILE, $tmpoby) or dprint(-3, "$gPluginname can't open `$tmpoby'"), return;

    while (my $line = <FILE>) {
        next if (parse_obyline($line) != 2) || ($gKeyword !~ /^spidata/i);
        $spicnt++;
        dprint(2, "`$gSource'" . ($gKeyword =~ /^spidata$/i ? "" : " ($gKeyword)"));
    }
    close(FILE);
    dprint(3, "Found $spicnt SPI input files");
}

sub obyparse_readconffile($$$$$)
{
    my ($basedir, $file, $type, $files, $indent) = @_;
    $file = "$basedir$file";
    my $filecnt = 0;

    dprint(3, "Reading $type files from $file") if $type;
    dprint(2, ("." x $indent) . "`$file'");

    open(FILE, $file) or dprint(3, "Error: $gPluginname can't open $file", 1), die("\n");
    my @files = <FILE>;
    close(FILE);

    foreach (@files) {
        if (/^\s*#include\s+(.+?)\s*$/i) {
            $filecnt += obyparse_readconffile($basedir, $1, "", $files, $indent + 2);
            next;
        }
        next if (/^\s*$/) || (/^\s*(?:#|\/\/|REM\s)/i);
        $filecnt++;
        (my $fname = $_) =~ s/^\s+|\s+$//g;
        $fname =~ s/(.)/{"*" => ".*", "?" => "."}->{$1} || "\Q$1\E"/eg;
        $$files .= ($$files eq "" ? "" : "|") . $fname;
    }
    return($filecnt);
}

1;

__END__ # OF OBYPARSE.PM
