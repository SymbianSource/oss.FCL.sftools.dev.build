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
#
#!perl -w
# ==============================================================================
#  %name:          BuildJob.pm %
#  Part of:        Juno Build Tools
#  Requires:       Symbian OS build tools
#
#  %derived_by:    hasegawa %
#  %version:	   to1r1103#4.1.2 %
#  %date_modified: Thu Oct  5 15:41:26 2006 %
#
#  See POD text at the end of this file for usage and other details.
# ==============================================================================

package BuildJob;
use strict;
use warnings;
use Win32::Job;
use Config;
use Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(EBS_PORT EBS_DIR EBS_CLIENT EBS_SERVER);

our $EPOCROOT = $ENV{EPOCROOT} || "\\";
our $BUILD_DRIVE = $ENV{BUILD_DRIVE};

my @EBS_PATHS = ("epoc32\\tools\\build", "src\\common\\generic\\tools\\build");

$BuildJob::EBS_PORT   = 1973;
$BuildJob::EBS_DIR    = "";
$BuildJob::EBS_CLIENT = "buildclient.pl";
$BuildJob::EBS_SERVER = "buildserver.pl";

sub find_ebs
{
    return 1 if -d "$BuildJob::EBS_DIR\\$BuildJob::EBS_CLIENT";
    foreach (map("${BuildJob::BUILD_DRIVE}${BuildJob::EPOCROOT}$_", @EBS_PATHS))
    {
        $BuildJob::EBS_DIR = $_ and return 1 if -f "$_\\$BuildJob::EBS_CLIENT";
    }
    return 0;
}

sub run
{
    my $data_source = shift;
    return 0 unless ($data_source and -e $data_source);

    # finding free port.
    my $offset = 0;
    my $trials = 10;
    $BuildJob::EBS_PORT = $BuildJob::EBS_PORT + int(rand(1000));
    for(;$offset < $trials; $offset++) {
      if (!is_buildjob_running($BuildJob::EBS_PORT + $offset)) {
        $BuildJob::EBS_PORT = $BuildJob::EBS_PORT + $offset;
        last;
      }
    }
    warn("Can't start build job, is one already running?\n") and return 0 if ($offset > $trials); 
    print "Using port: $BuildJob::EBS_PORT\n";
    
    my $log_file = shift;
    $log_file = "build.log" unless $log_file;
    my $num_clients = shift;

    # default number of clients is the number of processors
    $num_clients = $ENV{NUMBER_OF_PROCESSORS} unless ($num_clients);

    # if we can't find the number of processors, just run one client
    $num_clients = 1 unless ($num_clients);

    find_ebs()
      or die("Can't find EBS scripts; looked in: "
             . join(",", map("${BuildJob::EPOCROOT}$_", @EBS_PATHS)));

    my $job = Win32::Job->new();
    for (my $i = 0; $i < $num_clients; $i++)
    {
        $job->spawn(
            $Config{perlpath},
            "perl $BuildJob::EBS_DIR\\$BuildJob::EBS_CLIENT -d localhost:$BuildJob::EBS_PORT -w 2 -c EBS_CLIENT$i",
            {new_console => 1, window_attr => 'minimized'});
    }
    my $server_pid = $job->spawn($Config{perlpath},
                                 "perl $BuildJob::EBS_DIR\\$BuildJob::EBS_SERVER -d $data_source -p $BuildJob::EBS_PORT -l $log_file"
                                );

    my $job_failure = 0;
    {
        # kill the job if we receive a sigint
        local $SIG{INT} = sub {$job->kill();};

        # start job with no timeout (a null watchdog run every 60s)
        # and complete when the first process terminates
        $job_failure = !$job->watch(sub {return 0}, 60, 0);
    }

    my $job_status = $job->status();
    $job_failure ||= ($job_status->{$server_pid}{exitcode} != 0);

    if ($job_failure)
    {
        print(STDERR "Abnormal job termination:\nProcess\tExit Code\n");
        foreach my $pid (keys %$job_status)
        {
            print(  STDERR (($pid == $server_pid) ? "server" : "client") . "\t"
                  . $job_status->{$pid}{exitcode}
                  . "\n");
        }
    }
    return !$job_failure;
}

sub is_buildjob_running
{
    my $port = shift;
    use IO::Socket::INET;

    # try to open a socket on the build server port
    my $sock =
      IO::Socket::INET->new(LocalAddr => '127.0.0.1',
                            LocalPort => $port,
                            Proto     => 'tcp',
                            Timeout   => 2);

    # failure means the server is probably running already
    my $is_port_available = !defined $sock;
    $sock->close() if $sock;
    return $is_port_available;
}

