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
use File::stat;
use FindBin;		# for FindBin::Bin

# Add the directory contain this perl script into the path to find modules
use lib $FindBin::Bin;
use sbsv2scanlog;

# For Date calculations
use lib "$FindBin::Bin/../lib"; # For running in source
use lib "$FindBin::Bin/build/lib"; # For running in epoc32\tools

use XML::Parser;

# Variables
my $line;
my $iSlurp;
my %Components;
my %Commands;
my $component;
my $command;
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
my $currentfiletime;
my $warningcount;
my $errorcount;
my $remarkcount;
my $migrationNoteCount;
my $AdvisoryNoteCount;
my ($iStatus, $iName);
my $warningmigrated;
my %htmlColours=(
"errors" =>"#ff0000",
"warnings" =>"#fff000",
"remarks" =>"#ffccff",
"migrationNotes" =>"#ffcc99",
"AdvisoryNotes" => "#ffa500"
);
my $MigrateNextExitCode = 0;
my $inRecipe = 0;
my $RetryInProgress = 0;

# Package variables - these can also be accessed the from package "SubHandlers"
use vars qw($component $command %Components %Commands);
our $iLog;

my $Dsec;

# Main section

my ($iOutput, $iTitle, $iVerbose, @iLogs) =&ProcessCommandLine();

# Open Output file
  open (HTML, ">$iOutput") or die "Couldn't open $iOutput for writing: $!\n";


# Parse each log File
foreach $iLog (@iLogs) # parses through all logs 
{
    # Check the log file exists
    if (-e $iLog)
    {
        # Process the logs
        &ProcessLog();
    } else {
      print "WARNING: $iLog does not exist\n";
    }


}

&PrintResults($iTitle);

