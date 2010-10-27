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

package BuildServer;

use strict;

use FindBin;		# for FindBin::Bin
use lib "$FindBin::Bin/lib/freezethaw"; # For FreezeThaw

# Other necessary modules. For "use Scanlog;" see dynamic code below.
use Carp;
use Msg;
use ParseXML;
use FreezeThaw qw(freeze thaw);
use IO::File;
use File::Basename;
use File::Copy;
use Compress::Zlib;			  # For decompression library routines


# Globals
my @gCommands;                # Holds the parsed "Execute" data from the XML file.
my @gSetEnv;                  # Holds the parsed "SetEnv" data from the XML file.
my $gIDCount = 0;             # The current Execute ID we're processing.
my $gStage;                   # The current Stage we're in.
my %gClientEnvNum;            # Holds the current index into @gSetEnv for each client.  Indexed by client name.
my %gClientStatus;            # Holds the status of each client.  Indexed by client name.
my %gClientHandles;           # Holds the socket of each client.  Indexed by client name
my $gLogFileH;                # The logfile.
my $gLogStarted = 0;          # Boolean to say if the logfile has been started.
my $gRealTimeError = "";      # "" = No error, otherwise a string significant to AutoBuild's log parsing
my $gScanlogAvailable = 0;    # Boolean to say if scanlog is available.
my $gExit = 0;                # 0 = FALSE (Do not exit) # 1 = TRUE (Send Exit to all clients for next command)



# Check if HiRes Timer is available
my ($gHiResTimer) = 0; #Flag - true (1) if HiRes Timer module available
if (eval "require Time::HiRes;") {
  $gHiResTimer = 1;
} else {
  print "Cannot load HiResTimer Module\n";
}


# Check if Scanlog.pm is available.
# In the Perforce order of things, scanlog.pm is in directory ".\scanlog" relative to BuildServer.pl
# However, at build time, BuildServer.pl is in "\EPOC32\Tools\Build" while scanlog.pm is in "\EPOC32\Tools"
# i.e. in the parent directory relative to BuildServer.pl
# If Scanlog cannot be found in either place, we continue, but the Scanlog functionality will be skipped.
if (eval {require scanlog::Scanlog;})
  {
  $gScanlogAvailable = 1;
  }
elsif (eval {use lib $FindBin::Bin.'/..'; require Scanlog;})
  {
  $gScanlogAvailable = 1;
  }
else
  {
  print "Cannot load Scanlog Module\n";
  }

# GetServerVersion
#
# Inputs
#
# Outputs
# Server Version Number
#
# Description
# This function returns the server version number
sub GetServerVersion
{
  return "1.3";
}

