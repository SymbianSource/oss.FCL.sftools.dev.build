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
# Name   : ScanLogTBS.pm
# Path   : N:\isis_scripts\packages\ISIS\
# Use    : .

#
# Synergy :
# Perl %name: ScanLogTBS.pm % (%full_filespec: ScanLogTBS.pm-2:perl:fa1s60p1#1 %)
# %derived_by: wbernard %
# %date_created: Tue May  9 08:29:21 2006 %
#
# Version History :
#
# v1.0.1 (09/05/2006) :
#  - Fix for compatibility with pseudo EBS logs of EC builds.
#
# v1.0.0 (30/01/2006) :
#  - First version of the module.
#	 - Generate directly XML nodes compatible with the logger
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   ScanLog package.
#
#--------------------------------------------------------------------------------------------------

package ScanLogTBS;

use strict;
use warnings;
use ISIS::Assertion _DEBUG => 1;
use ISIS::XMLManip;
use ISIS::HttpServer;

use constant ISIS_VERSION     => '1.0.1';
use constant ISIS_LAST_UPDATE => '09/05/2006';

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
#
#	$logname path to the log
# $fast option (on|off) (optional parameter)
#--------------------------------------------------------------------------------------------------
sub new
{
	my ($class, $logname, $fast) = (shift, shift, shift||'off');
	my $self = {__logname  => $logname,
							__currentcomponent => undef,
							__currentcomponent_command => undef,
							__fast => $fast,
          		__message_types => { '1_remark'  => \@__remark_patterns,
                               '2_ignore'  => \@__ignore_patterns,
                               '3_warning' => \@__warning_patterns,
                               '4_error'   => \@__error_patterns,
                             },
						};
  bless $self, $class;
}

#--------------------------------------------------------------------------------------------------
# Generate.
#--------------------------------------------------------------------------------------------------
sub GenerateDataStructure
{
  my $self = shift;
  
	my $interface = HttpServer::GetAddress().'/isis_interface';
	
	$self->{ __xml_data } = new XMLManip::Node('__event', { title => "ScanLog" });
	
	unless (open (LOG, $self->{__logname}))	{OUT2XML::Error("Cannot open ".$self->{__logname}); return 0;};
	my $line;
  while ($line=<LOG>)
  {

    # Hostname is
    # capture the hostname if available
    if ($line =~ /^Hostname is (.*)$/)
    {
      $self->{ _hostname } = "$1";
    }

		
		#++ Finished at Wed Feb  8 19:55:33 2006
		if ( $line =~ /^\+\+\s+Finished\s+at(.*)/ )
		{
			$self->{ __currentcomponent } = undef;
			$self->{ __currentcomponent_command } = undef;
			next;
		}
		
		
		#++ Started at Wed Feb  8 19:55:32 2006
		#+++ HiRes Start 1139428532.36375
		if ( $line =~ /^\+\+\+\s+HiRes\s+Start\s+(\d+)/ and $self->{ __currentcomponent } )
		{
			$self->{ __currentcomponent_starttime }= $1;
		}
		
		#+++ HiRes End 1139428533.39499
		if ( $line =~ /^\+\+\+\s+HiRes\s+End\s+(\d+)/ and $self->{ __currentcomponent } )
		{
			$self->{ __currentcomponent_endtime }= $1;
		}
		
		#-- bldmake bldfiles -k
		if ( $line =~ /^\-\-\s+(.*)/ and $self->{ __currentcomponent } )
		{
				if ($self->{__fast} eq "on")
				{
					my $p = new XMLManip::Node('__print');
					$p->Content("<b>$1</b><br/>");
					$self->{ __currentcomponent }->PushChild( $p );
					$self->{ __currentcomponent_command } = $self->{ __currentcomponent };
					
				}
				else
				{
					$self->{ __currentcomponent_command } = new XMLManip::Node('__event',{ title => "$1"});
					$self->{ __currentcomponent }->PushChild( $self->{ __currentcomponent_command } );
				}
				next;
		}

		#--- Client8 Executed ID 2
		if ( $line =~ /^\-\-\-\s+(\w+)\s+Executed\s+ID\s+(\d+)/ and $self->{ __currentcomponent_command } )
		{
				$self->{ __currentcomponent_command }->Attribute( 'step', "$2" );
				next;
		}

		#Chdir \s60\Cdl\CdlCompiler\group
		if ( $line =~ /^Chdir\s+(.*)/ and $self->{ __currentcomponent } )
		{
				#$self->{ __currentcomponent_command }->( 'step', "$2" );
				next;
		}
		
		
		# === Stage=2 == CdlCompiler
		if ( $line =~ /^===\s+Stage=(\d+)\s+==\s+(.*)/  )
		{
			unless ( $self->{ __currentcomponent } )
			{
				my $name = "$2";
				if ( $self->{ _components }{ "$name" } )
				{
					$self->{ __currentcomponent } = $self->{ _components }{ "$name" };
				}
				else
				{
					$self->{ __currentcomponent } = new XMLManip::Node('__event',{ title => "$name"});
					$self->{ _components }{ "$name" } = $self->{ __currentcomponent };
					$self->{ __xml_data }->PushChild( $self->{ __currentcomponent } );
				}
			}
			next;			
		}		

		if ( $self->{ __currentcomponent_command } and $self->{ __currentcomponent } )
		{		
			my $n = $self->__parse_message( $line );
		}
	}
	close (LOG);
		
	return $self->{ __xml_data };
}


sub __parse_message
{
  my ($self, $line) = (shift, shift);
  

  foreach my $type (sort keys %{$self->{__message_types}})
  {
    my ($__type) = ($type =~ /\d+_(.*)$/);
    if($self->__match_patterns($line, $self->{__message_types}->{$type}))
    {
		  my $msg_node = new XMLManip::Node( "$__type" );
      $msg_node->Attribute('time', $self->{ __currentcomponent_starttime });
      $msg_node->Content( $line );
      $self->{__currentcomponent_command}->PushChild( $msg_node );
      return $msg_node;
    }
  }
  
  return undef;
}

sub __match_patterns
{
  my ($self, $line, $patterns) = (shift, shift, shift);

  foreach my $pattern (@$patterns)
  { return 1 if($line =~ /$pattern/); }
  
  return 0;
}


1;

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
