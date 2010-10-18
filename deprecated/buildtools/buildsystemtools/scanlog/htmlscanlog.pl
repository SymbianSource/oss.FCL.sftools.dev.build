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

# summarise an automated build log
use strict;
use Getopt::Long;
use HTML::Entities;
use Carp;
use FindBin;		# for FindBin::Bin

# Add the directory contain this perl script into the path to find modules
use lib $FindBin::Bin;
use Scanlog;

# For Date calculations
use lib "$FindBin::Bin/../lib"; # For running in source
use lib "$FindBin::Bin/build/lib"; # For running in epoc32\tools
use Date::Manip;

# Set TimeZone because Date:Manip needs it set and then tell it to IGNORE the TimeZone
&Date_Init("TZ=GMT","ConvTZ=IGNORE");

# Variables
my $line;
my $iSlurp;
my $PhaseStartTime;
my %Phases;
my %Components;
my %Commands;
my $component;
my $command;
my $phase;
my $match_phase='';
my %errors;
my %warnings;
my %remarks;
my %migrationNotes;
my %AdvisoryNotes;
my %CmdErrors;
my %CmdWarnings;
my %CmdRemarks;
my %CmdMigrationNotes;
my %CmdAdvisoryNotes;
my %missing;
my %not_built;
my $starttime;
my $duration;
my $warningcount;
my $errorcount;
my $remarkcount;
my $migrationNoteCount;
my $AdvisoryNoteCount;
my ($iStatus, $iName);
my %htmlColours=(
"errors" =>"#ff0000",
"warnings" =>"#fff000",
"remarks" =>"#ffccff",
"migrationNotes" =>"#ffcc99",
"AdvisoryNotes" => "#ffa500"
);
# Hires Timer Variables
my %HiResComponents;
my %HiResCommands;
my $HiResStartTime;
my $HiResErrorFlag; #True if one of the Clients has not reported HiRes timing info

my $Dsec;

# History Variables
my ($hostname) = "N/A";
my ($EndTime);

# Main section

my ($iOutput, $iTitle, $iVerbose, $iDiff, $iWhat, $iHistory, $iClass, @iLogs) =&ProcessCommandLine();

# Open Output file
  open (HTML, ">$iOutput") or die "Couldn't open $iOutput for writing: $!\n";

# Open Diff file if specified
if ($iDiff ne '')
{
  open (DIFF, ">$iDiff") or die "Couldn't open $iDiff for writing: $!\n";
}

# Print HTML Header
&PrintHTMLHeader($iTitle);


# Parse each log File
foreach my $iLog (@iLogs) # parses through all logs 
{
  # Open the Log file for reading
  unless (open (LOG, "< $iLog"))
    {   # On error, warn rather than die. Then record a "pseudo-error", which will appear in summary output file.
        $line = "Couldn't open $iLog for reading: $!";
        warn "$line\n";
        $command = 'HTMLScanLog';
        $component = 'Log Summaries';
        $Commands{$command} = 0;            # Need to define these! So assume zero seconds 
        $HiResCommands{$command} = 0;       # duration for each of four variables.
        $Components{$component} = 0;        # The fact the relevant time(s) are defined
        $HiResComponents{$component} = 0;   # triggers inclusion in the applicable table. 
        do_error($iLog);
        next;
    }
  # Chop $iLog just to the filename
  $iLog =~ s/^.*\\//;

  # Process the logs
  &ProcessLog($iLog);
  close LOG;
}

&PrintResults($iTitle);

# Print HTML Footer
&PrintHTMLFooter();

# Handle the History file
if (defined $iHistory)
{
  # Work out the class
  my ($mclass) = "N/A";
  open (MC, "< $iClass");
  while (<MC>)
  {
    chomp;
    my (@columns) = split(/,/);
    $mclass = $columns[0] if ($columns[1] eq $hostname);
  }
  close (MC);
  
  # Open and Lock the csv file
  open(FH, "+< $iHistory")                or die "can't open $iHistory: $!";
  flock(FH, 2)                        or die "can't flock iHistory: $!";
  # Read the file
  # Reader the headers
  my $cline = <FH>;
  chomp($cline);
  my (@headers) = split(/,/,$cline);
  # Read the data
  my (@csvdata);
  @csvdata = <FH>;
  # Return to the begining
  seek(FH,0,0)                        or die "Seeking: $!";
  # Print the old and new data
  # Work if new headers are needed
  # Use LowRes component names because they are always available
  foreach my $component (sort {lc $a cmp lc $b} keys %Components)
	{
    my $compexist = 0;
    # Itterate through the header array to see if it already exists
    foreach my $header (@headers)
    {
      if ($component eq $header)
      {
        $compexist = 1;
      }
    }
    # This component not found in the headers
    # put the new header at the end of the header array
    push @headers, $component if ($compexist == 0);
  }
  # Print the headers back out
  print FH join(',',@headers)."\n";
  # Print the original data
  print FH @csvdata;
  # Print the new data
  foreach my $header (@headers)
  {
    if ($header eq 'Machine Class')
    {
      print FH "$mclass";
    } elsif ($header eq 'Machine Name') {
      print FH "$hostname";
    } elsif ($header eq 'Title') {
      print FH "$iTitle";
    } elsif ($header eq 'End Time') {
      print FH "$EndTime";
    } elsif ($header eq 'Total Time') {
      print FH &ConvertSeconds($duration);
    } else {
      # If there is a complete set of HiRes data then use that instead of the LowRes data
      if ((defined %HiResComponents) && !$HiResErrorFlag)
      {
        if (exists $HiResComponents{$header})
        {
          print FH &ConvertSeconds($HiResComponents{$header});
        } else {
          print FH "";
        }
      } else {
        if (exists $Components{$header})
        {
          print FH &ConvertSeconds($Components{$header});
        } else {
          print FH "";
        }
      }
    }
    # Print the , for next entry
    print FH ",";
  }
  # End the entry
  print FH "\n";

  # truncate just in case the file is shorter
  truncate(FH,tell(FH))               or die "Truncating: $!";
  close(FH)                           or die "Closing: $!";
}

