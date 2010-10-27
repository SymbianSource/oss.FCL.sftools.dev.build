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
# Script to Generate the XML command file from the xml files
# 
#

use strict;
use FindBin;		# for FindBin::Bin
use Getopt::Long;
use File::Copy;

use lib $FindBin::Bin;
use lib "$FindBin::Bin/lib";

# Process the commandline
my ($iDataSource, $iDataOutput, $iLogFile, $iSourceDir, $iReallyClean, 
    $iClean, $iXmlSource, $iConfName, $iMergedXml, $iValidate,
    $iTextOutput, $iCBROutput, $iFilter, $iEffectiveDir) = ProcessCommandLine();

if (scalar(@$iXmlSource))
{
	use GenXml;
	&GenXml::Start($iXmlSource, $iDataOutput, $iLogFile, $iSourceDir, 
	               $iConfName, $iMergedXml, $iValidate, $iTextOutput, $iCBROutput, $iFilter, $iEffectiveDir);
} else {
	use GenBuild;
	# Start the generation of the XML
  print "Warning old .txt file input is being used\n";
	&GenBuild::Start($iDataSource, $iDataOutput, $iLogFile, $iSourceDir, $iReallyClean, $iClean);
}


# ProcessCommandLine
#
# Inputs
#
# Outputs
# @iDataSource array of multiple (txt file(s) to process)
# $iDataOutput (XML file to generate)
# $iLogFile (Log file to put processing errors)
# $iSourceDir (Location of Source)
# $iReallyClean (script to run the "abld reallyclean" command)
# $iClean (script to run the "abld clean" command)
# @iXmlSource array of multiple (XML file(s) to process)
# $iConfName (Name of configuration to generate)
# $iMergedXml - Hidden option to save the output of the merging xml process for debug use
# $iValidate (Just validate the input)
# $iText (txt file to generate)
# $iFilter (filter to apply before generating merged XML file)
# $iEffectiveDir (location at which source will be used)
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, $iPort, @iDataSource, $iLogFile, $iSourceDir, $iReallyClean, $iClean, 
      @iXmlSource, $iConfName, $iMergedXml, $iValidate, $iTextOutput, $iCBROutput, 
      $iFilter, $iEffectiveDir);
  GetOptions(
  	'h' => \$iHelp, 
  	'd=s@' =>\@iDataSource, 
  	'o=s' => \$iDataOutput, 
  	'l=s' => \$iLogFile, 
  	's=s' => \$iSourceDir, 
  	'e=s' => \$iEffectiveDir, 
  	'r=s' => \$iReallyClean, 
  	'c=s' => \$iClean, 	# or $iCBROutput in XML input mode
  	'x=s@' =>\@iXmlSource, 
  	'n=s' => \$iConfName, 
  	'm=s' => \$iMergedXml, 
  	'v' =>\$iValidate,
  	't=s' => \$iTextOutput,
  	'f=s' => \$iFilter);

  Usage() if ($iHelp);
  
  Usage("Must specify the root of the source tree with -s") if (!defined $iSourceDir);
  Usage("Must specify at least one input file") if ((!@iDataSource) && (!@iXmlSource));
  Usage("$iSourceDir is not a directory") if (!-d $iSourceDir);

  if (scalar @iXmlSource)
  	{
  	# Validation of options for XML input
  	
  	Usage("Can't mix -d and -x") if (scalar @iDataSource);
  	
  	$iCBROutput = $iClean;	# deal with ambiguity in -c option
  	$iClean = "";
  	
  	if ((!defined $iMergedXml) && (!defined $iDataOutput) 
  	     && (!defined $iTextOutput) && (!defined $iCBROutput))
  		{
  		Usage("Must specify at least one output file") if (!defined $iValidate);
  		}
  	else
  		{
  		Usage("Can't specify output files with -v") if (defined $iValidate);
  		}
  	if (defined $iDataOutput || defined $iTextOutput)
  		{
  		Usage("Must specify configuration for XML or list output") if (!defined $iConfName);
  		}
  	Usage("Can't specify reallyclean files with -x") if (defined $iReallyClean);
  	
  	$iEffectiveDir = $iSourceDir if (!defined $iEffectiveDir);
	}
  else
    {
  	# Validation of options for component list input

    Usage("Must specify a logfile with -l") if (!defined $iLogFile);
	Usage("Can't request validation on non-XML input") if (defined $iValidate);  	
  	Usage("Can't specify merged or text output with -d") if (defined $iTextOutput || defined $iMergedXml);
	Usage ("Can't specify a filter for non-XML input") if (defined $iFilter);
	Usage ("Can't specify a configuration for non-XML input") if (defined $iConfName);
    }
  
  foreach my $iFile (@iDataSource)
  {
    if (! -e $iFile)
    {
      die "Cannot open $iFile";
    }
  }

  foreach my $iFile (@iXmlSource)
  {
    if (! -e $iFile)
    {
      die "Cannot open $iFile";
    }
  }

  # Backup existing files
  
  &backupFile($iLogFile);
  &backupFile($iDataOutput);
  &backupFile($iMergedXml);
  &backupFile($iTextOutput);
  &backupFile($iCBROutput);
  &backupFile($iReallyClean);
  &backupFile($iClean);

  return(\@iDataSource, $iDataOutput, $iLogFile, $iSourceDir, $iReallyClean, $iClean, \@iXmlSource, $iConfName, $iMergedXml, $iValidate, $iTextOutput, $iCBROutput, $iFilter, $iEffectiveDir);
}

# backupFile
#
# Inputs
# $iFile - filename to backup
#
# Outputs
#
# Description
# This function renames a file with the .baknn extension, if necessary
sub backupFile
{
	my ($iFile) = @_;
	
	return if (!$iFile || !-e $iFile);
	
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
	print "WARNING: $iFile already exists, creating backup of original with new name of $iBak\n";
	move($iFile,$iBak) or die "Could not backup $iFile to $iBak because of: $!\n";
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  my ($reason) = @_;
  
  print "ERROR: $reason\n" if ($reason);
  print <<USAGE_EOF;

  Usage: Genxml.pl [options]

  options for XML input mode:

  -h  help
  -s  Source Directory
  -x  XML Data Source (XML file) [Multiple -x options allowed]
  -f  filter to apply to data source before main processing [optional]
  -m  Output merged & filtered XML file [optional]
  -n  Configuration name to use
  -l  Logfile [optional]
  -o  Output XML file [optional]
  -e  Effective source directory [optional]
  -t  Output TXT file corresponding to XML file [optional]
  -c  Output list of CBR components [optional]
  -v  Validate XML files only, Stop after merging and validating.
      Turns on extra INFO messages for Validation [optional]

  options for backward compatibility mode:

  -h  help
  -l  Logfile
  -s  Source Directory
  -d  Data Source (txt file) [Multiple -d options allowed]
  -o  Output XML file
  -r  Filename for ReallyClean xml file [optional]
  -c  Filename for Clean xml file [optional]

  Description:
  This program generates an XML file that is used by the Build
  Client-Server System. It expands the summarised configuration
  information stored in the input files to a detailed command by command
  instruction set for the Build System to use. This enabled the
  specified configuration to be built by the build system.

USAGE_EOF
  exit 1;
}
