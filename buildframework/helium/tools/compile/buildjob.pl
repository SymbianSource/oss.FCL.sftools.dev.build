#!perl -w

#============================================================================ 
#Name        : buildjpb.pl 
#Part of     : Helium 

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
#============================================================================

# ==============================================================================
#  %name:          buildjob.pl %
#  Part of:        Juno Build Tools
#  Requires:       BuildJob.pm
#
#  %derived_by:    ferg %
#  %version:	   3 %
#  %date_modified: Wed May 04 14:44:22 2005 %
#
#  See POD text at the end of this file for usage details.
# ==============================================================================

use strict;
use FindBin;
use Getopt::Long;
use Pod::Usage;
use lib "$FindBin::Bin/../lib";
use BuildJob;

my $help = 0;
my $data_source;
my $log_file;
my $num_clients;

GetOptions('datasrc|d=s'    => \$data_source,
	    'logfile|l=s'    => \$log_file,
	    'numclients|n=s' => \$num_clients,
	    'help'           => \$help) or pod2usage(2);
pod2usage(2) unless $data_source;
pod2usage({-verbose => 2 }) if $help;

BuildJob::run($data_source, $log_file, $num_clients) or die("Error running build job.\n");

__END__

=head1 NAME

BuildJob - Run BuildServer and BuildClients

=head1 SYNOPSIS

BuildJob.pl -d <data source> [-n <number of clients>] [-l <log file>] [-h]

=head1 OPTIONS

=over 8

=item B<-h>

Print a brief help message and exits.

=item B<-d> <data source file name>

Data Source (XML command file)

=item B<-l> <log file name>

Log file for output from commands run on the BuildClient. Defaults to
"build.log".

=item B<-n>

Number of BuildClients to run.  Defaults to the number of processors
on the system.

=back

=head1 DESCRIPTION

This program runs a number of BuildClients and the BuildServer 
with the specified data source and log file.

=head1 SEE ALSO

=over 4

=item * L<BuildJob>

BuildJob.pl is a wrapper which calls the BuildJob.pm module from the
command line.

=back

=cut
