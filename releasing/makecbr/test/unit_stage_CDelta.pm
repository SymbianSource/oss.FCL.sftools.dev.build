# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
#

package unit_stage_CDelta;
use strict;

use lib qw(../);
use lib qw(../stages);
use Archive::Zip qw(:ERROR_CODES);
use CConfig;
use CDelta;
use Cwd;
use Data::Dumper;
use Fcntl;
use File::Basename;
use File::Path;
use File::Spec;
use File::Temp qw(tempfile tempdir);

# constructor

sub RunTest {

    my $score = shift;

	print "> *** Testing CDelta ***\n";

    my $self = bless { score => $score };

    # initial set-up
    $self->init();

    # N.B. the order of the following tests is important
    #      as each progressively sets up the environment
    #      for the next.

    # test methods of CDelta
    $self->t_ListReleaseComponents();
    $self->t_ListPreviousComponents();
    $self->t_ListPreinstalledComponents();
    $self->t_ListDirtyComponents();
    $self->t_PrepComponents();

    # clean up
    $self->exit();

	return $score;
}

# init() and exit() methods

sub init { # sets up CDelta object and dummy environment

    my $self = shift;

    # create GT components list
    $self->{gtlist} = {
        foo    => 'src/foo/group/foo.mrp',
        qux    => 'src/qux/group/qux.mrp',
        quux   => 'src/quux/group/quux.mrp',
        corge  => 'src/corge/group/corge.mrp',
        grault => 'src/grault/group/grault.mrp',
        garply => 'src/garply/group/garply.mrp',
        waldo  => 'src/waldo/group/waldo.mrp',
        fred   => 'src/fred/group/fred.mrp',
        plugh  => 'src/plugh/group/plugh.mrp',
        xyzzy  => 'src/xyzzy/group/xyzzy.mrp',
        thud   => 'src/thud/group/thud.mrp',
        mos    => 'src/mos/group/mos.mrp',
        henk   => 'src/henk/group/henk.mrp',
        def    => 'src/def/group/def.mrp',
        bar    => 'src/bar/group/bar.mrp' };

    my $gtlist = $self->TempFile($self->Stringify($self->{gtlist}));

    # create TV components list
    $self->{tvlist} = {
        baz                  => 'src/baz/group/baz.mrp',
        mighty               => 'src/mighty/group/mighty.mrp',
        boosh                => 'src/boosh/group/boosh.mrp',
        gt_techview_baseline => 'src/gt_techview_baseline/group/gt_techview_baseline.mrp' };

    my $tvlist = $self->TempFile($self->Stringify($self->{tvlist}));

    # escape colons in paths so CConfig won't (irrationally) complain
    $gtlist =~ s/:/\\:/g;
    $tvlist =~ s/:/\\:/g;

    # create config file including paths generated above
    my $config = $self->TempFile(<<CONFIG);

GT+Techview baseline component name : gt_techview_baseline
Last baseline version : 1.0
Max Parallel Tasks : 4
GT component list : $gtlist
Techview component list : $tvlist
Release version : 1.1
Internal version : 1.1

CONFIG

    # create CConfig object
    $self->{config} = CConfig->New($config);

    # create CDelta object
    $self->{cdelta} = eval { CDelta->New($self->{config}) };

    # show the error if any
    print $@ if defined $@;

    # did it work?
    $self->Test(!$@, 'Create CDelta object (implicit config validation)');

    # move to a temporary directory so we can set up environment
    $self->{tempdir} = tempdir(CLEANUP => 0);

    # remember current settings
    $self->{old} = {
        cwd      => cwd(),
        EPOCROOT => $ENV{EPOCROOT},
        SRCROOT  => $ENV{SRCROOT} };

    # chdir to the temp directory
    chdir($self->{tempdir}) or die "Can't chdir to temporary directory\n";

    # set EPOC/SRCROOT to the temporary directory (substr trims drive letter)
    $ENV{EPOCROOT} = $ENV{SRCROOT} = substr($self->{tempdir}, 2).'\\';

    # create reltools.ini pointing to the current directory as the local archive
    $self->TempFile(
        "archive_path test $self->{tempdir} /archive\ndisable_win32_extensions",
        File::Spec->catfile(qw(epoc32 relinfo reltools.ini)));

    # determine baseline
    $self->{baseline} = {
        name    => $self->{config}->Get('GT+Techview baseline component name'),
        version => $self->{config}->Get('Last baseline version')};

    # create dummy reldata
    $self->{reldata} = {
        toolName => "$0 (${\__PACKAGE__})",
        env      => {
            $self->{baseline}{name} => $self->{baseline}{version},
            foo                     => '1.0',
            qux                     => '1.0',
            quux                    => '1.0',
            corge                   => '1.0',
            grault                  => '1.0',
            garply                  => '1.0',
            waldo                   => '1.0',
            fred                    => '1.0',
            plugh                   => '1.0',
            xyzzy                   => '1.0',
            thud                    => '1.0',
            mos                     => '1.0',
            henk                    => '1.0',
            def                     => '1.0',
            boosh                   => '1.0',
            baz                     => '1.0',
            mighty                  => '1.0',
            bar                     => '1.0' } };

    # create dummy archive components
    for my $component (keys %{$self->{reldata}{env}}) {

        my $version = $self->{reldata}{env}{$component};

        # create dummy reldata
        $self->TempFile(
            Data::Dumper->Dump([$self->{reldata}], ['self->{data}']),
            File::Spec->catfile($component, $version, 'reldata'));

        # create source zip file
        my $zip = Archive::Zip->new();

        $zip->addString('/* dummy */', "src/$component/$component.cpp");
        $zip->addString(<<EOMRP, "src/$component/group/$component.mrp");

component $component
source \\src\\$component
notes_source \\src\\$component\\readme.txt

EOMRP

        # write to sourceE.zip
        my $file = File::Spec->catfile($component, $version, 'sourceE.zip');
        $zip->writeToFileNamed($file) == AZ_OK or die "Couldn't create $file: $!\n";

    }

    # use CDelta to run getenv (_prefix means private but we're testing!)
    my $command = qq(getenv -sov -i $self->{tempdir} $self->{baseline}{name} $self->{baseline}{version});

    $self->{cdelta}->_runcmd($command) == 0 or die "Couldn't prepare test environment\n";

    # dirty the foo component
    unlink(File::Spec->catfile(qw(src foo foo.cpp)));

    # start CConfig phase - CDelta logging expects a phase to be active
    $self->{config}->PhaseStart('Testing CDelta');
}

