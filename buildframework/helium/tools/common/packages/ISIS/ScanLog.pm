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
# Name   : ScanLog.pm
# Path   : N:\isis_scripts\packages\ISIS\
# Use    : .

#
# Synergy :
# Perl %name: ScanLog.pm % (%full_filespec: ScanLog.pm-2.1.5:perl:fa1s60p1#1 %)
# %derived_by: oligrant %
# %date_created: Wed Apr  5 13:29:34 2006 %
#
# Version History :
#
# v1.0.0 (30/01/2006) :
#  - First version of the module.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   ScanLog package.
#
#--------------------------------------------------------------------------------------------------

package ScanLog;

use strict;
use warnings;
use ISIS::Assertion _DEBUG => 1;
use ISIS::XMLManip;
use ISIS::HttpServer;

use constant ISIS_VERSION     => '1.0.0';
use constant ISIS_LAST_UPDATE => '30/01/2006';

my @__error_patterns;
my @__warning_patterns;
my @__remark_patterns;
my @__ignore_patterns;

BEGIN
{
  @__error_patterns = (
    'FLEXlm error:',
    '(?:ABLD|BLDMAKE) ERROR:',
    'FATAL ERROR\(S\):',
    'fatal error U1077',
    'warning U4010',
    'make(?:\[\d+\])?: \*\*\* ',
    'make(?:\[\d+\])?: .* not remade ',
    '\".*\", line \d+: Error: +.\d+.*?:.*$',
    'error: Internal fault:.*$',
    'Exception: STATUS_ACCESS_VIOLATION',
    'target .* given more than once in the same rule',
    '^ERROR: ',
    '^ERROR\t',
    '^MISSING:\s+\\\\',
  );
  
  @__warning_patterns = (
    '(?i:Warning: Unmatched)',
    '^BLDMAKE WARNING:',
    'WARNING\(S\)',
    '^WARNING: ',
    '\(\d+\) : warning C',
    'LINK : warning',
    ':\d+: warning:',
    '\".*\", line \d+: Warning: +.\d+.*?:.*$',
    'Usage Warning:',
    'mwld.exe:',
    '^Command line warning',
    '^MAKEDEF WARNING:',
    'ERROR: bad relocation:',
    '^\d+ warning/',
    '^EventType:\s+Error\s+Source:\s+SweepNT',
    '^WARN\t',
  );
  
  @__remark_patterns = (
    '\".*\", line \d+: Warning: +.\d+.*?:',
    'Command line warning D4025 : ',
    '^REMARK: ',
    '^EventType:\s+Error\s+Source:\s+GNU\s+Make',
    ':\d+: warning: cannot find matching deallocation function',
  );
  
  @__ignore_patterns = (
    '\".*\", line \d+: Warning: +#68-D:',
    '\".*\", line \d+: Warning: +#108-D:',
    '\".*\", line \d+: Warning: +#128-D:',
    '\".*\", line \d+: Warning: +#191-D:',
    '\".*\", line \d+: Warning: +A1608W:',
    '\".*\", line \d+: Warning: +#1446-D:',
  );
}

#--------------------------------------------------------------------------------------------------
# Contructor - takes (parent xml node, annotation file, current step).
#--------------------------------------------------------------------------------------------------
sub new
{
  bless { __current_step  => pop,
          __parent_node   => pop,
          __anno_file     => pop,
          __xml_output    => undef,
          __discards      => '',
          __message_types => { '1_remark'  => \@__remark_patterns,
                               '2_ignore'  => \@__ignore_patterns,
                               '3_warning' => \@__warning_patterns,
                               '4_error'   => \@__error_patterns,
                             },
        }, shift;
}

