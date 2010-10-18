# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
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

package Msg;
use strict;
use IO::Select;
use IO::Socket;
use Carp;

use vars qw ( %scan_retrieves %publish_retrieves $scan_manages $publish_manages);

 %scan_retrieves = ();
%publish_retrieves = ();
$scan_manages   = IO::Select->new();
$publish_manages   = IO::Select->new();
my $obstructing_maintained = 0;

my $AllAssociations = 0;


BEGIN {
    # Checks if blocking is supported
    eval {
        require POSIX; POSIX->import(qw (F_SETFL O_NONBLOCK EAGAIN));
    };
    $obstructing_maintained = 1 unless $@;
}

use Socket qw(SO_KEEPALIVE SOL_SOCKET);
use constant TCP_KEEPIDLE  => 4; # Start keeplives after this period
use constant TCP_KEEPINTVL => 5; # Interval between keepalives
use constant TCP_KEEPCNT   => 6; # Number of keepalives before death

# AllAssociations
#
# Inputs
#
# Outputs
#
# Description
# This function returns the total number of connections
sub AllAssociations
{
  return $AllAssociations;
}

# associate
#
# Inputs
# $collection
# $toReceiver (Host associate to)
# $toChange (Port number to associate to)
# $get_notice_process (Function to call on recieving data)
#
# Outputs
#
# Description
# This function connects the client to the server
sub associate {
    my ($collection, $toChange, $toReceiver, $get_notice_process) = @_;
    
    # Create a new internet socket
    
    my $link = IO::Socket::INET->new (
                                      PeerAddr => $toReceiver,
                                      PeerPort => $toChange,
                                      Proto    => 'tcp',
                                      TimeOut => 10,
                                      Reuse    => 1);

    return undef unless $link;

    # Set KeepAlive
    setsockopt($link, SOL_SOCKET, SO_KEEPALIVE,  pack("l", 1));
    setsockopt($link, &Socket::IPPROTO_TCP, TCP_KEEPIDLE,  pack("l", 30));
    setsockopt($link, &Socket::IPPROTO_TCP, TCP_KEEPCNT,   pack("l", 2));
    setsockopt($link, &Socket::IPPROTO_TCP, TCP_KEEPINTVL, pack("l", 30));
  
    # Increse the total connection count
    $AllAssociations++;

    # Create a connection end-point object
    my $asso = bless {
        sock                   => $link,
        rcvd_notification_proc => $get_notice_process,
    }, $collection;
    
      # Set up the callback to the rcv function
    if ($get_notice_process) {
        my $retrieve = sub {_get($asso, 0)};
        define_result_manager ($link, "read" => $retrieve);
    }
    $asso;
}

# unplug
#
# Inputs
# $asso (Connection object)
#
# Outputs
#
# Description
# This function disconnects a connection and cleans up
sub unplug {
    my $asso = shift;
    
    # Decrease the number of total connections
    $AllAssociations--;
    
    # Delete the socket
    my $link = delete $asso->{sock};
    return unless defined($link);
    # Set to not try and check for reads and writes of this socket
    define_result_manager ($link, "write" => undef, "read" => undef);
    close($link);
}

# transmit_immediately
#
# Inputs
# $asso (Connection object)
# $content (Message to send)
#
# Outputs
#
# Description
# This function does a immediate send, this will block if the socket is not writeable
sub transmit_immediately {
    my ($asso, $content) = @_;
    
    # Puts the message in the queue
    _lineup ($asso, $content);
    # Flushes the queue
    $asso->_transmit (1); # 1 ==> flush
}

# transmit_afterwards
#
# Inputs
# $asso (Connection object)
# $content (Message to send)
#
# Outputs
#
# Description
# This function does a sends at a later time, does not block if the socket is not writeable.
# It sets a callback to send the data in the queue when the socket is writeable
sub transmit_afterwards {
    my ($asso, $content) = @_;
    
    # Puts the message in the queue
    _lineup($asso, $content);
    # Get the current socket
    my $link = $asso->{sock};
    return unless defined($link);
    # Sets the callback to send the data when the socket is writeable
    define_result_manager ($link, "write" => sub {$asso->_transmit(0)});
}

