#!perl -w
#============================================================================ 
#Name        : ec_whatcheck.pl 
#Part of     : Helium 
#
#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description: 
# 
#==============================================================================

#
# ==============================================================================
#  %name:          ec_whatcheck.pl %
#  Part of:        EC Tools
#
#  %derived_by:    tuokinnu %
#  %version:       ou1tools#6 %
#  %date_modified: Thu Jan 08 16:58:24 2009 %
#
#  See POD text at the end of this file for usage details.
# ==============================================================================

use strict;
use Getopt::Long;
use Pod::Usage;

my $help = 0;
my $man  = 0;
GetOptions('man'    => \$man,
           'help|?' => \$help)
  or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $in_check = 0;
my $in_what  = 0;
$| = 1;

my %relcheck;
while (<>)
{
    unless ($in_check || $in_what)
    {
        # remove The process tried to write to a nonexistent pipe. errors from the logs.
        print "WARNING: " and print and next if /^(The process tried to write to a nonexistent pipe.)/;
        # mark stalled jobs to errors e.g.: Command "cmd.exe /c call setup.pl" was not making progress so it was automatically aborted.
        print "ERROR: " and print and next if /^(Command )/;
        # mark error messages to the faulty make files
        print "WARNING: " and print and next if /warning: overriding commands for target/;
        print and next if (/^\*\*\*/);
        print;

        $in_check = /^-- (call )?abld(\.bat)? / && / -c(heck)? /;
        $in_what  = /^-- (call )?abld(\.bat)? / && / -w(hat)? /;
    }
    else
    {
        if (/^\+\+ Finished/ || /^Options\s\(case-insensitive\)\s:/)
        {
            %relcheck = ();
            $in_check = $in_what = 0;
            redo;
        }
        # remove The process tried to write to a nonexistent pipe. errors from the logs.
        print "WARNING: " and print and next if /^(The process tried to write to a nonexistent pipe.)/;
        #next if /^(The process tried to write to a nonexistent pipe.)/;
        # don't split make messages.
        print and next if /^(make\[)/;
        # transform current output to match symbian logs.
        print "Chdir $1\n$_\n" and next if /^cd\s+(.+)&&\s+/;
        print and next if /^(--|\+\+|Chdir|This project does not support|cd\s+)/;

		# ignore current missing if they are make messages
        print "$1\n" and next if /^MISSING:\s*([make].*)/;
        # ignore current missing if they are not path
        print "MISSING: $1\n" and next if /^MISSING:\s*([^\s\\].*)/;
        print and next if /^(\\\+\+)/;
        print and next if (/^\*\*\*/);
        # don't split missing commands
        print and next if /is not recognized as an internal or external command/;
        print and next if /operable program or batch file./;
        # don't split warning messages.
        print "WARNING: " and print and next if /warning: overriding commands for target/;
        print and next if /warning: ignoring old commands for target/; 
        # pull apart by quoted strings or whole words, WS separated
        while (/("([^"\t\n\r\f]+)"|([^ "\t\n\r\f]+))/go)
        {
            my $releasable = ($2 ? $2 : $3);
            next if $relcheck{$releasable} || $releasable eq "MISSING:";
            $relcheck{$releasable} = 1;
            print("MISSING: $releasable\n") if $in_check && !-e $releasable;
            print("$releasable\n") if $in_what;
        }
    }
}

__END__

=head1 NAME

ec_whatcheck - Reformat Electric Cloud output for "what" and "check" build phases

=head1 SYNOPSIS

perl ec_whatcheck.pl [-h] < <stdout log>

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

Parse the output and reformat it according to rules lifted from the
Symbian build scripts.  If the output is from a "check" phase, check
for the existence of the file and print "MISSING: <file>" just as the
standard EBS output does.

=head1 SEE ALSO

L<xml2mak|scripts::xml2mak>

=cut