# rcvd_msg_from_client
#
# Inputs
# $iConn (Instance of the Msg Module)
# $msg (the recieved message from the client)
# $err (any error message from the Msg Module)
#
# Outputs
#
# Description
# This function processes the incoming message from the BuildClient and acts upon them
sub rcvd_msg_from_client {
    my ($iConn, $msg, $err) = @_;

    # If the message is empty or a "Bad file descriptor" error happens then it
    # usually means the the BuildServer has closed the socket connection.
    # The BuildClient will keep trying to connect to a BuildServer
    if (($msg eq "") || ($err eq "Bad file descriptor"))
    {
      print "A client has probably Disconnected\n";
      croak "ERROR: Cannot recover from Error: $err\n";
    }

    # Thaw the message, this decodes the text string sent from the client back into perl variables
    my ($iCommand, $iClientName, $iID, $iStage, $iComp, $iCwd, $iCommandline, $args) = thaw ($msg);

    # Handle a "Ready" command. A client wishes to connect.
    if ( $iCommand eq "Ready")
    {
      # Check the Client Version.  $iID holds the client version in the "Ready" message.
      if ($iID ne &GetServerVersion)
      {
        die "ERROR: Client version \"$iID\" does not match Server version \"".&GetServerVersion."\", cannot continue\n";
      }
      # Handle the initial "Ready" Command from the client
      # Check that the Client name is unique
      if (defined $gClientHandles{$iClientName})
      {
        # The Client name is not unique, a client by this name has already connected
        warn "WARNING: Multiple Clients using the same name\n";
        warn "Adding random number to client name to try and make it unique\n";
        warn "This will affect the preference order of the Clients\n";
        # Generate a ramdom number to add to the client name.
        my ($iRNum) = int(rand 10000000);
        $iClientName .= $iRNum;
        print "Changing ClientName to \"$iClientName\"\n";
        # Send the new Client name to the client
        my $iMsg = freeze("ChangeClientName", $iClientName);
        $iConn->transmit_immediately($iMsg);
      }
      
      # Add the connection object to the store of connections
      $gClientHandles{$iClientName} = $iConn;
      
      # Write the header to the logfile on first connection only
      if ( $gLogStarted == 0)
      {
        # The start of the log file only needs to be printed once
        $gLogStarted = 1;
        &PrintStageStart;
      }
      
      # Set Environment Variable counter to zero
      # This client has not been sent any environment variables yet
      $gClientEnvNum{$iClientName} = 0;
      # Set the $iCommand variable so that we begin sending Environment Variables
      $iCommand = "SetEnv Ready";
    }

    # Handle the "SetEnv Ready" command.  The client is ready for a command or env var.
    if ( $iCommand eq "SetEnv Ready")
    {
      # If there are any environment variables to be set, send the next one to the client to set it
      if (defined $gSetEnv[$gClientEnvNum{$iClientName}])
      {
        &Send_SetEnv($iConn, $gClientEnvNum{$iClientName});
        $gClientEnvNum{$iClientName}++;
      } else {
        # The client has gone through the connect process and has been sent all its environment variables
        # Add this client to the list of client ready to process commands
        AddReady($iClientName, $iConn);
      }
    }
    
    # Handle the "Results" command.  The client has finished a step and given us the results.
    if ( $iCommand eq "Results")
    {
        $args = Decompress($args); # Decompress the results.
        
        # If Scanlog has been found, check returned text for real time error string.
        # If a client reports a real time error, set global flag. We can't just die here and 
        # now; instead we must wait for other "busy" clients to finish their current tasks.
        if ($gScanlogAvailable)
        {
            if (Scanlog::CheckForRealTimeErrors($args))
            {
                # Command returned a RealTimeBuild error - abort this script,
                # and propagate it up to our parent process
                $gRealTimeError = "RealTimeBuild:";
            }
            elsif ($gCommands[$iID]{'ExitOnScanlogError'} =~ /y/i && Scanlog::CheckForErrors($args) )
            {
                # This is a critical step - flag a real time error,
                # and don't process anything else in this script
                $gRealTimeError = "Realtime error (ExitOnScanlogError)";
            }
        }
        
        # Print the correct headers for an individual command to the log
        print $gLogFileH "=== Stage=$gStage == $iComp\n";
        print $gLogFileH "-- $iCommandline\n";
        print $gLogFileH "--- $iClientName Executed ID ".($iID+1)."\n";
        # Print the output of the command into the log
        print $gLogFileH "$args";
        # Flush the handle to try and make sure the logfile is up to date
        $gLogFileH->flush;
        # Add this client to the list of client ready to process commands
        AddReady($iClientName, $iConn);
    }
}

# Send_SetEnv
#
# Inputs
# $iOrder - index into @gSetEnv
#
# Outputs
# Sends frozen SetEnv message
#
# Description
# This function is used to produce frozen SetEnv messages from the hash and then sends its
sub Send_SetEnv
{
  my ($iConn, $iOrder) = @_;
  
  my $iName = $gSetEnv[$iOrder]{'Name'};
  my $iValue = $gSetEnv[$iOrder]{'Value'};
  
  my $iMsg = freeze ('SetEnv', $iName, $iValue);
  
  $iConn->transmit_immediately($iMsg);
}


# login_proc
#
# Inputs
#
# Outputs
#
# Description
# This function can be used to process a login procedure
# No login procedure is implemented
sub login_proc {
    # Unconditionally accept
    \&rcvd_msg_from_client;
}

# Start
#
# Inputs
# $iDataSource (XML Command file)
# $iPort (Port number to listen on for Build Clients)
# $iLogFile (Logfile to write output from Build Clients to)
#
# Outputs
#
# Description
# This function starts the server

sub Start
{
  my ($iDataSource, $iPort, $iLogFile, $iEnvSource, $iConnectionTimeout, $iSocketConnections) = @_;

  my ($iHost) = '';

  # Open the log file for writing, it will not overwrite logs
  $gLogFileH = IO::File->new("> $iLogFile")
    or croak "ERROR: Couldn't open \"$iLogFile\" for writing: $!\n";  

  # If $iEnvSource is defined the Environment needs to be processed from this file
  if (defined $iEnvSource)
  {
    # Parse the XML data
    my ($iCommands, $iSetEnv) = &ParseXML::ParseXMLData($iEnvSource);
    push @gSetEnv, @$iSetEnv;
  }

  # Parse the XML data
  my ($iCommands, $iSetEnv) = &ParseXML::ParseXMLData($iDataSource);
  push @gCommands, @$iCommands;
  push @gSetEnv, @$iSetEnv;
  
  # Assuming there are commands to be executed, initialise the "current stage"
  # variable with the stage of the first command
  $gStage = $gCommands[$gIDCount]{'Stage'} if (scalar @gCommands);

  # Create the TCP/IP listen socket
  Msg->recent_agent($iPort, $iHost, \&login_proc, $iConnectionTimeout, $iSocketConnections);
  print "BuildServer created. Waiting for BuildClients\n";
  # Enter event loop to process incoming connections and messages
  Msg->result_iteration();
}


