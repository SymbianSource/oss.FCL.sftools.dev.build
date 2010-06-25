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
# CStageRunner
# 
#

package CStageRunner;

use strict;

use FindBin;
use lib $FindBin::Bin."\\stages";

# CStageRunner New(listref aStageNames, CConfig aOptions) : constructor
sub New($$)
	{
	my $proto = shift;
	my ($aStageNames, $aOptions) = @_;

	my $class = ref($proto) || $proto;

	my $self = {};
	bless($self, $class);

	if (!defined($aOptions))
		{
		$aOptions->Die("ERROR: CStageRunner takes an CConfig object as its second parameter.");
		}

	# Instantiate stages
	$self->{iStages} = [];
	my $stage;
	my $okay = 1;

  # Added scanlog compatibility
  $aOptions->PhaseStart("Initialising CStageRunner");
	foreach my $stageName (@$aStageNames)
		{
		my $found = 0;
		foreach my $path (@INC)
			{
			if (-e $path."\\$stageName.pm")
				{
				$found = 1;
				}
			}
			
		if (!$found)
			{
			$aOptions->Error("Stage $stageName does not exist.");
			$okay = 0;
			}
		elsif (eval("require $stageName"))
			{
			$stage = New $stageName($aOptions);

			if (!defined($stage))
				{
				$aOptions->Error("Stage $stageName could not be started.");
				$okay = 0;
				}
			else
				{
				push @{$self->{iStages}}, $stage;
				}
			}
		else
			{
			$aOptions->Error("Stage $stageName could not be loaded:\n$@");
			$okay = 0;
			}
		}

	if (!$okay)
		{
		$aOptions->Die("");
		}
	else
		{
		$aOptions->Print("All stages loaded and options checked.");
		}
  # This flag triggers an error message if any stage produces errors
  # but does not die. The flag is used to emit a warning, once only,
  # that subsequent stages may be polluted buy the errors in previous stages.
  $self->{iWarnOnStageEerror} = 1;
	$self->iOptions($aOptions);
  
  # Scanlog compatibility, we ignore the return value as that is covered by $okay
	$aOptions->PhaseEnd();
  return $self;
	}

# Getters/setters
sub iOptions()
	{
	my $self = shift;
	if (@_) { $self->{iOPTIONS} = shift; }
	return $self->{iOPTIONS};
	}

# boolean Run()
sub Run()
	{
	my $self = shift;

	my $okay = 1;
  my $options;
	
	foreach my $stage (@{$self->{iStages}})
		{
    $options = $self->iOptions();
    $options->PhaseStart($stage->iName());
		if ($stage->PreCheck())
			{
			$options->Status("Running ".$stage->iName());
			if ($stage->Run())
				{
        # Passed stage i.e. no fatal errors but check for 'normal' errors
        my $errors = $options->GetErrorCount();
        # Check if the stage had errors and write a precautionary
        # error message if this has not been done so already
        if ($errors > 0 && $self->{iWarnOnStageEerror} != 0)
          {
          $options->Error("Stage errors mean that subsequent stages might be unreliable.");
          # It is a write once error message so clear the internal flag
          $self->{iWarnOnStageEerror} = 0;
          }
				}
      else
        {
        # Stage signalled a fatal error by returning non-zero so bail out
        $options->Error("Fatal error received from ".$stage->iName()."::Run().");
        $options->PhaseEnd();
				$okay = 0;
        last;
        }
			}
		else
			{
      $options->Error("Stage failed PreCheck()");
			$okay = 0;
      $options->PhaseEnd();
      last;
			}
    $options->PhaseEnd();
		}
		
	return ($okay == 1);
	}
1;