# _lineup
#
# Inputs
# $asso (Connection object)
# $content (Message to send)
#
# Outputs
#
# Description
# This is a private function to place the message on the queue for this socket
sub _lineup {
    my ($asso, $content) = @_;
    # prepend length (encoded as network long)
    my $dist = length($content);
    # Stores the length as a network long in the first 4 bytes of the message
    $content = pack ('N', $dist) . $content; 
    push (@{$asso->{queue}}, $content);
}

# _transmit
#
# Inputs
# $asso (Connection object)
# $remove (Deferred Mode)
#
# Outputs
#
# Description
# This is a private function sends the data
sub _transmit {
    my ($asso, $remove) = @_;
    my $link = $asso->{sock};
    return unless defined($link);
    my ($Lrq) = $asso->{queue};

    # If $remove is set, set the socket to blocking, and send all
    # messages in the queue - return only if there's an error
    # If $remove is 0 (deferred mode) make the socket non-blocking, and
    # return to the event loop only after every message, or if it
    # is likely to block in the middle of a message.

    $remove ? $asso->define_obstructing() : $asso->define_not_obstructing();
    my $branch = (exists $asso->{send_offset}) ? $asso->{send_offset} : 0;

    # Loop through the messages in the queue
    while (@$Lrq) {
        my $content            = $Lrq->[0];
        my $sequencetoPublish = length($content) - $branch;
        my $sequence_published  = 0;
        while ($sequencetoPublish) {
            $sequence_published = syswrite ($link, $content,
                                       $sequencetoPublish, $branch);
            if (!defined($sequence_published)) {
                if (_faultwillObstruct($!)) {
                    # Should happen only in deferred mode. Record how
                    # much we have already sent.
                    $asso->{send_offset} = $branch;
                    # Event handler should already be set, so we will
                    # be called back eventually, and will resume sending
                    return 1;
                } else {    # Uh, oh
                    $asso->manage_transmitted_fault($!);
                    return 0; # fail. Message remains in queue ..
                }
            }
            $branch         += $sequence_published;
            $sequencetoPublish -= $sequence_published;
        }
        delete $asso->{send_offset};
        $branch = 0;
        shift @$Lrq;
        last unless $remove; # Go back to select and wait
                            # for it to fire again.
    }
    # Call me back if queue has not been drained.
    if (@$Lrq) {
        define_result_manager ($link, "write" => sub {$asso->_transmit(0)});
    } else {
        define_result_manager ($link, "write" => undef);
    }
    1;  # Success
}

# _faultwillObstruct
#
# Inputs
# $asso (Connection object)
#
# Outputs
#
# Description
# This is a private function processes the blocking error message
sub _faultwillObstruct {
    if ($obstructing_maintained) {
        return ($_[0] == EAGAIN());
    }
    return 0;
}

# define_not_obstructing
#
# Inputs
# $_[0] (Connection socket)
#
# Outputs
#
# Description
# This is a function set non-blocking on a socket
sub define_not_obstructing {                        # $asso->define_obstructing
    if ($obstructing_maintained) {
        # preserve other fcntl flags
        my $pins = fcntl ($_[0], F_GETFL(), 0);
        fcntl ($_[0], F_SETFL(), $pins | O_NONBLOCK());
    }
}

# define_obstructing
#
# Inputs
# $_[0] (Connection socket)
#
# Outputs
#
# Description
# This is a function set blocking on a socket
sub define_obstructing {
    if ($obstructing_maintained) {
        my $pins = fcntl ($_[0], F_GETFL(), 0);
        $pins  &= ~O_NONBLOCK(); # Clear blocking, but preserve other flags
        fcntl ($_[0], F_SETFL(), $pins);
    }
}

