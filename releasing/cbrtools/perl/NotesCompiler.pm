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

package NotesCompiler;

use strict;
use CGI qw(-no_debug :standard start_ul);
use IniData;
use RelData;
use EnvDb;
use MrpData;
use IO::File;
use File::Basename;


#
# Constants.
#

use constant NOTES_DIREXTENSION => '.RelNotes';

#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{iniData} = shift;
  $self->{comp} = shift;
  $self->{ver} = shift;
  $self->{verbose} = shift;
  $self->{htmlMainFile} = shift;
  $self->{outputSTDOUTonly} = shift;
  $self->{htmlNotes} = shift; # flag to render old notes as html or plain text
  $self->{fh} = undef; # filehandle to write to
  $self->{envDb} = EnvDb->Open($self->{iniData}, $self->{verbose});
  # Not using 'use constant' because that requires Utils::PrependEpocRoot to be called at compile-time
  $self->{notes_store} = Utils::PrependEpocRoot('\\epoc32\\relinfo\\notes'); # constant
  return $self;
}

sub DoStandardNotes {
  my $self = shift;
  if( !defined ($self->{htmlMainFile} )) {
    my $filename = $self->{comp}.".".$self->{ver};
    if ($self->{htmlNotes}) {
      $filename.=".htmlnotes";
    } else {
      $filename.=".textnotes";
    }
    $self->{htmlName} = $self->{notes_store} . "\\$filename.html";
  }
  else {
    $self->{htmlName} = $self->{htmlMainFile};
  }
  
  if(!defined ($self->{outputSTDOUTonly})){
    $self->WriteUnlessAlreadyCompiled(\&PrepareStandardNotes, undef, 1); # sub, filename, cache
  }
  else{
    $self->WriteUnlessAlreadyCompiled(\&PrepareStandardNotes, undef, 0); # sub, filename, cache
  }
}

sub DoCompSummary {
  my $self = shift;
  if( !defined ($self->{htmlMainFile} )) {
    $self->{htmlName} = $self->{notes_store} . "\\$self->{comp}.summary.html";
  }
  else {
    $self->{htmlName} = $self->{htmlMainFile};
  }
  my $relDataObjects = RelData->OpenSet($self->{iniData}, $self->{comp}, $self->{verbose});
  @$relDataObjects = grep { $self->PassesFilter($_) } @$relDataObjects;
  foreach my $thisRelData (@$relDataObjects) {
    my $ver = $thisRelData->Version();
    my $htmlName;
    my $filename = $self->{comp}.".".$ver;
    if ($self->{htmlNotes}) {
      $filename.=".htmlnotes";
    } else {
      $filename.=".textnotes";
    }
    if( !defined ($self->{htmlMainFile}) ) {
      $htmlName = $self->{notes_store} . "\\$filename.html";
    }
    else {
      $htmlName = $self->{htmlMainFile} . NOTES_DIREXTENSION . "\\$filename.html";
    }
    $self->WriteUnlessAlreadyCompiled(\&PrepareStandardNotes, $htmlName, 1, $thisRelData); # sub, filename, cache, @args
  }
  $self->WriteUnlessAlreadyCompiled(\&PrepareSummary, undef, 0, $relDataObjects, 1); # sub, filename, cache, @args
  return $self;
}

sub DoEnvSummary {
  my $self = shift;
  if( !defined ($self->{htmlMainFile} )) {
    if ($self->{comp} and $self->{ver}) {
      $self->{htmlName} = $self->{notes_store} . "\\$self->{comp}.$self->{ver}.summary.html";
    }
    else {
      $self->{htmlName} = $self->{notes_store} . "\\current_env_summary.html";
    }
  }
  else {
    $self->{htmlName} = $self->{htmlMainFile};
  }

  my $versionInfo;
  if ($self->{comp} and $self->{ver}) {
    my $relData = RelData->Open($self->{iniData}, $self->{comp}, $self->{ver}, $self->{verbose});
    $versionInfo = $relData->Environment();
  }
  else {
    $versionInfo = $self->{envDb}->VersionInfo();
  }

  my @relData;
  foreach my $thisComp (sort keys %$versionInfo) {
    my $thisVer = $versionInfo->{$thisComp};
    (my $relData, my $preview) = $self->CreateRelData($thisComp, $thisVer);
    next unless $self->PassesFilter($relData);
    push (@relData, $relData);
    my $htmlName;
    my $filename = $thisComp.".".$thisVer;
    if ($self->{htmlNotes}) {
      $filename.=".htmlnotes";
    } else {
      $filename.=".textnotes";
    }
    if( !defined ($self->{htmlMainFile} )) {
      $htmlName = $self->{notes_store} . "\\$filename.html";
    }
    else {
      $htmlName = $self->{htmlMainFile} . NOTES_DIREXTENSION . "\\$filename.html";
    }
    $self->WriteUnlessAlreadyCompiled(\&PrepareStandardNotes, $htmlName, 1, $relData, $preview); # sub, filename, cache, @args
  }
  $self->WriteUnlessAlreadyCompiled(\&PrepareSummary, undef, 0, \@relData); # sub, filename, cache, @args
  return $self;
}