#--------------------------------------------------------------------------------------------------
# Generate.
#--------------------------------------------------------------------------------------------------
sub Generate
{
  my ($self, $interface) = (shift, HttpServer::GetAddress().'/isis_interface');

  $self->{__xml_file}   = $self->{__anno_file};
  $self->{__xml_file}  .= '.scanlog.xml' unless($self->{__xml_file}  =~ s/\.xml$/\.scanlog\.xml/);
  $self->{__anno_data}  = XMLManip::ParseXMLFile($self->{__anno_file});
  
  $self->{__xml_data}   = new XMLManip::Node('__scanlog', { date => scalar(localtime),
                                                            interface => $interface });

  $self->{__current_node} = new XMLManip::Node('__maincontent', { title => 'Build details',
                                                                  step => $self->{__current_step} });
  
  $self->{__xml_data}->PushChild(new XMLManip::Node('__header', { title => 'Electric Cloud ScanLog',
  	                                                              subtitle => 'Started on '.(localtime) } ));
  
  $self->{__xml_data}->PushChild($self->{__current_node});
  
  $self->{__xml_data}->PushChild(new XMLManip::Node('__footer', { title => 'Generated using ScanLog.pm v'.(ISIS_VERSION),
  	                                                              subtitle => 'Finished on '.(localtime) } ));
  
  $self->__PrintProperties();
  $self->__ParseChilds($self->{__anno_data});
  
  foreach my $child (@{$self->{__xml_data}->Child('__maincontent', 0)->Child('__event')})
  { $self->__DiscardEmptyNodes($self->{__xml_data}->Child('__maincontent', 0), $child); }

  XMLManip::WriteXMLFile($self->{__xml_data}, $self->{__xml_file});
}

#--------------------------------------------------------------------------------------------------
# GenerateDataStructure.
#--------------------------------------------------------------------------------------------------
sub GenerateDataStructure
{
  my ($self, $interface) = (shift, HttpServer::GetAddress().'/isis_interface');
  
  $self->{__anno_data} = XMLManip::ParseXMLFile($self->{__anno_file});
  
  $self->{__xml_data} = new XMLManip::Node('__event', { step => $self->{__current_step} });
  
  $self->{__current_node} = $self->{__xml_data};
  $self->__ParseChilds($self->{__anno_data});
  
  foreach my $child (@{$self->{__xml_data}->Child('__event', 0)->Child('__event')})
  { $self->__DiscardEmptyNodes($self->{__xml_data}->Child('__event', 0), $child); }
  
  return $self->{__xml_data};
}

#--------------------------------------------------------------------------------------------------
# Message types to discard - Avoid big logs.
#--------------------------------------------------------------------------------------------------
sub DiscardMessageTypes
{
  my ($self, $types) = (shift, join('|', @_));
  $self->{__discards} = $types;
}

#--------------------------------------------------------------------------------------------------
# Main parsing function.
#--------------------------------------------------------------------------------------------------
sub __ParseChilds
{
  my ($self, $xmlNode) = (shift, shift);
  
  foreach my $child (@{$xmlNode->Childs()})
  { 
    no strict 'refs';
    my $func = $child->Type();
    $self->$func($child);
  }
}

#--------------------------------------------------------------------------------------------------
# DiscardEmptyNodes.
#--------------------------------------------------------------------------------------------------
sub __DiscardEmptyNodes
{
  my ($self, $parent, $node, $removed) = (shift, shift, shift, 1);

  do
  {
    $removed = 0;
    foreach my $child (@{$node->Child('__event')})
    { $removed += $self->__DiscardEmptyNodes($node, $child); }
  }
  while($removed != 0);
  
  if($node->NbChilds() == 0)
  {
    my $tmp = $parent->NbChilds();
    $parent->RemoveChild($node);
    __ASSERT($parent->NbChilds() < $tmp);
    return 1;
  }
  
  return 0;
}

