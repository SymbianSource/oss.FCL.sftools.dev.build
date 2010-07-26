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
# Description:
# PathData/ComponentBased.pm
#

package PathData::ComponentBased;
use strict;

BEGIN {
  @PathData::ComponentBased::ISA=('PathData');
};

#
# Public
#
#

sub ProcessLine {
  my $self = shift;
  my $keywordref = shift;
  my $lineref = shift;

  die "Unknown keyword $$keywordref for component-based path data" unless ($$keywordref =~ m/archive_path_file/i);
  print "Warning: Deprecated keyword 'archive_path_file' found.  Support for component-based archives is planned for removal - please see documention for the 'archive_path' keyword for how to use project-based archives.\n"; 

  die "Can't have multiple archive_path_file keywords in reltools.ini." if ($self->{archive_path_file});

  $self->{archive_path_file} = $$lineref; # store the filename, just in case anybody wants to debug us - it might be useful.
  $self->ParsePathData();
}

sub LocalArchivePathForNewComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $project = shift;
  die "Project $project does not make any sense when we are using an archive_path_data.txt file";
  return $self->LocalArchivePath($comp, $ver);
}

sub LocalArchivePathForExistingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  return $self->LocalArchivePath($comp, $ver);
}

sub LocalArchivePathForImportingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $remotepath = shift;
  return $self->LocalArchivePath($comp, $ver);
}

sub RemoteArchivePathForExistingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  return $self->RemoteArchivePath($comp, $ver);
}

sub RemoteArchivePathForExportingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $localpath = shift;
  return $self->RemoteArchivePath($comp, $ver);
}

sub ListComponents {
  my $self = shift;
  my $remote = shift || 0;
  my @comps;
  if ($remote) { # list those in the remote archive
    die "Must pass a remote site object to ListComponents if you want a list of the components on the remote site" unless ref $remote;
    foreach my $location (values %{$self->{remote_archive_path}}) {
      my $list = $remote->DirList($location);
      $location =~ s/\\/\//g;
      foreach (@$list) {
        s/^$location\/?//i;
        push @comps, $_;
      }
    }
  } else { # list those in the local archive
    foreach my $location (values %{$self->{local_archive_path}}) {
      push @comps, @{Utils::ReadDir($location)} if (-d $location);
    }
  }
  return \@comps;
}

sub ListProjects {
  my $self = shift;
  die "Cannot give a list of projects because we are using the component-based style of archive path data.";
}

sub ListVersions {
  my $self = shift;
  my $comp = shift;
  my $remote = shift;
  my $filter = shift;
  my $found;
  if ($remote) { # list those in the remote archive
    die "Must pass a remote site object to ListVersions if you want a list of the versions on the remote site" unless ref $remote;
    my $compDir = $self->GetArchivePath($comp, "remote_archive_path")."/$comp";
    my $files = $remote->DirList($compDir);
    my @results = map { m/\Q$comp\E([^\\\/]*)\.zip/i; $1 } @$files;
    $found = \@results;
  } else { # list those in the local archive
    my $compDir = $self->GetArchivePath($comp, "local_archive_path")."\\$comp";
    return [] unless (-d $compDir);
    $found = Utils::ReadDir($compDir);
  }
  @$found = grep { m/$filter/i } @$found if ($filter);
  return @$found if wantarray;
  return $found;
}

sub ComponentProjects {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  return ("<n/a>");
}

sub ComponentProject {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  return ("<n/a>");
}

#
# Private
#
#
#

sub GetArchivePath {
  my $self = shift;
  my $component = lc(shift);
  my $type = shift;

  die "Couldn't get archive path for undefined component" unless defined $component;
  die unless defined $type;

  if ($self->{$type}->{$component}) {
    return $self->{$type}->{$component};
  }
  elsif ($self->{$type}->{default}) {
    return $self->{$type}->{default};
  }
  else {
    die "Error: archive path not specified for $component\n";
  }
}

sub LocalArchivePath {
  my $self = shift;
  my $component = shift;
  my $ver = shift;

  return $self->GetArchivePath($component, "local_archive_path")."\\$component\\$ver";
}