# DiffLog
#
# Inputs
#
# Outputs
#
# Description
# This function Outputs lines to the diff log
sub DiffLog()
{
    # Write the line to diff file if specified and not a line with Build Time dependent infomation
    if ($iDiff ne '')
    {
       # Check the line for Build Time dependent infomation
       unless (($line =~ /^=== .+ started/) || ($line =~ /^=== .+ finished/) || ($line =~ /^---/) || ($line =~ /^\+\+/))
       {
          print DIFF $line;
       }
    }
}


# ProcessLog
#
# Inputs
# $iLog - Logfile name
#
# Outputs
#
# Description
# This function processes the commandline
sub ProcessLog()
{
  my ($iLog) = @_;
  print "Processing: $iLog\n";

  while ($line=<LOG>)
    {
    &DiffLog;

    # Hostname is
    # capture the hostname if available
    if ($line =~ /^Hostname is (.*)$/)
    {
      $hostname = $1;
    }

    # ===-------------------------------------------------
    # === Stage=1
    # ===-------------------------------------------------
    # === Stage=1 started Wed Apr 30 23:09:38 2003

    if ($line =~ /^===------/)
    {
      $line=<LOG>;
          &DiffLog;
      $line=<LOG>;
          &DiffLog;
      $line = <LOG>;
          &DiffLog;
      $line =~ /^=== (.+) started (.*)/;
      $phase = $1;
      $PhaseStartTime =$2;
      $match_phase=$phase;
      $match_phase=~s-\\-\\\\-go;
      next;
    }

    # === bldfiles finished Sat Jul 24 01:38:56 1999.
    if ($line =~ /^=== $match_phase finished (.*)/)
    {
      my ($TempTime) = $1;
      # Calculate the difference in Date/Time and Total up for Phase
      $Phases{$phase} += &DiffDateTime($PhaseStartTime, $TempTime) ;
      # The check to see if phase end is later than current EndTime
      my $err;
      # The first time a phase end is seen set $EndTime
      if (!defined $EndTime)
      {
        $EndTime = $TempTime;
      } else {
        # Check the delta to previous EndTime value is positive
        # Need due to multiple log file processing might not be in time order
        my ($delta) = &DateCalc($EndTime,$TempTime,\$err);
        die "Date Manip error" if ($err);
        # If the delta starts with a + symbol $TempTime is later or the same as the last EndTime so set the new EndTime.
        if ($delta =~ /^\+/)
        {
          $EndTime = $TempTime;
        }
      }
      next;
    }


    # === resource == gdtran 036

    if ($line =~ /=== $match_phase == (.*)$/)
    {
      $component = $1;
      next;
    }

    # Find Command
    # -- bldmake bldfiles -keepgoing
    if ($line =~ /^-- (.*)/)
    {
      $command = $1;
      next;
    }

    # Find the Command's Start time
    # ++ Started at Sat May 03 21:09:07 2003
    if ($line =~ /^\+\+ Started at (.*)/)
    {
      $starttime = $1;
      next;
    }

    # Find the Command's End time
    # ++ Started at Sat May 03 21:09:07 2003
    if ($line =~ /^\+\+ Finished at (.*)/)
    {
      # Calculate the difference in Date/Time and Total up for Command
      $Dsec = &DiffDateTime($starttime, $1);
      $Commands{$command} += $Dsec;
      # Calculate the difference in Date/Time and Total up for Component
      $Components{$component} += $Dsec;
      next;
    }

    # Act on a HiRes Timer unavailable statement in the log
    # +++ HiRes Time Unavailable
    if (($line =~ /^\+\+\+ HiRes Time Unavailable/) && !$HiResErrorFlag)
    {
      $HiResErrorFlag = 1;
          print "Warning one of the clients is not sending HiRes timer Data\n";
          print "No HiRes timings will be available\n";
          print "Reverting to LowRes timing Data\n";
      # Clear out Current HiRes Data
      undef %HiResCommands;
      undef %HiResComponents;
      next;
    }


    # Find the Command's HiRes Start time
    # +++ HiRes Start 1051993130.602050
    if (($line =~ /^\+\+\+ HiRes Start (\S+)/) && !$HiResErrorFlag)
    {
      $HiResStartTime = $1;
      next;
    }

    # Find the Command's HiRes End time
    # +++ HiRes End 1051993193.829650
    if (($line =~ /^\+\+\+ HiRes End (\S+)/) && !$HiResErrorFlag)
    {
      # Calculate the difference in Date/Time and Total up for Command
      $HiResCommands{$command} += ($1 - $HiResStartTime);
      # Calculate the difference in Date/Time and Total up for Component
      $HiResComponents{$component} += ($1 - $HiResStartTime);
      next;
    }
    
    # Lines to Ignore
    ($iStatus) =&Scanlog::CheckForIgnore($line);
    if($iStatus)
    {
      next;
    }

    # Advisory Notes
    ($iStatus) =&Scanlog::CheckForAdvisoryNotes($line);
    if ($iStatus)
    {
       do_AdvisoryNotes($iLog);
       do_slurp($iSlurp);
      next;
    }

    # Migration Notes
    ($iStatus) = &Scanlog::CheckForMigrationNotes($line);
    if ($iStatus)
      {
      do_migrationNotes($iLog);
      next;
      }

    # Remarks
    ($iStatus, $iSlurp) =&Scanlog::CheckForRemarks($line);
    if ($iStatus)
    {
      do_remarks($iLog);
      do_slurp($iSlurp);
      next;
    }

    # Errors
    ($iStatus) =&Scanlog::CheckForErrors($line);
    if ($iStatus)
    {
      do_error($iLog);
      next;
    }

    
    # Warnings
    ($iStatus) =&Scanlog::CheckForWarnings($line);
    if ($iStatus)
    {
      do_warning($iLog);
      next;
    }
    

    # Things Not Built
    ($iStatus, $iName) =&Scanlog::CheckForNotBuilt($line);
    if ($iStatus)
    {
      do_error($iLog); # record these along with the errors
      $not_built{$iName} = "$component";
      next;
    }

    # Things missing
    ($iStatus, $iName) =&Scanlog::CheckForMissing($line);
    if ($iStatus)
    {
      do_error($iLog);
      $missing{$iName} += 1;
      next;
    }

	}
}


