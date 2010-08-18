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
# TableFormatter/Excel.pm
#

package TableFormatter::Excel;

use Utils;
use TableFormatter;
use vars qw/@ISA/;
@ISA = qw(TableFormatter);

use strict;
use Win32::OLE;
use Cwd;

sub New {
  my $class = shift;
  my $iniData = shift;

  if ($iniData->Win32ExtensionsDisabled()) {
    print "Cannot use Excel table format with win32 extensions disabled. It relies on Win32::OLE module to communicate with Excel. If anybody really cares about this, please rewrite the module to use Spreadsheet::WriteExcel... but you'll have to write your own auto-fit engine. Meanwhile, using Text formatting instead.";
    require TableFormatter::Text;
    return TableFormatter::Text->New($iniData);
  }

  return bless {}, (ref $class || $class);
}

sub PrintTable {
  my $self = shift;
  my $data = shift;
  my $doHeading = shift;

  my $excel = new ExcelConnection;

  my $filename = Utils::PrependEpocRoot("\\epoc32\\relinfo\\temp-table.xls");
  my $cwd = cwd;
  $cwd =~ m/^(\w\:)/;
  my $driveletter = $1 || "";
  $filename = "$driveletter$filename";
  unlink ($filename);

  my $wb = $excel->Workbooks->Add;

  my $ws = $wb->Worksheets(1);

  if ($doHeading) {
    my $style = $wb->Styles->Add("Headings");
    $style->{Font}->{Bold} = 1;
    $ws->Rows(1)->{Style} = "Headings";
  }

  for (my $row=0; $row<@$data; $row++) {
    my $rowdata = $data->[$row];
    for (my $col=0; $col<@$rowdata; $col++) {
      my $cell = $ws->Cells($row+1, $col+1);
      my $value = $rowdata->[$col];
      next if ($value eq ""); # otherwise Excel seems to think it's 0
      $cell->{Value} = "'$value";
    }
  }

  $self->DoFinalFormatting($ws);
  # We want to save, because otherwise Excel will prompt whether you
  # want to save when you close the workbook. But on the other hand
  # it prints horrible error messages if there is already a workbook
  # open with the same name.
  # So we need to implement a scheme to give each output workbook
  # a unique name, which means some sort of cleanup mechanism. TODO!
  #eval {
    #$wb->SaveAs($filename);
  #}; # ignore errors, we don't really care.
  $excel->{Visible} = (1);
}

### Private

sub FormatHeadingCell {
  my $self = shift;
  my $cell = shift;
  $cell->{Style}->{Font}->{Bold} = 1;
}

sub DoFinalFormatting {
  my $self = shift;
  my $ws = shift;
  $ws->Columns("A:J")->AutoFit();
}

package ExcelConnection;

sub new {
  my $excel;
  eval {$excel = Win32::OLE->GetActiveObject('Excel.Application')};
  die "Excel not installed" if $@;
  unless (defined $excel) {
      $excel = Win32::OLE->new('Excel.Application', sub {}) or die "Oops, cannot start Excel";
  }
  return $excel;
}

1;

__END__

=head1 NAME

TableFormatter/Excel.pm - Formats tables in Excel

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

