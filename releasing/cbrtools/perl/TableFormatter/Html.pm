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
# TableFormatter/Html.pm
#

package TableFormatter::Html;

use strict;
use Utils;
use TableFormatter;
use vars qw/@ISA/;
@ISA = qw(TableFormatter);

sub PrintTable {
  my $self = shift;
  my $data = shift;
  my $hasHeader = shift;

  my $location = Utils::PrependEpocRoot("\\epoc32\\relinfo\\temp-table.html");
  open(HTML, ">$location") or die "Couldn't open \"$location\" for writing because $!";
  print HTML <<ENDHEAD;
<html>
<head>
  <title>Release tools command output</title>
</head>
<body>
<table border>
ENDHEAD
  foreach my $row (@$data) {
    print HTML "  <tr>\n";
    my $celltype = "td";
    if ($hasHeader) {
      $celltype = "th";
      $hasHeader = 0; # only first row gets header cells
    }
    foreach my $cell (@$row) {
      $cell =~ s/\&/\&amp;/g;
      $cell =~ s/\</\&lt;/g;
      $cell =~ s/\>/\&gt;/g;
      print HTML "  <$celltype>$cell</$celltype>\n";
    }
    print HTML "  </tr>\n";
  }
  print HTML "</table>\n</body>\n</html>\n";
  close HTML;
  system ($location);
}

1;

__END__

=head1 NAME

TableFormatter/Html.pm - Formats tables in HTML format

=head1 INTERFACE

=head2 New

Creates a formatter.

=head2 PrintTable 

Prints the table. Two arguments: firstly, a 2D array of the data. Secondly, a Boolean specifying whether the first row is a header row.

=head1 KNOWN BUGS

The name of this file (i.e. Html.pm) must be in that capitalisation, for IniData.pm to be able to find it.

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