# manage_transmitted_fault
#
# Inputs
# $asso (Connection object)
# $fault_content (Error message)
#
# Outputs
#
# Description
# This is a function warns on send errors and removes the socket from list of writable sockets
sub manage_transmitted_fault {
   # For more meaningful handling of send errors, subclass Msg and
   # rebless $asso.  
   my ($asso, $fault_content) = @_;
   warn "Error while sending: $fault_content \n";
   define_result_manager ($asso->{sock}, "write" => undef);
}

#-----------------------------------------------------------------
# Receive side routines

# recent_agent
#
# Inputs
# $collection (Package)
# $mi_receiver (Hostname of the interface to use)
# $mi_change (Port number to listen on)
# $enter_process (Reference to function to call when accepting a connection)
#
# Outputs
#
# Description
# This is a function create a listening socket
my ($g_enter_process,$g_collection);
my $primary_plug = 0;
sub recent_agent {
    @_ >= 4 || die "Msg->recent_agent (myhost, myport, login_proc)\n";
    my ($RepeatNumber);
    my ($collection, $changes, $mi_receiver, $enter_process, $iAssociationBreak, $PlugAssociations) = @_;
    # Set a default Socket timeout value
    $iAssociationBreak = 0 if (!defined $iAssociationBreak);
    # Set a default Socket retry to be forever
    $PlugAssociations = -1 if (!defined $PlugAssociations);
    
    while(!$primary_plug)
    {
        #Check to see if there is a retry limit and if the limit has been reached
        if ($PlugAssociations != -1)
        {
            if (($RepeatNumber / scalar(@$changes)) >= $PlugAssociations)
            {
                die "ERROR: could not create socket after ".$RepeatNumber / scalar(@$changes)." attempts";            
            } else {
                # Increment the number of retries
                $RepeatNumber++;
            }
        }
        
        #Try the first port on the list
        my $mi_change = shift(@$changes);
        #Place the port on the back of the queue
        push @$changes,$mi_change;
        
        print "Using port number $mi_change\n";
        $primary_plug = IO::Socket::INET->new (
                                              LocalAddr => $mi_receiver,
                                              LocalPort => $mi_change,
                                              Listen    => 5,
                                              Proto     => 'tcp',
                                              TimeOut =>    10,
                                              Reuse     => 1);
        sleep $iAssociationBreak if (!$primary_plug);
    }
    
    # Set KeepAlive
    setsockopt($primary_plug, SOL_SOCKET, SO_KEEPALIVE,  pack("l", 1));
    setsockopt($primary_plug, &Socket::IPPROTO_TCP, TCP_KEEPIDLE,  pack("l", 30));
    setsockopt($primary_plug, &Socket::IPPROTO_TCP, TCP_KEEPCNT,   pack("l", 2));
    setsockopt($primary_plug, &Socket::IPPROTO_TCP, TCP_KEEPINTVL, pack("l", 30));
    
    # Add the socket to the list on filehandles to read from.
    define_result_manager ($primary_plug, "read" => \&_recent_node);
    # Store the package name and login proc for later use
    $g_enter_process = $enter_process; $g_collection = $collection;
}

sub get_immediately {
    my ($asso) = @_;
    my ($content, $fault) = _get ($asso, 1); # 1 ==> rcv now
    return wantarray ? ($content, $fault) : $content;
}

