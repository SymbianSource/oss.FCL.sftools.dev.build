#!/usr/bin/env perl

#============================================================================ 
#Name        : get_gscm_info.pl 
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
#
# Script that fetch database connection information.
#
# e.g get_gscm_info.pl myccmdb get_db_path|get_router_address|get_engine_host myccmdb
#
use strict;
BEGIN {
    require Socket;
    eval qq{
        sub Socket::IPPROTO_TCP ();
        sub Socket::TCP_NODELAY ();
    } if  Socket->VERSION < 1.76 ;
}

use Config;
BEGIN {
    my $archname = $Config{archname};
    my $gscm_lib;
    if ($archname =~ m/Win32/)
    {
      $gscm_lib = "C:/apps/base-apps/lib"; # TODO: remove hardcoded path!
    }
    else
    {
      use File::Basename;

      # Do not use .. because evaluation get wrong under  64-bit Linux
      $gscm_lib = dirname($ENV{'CCM_HOME'}) . "/gscm-apps/lib"; # TODO: remove hardcoded path!
    }
    my ($perl_version) = $Config{version} =~ /^(\d+\.\d+)/;    
    unshift @INC, "$gscm_lib/$perl_version/$archname", "$gscm_lib/$perl_version", $gscm_lib;
}

my $archname = $Config{archname};
if ($archname =~ m/Win32/) {
  eval "use BASE::CCM::Utils qw(locate_databases get_general_info get_ccm_home sites get_ccm_processes);";
  die $@ if $@;
  eval "use BASE::Logging;";
  die $@ if $@;
  eval "use Win32::TieRegistry ( Delimiter=>'/' );";
  die $@ if $@;
} else {
  eval "use GSCM::CCM::Utils qw(locate_databases get_general_info get_ccm_home sites get_ccm_processes);";
  die $@ if $@;
  eval "use GSCM::Logging;";
  die $@ if $@;
}
#use Data::Dumper;
log_config(level=>'alert');

sub get_db_path
{
    my $db = shift;
    foreach my $dbpath (locate_databases())
    {
        return $dbpath if ($dbpath =~ m/$db$/);
    }
    exit (-1);
}

sub get_router_address
{
    my %ccm_info = get_general_info(get_db_path(shift));    
    return $ccm_info{"win32::router_address"};
}

sub get_engine_host
{
    my $dbpath = get_db_path(shift);
    my %ccm_info = get_general_info($dbpath);
    my $archname = $Config{archname};
    if ($archname =~ m/Win32/)
    {
        if (MachineIsWin32()) {
            return $ccm_info{"win32::engine_host"};
        } else {
            # We need to do something clever on 64bit env.
            return &FindRandomEsdHost($dbpath);
        }
    }
    else
    {
        return $ccm_info{"hostname"};
    }
}

#
# Few helper methods.
#
sub FindEsdHosts {
    my ($dbpath) = @_;
    my %esdhosts = map { $_->{host} => 1 }
                   get_ccm_processes(db_path=>$dbpath, process=>'esd');
    return sort keys %esdhosts;
}

sub FindRandomEsdHost {
    my ($dbpath) = @_;
    my @esdhosts = &FindEsdHosts($dbpath);
    my $esdhost = ( @esdhosts ? $esdhosts[ rand @esdhosts ] : '' );
    return $esdhost;
}

sub MachineIsWin32 {
  # Check if this machine is possibly a 64-bit  (need to do readonly on Vista)
  my $mreg = $::Registry->Open("LMachine/SYSTEM/CurrentControlSet/Control/Session Manager/Environment",
                                   {Access => 0x2000000} );
  # This registry test just tells us the machine architecture.
  # According to a VBscript from MS themselves, this is a safe test for
  # 32-bit windows (=x86), so ne x86 just says 'could be 64-bit'
  return ( $mreg->{'PROCESSOR_ARCHITECTURE'} eq 'x86' );
}


if (scalar(@ARGV)==2)
{
    eval {
        no strict 'refs';
        my $subroutine = shift @ARGV;
        my $v = &$subroutine(@ARGV);
        print $v;
    };
    if ($@) {print "Error: error executing method $ARGV[1]:$@\n"; exit(-1)};
}
else
{
    print "get_gscm_info.pl dbname get_db_path|get_router_address|get_engine_host\n";
    exit(-2);
}
exit(0);

