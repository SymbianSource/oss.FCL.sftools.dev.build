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

package PathData;

use strict;

#
# Constructor
#

sub New {
  my $pkg = shift;
  my $verbose = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{verbose} = $verbose;
  return $self;
}

#
# Public
#
#

# This function is called by IniData when it comes across an archive_path*
# line. It will only be called once, because the first thing it does
# is reclassify this object as a PathData::ComponentBased or a
# PathData::ProjectBased. Subsequent calls to ProcessLine will therefore
# call the derived class methods.
sub ProcessLine {
  my $self = shift;
  my $keywordref = shift;
  my $lineref = shift;

  $self->SubclassifyMyselfByKeyword($keywordref); # make myself a subclass
  $self->ProcessLine($keywordref, $lineref); 
      # now ask the subclass to process the line
}

sub LocalArchivePathForExistingOrNewComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $project = shift;
  my $result = $self->LocalArchivePathForExistingComponent($comp, $ver, $project);
  $result ||=  $self->LocalArchivePathForNewComponent($comp, $ver, $project);
  return $result;
}

sub LocalArchivePathForNewOrExistingComponent {
  die "You meant LocalArchivePathForExistingOrNewComponent... teehee";
}

# These methods must all be reimplemented by the subclass
sub LocalArchivePathForNewComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $project = shift;
  die "No path data found in reldata.ini. Cannot provide local archive path for new component.\n";
}

sub LocalArchivePathForExistingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  die "No archive found in reldata.ini. Cannot provide local archive path for existing component.\n";
}

sub LocalArchivePathForImportingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $remotepath = shift;
  die "No path data found in reldata.ini. Cannot provide local archive path for importing component.\n";
}

sub RemoteArchivePathForExistingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  die "No path data found in reldata.ini. Cannot provide remote archive path for existing component.\n";
}

sub RemoteArchivePathForExportingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $localpath = shift;
  die "No path data found in reldata.ini. Cannot provide remote archive path for exporting component.\n";
}

sub ListComponents {
  my $self = shift;
  die "No path data found in reldata.ini. Cannot return list of components.\n";
}

sub ListVersions {
  my $self = shift;
  my $comp = shift;
  my $filter = shift;
  die "No path data found in reldata.ini. Cannot return a list of versions.\n";
}

sub ListProjects {
  my $self = shift;
  die "No path data found in reltools.ini. Cannot return list of projects.\n";
}

sub ComponentProjects {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  die "No path data found in reldata.ini. Cannot return which project a component belongs to.\n";
}

sub ComponentProject {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  die "No path data found in reldata.ini. Cannot return which project a component belongs to.";
}

sub ReleaseExists {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  my $relDir = $self->LocalArchivePathForExistingComponent($comp, $ver);
  if ($relDir && -e $relDir) {
    return 1;
  }
  return 0;
}

sub CheckReleaseExists {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  unless ($self->ReleaseExists($comp, $ver)) {
    die "Error: $comp $ver not found\n";
  }
}


#
# Private
#
#

sub SubclassifyMyselfByKeyword {
  my $self = shift;
  my $keywordref = shift;

  if ($$keywordref =~ m/archive_path_file/i) {
    require PathData::ComponentBased;
    bless ($self, "PathData::ComponentBased");
  } elsif ($$keywordref =~ m/archive_path/i) {
    require PathData::ProjectBased;
    bless ($self, "PathData::ProjectBased");
  } else {
    die "Unknown archive_path related keyword: ".$$keywordref."\n";
  }
  print "Using ".(ref $self)." type of archive path arrangement. Keyword was $$keywordref\n" if ($self->{verbose});
}

1;

__END__

=head1 NAME

PathData.pm - Provides the location of archived releases.

=head1 DESCRIPTION

Provides a class to represent knowledge of the archive structure. The class is mostly abstract; however, an object of this class may exist temporarily before it converts itself to a subclass.

=head1 INTERFACE

=head2 New

Expects to be passed a verbosity flag.

=head2 ProcessLine

Processes a line from the C<reltools.ini> file. This will cause the object to bless itself into a subclass, depending on the keyword, then it will ask the subclass to process the line.

=head2 LocalArchivePathForExistingOrNewComponent

This method returns C<LocalArchivePathForExistingComponent>, or failing that, C<LocalArchivePathForNewComponent>.

=head2 ComponentProject

This returns the first item returned by the subclass method C<ComponentProjects>.

=head2 Methods to be implemented by the subclass

All the remaining methods should be implemented by the subclass of the C<PathData>. All of these methods are expected to return the full location where the files should be stored; i.e. local archive paths should end in "\component\version" and remote archive paths should end in "/component".

=head2 LocalArchivePathForNewComponent

This takes a component and a version and (optionally) the name of the project to store the component in.

=head2 LocalArchivePathForExistingComponent

This takes a component and a version.

=head2 LocalArchivePathForImportingComponent

This takes a component, a version, and the remote path where the component was found.

=head2 RemoteArchivePathForExistingComponent

This takes a component, a version and a C<RemoteSite> object.

=head2 RemoteArchivePathForExportingComponent

This takes a component, a version, and the local path where the component was found.

=head2 ListComponents

This may take "1" to indicate that it should list the components stored remotely, not locally.

=head2 ListVersions

This takes a component. It may optionally take a "1" to indicate that it should list the versions stored remotely, not locally. The third parameter is also optional; a regular expression that can be applied to filter the list of versions that is returned.

=head2 ListProjects

=head2 ComponentProjects

This takes a component and a version and returns the project name of all archives where the release is found.

=head2 ComponentProject

This takes a component name and a version and returns the project name of the first archive where the release is found.  It gives the corresponding project name to the path that LocalArchivePathForExistingComponent gives for the same arguments.

=head2 ReleaseExists

Takes a component name and a version number. Return true if the component release is present in the local archive, false otherwise.

=head2 CheckReleaseExists

Takes a component name and a version number. Dies if the component release is not present in the local archive.

=head1 IMPLEMENTATION

=head2 SubclassifyMyselfByKeyword

This will convert the object to either a C<PathData::ProjectBased> or C<PathData::ComponentBased> depending on the keyword passed in.

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