sub DoDiffEnvSummary {
  my $self = shift;
  my $comp2 = shift;
  my $ver2 = shift;

  require EnvDifferencer;

  my $comp1 = $self->{comp};
  my $ver1 = $self->{ver};
  $comp2 ||= $comp1;
  $ver2 ||=  $self->{envDb}->VersionInfo()->{$comp2};
  unless ($ver2) {
    die "Error: $comp2 not installed in current environment\n";
  }
  if( !defined ($self->{htmlMainFile} )) {
    my $filename = $comp1.".".$ver1.".".$comp2.".".$ver2."-full";
    if ($self->{htmlNotes}) {
      $filename.=".htmlnotes";
    } else {
      $filename.=".textnotes";
    }
    $self->{htmlName} = $self->{notes_store} . "\\$filename.html";
  }
  else {
    $self->{htmlName} = $self->{htmlMainFile};
  }
  if(!defined ($self->{outputSTDOUTonly})){
    $self->WriteUnlessAlreadyCompiled(\&PrepareDiffEnvReport, undef, 1, $comp2, $ver2); # sub, filename, cache, @args
  }
  else{
    $self->WriteUnlessAlreadyCompiled(\&PrepareDiffEnvReport, undef, 0, $comp2, $ver2); # sub, filename, cache, @args
  }
}

sub HtmlFileName {
  my $self = shift;
  return $self->{htmlName};
}

sub HtmlMainFile {
  my $self = shift;
  return $self->{htmlMainFile};
}

sub SetProjectFilter {
  my $self = shift;
  $self->{filter}->{project} = shift;
}

sub SetVersionNumberFilter {
  my $self = shift;
  $self->{filter}->{versionregex} = shift;
}

#
# Private.
#

sub WriteUnlessAlreadyCompiled {
  my $self = shift;
  my $sub = shift;
  my $filename = shift || $self->{htmlName};
  my $cache = shift;
  my @args = @_;

  if ($cache) {
    return if $self->NotesFileAlreadyCompiled($filename, $self->{comp}, $self->{ver});
  }

  my $output = $sub->($self, @args);
 
  if (!defined ($self->{outputSTDOUTonly})) {
    my $fh = $self->OpenFileForWriting($filename);
    print "FILE LOCATION: $filename\n" if ($self->{verbose});
    print $fh $output;
    $fh = undef; # close file
  }
  else {
    print $output;
  }
}

sub OpenFileForWriting {
  my $self = shift;
  my $filename = shift;
  Utils::MakeDir(dirname($filename));
  return new IO::File($filename, "w") or die "Couldn't open file \"$filename\" for writing: $!";
}

