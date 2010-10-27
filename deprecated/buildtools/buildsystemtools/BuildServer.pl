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
# Script to send commands to 1 or more Build Clients to perform parallel builds
# 
#

use strict;
use FindBin;    # for FindBin::Bin
use Getopt::Long;
use File::Copy;

# Add the directory contain this perl script into the path to find modules
use lib $FindBin::Bin;

use BuildServer;
use ParseXML;

# Turn on per command Buffering of STDOUT, so the log files are not so far behind what is actually happening
$| = 1;

# Process the commandline
my ($iDataSource, $iPort, $iLogFile, $iEnvSource, $iConnectionTimeout, $iSocketConnections) = ProcessCommandLine();

# Create socket to server
&BuildServer::Start($iDataSource, $iPort, $iLogFile, $iEnvSource, $iConnectionTimeout, $iSocketConnections);


# ProcessCommandLine
#
# Inputs
#
# Outputs
# $iPort (Port to listen on for Build Clients)
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, @iPort, $iDataSource, $iLogFile, $iEnvSource, $iConnectionTimeout, $iSocketConnections);
  GetOptions('h' => \$iHelp, 'd=s' =>\$iDataSource, 'p=i' => \@iPort, 'l=s' => \$iLogFile, 'e=s' =>\$iEnvSource, 't=s' =>\$iConnectionTimeout, 'c=s' =>\$iSocketConnections);

  if (($iHelp) || (scalar(@iPort) < 0) || (!defined $iDataSource) || (!defined $iLogFile))
  {
    Usage();
  } elsif (! -e $iDataSource) {
    die "Cannot open $iDataSource";
  }
  if ((defined $iEnvSource) && (! -e $iEnvSource))
  {
    die "Cannot open $iEnvSource";
  }
  
  &backupFile($iLogFile) if (-e $iLogFile);
  
  return($iDataSource,\@iPort,$iLogFile, $iEnvSource, $iConnectionTimeout, $iSocketConnections);
}

# backupFile
#
# Inputs
# $iFile - filename to backup
#
# Outputs
#
# Description
# This function renames a file with the .baknn extension
sub backupFile
{
  my ($iFile) = @_;
  
  my ($iBak) = $iFile.".bak";
  my ($i, $freefilename);
  # Loop until you find a free file name by increamenting the number on the end of the .bak extension
  while (!$freefilename)
  {
    if (-e $iBak.$i)
    {
      $i++;
    } else {
      $iBak .= $i;
      $freefilename = 1;
    }
  }
  print "WARNING: $iFile already exists, creating backup of orignal with new name of $iBak\n";
  move($iFile,$iBak) or die "Could not backup $iFile to $iBak because of: $!\n";
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

  Usage: BuildServer.pl [options]

USAGE_EOF
print "  Version: ".&BuildServer::GetServerVersion()."\n";
print <<USAGE_EOF;

  options:

  -h  help
  -p  Port number to listen on for Build Clients [Multiple allowed]
  -t  Time between connection attempts [Optional - default 0 seconds]
  -c  Number of connection attempts per port [Optional - default infinite]
  -d  Data Source (XML command file)
  -l  Log file for output from commands run on the Build Client
  -e  Use Environment of this data source (XML command file)
      The Environment in the main data source takes precedence
USAGE_EOF
  exit 1;
}
