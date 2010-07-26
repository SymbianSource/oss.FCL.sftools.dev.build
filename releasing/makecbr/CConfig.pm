#!\bin\perl -w
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
# CConfig
# 

package CConfig;

use strict;
use IO::File;
use COutputHandler;

# Added for scanlog compatibility
use Time::localtime;

# CConfig New(scalar aFilename) : constructor
sub New($)
	{
	my $proto = shift;
	my ($aFilename) = @_;

	my $class = ref($proto) || $proto;

	my $self = { RELTOOLS_REQUIRED => "",
                     outputHandler => COutputHandler->new()};
	bless($self, $class);
  # undef the logfile here so that the folowing warning goes to stdout
  $self->{iLOGFILE} = undef;
	# Load in options
	if (defined($aFilename))
		{
		if (!$self->Reload($aFilename))
			{
			$self->Warning("Option file could not be loaded.\n");
			}
		}
	
  # Added support for scanlog and Die() control.
  $self->{iPhaseErrorCount} = 0;
	$self->{iPhase} = undef;
        
	return $self;
	}

# boolean Set(scalar aOptionName, scalar aValue)
sub Set($$)
	{
	my $self = shift;
	my ($aOptionName, $aValue) = @_;

	if (!defined($aOptionName))
		{
		$self->Warning("Cannot set undefined option");
		
		return 0;
		}
		
	if (!defined($aValue))
		{
		$self->Warning("Cannot set option '$aOptionName' to undefined value.");
		return 0;
		}
	
	if ((ref($aValue) ne "") && (ref($aValue) ne "ARRAY"))
		{
		$self->Warning("Value of '$aOptionName' must be either a string or list.");
		return 0;
		}

	$self->{iOptions}->{lc($aOptionName)} = [$aOptionName, $aValue];
	return 1;
	}

# scalar Get(scalar aOptionName)
sub Get($)
	{
	my $self = shift;
	my ($aOptionName) = @_;

	if (defined($self->{iOptions}->{lc($aOptionName)}))
		{
		return ($self->{iOptions}->{lc($aOptionName)})->[1];
		}
	else
		{
		return undef;
		}
	}