sub PrepareDiffEnvReport {
  my $self = shift;
  my $endcomp = shift;
  my $endver = shift;
  my $startcomp = $self->{comp};
  my $startver = $self->{ver};

  $self->{envDb} = EnvDb->Open($self->{iniData}, $self->{verbose});

  my $envDifferencer = EnvDifferencer->New($self->{iniData}, $self->{verbose});
  $envDifferencer->SetStartCompVer($startcomp, $startver);
  $envDifferencer->SetEndCompVer($endcomp, $endver);

  my @contentsrows;
  my $bodies;
  
  my $changedcomps = $envDifferencer->ChangedComps();
  my $i=0;
  foreach my $comp (sort @$changedcomps) {
    $i++; # counter for debug output only
    my $endReldata = $envDifferencer->EndReldata($comp);
    my $intermediateReldatas = $envDifferencer->IntermediateReldatas($comp);
    
    my @allreldatas = (@$intermediateReldatas, $endReldata);
    @allreldatas = grep { $self->PassesFilter($_) } @allreldatas;
    print "Processing $comp ($i/".(scalar @$changedcomps)."): ".(scalar @allreldatas)." releases to process\n" if $self->{verbose};
    next unless @allreldatas;

    my @versions;

    $bodies .= hr . h2(a({name=>$comp},$comp));

    my $firstver;
    foreach my $reldata (sort { $b->ReleaseTime() <=> $a->ReleaseTime() } @allreldatas) {
      my $ver = $reldata->Version();
      my $link = "$comp$ver";
      if(defined $self->{htmlMainFile})
        {
        $link = $self->{htmlMainFile} . NOTES_DIREXTENSION . "/" . $link;
        }
      # First add an entry to our contents table
      push @versions, td(a{href=>"#$link"}, $ver);

      # Now prepare the body itself
      $bodies .= a({name=>$link}, h3($ver));
      $bodies .= ul($self->MainBody($reldata, 1)); # 1 = concise
    }
    push @contentsrows, Tr(th(a({href=>"#$comp"},$comp)), @versions);
  }

  my $output = "";
  $output .= h1("Differences between $startcomp $startver and $endcomp $endver");
  $output .= h1("Contents");
  $output .= p("Newer releases are on the left.");
  $output .= table({border=>1},@contentsrows);

  if(defined $bodies){
    $output .= $bodies;
  }
  
  return $output;
}

sub PrepareStandardNotes {
  my $self = shift;
  my $relData = shift;
  my $preview;
  my $comp;
  my $ver;
  if ($relData) {
    $comp = $relData->Component();
    $ver = $relData->Version();
  } else {
    $comp = $self->{comp};
    $ver = $self->{ver};
    ($relData, $preview) = $self->CreateRelData($comp, $ver);
  }
  my $output = "";

  if ($self->{verbose}) { print "Compiling release notes for $comp $ver...\n"; }

  if ($preview) {
    $output .= start_html({-title => "$comp $ver release notes PREVIEW"})
      .h1({-style=>'Color: red;'}, 'Release Notes Preview'). hr
      .h1("$comp")
      .hr;
  }
  else {
    $output .= start_html({-title => "$comp $ver release notes"})
      .h1("$comp")
      .hr;
  }

  $output .= $self->MainBody($relData);
  $output .= $self->EnvDetails($relData, $preview);
  $output .= $self->SrcFilterErrors($relData, $preview);

  $output .= end_html();
 
  return $output;
}

sub PrepareSummary {
  my $self = shift;
  my $relDataObjects = shift;
  my $compSummary = shift;

  my $output = "";

  if ($compSummary) {
    if ($self->{verbose}) { print "Writing component summary for $self->{comp}...\n"; }
    $output .= (start_html({-title => "Release note summary for component $self->{comp}"})
      .h1("Release note summary for component $self->{comp}")
      .hr);
  }
  else {
    if ($self->{comp} and $self->{ver}) {
      if ($self->{verbose}) { print "Writing environment summary for $self->{comp} $self->{ver}...\n"; }
      $output .= (start_html({-title => "Release note summary for environment $self->{comp} $self->{ver}"})
      .h1("Release note summary for environment $self->{comp} $self->{ver}")
      .hr);
    }
    else {
      if ($self->{verbose}) { print "Writing environment summary for current environment...\n"; }
      $output .= (start_html({-title => "Release note summary for the current environment"})
        .h1("Release note summary for the current environment")
        .hr);
    }
  }

  foreach my $thisRelData (@$relDataObjects) {
    my $thisVer = $thisRelData->Version();
    my $thisComp = $thisRelData->Component();
    my $thisIntVer = $thisRelData->InternalVersion();

    my $link;
    if ($compSummary) {
      my $filename = $self->{comp}.".".$thisVer;
      if ($self->{htmlNotes}) {
        $filename.=".htmlnotes";
      } else {
        $filename.=".textnotes";
      }
      $link = "$filename.html";
    }
    else {
      my $filename = $thisComp.".".$thisVer;
      if ($self->{htmlNotes}) {
        $filename.=".htmlnotes";
      } else {
        $filename.=".textnotes";
      }
      $link = "$filename.html";
    }

    if(defined $self->{htmlMainFile})
      {
      $link = $self->{htmlMainFile} . NOTES_DIREXTENSION . "/" . $link;
      }

    my $caption = $thisVer;
    if ($thisIntVer) {
      $caption .= " [$thisIntVer]";
    }
    unless ($compSummary) {
      $caption = "$thisComp $caption";
    }
    my $notesSrc = $thisRelData->NotesSource();
    $output .= a({ -href => $link }, $caption). ' - ';
    $output .= ("Made by $notesSrc->{releaser} on $notesSrc->{date}");
    $output .= (p(""));
  }

  $output .= (end_html());
  return $output;
}

