#!perl -w
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
# summarise an automated build log
# documentation available in generic\tools\e32toolp\docs\scanlog.txt
# please update the documentation when modifying this file
# 
#

package sbsv2scanlog;

use strict;
use Carp;
use FindBin;		# for FindBin::Bin

use lib "$FindBin::Bin/../../tools/build/scanlog"; # For running in source
use lib "$FindBin::Bin"; # For running in \tools

use Scanlog;

# CheckForErrors
#
# Inputs
# $line - Line of text to check
#
# Outputs
# Return true for presence of error in the line
# Return false for no error found
#
# Description
# This function matches the input against a known set of Error Strings
sub CheckForErrors
{
  my ($line) = @_;


    # Check Original scanlog rules
    return &Scanlog::CheckForErrors($line);
	
	# Not already returned so return false
	return 0;
}

# CheckForRemarks
#
# Inputs
# $iLine - Line of text to check
#
# Outputs
# Return true for presence of Warning in the line according to the warning codes
# defined in the checkList array
# The list is the current known EABI warnings which are considered to be 
# Remarks
# Return false for no Warning found
#
# Description
# This function matches the input against a known set of Warning Strings defined
# in the array CheckList
sub CheckForRemarks
{
    my ($line) = @_;

    #/sf/app/messaging/email/pop3andsmtpmtm/clientmtms/group/imcm.rls:36:54: warning: no newline at end of file
    if ($line =~ /:\d+:\d+: warning: no newline at end of file/)
    {
      return 1;
    }

    # Check Original scanlog rules
    return &Scanlog::CheckForRemarks($line);


	# Not already returned so return false
    return 0;
	
}

# CheckForWarnings
#
# Inputs
# $iLine - Line of text to check
#
# Outputs
# Return true for presence of Warning in the line
# Return false for no Warning found
#
# Description
# This function matches the input against a known set of Warning Strings
sub CheckForWarnings
{
  my ($line) = @_;

    # Check Original scanlog rules
    return &Scanlog::CheckForWarnings($line);

	# Not already returned so return false
	return 0;
}

# CheckForIgnore
#
# Inputs
# $iLine - Line of text to check
#
# Outputs
# Return true if line can be ignored
# Return false if line cannot be ignored
#
# Description
# This function matches the input against a known set of Warning Strings which can be ignored
sub CheckForIgnore
{
  my ($line) = @_;
  
    # Check Original scanlog rules
    return &Scanlog::CheckForIgnore($line);
	
	# Not already returned so return false
	return 0;
}




# CheckForNotBuilt
#
# Inputs
# $iLine - Line of text to check
#
# Outputs
# Return true for presence of Warning in the line
# Return false for no Warning found
# $iNotBuilt - Name of thing not built
#
# Description
# This function matches the input against a known set of Strings for things not built
sub CheckForNotBuilt
{
  my ($line) = @_;
  
    # Check Original scanlog rules
    return &Scanlog::CheckForNotBuilt($line);
	
	# Not already returned so return false
	return 0;
}

# CheckForMissing
#
# Inputs
# $iLine - Line of text to check
#
# Outputs
# Return true for presence of Warning in the line
# Return false for no Warning found
# $iNotBuilt - Name of thing not built
#
# Description
# This function matches the input against a known set of Strings for things not built
sub CheckForMissing
{
  my ($line) = @_;
  
    # Check Original scanlog rules
    return &Scanlog::CheckForMissing($line);
	
	# Not already returned so return false
	return 0;
}

# CheckForRealTimeErrors
#
# Inputs
# $iLine - Line of text to check
#
# Outputs
# Return true for presence of a Real Time Error in the line
#        plus string detailing error (if available)
# Return false for no Real Time Error found
#
# Description
# This function matches the input against a known set of Error Strings
# At the time of adding this subroutine, such error strings were only reported by P4GetSource.pm
# Scripts calling this subroutine should note that, for example, lines beginning with "ERROR:" will
# also be considered to be errors by subroutine CheckForErrors, above. 
sub CheckForRealTimeErrors
{
  my ($line) = @_;

    # Check Original scanlog rules
    return &Scanlog::CheckForRealTimeErrors($line);
	
	# Not already returned so return False
	return 0;
}



# CheckForMigrationNotes
#
# Inputs
# $iLine - Line of text to check
#
# Outputs
# Return true for presence of Migration_Note in the line
# Return false for no Migration_Note found
#
# Description
# This function matches the input against a known set of Migration_Note Strings
sub CheckForMigrationNotes
{
  my ($line,$component) = @_;

  if ($component =~ /STLPORT/i)
  {
    # ../../src/iostream.cpp:164: warning: 'result' might be used uninitialized in this function 
    if ($line =~ /:\d+: warning:.*?might be used uninitialized in this function/)
    {
      return 1;
    }
  }

  #cpp: file.h:48:8: warning: extra tokens at end of #endif directive
  if ($line =~ /:\d+:\d+: warning: extra tokens at end of #endif directive/)
  {
    return 1;
  }

  #raptor/lib/flm/export.flm:56: warning: overriding commands for target `S:/epoc32/rom/include/midp20_installer.iby'
  if ($line =~ /:\d+: warning: overriding commands for target/)
  {
    return 1;
  }
  
  #raptor/lib/flm/export.flm:56: warning: ignoring old commands for target `S:/epoc32/rom/include/midp20_installer.iby'
  if ($line =~ /:\d+: warning: ignoring old commands for target/)
  {
    return 1;
  }

  #\sf\app\techview\techviewplat\techviewuiklaf\resource\eikcoctl.rls(38) : Warning: (003) rls item redefined.
  if ($line =~ /\(\d+\)\s+: Warning: (003) rls item redefined/)
  {
    return 1;
  }

    # Check Original scanlog rules
    return &Scanlog::CheckForMigrationNotes($line);

    # Not already returned so return False
    return 0;
}

# CheckForComponentExitCodesToMigrate
#
# Inputs
# $iLine - Line of text to check
# $component - Current Component
#
# Outputs
# Return true for to ignore this special component error
# Return false for to not ignore this special component error
#
# Description
# This function matches the input against a known set of Components and Strings to ignore the later non zero exit code of.
sub CheckForComponentExitCodesToMigrate
{
  my ($line,$component) = @_;

  if ($component =~ /Integrator ARM1136 Core Module/ || $component =~ /OMAP H2 BSP|omaph2bsp/ )
  {
    # M://epoc32/tools/makefile_templates/base/bootstrap.mk:213: *** missing `endef', unterminated `define'.  Stop.
    # if ($line =~ /\/epoc32\/tools\/makefile_templates\/base\/bootstrap\.mk:\d+: \*\*\* missing `endef', unterminated `define'\.  Stop\./)
    if ($line =~ /\/epoc32\/tools\/makefile_templates\/base\/bootstrap\.mk:\d+: \*\*\* multiple target patterns\.  Stop\./)
    {
      return 1;
    }
    #/bin/sh: make: command not found
    if ($line =~ /\/bin\/sh: make: command not found/)
    {
      return 1;
    }
  } else {
    return 0;
  }
}

# CheckForAdvisoryNotes
#
# Inputs
# $iLine - Line of text to check
#
# Outputs
# Return true if line can be ignored
# Return false if line cannot be ignored
#
# Description
# This function matches the input against a known set of Strings
sub CheckForAdvisoryNotes
{
  my ($line) = @_;
  
    # Check Original scanlog rules
    return &Scanlog::CheckForAdvisoryNotes($line);
	
	# Not already returned so return false
	return 0;
}
1;
