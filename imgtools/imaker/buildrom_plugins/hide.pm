#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Symbian Foundation License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# Buildrom plugin for hiding entire iby files.
# Adds a HIDEALL keyword to hide content.
#



##############################################################################
#
# Syntax: HIDEALLBEGIN
#         ..
#         HIDEALLEND
#
# Example:
# HIDEALLBEGIN
# #include <browserui.iby>
# #include <BrowserResources.iby>
# HIDEALLEND
# hides all target files in browserui.iby
#
##############################################################################


package hide;
use strict;
use plugincommon;

BEGIN
  {
  use Exporter ();
  our ( $VERSION, @ISA, @EXPORT );
  # set the version for version checking
  $VERSION     = 1.00;

  @ISA         = qw( Exporter );
  @EXPORT      = qw(&hide_info
                    &do_hide_extension
                    &is_hideallbegin
                    &is_hideallend );
  }

my %hide_infostruct =
  (
  name => "hide",
  invocation => "InvocationPoint2.5",
  single => "hide::do_hide_extension"
  );

my $line;
my @newobydata;
my %languages;
my $defaultLang;
my $verbose=0;
my $errors=0;

sub hide_info
  {
  return \%hide_infostruct;
  }

sub do_hide_extension
{
  print "Running plugin hide.pm\n";
  my $obydata = shift;
  my $depth = 0;
  my $inhide = 0;
  undef @newobydata;
  foreach $line (@{$obydata})
  {
    if ($line =~ /^\s*REM/i)
    {
      # Ignore REM statements, to avoid processing "REM __SCALABLE_IMAGE( ... )"
      push @newobydata, $line;
      next;
    }
    if (is_hideallbegin($line))
    {
      push @newobydata, "REM handled $line";
      $inhide = 1;
      print "DoHide inhide\n" if $verbose;
      next;
    }
    if (is_hideallend($line))
    {
      print "DoHide inhide end!\n" if $verbose;
      $inhide = 0;
      push @newobydata, "REM handled $line";
      next;
    }
    # inhide, hide all target files and data entries
    if ($inhide)
    {
      if (is_entry($line))
      {
        my $target = get_target_from_entry($line);
        print "DoHide target $target!\n" if $verbose;
        push @newobydata, "hide=$target\n";
        next;
      }
    }
    # Default case
    push @newobydata, $line;
  }
  @{$obydata} = @newobydata;
  print "========================== End DoHideExtension =======================\n" if $verbose;
  #Stop image creation in error case
  #exit(1) if ($errors);

}

sub is_hideallbegin
{
  my $entry = shift;
  if ($entry=~/^\s*HIDEALLBEGIN\s*$/i)
  {
    return 1;
  }
  return 0;
}

sub is_hideallend
{
  my $entry = shift;
  if ($entry=~/^\s*HIDEALLEND\s*$/i)
  {
    return 1;
  }
  return 0;
}

1;  # Return a true value from the file