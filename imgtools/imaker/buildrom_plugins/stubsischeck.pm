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
# Check included sis/sisx file validity.
#



package stubsischeck;

use strict;
use warnings;
use File::Basename;
use plugincommon;

BEGIN
{
    use Exporter();
    our($VERSION, @ISA, @EXPORT);
    $VERSION = 1.00;
    @ISA     = qw(Exporter);
    @EXPORT  = qw(&stubsischeck_info &stubsischeck_init &stubsischeck_process);
}

my $conf;

sub stubsischeck_info()
{
    return({
        name       => "stubsischeck",
        invocation => "InvocationPoint3",  # tmp9.oby
        initialize => "stubsischeck::stubsischeck_init",
        single     => "stubsischeck::stubsischeck_process"});
}

sub stubsischeck_init($)
{
    plugin_init(&stubsischeck_info, $conf = shift(), 0);
}

sub stubsischeck_process($)
{
    plugin_start(&stubsischeck_info, $conf);
    my $obydata = shift();
    my %uids = ();

    dprint(3, "Finding and checking stub sis files...");

    foreach (@{$obydata}) {
        next if (parse_obyline($_) != 2)   || ($gImgid != $gRomidCmp)  ||
            ($gKeyword !~ FILESPECKEYWORD) || ($gSrcCmp !~ /\.sisx?$/) || !-e($gSource);

        my ($basename, $uiddata) = (File::Basename::basename($gSrcCmp), "");
        dprint(2, "Checking `$gSource'", 1);

        # Find out whether or not this is stub sis file
        open(FILE, $gSource) or
            dprint(2, ""), dprint(-3, "$gPluginname can't open `$gSource'"), next;
        binmode(FILE);
        sysread(FILE, $uiddata, 0x1C);
        close(FILE);

        my $uid = unpack("V", substr($uiddata, 0x00, 4));
        if ($uid == 0x0000000D) {
            my $puid = sprintf("0x%08X", unpack("V", substr($uiddata, 0x18, 4)));
            dprint(2, ", pUID: $puid");

            # Quick-and-dirty way to check duplicate UIDs
            if (exists($uids{$puid}) && ($basename ne $uids{$puid})) {
                dprint(3, "Error: `$gSource': Duplicate pUID $puid, see `$uids{$puid}'");
            } else {
                $uids{$puid} = $basename;
            }
        } elsif ($uid == 0x10201A7A) {
            dprint(2, ": Normal (non-stub) sis file");
        } else {
            dprint(2, "");
            if (unpack("V", substr($uiddata, 0x08, 4)) == 0x10000419) { # UID3
                dprint(-3, "`$gSource': Legacy (pre Symbian 9.x) sis file");
            } else {
                dprint(3, "Error: `$gSource': Sis file with unknown UID ($uid)");
            }
        }
    }
    plugin_end();
}

1;

__END__ # OF STUBSISCHECK.PM
