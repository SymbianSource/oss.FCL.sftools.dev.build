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
# Name   : ErrorDefs.pm
# Use    : Nokia Automated Build error definitions.
#
# Synergy :
# Perl %name    : % (%full_filespec :  %)
# %derived_by   : %
# %date_created : %
#
# History :
# v1.0.2 (20/03/2006)
#  - Added PREMATURE_INTERRUPT error code.
#
# v1.0.1 (13/03/2006)
#  - Added CRITICAL_STEP_FAILED error code.
#
# v1.0 (07/10/2005) :
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

# These constant values define the error messages and corresponding exit codes
# used in the Nokia Automated Build (NAB) tool.

package ERR;

use strict;
use warnings;
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(GetError);

use constant ISIS_VERSION     => '1.00';
use constant ISIS_LAST_UPDATE => '13/12/2005';

use constant NO_ERROR             =>   0;
use constant FILE_NOT_FOUND       =>  -1;
use constant CONFIG_NOT_FOUND     =>  -2;
use constant SCRIPT_NOT_FOUND     =>  -3;
use constant MODULE_NOT_FOUND     =>  -4;
use constant INVALID_CFG_STEP     =>  -5;
use constant INVALID_CFG_FLAG     =>  -6;
use constant FILE_OPEN_FAILED     =>  -7;
use constant FILE_CREATION_FAILED =>  -8;
use constant FILE_WRITE_ERROR     =>  -9;
use constant FILE_READ_ERROR      => -10;
use constant DIR_OPEN_FAILED      => -11;
use constant DIR_CREATION_FAILED  => -12;
use constant DIR_WRITE_ERROR      => -13;
use constant DIR_READ_ERROR       => -14;
use constant INVALID_SWITCH       => -15;
use constant MISSING_SWITCH       => -16;
use constant MISSING_ATTR         => -17;
use constant INVALID_PATH         => -18;
use constant CRITICAL_STEP_FAILED => -19;
use constant PREMATURE_INTERRUPT  => -20;

my %__ErrorMessage = (
   0 => "No error to report",
  -1 => "File not found",
  -2 => "Configuration file not found",
  -3 => "Script not found",
  -4 => "Module file not found",
  -5 => "Invalid configuration step in file",
  -6 => "Invalid configuration flag definition in file",
  -7 => "Unable to open file",
  -8 => "Unable to create file",
  -9 => "Unable to write to file",
 -10 => "Unable to read from file",
 -11 => "Unable to open directory",
 -12 => "Unable to create directory",
 -13 => "Unable to write to directory",
 -14 => "Unable to read from directory",
 -15 => "Unknown flag passed",
 -16 => "Flag was not defined",
 -17 => "Attribute was not defined",
 -18 => "Path does not exist",
 -19 => "Critical step failed",
 -20 => "Premature interruption of script",
);

sub GetError
{
	my ($errCode) = (shift);
	my $message = $__ErrorMessage{$errCode};
	return "Undefined error code" unless(defined $message);

	$message .= " : $!\n" if($!);

	return $message;
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

ISIS::ErrorDefs - A perl module for error codes.

=head1 SYNOPSIS

=begin text

	# Use of error value in code.
	use ISIS::XMLManip;
	
	sub CreateFile
	{ 
	 open(FILE, '>'.shift) or return ERR::FILE_CREATION_FAILED;
	}
	
	# Determine error type.
	use ISIS::XMLManip;
	
	my $res = &CreateFile('test.txt');
	print GetError($res) if($res != 0);

=end text

=head1 DESCRIPTION

This module defines the ERR package that contains all erro constant
values and equivalent error definitions. The current implementation
has all error codes but the 'GetError' subroutine should not be used
yet. An update will come shortly.

=head2 GetError( ERROR_CODE ) :

Returns the corresponding error message for a given error code.

=head1 AUTHOR

=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