#--------------------------------------------------------------------------------------------------
# Print build properties.
#--------------------------------------------------------------------------------------------------
sub __PrintProperties
{
  my ($self) = (shift);
  
  my $properties = $self->{__anno_data}->Child('properties')->[0];
  return unless($properties);
  
  my $summaryNode = new XMLManip::Node('__summary');
	$summaryNode->Comment(" +++ SCANLOG SUMMARY +++ ");
	$summaryNode->Attribute('title', "Build ".$self->{__anno_data}->Attribute('id').' '.
	                                 "started on ".$self->{__anno_data}->Attribute('start'));
  
  $summaryNode->PushChild(new XMLManip::Node('__elmt', { tag => 'Cluster Manager',
                                                         val => $self->{__anno_data}->Attribute('cm') }));
  
  foreach my $property (@{$properties->Child('property')})
  {
    my $tag = $property->Attribute('name');
    my $val = $property->Content();
  
    $tag =~ s/([A-Z][a-z]+)/$1 /g; $tag =~ s/ $//;
    $val =~ s/\n$//g; $val =~ s/\n/ /g;
  
  	my $elementNode = new XMLManip::Node('__elmt', { tag => $tag, val => $val });
    $summaryNode->PushChild($elementNode);
  }
  
  $self->{__xml_data}->PushChild($summaryNode);
}

#--------------------------------------------------------------------------------------------------
# make nodes.
#--------------------------------------------------------------------------------------------------
sub make
{
  my ($self, $xmlNode) = (shift, shift);
  ++$self->{__current_step};
  
  my $makeNode = new XMLManip::Node('__event');
  my ($title)  = ($xmlNode->Attribute('cmd') =~ /-f (.*?) /);
  $makeNode->Attribute('title', $title || 'unknown');
  $makeNode->Attribute('time', $self->__make_starttime($makeNode));
  $makeNode->Attribute('step', $self->{__current_step});
  
  push @{$self->{__parent_nodes}}, $self->{__current_node};
  $self->{__current_node}->PushChild($makeNode);
  $self->{__current_node} = $makeNode;
  
  $self->__ParseChilds($xmlNode);
  
  $self->{__current_node} = pop @{$self->{__parent_nodes}};
}

sub __make_starttime
{
  my ($self, $makeNode) = (shift, shift);
  
  my $jobNode  = $makeNode->Child('job')->[0] or return 'unknown';
  my $timeNode = $jobNode->Child('timing')->[0] or return 'unknown';
  return $timeNode->Attribute('invoked') || 'unknown';
}

sub job
{
	my ($self, $jobNode) = (shift, shift);

	foreach my $cmdNode (@{$jobNode->Child('command')})
	{
		foreach my $outputNode (@{$cmdNode->Child('output')})
		{
			next if(($outputNode->Attribute('src') || 'undef') !~ /^prog$/ or
			        not defined $outputNode->Content());
			
			++$self->{__current_step};
			my $timeNode = $jobNode->Child('timing')->[0];
			my $invoked = $timeNode && $timeNode->Attribute('invoked') || 'unknown';
			my $errorNode = $self->__parse_message($outputNode, $invoked);
			
			$self->{__current_node}->PushChild($errorNode) if($errorNode);
		}
	}
}

sub __parse_message
{
  my ($self, $node, $invoked) = (shift, shift, shift);
  my $discards = $self->{__discards};
  
  foreach my $line (split('\n', $node->Content()))
  {
	  foreach my $type (sort keys %{$self->{__message_types}})
	  {
	    my ($__type) = ($type =~ /\d+_(.+)$/);
	    next if($__type =~ /$discards/i);

	    if($self->__match_patterns($line, $self->{__message_types}->{$type}))
	    {
	    	my $msg_node = new XMLManip::Node($__type);
	      $msg_node->Attribute('step', $self->{__current_step});
	      $msg_node->Attribute('time', $invoked);
	      $msg_node->Content( $line );
	      return $msg_node;
	    }
	  }
  }
  return undef;
}

sub __match_patterns
{
  my ($self, $text, $patterns) = (shift, shift, shift);

  foreach my $pattern (@$patterns)
  { return 1 if($text =~ /$pattern/); }
  
  return 0;
}

sub AUTOLOAD
{ # Dummy debug method.
  my ($self, $method, $node) = (shift, our $AUTOLOAD, shift || '');
  warn " called $method : $node\n";
}

1;

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
