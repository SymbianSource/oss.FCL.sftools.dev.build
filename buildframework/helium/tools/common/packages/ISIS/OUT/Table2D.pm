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
#!/usr/bin/perl -w
#--------------------------------------------------------------------------------------------------
# Name   : Table2D.pm
# Use    : Fast simple HTML table of any dimension.

#
# Synergy :
# Perl %name: Table2D.pm % (%full_filespec:  Table2D.pm-3:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Mon Feb  6 13:34:47 2006 %
#
# Version History :
# v1.1.0 (01/02/2006)
#  - Added 'SetColumnAttr', 'SetRowAttr', 'SetCellAttr' subroutines to Table2D.
#
# v1.0.0 (24/11/2005)
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

package OUT::Table2D;

use strict;
use warnings;
use ISIS::OUT::Outputer;
use ISIS::OUT::Debug;

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::Table2D( ", join(', ', @_), " )\n" if(DBG::TABLE2D);
  
  my ($class, $outputer, $lines) = (shift, pop, shift || {});
  
  $outputer->RequireCSSFile('css/logger2.css');
  
  my $self = bless { width     => 0,
                     height    => 0,
                     _childs   => undef,
                     _widths   => undef,
                     _outputer => $outputer,
                   }, $class;
  
  foreach (sort keys %{$lines}) { $self->AddLine($_, ${$lines}{$_}); }
  
  return $self;
}

#--------------------------------------------------------------------------------------------------
# AddLine
#--------------------------------------------------------------------------------------------------
sub AddLine
{
  warn "OUT::Table2D::AddLine( ", join(', ', @_), ")\n" if(DBG::TABLE2D);
  my $self     = shift;
  my $outputer = $self->{_outputer};

  my @line = map { ref $_ eq '' ? $outputer->Create('Text', $_) : $_ } @_;
  push @{$self->{_childs}}, \@line;

	my @attrs = map { {} } @_;
	push @{$self->{_attrs}}, \@attrs;

  $self->{width} = scalar(@_) if(scalar(@_) > $self->{width});
  ++$self->{height};
}

sub SetRowAttr
{
	my ($self, $idx, $attrs) = (shift, shift, shift);
	
	foreach my $rowAttr (@{$self->{_attrs}->[$idx]})
	{ 
		foreach my $attr (keys %$attrs)
		{ print $$attrs{$attr}, "\n"; $$rowAttr{$attr} = $$attrs{$attr}; }
	}
}

sub SetColumnAttr
{
	my ($self, $idx, $attrs) = (shift, shift, shift);
	
	foreach my $columnAttr (@{$self->{_attrs}})
	{ 
		foreach my $attr (keys %$attrs)
		{ $columnAttr->[$idx]->{$attr} = $$attrs{$attr}; }
	}
}

sub SetCellAttr
{
	my ($self, $col, $row, $attrs) = (shift, shift, shift, shift);
	
	foreach my $attr (keys %$attrs)
	{ $self->{_attrs}->[$col]->[$row]->{$attr} = $$attrs{$attr}; }
}

#--------------------------------------------------------------------------------------------------
# Print
#--------------------------------------------------------------------------------------------------
sub Print
{
  warn "OUT::Table2D::Print( ", join(', ', @_), " )\n" if(DBG::TABLE2D);
	my $self     = shift;
	my $outputer = $self->{_outputer};
	my $indent   = $outputer->Indent();

  $outputer->Print("<div class=\"t_wrapper\">\n",
                   "  <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\" width=\"100%\">\n"
                  );

	for my $col (0 .. $#{$self->{_childs}})
	{
		$outputer->Print("    <tr>\n");
		
		for my $row (0 .. $#{$self->{_childs}->[$col]})
		{
			my $attrs = $self->{_attrs}->[$col]->[$row];
			if(keys %$attrs)
			{
				$outputer->Print("      <td ", join(' ', map { "$_=\"".$attrs->{$_}."\"" } keys %$attrs), ">\n");
			}
			else
			{
				$outputer->Print("      <td>\n");
			}
			
			$outputer->Indent($indent . '        ');
			$self->{_childs}->[$col]->[$row]->Print();
			$outputer->Indent($indent);
			$outputer->Print("      </td>\n");
		}
		
		$outputer->Print("    </tr>\n");
	}
	
	$outputer->Print("  </table>\n",
	                 "</div>\n"
	                );
}

#--------------------------------------------------------------------------------------------------
# Accessor.
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	warn "$method( ".join(', ', @_)." )\n" if(DBG::TABLE2D);
	$self->{_outputer}->_Accessor($self, $method, @_);
}

1;

__END__

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
