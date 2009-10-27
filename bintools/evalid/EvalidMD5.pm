#
# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# This module implements the MD5 version of the Evalid's compare
#

package EvalidMD5;

use strict;
use Carp;
use File::Find;
use IO::File;
use Sys::Hostname;

use FindBin;
use lib "$FindBin::Bin";
require Exporter;
use File::Basename;

use vars       qw($VERSION );
$VERSION     = 0.02;

use EvalidCompare;

# Public

# MD5Generate
#
# Inputs
# $iLeftDir - Left side directory or File containing listing of left side
# $iResultsFile - Name of file to write the list of files and MD5 checksum to
# $iExclude - Reference to array of regular expression patterns to exclude
# $iInclude - Reference to array of regular expression patterns to include
# $iListFile - Filename to read for list of files from [Optional]
# $iDumpDir - Directory to generate dump of comparison data [Optional]
#
# Outputs
#
# Description
# This function generates the MD5 checksum file

sub MD5Generate
{
  my ($iLeftDir, $iResultsFile, $iExclude, $iInclude, $iListFile, $iDumpDir) = @_;

  my (@iLeftFiles);

  # This should have been check before getting here but to be on the safe side
  # check again, as it should never overwrite or append to the file
  croak "$iResultsFile already exists" if (-e $iResultsFile);
  croak "$iListFile does exist" if ((defined($iListFile) && (!-e $iListFile)));

  if (-d $iLeftDir){
    # Make sure all the \ are / for the RegEx
    $iLeftDir =~ s/\\/\//g;
    # Make sure it does not have a / on the end
    $iLeftDir =~ s/\/$//;
    # If $iFileList is defined then use the filelist to generate @iLeftFiles
    if (defined($iListFile))
    {
      # Generate list of files
      @iLeftFiles = &FilterDir($iLeftDir,$iExclude,$iInclude, $iListFile);
    } else {
      # Generate the the directory listing
      @iLeftFiles = &FilterDir($iLeftDir,$iExclude,$iInclude);
    }
  } else {
    croak "$iLeftDir is not a directory";
  }

  # Open the results file for writing
  my ($fResultsFile) = new IO::File;
  croak "Cannot for $iResultsFile for writing" unless ($fResultsFile->open("> $iResultsFile"));

  # Write headers to the file
  print $fResultsFile "Host:".&hostname()."\n";
  print $fResultsFile "Username:".$ENV{'USERNAME'}."\n";
  print $fResultsFile "Date-Time:".scalar(localtime)."\n";
  print $fResultsFile "Version:".$VERSION."\n";
  print $fResultsFile "Directory:".$iLeftDir."\n";
  print $fResultsFile "FileList:".$iListFile."\n" if (defined($iListFile));
  print $fResultsFile "Exclusion(s):";
  foreach my $iExc (sort @$iExclude)
  {
    print $fResultsFile "$iExc ";
  }
  print $fResultsFile "\n";

  print $fResultsFile "Inclusion(s):";
  foreach my $iInc (@$iInclude)
  {
    print $fResultsFile "$iInc ";
  }
  print $fResultsFile "\n";

  print $fResultsFile "----------------\n";

  # Write out sorted list of files with MD5 Checksums
  foreach my $iFile (sort @iLeftFiles)
  {
    my ($MD5, $type) = &EvalidCompare::GenerateSignature($iLeftDir."/".$iFile, $iDumpDir);
    print $fResultsFile $iFile." TYPE=".$type." MD5=".$MD5."\n";
  }

  $fResultsFile->close;
}


# MD5Compare
#
# Inputs
# $iLeftFile - Left side File containing listing and MD5 of left side
# $iRightFile - Right side File containing listing and MD5 of right side
# $iVerbose - Verbose Flag
# $iLog - Logfile name
#
# Outputs
# %iCommon - hash relative filenames with values of file type that are in both directories and Compare results/types
# %iDiff - hash relative filenames with values of file type and directory side infomation
#
# Description

