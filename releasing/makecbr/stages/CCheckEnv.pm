#!\bin\perl
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
# CCheckEnv
# Uses the checkenv command to ensure all files are accounted for
# 
#

use strict;

use FindBin;
use lib $FindBin::Bin."\\..";
use lib $FindBin::Bin."\\Stages\\CBRRepair";

# Load base class
use CProcessStage;

# Load the error recovery code.
use CBRPatch;

package CCheckEnv;
use vars ('@ISA');
@ISA = qw( CProcessStage );

use constant CONFIG_PREINSTALLED_COMPONENTS => 'Preinstalled components';

# void CheckOpts()
# Ensures that all required (user) options are set to reasonable values at the
# start of execution
#
# Dies if options invalid
sub CheckOpts()
    {
    my $self = shift;
    # Nothing to check
    }

# boolean PreCheck()
# Ensures that all required results from previous stages are set to reasonable
# values before this stage is run
#
# Returns false if result options are invalid
sub PreCheck()
    {
    my $self = shift;
    my $options = $self->iOptions();

    if (!$self->PreCheckListOpt(CONFIG_PREINSTALLED_COMPONENTS)) {
        $options->Error("Preinstalled components list not available (did CDelta run OK?)");
        return 0;
    }

    return 1;
    }

# boolean Run()
# Performs the body of work for this stage
#
# Returns false if it encounters problems
sub Run()
    {
    my $self = shift;
    my $passed = 1; # True, so far
    my $options = $self->iOptions();

    # First things first. We are going to need EnvDb and IniData. Make sure
    # they are loaded.
    # This copied from CPrepEnv, really ought to happen at a higher level.
    my $found = 0;
    for my $path (split(/;/,$ENV{PATH}))
        {
        if (-e $path."\\envdb\.pm")
            {
            push @INC, $path;
            $found = 1;
            last;
            }
        }
    if (!$found)
        {
        $options->Error("Couldn't find release tools in path");
        }
    require EnvDb;
    require IniData;
    require MrpData;

    # Create a new CBRPatch object. This won't do anything quite yet..
    # Pass in the options object so it can generate reports.
    my $cbrpatch = CBRPatch->new($options);

    # get the list of preinstalled components (really a hash)
    my %preinstalled = @{$options->Get(CONFIG_PREINSTALLED_COMPONENTS)};

    # Check the output of envinfo, if its broken the patching code
    # attempts to fix things x times (defaults to 3).
    $options->Component('CBRPatch: Miscellaneous');
    for my $att (1..$cbrpatch->Attempts)
        {
        my $evcomment = "Patch $att> " unless($att == 1);
        # Detemine the fixes required to sort out the CBR. Might be none..
        my $nfixes = $cbrpatch->CBRFixes;

        # Get envinfo output. We get a reference to an array which is the
        # output from 'envinfo -ffv'. Envinfo will already have been triggered
        # by the above call to CBRFixes, we'll just get the envinfo output
        # generated there. If we wanted envinfo run again we'd pass an argument.
        my $evop = $cbrpatch->EnvinfoOutput;

        $passed &= $self->EnvInfoErrorReport( $evop, $evcomment );

        if ( $nfixes )
            {
            # get a list of component names to be fixed
            my @components = grep defined, map $_->Component(), @$nfixes;

            # do not attempt to fix preinstalled components (e.g. ISCs)
            my @wontfix = grep exists $preinstalled{$_}, @components;

            # if any are on the list of components to fix then this is a fatal error
            if (@wontfix) {
                $options->Error("Not going to patch preinstalled component(s): @wontfix");
                return 0;
            }

            # Implement the fixes required. This will also trigger
            # rerun of envinfo, + recalc problems and fixes.
            my $fixesdone = $cbrpatch->ImplementFixes;
#           $options->Print("$fixesdone patches applied to CBR.\n");

            # Make sure we get an error report if this is the last
            # iteration. If it isn't, it'll get done on the next.
            $passed &= $self->EnvInfoErrorReport( $evop, "Patch FINAL> ")
                if( $att == $cbrpatch->Attempts );
            if( $cbrpatch->{ncbrproblems} )  # Are there further problems?
                {
                $options->Error( $cbrpatch->{ncbrproblems} . " CBR problems remain.\n" );

                }
            else
                {
                $passed = 1; # Problems fixed. Make sure we continue.
                last;
                }
            }
        else
            {
            last; # There are no fixes, though there may be trouble..
            }
        }
    $options->Component('CCheckEnv: Miscellaneous');
    return $passed;
    }

