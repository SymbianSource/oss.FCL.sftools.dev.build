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
# Name   : Makefile.pm
# Path   : \isis_sw\isis_scripts\packages\ISIS\
# Use    : Generate makefiles.

#
# Synergy :
# Perl %name: Makefile.pm % (%full_filespec: Makefile.pm-3:perl:fa1s60p1#1 %)
# %derived_by: oligrant %
# %date_created: Wed Apr  5 13:29:30 2006 %
#
# Version History :
# v1.0.1 (23/01/2006) :
#  - Added check to avoid printing out empty rules.
#
# v1.0.0 (20/01/2006) :
#  - First version of the module.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   Makefile package.
#
#--------------------------------------------------------------------------------------------------

package Makefile;

use strict;
use warnings;
use ISIS::ErrorDefs;
use ISIS::Assertion _Debug => 1;

use constant ISIS_VERSION     => '1.0.1';
use constant ISIS_LAST_UPDATE => '23/01/2006';

sub new
{
  my ($class, $filename) = (shift, shift);
  
  bless { __filename  => $filename,
          __variables => {},
          __rules     => [],
          __gbl_id    => 0,
        }, $class;
}

sub Name { $_[0]->{__filename} }

sub NewRule
{
  my ($self, $rule) = (shift, __Rule->new(@_));
  return undef unless($rule->{__rule_name});
  push @{$self->{__rules}}, $rule;
  return $rule;
}

sub SetVariable
{
  my ($self, $name, $value) = (shift, shift, join('', @_));
  $self->{__variables}->{$name} = $value;
}

sub RulesFromTemplate
{
  my ($self, $name, $args, $maxIndex, @templates) = (shift, shift, pop || {}, 0, @_);
  
  foreach my $arg (sort keys %$args)
  {
    __ASSERT(ref $$args{$arg} eq 'ARRAY' or
             ref $$args{$arg} eq 'SCALAR' or
             ref $$args{$arg} eq '');

    if(ref $$args{$arg} eq 'SCALAR' or ref $$args{$arg} eq '')
    {
      my @array = ($$args{$arg});
      $$args{$arg} = \@array;
    }
    else
    {
      my $tmp = scalar @{$$args{$arg}} - 1;
      __ASSERT($tmp == 0 or $tmp == $maxIndex);
      $maxIndex = $tmp if($maxIndex < $tmp);
    }
  }

  my $mainRule = $self->NewRule($name);
  $mainRule->AddDependancy(join(' ', map { 'id'.$_ } ($self->{__gbl_id} .. $self->{__gbl_id} + $maxIndex)));

  for my $i (0 .. $maxIndex)
  {
  	my $rule = $self->NewRule('id'.$self->{__gbl_id});
	  ++$self->{__gbl_id};

  	foreach my $template (@templates)
		{
			my $tmp = $template;
	    foreach my $arg (sort keys %$args)
	    {
	      my $value = (@{$$args{$arg}} == 1 ? $$args{$arg}->[0] : $$args{$arg}->[$i]);
	      $tmp =~ s/\$$arg/$value/g;
	    }

	    $rule->AddCmdLine($tmp);
	  }
  }
}

sub Generate
{
  my ($self, $error) = (shift, 0);

  open(MAKEFILE, ">".$self->{__filename}) or return ERR::FILE_CREATION_FAILED;

  foreach my $var (sort keys %{$self->{__variables}})
  { print MAKEFILE $var, " = ", $self->{__variables}->{$var}, "\n"; }

  print MAKEFILE "\n";

  foreach my $rule (@{$self->{__rules}})
  { $rule->Print(\*MAKEFILE); }

  close(MAKEFILE);
  return ERR::NO_ERROR;
}

1;

#--------------------------------------------------------------------------------------------------
#
#   __Rule package.
#
#--------------------------------------------------------------------------------------------------

package __Rule;

use strict;
use warnings;

sub new
{
  my ($class, $name, @dependancies) = (shift, shift, @_);
  
  bless { __command_lines => [],
          __dependancies  => \@dependancies,
          __rule_name     => $name,
        }, $class;
}

sub AddCmdLine    { push @{shift->{__command_lines}}, join('', @_); }
sub AddDependancy { push @{shift->{__dependancies}}, @_; }

sub Print
{
  my ($self, $fh) = (shift, shift);
  
  return if(@{$self->{__dependancies}} == 0 and @{$self->{__command_lines}} == 0);
  
  print $fh $self->{__rule_name}, ": ", join(' ', @{$self->{__dependancies}}), "\n";

  foreach my $cmd (@{$self->{__command_lines}})
  { print $fh "\t", $cmd, "\n"; }
  
  print $fh "\n";            
}

1;

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
