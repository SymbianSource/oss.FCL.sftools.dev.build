# Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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

package ExportData;
use strict;
use Utils;
use IniData;

use constant BIN_KEYS => 0;
use constant RELDATA_KEYS => 1;
use constant EXP_KEYS => 2;
use constant SRC_KEYS => 3;
use constant SRC_EXP_KEYS => 4;

#
# Constructor
#
sub New {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  my %args = @_;
  my $self = {
	      exportsFile => $args{exports_file},
	      verbose => $args{verbose},
	      iniData => IniData->New(),
	     };
  bless $self, $class;
  
  $self->ParseExportData();
  return $self;
}

#
# Public
#

sub PgpKeysForSource {
  my $self = shift;
  my $component = lc(shift);
  my $category = lc(shift);

  return $self->ReconstructData($component, SRC_KEYS, $category);
}

sub PgpKeysForBinaries {
  my $self = shift;
  my $component = lc(shift);

  return $self->ReconstructData($component, BIN_KEYS);
}

sub PgpKeysForExports {
  my $self = shift;
  my $component = lc(shift);
  my $category = lc(shift);

  return $self->ReconstructData($component, EXP_KEYS, $category);
}

sub PgpKeysForRelData {
  my $self = shift;
  my $component = lc(shift);

  return $self->ReconstructData($component, RELDATA_KEYS);
}

sub AllPgpKeys {
  my $self = shift;
  if (exists $self->{pgpKeys}) {
    return $self->{pgpKeys};
  }
  return [];
}

sub ExportableComponents {
  my $self = shift;

  if (exists $self->{components}) {
    return $self->{components};
  }
  return [];
}

sub ComponentIsExportable {
  my $self = shift;
  my $comp = lc(shift);

  foreach my $exportableComp (@{$self->ExportableComponents()}) {
    if ($comp eq lc($exportableComp)) {
      return 1;
    }
  }
  return 0;
}


#
# Private
#

