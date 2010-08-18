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

package TableFormatter;

use constant TABLE_MARGIN => 3;

use strict;

sub New {
  my $class = shift;
  my $inidata = shift;
  my $args = shift;
  # SUBCLASSES: don't store $iniData anywhere, because then you'll
  # get a reference loop and a memory leak.

  my $self = bless {}, (ref $class || $class);
  $self->{args} = $args;

  return $self;
}

### Static methods

sub CreateFormatter {
  my $type = shift;
  my $inidata = shift;
  my $args = shift;

  die "Error: couldn't create a formatter without a type" unless $type;

  $type = ucfirst($type);
  my $class = "TableFormatter::$type";
  eval "require $class";
  if ($@) {
    die "Could not load the table formatter \"$class\" for format \"$type\" because $@";
  }
  return $class->New($inidata, $args) or die "Could not create the table formatter \"$class\" for format \"$type\"";
}

### Private

sub FindColWidths {
  my $self = shift;
  my $data = shift;
  my @widths;
  return [] unless defined ($data->[0]);
  my $numCols = scalar(@{$data->[0]});
  for (my $col = 0; $col < $numCols; ++$col) {
    my $width = $self->FindWidestColElement($data, $col);
    $width += TABLE_MARGIN unless ($col == $numCols-1);
    # Don't pad the last column in case it gives us unnecessary line wrapping
    push @widths, $width;
  }
  return \@widths;
}

sub FindWidestColElement {
  my $self = shift;
  my $data = shift;
  my $col = shift;
  my $widest = 0;
  my $numRows = scalar(@{$data});
  for (my $row = 0; $row < $numRows; ++$row) {
    my $this = $data->[$row][$col];
    my $lengthThis = length($this);
    if ($lengthThis > $widest) {
      $widest = $lengthThis;
    }
  }
  return $widest;
}

1;

__END__

=head1 NAME

TableFormatter.pm - An abstract superclass for table formatting classes.

=head1 INTERFACE FOR SUBCLASSES

=head2 New

Creates a formatter.

=head2 PrintTable

Prints a table. Two arguments: firstly, a 2D array of the data. Secondly, a Boolean specifying whether the first row is a header row.

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
