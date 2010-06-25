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

package RelData;

use strict;
use Data::Dumper;
use MrpData;
use PathData;

#
# Data version history.
#
# 1 - Original release.
# 2 - Added 'relToolsVer' tag.
#


#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{iniData} = shift;
  $self->{mrpData} = shift;
  $self->{notesSrc} = shift;
  $self->{data}->{env} = shift;
  $self->{data}->{toolName} = shift;
  $self->{verbose} = shift;
  $self->{dontPersist} = shift;
  $self->{project} = shift;

  $self->{comp} = $self->{mrpData}->Component();
  $self->{ver} = $self->{mrpData}->ExternalVersion();
  $self->{data}->{dataFormatVer} = 2;
  $self->{data}->{intVer} = $self->{mrpData}->InternalVersion();
  $self->{data}->{mrpName} = $self->{mrpData}->MrpName();
  $self->{data}->{relToolsVer} = Utils::ToolsVersion();
  $self->{data}->{notesSrc}->{srcFilterErrors} = $self->{mrpData}->SourceFilterErrors();
  $self->{data}->{notesSrc}->{date} = localtime;
  
  foreach my $srcitem (keys %{$self->{mrpData}->SourceItems()}) {
    if($self->{iniData}->HasMappings()){
      $srcitem = $self->{iniData}->PerformReverseMapOnFileName($srcitem);
      $srcitem = Utils::RemoveSourceRoot($srcitem);
    }

    $self->{data}->{srcitems}->{$srcitem} = 1;
  }

  unless(defined $self->{data}->{srcitems}){
    $self->{data}->{srcitems} = $self->{mrpData}->SourceItems();
  }
  
  $self->{data}->{envUserName} = ($ENV{FirstName} || '') . " " . ($ENV{LastName} || '');
  $self->ParseNotesSource();
  $self->WorkOutFirstCompatibleVersion();
  unless (defined $self->{dontPersist}) {
    $self->WriteToFile();
  }
  return $self;
}

sub Open {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{iniData} = shift;
  $self->{comp} = shift;
  $self->{ver} = shift;
  $self->{verbose} = shift;
  $self->ReadFromFile();
  return $self;
}

sub OpenExternal {
  my $pkg = shift;
  my $externalArchive = shift;
  my $comp = shift;
  my $ver = shift;
  my $self = {};
  $self->{comp} = $comp;
  $self->{ver} = $ver;
  my $externalFile = File::Spec->catdir($externalArchive, $comp, $ver);
  bless $self, $pkg;
  $self->ReadFromSpecificFile($externalFile);
  return $self;
}


sub OpenSet {
  my $pkg = shift;
  my $iniData = shift;
  my $comp = shift;
  my $verbose = shift;
  my $versionfilter = shift;
  
  my @relDataObjects;
  foreach my $ver (@{$iniData->PathData->ListVersions($comp, 0, $versionfilter, $iniData->LatestVerFilter)}) {
    my $thisRelData = {};
    bless $thisRelData, $pkg;
    eval {
      # ReadFromFile may die, if the file is corrupt.
      # In which case we do not add it to the set.
      $thisRelData->{iniData} = $iniData;
      $thisRelData->{comp} = $comp;
      $thisRelData->{ver} = $ver;
      $thisRelData->{verbose} = $verbose;
      $thisRelData->ReadFromFile();
      push (@relDataObjects, $thisRelData);
    };
    print "Warning: could not examine \"$comp\" \"$ver\" because $@" if ($@);
  }
  
  @relDataObjects = sort { $b->ReleaseTime() <=> $a->ReleaseTime() } @relDataObjects;

  return \@relDataObjects;;
}

sub Component {
  my $self = shift;
  die unless exists $self->{comp};
  return $self->{comp};
}

sub MadeWith {
  my $self = shift;
  my $ver = $self->{data}->{relToolsVer} || "(unknown version)";
  my $tool = $self->{data}->{toolName} || "(unknown tool)";
  return "$tool $ver";
}

sub MadeWithVersion {
  my $self = shift;
  return "".$self->{data}->{relToolsVer};
}

sub SourceIncluded {
  my $self = shift;
  my $items;
  eval {
    $items = $self->SourceItems();
  };
  return "(unknown)" if $@;
  return join (", ", keys %$items);
}