sub RemoteArchivePath {
  my $self = shift;
  my $component = shift;
  my $ver = shift;

  return $self->GetArchivePath($component, "remote_archive_path")."/$component";
}

sub ParsePathData {
  my $self = shift;

  my $path_file = $self->{archive_path_file};
  
  unless (-f $path_file) {
    die "Error: $path_file not found\n";
  }    
  
  open PATH, "$path_file" or die "Unable to open $path_file for reading\n";

  while (my $line = <PATH>) {
    # Remove line feed, white space and comments.	   
    chomp $line;
    $line =~ s/^\s*$//;
    $line =~ s/#.*//;
    if ($line eq '') {
      # Nothing left.
      next;
    }
    my ($component, $local, $remote) = split (/\s+/, $line, 4);
    $component = lc($component);
    unless ($local and $remote) {
      die "Error: Path not defined for \"$component\" in \"$path_file\"\n";
    }
    if (exists $self->{local_archive_path}->{$component}) {
      die "Error: \"$component\" specified more than once in \"$path_file\"\n";
    }
    $self->{local_archive_path}->{$component} = $local;
    $self->{remote_archive_path}->{$component} = $remote;   
  }  
  close PATH;
}


1;

__END__

=head1 NAME

PathData/ComponentBased.pm - Provides the location of archived releases with an old-style archive arrangement.

=head1 DESCRIPTION

Parses a file containing paths to component release packets on both the local and remote archives.

=head1 INTERFACE

=head2 ProcessLine

This interprets an C<archive_path_file> line from your F<reltools.ini>, and goes away to parse the F<archive_path.txt> file (which it does using the internal method C<ParsePathData>).

The parser expects each line in the file to have the following form: 
 
 <component_name>  <local_archive_path>  <remote_archive_path>

So an example file might have the following structure:

 #
 # App Engines
 #
 agnmodel     X:\ProjectX\appeng      \ProjectX\appeng
 cntmodel     X:\ProjectX\appeng      \ProjectX\appeng
 damodel      X:\ProjectX\appeng      \ProjectX\appeng
 ...
 ...
 #
 # App Framework
 #
 apparc       X:\ProjectX\appframework      \ProjectX\appframework
 eikstd       X:\ProjectX\appframework      \ProjectX\appframework
 etext        X:\ProjectX\appframework      \ProjectX\appframework
 ...
 ...
 #
 # Default path
 #
 default      X:\ProjectX\misc       \ProjectX\misc

The C<default> line is optional (and there should be only one in the file). The C<default> value is the path given to all component releases which are not explicity listed in the file.

[Note: text following a # is treated as a comment]   

=head2 Methods that return paths

All of these methods are expected to return the full location where the files should be stored; i.e. local archive paths should end in "\component\version" and remote archive paths should end in "/component".

=head2 LocalArchivePathForNewComponent

This takes a component and a version and (optionally) the name of the project to store the component in.

=head2 LocalArchivePathForExistingComponent

This takes a component and a version.

=head2 LocalArchivePathForImportingComponent

This takes a component, a version, and the remote path where the component was found.

=head2 RemoteArchivePathForExistingComponent

This takes a component and a version.

=head2 RemoteArchivePathForExportingComponent

This takes a component, a version, and the local path where the component was found.

=head2 ListComponents

This may take "1" to indicate that it should list the components stored remotely, not locally. 

=head2 ListVersions

This takes a component. It may optionally take a "1" to indicate that it should list the versions stored remotely, not locally.

=head2 ListProjects

=head2 ComponentProjects

=head2 ComponentProject

These methods all throw an error, since projects aren't a relevant concept in this type of archive structure.

=head1 IMPLEMENTATION

=head2 LocalArchivePath

Takes a component name. Returns the path of the component release packet on the local archive. Dies if not found.

=head2 RemoteArchivePath

Takes a component name. Returns the path of the component release packet on the remote archive (either an FTP site or a network drive). Dies if not found.

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
