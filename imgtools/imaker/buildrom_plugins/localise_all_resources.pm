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
# Adds a LOCALISE macro that enables configuration of localised files.
# The localised language selection is done with a ADD_LANGUAGE macro.
#



###############################################################################
#
# Syntax: LOCALISE
#   type=LOCALISE(source, target[, languages])
#   source => the source file. The section that needs to be localised should be marked with ??.
#   target => the target file. The section that needs to be localised should be marked with ??.
#   languages => a space delimited list of language codes
#
# Syntax: ADD_LANGUAGE
#   ADD_LANGUAGE lang
#
# Example:
# Add languages
# ADD_LANGUAGE 01
# ADD_LANGUAGE 02
# ADD_LANGUAGE 03
#
# Use Case 1:
# Localises a App resoure file.
#   data=LOCALISE(APP_RESOURCE_DIR\App.r??, RESOURCE_DIR\app.r??)
# Output:
#   data=APP_RESOURCE_DIR\App.r01 RESOURCE_DIR\app.r01
#   data=APP_RESOURCE_DIR\App.r02 RESOURCE_DIR\app.r02
#   data=APP_RESOURCE_DIR\App.r03 RESOURCE_DIR\app.r03
#
# Use Case 2:
# Localise all resource files under a section
# ADD_LANGUAGE 01
# ADD_LANGUAGE 02
# ADD_LANGUAGE 03
#
# LOCALISE_ALL_RESOURCES_BEGIN
# // All resource files will be localised
# data=APP_RESOURCE_DIR\App.rsc RESOURCE_DIR\app.rsc
# data=APP_RESOURCE_DIR\App2.rsc RESOURCE_DIR\app2.rsc
# LOCALISE_ALL_RESOURCES_END
# Output:
#   data=APP_RESOURCE_DIR\App.r01 RESOURCE_DIR\app.r01
#   data=APP_RESOURCE_DIR\App.r02 RESOURCE_DIR\app.r02
#   data=APP_RESOURCE_DIR\App.r03 RESOURCE_DIR\app.r03
#   data=APP_RESOURCE_DIR\App.r01 RESOURCE_DIR\app.r01
#   data=APP_RESOURCE_DIR\App.r02 RESOURCE_DIR\app.r02
#   data=APP_RESOURCE_DIR\App.r03 RESOURCE_DIR\app.r03
#
###############################################################################

#
# Version 4
# Path corrections to widget support.
#
# Version 3
# Support for Idle widgets.
#
# Version 2
# Localises also *.hlp to *.h%s.
#
# Version 1
# Initial version.


package localise_all_resources;
use strict;

BEGIN
  {
  use Exporter ();
  our ( $VERSION, @ISA, @EXPORT );
  # set the version for version checking
  $VERSION     = 1.00;

  @ISA         = qw( Exporter );
  @EXPORT      = qw( &localise_all_resources_info
                     &do_localise_all_resources_extension
                     &is_localise_all_resources_begin
                     &is_localise_all_resources_end
                     &is_resource_entry
                     &is_help_entry_xhtml
                     &is_help_entry_hlp
                     &is_dtd_entry
                     &is_active_idle_entry
                     &is_elocl_entry
                     &get_type_from_entry
                     &get_source_from_entry
                     &get_target_from_entry
                     &create_localise_entry_from_resource
                     &create_localise_entry_from_help
                     &create_localise_entry_from_dtd
                     &create_localise_entry_from_active_idle
                     &create_localise_entry_from_elocl
                      );
  }

my %localise_all_resources_infostruct =
  (
  name => "localise_all_resources",
  invocation => "InvocationPoint1",
  single => "localise_all_resources::do_localise_all_resources_extension"
  );

my $line;
my @newobydata;
my %languages;
my $verbose=0;
my $errors=0;
my $localise_all_resource=0;

sub localise_all_resources_info
  {
  return \%localise_all_resources_infostruct;
  }