sub EnvInfoErrorReport
    {
    my $self = shift;
    my $evop = shift;
    my $opcomment = shift;
    my $passed=1;

    my $options = $self->iOptions();

    if( ref($evop) )
        {
        my @output = ();
        my $status;

        foreach my $line (@$evop)
            {
            chomp $line;

            if ($line =~ /^ERROR: Failed to run envinfo(.*)$/)
                {
                $options->Error($opcomment . "Couldn't spawn child process to run envinfo -f");
                $passed = 0;
                return $passed;
                }

            if ($line =~ /^Overall status: (.*)$/)
                {
                if (defined($status))
                    {
                    $passed = 0;
                    last;
                    }
                else
                    {
                    $status = $1;
                    }
                }

            push @output, $line;
            }

        if (!$passed)
            {
            $options->Error($opcomment . "Found multiple instances of 'Overall status' lines when parsing envinfo -ffv output.");
            $status = undef;
            }

        if (!defined($status))
            {
            $options->Error($opcomment . "Envinfo overall status was not found:");
            $passed = 0;
            }
        elsif ($status ne "pending release")
            {
            $options->Error($opcomment . "Envinfo status was '$status'. Expected 'pending release':");
            $passed = 0;
            }

        if (!$passed)
            {
            $self->ExtractFromErrorArray(@output);
            # Now dump out the entire envinfo output in non-scanlog format
            $options->Print($opcomment . "Complete envinfo output:\n");
            foreach my $error (@output)
                {
                $options->Print($opcomment . "- ".$error);
                }
            }
        }
    else
        {
        # Envinfo output not a reference to an array. Something is broken.
        $passed = 0;
        }
        return $passed;
    }

# This parses the envinfo -f output and extracts specific error
# and warning messages and dumps them out in scanlog format.
sub ExtractFromErrorArray($)
  {
  my $self = shift;
  my @logErrorLines = @_;

  my $options = $self->iOptions();
  $options->Print("Specific errors and warnings extracted from envinfo output:\n");
  $options->Print("Component name is shown thus; [component] before the message\n");
  my $component = "";
  my @errorList = ();
  my @warningList = ();
  foreach my $line (@logErrorLines) {
    # Remove line feed, white space
    chomp $line;
    # Strip all leading '.' that are envinfo's way of showing progress
    $line =~ s/^(Scanning environment)*\.*//;

    if ($line =~ m/^(\S+): Error: (.*)/) {
      $component = $1;
      my $err = $2;

      # Print out any unknown errors with [???] which are cached
      if(scalar(@errorList) != 0) {
        foreach my $unknownErr (@errorList){
          $options->Error("[???] $unknownErr");
        }
        @errorList = ();
      }

      $options->Error("[$component] $err");
      $component = "";
    }
    # Search for ": Multiple errors (first" and grab the first word, that is the component
    elsif ($line =~ m/^(\S+): Multiple errors \(first/) {
      # Dump the array of errors previously logged then clear the error array and the component
      $component = $1;
      foreach my $err (@errorList) {
        $options->Error("[$component] $err");
      }
      @errorList = ();
      $component = "";
    # Special case warnings or errors:
    # The next three regexs are a bit fragile:
    # EnvDb::Duplicates() will return a message "attempting to release.."
    # but EnvInfo::CheckEnv() prepends "Warning: "
    # Defensively this regex ignores the EnvInfo::CheckEnv() prefix but if
    # the EnvDb::Duplicates() should change this regex may fail.
    # Note that we are explicitly converting a EnvInfo::CheckEnv() warnings
    # to an error message by putting it on the error list
    } elsif ($line =~ m/^(\S+):\s+(\S+) attempting to release (\S+) which has already been released by (\S+)/) {
      push @errorList, "$2 attempting to release $3 which has already been released by $4";
      #push @errorList, $line;
    } elsif ($line =~ m/^(\S+): Component name in MRP file is "(\S+)" whilst the name of this component in the environment database is "(\S+)"/) {
      push @errorList, "Component name in MRP file is \"$2\" whilst the name of this component in the environment database is \"$3\"";
      #push @errorList, $line;
    } elsif ($line =~ m/^(\S+): (.+) has unknown origin/) {
      push @errorList, $2." has unknown origin";
      #push @errorList, $line;
    # Treatment of general warnings or errors
    } elsif ($line =~ m/^(Error): (.+)/i || $line =~ m/^(Warning): (.+)/i) {
      if (uc $1 eq "ERROR") {
        my $error = $2;
        # Strip spurious CR
        $error =~ s/\r//;
        push @errorList, $error;
      } else {
        # Process a warning
        # MAINTANANCE NOTE: The lines up to "END MAINTANANCE NOTE" can be removed
        # once the missing '\n' is added in in MrpData::HandleBinFile() line 594
        #
        # First a precautionary check to see if this is a single line with multiple
        # warnings. This is specific to MrpData::HandleBinFile()
        # that emits a warning with this particlular pattern.
        if ($line =~ m/^Warning: \((\S+?)\)(.+?)\?/) {
          # In this case we can include the component that is in (...)
          while ($line =~ m/^Warning: \((\S+?)\)(.+?)\?(.*)/i) {
            push @warningList, "[$1]".$2."?";
            $line = $3;
            $line =~ s/^\.*//;
          }
          # Pick up an error that might be at the end of this line
          if ($line =~ m/^(Error): (.+)/i) {
            my $error = $2;
            # Strip spurious CR
            $error =~ s/\r//;
            push @errorList, $error;
          }
        } else {
          # END MAINTENANCE NOTE
          # Treat as a single warning line
          # NOTE: No component addded
          push @warningList, $2
        }
      }
    }
  }
  # Residual errors (these do not have an identifiiable component)
  foreach my $err (@errorList) {
    $options->Error("$err");
  }
  foreach my $warn (@warningList) {
    $options->Warning("$warn");
  }
}
1;