sub CreateRelData {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  my $installedVer = $self->{envDb}->Version($comp);
  my $preview = 0;
  my $relData;
  if (defined $installedVer) {
    if ($ver eq $installedVer) {
      if ($self->{envDb}->Status($comp) == EnvDb::STATUS_PENDING_RELEASE) {
        # This release has not yet been made, so preview the notes.
        $preview = 1;
        my $intVer = $self->{envDb}->InternalVersion($comp);
        unless (defined $intVer) {
          $intVer = ' ';
        }
        my $mrpData = MrpData->New($self->{envDb}->MrpName($comp),
          $ver, $intVer, $self->{iniData}, $self->{verbose});
          $relData = RelData->New($self->{iniData}, $mrpData,
          Utils::PrependSourceRoot($mrpData->NotesSource()), $self->{envDb}->VersionInfo(), 'viewnotes', $self->{verbose}, 1);
      }
    }
  }
  unless (defined $relData) {
    # This release has already been made, so we can read it's reldata.
    $relData = RelData->Open($self->{iniData}, $comp, $ver, $self->{verbose});
  }

  return ($relData, $preview);
}

sub MainBody {
  my $self = shift;
  my $relData = shift;
  my $concise = shift;

  my $output = "";

  if ($self->{verbose} > 1) {
    print "Compiling release notes main body for ".$relData->Component()." ".$relData->Version()."...\n";
  }

  my $notesSrc = $relData->NotesSource();
  
  my $release_version = $relData->MadeWithVersion();

  foreach my $key (keys %{$notesSrc}) {
    my $html_markers;
    my $note = $notesSrc->{$key};
    if (ref $note eq 'ARRAY') {
      $html_markers = $self->CheckHtmlMarkers(join("",@$note));
    } else {
      $html_markers = $self->CheckHtmlMarkers($note);
    }
    if (!$html_markers) {
      if (Utils::CompareVers($release_version, "2.83.1013") > 0) {
        # 'Recent' release: escape html chars
        $notesSrc->{$key} = $self->EscapeHtmlChars($note);
      } else {
        # Old release
        if (!($self->{htmlNotes})) {
          # User hasn't set html_notes: escape html chars
          $notesSrc->{$key} = $self->EscapeHtmlChars($note);
        }
      }
    }
  }
  
  unless ($concise) {
    my $comp = $relData->Component();
    my $ver = $relData->Version();
    my $intVer = $relData->InternalVersion();
    my $toolsver = $relData->MadeWith();
    my $sourcecode = $relData->SourceIncluded();
    my $mrpName = $relData->MrpName();
    my $project = $self->ComponentProject($comp, $ver);
    my $envUserName = $relData->EnvUserName() || "";
    my $firstCompatibleVersion = $relData->FirstCompatibleVersion() || "&lt;unknown&gt;";
    my $zipsize;
    eval {
      $zipsize = $self->{envDb}->GetReleaseSize($relData->Component(), $relData->Version());
    };
    $zipsize ||= "-"; # for example, if we're pending release...

    $output .= table({-border=>0}, Tr({-align =>'left'},
               [td([b('Version'), $ver]),
          td([b('Internal version'), ($intVer || "&lt;none&gt;")]),
          td([b('Made by'), $notesSrc->{releaser}]),
          td([b('Date'), $notesSrc->{date}]),
          td([b('Made with'), $toolsver]),
          td([b('Earliest compatible tools'), $firstCompatibleVersion]),
          td([b('Source included'), tt($sourcecode)]),
          td([b('Size of release zips'), tt($zipsize)]),
          td([b('Project storage archive'), $project]),
          td([b('MRP file used'), tt($mrpName)]),
          td([b('Environment username'), $envUserName])
               ]));
  }

  $output .= hr;
  $output .= h2("Release Summary");
  $output .= h3("Reason for release");
  foreach my $line (@{$notesSrc->{releaseReason}}) {
    $output .= tt($line). br;
  }
  $output .= h3("General release comments");
  foreach my $line (@{$notesSrc->{generalComments}}) {
      $output .= tt($line). br;
  }
  $output .= h3("Known omissions, deviations and discrepancies");
  foreach my $line (@{$notesSrc->{knownDeviations}}) {
      $output .= tt($line). br;
  }
  
  @{$notesSrc->{bugsFixed}} = map tt($_), @{$notesSrc->{bugsFixed}};
  @{$notesSrc->{bugsRemaining}} = map tt($_), @{$notesSrc->{bugsRemaining}}; 
  @{$notesSrc->{otherChanges}} = map tt($_), @{$notesSrc->{otherChanges}};
   
  $output .= hr;
  $output .= h2("Bugs fixed");
  $output .= ul(li($notesSrc->{bugsFixed}));
  $output .= hr;
  $output .= h2("Known bugs remaining");
  $output .= ul(li($notesSrc->{bugsRemaining}));
  $output .= hr;
  $output .= h2("Other changes");
  $output .= ul(li($notesSrc->{otherChanges}));
  $output .= hr;

  return $output;
}