# PrintResults
#
# Inputs
# $iTitle (Title for Log file)
#
# Outputs
#
# Description
# This function prints all the data as HTML
sub PrintResults
{
  my ($iTitle) = @_;
  
  my $title;

  # Print Heading of Log File
  my $heading ="Overall";
  print HTML qq{<h1>$iTitle</h1>\n};
  print HTML qq{<h2>$heading</h2>\n};

  # Calculate the total number of remarks messages
	$remarkcount = 0;
	foreach $component (sort {lc $a cmp lc $b} keys %remarks)
		{
		$remarkcount += scalar(@{$remarks{$component}});
		}
  # Calculate the Total number of errors
  	$errorcount = 0;
	foreach $component (sort {lc $a cmp lc $b} keys %errors)
		{
		$errorcount += scalar(@{$errors{$component}});
		}
  # Calculate the total number of warnings
	$warningcount = 0;
	foreach $component (sort {lc $a cmp lc $b} keys %warnings)
		{
		$warningcount += scalar(@{$warnings{$component}});
		}
  
  # Calculate the total number of migration notes
        $migrationNoteCount=0;
        foreach $component (sort {lc $a cmp lc $b} keys %migrationNotes)
                {
                $migrationNoteCount += scalar(@{$migrationNotes{$component}});
                }

  # Calculate the total number of Advisory notes
        $AdvisoryNoteCount=0;
        foreach $component (sort {lc $a cmp lc $b} keys %AdvisoryNotes)
                {
                $AdvisoryNoteCount += scalar(@{$AdvisoryNotes{$component}});
                }

  # Calculate the Total Duration from Phase Data
	$duration = 0;
	foreach $phase (sort {lc $a cmp lc $b} keys %Phases)
		{
		  $duration += $Phases{$phase};
		}
  # Start the Table
  &StartHTMLTable();

  # Print the Totals
  &HTMLTableRow($heading,"Total", $duration, $errorcount, $warningcount, $AdvisoryNoteCount, $remarkcount, $migrationNoteCount);

  # End the Table
  print HTML qq{</table>\n};



  # By Component
  print HTML qq{<h2>By Component</h2>\n};

  # Start the Table
  $title="Component";
  &StartHTMLTable($title);

  # Print the by Component Data
  # If there is a complete set of HiRes data then use that instead of the LowRes data
  if ((defined %HiResComponents) && !$HiResErrorFlag)
  {
    foreach $component (sort {lc $a cmp lc $b} keys %HiResComponents)
	{
      # Calculate the number errors,warnings,advisory notes and remarks
      my $totalerrors;
      my $totalwarnings;
      my $totalremarks;
      my $totalMigrationNotes;
      my $totalAdvisoryNotes;
      if (!defined $remarks{$component})
      {
        # No Remarks were recorded, set total to zero
        $totalremarks = 0;
      } else {
        $totalremarks = scalar(@{$remarks{$component}});
      }
      if (!defined $errors{$component})
      {
        # No errors were recorded, set total to zero
        $totalerrors = 0;
      } else {
        $totalerrors = scalar(@{$errors{$component}});
      }
      if (!defined $warnings{$component})
      {
        # No Warnings were recorded, set total to zero
        $totalwarnings = 0;
      } else {
        $totalwarnings = scalar(@{$warnings{$component}});
      }
      
      if (!defined $migrationNotes{$component})
        {
        # No MigrationNotes were recorded, set total to zero
        $totalMigrationNotes=0;
        }
      else
        {
        $totalMigrationNotes = scalar(@{$migrationNotes{$component}});
        }
      if (!defined $AdvisoryNotes{$component})
        {
        # No AdvisoryNotes were recorded, set total to zero
        $totalAdvisoryNotes=0;
        }
      else
        {
        $totalAdvisoryNotes = scalar(@{$AdvisoryNotes{$component}});
        }


      # Print the Table Row      
      &HTMLTableRow($title,$component, $HiResComponents{$component}, $totalerrors, $totalwarnings, $totalAdvisoryNotes, $totalremarks, $totalMigrationNotes);

	}
  } else {
    foreach $component (sort {lc $a cmp lc $b} keys %Components)
	{
      # Calculate the number errors,warnings,advisory notes and remarks
      my $totalerrors;
      my $totalwarnings;
      my $totalremarks;
      my $totalMigrationNotes;
      my $totalAdvisoryNotes;
      if (!defined $remarks{$component})
      {
        # No Remarks was recorded, set total to zero
        $totalremarks = 0;
      } else {
        $totalremarks = scalar(@{$remarks{$component}});
      }
      if (!defined $errors{$component})
      {
        # No errors were recorded, set total to zero
        $totalerrors = 0;
      } else {
        $totalerrors = scalar(@{$errors{$component}});
      }
      if (!defined $warnings{$component})
      {
        # No Warnings were recorded, set total to zero
        $totalwarnings = 0;
      } else {
        $totalwarnings = scalar(@{$warnings{$component}});
      }
      
      if (!defined $migrationNotes{$component})
        {
        # No MigrationNotes were recorded, set total to zero
        $totalMigrationNotes=0;
        }
      else
        {
        $totalMigrationNotes = scalar(@{$migrationNotes{$component}});
        }

      if (!defined $AdvisoryNotes{$component})
        {
        # No AdvisoryNotes were recorded, set total to zero
          $totalAdvisoryNotes=0;
          }
       else
          {
         $totalAdvisoryNotes = scalar(@{$AdvisoryNotes{$component}});
          }
 


      # Print the Table Row
	  &HTMLTableRow($title,$component, $Components{$component}, $totalerrors, $totalwarnings, $totalAdvisoryNotes, $totalremarks, $totalMigrationNotes);
	}
  }

  # End the Table
  print HTML qq{</table>\n};

  # By Command
  print HTML qq{<h2>By Command</h2>\n};

  # Start the Table
  $title="Command";
  &StartHTMLTable($title);

  # Print the by Command Data
  # If there is a complete set of HiRes data then use that instead of the LowRes data
  if ((defined %HiResCommands) && !$HiResErrorFlag)
  {
    foreach $command (sort {lc $a cmp lc $b} keys %HiResCommands)
	{
      # Calculate the number errors, warnings, advisory notes and remarks
      my $totalerrors;
      my $totalwarnings;
      my $totalremarks;
      my $totalMigrationNotes;
      my $totalAdvisoryNotes;
      if (!defined $CmdRemarks{$command})
      {
        # No Remarks were recorded, set total to zero
        $totalremarks = 0;
      } else {
        $totalremarks = scalar(@{$CmdRemarks{$command}});
      }
      if (!defined $CmdErrors{$command})
      {
        # No errors were recorded, set total to zero
        $totalerrors = 0;
      } else {
        $totalerrors = scalar(@{$CmdErrors{$command}});
      }
      if (!defined $CmdWarnings{$command})
      {
        # No Warnings were recorded, set total to zero
        $totalwarnings = 0;
      } else {
        $totalwarnings = scalar(@{$CmdWarnings{$command}});
      }
      
      if (!defined $CmdMigrationNotes{$command})
        {
        # No MigrationNotes were recorded, set total to zero
        $totalMigrationNotes=0;
        }
      else
        {
        $totalMigrationNotes = scalar(@{$CmdMigrationNotes{$command}});
        }

      if (!defined $CmdAdvisoryNotes{$command})
        {
        # No AdvisoryNotes were recorded, set total to zero
        $totalAdvisoryNotes=0;
        }
      else
        {
        $totalAdvisoryNotes = scalar(@{$CmdAdvisoryNotes{$command}});
        }


      # Print the Table Row
	  &HTMLTableRow($title,$command, $HiResCommands{$command}, $totalerrors, $totalwarnings, $totalAdvisoryNotes, $totalremarks, $totalMigrationNotes);
	}
  } else {
    foreach $command (sort {lc $a cmp lc $b} keys %Commands)
    {
      # Calculate the number errors,warnings,advisory notes and remarks
      my $totalerrors;
      my $totalwarnings;
      my $totalremarks;
      my $totalMigrationNotes;
      my $totalAdvisoryNotes;
      
      if (!defined $CmdRemarks{$command})
      {
        # No Remarks were recorded, set total to zero
        $totalremarks = 0;
      } else {
        $totalremarks = scalar(@{$CmdRemarks{$command}});
      }
      if (!defined $CmdErrors{$command})
      {
        # No errors were recorded, set total to zero
        $totalerrors = 0;
      } else {
        $totalerrors = scalar(@{$CmdErrors{$command}});
      }
      if (!defined $CmdWarnings{$command})
      {
        # No Warnings were recorded, set total to zero
        $totalwarnings = 0;
      } else {
        $totalwarnings = scalar(@{$CmdWarnings{$command}});
      }
      
      if (!defined $CmdMigrationNotes{$command})
        {
        # No MigrationNotes were recorded, set total to zero
        $totalMigrationNotes=0;
        }
      else
        {
        $totalMigrationNotes = scalar(@{$CmdMigrationNotes{$command}});
        }

      if (!defined $CmdAdvisoryNotes{$command})
        {
        # No AdvisoryNotes were recorded, set total to zero
        $totalAdvisoryNotes=0;
        }
      else
        {
        $totalAdvisoryNotes = scalar(@{$CmdAdvisoryNotes{$command}});
        }

      # Print the Table Row
      &HTMLTableRow($title,$command, $Commands{$command}, $totalerrors, $totalwarnings, $totalAdvisoryNotes, $totalremarks, $totalMigrationNotes);
    }
  }

  # End the Table
  print HTML qq{</table>\n};

  # Print Things Missing
  if (scalar %missing)
	{
	my $count = scalar keys %missing;
	print HTML qq{<h2>Things Missing ($count)</h2>\n};
	print HTML "Don't know how to make...\n";
	foreach my $file (sort {lc $a cmp lc $b} keys %missing)
		{
		printf HTML "%d\t%s</BR>\n", $missing{$file}, $file;
		}
	}
  print HTML qq{</BR>\n};

  # Print Things Not Built
  if (scalar %not_built)
	{
	my $count = scalar keys %not_built;
	print HTML qq{<h2>Things Not Built ($count)</h2>\n};
	foreach my $file (sort {lc $a cmp lc $b} keys %not_built)
		{
		print HTML "MISSING: $file ($not_built{$file})</BR>\n";
		}
	}


  # Print the Actual Errors by Component
  if ($iVerbose > 0)
  {
    # Only Print the header if there are some errors
    if (scalar(keys %errors))
    {
      print HTML qq{<h2><a name="errorsByOverall_Total">Error Details by Component</a></h2>\n};
	  foreach $component (sort {lc $a cmp lc $b} keys %errors)
		{
			my ($HTML) = $component;
			$HTML =~ s/\s+$//;
			encode_entities($HTML);
			my $count = scalar @{$errors{$component}};
			print HTML qq{<h3><a name="errorsByComponent_$HTML">$HTML</a> ($count)</h3>\n};
			foreach $line (@{$errors{$component}})
				{
				encode_entities($line);
				print HTML $line.qq{</BR>};
				}
			print HTML qq{</BR>\n};
		}
    }
  }

  # Print the Actual Warning by Component
  if ($iVerbose > 1)
  {
    # Only Print the header if there are some warnings
    if (scalar(keys %warnings))
    {
      print HTML qq{<h2><a name="warningsByOverall_Total">Warning Details by Component</a></h2>\n};
      foreach $component (sort {lc $a cmp lc $b} keys %warnings)
        {
          my ($HTML) = $component;
          $HTML =~ s/\s+$//;
          encode_entities($HTML);
		  my $count = scalar @{$warnings{$component}};
          print HTML qq{<h3><a name="warningsByComponent_$HTML">$HTML</a> ($count)</h3>\n};
          foreach $line (@{$warnings{$component}})
            {
            encode_entities($line);
            print HTML $line.qq{</BR>};
            }
          print HTML qq{</BR>\n};
        }
    }
  }
  
  # Print the Actual Advisory Notes by Component
  if ($iVerbose > 1)
  {
    # Only Print the header if there are some warnings
    if (scalar(keys %AdvisoryNotes))
    {
      print HTML qq{<h2><a name="AdvisoryNotesByOverall_Total">Advisory Note Details by Component</a></h2>\n};
      foreach $component (sort {lc $a cmp lc $b} keys %AdvisoryNotes)
        {
          my ($HTML) = $component;
          $HTML =~ s/\s+$//;
          encode_entities($HTML);
		     my $count = scalar @{$AdvisoryNotes{$component}};
          print HTML qq{<h3><a name="AdvisoryNotesByComponent_$HTML">$HTML</a> ($count)</h3>\n};
          foreach $line (@{$AdvisoryNotes{$component}})
            {
            encode_entities($line);
            print HTML $line.qq{</BR>};
            }
          print HTML qq{</BR>\n};
        }
    }
  }  

  # Print the Actual Remarks by Component
  if ($iVerbose > 1)
  {
    # Only Print the header if there are some errors
    if (scalar(keys %remarks))
    {
      print HTML qq{<h2><a name="remarksByOverall_Total">Remarks Details by Component</a></h2>\n};
	  foreach $component (sort {lc $a cmp lc $b} keys %remarks)
		{
			my ($HTML) = $component;
			$HTML =~ s/\s+$//;
			encode_entities($HTML);
			my $count = scalar @{$remarks{$component}};
			print HTML qq{<h3><a name="remarksByComponent_$HTML">$HTML</a> ($count)</h3>\n};
			foreach $line (@{$remarks{$component}})
				{
				encode_entities($line);
				print HTML $line.qq{</BR>};
				}
			print HTML qq{</BR>\n};
		}
    }
  }

   # Print the Actual Migration Notes by Component
if ($iVerbose > 1)
  {
    # Only Print the header if there are some warnings
    if (scalar(keys %migrationNotes))
    {
      print HTML qq{<h2><a name="migrationNotesByOverall_Total">Migration Note Details by Component</a></h2>\n};
      foreach $component (sort {lc $a cmp lc $b} keys %migrationNotes)
        {
          my ($HTML) = $component;
          $HTML =~ s/\s+$//;
          encode_entities($HTML);
		     my $count = scalar @{$migrationNotes{$component}};
          print HTML qq{<h3><a name="migrationNotesByComponent_$HTML">$HTML</a> ($count)</h3>\n};
          foreach $line (@{$migrationNotes{$component}})
            {
            encode_entities($line);
            print HTML $line.qq{</BR>};
            }
          print HTML qq{</BR>\n};
        }
    }
  }
  
  # Print the Actual Errors by Command
  if ($iVerbose > 0)
  {
    # Only Print the header if there are some errors
    if (scalar(keys %CmdErrors))
    {
      print HTML qq{<h2>Error Details by Command</h2>\n};
	  foreach $command (sort {lc $a cmp lc $b} keys %CmdErrors)
		{
			my ($HTML) = $command;
			$HTML =~ s/\s+$//;
			encode_entities($HTML);
			print HTML qq{<h3><a name="errorsByCommand_$HTML">$HTML</a></h3>\n};
			foreach $line (@{$CmdErrors{$command}})
				{
				encode_entities($line);
				print HTML $line.qq{</BR>};
				}
			print HTML qq{</BR>\n};
		}
    }
  }

  # Print the Actual Warning by Command
  if ($iVerbose > 1)
  {
    # Only Print the header if there are some warnings
    if (scalar(keys %CmdWarnings))
    {
      print HTML qq{<h2>Warning Details by Command</h2>\n};
	  foreach $command (sort {lc $a cmp lc $b} keys %CmdWarnings)
		{
			my ($HTML) = $command;
			$HTML =~ s/\s+$//;
			encode_entities($HTML);
			print HTML qq{<h3><a name="warningsByCommand_$HTML">$HTML</a></h3>\n};
			foreach $line (@{$CmdWarnings{$command}})
				{
				encode_entities($line);
				print HTML $line.qq{</BR>};
				}
			print HTML qq{</BR>\n};
		}
    }
  }
  
  # Print the Actual Advisory Notes by Command
  if ($iVerbose >1)
  {
    # Only Print the header if there are some errors
    if (scalar(keys %CmdAdvisoryNotes))
      {
        print HTML qq{<h2>Advisory Note Details by Command</h2>\n};
            foreach $command (sort {lc $a cmp lc $b} keys %CmdAdvisoryNotes)
                  {
     	                  my ($HTML) = $command;
                          $HTML =~ s/\s+$//;
                          encode_entities($HTML);
                          print HTML qq{<h3><a name="AdvisoryNotesByCommand_$HTML">$HTML</a></h3>\n};
                          foreach $line (@{$CmdAdvisoryNotes{$command}})
				  {
				  encode_entities($line);
		                  print HTML $line.qq{</BR>};
	                          }
                          print HTML qq{</BR>\n}
                  }
      }
    }

  # Print the Actual Remarks by Command
  if ($iVerbose > 1)
  {
    # Only Print the header if there are some errors
    if (scalar(keys %CmdRemarks))
    {
      print HTML qq{<h2>Remarks Details by Command</h2>\n};
	  foreach $command (sort {lc $a cmp lc $b} keys %CmdRemarks)
		{
			my ($HTML) = $command;
			$HTML =~ s/\s+$//;
			encode_entities($HTML);
			print HTML qq{<h3><a name="remarksByCommand_$HTML">$HTML</a></h3>\n};
			foreach $line (@{$CmdRemarks{$command}})
				{
				encode_entities($line);
				print HTML $line.qq{</BR>};
				}
			print HTML qq{</BR>\n};
		}
    }
  }

  # Print the Actual Migration Notes by Command
  if ($iVerbose >1)
    {
    # Only Print the header if there are some errors
    if (scalar(keys %CmdMigrationNotes))
      {
      print HTML qq{<h2>Migration Note Details by Command</h2>\n};
      
      foreach $command (sort {lc $a cmp lc $b} keys %CmdMigrationNotes)
        {
     	  my ($HTML) = $command;
        $HTML =~ s/\s+$//;
        encode_entities($HTML);
        print HTML qq{<h3><a name="migrationNotesByCommand_$HTML">$HTML</a></h3>\n};
        foreach $line (@{$CmdMigrationNotes{$command}})
				  {
				  encode_entities($line);
				  print HTML $line.qq{</BR>};
				  }
        print HTML qq{</BR>\n}
        }
      }
    }
  
}