# boolean Reload(scalar aFilename)
sub Reload($)
	{
	my $self = shift;
	my ($aFilename) = @_;
	my $okay = 1;

	$self->{iOptions}={}; # Blank existing options

	if (!open(FILE, $aFilename))
		{
		$self->Warning("Option file '$aFilename' could not be opened.");
		$okay = 0;
		}
	else
		{
		foreach my $line (<FILE>)
			{
			chomp ($line);

			# Split on colon
			my $parms = $line;
			$parms =~ s/([^\\]):/$1\x08/g; # Turn unescaped colons into 0x08 chars
			$parms =~ s/\\:/:/g; # Unescape escaped colons
			my @parms = split(/\x08/,$parms); # Split on 0x08

			if (scalar(@parms) != 0)
				{
				if (scalar(@parms) == 2)
					{
					my $key = $parms[0];
					$key =~ s/^\s+//; # Remove preceding spaces
					$key =~ s/([^\\])\s$/$1/g; # Remove unescaped trailing spaces
					$key =~ s/\\(\s)/$1/g; # Unescape space characters

					my $value = $parms[1];
					if ($value =~ /\s*\[.*\]\s*$/)
						{
						# Value is a [list]

						# Remove square brackets
						$value =~ s/^\s*\[//;
						$value =~ s/\]\s*$//;

						# Split on comma
						$value =~ s/([^\\]),/$1\x08/g; # Turn unescaped commas into 0x08 chars
						$value =~ s/\\,/,/g; # Unescape escaped commas
						my @values = split(/\x08/,$value); # Split on 0x08

						map(s/^\s+//, @values); # Remove preceding spaces
						map(s/([^\\])\s$/$1/g, @values); # Remove unescaped trailing spaces
						map(s/\\(\s)/$1/g, @values); # Unescape space characters

						$value = [@values];
						}
					else
						{
						# Value is a scalar

						$value =~ s/^\s+//; # Remove preceding spaces
						$value =~ s/([^\\])\s$/$1/g; # Remove unescaped trailing spaces
						$value =~ s/\\(\s)/$1/g; # Unescape space characters
						}

					if (!($self->Set($key, $value)))
						{
						$okay = 0;
						}
					}
				else
					{
					$self->Warning("In file '$aFilename', ".scalar(@parms)." parameters found on a line.\nOnly two parameters, colon separated, are supported.\nLine: '$line'");
					$okay = 0;
					}
				}
			}
		close(FILE);
		}

	return ($okay);
	}

# boolean Save(scalar aFilename)
sub Save($)
	{
	my $self = shift;
	my ($aFilename) = @_;
	my $okay = 1;

	if (!open(FILE, ">$aFilename"))
		{
		$self->Warning("Could not open option file '$aFilename' to save to.");
		$okay = 0;
		}
	else
		{
		foreach my $pair (values(%{$self->{iOptions}}))
			{
			my $key = $pair->[0];
			my $value = $pair->[1];
			
			if (!defined($value))
				{
				$self->Error("Cannot write undefined value for key '$key' when saving options.");
				$okay = 0;
				}
			else
				{

				if (ref($value))
					{
					if (ref($value) ne "ARRAY")
						{
						$self->Error("Cannot write ".ref($value)." for key '$key' when saving options.");
						$okay = 0;
						}
					else
						{
						# It's a list: [value,value,value] and escape any commas or opening spaces
						my @values = @{$value};
						map(s/^(\s)/\\$1/,@values);
						map(s/,/\\,/g,@values);
						$value = "[".join(",",@values)."]";
						}
					}
				else
					{
					# It's a scalar string
					# Escape opening space
					$key =~ s/^(\s)/\\$1/;
					# Escape square brackets;
					}
					
				# Escape colons
				$key =~ s/:/\\:/g;
				$value =~ s/:/\\:/g;
				
				print FILE $key.":".$value."\n";
				}
			}
		close (FILE)
		}
	return $okay;
	}

# boolean SetLog(scalar aFilename)
sub SetLog($)
	{
	my $self = shift;
	my ($aLogFile) = @_;

	if (defined($self->{iLOGFILE}))
		{
		$self->{iLOGFILE}->close();
    # This forces any subsequent error message to go to stdout
    $self->{iLOGFILE} = undef;
		}
	
	if (-e $aLogFile)
		{
		if (-e $aLogFile."~")
			{
			if (!unlink $aLogFile."~")
				{
				$self->Error("Couldn't delete backup log file\n");
				return 0;
				}
			}

		if (system("copy $aLogFile $aLogFile~ > nul 2>&1"))
			{
			$self->Error("Couldn't back-up existing log file\n");
			return 0;
			}
		}
		
	$self->{iLOGFILE}=new IO::File("> $aLogFile");

	if (defined($self->{iLOGFILE}))
		{
		return 1;
		}
	else
		{
		$self->Error("Couldn't open logfile $aLogFile\n");
		return 0;
		}
	}

# void Print(scalar aLogLine)
sub Print($)
	{
	my $self = shift;
	my ($aLogLine) = @_;

	my $logfile = $self->{iLOGFILE};

	if ($aLogLine !~ /\n$/)
		{
		$aLogLine = $aLogLine."\n";
		}
                
        $aLogLine = $self->{outputHandler}->CheckOutput($aLogLine);      

	if (!defined($logfile))
		{
		print $aLogLine;
		}
	else
		{
		print $logfile $aLogLine;
		}
	}

# void Die(scalar aError)
sub Die($)
	{
	my $self = shift;
	my ($aError) = @_;

	my $logfile = $self->{iLOGFILE};

	if ($aError !~ /\n$/)
		{
		$aError = $aError."\n";
		}

	if (!defined($logfile))
		{
		die $aError;
		}
	else
		{
		print $logfile $aError;
		die "ERROR: System experienced a fatal error; check the log file.\n";
		}
	}

# void Status(scalar aMessage)
sub Status($)
	{
	my $self = shift;
	my ($aMessage) = @_;

	if (defined($self->{iLOGFILE}))
		{
		print STDOUT $aMessage."\n"; # Only display status (to STDOUT) if everything else is going to the logfile
		}
	}

# Returns the number of errors encountered in a phase
sub GetErrorCount()
  {
  my $self = shift;
  return $self->{iPhaseErrorCount};
  }

###########################################
# Utility functions
###########################################

# boolean CheckRelTools()

sub CheckRelTools()
	{
	# Search for reldata API
	my $found = 0;
	foreach my $path (split(/;/,$ENV{PATH}))
		{
		if (-e $path."\\reldata\.pm")
			{
			$found = 1;
			last;
			}
		}
	
	return $found
	}

# void RequireRelTools() - Requires RelData and IniData. Dies if tools can't be located, or die when being required.

sub RequireRelTools()
	{
	my $self = shift;

	if ($self->{RELTOOLS_REQUIRED} ne "required")
		{
		# Locate reldata API
		my $found = 0;
		foreach my $path (split(/;/,$ENV{PATH}))
			{
			if (-e $path."\\reldata\.pm")
				{
				push @INC, $path;
				$found = 1;
				last;
				}
			}

		if (!$found)
			{
			$self->Error("Couldn't find release tools in path");
			}

		# Require core modules
		require RelData;
		require IniData;
		$self->{RELTOOLS_REQUIRED}="required";
		}
	}

###########################################
# Handling Commands, Phases and components.
###########################################

# void Command(scalar aMessage)
# Prints out a command in scanlog format to the log file or stdout
sub Command($)
  {
  my $self = shift;
	my ($aCommand) = @_;
  my $message = "===-------------------------------------------------\n=== Stage=$self->{stageNumber}.$aCommand\n===-------------------------------------------------\n";	my $logfile = $self->{iLOGFILE};
  $self->Print($message);
	}

# void PhaseStart(scalar aPhaseName)
# If a current phase is active then this is closed, if when doing so a
# non-zero error count is returned by PhaseEnd() then Die is called. This
# is regarded as a logic error as the stage runner should normally call PhaseEnd()
# itself and decide what to do about any errors that occured in that phase.
sub PhaseStart($)
  {
  my $self = shift;
  my $phase = shift;
  if (defined $self->{iPhase})
    {
    my $numErrs = $self->PhaseEnd();
    # If there are errors returned by PhaseEnd then Die()
    if ($numErrs != 0)
      {
        $self->Die("Fatal logic error detected, CConfig::PhaseStart() called without PhaseEnd() when phase has $numErrs errors.\n");
      }
    }
    
    $self->{stageNumber}++; # For scanlog compatibility
    
    
    $self->Command($phase);
    $self->{iPhase} = $phase;

    my $localTime = ctime(); 
    my $message = "=== Stage=$self->{stageNumber}.$self->{iPhase} started $localTime\n";
    $message .= "=== Stage=$self->{stageNumber}.$self->{iPhase} == $self->{iPhase}\n"; # For Scanlog compatibility
    $message .= "+++ HiRes Start " . time() . "\n"; # For Scanlog compatibility
    $message .= "--  $self->{iPhase}: Miscellaneous\n"; # For Scanlog compatibility
    $self->Print($message);
    $self->{iPhaseErrorCount} = 0;
  }
  
# scalar PhaseEnd(void)
# Closes the current phase and returns a count of the number of errors encountered.
# This will die if a PhaseStart() has not been declared.
sub PhaseEnd()
  {
  my $self = shift;
  my $localTime = ctime();
  if (defined $self->{iPhase})
    {   
    my $message = "+++ HiRes End " . time() . "\n"; # For Scanlog compatibility
    $message .= "=== Stage=$self->{stageNumber}.$self->{iPhase} finished $localTime\n";
    $self->Print($message);
    }
  else
    {
    $self->Die("Error: CConfig::PhaseEnd() called without corresponding PhaseStart()\n");
    }
	$self->{iPhase} = undef;
  return $self->{iPhaseErrorCount};
  }
  
# void Component(scalar aComponent)
# Prints out a component for this phase in scanlog format to the log file or stdout
sub Component($)
  {
  my $self = shift;
	my ($aComponent) = @_;
  if (!defined $self->{iPhase})
    {
    $self->Die("Logger: Undefined phase for component \"$aComponent\"\n");
    }
  else
    {
    my $message = "+++ HiRes End " . time() . "\n-- $aComponent\n+++ HiRes Start " . time();
    $self->Print($message);
    }
  }

###############################
# Handling errors and warnings.
###############################

# void Error(scalar aMessage)
# Writes an error message to the logfile (if defined) or stdout
# and will increment the error count for this phase.
sub Error($)
  {
	my $self = shift;
	my ($aMessage) = @_;
  $self->{iPhaseErrorCount} += 1;
  my $message = "ERROR: $aMessage";
  $self->Print($message);
  }

# void Warning(scalar aMessage)
# Writes an warning message to the logfile (if defined) or stdout
sub Warning($)
  {
	my $self = shift;
	my ($aMessage) = @_;
  my $message = "WARNING: $aMessage";
  $self->Print($message);
  }

sub DESTROY
	{
	my $self = shift;

	# Avoid "unreferenced scalar" error in Perl 5.6 by not calling
	# PhaseEnd method for each object in multi-threaded CDelta.pm

   if ((defined $self->{iPhase}) && ($self->{iPhase} !~ /CDelta/)) {
      $self->PhaseEnd;
   }

	if (defined($self->{iLOGFILE}))
		{
		$self->{iLOGFILE}->close();
		$self->{iLOGFILE} = undef;
		}
	}
1;
