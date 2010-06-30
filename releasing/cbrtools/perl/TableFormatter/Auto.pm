# Copyright (c) 2002-2009 Nokia Corporation and/or its subsidiary(-ies).
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
#
# Description:
# TableFormatter/Text.pm
#

package TableFormatter::Auto;

use constant MAX_WIDTH => 75;
use constant MAX_ROWS => 10;

use strict;
use TableFormatter;
use TableFormatter::Text;
use vars qw/@ISA/;

@ISA = qw(TableFormatter);

sub New {
  my $class = shift;
  my $inidata = shift;
  my $args = shift;
  
  my ($complex, $complexargs) = $args =~ m/^(\w+)\s*(.*)/;
  my $self = bless {}, (ref $class || $class);

  $self->CreateFormatters($complex, $inidata, $complexargs);

  return $self;
}

sub PrintTable {
  my $self = shift;
  my $data = shift;
  my $doHeading = shift;

  my $usecomplex = $self->UseComplexFormatter($data);

  my $formatter = ($usecomplex?$self->{complex}:$self->{simple});
  return $formatter->PrintTable($data, $doHeading);
}

## Private

sub CreateFormatters {
  my $self = shift;
  my $complex = shift;
  my $inidata = shift;
  my $complexargs = shift;

  $self->{complex} ||= TableFormatter::CreateFormatter($complex, $inidata, $complexargs);
  $self->{simple} ||= TableFormatter::Text->New($inidata);
}

sub UseComplexFormatter {
  my $self = shift;
  my $data = shift;

  # Currently {maxrows} and {maxwidth} are unused
  my $maxrows = $self->{maxrows} || MAX_ROWS;
  my $maxwidth = $self->{maxwidth} || MAX_WIDTH;

  return 1 if (@$data > $maxrows);
  return 1 if ($self->TotalWidth($data) > $maxwidth);
  return 0;
}

sub TotalWidth {
  my $self = shift;
  my $data = shift;
  
  my $widths = $self->FindColWidths($data);
  my $total = 0;
  $total += $_ foreach (@$widths);
  return $total;
}

1;

__END__

=head1 NAME

TableFormatter/Text.pm - Formats tables in text

=head1 INTERFACE

=head2 New

Creates a formatter.

=head2 PrintTable 

Prints the table. Two arguments: firstly, a 2D array of the data. Secondly, a Boolean specifying whether the first row is a header row.

=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2002-2009 Nokia Corporation and/or its subsidiary(-ies).
 All rights reserved.
 This component and the accompanying materials are made available
 under the terms of the License "Eclipse Public License v1.0"
 which accompanies this distribution, and is available
 at the URL "http://www.eclipse.org/legal/epl-v10.html".
 
 Initial Contributors:
 Nokia Corporation - initial contribution.
 
 Contributors:
 
 Description:
 

=cut
