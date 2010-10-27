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

package ParseXML;

use strict;
use Carp;
use XML::Parser;

# Package variables - these can also be accessed the from package "SubHandlers"
use vars qw($gDataSource @gCommands @gSetEnv);

# ParseXMLData
#
# Inputs
# $iDataSource - XML Command file.
#
# Outputs
# @gCommands   - Contains commands.  Each command has various attributes.
# @gSetEnv     - Contains environment vars.  Each var has a key and value.
#
# Description
# This function parses the XML file and returns two arrays.
sub ParseXMLData
{
  my ($iDataSource) = @_;

  eval { $gDataSource = File::Spec->rel2abs($iDataSource); };

  undef @gCommands;
  undef @gSetEnv;

  # Create a new XML Parser
  my $iParser = new XML::Parser(Style=>'Subs', Pkg=>'SubHandlers', ErrorContext => 2);
  # Supply the XML Parser the data source
  $iParser->parsefile($iDataSource);

  return \@gCommands, \@gSetEnv;
}



package SubHandlers;
use FreezeThaw qw(freeze thaw);

# Execute
#
# Inputs
#
# Outputs
#
# Description
# This function handles the Execute tag in the XML
sub Execute
{
  my $iExpat = shift; my $iElement = shift;

  my (%iAttr);

  # Read the attributes
  while (@_) {
    my $iAtt = shift;
    my $iVal = shift;
    $iAttr{$iAtt} = $iVal;
  }

  # Read in the attributes into temporary variables
  my $iID                 = $iAttr{'ID'};   # ignored
  my $iStage              = $iAttr{'Stage'};
  my $iComp               = $iAttr{'Component'};
  my $iCwd                = $iAttr{'Cwd'};
  my $iCommandLine        = $iAttr{'CommandLine'};
  my $iExitOnScanlogError = $iAttr{'ExitOnScanlogError'};

  # Replace the magic words with values in the commandline
  if ($ParseXML::gDataSource) {
    $iCommandLine =~ s/%%%this_file%%%/$ParseXML::gDataSource/g;
  } else {
    $iCommandLine =~ s/%%%this_file%%%/this_file/g;
  }

  # Replace the server side environment variables with values in the commandline
  $iCommandLine =~ s/%%(\w+)%%/$ENV{$1}/g;
  # Replace the server side environment variables with values in the cwd
  $iCwd =~ s/%%(\w+)%%/$ENV{$1}/g;

  # Store the data about the command in a temporary hash
  my %temp = (
               'Type'               => 'Execute',
               'Stage'              => $iStage,
               'Component'          => $iComp,
               'Cwd'                => $iCwd,
               'CommandLine'        => $iCommandLine,
               'ExitOnScanlogError' => $iExitOnScanlogError,
             );
  push @ParseXML::gCommands, \%temp;
}


# Product
#
# Inputs
#
# Outputs
#
# Description
# This function handles the Product tag in the XML
sub Product
{
  my $iExpat = shift; my $iElement = shift;

  my (%iAttr);

  # Read the attributes
  while (@_) {
    my $iAtt = shift;
    my $iVal = shift;
    $iAttr{$iAtt} = $iVal;
  }

  my $iName = $iAttr{'Name'};

  print "$iElement = $iName\n";
}

# SetEnv
#
# Inputs
#
# Outputs
#
# Description
# This function handles the SetEnv tag in the XML
sub SetEnv
{
  my $iExpat = shift; my $iElement = shift;

  my (%iAttr);

  # Read the attributes
  while (@_) {
    my $iAtt = shift;
    my $iVal = shift;
    $iAttr{$iAtt} = $iVal;
  }

  # Read in the attributes to temporary variables
  my $iName  = $iAttr{'Name'};
  my $iValue = $iAttr{'Value'};
  my $iOrder = $iAttr{'Order'};   # Ignored

  # Replace the server side environment variables with values in the environment variable value
  $iValue =~ s/%%(\w+)%%/$ENV{$1}/g;

  # Store the data about the Environment
  my %temp = (
               'Name'  => $iName,
               'Value' => $iValue,
             );
  push @ParseXML::gSetEnv, \%temp;
}

# Exit
#
# Inputs
#
# Outputs
#
# Description
# This function handles the Exit tag in the XML which cause the client to exit
sub Exit
{
  my $iExpat = shift; my $iElement = shift;
  my (%iAttr);

  # Read the attributes
  while (@_) {
    my $iAtt = shift;
    my $iVal = shift;
    $iAttr{$iAtt} = $iVal;
  }

  # Read in the attributes into temporary variables
  my $iStage              = $iAttr{'Stage'};
  
  # Store the data about the command in a temporary hash
  my %temp = (
               'Type'               => 'Exit',
               'Stage'              => $iStage
             );
  push @ParseXML::gCommands, \%temp;
}
1;