# SendCommand
#
# Inputs
# $iConn - the socket to use
# $iID - the ID of the command
#
# Outputs
# Command or file or file request sent via TCP connection
#
# Description
# Sends the command or file or file request indexed by $iID to the client
sub SendCommand
{
  my ($iConn, $iID) = @_;

  my $msg;
  my $iData;
  
  $msg = freeze ($gCommands[$iID]{'Type'}, $iID, $gCommands[$iID]{'Stage'}, $gCommands[$iID]{'Component'}, $gCommands[$iID]{'Cwd'}, $gCommands[$iID]{'CommandLine'});

  
  $iConn->transmit_immediately($msg);
}


# AddReady
#
# Inputs
# $iClientName (Client name)
# $iConn (Connection Object)
#
# Outputs
#
# Description
# This function adds the client defined by the connection ($iConn) to the list of ready clients
# It also sends new commands to clients if apropriate
sub AddReady
{
  my ($iClientName, $iConn) = @_;
  
  my @iClientsWaiting;
  
  # Set the client status to the "Waiting" State
  $gClientStatus{$iClientName} = "Waiting";

  # If the next command is Exit set global Exit flag
  if (defined $gCommands[$gIDCount])
  {
    $gExit = 1 if ($gCommands[$gIDCount]{'Type'} eq "Exit");
  }

  # Add the all "Waiting" clients to a list of waiting Clients
  foreach my $iClient (keys %gClientStatus)
  {
    push @iClientsWaiting, $iClient if ($gClientStatus{$iClient} eq "Waiting");
  }

  # Are all the clients waiting?
  if (scalar @iClientsWaiting == $iConn->AllAssociations)
  {
    # Everyone has finished.  Everyone is waiting.  One of 3 things has happened:
    # - There has been a realtime error.
    # - All commands have been run.
    # - We have come to the end of the current stage.
    # - There is only one client, and it has further commands in the current stage.

    if ($gRealTimeError)
    {
      &PrintStageEnd;
      
      print $gLogFileH "ERROR: $gRealTimeError BuildServer terminating\n";
      close ($gLogFileH);
      die "ERROR: $gRealTimeError BuildServer terminating\n";
    }
    
    # If all other clients waiting for a command and an exit pending
    # Send Messages to all clients (not just current) to exit their procees
    # No return is expected so exit the buildserver process
    if ($gExit)
    {
      # Close up log nicely
      &PrintStageEnd;
      foreach my $key (keys %gClientHandles)
      {
        my $msg = freeze ("Exit");  
        $gClientHandles{$key}->transmit_immediately($msg);
      }
      exit 0;
    }

    if (!defined $gCommands[$gIDCount])
    {
      # All commands have been run.  There are no more commands.
      &PrintStageEnd;
      
      print "No more stages\n";
      close ($gLogFileH);
      # Exit successfully
      exit 0;
    }
    
    if ( !defined $gStage ||                # the last command had no stage set
         $gStage eq '' ||                   # the last command had no stage set
         $gStage != $gCommands[$gIDCount]{'Stage'}   # the last command's stage is different to the next command's stage
       )
    {
      # We've successfully reached the end of a stage
      &PrintStageEnd;
      
      # Update the current stage variable to be the stage of the next command
      $gStage = $gCommands[$gIDCount]{'Stage'};
      
      &PrintStageStart;    
    }
  }
  
  # If the next command is the first in a stage then all clients are waiting.

  # Below this point we are approaching the command sending section.
  # Other clients could be working on previous commands at this point.
  
  # If the next command can not be run in parallel with the previous command
  # and another client is executing the previous command, then we should
  # return and simply wait for the other client to finish.
  
  # Don't issue anymore commands if there is an exit pending
  return if ($gExit);
  
  # Don't issue anymore commands if there has been a realtime error.
  return if ($gRealTimeError);
  
  # Sort the waiting clients alphabetically
  @iClientsWaiting = sort(@iClientsWaiting);
  # Extract the first client name
  my $iClient = shift @iClientsWaiting;
  
  # Check if there are commands and clients available
  while (defined $gCommands[$gIDCount] and defined $iClient)
  {
    # Check if the next command's stage is different to the current stage.
    # They will be identical if we are running the first command in a stage.
    # They will also be identical if we are running a subsequent command in the same stage.
    # So if they are different it means the next command is in a different stage.
    # Therefore we want to return and wait until all other clients have finished before
    # sending this command.
    return if ($gStage ne $gCommands[$gIDCount]{'Stage'});
    
    # Check to make sure a Exit command is not sent to 1 of multiple clients if Exit was not in it's own stage
    return if ($gCommands[$gIDCount]{'Type'} eq "Exit");
    
    # If at least one client is doing some work, and both the previous and next
    # commands' stages are not set, just wait until the working client finishes.
    # So we treat two steps with no stage name as though a stage change has occurred between them.
    if ((!defined $gCommands[$gIDCount-1]{'Stage'} or '' eq $gCommands[$gIDCount-1]{'Stage'}) and
        (!defined $gCommands[$gIDCount]{'Stage'} or '' eq $gCommands[$gIDCount]{'Stage'}) )
    {
      foreach my $status (values %gClientStatus)
      {      
        return if ($status ne 'Waiting');
      }
    }
    
    print "Sending Step ". ($gIDCount+1) ." to $iClient\n";

    # Set client as "Busy" and then send the command
    $gClientStatus{$iClient} = "Busy";    
    &SendCommand($gClientHandles{$iClient}, $gIDCount);
    $gIDCount++;
    
    # Extract the next client name
    $iClient = shift @iClientsWaiting;
  }
}