# StartHTMLTable
#
# Inputs
# $iC1Title (Column 1 Title)
#
# Outputs
#
# Description
# This function prints the start of the HTML Table
sub StartHTMLTable
{
  my ($iC1Title) = @_;

  if ($iC1Title eq '')
  {
    $iC1Title = "&nbsp;";
  } else {
    encode_entities($iC1Title);
  }

  # Start the Table
  print HTML qq{<table border="1" cellpadding="0" cellspacing="0" width="100%">\n};

  # Print the Header Row
  print HTML qq{\t<th width="50%">$iC1Title</th>\n};
  print HTML qq{\t<th width="15%">Time</th>\n};
  print HTML qq{\t<th width="8%">Errors</th>\n};
  print HTML qq{\t<th width="8%">Warnings</th>\n};
  print HTML qq{\t<th width="8%">Advisory Notes</th>\n};
  print HTML qq{\t<th width="8%">Remarks</th>\n};
  print HTML qq{\t<th width="8%">Migration Notes</th>\n};
  print HTML qq{</tr>\n};
}

# HTMLTableCell
#
# Inputs
# $iType	(errors,warnings,remarks,migration_notes)
# $iCount	(number of errors)
# $iLink	(empty string or linktype)
#
# Outputs
# Returns HTML table data element with appropriate link & background color
#
# Description
# Constructs HTML table element - used by HTMLTableRow to handle the formatting
# of the data cells, complete with colouring and links where appropriate.
sub HTMLTableCell
{
   my ($iType,$iCount,$iLink)= @_;
   my $td = qq{td width="8%" align="center"};	# implied by the TH elements already?
   if ($iCount != 0)
      {
	  $td = "$td BGCOLOR=$htmlColours{$iType}";
      }
   if ($iLink eq "" || $iCount == 0)
      {
      return qq{<$td>$iCount</td>};
      }
   $iLink = $iType."By".$iLink;
   return qq{<$td><a href="#$iLink">$iCount</a></td>};
}

