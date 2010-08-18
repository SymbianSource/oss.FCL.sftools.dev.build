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
# PathData/ProjectBased.pm
#

package PathData::ProjectBased;
use Utils;
use Carp;
use File::Spec;
use strict;

BEGIN {
  @PathData::ProjectBased::ISA=('PathData');
};

#
# Public
#
#

sub ProcessLine {
  my $self = shift;
  my $keywordref = shift;
  my $lineref = shift;

  die "Unknown keyword $$keywordref for project-based path data" unless ($$keywordref =~ m/archive_path/i);
  $$lineref =~ m/(\S+)\s+(\S+)(?:\s+(\S*))?/ or die "Error: Couldn't cope with archive path arguments \"$$lineref\": possibly the wrong number of arguments?\n";
  my $entry = {
    'name' => lc $1,
    'local' => $2,
    'remote' => $3
  };
 

  $self->{project_paths} ||= []; # I know this line is redundant, but I prefer explicitness :-)
  die "You cannot have multiple archive_path lines with the same project name (".$entry->{name}.")" if (grep { $_->{name} eq $entry->{'name'} } @{$self->{project_paths}});
  # You are allowed to have multiple lines with the same local and/or remote path lines,
  # but it ain't necessarily a good plan.
  push @{$self->{project_paths}}, $entry;
}

sub LocalArchivePath {
  my $self = shift;
  my $project = shift;
  my $result;
  $self->BasicChecks();

  if(defined $project){
    $self->CheckProject($project);
    $result = $self->FindEntry("name", $project);
  }
  else{
    $result = $self->FindEntryWithSub(sub { -d ($_->{'local'})});
  }
  
  return undef unless $result;
  print "Existing component stored at $result\n" if ($self->{verbose});
  return $result->{'local'};
}

sub LocalArchivePathForNewComponent {
  my $self = shift;
  my $comp = shift || confess "No component provided";
  my $ver = shift || confess "No version provided";
  my $project = shift;
  $self->BasicChecks();

  my $result;
  if (defined $project) {
    $self->CheckProject($project);
    $result = $self->FindEntry("name", $project);
  } else {
    $result = $self->{project_paths}->[0];
  }
  die "Error: No archive paths found\n" unless $result; # should never happen due to BasicChecks
  $self->CreateLocalDirectory($result);
  $result = $result->{'local'};
  print "New component being stored at $result\n" if ($self->{verbose});
  return $result . "\\$comp\\$ver";
}

sub LocalArchivePathForExistingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $project = shift;
  
  my $result;
  
  $self->BasicChecks();
  confess "Component name undefined" unless defined $comp;
  confess "Version number undefined" unless defined $ver;

  if(defined $project){
    $self->CheckProject($project);
    $result = $self->FindEntry("name", $project);
  }
  else{
    $result = $self->FindEntryWithSub(sub { -d ($_->{'local'}.'\\'.$comp.'\\'.$ver)});
  }
  
  return undef unless $result;
  print "Existing component stored at $result\n" if ($self->{verbose});
  return $result->{'local'} . "\\$comp\\$ver";
}

sub LocalArchivePathForImportingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $remotepath = shift; 
  $self->BasicChecks();
  confess "Component name undefined" unless defined $comp;
  confess "Version number undefined" unless defined $ver;
  $remotepath =~ s/(.*)\/.*/$1/;
  my $result = $self->FindEntry("remote", $remotepath);
  $self->CreateLocalDirectory($result);
  die "Couldn't find the remote project directory $remotepath where component $comp is being imported from." unless defined $result;
  return $result->{'local'} . "\\$comp\\$ver";
}

sub RemoteArchivePathForExistingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $remotesite = shift; # we must get passed a remote site object

  $self->CheckRemoteSites();

  $self->BasicChecks();
  confess "Component name undefined" unless defined $comp;
  confess "Version number undefined" unless defined $ver;
  confess "No remote site object was provided" unless (ref $remotesite);
  die "Component name undefined" unless defined $comp;
  my %checked;
  my $result = $self->FindEntryWithSub(sub {
     return undef unless $_->{'remote'}; # skip those with no remote path
     return undef if $checked{$_->{'remote'}}; # already checked this remote path
     $checked{$_->{'remote'}} = 1;
     $remotesite->FileExists($_->{'remote'}."/$comp/$comp$ver.zip"
   )});
  return undef unless defined $result;
  $result = $result->{remote};
  return $result . "/$comp";
}

