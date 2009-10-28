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
# Description: iMaker main Perl script
#



#
$(error >>>MAKECMDGOALS=$(MAKECMDGOALS)<<<)
#
#!perl

use strict;
use warnings;
use Getopt::Long qw(:config pass_through no_auto_abbrev);

my $error = "";
my $perlver;
my $start;

BEGIN {
    ($start, $perlver) = (time(), sprintf("%vd", $^V));
    select(STDERR); $|++;
    select(STDOUT); $|++;
    if (!@ARGV) {
        warn("Warning: iMaker is running under Cygwin!\n")
            if (!$ENV{IMAKER_CYGWIN} && $^O =~ /cygwin/i);
        warn("Warning: iMaker uses Perl version $perlver! Recommended versions are 5.6.1 and 5.8.8.\n")
            if ($perlver !~ /^5\.(6\.1|8\.8)$/);
    }
    unshift(@INC, defined($ENV{IMAKER_DIR}) ? $ENV{IMAKER_DIR} : ($0 =~ /^(.*)[\/\\]/ ? $1 : "."));
}

use imaker;


###############################################################################
# Main program

{
    if (!@ARGV) {
        $ENV{CONFIGROOT} = imaker::GetAbsDirname($ENV{CONFIGROOT});
        $ENV{ITOOL_DIR}  = imaker::GetAbsDirname($ENV{ITOOL_DIR}, 0, 1);
        $ENV{IMAKER_DIR} = imaker::GetAbsDirname($ENV{IMAKER_DIR}, 0, 1);
        $ENV{PATH} = join(";", grep(!/[\\\/]cygwin[\\\/]/i, split(/;+/, $ENV{PATH})))
            if $imaker::gWinOS && !$ENV{IMAKER_CYGWIN};

        my ($version, $verfile) = ("", "$ENV{IMAKER_DIR}/imaker_version.mk");
        open(FILE, "<$verfile") and map { $version = $1 if /^\s*IMAKER_VERSION\s*[+:?]?=\s*(.*?)\s*$/ } <FILE>;
        close(FILE);
        $version and print("$version\n") or
            warn("Can't read iMaker version from `$verfile'.\n");

        my $cmdarg  = " " . imaker::HandleCmdArg($ENV{IMAKER_CMDARG}) . " ";
        my $makecmd = "$ENV{IMAKER_MAKE} -R --no-print-directory" .
            ($ENV{IMAKER_MAKESHELL} ? " SHELL=\"$ENV{IMAKER_MAKESHELL}\"" : "");
        my $cmdout  = qx($makecmd -f $0 $cmdarg 2>&1);
        my $targets = ($cmdout =~ />>>MAKECMDGOALS=(.*?)<<</ ? $1 : undef);

        die("Can't run `$ENV{IMAKER_MAKE}' properly:\n$cmdout") if !defined($targets);
        map { $cmdarg =~ s/\s+\Q$_\E\s+/ / } split(/\s+/, $targets);

        my $tmptarg = $targets = " $targets";
        my $hptarg  = 0;
        while ($tmptarg =~ /(\s+(help-\S+))/g) {
            $hptarg = $1, $targets =~ s/\Q$hptarg\E(.*)$/ $1$hptarg/ if $2 ne "help-config";
        }
        $hptarg = $1, $targets =~ s/\Q$hptarg\E(.*)$/ $1$hptarg/ while $tmptarg =~ /(\s+print-\S+)/g;
        $targets =~ s/^\s+|\s+(?=\s)|\s$//g;

        my $mainmk = "-f $ENV{IMAKER_DIR}/imaker.mk";
        $makecmd .= " -I " . imaker::GetAbsDirname($ENV{CONFIGROOT}, 0, 1) . " $mainmk";

        foreach my $target ($hptarg || $targets eq "" ? $targets : split(/\s/, $targets)) {
            ($cmdarg, $target) = imaker::Menu($makecmd, $mainmk, $cmdarg) if $target eq "menu";
            system($ENV{IMAKER_MAKECMD} = "$makecmd TIMESTAMP=" . imaker::GetTimestamp() . " $cmdarg $mainmk $target")
                if $target ne "menu";
            $error = ($? >> 8) if ($? >> 8);
        }

#        imaker::DPrint(1, "\nTotal duration: " . imaker::Sec2Min(time() - $start) . "\n");
        exit($error || 0);
    }

    #==========================================================================

    my ($opt_cmdfile, $opt_incdir, $opt_logfile, $opt_printcmd, $opt_step, $opt_verbose, $opt_workdir) =
       ( "",           "",          "",           0,             "",        1,            ".");
    Getopt::Long::GetOptions(
        "cmdfile=s" => \$opt_cmdfile,
        "incdir=s"  => \$opt_incdir,
        "logfile=s" => \$opt_logfile,
        "printcmd"  => \$opt_printcmd,
        "step=s"    => \$opt_step,
        "verbose=s" => \$opt_verbose,
        "workdir=s" => \$opt_workdir,
        "<>"        => sub { $error .= ($error ? ", `@_'" : "Unknown imaker.pl option: `@_'") });

    if ($opt_incdir) {
        my $bsf = ($opt_incdir =~ s/:bsf$//);
        print(map("$_\n", imaker::GetFeatvarIncdir($opt_incdir, $bsf)));
        exit;
    }

    $opt_verbose = imaker::SetVerbose($opt_verbose);

    imaker::DPrint(2, "=" x 79 . "\nTIME: " . localtime() . ", USER: " . getlogin() .
        ", HOST: " . ($ENV{HOSTNAME} || $ENV{COMPUTERNAME} || "?") . "\n$^X (v$perlver-$^O)\n");

    imaker::SetLogfile($opt_logfile);
    die("$error.\n") if $error;

    foreach (split(/-+/, $opt_step)) {
        $error .= ($error ? ", `$_'" : "Unknown imaker.pl step: `$_'")
            if (!/^\w+:?([cbk\d]+)?$/i) || $1 && ($1 =~ /c.*c|b.*b|k.*k|\d[^\d]+\d/i);
    }
    die("$error.\n") if $error;

    imaker::SetWorkdir($opt_workdir);
    imaker::ReadICmdFile($opt_cmdfile);

    my (@step, @stepdur) = (split(/-+/, lc($opt_step)), ());
    my ($durstr, $maxslen, $maxdlen) = ("", 6, 8);

    foreach my $stepnum (0 .. $#step) {
        $step[$stepnum] =~ /^(\w+):?([cbk\d]+)?$/;
        my $step = uc($1);
        $_ = (defined($2) ? $2 : "");
        my @dur = imaker::MakeStep($step, /c/, /b/, /k/, /(\d+)/ ? $1 : $opt_verbose, $opt_printcmd);
        imaker::SetVerbose($opt_verbose);
        my ($cmddur, $stepdur) = (0, pop(@dur));
        $durstr = imaker::Sec2Min($stepdur);
        if (@dur) {
            $durstr .= " (";
            foreach my $dur (@dur) {
                $cmddur += $dur;
                $durstr .= imaker::Sec2Min($dur) . " + ";
            }
            $durstr .= imaker::Sec2Min($stepdur - $cmddur) . ")";
        }
        $step = sprintf("%" . length(@step."") . "s", $stepnum + 1) . ". $step";
        push(@stepdur, $step, $durstr);
        $maxslen = imaker::Max($maxslen, length($step));
        $maxdlen = imaker::Max($maxdlen, length($durstr));
    }

    imaker::DPrint(2, "=" x 79 . "\n");
    @stepdur = ("Step", "Duration", "=" x $maxslen, "=" x $maxdlen, @stepdur,
        "-" x $maxslen, "-" x $maxdlen, "Total", imaker::Sec2Min(time() - $start));
    imaker::DPrint(2, sprintf("%-${maxslen}s %-${maxdlen}s ", shift(@stepdur), shift(@stepdur)) . "\n")
        while(@stepdur);

    imaker::CloseLog();
}

__END__ # OF IMAKER.PL
