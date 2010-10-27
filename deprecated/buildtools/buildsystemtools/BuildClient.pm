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

package BuildClient;

use FindBin;		# for FindBin::Bin
use lib "$FindBin::Bin/lib/freezethaw"; # For FreezeThaw

use strict;
use Carp;
use Msg;
use FreezeThaw qw(freeze thaw);
use Cwd 'chdir';
use Compress::Zlib;			# For compression library routines

# Global Varibales
my $gClientName;
my ($gHiResTimer) = 0; #Flag - true (1) if HiRes Timer module available
my ($gDebug) = 0;

# Check if HiRes Timer is available
if (eval "require Time::HiRes;") {
  $gHiResTimer = 1;
} else {
  print "Cannot load HiResTimer Module\n";
}


# GetClientVersion
#
# Inputs
#
# Outputs
# Client Version Number
#
# Description
# This function returns the Client version number
sub GetClientVersion
{
  return "1.3";
}

# rcvd_msg_from_server
#
# Inputs
# $iConn (Instance of the Msg Module)
# $msg (the recieved message from the server)
# $err (any error message from the Msg Module)
#
# Outputs
#
# Description
# This function processes the incoming message from the Build Server and acts upon them
sub rcvd_msg_from_server {
    my ($iConn, $msg, $err) = @_;

    my ($iResults, $iChdir);

    # if the message is empty or a "Bad file descriptor" error happens
    # This usually means the the Build Server has closed the socket connection.
    # The client is returned to trying to connect to a build server
    if (($msg eq "") || ($err eq "Bad file descriptor"))
    {
      print "Server Disconnected\n";
      return 0;
    } elsif ($err ne "") {
      print "Error is communication occured:$err\n";
      return 0;
    }

    # Thaw the message, this decodes the text string sent from the server back into perl variables
    my ($sub_name, $iID, $iStage, $iComp, $iCwd, $iCommandline) = thaw ($msg);

    # The server has determined that this client is using a non-unique client name.
    # The server has added a random number on to the client name to try and make it unique.
    # The server send this new name back to the client, so the two are in sync.
    if ($sub_name eq 'ChangeClientName')
    {
      print "ClientName changed to: $iID by the server\n";
      $BuildClient::gClientName = $iID;
    }

    # The server sent and exit message to this client, so exit.
    if ($sub_name eq 'Exit')
    {
      print "Server request the client to exit\n";
      exit 0;
    }

    # If the command sent by the server is "SetEnv", call the SetEnv Function and respond to server when complete
    if ($sub_name eq 'SetEnv')
    {
      &SetEnv($iID, $iStage);
      # Prepare and send the "SetEnv Ready" message to the server with the client name
      my $serialized_msg = freeze ("SetEnv Ready", $BuildClient::gClientName);
      $iConn->transmit_immediately($serialized_msg);
    } elsif ($sub_name eq 'Execute') {
      # Process the "Execute" command
      print "Executing ID ". ($iID+1) ." Stage $iStage\n"; 
      # Add the client side per command start timestamp
      &TimeStampStart(\$iResults);

      eval {
          no strict 'refs';  # Because we call the subroutine using
                             # a symbolic reference
          # Change the working directory, first replacing the environment variables
          $iCwd =~ s/%(\w+)%/$ENV{$1}/g;
          $iCommandline =~ s/%(\w+)%/$ENV{$1}/g;
          # If the changing of the working directory fails it will remain in the current directory
          $iChdir = chdir "$iCwd";
          # Don't execute the command if the changing of the working directory failed.
          if ($iChdir)
          {
            # Log the directory change
            print "Chdir $iCwd\n";
            $iResults .= "Chdir $iCwd\n";
            # Execute the "Execute" function, passing it the commandline to execute and collect the results
            $iResults .= normalize_line_breaks(&{$sub_name} ($iCommandline));
          } else {
            $iResults .= "ERROR: Cannot change directory to $iCwd for $iComp\n";
          }
      # Add the client side per command end HiRes timestamp if available
      &TimeStampEnd(\$iResults);
      };

      # Send an appropriate message back to the server, depending on error situation
      if ($@ && $iChdir) {      # Directory changed OK, but an error occurred subsequently
          # Handle Generic errors
          $msg = bless \$@, "RPC::Error\n";
          
          # Freeze the perl variables into a text string to send to the server
          $msg = freeze('Results', $BuildClient::gClientName, $iID, $iStage, $iComp, $iCwd, $iCommandline, Compress($msg));
      } else {                  # Directory change failed OR no error at all.
          # $iResults will contain the error string if changing working directories failed
          #     otherwise it will contain the output of the execution of the commandline
          # Freeze the perl variables into a text string to send to the server
          $msg = freeze('Results', $BuildClient::gClientName, $iID, $iStage, $iComp, $iCwd, $iCommandline, Compress($iResults));
      }
      # Send the message back to the server
      $iConn->transmit_immediately($msg);
      
    } 
}

# normalize_line_breaks
#
# Inputs
# $lines  Text string which may consist of many lines
#
# Outputs
# $lines  Text string which may consist of many lines
#
# Description
# This subroutine converts any Unix, Macintosh or other line breaks into the DOS/Windows CRLF sequence
# Text in each line remains unchanged. Empty lines are discarded.
sub normalize_line_breaks
{
    my $lines = '';
    foreach my $line (split /\r|\n/, shift)
        {
        unless ($line) { next; }    # Discard empty line
        $lines .= "$line\n";
        }
    return $lines;    
}

