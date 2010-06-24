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
use File::Basename;
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

my $conf;

sub override_info
{
    return({
        name       => "override",
        invocation => "InvocationPoint2",  # tmp6.oby
        initialize => "override::override_init",
        single     => "override::override_process"});
}

sub override_init
{
    plugin_init(&override_info, $conf = shift(), 0);
}

sub override_process
{
    plugin_start(&override_info, $conf);

    my $obydata    = shift();
    my %targets    = ();
    my @overrides  = ();
    my @oconfstack = (REPLACE_WARN);

    # Go through all the tmp6.oby (InvocationPoint2) lines and store
    # normal targets' data to %targets and override targets' data to @overrides

    dprint(2, "Finding overrides...");

    foreach (@{$obydata})
    {
        next if !(my $parse = parse_obyline($_));

        if (($parse == 2) && ($gKeyword =~ /-?override$/i)) {
            # Override entry
            $_ = "$gHandlestr $_", next if ($gImgid != $gRomidCmp);
            dprint(2, "#$gLnum: `$gLine'");
            push(@overrides, [$gLnum - 1, $oconfstack[$#oconfstack]]);
            next;
        }
        if (($parse == 2) && ($gKeyword =~ FILEBITMAPSPECKEYWORD)) {
            # Normal file specification entry
            $targets{$gTgtCmp} = $targets{File::Basename::basename($gTgtCmp)} = $gLnum - 1
                if ($gImgid == $gRomidCmp);
            next;
        }

        next if !/^\s*OVERRIDE_(?:(END)|(REPLACE\/ADD)|(REPLACE\/SKIP)|(REPLACE\/WARN)|SKIP\/ADD)\s*$/i;

        # Override configuration keyword
        $_ = "$gHandlestr $_";
        next if $gRomid && ($gImgid != $gRomidCmp);
        if (defined($1)) {
            # OVERRIDE_END
            pop(@oconfstack);
        } else {
            # OVERRIDE_REPLACE/ADD|REPLACE/SKIP|REPLACE/WARN|SKIP/ADD
            push(@oconfstack, defined($2) ? REPLACE_ADD : (defined($3) ? REPLACE_SKIP : (defined($4) ? REPLACE_WARN : SKIP_ADD)));
        }
        dprint(2, "#$gLnum: `$gLine'");
    }

    # Loop through all overrides and handle them
    dprint(3, @overrides ? "Handling overrides..." : "No override entries found");

    foreach (@overrides)
    {
        my ($tlnum, $olnum, $type) = (0, @$_);
        parse_keyline(${$obydata}[$olnum]);
        dprint(2, "Handling    : `$gLine' (" . ("REPLACE/ADD", "REPLACE/SKIP", "REPLACE/WARN", "SKIP/ADD")[$type] . ")");
        ${$obydata}[$olnum] = "$gHandlestr ${$obydata}[$olnum]";

        if (defined($tlnum = $targets{$gTgtCmp}) || defined($tlnum = $targets{File::Basename::basename($gTgtCmp)})) {
            # Override target found
            my ($line, $keyword, $source, $attrib) = ($gLine, $gKeyword, $gSource, $gAttrib);
            parse_keyline(${$obydata}[$tlnum]);
            dprint(2, "Target      : `$gLine' (#" . ($tlnum + 1) . ")");

            if ($type == SKIP_ADD) {
                dprint(2, "Do nothing  : Target found and override type SKIP");
            }
            elsif ($source =~ /^empty$/i) {
                # Empty keyword -> comment line out
                ${$obydata}[$tlnum] = "$gHandlestr ${$obydata}[$tlnum]";
                dprint(1, "Remove `$gLine' due to `$line'");
                dprint(2, "Replace with: `${$obydata}[$tlnum]' (Override source EMPTY)");
            }
            else {
                # Replace existing line with new line
                $keyword =~ s/-?override$//i;
                $attrib = ($attrib eq "" ? $gAttrib : ($attrib =~ /^\s*empty$/i ? "" : $attrib));
                $line = ${$obydata}[$tlnum] = ($keyword ne "" ? $keyword : $gKeyword) .
                    ($source  =~ /\s/ ? "=\"$source\"" : "=$source") . "  " .
                    ($gTarget =~ /\s/ ? "\"$gTarget\"" : $gTarget) . "$attrib\n";
                dprint(1, "Replace `$gLine' with `$line'");
                dprint(2, "Replace with: `$line'");
            }
        }
        else { # Override target not found
            if ($type == REPLACE_SKIP) {
                dprint(2, "Do nothing  : Target not found and override type SKIP");
            }
            elsif ($type == REPLACE_WARN) {
                dprint(-3, "Ignoring override target `$gTarget', target not found");
                dprint(2, "Do nothing  : Target not found and override type WARN");
            }
            else {
                # OVERRIDE_XXX/ADD
                (my $line = $gLine) =~ s/^(\S*?)-?override/$1/i;
                $line = ${$obydata}[$olnum] = ($1 ne "" ? "" : "data") . $line;
                dprint(1, "Add `$line' from `$gLine'");
                dprint(2, "Add new     : `$line' (Target not found, override type ADD)");
            }
        }
    }
    plugin_end();
}

1;

__END__ # OF OVERRIDE.PM