sub Version {
  my $self = shift;
  die unless exists $self->{ver};
  return $self->{ver};
}

sub InternalVersion {
  my $self = shift;
  die unless exists $self->{data};
  return $self->{data}->{intVer};
}

sub MrpName {
  my $self = shift;
  die unless exists $self->{data};
  return $self->{data}->{mrpName};
}

sub FirstCompatibleVersion {
  my $self = shift;
  die unless exists $self->{data};
  return $self->{data}->{firstCompatibleVersion};
}

sub Environment {
  my $self = shift;
  die unless exists $self->{data};
  return $self->{data}->{env};
}

sub NotesSource {
  my $self = shift;
  die unless exists $self->{data};
  return $self->{data}->{notesSrc};
}

sub UpdateProject {
  my $self = shift;
  $self->{project} = shift;
  $self->WriteToFile();
}

sub UpdateNotes {
  my $self = shift;
  $self->{notesSrc} = shift;
  $self->DeleteNotesSource();
  $self->ParseNotesSource();
  $self->WriteToFile();
}

sub UpdateInternalVersion {
  my $self = shift;
  $self->{data}->{intVer} = shift;
  $self->WriteToFile();
}

sub UpdateEnv {
  my $self = shift;
  $self->{data}->{env} = shift;
  $self->WriteToFile();
}

sub ReleaseTime {
  my $self = shift;
  unless (exists $self->{releaseTime}) {
    $self->{releaseTime} = Utils::TextTimeToEpochSeconds($self->{data}->{notesSrc}->{date});
  }
  return $self->{releaseTime};
}

sub SourceItems {
  my $self = shift;
  unless (defined $self->{data}->{srcitems}) {
    my $createdver = $self->{data}->{relToolsVer} || 0;
    if (Utils::CompareVers($createdver,2.54)<0) {
      die "this release was created with Release Tools $createdver, and the necessary information is only present in releases created with 2.54 or later.\n";
    }
    die "Could not return the list of \"source\" statements used in the MRP file." 
  }
  return $self->{data}->{srcitems};
}

sub EnvUserName {
  my $self = shift;
  return $self->{data}->{envUserName};
  }

#
# Private.
#

sub WriteToFile {
  my $self = shift;
  my $relDir = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($self->{comp}, $self->{ver}, $self->{project});

  my $file = "$relDir\\reldata";  
  
  if (-e $file) {
    Utils::SetFileWritable($file);
  }
  open (OUT, ">$file") or die "Error: Couldn't open \"$file\" for writing: $!\n";
  print OUT Data::Dumper->Dump([$self->{data}], ['self->{data}']);
  close (OUT);
  Utils::SetFileReadOnly($file);
}

sub ReadFromFile {
  my $self = shift;
  my $pathData = shift || $self->{iniData}->PathData;

  my $comp = $self->{comp};
  my $ver = $self->{ver};

  my $relDir = $pathData->LocalArchivePathForExistingComponent($comp, $ver);
  die "Error: \"$comp $ver\" does not exist\n" unless $relDir;
  die "Error: \"$comp $ver\" was not a valid release (can't find \"$relDir\\reldata\")\n" unless -e "$relDir\\reldata";
  $self->{project} = $pathData->ComponentProject($comp, $ver);
  $self->ReadFromSpecificFile($relDir);
}

sub ReadFromSpecificFile {
  my $self = shift;
  my $relDir = shift;
  unless (-e $relDir) {
    die "Error: $self->{comp} $self->{ver} does not exist\n";
  }
  my $file = "$relDir\\reldata";
  open (IN, $file) or die "Error: Couldn't open \"$file\" for reading: $!\n";
  local $/ = undef;
  my $data = <IN>;
  die "Error: Reldata in \"$relDir\" is blank" unless $data =~ (m/\S/);
  eval ($data) or die "Error: Couldn't parse reldata in \"$relDir\"\n";
  close (IN);
}