# Entry point for the plugi
sub do_localise_all_resources_extension
{
  print "========================== Begin localise_all_resources =======================\n" if $verbose;
  my $obydata = shift;

  undef @newobydata;
  foreach $line (@{$obydata})
  {
    # Ignore REM statements, to avoid processing "REM __SCALABLE_IMAGE( ... )"
    if ($line =~ /^\s*REM/i)
    {
      push @newobydata, $line;
      next;
    }
    # LOCALISE_ALL_RESOURCES_BEGIN
    if (is_localise_all_resources_begin($line))
    {
      $localise_all_resource = 1;
      push @newobydata, "REM handled $line";
      next;
    }
    # LOCALISE_ALL_RESOURCES_END
    if (is_localise_all_resources_end($line))
    {
      $localise_all_resource = 0;
      push @newobydata, "REM handled $line";
      next;
    }
    if ( $localise_all_resource )
    {
      # localise all rsc files inside the localise_all_resources section
      # resource files .rsc
      if ( is_resource_entry($line) )
      {
        # match data/file=foobar.rsc resource/foobar.rsc
        $line = create_localise_entry_from_resource($line);
        push @newobydata, "$line\n";
        next;
      }
      # help files .hlp
      if ( is_help_entry_hlp($line) )
      {
        # match data/file=foobar.rsc resource/foobar.rsc
        $line = create_localise_entry_from_help_hlp($line);
        push @newobydata, "$line\n";
        next;
      }
      # localise the .dtd files that have \\01\\ in their source target path
      if ( is_dtd_entry($line) )
      {
        # match data/file=foobar.rsc resource/foobar.rsc
        $line = create_localisable_path($line);
        $line = create_localise_entry_from_dtd($line);
        push @newobydata, "$line\n";
        next;
      }
      # localise the active idle .o0001 files
      if ( is_active_idle_entry($line) )
      {
        # match data/file=foobar.rsc resource/foobar.rsc
        $line = create_localisable_path($line);
        $line = create_localise_entry_from_active_idle($line);
        push @newobydata, "$line\n";
        next;
      }
      # localise the elocl file
      if ( is_elocl_entry($line) )
      {
        # match data/file=foobar.rsc resource/foobar.rsc
        $line = create_localise_entry_from_elocl($line);
        push @newobydata, "$line\n";
        next;
      }

    }
    # Default case
    push @newobydata, $line;
  }
  @{$obydata} = @newobydata;
  print "========================== End localise_all_resources =======================\n" if $verbose;
  #Stop image creation in error case
  #exit(1) if ($errors);
}

# trim(string)
# Removes spaces from both ends of the string.
# Returns a trimmed string.
sub trim($)
{
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

# match LOCALISE_ALL_RESOURCE_BEGIN
sub is_localise_all_resources_begin($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*LOCALISE_ALL_RESOURCES_BEGIN\s*$/i )
  {
    return 1;
  }
  return 0;
}

# match LOCALISE_ALL_RESOURCE_END
sub is_localise_all_resources_end($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*LOCALISE_ALL_RESOURCES_END\s*$/i )
  {
    return 1;
  }
  return 0;
}
#
# match data=foobar.rsc resource/foobar.rsc
sub is_resource_entry($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  if ($source =~ m/\.rsc[\"|\']?$/i &&
      $target =~ m/\.rsc[\"|\']?$/i )
  {
    return 1;
  }
  return 0;
}

#
# match
sub is_help_entry_xhtml($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  if ($source =~ m/\\01\\/i &&
      $target =~ m/\\01\\/i )
  {
    return 1;
  }
  return 0;
}

# match data=foobar.hlp resource/foobar.hlp
sub is_help_entry_hlp($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  if ($source =~ m/\.hlp[\"|\']?$/i &&
      $target =~ m/\.hlp[\"|\']?$/i )
  {
    return 1;
  }
  return 0;
}

#
# match data=DATAZ_\\resource\\xhtml\\01\\0x01000000\\contents.zip  RESOURCE_FILES_DIR\\xhtml\\01\\0x01000000\\contents.zip
sub is_dtd_entry($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  if (($source =~ m/\\01\\.*\.dtd/i &&
      $target =~ m/\\01\\.*\.dtd/i ) ||
    ($source =~ m/\\00\\.*\.dtd/i &&
      $target =~ m/\\00\\.*\.dtd/i ))
  {
    return 1;
  }
  return 0;
}

#
# match data=DATAZ_\\resource\\xhtml\\01\\0x01000000\\contents.zip  RESOURCE_FILES_DIR\\xhtml\\01\\0x01000000\\contents.zip
sub is_active_idle_entry($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  if (($source =~ m/\.o0001/i &&
        $target =~ m/\.o0001/i ) ||
     ($source =~ m/\.o0000/i &&
        $target =~ m/\.o0000/i ))
  {
    return 1;
  }
  return 0;
}

#
#
sub is_elocl_entry($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  if ($source =~ m/elocl\.dll/i &&
      $target =~ m/elocl\.loc/i )
  {
    return 1;
  }
  return 0;
}

# get the type from an iby entry
sub get_type_from_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*(\S+)\s*=\s*(\S+)\s+(\S+)\s*/i )
  {
    return $1;
  }
  return "";
}
# get the source file from an iby entry
sub get_source_from_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*(\S+)\s*=\s*(\S+)\s+(\S+)\s*/i )
  {
    return $2;
  }
  return "";
}
# get the target file from an iby entry
sub get_target_from_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*(\S+)\s*=\s*(\S+)\s+(\S+)\s*/i )
  {
    return $3;
  }
  return "";
}