sub MD5Compare
{
  my ($iLeftFile) = shift;
  my ($iRightFile) = shift;
  my ($iVerbose) = defined($_[0]) ? shift : 0;
  my ($iLog) = defined($_[0]) ? shift : *STDOUT;

  my (%iCommon, %iDiff);

  my (%iLeftFiles, %iRightFiles);
  my (%iLeftHeaders, %iRightHeaders);

  # Backup check the files are available to read.
  croak "$iLeftFile is not a file" unless (-f $iLeftFile);
  croak "$iRightFile is not a file" unless(-f $iRightFile);

  #Read the files
  &ReadMD5File($iLeftFile, \%iLeftFiles, \%iLeftHeaders);
  &ReadMD5File($iRightFile, \%iRightFiles, \%iRightHeaders);

  # Check Critical headers
  foreach my $iHeader (sort keys %iLeftHeaders)
  {
    # Warning is certain headers are not identical
    if ($iHeader =~ /^Version|Exclusion\(s\)|Inclusion\(s\)/)
    {
      print $iLog "WARNING:$iHeader is different\n" if ($iLeftHeaders{$iHeader} ne $iRightHeaders{$iHeader});
    }
  }

  # A Hash is used to combine the two directory listing using the filename as the key
  my %iCombinedFiles;

  # Enter the files from the left side listing and check the right side critical header are the same
  # Note all filenames are turned to lower case as this is designed to only wotk on Windows
  foreach my $iFile (sort keys %iLeftFiles)
  {
    $iCombinedFiles{$iFile} = "Left";
  }

  # Enter the files from the right side listing
  # Note all filenames are turned to lower case as this is designed to only wotk on Windows
  foreach my $iFile (sort keys %iRightFiles)
  {
    # Check to see if any entry for this file exists on the left side
    if ((defined ($iCombinedFiles{$iFile})) && ( $iCombinedFiles{$iFile} eq "Left"))
    {
      # Yes, so add to the Common set
      # Check if the MD5 checksum matches
      # The [0] element is the file type
      if ($iLeftFiles{$iFile}[0] ne $iRightFiles{$iFile}[0])
      {
        $iCommon{$iFile} = [$iLeftFiles{$iFile}[0]." to ".$iRightFiles{$iFile}[0], "Type Changed"]; 
      } elsif ($iLeftFiles{$iFile}[1] eq $iRightFiles{$iFile}[1]) {
        $iCommon{$iFile} = [$iLeftFiles{$iFile}[0],"OK"];
      } else {
        $iCommon{$iFile} = [$iLeftFiles{$iFile}[0],"Different"];
      }
      # The filename key is not needed any more as both sides have been processed, so delete the hash entry
      delete $iCombinedFiles{$iFile};
    } elsif (!defined($iCombinedFiles{$iFile})) {
      # No, the key is not defined, so this filename is only in the right side
      $iDiff{$iFile} = [$iRightFiles{$iFile}[0],"Right"];
      # The filename key is not needed any more as both sides have been processed, so delete the hash entry
      delete $iCombinedFiles{$iFile};
    }
  }

  # Add the files left in the hash to the Left side only list
  foreach my $iFile (sort keys %iCombinedFiles)
  {
    $iDiff{$iFile} = [$iLeftFiles{$iFile}[0],"Left"];
  }

  # Return References to the Arrays
  return (\%iCommon, \%iLeftHeaders, \%iRightHeaders, \%iDiff);
}

# FilterDir
#
# Inputs
# $iDir - Directory to process
# $iExclude - Reference to array of regular expression patterns to exclude
# $iInclude - Reference to array of regular expression patterns to include
# $iListFile - Filename to read for list of files from [Optional]
#
# Outputs
# @iFinalFileList - Filtered list relative filenames
#
# Description
# This function produces a filtered list of filenames in the specified directory or from file

