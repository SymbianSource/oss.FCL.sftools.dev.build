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
# Name   : Registry.pm
# Use    : Parse and allow easy data manipulation from configs.xml files.

#
# History :
#  v1.1.1 (11/01/2006)
#   - Added flag passing to Registry constructor. Allows to modify its general behaviour.
#   - Added error_level flag to '__Data' package to raise warning/error if wrong key is fetched.
#
#  v1.1.0 (09/01/2006)
#   - Added 'Inheritance' and 'TiedRegister' to the Registry package.
#
#  v1.0.0 (05/01/2006)
#   - First version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   Registry package.
#
#--------------------------------------------------------------------------------------------------
package Registry;

use strict;
use warnings;
use ISIS::XMLManip;

use constant ISIS_VERSION     => '11/01/2006';
use constant ISIS_LAST_UPDATE => '1.1.1';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  my ($class, $file, $flags, %cfgData) = (shift, shift, shift || {});
  my $cfgXmlRoot = XMLManip::ParseXMLFile($file, XMLManip::LOCK);
  
  foreach my $groupNode (@{$cfgXmlRoot->Childs()})
  {
    my %group;
    foreach my $node (@{$groupNode->Childs()})
    {
      tie my %data, '__Data', \%group, $node, $flags;
      $group{$node->Attribute('type')} = \%data;
    }

    $cfgData{$groupNode->Type()} = \%group;
  }
  
  bless \%cfgData, $class;
}

sub Inheritance
{
  my ($self, $group, $type, @result) = (shift, shift, shift);

  while($type)
  {
    push @result, $type;
    
    $type = $self->{$group} &&
            $self->{$group}->{$type} &&
            tied(%{$self->{$group}->{$type}})->{__inherit};
  }
  
  return @result;
}

sub TiedRegister
{
  my ($self, $group, $type) = (shift, shift, shift);
  
  return $self->{$group} &&
         $self->{$group}->{$type} &&
         tied(%{$self->{$group}->{$type}})->{__registry};
}

1;

#--------------------------------------------------------------------------------------------------
#
#   __Data package.
#
#--------------------------------------------------------------------------------------------------
package __Data;

sub TIEHASH
{
  my ($class, $group, $xmlNode, $flags) = (shift, shift, shift, shift);

  my %registry;
  foreach my $regkey (@{$xmlNode->Child('regkey')})
  {
    $registry{$regkey->Attribute('name')} = $regkey->Attribute('value');
  }
  
  my $internalHash = { __type     => $xmlNode->Attribute('type'),
                       __inherit  => $xmlNode->Attribute('inherit'),
                       __group    => $group,
                       __registry => \%registry,
                     };
  
  foreach my $flag (sort keys %$flags) { $$internalHash{'__'.$flag} = $$flags{$flag}; }
        
  bless $internalHash, $class;
}

sub FETCH
{
  my ($self, $key) = (shift, shift);  
  my $value = $self->{__registry}{$key} || $self->{__inherit} && $self->{__group}{$self->{__inherit}}{$key};
  
  if($self->{__error_level} > 0 and not defined $value)
  { 
    if($self->{__error_level} > 1) { die "Key \'$key\' does not exist for \'".$self->{__type}."\'"; }
    else                           { warn "Key \'$key\' does not exist for \'".$self->{__type}."\'"; }
  }
  
  return $value;
}

sub STORE
{
  my ($self, $key, $value) = (shift, shift, shift);
  $self->{__registry}{$key} = $value;
}

sub DELETE
{
  my ($self, $key) = (shift, shift);
  delete $self->{__registry}{$key};
}

sub CLEAR
{
  my $self = shift;
  $self->{__registry} = (); 
}

sub EXISTS
{
  my ($self, $key) = (shift, shift);
  return exists $self->{__registry}{$key} || $self->{__inherit} && exists $self->{__group}{$self->{__inherit}}{$key};
}

sub FIRSTKEY
{
  my $self = shift;
  my %tmp  = keys %{$self->{__registry}};
  return scalar each %{$self->{__registry}}; 
}

sub NEXTKEY
{
  my $self = shift;
  return scalar each %{$self->{__registry}};
}

1;

__END__

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

Registry - XML configuration file reader with inheritance support.

=head1 SYNOPSIS

in the configs.xml file :

  <configs>
    <builds>
      
      <build type='wakeup'>
        <registry name='year' value='2006' />
        <registry name='week' value='31' />
      </build>
      
      <build type='multibase' inherit='wakeup'>
        <registry name='week' value='32' />
      </build>
      
    </builds>
  </configs>

in the script file :

  use ISIS::ConfigsData;

  my $registry = new Registry('configs.xml');
  
  print $registry->{'builds'}->{'multibase'}->{'week'}; # prints '32' since defined in multibase.
  print $registry->{'builds'}->{'multibase'}->{'year'}; # prints '2006' since multibase inherits wakeup.

=head1 DESCRIPTION

This module is used to parse XML configuration files following a certain formatting, and allows to
reduce data redudancy by allowing different elements from the configuration file to inherit from
one another.

This allows for common data to be shared between several elements of a group as shown in the given
example.

=head2 Register( <FILE>, [FLAG1, [FLAG2, ...]] ) :

Creates a new register from the specified file. The file must be in XML and follow the syntax described
in the synopsis. The flags are passed as a hash table - key/value pairs - and must be one of the flags
described in L<Registry Flags>.

=head2 Inheritance( <GROUP>, <TYPE> ) :

Returns the inherited type of the specified type in the specified group. This allows to access the
'__inherit' key of the '__Data' package's internal hash table.

=head2 TiedRegister( <GROUP>, <TYPE> ) :

Returns a reference to the register tied to a specific type in a given group. This allows to directly
access the '__Data' package's internal hash table.

=head1 REGISTRY FLAGS

The flags allow to modify the registry's behaviour and are directly passed to the registry constructor
as a hash table - key/value pairs. Here are the following accepted flags :

=head2 error_level :

Sets the registry's error level. If a key fetched does not exist, a warning is issued if the error_level
is set to 1, and an error is raised followed by a die if the error_level is set to 2.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