sub EscapeHtmlChars {
  my $self = shift;
  my $note = shift;
  
  my $newnote;
  if (ref $note eq 'ARRAY') {
    $newnote = [];
    foreach my $line (@$note) {
      my $newline = $line;
      $newline =~ s/&/&amp;/g;
      $newline =~ s/</&lt;/g;
      $newline =~ s/>/&gt;/g;
      push @$newnote, $newline;
    }
  } else {
    $newnote = $note;
    $newnote =~ s/&/&amp;/g;
    $newnote =~ s/</&lt;/g;
    $newnote =~ s/>/&gt;/g;
  }
  return $newnote;
}

sub CheckHtmlMarkers {
  my $self = shift;
  my $note = shift;
  if ($note =~ /^\s*<\s*html\s*>.*<\s*[\/\\]\s*html\s*>\s*$/i) {
    # Note begins with <html> and ends with </html> or something along those lines
    return 1;
  } else {
    return 0;
  }
}

sub EnvDetails {
  my $self = shift;
  my $relData = shift;
  my $preview = shift;

  my $contents = "";

  if ($preview) {
    $contents .= h2("Release environment");
    $contents .= span({-style=>'Color: red;'}, '[not yet known]');
    $contents .= br();
  }
  else {
    my $env = $relData->Environment();
    if (defined $env) {
      $contents .= h2("Release environment");
      my $tableData;
      $contents .= p("Number of components: ".(scalar keys %$env));
      foreach my $comp (sort keys %{$env}) {
  push (@$tableData, td([b($comp), $env->{$comp}]));
      }
      $contents .= table({-border=>0}, Tr({-align =>'left'}, $tableData));
    }
  }
  return $contents;
}

sub SrcFilterErrors {
  my $self = shift;
  my $relData = shift;
  my $preview = shift;
  my $notesSrc = $relData->NotesSource();

  my $contents = "";

  if (defined $notesSrc->{srcFilterErrors} and scalar(@{$notesSrc->{srcFilterErrors}}) > 0) {
    $contents .= hr, h2("Source filter errors");
    foreach my $errorLine (@{$notesSrc->{srcFilterErrors}}) {
      $contents .= $errorLine, br();
    }
  }
  return $contents;
}

sub NotesFileAlreadyCompiled {
  my $self = shift;
  my $fileName = shift;
  my $comp = shift;
  my $ver = shift;
  my $alreadyCompiled = 0;

  if(!(defined $self->{htmlMainFile})) {
    if (-e $fileName && $comp && $ver) {
      my $reldata = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($comp, $ver) . '\\reldata';
      if (-e $reldata and Utils::FileModifiedTime($reldata) < Utils::FileModifiedTime($fileName)) {
        $alreadyCompiled = 1;
      }
    }
  }
  return $alreadyCompiled;
}

sub PassesFilter {
  my $self = shift;
  my $rd = shift;
  my $comp = $rd->Component();
  my $ver = $rd->Version();
  if ($self->{filter}->{project}) {
    return 0 unless $self->ComponentProject($comp, $ver) eq $self->{filter}->{project};
  }
  if ($self->{filter}->{versionregex}) {
    my $re = $self->{filter}->{versionregex};
    return 0 unless $ver =~ m/$re/i;
  }
  return 1;
}

sub ComponentProject {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  return $self->{iniData}->PathData->ComponentProject($comp, $ver);
}

1;
  
__END__

=head1 NAME

NotesCompiler.pm - Compiles a set of release notes into HTML.

=head1 INTERFACE

=head2 New

Expects to be passed an C<IniData> reference, a component name, a version, a verbosity level, an output HTML file name and an output STDOUT only flag. Creates a C<RelData> object for the component release and uses the information contained within it to compile the output HTML file.

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