# HTMLTableRow
#
# Inputs
# $iTitle (Need to differentiate between command and component to provide correct anchors)
# $iC1Data(Column 1 Data)
# $iC2Data(Column 2 Data) (Time in seconds)
# $iC3Data(Column 3 Data) (Number of errors)
# $iC4Data(Column 4 Data) (Number of warnings)
# $iC5Data(Column 5 Data) (Number of Advisory notes )
# $iC6Data(Column 6 Data) (Number of remarks )
# $iC7Data(Column 7 Data) (Number of migration notes )
#
# Outputs
#
# Description
# This function prints a line of the HTML Table
sub HTMLTableRow
{
  my ($iTitle,$iC1Data, $iC2Data, $iC3Data, $iC4Data,$iC5Data, $iC6Data, $iC7Data) = @_;

  #print "$iC2Data\n";

  # Convert the seconds in hh:mm:ss format
  $iC2Data = &ConvertSeconds($iC2Data);

  # HTML encode the text
  encode_entities($iC1Data);
  encode_entities($iC2Data);
  encode_entities($iC3Data);
  encode_entities($iC4Data);
  encode_entities($iC5Data);
  encode_entities($iC6Data);
  encode_entities($iC7Data);

  my $linkname = "$iTitle"."_"."$iC1Data";
  
  # Print the Row, including summary in a script comment
  print HTML qq{<tr>\n};
  print HTML qq{<!--\t$linkname\t$iC2Data\t$iC3Data\t$iC4Data\t$iC5Data\t$iC6Data\t$iC7Data\t-->\n};
  print HTML qq{\t<td width="50%">$iC1Data</td>\n};
  print HTML qq{\t<td width="15%" align="center">$iC2Data</td>\n};

  print HTML "\t",&HTMLTableCell("errors",  $iC3Data,$linkname),"\n";
  print HTML "\t",&HTMLTableCell("warnings",$iC4Data,$linkname),"\n";
  print HTML "\t",&HTMLTableCell("AdvisoryNotes", $iC5Data,$linkname),"\n";
  print HTML "\t",&HTMLTableCell("remarks", $iC6Data,$linkname),"\n";
  print HTML "\t",&HTMLTableCell("migrationNotes", $iC7Data,$linkname),"\n";

  print HTML qq{</tr>\n};
}

