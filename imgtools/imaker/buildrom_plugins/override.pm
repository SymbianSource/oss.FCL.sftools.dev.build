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
# Enabler for overriding file and data entries from platform iby files.
#



##############################################################################
#
# Example 1: Replace an existing file with a different source files
# This replaces the original line with the override line.
# NOTE! One must define the ROM_IMAGE section for the overrides correctly.
#
# Some platform.iby
# data=file.txt         sys\bin\file.txt // In ROM_IMAGE[3]
#
# product.iby
# ROM_IMAGE[3] data-override=file_product.txt        sys\bin\file.txt
#
# output
# data=file_product.txt         sys\bin\file.txt
#
# Example 2: Remove an existing file from a platform iby
# This deletes the original line from the iby structure.
#
# Some platform.iby
# data=file.txt         sys\bin\file.txt // In ROM_IMAGE[3]
#
# product.iby
# ROM_IMAGE[3] {
# data-override=empty   sys\bin\file.txt
# }
# output
# REM OVERRIDE data=file_product.txt    sys\bin\file.txt
#
##############################################################################



package override;

use strict;
use warnings;
use plugincommon;

                                 # OVERRIDE TARGET FOUND  OVERRIDE TARGET NOT FOUND
use constant REPLACE_ADD  => 0;  # Replace with override  Add override
use constant REPLACE_SKIP => 1;  # Replace with override  Do nothing
use constant REPLACE_WARN => 2;  # Replace with override  Do nothing but warn
use constant SKIP_ADD     => 3;  # Do nothing             Add override

BEGIN
{
    use Exporter();
    our ($VERSION, @ISA, @EXPORT);
    $VERSION = 1.00;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(&override_info &override_init &override_process);
}

my $conf = "";

sub override_info
{
    return({
        name       => "override",
        invocation => "InvocationPoint2",
        initialize => "override::override_init",
        single     => "override::override_process"});
}

sub override_init
{
    plugin_init("override.pm", $conf = shift());
}

sub override_process
{
    plugin_start("override.pm", $conf);

    my $obydata    = shift();
    my %targets    = ();
    my @overrides  = ();
    my @oconfstack = (REPLACE_WARN);
    my @romelemcnt = (0, 0, 0, 0, 0, 0, 0, 0);

    # Go through all the tmp6.oby (InvocationPoint2) lines and store
    # normal targets' data to %targets and override targets' data to @overrides

    dprint(2, "Finding overrides...");

    foreach (@{$obydata})
    {
        my $parse = parse_obyline($_);

        if ($parse == 2) {
            # REM ROM_IMAGE[id]
            dprint(2, "#$gLnum: `$gLine'");
        }
        elsif (/^\s*OVERRIDE_(?:(END)|(REPLACE\/ADD)|(REPLACE\/SKIP)|(REPLACE\/WARN)|SKIP\/ADD)\s*$/i) {
            # Override configuration keyword
            if (defined($1)) {
                # OVERRIDE_END
                pop(@oconfstack);
            } else {
                # OVERRIDE_REPLACE/ADD|REPLACE/SKIP|REPLACE/WARN|SKIP/ADD
                push(@oconfstack, defined($2) ? REPLACE_ADD : (defined($3) ? REPLACE_SKIP : (defined($4) ? REPLACE_WARN : SKIP_ADD)));
            }
            dprint(2, "#$gLnum: `$gLine'");
            $_ = "$gHandlestr $gLine";
        }
        elsif ($parse == 1 && $gKeyword =~ /-override/i) {
            # Override entry
            dprint(2, "#$gLnum: `$gLine'");
            push(@overrides, [$gLnum - 1, $gRomid, $oconfstack[$#oconfstack]]);
        }
        elsif ($parse == 1 && $gKeyword =~ FILESPECKEYWORD) {
            # Normal file specification entry
            $targets{lc("$gTarget/$gRomid")} = $gLnum - 1;
            $romelemcnt[$gRomid]++;
        }
    }

    # Loop through all overrides and handle them
    dprint(3, @overrides ? "Handling overrides..." : "No override entries found");

    foreach (@overrides)
    {
        my ($lnum, $romid, $type) = @{$_};
        parse_keyline(${$obydata}[$lnum], 1);
        dprint(2, "Handling    : `$gLine' ($romid, " . ("REPLACE/ADD", "REPLACE/SKIP", "REPLACE/WARN", "SKIP/ADD")[$type] . ")");
        ${$obydata}[$lnum] = "$gHandlestr $gLine";
        (my $target = $gTarget) =~ s/^"(.*)"$/$1/;

        if (exists($targets{lc("$target/$romid")})) {
            # Override target found

            my ($line, $keyword, $source, $attrib) = ($gLine, $gKeyword, $gSource, $gAttrib);
            parse_keyline(${$obydata}[$lnum = $targets{lc("$target/$romid")}], 1);
            dprint(2, "Target      : `$gLine' ($romid, #" . ($lnum + 1) . ")");

            if ($type == SKIP_ADD) {
                dprint(2, "Do nothing  : Target found and override type SKIP");
            }
            elsif ($source =~ /^"?empty"?$/i) {
                # Empty keyword -> comment line out
                ${$obydata}[$lnum] = "$gHandlestr $gLine";
                dprint(1, "Remove ROM_IMAGE[$romid] `$gLine' due to `$line'");
                dprint(2, "Replace with: `${$obydata}[$lnum]' (Override source EMPTY)");
            }
            else {
                # Replace existing line with new line
                $keyword =~ s/-override//i;
                $attrib = ($attrib eq "" ? $gAttrib : ($attrib =~ /^\s*empty$/i ? "" : $attrib));
                $line = ${$obydata}[$lnum] = "$keyword=$source  $gTarget$attrib\n";
                dprint(1, "Replace ROM_IMAGE[$romid] `$gLine' with `$line'");
                dprint(2, "Replace with: `$line'");
            }
        }
        else {
            # Override target not found

            if (!$romelemcnt[$romid] && $type != REPLACE_ADD && $type != SKIP_ADD) {
                # Ignore override non-XXX/ADD targets on empty ROM_IMAGE sections
                dprint(2, "Do nothing  : Target not found, override target's ROM_IMAGE[$romid] section is empty");
                next;
            }
            # Check if override target exists in different ROM section
            my $warn = "";
            foreach my $tromid (0 .. 7) {
                $warn = "Override target `$target' found from ROM_IMAGE[$tromid] while override is for ROM_IMAGE[$romid]", last
                    if exists($targets{lc("$target/$tromid")});
            }
            if ($type == REPLACE_SKIP) {
                dprint(2, "Do nothing  : Target not found " . ($warn ? "from ROM_IMAGE[$romid] " : "") . "and override type SKIP");
            }
            elsif ($type == REPLACE_WARN) {
                dprint(-3, $warn ? "$warn, ignoring `$target'" : "Ignoring override target `$target', target not found");
                dprint(2, "Do nothing  : Target not found and override type WARN");
            }
            else {
                # OVERRIDE_XXX/ADD
                (my $line = $gLine) =~ s/^(\S+?)-override/$1/i;
                ${$obydata}[$lnum] = $line;
                dprint(-3, $warn) if $warn;
                dprint(1, "Add ROM_IMAGE[$romid] `$line' from `$gLine'");
                dprint(2, "Add new     : `$line' (Target not found, override type ADD)");
            }
        }
    }
    plugin_end();
}

1;

__END__ # OF OVERRIDE.PM