sub ParseExportData {
  my $self = shift;

  unless ($self->{exportsFile}) {
    die "Error: Export data filename not defined\n";
  }

  open EXPORTS, "$self->{exportsFile}" or die "Error: Unable to open $self->{exportsFile} for reading\n";

  if ($self->{verbose}) {
    print "Parsing export data file $self->{exportsFile} ...\n";
  }

  my $separator = $self->{iniData}->CsvSeparator();

  my $firstRow = 1;
  while (my $row = <EXPORTS>) {
    chomp $row;
    if ($row =~ /^\s*$/ or $row =~ /^[$separator]*#/) {next;}  #ignore empty rows in table
    #handle first non empty row
    if ($firstRow) {
      $self->HandleFirstRow($row);
      $firstRow = 0;
    }
    #handle subsequent non empty rows
    else {
      $self->HandleRow($row);
    }
  }
  close EXPORTS;
}

sub HandleFirstRow {
  my $self = shift;
  my $row = shift;

  #parse row of delimiter-separated values
  my @cols = $self->ParseCSV($row);

  for (my $i = 1; $i <= $#cols; ++$i) {
    my $cell = $cols[$i];
    if (defined $cell) {
      Utils::StripWhiteSpace(\$cell);
      my ($pgpKeyid) = ($cell =~ /\b(0X[0-9a-fA-F]{8})\b/i);
      unless ($pgpKeyid) {
	die "Error: PGP key ID of the correct format not defined in column header \"$cell\"\n";
      }
      push @{$self->{pgpKeys}}, $pgpKeyid;
      push @{$self->{nonemptyColumns}} ,$i;
    }
    else {
      die "Error: Undefined PGP key in ".$self->{exportsFile}." file.\n";
    }
  }
}

sub HandleRow {
  my $self = shift;
  my $row = shift;

  $row = lc($row);

  #parse row of delimiter-separated values
  my @cols = $self->ParseCSV($row);

  my $component = $cols[0];
  Utils::StripWhiteSpace(\$component);
  if ($component =~ /^\s*$/) {
    die "Error: Export table has wrong format. Must have component name in first column.\n";
  }
  push @{$self->{components}}, $component;

  #iterate over columns which have a nonempty recipient heading and store cell data
  my @cells = @cols[@{$self->{nonemptyColumns}}];
  for (my $j = 0; $j < @cells; ++$j) {
    $self->HandleCell($component, $j, $cells[$j]); #$j is the PGP array index
  }
}

sub HandleCell {
  my $self = shift;
  my $component = shift;
  my $pgpKeyIndex = shift;
  my $cell = shift;
  
  my $pgpKey = $self->{pgpKeys}->[$pgpKeyIndex];

  # cell must not be undef but may be blank
  if (!defined $cell) {
    $cell = '';
  }

  if ($cell =~ /exclude(?!_)/i) {
    # Cells containing 'exclude' must not have _any_ release files of this
    # component exported to this recipient.  However if only you want to stop
    # binaries, use exclude_bin
    return;
  }

  # Other cells must have the recipient's key added to 'relDataPgpKeys' and
  # possibly also 'srcPgpKeys', 'expPgpKeys or 'binPgpKeys' for this component.
  # Concatenating the string save memory, over using an array
  $self->{keys}->{$component}->[RELDATA_KEYS] .= "$pgpKeyIndex,";

  # Include binaries unless 'exclude_bin'
  if ( $cell !~ s/exclude_bin//i ) {
    $self->{keys}->{$component}->[BIN_KEYS] .= "$pgpKeyIndex,";
  }

  # Identify any S() or E() blocks
  my %blocks;
  while ($cell =~ s/([a-z])\((.*?)\)//i) {
    if (!defined $blocks{$1}) {
      $blocks{$1} = [$1, $2];
    } else {
      die "Error: Export table has wrong format. Multiple $1() blocks found in cell for component '$component', PGP key '$pgpKey'\n";
    }
  }

  foreach my $block (keys(%blocks)) {
    my ($origblock, $cats) = @{$blocks{$block}};
    my $type;
    if ($block eq "s") {
      $type = SRC_KEYS;
    } elsif ($block eq "e") {
      $type = EXP_KEYS;
    }
    if (defined $type) {
      while ($cats =~ s/([a-z]-[a-z]|\S)//i) { # a letter range (e.g. A-Z) or any non whitespace character
        my $cat = $1;
        
        if ($cat =~ /(.)-(.)/) {
          my ($from, $to) = ($1, $2);
      
          foreach my $cat (ord($from)..ord($to)) { # convert the characters to numbers so that we can do a foreach on the range
            $cat -= 96;
            $self->{keys}->{$component}->[$type]->[$cat] .= "$pgpKeyIndex,";
          }
        }
        elsif ($cat =~ /^[a-z]$/i) {
          $cat = ord($cat) - 96;         
          $self->{keys}->{$component}->[$type]->[$cat] .= "$pgpKeyIndex,";
        } else {
          die "Error: Export table has wrong format. '$cat' is not a valid IPR category in cell for component '$component', PGP key '$pgpKey'\n";
        }
      }
    } else {
      die "Error: Export table has wrong format. '$origblock()' is not a valid construct in cell for component '$component', PGP key '$pgpKey'\n";
    }
  }

  # Handle any 'old format' IPR categories not in blocks
  while ($cell =~ s/([a-z]-[a-z]|\S)//i) { # a letter range (e.g. A-Z) or any non whitespace character
    my $cat = $1;

    if ($cat =~ /(.)-(.)/) {
      my ($from, $to) = ($1, $2);

      foreach my $cat (ord($from)..ord($to)) { # convert the characters to numbers so that we can do a foreach on the range
        $cat -= 96;
        $self->{keys}->{$component}->[SRC_EXP_KEYS]->[$cat] .= "$pgpKeyIndex,";
      }
    }
    elsif ($cat !~ /^[a-z]$/i) {
      die "Error: Export table has wrong format. '$cat' is not a valid IPR category in cell for component '$component', PGP key '$pgpKey'\n";
    }
    else {
      $cat = ord($cat) - 96;
      $self->{keys}->{$component}->[SRC_EXP_KEYS]->[$cat] .= "$pgpKeyIndex,";
    }
  }
}

sub ParseCSV {
  my $self = shift;
  my $text = shift;      # record containing delimited-separated values
  my @new ;
  
  my $separator = $self->{iniData}->CsvSeparator();
  
  while ($text =~ m{"([^\"\\]*(?:\\.[^\"\\]*)*)"$separator?|([^$separator]+)$separator?|$separator}gx) {
    push(@new, $+);
  }
  
  push(@new, undef) if substr($text, -1,1) eq $separator;

  return @new;      # list of values that were delimited-separated
}

sub ReconstructData {
  my $self = shift;
  my $component = shift;
  my $type = shift;
  my $category = shift;
  
  if ($category) {
    $category = ord($category) - 96;
  }

  if (defined $self->{keys}->{$component}) {
    my @results;
    my @pgpKeysIndex;
  
    if ($type == EXP_KEYS || $type == SRC_KEYS) {
      # Gets a list of the src or export keys, as well as the list of keys in both source and exports.
      # Splits the key indexes on ,
      if (defined $self->{keys}->{$component}->[$type]->[$category]) {
        @pgpKeysIndex = split /,/, $self->{keys}->{$component}->[$type]->[$category];
      }
      if (defined $self->{keys}->{$component}->[SRC_EXP_KEYS]->[$category]) {
        push @pgpKeysIndex, split /,/, $self->{keys}->{$component}->[SRC_EXP_KEYS]->[$category];
      }
    }
    else { # BIN or RELDATA
      @pgpKeysIndex = split /,/, $self->{keys}->{$component}->[$type]
    }
    
    @results = map $self->{pgpKeys}->[$_], @pgpKeysIndex;
    return \@results;
  }
  
  return [];
}

1;

__END__

=head1 NAME

ExportData.pm - Provides an interface to the contents of the project's export data file.

=head1 DESCRIPTION

A module used for accessing export restriction information for a component release.

=head1 INTERFACE

=head2 New

Passed a named parameter list in the form of hash key value pairs:

 exportsFile => $export_data_filename
 verbose     => $integer_verbosity_value

Opens and parses the export data file which should contain lines of delimiter separated values representing a table of component name rows and recipient columns, as in the example below:

             | pgpkeyid_1 (recipient) | pgpkeyid_2 (recipient) | pgpkeyid_3 (recipient) |
 ------------+------------------------+------------------------+------------------------+--
 component_1 |           DE           |            E           |          CDE           |
 ------------+------------------------+------------------------+------------------------+--
 component_2 |          S(CDE) E(DE)  |                        |           DE           |
 ------------+------------------------+------------------------+------------------------+--
 component_3 |           D-G  T       |           A-F          |         exclude        |
 ------------+------------------------+------------------------+------------------------+--
 component_4 |  exclude_bin DEFG      |       DEFG             |       DEFG             |



The column headers must contain the recipients PGP key ID - an eight digit hexadecimal number preceeded by C<0x> (e.g C<0xD9A2CE15>). This public PGP key will be used to encrypt all files sent to the recipient. The name of the recipient may also be included in the column header although this is not mandatory.

A cell contains a list of IPR categories available to the recipient of the component.
 Each category must be a single letter or digit or a range (e.g. A-Z). Empty cells imply that the recipient
 does not have access to any source for the corresponding component but can still receive
binaries.

Alternatively, different categories may be specified for source files and export files, using the S(...) and E(...) notations respectively, with '...' being a list of IPR categories.

To prevent a recipient from receiving both source and binaries for the corresponding component, use the keyword C<exclude>. This can be useful when certain recipients may receive releases of some but not all components.

To prevent a recipient from receiving binaries for the corresponding component, use the keyword C<exclude_bin>. Unlike C<exclude>, this does not break any environment.

Components which are not listed in the table but exist on the local site will not be exported to any recipients. However, a warning will be issued to alert the exporter of this situation.

If a licensee or third party does not use C<DISTRIBUTION.POLICY> files to categorize source then all source will have the category X. In this case, putting X in a cell implies that all source for that component will be sent to the recipient, otherwise none will be sent.

Lines starting with a C<#> are treated as comments and ignored.

[NOTE: It is recommended that this file is created and maintained using a spreadsheet
application (saving as a CSV file) rather than editing it directly.]

If your CSV file does not use a comma ',' as the separator you will need to specify the required
separator in your reltools.ini, using the syntax F<csv_separator <separator>>, e.g. F<csv_separator ;>.

=head2 PgpKeysForRelData

Expects a component name. Returns a reference to an array of public PGP key ids (corresponding to different
recipients) to be used to encrypt the component's reldata.

=head2 PgpKeysForSource

Expects a component name and a source category. Returns a reference to an array of public PGP
 key ids (corresponding to different recipients) to be used to encrypt the component's source of
 this category.

=head2 PgpKeysForBinaries

Expects a component name. Returns a reference to an array of public PGP key ids (corresponding to different
recipients) to be used to encrypt the component's binaries.

=head2 PgpKeysForExports

Expects a component name and an IPR category. Returns a reference to an array of public PGP
 key ids (corresponding to different recipients) to be used to encrypt the component's exports of
 this category.

=head2 AllPgpKeys

Returns a reference to an array of all PGP key IDs listed in the export table.

=head2 ExportableComponents

Returns a reference to an array of all the components listed in the export table

=head2 ComponentIsExportable

Expects to be passed a component name. Returns true if the component is listed in the
export table.

=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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