sub new
{
    my $invocant = shift;
    my $name     = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = {name => $name, stages => [], env => []};
    bless($self, $class);
    $self->new_stage();
    return $self;
}

sub set
{
    my $self  = shift;
    my $var   = shift;
    my $value = shift;

    push(@{$self->{env}},
         {name  => $var,
          value => $value});
}

sub add
{
    my $self = shift;
    push(@{$self->{stages}->[0]}, shift);
}

sub new_stage
{
    my $self = shift;
    unshift(@{$self->{stages}}, []);
}

sub go
{
    my $self       = shift;
    my $logfile    = shift;
    my $scriptfile = $self->{name} . ".xml";

    open(EBSSCRIPT, ">$scriptfile") or die("Can't open $scriptfile: $!");
    print EBSSCRIPT <<EOT;
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="build.xsl"?>
<!-- <!DOCTYPE BUILD SYSTEM "ebs.dtd"> -->
<!DOCTYPE Build  [
  <!ELEMENT Product (Commands)>
  <!ATTLIST Product name CDATA #REQUIRED>
  <!ELEMENT Commands (Execute+ | SetEnv*)>
  <!ELEMENT Execute EMPTY>
  <!ATTLIST Execute ID CDATA #REQUIRED>
  <!ATTLIST Execute Stage CDATA #REQUIRED>
  <!ATTLIST Execute Component CDATA #REQUIRED>
  <!ATTLIST Execute Cwd CDATA #REQUIRED>
  <!ATTLIST Execute CommandLine CDATA #REQUIRED>
  <!ELEMENT SetEnv EMPTY>
  <!ATTLIST SetEnv Order ID #REQUIRED>
  <!ATTLIST SetEnv Name CDATA #REQUIRED>
  <!ATTLIST SetEnv Value CDATA #REQUIRED>
]>
<Product name="zip">
  <Commands>
    <SetEnv Order="1" Name="PATH" Value="\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%"/>
EOT

    my $order = 2;
    foreach my $setenv (@{$self->{env}})
    {
        print EBSSCRIPT
          "<SetEnv Order=\"$order\" Name=\"$setenv->{name}\" Value=\"$setenv->{value}\"/>\n";
        $order++;
    }

    my $id       = 1;
    my $stage_id = 1;
    foreach my $stage (reverse @{$self->{stages}})
    {
        foreach my $cmd (@{$stage})
        {
            my $cmdline;
            $cmdline = $cmd->{commandline} if exists $cmd->{commandline};
            die("Undefined command line") unless $cmdline;
            my $cwd = "\\";
            $cwd = $cmd->{cwd} if exists $cmd->{cwd};
            my $component = $id;
            $component = $cmd->{component} if exists $cmd->{component};

            print EBSSCRIPT
              "<Execute ID=\"$id\" Stage=\"$stage_id\" Component=\"$component\" Cwd=\"$cwd\" CommandLine=\"$cmdline\"\/>\n";
            $id++;
        }
        $stage_id++;
    }
    print EBSSCRIPT <<EOT;
  </Commands>
</Product>
EOT
    close(EBSSCRIPT);

    my $status = run($scriptfile, $logfile);
    unlink($scriptfile);
    return $status;
}

1;

__END__

=head1 NAME

BuildJob - Run BuildServer and BuildClients

=head1 SYNOPSIS

 use BuildJob;

 BuildJob::run($data_source, $num_clients, $log_file);

=head1 DESCRIPTION

BuildJob runs a number of BuildClients and the BuildServer with the
specified data source and log file.  If undefined, the number of
clients defaults to the number of processors on the system and the log
file name defaults to "build.log" in the current working directory.

Any errors are communicated by a nonzero return code.

BuildJob uses port 1973 for communications and looks for the build
client and server scripts "buildclient.pl" and "buildserver.pl" in
"\src\common\generic\tools\build".  Change these defaults by setting
the following variables prior to calling "run":

 $EBS_PORT = 1973;
 $EBS_DIR = "\\src\\common\\generic\\tools\\build";
 $EBS_CLIENT = "buildclient.pl";
 $EBS_SERVER = "buildserver.pl";

This module uses Win32::Job to start and stop the clients and server.

If a BuildJob attempts to run on a system that is already running one
on the same EBS_PORT, the job will not be run and the original job
will continue unaffected.

=head1 SEE ALSO

L<BuildJob|scripts::BuildJob> is a wrapper to call this module from the command line.

=cut
