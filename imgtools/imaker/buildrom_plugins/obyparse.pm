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

my $conf = "";

sub obyparse_info()
{
    return({
        name       => "obyparse",
        invocation => "InvocationPoint2",
        initialize => "obyparse::obyparse_init",
        single     => "obyparse::obyparse_process"});
}

sub obyparse_init($)
{
    plugin_init("obyparse.pm", $conf = shift());
}

sub obyparse_readconffile($$$$$);


sub obyparse_process($)
{
    plugin_start("obyparse.pm", $conf);

    my $obydata = shift();
    my %targets = ();
    my %patchdata = ();
    my ($romfiles, $rofs1files, $udebfiles, $urelfiles) = (undef, undef, "", "");
    my $fname = "";

    foreach (@$obydata)
    {
        next if (my $parse = parse_obyline($_)) < 0;

        if (($parse == 1) && ($gKeyword =~ FILEBITMAPSPECKEYWORD)) {
            ($fname = lc($gTarget)) =~ /^(?:.*\\)?(.+?)$/;
            my $tname = $1;
            $targets{$fname} = $targets{$tname} = [$gLnum - 1, !$gRomid && ($gKeyword =~ ROFSBITMAPFILESPECKEYWORD)];
            next;
        }

        next if !/^\s*OBYPARSE_(ROM|ROFS1|UDEB|UREL)\s+(.+?)\s*$/i;

        (my $rule, $fname) = (uc($1), $2);
        my $files = ($rule eq "ROM" ? \$romfiles : ($rule eq "ROFS1" ? \$rofs1files :
            ($rule eq "UDEB" ? \$udebfiles : \$urelfiles)));
        $$files = "" if !defined($$files);
        dprint(2, "#$gLnum: `$gLine'");

        if ($fname ne "*") {
            my $basedir = "";
            ($basedir, $fname) = ($1, $2) if $fname =~ /^(.*[\/\\])(.+?)$/;
            dprint(3, "Found " . obyparse_readconffile($basedir, $fname, $rule, $files, 0) . " entries");
        }
        else {
            $$files = ".*";
            dprint(3, "Move/change all possible components to $rule");
        }
        $_ = "$gHandlestr $_";
    }

    $romfiles   = qr/^($romfiles)$/i   if defined($romfiles);
    $rofs1files = qr/^($rofs1files)$/i if defined($rofs1files);
    ($udebfiles, $urelfiles) = (qr/^($udebfiles)$/i, qr/^($urelfiles)$/i);

    ($gLnum, $gRomid) = (0, 0);
    my ($rofs1cnt, $udebcnt, $urelcnt, $offset, @torofs1) = (0, 0, 0, 0, ());

    foreach (@$obydata)
    {
        my $parse = parse_obyline($_);
        $offset++ if $gRomid < 2;
        next if $parse != 1;

        if ($gKeyword =~ /^patchdata$/i) {
            $gSource =~ /^(.+?)(?:@.+)?$/;
            $fname = lc($1);
            $patchdata{$fname} = $targets{$fname}[0] if !exists($patchdata{$fname});
        }
        else {
            $gTarget =~ /^(?:.*\\)?(.+?)$/;
            $fname = $1;
            if ($fname =~ $urelfiles && s/(?<=[\/\\])udeb(?=[\/\\])/urel/i) {
                $urelcnt++;
                dprint(2, "Changed to UREL: `$_'");
            }
            elsif ($fname =~ $udebfiles && s/(?<=[\/\\])urel(?=[\/\\])/udeb/i) {
                $udebcnt++;
                dprint(2, "Changed to UDEB: `$_'");
            }
        }

        next if $gRomid || !defined($romfiles) && !defined($rofs1files);

        if (($gKeyword =~ ROFSBITMAPFILESPECKEYWORD) ||
            ($gKeyword =~ /^patchdata$/i) && exists($targets{$fname}) && $targets{$fname}[1]) {
        }
        elsif ($gKeyword =~ /^(?:alias|rename)/i && exists($targets{lc($gSource)}) && $targets{lc($gSource)}[1]) {
            $gSource =~ /^(?:.*\\)?(.+?)$/;
            $fname = $1;
        }
        else {
            next;
        }
        if (defined($rofs1files) && ($fname =~ $rofs1files) || defined($romfiles) && ($fname !~ $romfiles)) {
            $rofs1cnt++;
            push(@torofs1, $_);
            $_ = "$gHandlestr =>ROFS1 $_";
        }
    }

    dprint(3, "Moved $rofs1cnt entries to ROFS1")    if $rofs1cnt;
    dprint(3, "Changed $udebcnt components to UDEB") if $udebcnt;
    dprint(3, "Changed $urelcnt components to UREL") if $urelcnt;

    dprint(2, "Found " . keys(%patchdata) . " ROM-patched components:") if %patchdata;
    foreach (sort({$a <=> $b} values(%patchdata))) {
        ${$obydata}[$_] =~ /^(?:$gHandlestr =>ROFS1 )?(.+)$/;
        parse_keyline($1);
        dprint(2, "`$gSource'");
    }

    splice(@$obydata, $offset, 0, @torofs1) if @torofs1;

    plugin_end();
}


sub obyparse_readconffile($$$$$)
{
    my ($basedir, $file, $type, $files, $indent) = @_;
    $file = $basedir . $file;
    my $filecnt = 0;

    dprint(3, "Reading $type files") if $type;
    dprint(3, ("." x $indent) . "`$file'");

    open(FILE, $file) or die("ERROR: Can't open `$file'\n");

    foreach my $line (<FILE>) {
        if ($line =~ /^\s*#include\s+(.+?)\s*$/i) {
            $filecnt += obyparse_readconffile($basedir, $1, "", $files, $indent + 2);
            next;
        }
        next if ($line =~ /^\s*$/) || ($line =~ /^\s*(?:#|\/\/|REM\s)/i);
        $filecnt++;
        (my $fname = $line) =~ s/^\s+|\s+$//g;
        $fname =~ s/(.)/{'*' => '.*', '?' => '.', '[' => '[', ']' => ']'}->{$1} || "\Q$1\E"/ge;
        $$files .= ($$files eq "" ? "" : "|") . $fname;
    }
    close(FILE);
    return($filecnt);
}

1;

__END__ # OF OBYPARSE.PM