# ConvertSeconds
#
# Inputs
# $iSeconds
#
# Outputs
# $iString (seconds in hh:mm:ss)
#
# Description
# This function processes the commandline
sub ConvertSeconds
{
  my ($iSeconds) = @_;
  
  my ($iString);
  my ($ih) = int($iSeconds/3600);
  my ($im) = int(($iSeconds-($ih*3600))/60);
  my ($is) = $iSeconds-($ih*3600)-($im*60);
  # Print the correct format if the data is HiRes (has a decimal point in the string)
  if ($is =~ /\d+\.\d+/)
  {
    $iString = sprintf "%d:%02d:%06.3f", $ih, $im, $is;
  } else {
    $iString = sprintf "%d:%02d:%02d", $ih, $im, $is;
  }
  return $iString;
}

# ProcessCommandLine
#
# Inputs
#
# Outputs
# $iOutput (Output filename)
# $iVerbose (Verbose Level)
# $iLogs (Log files to process)
#
# Description
# This function processes the commandline

sub ProcessCommandLine {
  my ($iHelp, @iLogs, $iOutput, $iTitle, $iVerbose, $iDiff, $iHistory, $iClass, $iHistoryHelp);
  GetOptions('h' => \$iHelp, 'l=s' =>\@iLogs, 'o=s' => \$iOutput, 't=s' => \$iTitle, 'v+' => \$iVerbose, 'd=s' =>\$iDiff, 'c=s' =>\$iHistory, 'm=s' =>\$iClass, 'hh' => \$iHistoryHelp);

  if ($iHistoryHelp)
  {
    &HistoryHelp();
  }

  if (($iHelp) || (!defined @iLogs) || (!defined $iOutput))
  {
    Usage();
  } elsif (-e $iOutput) {
    die "$iOutput already exists";
  } elsif (-e $iDiff) {
    die "$iDiff already exists";
  } elsif (-e $iWhat) {
    die "$iWhat already exists";
  }
  foreach my $iLog (@iLogs)
  {
    warn "$iLog does not exist" if (! -e $iLog);
  }
  
  # Check the history options
  if (defined $iHistory)
  {
    if (! -e $iHistory)
    {
	    warn "$iHistory does not exist";
	    undef $iHistory;
    } 
    
   	elsif (!defined $iClass)
   	{
	    warn "No machine name to class csv file specified with -m option";
	    undef $iHistory;
   	}
  }

  # Set default title
  if ($iTitle eq '')
  {
    $iTitle = "Log File Summary";
  }

  return($iOutput, $iTitle, $iVerbose, $iDiff, $iWhat, $iHistory, $iClass, @iLogs);
}

