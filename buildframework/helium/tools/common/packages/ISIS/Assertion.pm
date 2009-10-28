#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#
#--------------------------------------------------------------------------------------------------
# Name   : Assertion.pm
# Use    : Nokia Automated Build error definitions.
#
# Synergy :
# Perl %name    : % (%full_filespec :  %)
# %derived_by   : %
# %date_created : %
#
# History :
#
# v1.0 (07/10/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   Assertion package;
#
#--------------------------------------------------------------------------------------------------

package ISIS::Assertion;

use strict;
use warnings;

my $__DEBUG_FLAG;

#--------------------------------------------------------------------------------------------------
# import and unimport package subroutines.
#--------------------------------------------------------------------------------------------------
sub import
{
  my ($pkg, %symbols) = (@_);
  
  die "Invalid symbols defined\n" if(scalar keys %symbols != (0 + (exists $symbols{_DEBUG})));
  
  $__DEBUG_FLAG = !($symbols{_DEBUG} || 0);

  no strict 'refs';
  
  my $caller = caller;
  *{$caller.'::__ASSERT'}      = \&__ASSERT;
  *{$caller.'::__DBG_MESSAGE'} = \&__DBG_MESSAGE;
}

sub unimport
{
  $__DEBUG_FLAG = 1;
}

#--------------------------------------------------------------------------------------------------
# Assertion subroutines.
#--------------------------------------------------------------------------------------------------
sub __ASSERT($)
{
  __ASSERT_AUX() unless(shift || $__DEBUG_FLAG);
}

sub __ASSERT_AUX()
{
  my $__subroutine = 'unknown';
  
  my ($__pkg,   $__file,  $__line, $__sub, $__args,
      $__array, $__eval,  $__req,  $__ind, $__bmsk);
    
  if(($__pkg,   $__file,  $__line, $__sub, $__args,
      $__array, $__eval,  $__req,  $__ind, $__bmsk) = caller(2))
  {
    $__subroutine = $__sub;
  }
  
  if(($__pkg,   $__file,  $__line, $__sub, $__args,
      $__array, $__eval,  $__req,  $__ind, $__bmsk) = caller(1))
  {
    
    my ($__file_handle, $__expression, $__i) = (undef, 'unknown', 0);

    open($__file_handle, $__file);
    while($__i != $__line) { $__expression = <$__file_handle>; ++$__i; }
    close($__file_handle);
    
    ($__expression) = ($__expression =~ /__ASSERT\((.*)\)/);    
    
    die "File \'$__file\' line \'$__line\' - Assertion Failed!\n".
        "   In $__subroutine : \'$__expression\' was evaluated to false.\n";
    
  } 
}

#--------------------------------------------------------------------------------------------------
# Debug message output on standard output.
#--------------------------------------------------------------------------------------------------
sub __DBG_MESSAGE(@)
{
  print STDERR @_ unless($__DEBUG_FLAG);
}

1;

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