sub exit { # cleans up temp files and restores original environment
    my $self = shift;

    # delete temp files
    unlink for grep -e, @{$self->{tempfiles}};

    # chdir back to original working directory
    if (!chdir($self->{old}{cwd})) {
       die("Can't chdir back to original working directory ($self->{old}{cwd})\n");
    }

    # return EPOC/SRCROOT to previous settings
    $ENV{EPOCROOT} = $self->{old}{EPOCROOT};
    $ENV{SRCROOT} = $self->{old}{SRCROOT};

    # complete phase
    $self->{cdelta}->PhaseEnd();
}

# utility methods

sub Stringify { # creates a consistent string representation of a ref

    my $self = shift;
    my $ref = shift;

    if (UNIVERSAL::isa($ref, 'HASH')) {

        # sorted_key[space]value\n...
        return join("\n", map { join(' ', $_, $ref->{$_}) } sort keys %$ref);

    } elsif (UNIVERSAL::isa($ref, 'ARRAY')) {

        # sorted space separated
        return join(' ', sort @$ref);
    }

    return '';
}

sub TempFile { # writes data to a tempfile (optionally anonymous) and returns its path

    my $self = shift;
    my $data = shift;
    my $file = shift;

    # create anonymous tempfile or open specified file for writing
    my($fh, $filename) = !defined $file ? tempfile(UNLINK => 0, DIR => $self->{tempdir}) : do {
        my $dir = dirname($file);
        mkpath($dir) if !-d $dir;
        open(FH, ">$file") or die "Couldn't open $file: $!\n";
        (\*FH, $file);
    };

    # add to list of tempfiles (for later deletion)
    push @{$self->{tempfiles}}, $filename;
    print $fh $data;
    close($fh);

    return $filename;
}

sub Test { # delegator method - calls the supplied CTestScore->Test

    my $self = shift;

    # run test using CTestScore object
    return $self->{score}->Test(@_);
}

# test methods

sub t_ListReleaseComponents { # tests CDelta::ListReleaseComponents

    my $self = shift;

    # call ListReleaseComponents
    my $components = $self->{cdelta}->ListReleaseComponents();

    # make expected result by combining the two component lists
    my $expected = { %{$self->{gtlist}}, %{$self->{tvlist}} };

    # compare string representations of both lists
    $self->Test(
        $self->Stringify($components) eq $self->Stringify($expected),
        'Check ListReleaseComponents output');
}

sub t_ListPreviousComponents { # tests CDelta::ListPreviousComponents

    my $self = shift;

    # call ListPreviousComponents
    my $components = $self->{cdelta}->ListPreviousComponents(
        $self->{baseline}{name}, $self->{baseline}{version});

    # expected test result is the dummy environment
    my $expected = $self->{reldata}{env};

    # test ListPreviousComponents return value
    $self->Test(
        $self->Stringify($components) eq $self->Stringify($expected),
        'Check ListPreviousComponents output');
}

sub t_ListPreinstalledComponents { # tests CDelta::ListPreinstalledComponents

    my $self = shift;

    # call ListPreinstalledComponents
    my $components = $self->{cdelta}->ListPreinstalledComponents();

    # make expected test result from the dummy environment
    my $expected = { map { ($_, $self->{reldata}{env}{$_}) } keys %{$self->{reldata}{env}} };

    # test ListPreinstalledComponents return value
    $self->Test(
        $self->Stringify($components) eq $self->Stringify($expected),
        'Check ListPreinstalledComponents output');
}

sub t_ListDirtyComponents { # tests CDelta::ListDirtyComponents

    my $self = shift;

    # call ListDirtyComponents
    my $components = $self->{cdelta}->ListDirtyComponents($self->{reldata}{env});

    # make expected result
    my $expected = ['foo'];

    # test ListDirtyComponents return value
    $self->Test(
        $self->Stringify($components) eq $self->Stringify($expected),
        'Check ListDirtyComponents output');
}

sub t_PrepComponents { # tests CDelta::PrepComponents

    my $self = shift;

    # call PrepComponents
    my $status = $self->{cdelta}->PrepComponents(
        ['foo', $self->{baseline}{name}],
        { %{$self->{gtlist}}, %{$self->{tvlist}} });

    # test PrepComponents return value
    $self->Test($status == 1, 'Check PrepComponents output');
}

1;