sub FilterDir
{
  my ($iDir,$iExclude,$iInclude, $iListFile) = @_;

  my (@iFileList, @iFinalFileList, $iFileName);

  if(defined($iListFile))
  {
    open LIST, "$iListFile" or croak "Cannot open $iListFile\n";
    while(<LIST>)
    {
      next if /^\s+$/;  # skip blank lines 
      my $iFileName = $iDir."/".$_;
      chomp $iFileName; # Remove new line
      if(-e $iFileName)
      {
        # The listed file exists add to the @iFileList
        push @iFileList, $iFileName;
      } else {
        print "Warning: Cannot find $iFileName\n";
      }
    }
    close LIST;
  } else {
    # Produce full filelist listing without directory names
    find sub { push @iFileList, $File::Find::name if (!-d) ;}, $iDir;
  }

  foreach my $iFile ( @iFileList)
  {
    my $iExcludeFile = 0;

    # Remove the specified directory path from the front of the filename
    $iFile =~ s#^$iDir/##;

    # Process all Exclude RegEx to see if this file matches
    foreach my $iExcludeRegEx (@$iExclude)
    {
      if ($iFile =~ /$iExcludeRegEx/i)
      {
        # Mark this file to be excluded from the final list
        $iExcludeFile = 1;
      }
    }

    # Process all Include RegEx to see if this file matches
    foreach my $iIncludeRegEx (@$iInclude)
    {
      if ($iFile =~ /$iIncludeRegEx/i)
      {
        # Mark this file to be Included in the final list
        $iExcludeFile = 0;
      }
    }

    # Added the file to the final list based on the flag
    push @iFinalFileList, lc($iFile) unless $iExcludeFile;
  }

  return @iFinalFileList;

}

# MD5ComparePrint
#
# Inputs
# $iCommon - Reference to Hash of common file names and the result the comparision
# $iLeftHeaders - Reference to Hash contain the left side
# $iRightHeaders - Reference to Hash contain the right side
# $iDiff - Reference to Hash of relative filenames with values of file type and left/right directory side
# $iLog - Logfile name
#
# Outputs
#
# Description
# This function prints the output of a Compare
sub MD5ComparePrint
{
  my ($iCommon) = shift;
  my ($iLeftHeaders) = shift;
  my ($iRightHeaders) = shift;
  my ($iDiff) = shift;
  my ($iLog) = shift;

  my ($iFailed) = 0; # Count of the failed comparisions
  my ($iPassed) = 0; # Count of the Passed comparisions
  my ($iLeft) = 0; # Count of the Passed comparisions
  my ($iRight) = 0; # Count of the Passed comparisions


  my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
  printf $iLog "\n----------------\n%02d:%02d %02d/%02d/%04d\n", $hour, $min, $mday, $mon+1, $year+1900;
  print $iLog "evalid\nLeft Side=$ARGV[0]\nRight Side=$ARGV[1]\n";
  print $iLog "\nLeft side information\n";
  foreach my $iHeader (sort keys %$iLeftHeaders)
  {
    print $iLog $iHeader.":".$$iLeftHeaders{$iHeader}."\n";
  }
  print $iLog "\nRight side information\n";
  foreach my $iHeader (sort keys %$iRightHeaders)
  {
    print $iLog $iHeader.":".$$iRightHeaders{$iHeader}."\n";
  }
  print $iLog "\n";

  foreach my $iFile (sort keys %$iCommon)
  {
    if ($$iCommon{$iFile}[1] eq "OK")
    {
      print $iLog "Passed:$iFile (".$$iCommon{$iFile}[0].")\n";
      $iPassed++;
    }
  }
  print $iLog "\n";

  foreach my $iFile (sort keys %$iCommon)
  {
    if ($$iCommon{$iFile}[1] eq "Type Changed")
    {
      print $iLog "Type Changed:$iFile (".$$iCommon{$iFile}[0].")\n";
      $iFailed++;
    }
  }
  print $iLog "\n";

  foreach my $iFile (sort keys %$iCommon)
  {
    if ($$iCommon{$iFile}[1] eq "Different")
    {
      print $iLog "Failed:$iFile (".$$iCommon{$iFile}[0].")\n";
      $iFailed++;
    }
  }
  print $iLog "\n";

  foreach my $iFile (sort keys %$iDiff)
  {
    if ($$iDiff{$iFile}[1] eq "Left")
    {
      print $iLog "Missing Left:$iFile (".$$iDiff{$iFile}[0].")\n";
      $iLeft++;
    }
  }
  print $iLog "\n";

  foreach my $iFile (sort keys %$iDiff)
  {
    if ($$iDiff{$iFile}[1] eq "Right")
    {
      print $iLog "Missing Right:$iFile (".$$iDiff{$iFile}[0].")\n";
      $iRight++;
    }
  }

  print $iLog "\n\nSummary\n";
  print $iLog "Total files processed=".($iPassed+$iFailed+$iRight+$iLeft)."\n";
  print $iLog "Files Passed=$iPassed\n";
  print $iLog "Files Failed=$iFailed\n";
  print $iLog "Missing Files in Left=".$iRight."\n";
  print $iLog "Missing Files in Right=".$iLeft."\n";

  return ($iFailed);
}
# NameOnly
# 
# Inputs
# $filename - may contain path and file extension
#
# Outputs
# $nameOnly - filename without extension and path
#
# Description
# This routine is used to extract the name of the file
# only from a filename that may include a path and file extension
# 
sub NameOnly
{
  my ($filename) = @_;
  my $nameOnly = basename($filename);
  $nameOnly =~ s/(\w+.*)\.\w+$/$1/;
  return $nameOnly;
}