sub PrintStageStart
{
  # Output to log that the Stage has started
  print $gLogFileH "===-------------------------------------------------\n";
  print $gLogFileH "=== Stage=$gStage\n";
  print $gLogFileH "===-------------------------------------------------\n";
  print $gLogFileH "=== Stage=$gStage started ".localtime()."\n";

  # Flush the handle to try and make sure the logfile is up to date
  $gLogFileH->flush;
}

sub PrintStageEnd
{
  print "Stage End $gStage\n";
  
  # Output to the log that the Stage has finished
  print $gLogFileH "=== Stage=$gStage finished ".localtime()."\n";
  # Flush the handle to try and make sure the logfile is up to date
  $gLogFileH->flush;
}

# TimeStampStart
#
# Inputs
# $iData - Reference to variable to put the start time stamp
#
# Outputs
#
# Description
# This places a timestamp in the logs
sub TimeStampStart
{
  my $ref = shift;
  
  # Add the client side per command start timestamp
  $$ref = "++ Started at ".localtime()."\n";
  # Add the client side per command start HiRes timestamp if available
  if ($gHiResTimer == 1)
  {
    $$ref .= "+++ HiRes Start ".Time::HiRes::time()."\n";
  } else {
    # Add the HiRes timer unavailable statement
    $$ref .= "+++ HiRes Time Unavailable\n";
  }
}

# TimeStampEnd
#
# Inputs
# $iData - Reference to variable to put the end time stamp
#
# Outputs
#
# Description
# This places a timestamp in the logs
sub TimeStampEnd
{
  my $ref = shift;
 
  # Add the client side per command end HiRes timestamp if available
  $$ref .= "+++ HiRes End ".Time::HiRes::time()."\n" if ($gHiResTimer == 1);
   # Add the client side per command end timestamp
  $$ref .= "++ Finished at ".localtime()."\n";
}

# Subroutine for decompressing data stream.
# Input: message to be decompressed.
# Output: decompressed message.
# Note: here, when decompression is taking place, usually a complete message
# is passed as the input parameter; in this case Z_STREAM_END is the
# returned status. If an empty message is decompressed (e.g. because ""
# was sent) Z_OK is returned.
sub Decompress($)
{
    my $msg = shift; # Get the message.
    
    # Initialise deflation stream
    my ($x, $init_status);
    eval { ($x, $init_status) = inflateInit() or die "Cannot create an inflation stream\n"; };
    
    if($@) # Inflation initialisation has failed.
    {
	    return "ERROR: Decompression initialisation failed: $@\nERROR: zlib error message: ", $x->msg(), "\n";
    }
    
    # Some other failure?
    if($init_status != Z_OK and !defined($x))
    {
        return "ERROR: Decompression initialisation failed: $init_status\n";
    }
    
    # Decompress the message
    my ($output, $status);
    eval { ($output, $status) = $x->inflate(\$msg) or die "ERROR: Unable to decompress message"; };
    
    if($@) # Failure of decompression
    {
	    return "ERROR: unable to decompress: $@\n";
    }
    
    # Some other failure?
    if($status != Z_STREAM_END and $status != Z_OK)
    {
        my $error = $x->msg();
        return "ERROR: Decompression failed: $error\n";
    }
    
    # Return the decompressed output.
    return $output;
}

1;