sub RemoteArchivePathForExportingComponent {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $localpath = shift;

  $self->CheckRemoteSites();

  $localpath =~ s/(.*)[\/\\].*?[\/\\].*?$/$1/; # remove last two path segments
  $self->BasicChecks();
  confess "Component name undefined" unless defined $comp;
  my $result = $self->FindEntry("local", $localpath);
  die "Couldn't find the local project directory $localpath where component $comp is being exported from." unless (defined $result);
  die "Error: The archive ".$result->{name}." does not have a remote path listed in reltools.ini" unless (defined $result->{remote});
  return $result->{remote} . "/$comp";
}

sub ListComponents {
  my $self = shift;
  my $remote = shift || 0;
  my $continue = shift || 0;
  # This returns a list of the components we have locally or remotely.
  
  my $archiveExists;
  
  $self->BasicChecks();
  my @list;
  if ($remote) { # list remote archive
    $self->CheckRemoteSites();
    die "Need a remote site object" unless (ref $remote);
    foreach (map { $_->{'remote'} } @{$self->{project_paths}}) {
      next unless $remote->DirExists($_);
      $archiveExists = 1;
      my $rawlist = $remote->DirList($_);
      if ($rawlist) {
        push @list, grep { !m/^\./ } map { s/.*[\\\/]//; $_ } @$rawlist;
      }
    }
  } else { # list local archive
    foreach (map { $_->{'local'} } @{$self->{project_paths}}) {
      if (!-d $_) {
        if ($continue) {
          next;
        }		
        die "Project path $_ does not correspond to a real directory" ;
      }
      
      $archiveExists = 1;
      
      opendir LISTHANDLE, $_;
      push @list, grep { !/^\./ } readdir LISTHANDLE;
      closedir LISTHANDLE;
    }
  }
  
  if (!$archiveExists) {
    warn "Warning: The archive path locations specified in your reltools.ini do not exist\n";
  }
    
  # Now unique-ify list as per Perl Cookbook recipe
  my %seen;
  @list = grep { ! $seen{$_} ++ } @list;

  return @list if wantarray;
  return \@list;
}

sub ListProjects {
  my $self = shift;
  $self->BasicChecks();
  my @results = map { $_->{name} } @{$self->{project_paths}};
  return @results if wantarray;
  return \@results;
}

sub ListVersions {
  my $self = shift;
  my $comp = shift;
  my $remote = shift || 0;
  my $filter = shift;
  my $latestverFilter = shift;
  $self->BasicChecks();

  my $archiveExists;

  confess "Component name undefined" unless defined $comp;
  my @found;
  if ($remote) {
    $self->CheckRemoteSites();
    die "Need a remote site object" unless (ref $remote);
    foreach (map { $_->{'remote'} } @{$self->{project_paths}}) {
      my $dir = "$_/$comp";
      next unless $remote->DirExists($dir);
      $archiveExists = 1;
      my $files = $remote->DirList($dir);
      push @found, grep { $_ } map { m/.*(?:^|\\|\/)\Q$comp\E[\\\/]\Q$comp\E(.*?)\.zip$/i; $1 } @$files;
    }
  } else {
    foreach (map { $_->{'local'} } @{$self->{project_paths}}) {
      if (-e $_) {
        $archiveExists = 1;
      }
      
      my $dir = "$_\\$comp";
      if (-d $dir) {
        foreach my $entry (@{Utils::ReadDir($dir)}) {
          if (-d File::Spec->catdir($dir, $entry)) {
            push @found, $entry;
          }
        }
      }
    }
  }
  
  if (!$archiveExists) {
    warn "Warning: The archive path locations specified in your reltools.ini do not exist\n";
  }
  
  # Now unique-ify list as per Perl Cookbook recipe
  my %seen;
  @found = grep { ! $seen{$_} ++ } @found;

  # The filter regexes may have been compiled, here we uncompile them
  $latestverFilter =~ s/^\(\?[-imsx]*:(.*)\)$/$1/i if ($latestverFilter);
  $filter =~ s/^\(\?[-imsx]*:(.*)\)$/$1/i if ($filter);
           
  # Now apply a filter to the list
  @found = grep { ! m/$latestverFilter/i } @found if ($latestverFilter);
  @found = grep { m/$filter/i } @found if ($filter);
  return @found if wantarray;
  return \@found;
}

sub ComponentProjects {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  confess "Component name undefined" unless defined $comp;
  confess "Version number undefined" unless defined $ver;
  $self->BasicChecks();
  my @results = $self->FindEntriesWithSub(sub {
    -d ($_->{local}."\\$comp\\$ver")
  });
  return map {$_->{name}} @results; 
}

sub ComponentProject {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  confess "Component name undefined" unless defined $comp;
  confess "Version number undefined" unless defined $ver;
  $self->BasicChecks();
  my $archive = $self->FindEntryWithSub(sub {
    -d ($_->{local}."\\$comp\\$ver")
  });

  if (defined $archive) {
    return $archive->{name};
  } else {
    return "<none>";
  }
}

#
# Private
#

sub BasicChecks {
  my $self = shift;
  die "No project paths are defined" unless ($self->{project_paths});
}

sub CheckProject {
  my $self = shift;
  my $project = shift;

  die "Project \"$project\" unknown" unless $self->FindEntry("name", $project);
}

sub FindEntry {
  my $self = shift;
  my $type = shift;
  my $what = shift;

  return ($self->FindEntries($type, $what))[0];
}

sub FindEntries {
  my $self = shift;
  my $type = shift;
  my $what = shift;

  return $self->FindEntriesWithSub(sub { lc $_->{$type} eq lc $what });
}

sub CreateLocalDirectory {
  my $self = shift;
  my $entry = shift;
  if (-e $entry->{'local'}) {
    die "Error: Local archive path ".$entry->{'local'}." is not a directory\n" unless (-d _);
  } else {
    print "Warning: creating local archive path ".$entry->{local}."\n";
    Utils::MakeDir($entry->{'local'});
  }
}

sub FindEntryWithSub {
  my $self = shift;
  my $checksub = shift;
  my $projectPath;
  
  foreach (@{$self->{project_paths}}) {
    if (&$checksub) {
      $projectPath = $_;
      last;
    }
  }

  return $projectPath;
} 

sub FindEntriesWithSub {
  my $self = shift;
  my $checksub = shift;

  return grep { &$checksub } @{$self->{project_paths}};
}

sub CheckRemoteSites {
  my $self = shift;
  my $hasRemoteSite = 0;
  
  foreach my $project (@{$self->{project_paths}}) {
    $hasRemoteSite = 1 if ($project->{remote}); 
  }
  
  die "Error: No remote sites are defined in your reltools.ini\n" if (!$hasRemoteSite);
}

1;

__END__

=head1 NAME

PathData/ProjectBased.pm - Provides the location of archived releases with a new-style archive structure.

=head1 DESCRIPTION

A subclass of C<PathData>, provides the understanding of the new-style archive path structure and returns information on where to store releases, and where existing releases are stored.

=head1 INTERFACE

The abstract methods of C<PathData> are implemented.

=head2 LocalArchivePathForNewComponent

This takes a component and a version and (optionally) the name of the project to store the component in.

=head2 LocalArchivePathForExistingComponent

This takes a component, version and optionally a project. 

=head2 LocalArchivePathForImportingComponent

This takes a component, a version, and the remote path where the component was found.

=head2 RemoteArchivePathForExistingComponent

This takes a component, a version and a C<RemoteSite> object.

=head2 RemoteArchivePathForExportingComponent

This takes a component, a version, and the local path where the component was found.

=head2 ListComponents

This takes a remote and continue flag. The remote flag when set as "1" is used to indicate that it should list the components stored remotely, not locally. The continue flag when set as "1" is used to indicate that the script should continue regardless of any problems found with regards to the paths set.

=head2 ListVersions

This takes a component. It may optionally take a "1" to indicate that it should list the versions stored remotely, not locally. The third parameter is also optional; it's a Perl-syntax pattern match for the versions.

=head2 ListProjects

=head2 ComponentProjects

This takes a component and a version and returns the project name of all archives where the release is found.

=head2 ComponentProject

This takes a component name and a version and returns the project name of the first archive where the release is found.  It gives the corresponding project name to the path that LocalArchivePathForExistingComponent gives for the same arguments.
=head2 ProcessLine

This processes a line from the F<reltools.ini>.

=head1 IMPLEMENTATION

This object has a data member, C<project_paths>, which is an array of the project descriptions found in the F<reltools.ini>. Each line is stored as a hash struct, with keys "name", "local" and "remote". It's filled in by C<ProcessLine>, and used by all the other methods via a variety of subroutines which check the contents of this array.

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
