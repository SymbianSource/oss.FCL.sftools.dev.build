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

package TableFormatter::Text;

use strict;
use TableFormatter;
use vars qw/@ISA/;
@ISA = qw(TableFormatter);

sub PrintTable {
  my $self = shift;
  my $data = shift;
  my $doHeading = shift;
  unless (defined $doHeading) {
    $doHeading = 0;
  }

  my $colWidths = $self->FindColWidths($data);
  my $numRows = scalar(@$data);
  for (my $row = 0; $row < $numRows; ++$row) {
    if ($doHeading and $row == 1) {
      print "\n";
    }
    $self->PrintRow($data, $colWidths, $row);
  }  
}

## Private

sub PrintRow {
  my $self = shift;
  my $data = shift;
  my $colWidths = shift;
  my $row = shift;
  my $numCols = scalar(@{$data->[$row]});
  for (my $col = 0; $col < $numCols; ++$col) {
    my $this = $data->[$row][$col];
    $this = '<UNDEFINED>' unless defined $this;
    print $this, ' ' x ($colWidths->[$col] - length($this));
  }
  print "\n";
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