# Execute
#
# Inputs
# @args
#
# Outputs
# @results
#
# Description
# This Executes the command in the args, must return and array
# It combines STDERR into STDOUT
sub Execute
{
  my (@iCommandline) = @_;

  print "Executing '@iCommandline'\n";
  if (! defined($BuildClient::gDebug))
  {
    return my $ireturn= `@iCommandline 2>&1`;   # $ireturn is not used but ensures that a scalar is returned.
  } else {
    if ($BuildClient::gDebug ne "")
    {
      # Open log file for append, if cannot revert to STDOUT
      open DEBUGLOG, ">>$BuildClient::gDebug" || $BuildClient::gDebug== "";
    }
    my $iResults;

    print DEBUGLOG "Executing '@iCommandline'\n" if ($BuildClient::gDebug ne "");
    open PIPE, "@iCommandline 2>&1 |";
    while (<PIPE>)
    {
      if ($BuildClient::gDebug ne "")
      {
        print DEBUGLOG $_;
      } else {
        print $_;
      }
      $iResults .= $_;
    }
    close PIPE;
    close DEBUGLOG if ($BuildClient::gDebug ne "");
    return $iResults;
  }
}

# SetEnv
#
# Inputs
# @args
#
# Outputs
#
# Description
# This function sets the local Environment.
sub SetEnv
{
  my ($iKey, $iValue) = @_;

  # Replace an environment Variable referenced using %Variable% with the contents of the Environment Variable
  # This allows the use of one Environment Variable in another as long as it is already set
  $iValue =~ s/%(\w+)%/$ENV{$1}/g;
  print "Setting Environment Variable $iKey to $iValue\n";
  $ENV{$iKey} = $iValue;
}

# Connect
#
# Inputs
# $iDataSource - Reference to array of Hostname:Port of BuildServers to connect to)
# $iConnectWait (How often it polls for a build server)
# $iClientName (Client name used to help identify the machine, Must be unique)
# $iDebug - Debug Option
#
# Outputs
#
# Description
# This function connects to the BuildServer and reads commands to run

sub Connect
{
  my ($iDataSource, $iConnectWait, $iClientName, $iExitAfter, $iDebug) = @_;

  my ($iSuccessConnect);

  # Set the Client name
  $BuildClient::gClientName = $iClientName;
  # Set Global Debug flag/filename
  $BuildClient::gDebug = $iDebug;

  # In continual loop try and connect to the datasource
  while (($iExitAfter == -1) || ($iSuccessConnect < $iExitAfter))
  {
    # Cycle through the datasource list
    my $iMachine = shift @$iDataSource;
    push @$iDataSource, $iMachine;
    print "Connecting to $iMachine\n";

    # Process the datasource into hostname and port number
    my ($iHostname,$iPort) = $iMachine =~ /^(\S+):(\d+)/;

    # Create an instance of the message Module to handle the TCP/IP connection
    my $iConn = Msg->associate($iPort, $iHostname, \&rcvd_msg_from_server);

    # Check the status of the connection attempt
    if ($iConn)
    {
      # Connection was succesful
      print "Connection successful to $iMachine\n";
      $iSuccessConnect++;
      # Send a "Ready" command to the Server
      my $serialized_msg = freeze ("Ready", $BuildClient::gClientName, &GetClientVersion);
      print "Sending Ready\n";
      $iConn->transmit_immediately($serialized_msg);
      # Start the message processing loop with inital timeout of 300 seconds
      Msg->result_iteration(300);
      # Server disconnected, clean up by chdir to root
      chdir "\\";
      # Set the client name back to the name specified on the commandline just in case it has had it's name changed.
      $BuildClient::gClientName = $iClientName;
    } else {
      # Connection Failed, wait specified time before continuing and trying another connection attempt
      print "Could not connect to $iHostname:$iPort\n";
      print "Trying another connection attempt in $iConnectWait seconds\n";
      sleep $iConnectWait;
    }
  }
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

# Subroutine for compressing data stream.
# Input: message to be compressed.
# Output: compressed message, ready for sending.
sub Compress($)
{
    my $msg = shift; # Get the message.
    
    # Initialise deflation stream
    my $x;
    eval {$x = deflateInit() or die "Error: Cannot create a deflation stream\n";};
    
    if($@) # Deflation stream creationg has failed.
    {
	    return Compress("Error: creation of deflation stream failed: $@\n");
    }
    
    # Compress the message
    my ($output, $status);
    my ($output2, $status2);
    
    # First attempt to perform the deflation
    eval { ($output, $status) = $x -> deflate($msg); };
    
    if($@) # Deflation has failed.
    {
	    $x = deflateInit();
	    ($output, $status) = $x -> deflate("ERROR: Compression failed: $@\n");
	    ($output2, $status2) = $x -> flush();
	    
	    return $output.$output2;
    }
    
    # Now attempt to complete the compression
    eval { ($output2, $status2) = $x -> flush(); };
    
    if($@) # Deflation has failed.
    {
	    $x = deflateInit();
	    ($output, $status) = $x -> deflate("ERROR: Compression failed: $@\n");
	    ($output2, $status2) = $x -> flush();
	    
	    return $output.$output2;
    }
    
    if($status != Z_OK) # Deflation has failed.
    {
        $x = deflateInit();
	    ($output, $status) = $x -> deflate("ERROR: Compression failed: $@\n");
	    ($output2, $status2) = $x -> flush();
	    
	    return $output.$output2;
    }
    
    # Attempt to complete the compressions
    if($status2 != Z_OK)
    {
        $x = deflateInit();
	    ($output, $status) = $x -> deflate("ERROR: Compression failed: $@\n");
	    ($output2, $status2) = $x -> flush();
	    return $output.$output2;
    }
    
    # Return the compressed output.
    return $output . $output2;
}

1;