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

package CatData;

use strict;
use Data::Dumper;
use MrpData;
use PathData;

#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;

  my $iniData = shift;
  my $fileToWriteTo = shift;
  my $mrpData = shift;
  my $category = shift;
  
  $self->{data}->{category} = $category;

  foreach my $exportfile (keys %{$mrpData->ExportInfoForCat($category)}) {
    my $destination = $mrpData->ExportSourceFileInfoForCat($category, $exportfile);

    # Consider any mappings if defined in the reltools.ini file
    if($iniData->HasMappings()){
      $destination = $iniData->PerformReverseMapOnFileName($destination);
      $destination = Utils::RemoveSourceRoot($destination);
    }
    $self->{data}->{exportinfo}->{$exportfile} = $destination;
  }
  
  # Used to write infomation store to to file named $fileToWriteTo
  $self->WriteToFile($fileToWriteTo);
}

sub Open {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{iniData} = shift;
  $self->{comp} = shift;
  $self->{ver} = shift;
  $self->{category} = shift;
  $self->ReadFromFile();
  return $self;
}

sub Category {
  my $self = shift;
  die unless exists $self->{data}->{category};
  return $self->{data}->{category};
}

sub ExportInfo {
  my $self = shift;
  die unless exists $self->{data}->{exportinfo};
  return $self->{data}->{exportinfo};
}

sub ExportSource {
  my $self = shift;
  my $destination = shift;
  die unless exists $self->{data}->{exportinfo}->{$destination};
  return $self->{data}->{exportinfo}->{$destination};
}

#
# Private.
#

sub WriteToFile {
  my $self = shift;
  my $fileToWriteTo = shift;
  
  if (-e $fileToWriteTo) {
    Utils::SetFileWritable($fileToWriteTo);
  }
  open (OUT, ">$fileToWriteTo") or die "Error: Couldn't open \"$fileToWriteTo\" for writing: $!\n";
  print OUT Data::Dumper->Dump([$self->{data}], ['self->{data}']);
  close (OUT);
  Utils::SetFileReadOnly($fileToWriteTo);
}

sub ReadFromFile {
  my $self = shift;
  my $category = $self->{category};
  my $pathData = $self->{iniData}->PathData;
  my $comp = $self->{comp};
  my $ver = $self->{ver};
  
  my $relDir = $pathData->LocalArchivePathForExistingComponent($comp, $ver);
  die "Error: \"$comp $ver\" does not exist\n" unless $relDir;
  if (!-e "$relDir\\exports$category.txt") {
    print "Info: Can't find \"$relDir\\exports$category.txt\" \"$comp $ver\" is an incompatible release\n";
  }
  else{
    $self->{project} = $pathData->ComponentProject($comp, $ver);
    unless (-e $relDir) {
      die "Error: $comp $ver does not exist\n";
    }
    my $file = "$relDir\\exports$category.txt";

    open (IN, $file) or die "Error: Couldn't open \"$file\" for reading: $!\n";
    local $/ = undef;
    my $data = <IN>;
    die "Error: Reldata in \"$relDir\" is blank" unless $data =~ (m/\S/);
    eval ($data) or die "Error: Couldn't parse reldata in \"$relDir\"\n";
    close (IN);
  }
}

1;

=head1 NAME

CatData.pm - Provides an interface to data associated with categories for a release.

=head1 DESCRIPTION

Stores the source and export location of export files in a release. All information is stored in a single file named F<catdata> within the release directory using the module Data::Dumper.

=head1 INTERFACE

=head2 New

Creates a new C<CatData> object and corresponding data file. Expects to be passed a filename to write to, a C<MrpData> reference, and a category.

=head2 Open

Creates a C<CatData> object from an existing data file. Expects to be passed an C<IniData> reference, a component name, a version and a category.

=head2 Category

Returns the category value.

=head2 ExportInfo

Returns the exportinfo.

=head2 ExportSource

Expects an export destination. Returns the export source location.

=head2 WriteToFile

Expects to be passed a filename which is used to write a F<catdata>.

=head2 ReadFromFile

Enables a F<catdata> file to be read so that all infomation contained can be read.

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
