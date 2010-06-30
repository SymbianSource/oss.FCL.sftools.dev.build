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
# TableFormatter/Csv.pm
#

package TableFormatter::Csv;

use strict;
use Utils;
use TableFormatter;
use vars qw/@ISA/;
@ISA = qw(TableFormatter);

sub PrintTable {
  my $self = shift;
  my $data = shift;
  my $location = Utils::PrependEpocRoot("\\epoc32\\relinfo\\temp-table.csv");
  open(CSV, ">$location") or die "Couldn't open \"$location\" for writing because $!";
  foreach my $row (@$data) {
    my $rowtext = "";
    foreach my $cell (@$row) {
      $cell =~ s/\"/\\\"/g;
      $cell =~ s/(.*)/\"$1\"/ if $cell =~ m/[\,\"]/;
      $rowtext .= $cell . ",";
    }
    chop $rowtext;
    print CSV "$rowtext\n";
  }
  close CSV;
  system ($location);
}

1;

__END__

=head1 NAME

TableFormatter/Csv.pm - Formats tables in text

=head1 INTERFACE

=head2 New

Creates a formatter.

=head2 PrintTable 

Prints the table. Two arguments: firstly, a 2D array of the data. Secondly, a Boolean specifying whether the first row is a header row.

=head1 KNOWN BUGS

The name of this file (i.e. Csv.pm) must be in that capitalisation, for IniData.pm to be able to find it.

No actual bugs.

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