# Usage
#
# Output Usage Information.
#

sub Usage {
  print <<USAGE_EOF;

    Usage: Scanlog.pl [options]

    options:

    -h  help
    -l  Log file to scan [Multiple allowed]
    -o  Output file
    -v  Increments Verbose level [Maximum Level = 2]
    -t  Title to add to the Summary
    -d  Filename for Logfile with Time Information removed [Optional]
    
    History options [Optional]
    -hh More help on History options and file formats
    -c  History csv to add summary to
    -m  Machine name to class csv data file [required if using -c]

USAGE_EOF
	exit 1;
}

# HistoryHelp
#
# Output History Help Information.
#
sub HistoryHelp{
  print <<HISTORY_EOF;

  History Description:
  The History function collates the timing summary information of the
  components from multiple builds. As the timing data varies between
  machines of different specifications, htmlscanlog tries to identify
  the machines hostname from the logs so it can identify which class
  of machine it belongs to (the machine class is used to group multiple
  machines with identical specifications). If it is not able to identify
  a machine name (and class) it uses the first entry in the Machine name
  to class csv.
  
  History csv file format:
  The csv format is for easy loading into spreadsheet programs for
  generating charts. The first line contains the column headings, the
  first column headings is the machine class, machine name, Title,
  the last time entry in all the logs processed, then the
  component names. Removed components will cause empty entries, new
  components will be added at the end.
  
  Machine name to class csv data file format:
  The csv format contains two columns with no headings, first column is
  the class name, the second is the machine name.
    
HISTORY_EOF
	exit 1;
}