# create localise entry from resource entry
sub create_localise_entry_from_resource($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  #convert the .rsc to .r%02d
  $source =~ s/\.rsc/\.r%s/i;
  $target =~ s/\.rsc/\.r%s/i;
  #print "create_localise_entry_from_resource: $source\n";
  return "$type=LOCALISE($source, $target)";
}

# create localise entry from resource entry
sub create_localise_entry_from_help($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  #convert the \\01\\ to \\%02d\\
  $source =~ s/\\01\\/\\%02d\\/i;
  $target =~ s/\\01\\/\\%02d\\/i;
  #print "create_localise_entry_from_resource: $source\n";
  return "$type=LOCALISE($source, $target)";
}

# create localise entry from help entry hlp
sub create_localise_entry_from_help_hlp($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  #convert the .hlp to .h%02d
  $source =~ s/\.hlp/\.h%s/i;
  $target =~ s/\.hlp/\.h%s/i;
  #print "create_localise_entry_from_resource: $source\n";
  return "$type=LOCALISE($source, $target)";
}

# create localise entry from resource entry
sub create_localise_entry_from_dtd($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  #convert the \\01\\ to \\%02d\\
#  $source =~ s/\\01\\/\\%02d\\/i;
#  $target =~ s/\\01\\/\\%02d\\/i;
#  $source =~ s/\\00\\/\\%02d\\/i;
#  $target =~ s/\\00\\/\\%02d\\/i;
#  #print "create_localise_entry_from_resource: $source\n";
  return "$type=LOCALISE($source, $target)";
}

# create localise entry from resource entry
sub create_localise_entry_from_active_idle($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  #convert the \\0001\\ to \\%04d\\
  $source =~ s/o0001/o%04d/i;
  $target =~ s/o0001/o%04d/i;
  $source =~ s/o0000/o%04d/i;
  $target =~ s/o0000/o%04d/i;
  #print "create_localise_entry_from_resource: $source\n";
  return "$type=LOCALISE($source, $target)";
}

sub create_localise_entry_from_elocl($)
{
  my $entry = shift;
  my $type = get_type_from_entry($entry);
  my $source = get_source_from_entry($entry);
  my $target = get_target_from_entry($entry);
  #convert the \\0001\\ to \\%04d\\
  $source =~ s/\.dll/\.%02d/i;
  $target =~ s/\.loc/\.%02d/i;
  #print "create_localise_entry_from_resource: $source $target\n";
  return "$type=LOCALISE($source, $target)";
}

# create localisable path from /00/ or /01/ paths
sub create_localisable_path($)
{
  my $entry = shift;

  $entry =~ s/\\01\\/\\%02d\\/ig;
  $entry =~ s/\\00\\/\\%02d\\/ig;

  #print "create_localise_entry_from_resource: $source\n";
  return $entry;
}
1;  # Return a true value from the file