sub ParseNotesSource {
  my $self = shift;

  if ($self->{verbose} > 1) { print "Parsing notes source...\n"; }

  open(SRC,"$self->{notesSrc}") or die "Unable to open $self->{notesSrc} for reading: $!\n";

  my $thisTag;
  while (<SRC>) {
    if (m/^NOTESRC/i) {
      chomp;
      $thisTag = $_;
    }
    elsif (m/^\s*$/) {
      next;
    }
    elsif (defined $thisTag) {
      $self->AddLine($thisTag, $_);
    }
  }
  close SRC;

  $self->ValidateSource();
}

sub AddLine {
  my $self = shift;
  my $thisTag = shift;
  my $thisLine = shift;
  chomp $thisLine;

  if ($thisTag =~ m/^NOTESRC_RELEASER$/i) {
    $self->{data}->{notesSrc}->{releaser} = $thisLine;		
  }
  elsif ($thisTag =~ m/^NOTESRC_RELEASE_REASON$/i) {
    push @{$self->{data}->{notesSrc}->{releaseReason}}, $thisLine;
  }
  elsif ($thisTag =~ m/^NOTESRC_GENERAL_COMMENTS$/i) {
    push @{$self->{data}->{notesSrc}->{generalComments}}, $thisLine;
  }
  elsif ($thisTag =~ m/^NOTESRC_KNOWN_DEVIATIONS$/i) {
    push @{$self->{data}->{notesSrc}->{knownDeviations}}, $thisLine;
  }
  elsif ($thisTag =~ m/^NOTESRC_BUGS_FIXED$/i) {
    push @{$self->{data}->{notesSrc}->{bugsFixed}}, $thisLine;
  }
  elsif ($thisTag =~ m/^NOTESRC_BUGS_REMAINING$/i) {
    push @{$self->{data}->{notesSrc}->{bugsRemaining}}, $thisLine;
  }
  elsif ($thisTag =~ m/^NOTESRC_OTHER_CHANGES$/i) {
    push @{$self->{data}->{notesSrc}->{otherChanges}}, $thisLine;
  }
  else {
    die "Error: Unknown tag \"$thisTag\" in $self->{notesSrc}\n";
  }
}

sub ValidateSource {
  my $self = shift;

  if ($self->{verbose} > 1) { print "Validating notes source...\n"; }

  unless (exists $self->{data}->{notesSrc}->{releaser}) {
    die "Error <NOTESRC_RELEASER> not specified in $self->{notesSrc}\n";
  } 
  unless (exists $self->{data}->{notesSrc}->{releaseReason}) {
    die "Error <NOTESRC_RELEASE_REASON> not specified in $self->{notesSrc}\n";
  } 
  unless (exists $self->{data}->{notesSrc}->{generalComments}) {
    push @{$self->{data}->{notesSrc}->{generalComments}}, "<unspecified>";
  } 
  unless (exists $self->{data}->{notesSrc}->{knownDeviations}) {
    push @{$self->{data}->{notesSrc}->{knownDeviations}}, "<unspecified>";
  }
  unless (exists $self->{data}->{notesSrc}->{bugsFixed}) {
    push @{$self->{data}->{notesSrc}->{bugsFixed}}, "<unspecified>";
  }
  unless (exists $self->{data}->{notesSrc}->{bugsRemaining}) {
    push @{$self->{data}->{notesSrc}->{bugsRemaining}}, "<unspecified>";
  }
  unless (exists $self->{data}->{notesSrc}->{otherChanges}) {
    push @{$self->{data}->{notesSrc}->{otherChanges}}, "<unspecified>";
  }
}

sub DeleteNotesSource {
  my $self = shift;
  delete $self->{data}->{notesSrc}->{releaser};		
  delete $self->{data}->{notesSrc}->{releaseReason};
  delete $self->{data}->{notesSrc}->{generalComments};
  delete $self->{data}->{notesSrc}->{knownDeviations};
  delete $self->{data}->{notesSrc}->{bugsFixed};
  delete $self->{data}->{notesSrc}->{bugsRemaining};
  delete $self->{data}->{notesSrc}->{otherChanges};
}