# PrintHTMLHeader
#
# Inputs
# $iTitle (Title for Log file)
#
# Outputs
#
# Description
# This function print the HTML Header

sub PrintHTMLHeader {
  my ($iTitle) = @_;

   print HTML <<HTML_EOF;
<HTML>
<HEAD>
<TITLE>$iTitle</TITLE>
</HEAD>
<BODY BGCOLOR="FFFFFF">
<FONT FACE="Courier New">
HTML_EOF
}

# PrintHTMLFooter
#
# Inputs
#
# Outputs
#
# Description
# This function print the HTML Footer

sub PrintHTMLFooter {
   print HTML <<HTML_EOF;
</FONT>
</BODY>
</HTML>
HTML_EOF
}

#  DiffDateTime
#
# Inputs
# $StartDateTime (Start Date/Time String)
# $EndDateTime (End Date/Time String)
#
# Outputs
# $Duration (Difference in seconds bertween the two dates/Times)
#
# Description
# This function calculate the difference between to dates and times

sub DiffDateTime {
  my ($String1, $String2) = @_;
  
  my ($err, $delta);

  $delta=&DateCalc($String1,$String2,\$err);
  if ($err)
  {
    print "WARNING: DiffDateTime encountered and error\n";
    return "0";
  } else { 
    # Convert into seconds to aid additions
    return &Delta_Format($delta,'0',"%sh");
  }
}

sub do_remarks()
{
	my ($iLog) =@_;
	# Store remarks by Command
	if (!defined $CmdRemarks{$command})
		{
		$CmdRemarks{$command} = ();
		}
	push @{$CmdRemarks{$command}}, "$iLog:"."$.".">$line";

	# Store remarks by Component
	if (!defined $remarks{$component})
		{
		$remarks{$component} = ();
		}
	push @{$remarks{$component}}, "$iLog:"."$.".">$line";
}

sub do_warning()
{
	my ($iLog) =@_;
	# Store warning by Command
	if (!defined $CmdWarnings{$command})
		{
		$CmdWarnings{$command} = ();
		}
	push @{$CmdWarnings{$command}}, "$iLog:"."$.".">$line";

	# Store warning by Component
	if (!defined $warnings{$component})
		{
		$warnings{$component} = ();
		}
	push @{$warnings{$component}}, "$iLog:"."$.".">$line";
}


sub do_migrationNotes()
  {
  my ($iLog)= @_;
  # Store Migration Notes by command
  if (!defined $CmdMigrationNotes{$command})
    {
    $CmdMigrationNotes{$command} = ();
    }
  push @{$CmdMigrationNotes{$command}}, "$iLog:"."$.".">$line";
  
  # Store Migration Notes by Componen
  if (!defined $migrationNotes{$component})
    {
    $migrationNotes{$component} = ();
    }
  push @{$migrationNotes{$component}}, "$iLog:"."$.".">$line";
  
  }

sub do_AdvisoryNotes()
  {
  my ($iLog)= @_;
  # Store Advisory Notes by command
  if (!defined $CmdAdvisoryNotes{$command})
    {
    $CmdAdvisoryNotes{$command} = ();
    }
  push @{$CmdAdvisoryNotes{$command}}, "$iLog:"."$.".">$line";
  
  # Store Advisory Notes by Component
  if (!defined $AdvisoryNotes{$component})
    {
    $AdvisoryNotes{$component} = ();
    }
  push @{$AdvisoryNotes{$component}}, "$iLog:"."$.".">$line";
  
}

sub do_error()
{
  my ($iLog) =@_;
	# Store Errors by Command
	if (!defined $CmdErrors{$command})
		{
		$CmdErrors{$command} = ();
		}
	push @{$CmdErrors{$command}}, "$iLog:"."$.".">$line";

	# Store Errors by Component
	if (!defined $errors{$component})
		{
		$errors{$component} = ();
		}
	push @{$errors{$component}}, "$iLog:"."$.".">$line";
}

# Read a number of lines in the log ignoreing the content
sub do_slurp()
{
  my ($num_lines) =@_;
  for (my $i = 0; $i < $num_lines; $i++)
  {
    <LOG>;
  }
}