# MD5CompareZipDel
#
# Inputs
# $iCommon - Reference to Hash of common file names and the result the comparision
# $iDiff - Reference to Hash of relative filenames with values of file type and left/right directory side
# $iLeft - filename of Left side directory
# $iRight - filename of Right side directory
#
# Outputs
#
# Description
# This function prints the output of a Compare results in a format ready for creating the a
# Zip and batch file to upgrade the left side to the equivalent of the right side.
sub MD5CompareZipDel
{
  my ($iCommon) = shift;
  my ($iDiff) = shift;
  my ($iLeft) = shift;
  my ($iRight) = shift;

  # Build a suitable name for outputfiles based on input filenames
  $iLeft = NameOnly($iLeft);
  $iRight = NameOnly($iRight);
  my ($iBasename) = $iLeft."_to_".$iRight;

  open DELLIST, ">del_$iBasename.bat";
  open ZIPLIST, ">zip_$iBasename.log";
  open ZIPBAT, ">zip_$iBasename.bat";

  foreach my $iFile (sort keys %$iCommon)
  {
    if (($$iCommon{$iFile}[1] eq "Different") || ($$iCommon{$iFile}[1] eq "Type Changed"))
    {
      print ZIPLIST "$iFile\n";
    }
  }

  foreach my $iFile (sort keys %$iDiff)
  {
    if ($$iDiff{$iFile}[1] eq "Right")
    {
      print ZIPLIST "$iFile\n";
    } else {
      # DEL needs the / to be \
      $iFile =~ s/\//\\/g;
      print DELLIST "del /F $iFile\n";
    }
  }

  print ZIPBAT "zip $iBasename.zip -@<zip_$iBasename.log\n";

  close DELLIST;
  close ZIPLIST;
  close ZIPBAT;

}


# Private

# ReadMD5File
#
# Inputs
# $iResultsFile - Results filename to process
# $iResults - Reference to Results Hash
# $iHeaders - Reference to Headers Hash
#
# Outputs
#
# Description
# This function reads the conntent of the MD5 File in to a Hash
sub ReadMD5File
{
  my ($iResultsFile, $iResults, $iHeaders) = @_;

  # Open the results file for reading
  open (INPUT, "$iResultsFile") or croak "Cannot for $iResultsFile for reading";
  while (<INPUT>)
  {
    if (/^(\S+?):(.*)/)
    {
      $$iHeaders{$1} = $2;
    } elsif (/^(\S+?)\sTYPE=(.*?)\sMD5=(.*)/){
      $$iResults{$1} = [$2,$3];
    }
  }
  close INPUT;

}

1;