# Print HTML Footer
&PrintHTMLFooter();


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
  #Clear current file time as starting processing a new log
  $currentfiletime = 0;
  
  print "Processing: $iLog\n";

  my $iParser = XML::Parser->new(Style => 'Subs', Pkg => 'MySubs' , ErrorContext => 2,
                                 Handlers => {Char => \&char_handler});

  # Supply the XML Parser the data source
  eval {
    $iParser->parsefile($iLog);
  };
 
  #Set current component and command to special values to record log processing errors/warnings/etc
  $component = 'sbsv2scanlog';    
  $command = 'sbsv2scanlog';
 
  #Check for parse errors
  if ($@)
  {
    #Generate error in log as the file time stamps are duff
    &do_error($iLog, "No_linenumer", "XML Parse error:$@");
    $Components{$component} = '0';
    $Commands{$command} ='0';
  }
  
  # Calculate the Total Duration
  # $currentfiletime is set from the info tags at the end of the log.
  $duration += $currentfiletime;  

  #Clear current component and command
  $component = '';    
  $command = ''; 
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
    foreach $component (sort {lc $a cmp lc $b} keys %Components)
    {
      # Calculate the number errors and warnings
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
      &HTMLTableRow($title,$component, $Components{$component}, $totalerrors, $totalwarnings, $totalAdvisoryNotes,$totalremarks, $totalMigrationNotes);

    }

  # End the Table
  print HTML qq{</table>\n};

  # By Command
  print HTML qq{<h2>By Command</h2>\n};

  # Start the Table
  $title="Command";
  &StartHTMLTable($title);

  # Print the by Command Data
    foreach $command (sort {lc $a cmp lc $b} keys %Commands)
	{
      # Calculate the number errors, warnings and remarks
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
  print HTML qq{<tr>\n};
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
  my ($iHelp, @iLogs, $iOutput, $iTitle, $iVerbose);
  GetOptions('h' => \$iHelp, 'l=s' =>\@iLogs, 'o=s' => \$iOutput, 't=s' => \$iTitle, 'v+' => \$iVerbose);

  if (($iHelp) || (!defined @iLogs) || (!defined $iOutput))
  {
    Usage();
  } elsif (-e $iOutput) {
    die "$iOutput already exists";
  }
  
  foreach my $iLog (@iLogs)
  {
    warn "$iLog does not exist" if (! -e $iLog);
  }

  # Set default title
  if ($iTitle eq '')
  {
    $iTitle = "Log File Summary";
  }

  return($iOutput, $iTitle, $iVerbose, @iLogs);
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

USAGE_EOF
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

sub do_remarks()
{
	my ($iLog, $iLineNumber, $line)= @_;
	# Store remarks by Command
	if (!defined $CmdRemarks{$command})
		{
		$CmdRemarks{$command} = ();
		}
	push @{$CmdRemarks{$command}}, "$iLog:$iLineNumber>$line";

	# Store remarks by Component
	if (!defined $remarks{$component})
		{
		$remarks{$component} = ();
		}
	push @{$remarks{$component}}, "$iLog:$iLineNumber>$line";
}

sub do_warning()
{
	my ($iLog, $iLineNumber, $line)= @_;
	# Store warning by Command
	if (!defined $CmdWarnings{$command})
		{
		$CmdWarnings{$command} = ();
		}
	push @{$CmdWarnings{$command}}, "$iLog:$iLineNumber>$line";

	# Store warning by Component
	if (!defined $warnings{$component})
		{
		$warnings{$component} = ();
		}
	push @{$warnings{$component}}, "$iLog:$iLineNumber>$line";
}


sub do_migrationNotes()
  {
  my ($iLog, $iLineNumber, $line)= @_;
  # Store Migration Notes by command
  if (!defined $CmdMigrationNotes{$command})
    {
    $CmdMigrationNotes{$command} = ();
    }
  push @{$CmdMigrationNotes{$command}}, "$iLog:$iLineNumber>$line";
  
  # Store Migration Notes by Component
  if (!defined $migrationNotes{$component})
    {
    $migrationNotes{$component} = ();
    }
  push @{$migrationNotes{$component}}, "$iLog:$iLineNumber>$line";
  
  }

sub do_AdvisoryNotes()
  {
  my ($iLog, $iLineNumber, $line)= @_;
  # Store Advisory Notes by command
  if (!defined $CmdAdvisoryNotes{$command})
    {
    $CmdAdvisoryNotes{$command} = ();
    }
  push @{$CmdAdvisoryNotes{$command}}, "$iLog:$iLineNumber>$line";
  
  # Store Advisory Notes by Component
  if (!defined $AdvisoryNotes{$component})
    {
    $AdvisoryNotes{$component} = ();
    }
  push @{$AdvisoryNotes{$component}}, "$iLog:$iLineNumber>$line";
  
}


sub do_error()
{
  my ($iLog, $iLineNumber, $line)= @_;
	# Store Errors by Command
	if (!defined $CmdErrors{$command})
		{
		$CmdErrors{$command} = ();
		}
	push @{$CmdErrors{$command}}, "$iLog:$iLineNumber>$line";

	# Store Errors by Component
	if (!defined $errors{$component})
		{
		$errors{$component} = ();
		}
	push @{$errors{$component}}, "$iLog:$iLineNumber>$line";
}

# Read a number of lines in the log ignoreing the content
sub do_slurp()
{
  my ($num_lines) =@_;
  for (my $i = 0; $i < $num_lines; $i++)
  {
    ;
  }
}

sub char_handler
{
  my ($iExpat, $data) = @_;
  my ($iStatus);
  
  # Now Buffer it up for context data
  $iExpat->{cdata_buffer} .= $data;
  
  #Delay parsing until end of line is found or close xml tag or end of recipe
  return if ($inRecipe);
  if (!($data =~ /\n$/))
  {
    #Put in the line buffer until the rest of the line comes in or an element end causes a parseline call
    $iExpat->{line_buffer} .= $data;
    return;
  } else {
    #line ends in a \n
    #Add the $data to buffer(normally empty) and parse
    &parseline($iExpat,$iExpat->{line_buffer}.$data);
    #Empty the line buffer
    $iExpat->{line_buffer} =''; 
  }
}

sub parseline
{
  my ($iExpat, $data,$iLineNumber) = @_;
  if (!($iLineNumber =~ /\d+/))
  {
    #If no linenumber is passed the set to the current line in the parse
    $iLineNumber = $iExpat->current_line;
  }
  my $CheckForComponentExitCodesToMigrate = 0;
  
  #Set some defaults if $component and $command are empty
  if ($component eq '')
  {
    $component = "anonymous component";
    $Components{$component} = '0';

  }
  if ($command eq '')
  {
    $command = "anonymous command";
    $Commands{$command} ='0';
  }

    # Lines to Ignore
    $iStatus =&sbsv2scanlog::CheckForIgnore($data);
    if($iStatus)
    {
      return;
    }

    # AdvisoryNotes
    ($iStatus) =&sbsv2scanlog::CheckForAdvisoryNotes($data);
    if ($iStatus)
    {
      if ($RetryInProgress)
      {
        #A retry is in progress so downgrade to a remark
        &do_remarks($iLog, $iLineNumber, $data);
        return;
      } else {
      &do_AdvisoryNotes($iLog, $iLineNumber, $data);
      return;
      }
    }


    #CheckForComponentExitCodesToMigrate
    $CheckForComponentExitCodesToMigrate = &sbsv2scanlog::CheckForComponentExitCodesToMigrate($data,$component);
    if ($CheckForComponentExitCodesToMigrate )
    {
      $MigrateNextExitCode = 1;
    }

    # Migration Notes
    $iStatus = &sbsv2scanlog::CheckForMigrationNotes($data,$component);
    if ($iStatus)
    {
      if ($RetryInProgress)
      {
        #A retry is in progress so downgrade to a remark
        &do_remarks($iLog, $iLineNumber, $data);
        return;
      } else {
        &do_migrationNotes($iLog, $iLineNumber, $data);
        #Setup global $warningmigrated flag so warning_ function can ignore the warning element that this migration note was in
        $warningmigrated = 1;
        return;
      }
    }

    # Remarks
    ($iStatus) =&sbsv2scanlog::CheckForRemarks($data);
    if ($iStatus)
    {
      &do_remarks($iLog, $iLineNumber, $data);
      return;
    }
    
    # Errors
    ($iStatus) =&sbsv2scanlog::CheckForErrors($data);
    if ($iStatus)
    {
      if ($RetryInProgress)
      {
        #A retry is in progress so downgrade to a remark
        &do_remarks($iLog, $iLineNumber, $data);
        return;
      } else {
        &do_error($iLog, $iLineNumber, $data);
        return;
      }
    }

    
    # Warnings
    ($iStatus) =&sbsv2scanlog::CheckForWarnings($data);
    if ($iStatus)
    {
      if ($RetryInProgress)
      {
        #A retry is in progress so downgrade to a remark
        &do_remarks($iLog, $iLineNumber, $data);
        return;
      } else {
        &do_warning($iLog, $iLineNumber, $data);
        return;
      }
    }
    return;
}

{
  package MySubs;
  # recipe
  #
  # Inputs
  #
  # Outputs
  #
  # Description
  # This function handles the recipe tag in the XML
  sub recipe
  {
    my $iExpat = shift; my $iElement = shift;
    
    #empty cdata buffer
    $iExpat->{cdata_buffer} = '';
    
    #Set global flag to change char data handling to the end of the recipe
    #So that errors/warnings/migration notes can be down grade to remarks
    #if a retry is signalled
    $inRecipe = 1;
  
    my (%iAttr);
  
    # Read the attributes
    while (@_) {
      my $iAtt = shift;
      my $iVal = shift;
      $iAttr{$iAtt} = $iVal;
    }
    
    #print "recipe name =".$iAttr{'name'}."\n";
    if ($iAttr{'component'} ne '')
    {
      $component = $iAttr{'component'};
    } else {
      #Try using the bld.inf as unique component identifier
      $component = $iAttr{'bldinf'};
    }
    
    $command = $iAttr{'name'}." ".$iAttr{'platform'};
  }
  
  sub recipe_
  {
    my $iExpat = shift;
    
    #Handle all recipe text that was inside this element
    
    #Split the multiline cdata_buffer in to single lines
    my @lines = split /\n/,$iExpat->{cdata_buffer};
    for (my $buffnum = 0 ; $buffnum < scalar (@lines); $buffnum++)
    {
      #Parse each line
      
      #Calculate the actual line number subtracking status and time element lines (2) and position in array from end
      my $linenum = ($iExpat->current_line) - 2 - (scalar (@lines) - $buffnum);
      &main::parseline($iExpat, $lines[$buffnum],$linenum);
    }

    #Clear $inRecipe flag
    $inRecipe = 0;
    
    #Clear $RetryInProgress flag as a retry cannot out live a recipe
    $RetryInProgress = 0;
    
    #Clear all data set by recipe start
    $component = '';
    $command = '';
    
    #empty cdata buffer
    $iExpat->{cdata_buffer} = '';
  }
  
  sub time
  {
    my $iExpat = shift; my $iElement = shift;
  
    my (%iAttr);
  
    # Read the attributes
    while (@_) {
      my $iAtt = shift;
      my $iVal = shift;
      $iAttr{$iAtt} = $iVal;
    }
    
    #Elapsed time and Total up for Command
    $Commands{$command} += $iAttr{'elapsed'};
    #Elapsed time and Total up for Component
    $Components{$component} += $iAttr{'elapsed'};
  }
  
  sub time_
  {
    #Do nothing
  }
  
  sub info
  {
    my $iExpat = shift; my $iElement = shift;
    #empty cdata buffer
    $iExpat->{cdata_buffer} = '';
    
    $component = 'SBS: Info';    
    $command = 'SBS: Info';
    $Components{$component} = '0';
    $Commands{$command} ='0';
  }
  
  sub info_
  {
    my $iExpat = shift; my $iElement = shift;
    
    #Handle any unhandle text that was inside this element
    if ($iExpat->{line_buffer} =~ /.+/)
    {
      &main::parseline($iExpat, $iExpat->{line_buffer});
      $iExpat->{line_buffer} =''; 
    }
    
    #Clear all data set by info start
    $component = '';
    $command = '';
	if ($iExpat->{cdata_buffer} =~ /Run time (.*?) seconds/)
    {
      ($currentfiletime) =$1;
    }
    
    #empty cdata buffer
    $iExpat->{cdata_buffer} = '';
  }
  
  sub warning
  {
    my $iExpat = shift; my $iElement = shift;
    #empty cdata buffer
    $iExpat->{cdata_buffer} = '';
    #reset $warningmigrated flag
    $warningmigrated = 0;
    
    $component = 'SBS: Warning';    
    $command = 'SBS: Warning';
    $Components{$component} = '0';
    $Commands{$command} ='0';
  }
  
  sub warning_
  {
    my $iExpat = shift; my $iElement = shift;
    
    #Handle any unhandle text that was inside this element
    if ($iExpat->{line_buffer} =~ /.+/)
    {
      &main::parseline($iExpat, $iExpat->{line_buffer});
      $iExpat->{line_buffer} =''; 
    }
    
    my ($iLineNumber) = $iExpat->current_line;
  
    if ($warningmigrated != 1)
    {
      #Record error in its own right for the error xml element
      &main::do_warning($iLog, $iLineNumber, $iExpat->{cdata_buffer});
    }
    
    #Clear all data set by info start
    $component = '';
    $command = '';
    
    #empty cdata buffer
    $iExpat->{cdata_buffer} = '';
  }
  
  sub error
  {
    my $iExpat = shift; my $iElement = shift;
    #empty cdata buffer
    $iExpat->{cdata_buffer} = '';
    
    #Set generic component and command names so that these don't get allocated to a empty component
    $component = 'SBS: Error';    
    $command = 'SBS: Error';
    $Components{$component} = '0';
    $Commands{$command} ='0';
  }
  
  sub error_
  {
    my $iExpat = shift; my $iElement = shift;
    
    #Handle any unhandle text that was inside this element
    if ($iExpat->{line_buffer} =~ /.+/)
    {
      &main::parseline($iExpat, $iExpat->{line_buffer});
      $iExpat->{line_buffer} =''; 
    }

    my ($iLineNumber) = $iExpat->current_line;
  
    #Record error in its own right for the error xml element
    &main::do_error($iLog, $iLineNumber, $iExpat->{cdata_buffer});
    
    #Clear all data set by info start
    $component = '';
    $command = '';
    
    #empty cdata buffer
    $iExpat->{cdata_buffer} = '';
  }
  
  sub status
  {
    my $iExpat = shift; my $iElement = shift;

    my (%iAttr);
  
    # Read the attributes
    while (@_) {
      my $iAtt = shift;
      my $iVal = shift;
      $iAttr{$iAtt} = $iVal;
    }

    my ($iLineNumber) = $iExpat->current_line;

    if ($iAttr{'exit'} eq 'retry')
    {
      $RetryInProgress = 1;
      #Record retry as a remark
      &main::do_remarks($iLog, $iLineNumber, "$component retried on $command with ".$iAttr{'code'});
      return;
    } elsif ($iAttr{'exit'} ne 'ok') {
      #Record as migration note for non ok exit because a previous line has triggered this flag
      if ($MigrateNextExitCode)
      {
        &main::do_migrationNotes($iLog, $iLineNumber, "$component failed on $command with ".$iAttr{'code'});
      } else {
        #Record error in its own right for the non 'ok' exit status
        &main::do_error($iLog, $iLineNumber, "$component failed on $command with ".$iAttr{'code'});
      }
    }
    
    #Resest the Migrate exit code flag because a previous line has triggered this flag
    $MigrateNextExitCode =0;
  }
  
  sub status_
  {
    my $iExpat = shift; my $iElement = shift;
    # Nothing to do
  }
  
  sub debug
  {
    my $iExpat = shift; my $iElement = shift;
    # Nothing to do
  }
  
    sub debug_
  {
    my $iExpat = shift; my $iElement = shift;
    # Nothing to do
  }
}