sub WorkOutFirstCompatibleVersion {
  my $self = shift;

  my $version = "2.00";
  $version = "2.50" if ($self->{iniData}->CategoriseBinaries());
  $version = "2.59" if ($self->{iniData}->CategoriseExports());
  $version = "2.80.1000" if grep /[^A-GX]/, @{$self->{mrpData}->SourceCategories()}; 
  # Add to this when extra features are added which break
  # backward compatibility of release formats.
  $self->{data}->{firstCompatibleVersion} = $version;
}

sub WarnIfReleaseTooNew {
  my $self = shift;
  # Called from EnvDb::InstallComponent
  my $relversion = $self->FirstCompatibleVersion();
  return unless defined $relversion;
  my $toolsver = Utils::ToolsVersion;
  if (Utils::CompareVers($relversion,$toolsver)>0) {
    my $thisComp = $self->{comp};
    print "Warning: $thisComp requires Release Tools version $relversion or later. You have $toolsver.\n";
    print "         It's recommended you stop and upgrade your tools before continuing, as\n";
    print "         the release probably won't install correctly.\n";
    print "         Continue? [y/n] ";
    my $response = <STDIN>;
    chomp $response;
    if (lc $response eq 'y') {
      return;
    }
    die "Aborting operation.\n";
  }
}

1;

=head1 NAME

RelData.pm - Provides an interface to data associated with a release.

=head1 DESCRIPTION

Along with the source and binaries of a component release, the following information is also stored:

=over 4

=item *

The name of the F<mrp> file used to create the release.

=item *

The release's internal version.

=item *

The name and version of every component in the environment used to create the release.

=item *

The time and date the release was made.

=item *

The release notes source, which can subsequently be used to compile the release notes.

=back

All this information is stored in a single file named F<reldata> within the release directory using the module Data::Dumper.

=head1 INTERFACE

=head2 New

Creates a new C<RelData> object and corresponding data file. Expects to be passed an C<IniData> reference, a component name, a version, an internal version,  an F<mrp> file name, release notes source file name, a reference to a list of components in the release environment and a verbosity level. This information is assembled into an in-memory data structure, and then written into F<reldata> in the component's release directory. You may optionally pass a "project" name to this function, to specify where the F<reldata> should be written.

=head2 Open

Creates a C<RelData> object from an already existing data file. Expects to be passed an C<IniData> reference, a component name, a version, and a verbosity level.

=head2 OpenExternal

As C<New> except expects to be explicitly passed an archive path file name, rather than an C<IniData> object. Effectively creates a C<RelData> object from an external archive.

=head2 OpenSet

Expects to be passed an C<IniData> reference, a component name, and a verbosity level. Opens C<RelData> objects for all of the releases of the specified component made to date and returns a reference to an array of references to them in descending date order.

Optionally takes a regular expression to limit the versions that are returned.

=head2 Component

Returns the component name.

=head2 Version

Returns the component's version.

=head2 InternalVersion

Returns the component's internal version.

=head2 MrpName

Returns the component's F<mrp> file name.

=head2 Environment

Returns a reference to a hash containing component name / version pairs for the components that were in the release environment.

=head2 NotesSource

Returns a reference to a hash containing all the data needed to compile a set of release notes.

=head1 SourceItems

Returns a reference to a hash of all the "source" lines that were in the MRP file used to create this component. This function will die if no such information was found; this means it will die for releases created with Release Tools versions prior to 2.54.

Note that a hash is used just to ensure uniqueness. Only the keys of the hash have value; the values of the hash currently have no meaning.

=head2 SourceIncluded

Returns a string version of the output of SourceItems.

=head2 UpdateProject

Expects to be passed a project. The project passed is then set as the project for the reldata.pm object, which is used when writing the reldata file.

=head2 UpdateNotes

Expects to be passed the name of a notes source file. Parses this and replaces the persisted version of the release notes.

=head2 UpdateInternalVersion

Expects to be passed an internal version. The internal version is then set as internal version for the reldata.pm object, which is used when writing the reldata file.

=head2 UpdateEnv

Expects to be passed an environment. The environment is then set as environment for the reldata.pm object, which is used when writing the reldata file.

=head2 ReleaseTime

Returns the time (in epoch seconds) at which the release was made.

=head2 MadeWith

Returns a string describing which tool this was made with, including the version number.

=head2 EnvUserName

Returns the full name of the user who made this release, according to environment variables FirstName and LastName.

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
