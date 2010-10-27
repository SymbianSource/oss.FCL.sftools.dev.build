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
# Script to Process builds commands sent from the Build Server via TCP/IP
# 
#

use strict;
use FindBin;		# for FindBin::Bin
use Getopt::Long;

# Add the directory contain this perl script into the path to find modules
use lib $FindBin::Bin;

use BuildClient;

# Process the commandline
my ($iDataSource, $iConnectWait, $iClientName, $iExitAfter, $iDebug) = ProcessCommandLine();

# Create socket to server
&BuildClient::Connect($iDataSource, $iConnectWait, $iClientName, $iExitAfter, $iDebug);

# ProcessCommandLine
#
# Inputs
#
# Outputs
# $iDataSource - Reference to array of Hostname:Port combinations to try in sequence
# $iConnectWait (How often it polls for a build server)
# $iClientName (Client name used to help identify the machine, Must be unique)
# $iExitAfter - Number of succesful connections to exit after
# $iDebug - Prints Command output to screen to help debug
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, @iDataSource, $iConnectWait, $iDebug);
  my ($iExitAfter) = -1; #Set default to never exit
  GetOptions('h' => \$iHelp, 'd=s' => \@iDataSource, 'debug:s' => \$iDebug, 'w=i' => \$iConnectWait, 'c=s' => \$iClientName, 'e=i' => \$iExitAfter);

  if (($iHelp) || (!defined @iDataSource) || (!defined $iConnectWait) || (!defined $iClientName))
  {
    &Usage();
  } else {
		foreach my $iMachine (@iDataSource)
		{
			&Usage() if ($iMachine !~ /^\S+:\d+/);
		}
    return(\@iDataSource, $iConnectWait, $iClientName, $iExitAfter, $iDebug);
  }
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: BuildClient.pl [options]

USAGE_EOF
print "  Version: ".&BuildClient::GetClientVersion()."\n";
print <<USAGE_EOF;

  options:

  -h  help
  -d  Data Source - format Hostname:Port (e.g. Machine:1234) [Multiple allowed]
  -w  Seconds to wait between each connection attempt
  -c  Client name (Used to identify the machine in the logs, Must be unique)
  -e  Exit after specified number of successful connections [optional]
      default to never exit
USAGE_EOF
	exit 1;
}
