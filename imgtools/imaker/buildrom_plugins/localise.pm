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


package localise;
use strict;
use localise_all_resources;

BEGIN
  {
  use Exporter ();
  our ( $VERSION, @ISA, @EXPORT );
  # set the version for version checking
  $VERSION     = 1.00;

  @ISA         = qw( Exporter );
  @EXPORT      = qw( &localise_info
                     &do_localise_extension
                     &convert_lang
                     &trim
                     &is_addlanguage_entry
                     &get_lang_from_addlanguage_entry
                     &is_localise_entry
                     &get_type_from_localise_entry
                     &get_source_from_localise_entry
                     &get_target_from_localise_entry
                     &get_langs_from_localise_entry
                     &parse_component_langs
                     &expand_localise_macro
                     &is_language_in_component_langs
                      );
  }

my %localise_infostruct =
  (
  name => "localise",
  invocation => "InvocationPoint1",
  single => "localise::do_localise_extension"
  );

my $line;
my @newobydata;
my %languages;
my $verbose=0;
my $errors=0;
my $localise_all_resource=0;

sub localise_info
  {
  return \%localise_infostruct;
  }

# Entry point for the plugi
sub do_localise_extension
{
  print "========================== Begin do_localise_extension =======================\n" if $verbose;
  my $obydata = shift;
  do_localise_all_resources_extension(\@{$obydata});


  undef @newobydata;
  foreach $line (@{$obydata})
  {
    # Ignore REM statements, to avoid processing "REM __SCALABLE_IMAGE( ... )"
    if ($line =~ /^\s*REM/i)
    {
      push @newobydata, $line;
      next;
    }
    # ADD_LANGUAGE xx
    if (is_addlanguage_entry($line))
    {
      my $code = get_lang_from_addlanguage_entry($line);
      if ($code !~ /^\w\w+$/)
      {
        print "ERROR: bad default language code $code";
        #$errors++;
        next;
      }
      else
      {
        print "adding language $code\n" if $verbose;
        $languages{$code} = 1;
        push @newobydata, "REM handled $line";
        next;
      }
    }
    # LOCALISE macro
    if (is_localise_entry($line))
    {
      my @newdata = expand_localise_macro($line,\%languages);
      push @newobydata, @newdata;
      next;
    }
    # Default case
    push @newobydata, $line;
  }
  @{$obydata} = @newobydata;
  print "========================== End do_localise_extension =======================\n" if $verbose;
  #Stop image creation in error case
  #exit(1) if ($errors);
}

sub expand_localise_macro
{
  my $data         = $_[0];
  my %theLanguages = %{ $_[1] };
  my @localised = ();
  print "LOCALISE $data\n" if $verbose;

  my $type   = get_type_from_localise_entry($data);
  my $source = get_source_from_localise_entry($data);
  my $target = get_target_from_localise_entry($data);
  my %componentLangs = get_langs_from_localise_entry($data);

  my @languages = sort keys %theLanguages;
  foreach my $lang (@languages)
  {
    print "Language ".$lang."\n" if $verbose;
    my $sourcedata = convert_lang($source,$lang);
    my $targetdata = convert_lang($target,$lang);

    # Check does the component have overriding configurations
    # The component specific setting can define the component to ignore localisation
    if ( !is_language_in_component_langs($lang,\%componentLangs) )
    {
      #Component specific configuration overrides the global lang definitions
      print "WARNING: Component specific configuration removes this resource $source\n"  if $verbose;
      next;
    }

    my $data = "$type=$sourcedata $targetdata\n";
    print "lang data $data\n" if $verbose;
    #push the data to the new structure
    push @localised, $data;
  }
  return @localised;
}

sub is_language_in_component_langs($$)
{
  my $lang           = $_[0];
  my %componentLangs = %{ $_[1] };
  #Check whether the component langs is empty
  if ( (keys %componentLangs) > 0)
  {
    if (exists $componentLangs{ $lang })
    {
      return $componentLangs{ $lang };
    }
    else
    {
      return 0;
    }
  }
  else
  {
    return 1;
  }

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

# convert_lang(string)
# convert the string ?? part to the lang specific
sub convert_lang($$)
{
  my $res = shift;
  my $lang= shift;
  my $count = ($res =~ tr/%//);
  #create array with count amount of time of lang
  my @data = ();
  for (my $i=0; $i<$count; $i++) {
    push(@data, $lang);
  }
  my $output = sprintf($res,@data);
  return $output;
}
# match ADD_LANGUAGE 01
sub is_addlanguage_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*ADD_LANGUAGE\s+(\S+)\s*/i )
  {
    return 1;
  }
  return 0;
}
#
sub get_lang_from_addlanguage_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*ADD_LANGUAGE\s+(\S+)/i )
  {
    return $1;
  }
  return "";
}

# match data=LOCALISE(foobar.rsc, resource/foobar.rsc)
sub is_localise_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*\S+\s*=\s*LOCALISE(\s*(\S+),\s*(\S+))/i )
  {
    return 1;
  }
  return 0;
}
# get the type from an iby entry
sub get_type_from_localise_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*(\S+)\s*=/i )
  {
    return $1;
  }
  return "";
}
# get the source file from an iby entry
sub get_source_from_localise_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*(\S+)\s*=\s*LOCALISE\(\s*([^, ]+)\s*,/i )
  {
    return $2;
  }
  return "";
}
# get the target file from an iby entry
sub get_target_from_localise_entry($)
{
  my $entry = shift;
  if ( $entry =~ m/^\s*(\S+)\s*=\s*LOCALISE\(\s*([^, ]+)\s*,\s*([^, ]+)(,|\))/i )
  {
    return $3;
  }
  return "";
}
# get the target file from an iby entry
sub get_langs_from_localise_entry($)
{
  my $entry = shift;
  my %emptyhash;
  if ( $entry =~ m/^\s*(\S+)\s*=\s*LOCALISE\(\s*([^, ]+)\s*,\s*([^, ]+)\s*,\s*(.*?)\)/i )
  {
    if ($4)
    {
      return parse_component_langs($4);
    }
  }
  return %emptyhash;
}
sub parse_component_langs($)
{
  my $langs = shift;
  my %cLangs;
  foreach my $item (split(/ /,$langs))
  {
  print "lang item $item\n" if $verbose;
  if ($item =~ /^(\w\w+)$/)
    {
    print "include component specific language $1\n" if $verbose;
    $cLangs{$1} = 1;
    }
  elsif ($item =~ /^!(\w\w+)$/)
    {
    print "exclude component specific language $1\n" if $verbose;
    $cLangs{$1} = 0;
    }
  else
    {
    print "ERROR: bad default language code in $item localise macro $langs\n";
    $errors++;
    next;
    }
  }
  return %cLangs;
}


1;  # Return a true value from the file