sub _get {                     # Complement to _transmit
    my ($asso, $get_immediately) = @_; # $get_immediately complement of $remove
    # Find out how much has already been received, if at all
    my ($content, $branch, $sequencetoScan, $sequence_scan);
    my $link = $asso->{sock};
    return unless defined($link);
    if (exists $asso->{msg}) {
        $content           = $asso->{msg};
        $branch        = length($content) - 1;  # sysread appends to it.
        $sequencetoScan = $asso->{bytes_to_read};
        delete $asso->{'msg'};              # have made a copy
    } else {
        # The typical case ...
        $content           = "";                # Otherwise -w complains 
        $branch        = 0 ;  
        $sequencetoScan = 0 ;                # Will get set soon
    }
    # We want to read the message length in blocking mode. Quite
    # unlikely that we'll get blocked too long reading 4 bytes
    if (!$sequencetoScan)  {                 # Get new length 
        my $storage;
        $asso->define_obstructing();
        $sequence_scan = sysread($link, $storage, 4);
        if ($! || ($sequence_scan != 4)) {
            goto FINISH;
        }
        $sequencetoScan = unpack ('N', $storage);
    }
    $asso->define_not_obstructing() unless $get_immediately;
    while ($sequencetoScan) {
        $sequence_scan = sysread ($link, $content, $sequencetoScan, $branch);
        if (defined ($sequence_scan)) {
            if ($sequence_scan == 0) {
                last;
            }
            $sequencetoScan -= $sequence_scan;
            $branch        += $sequence_scan;
        } else {
            if (_faultwillObstruct($!)) {
                # Should come here only in non-blocking mode
                $asso->{msg}           = $content;
                $asso->{bytes_to_read} = $sequencetoScan;
                return ;   # .. _get will be called later
                           # when socket is readable again
            } else {
                last;
            }
        }
    }

  FINISH:
    if (length($content) == 0) {
        $asso->unplug();
    }
    if ($get_immediately) {
        return ($content, $!);
    } else {
        &{$asso->{rcvd_notification_proc}}($asso, $content, $!);
    }
}

sub _recent_node {
    my $link = $primary_plug->accept();
    $AllAssociations++;
    my $asso = bless {
        'sock' =>  $link,
        'state' => 'connected'
    }, $g_collection;
    my $get_notice_process =
        &$g_enter_process ($asso, $link->peerhost(), $link->peerport());
    if ($get_notice_process) {
        $asso->{rcvd_notification_proc} = $get_notice_process;
        my $retrieve = sub {_get($asso,0)};
        define_result_manager ($link, "read" => $retrieve);
    } else {  # Login failed
        $asso->unplug();
    }
}

#----------------------------------------------------
# Event loop routines used by both client and server

sub define_result_manager {
    shift unless ref($_[0]); # shift if first arg is package name
    my ($manage, %parameters) = @_;
    my $retrieve;
    if (exists $parameters{'write'}) {
        $retrieve = $parameters{'write'};
        if ($retrieve) {
            $publish_retrieves{$manage} = $retrieve;
            $publish_manages->add($manage);
        } else {
            delete $publish_retrieves{$manage};
            $publish_manages->remove($manage);
        }
    }
    if (exists $parameters{'read'}) {
        $retrieve = $parameters{'read'};
        if ($retrieve) {
            $scan_retrieves{$manage} = $retrieve;
            $scan_manages->add($manage);
        } else {
            delete $scan_retrieves{$manage};
            $scan_manages->remove($manage);
       }
    }
}

sub result_iteration {
    my ($collection, $starting_scan_break, $iteration_number) = @_; # result_iteration(1) to process events once
    my ($asso, $scan, $publish, $scandefine, $publishdefine);
    while (1) {
        # Quit the loop if no handles left to process
        last unless ($scan_manages->count() || $publish_manages->count());
        if (defined $starting_scan_break)
        {
            ($scandefine, $publishdefine) = IO::Select->select ($scan_manages, $publish_manages, undef, $starting_scan_break);
            # On initial timeout a read expect a read within timeout if not disconnect
            if (!defined $scandefine)
            {
              print "WARNING: no response from server within $starting_scan_break seconds\n";
              last;
            }
            # Unset intial timeout
            $starting_scan_break = undef;
        } else {
            ($scandefine, $publishdefine) = IO::Select->select ($scan_manages, $publish_manages, undef, undef);
        }
        foreach $scan (@$scandefine) {
            &{$scan_retrieves{$scan}} ($scan) if exists $scan_retrieves{$scan};
        }
        foreach $publish (@$publishdefine) {
            &{$publish_retrieves{$publish}}($publish) if exists $publish_retrieves{$publish};
        }
        if (defined($iteration_number)) {
            last unless --$iteration_number;
        }
    }
}

1;

__END__

