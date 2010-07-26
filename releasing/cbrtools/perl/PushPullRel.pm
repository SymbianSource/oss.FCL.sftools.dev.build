#!perl
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
# PushPullRel - abstracts out common parts of PushEnv, PullEnv, PushRel, PullRel
#

package PushPullRel;

use strict;
use File::Copy;
use IniData;
use RelData;
use PathData;
use CommandController;

sub new {
  my $class = shift;
  my $localinidata = shift;
  my $foreigninifile = shift; # can be an ini file location or an IniData object
  my $pushing = shift; # flag, whether we're pushing a release or pulling it
  my $verbose = shift;
  my $force = shift;

  my $self = bless {}, (ref $class || $class);

  $self->{localinidata} = $localinidata;
  if (ref $foreigninifile) {
    $self->{foreigninidata} = $foreigninifile;
  } else{ 
    $self->{foreigninidata} = IniData->New($foreigninifile);
  }

  $self->{pushing} = $pushing || 0;
  if ($self->{pushing}) {
    $self->{frominidata} = $self->{localinidata};
    $self->{toinidata} = $self->{foreigninidata};
  } else {
    $self->{toinidata} = $self->{localinidata};
    $self->{frominidata} = $self->{foreigninidata};
  }
  $self->{errors} = [];
  $self->{verbose} = $verbose;
  $self->{force} = $force;

  return $self;
}

sub TransferRel {
  my $self = shift;
  my $thisComp = shift;
  my $thisVer = shift;
  eval {
    my $toRelDir = $self->{toinidata}->PathData->LocalArchivePathForExistingOrNewComponent($thisComp, $thisVer);
    my $fromRelDir = $self->{frominidata}->PathData->LocalArchivePathForExistingComponent($thisComp, $thisVer);
    die "Error: Couldn't find component \"$thisComp\" \"$thisVer\"\n" unless defined $fromRelDir;
    $self->PerformCopying($thisComp, $thisVer, $toRelDir, $fromRelDir);
  };

  if ($@) {
    print "$@";
    $self->_AddError($@);
  }
}

sub PerformCopying {
  my $self = shift;
  my $thisComp = shift;
  my $thisVer = shift;
  my $toRelDir = shift;
  my $fromRelDir = shift;
  
  if (-e $toRelDir and Utils::CrossCheckDirs($toRelDir, $fromRelDir)) {
    print "$thisComp $thisVer already present\n";
  }
  elsif (-e $toRelDir) {
    if ($self->{force}) {
      print "Overwriting \"$toRelDir\" with \"$fromRelDir\"...\n";
      $self->_DoCopying($fromRelDir, $toRelDir);
    }
    else {
      die "\"$toRelDir\" present, but doesn't match \"$fromRelDir\". Use -f to force copy.\n";
    }
  }
  else {
    # Directory not present, so create an copy release files.
    print "Copying $thisComp $thisVer to \"$toRelDir\"...\n";
    $self->_DoCopying($fromRelDir, $toRelDir);
  }
}

sub TransferEnv {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  my $relData = RelData->Open($self->{frominidata}, $comp, $ver, $self->{verbose});
  my $env = $relData->Environment();

  my @errors;
  foreach my $thisComp (sort keys %{$env}) {
    my $thisVer = $env->{$thisComp};
    $self->TransferRel($thisComp, $thisVer);
  }
}

sub Errors {
  my $self = shift;
  return @{$self->{errors}} if wantarray;
  return $self->{errors};
}

sub SummariseErrors {
  my $self = shift;
  my $copyRel = shift || 0;
  
  my $errors = $self->Errors;
  if ($#$errors >= 0) {
    print "\nSummary of errors:\n\n";
    foreach my $thisError (@$errors) {
      print $thisError;
    }
    
    if($copyRel){
      print "\nError: Unable to copy release successfully\n";
    }
    else{
      print "\nError: Unable to push/pull release successfully\n";
    }
  }
}

sub _DoCopying {
  my $self = shift;
  my $localRelDir = shift;
  my $externalRelDir = shift;
  die "Local release directory not provided" unless $localRelDir;
  die "External release dir was undefined" unless defined $externalRelDir;
  opendir(DIR, $localRelDir) or die "Error: Couldn't open directory \"$localRelDir\": $!\n";
  Utils::MakeDir($externalRelDir);
  
  while (defined(my $file = readdir(DIR))) {
    next if ($file eq '.' or $file eq '..');
    my $localFile = "$localRelDir\\$file";
    my $externalFile = "$externalRelDir\\$file";
    if (-f $localFile) {
      if (-e "$externalRelDir\\$file" and $self->{force}) {
        if ($self->{verbose}) { print "\tMaking \"$externalRelDir\\$file\" writable...\n"; }
        Utils::SetFileWritable("$externalRelDir\\$file");
      }
      elsif (-e "$externalRelDir\\$file") {
        die;
      }
      if ($self->{verbose}) { print "\tCopying \"$localFile\" to \"$externalRelDir\"...\n"; }
      
      unless (copy ($localFile, $externalFile)){
         my $errormessage = $!;
         
         if($errormessage =~ /No such file or directory/i) {
           $errormessage = "Unknown Error - Check disk space or missing file/directory";
         }

         die "Error: Couldn't copy \"$localFile\" to \"$externalFile\": $errormessage";
      }
    }
    else {
      die "Error: \"$file\" is not a file\n";
    }
  }
}

sub _AddError {
  my $self = shift;
  my $error = shift;
  push @{$self->{errors}}, $error;
}

1;

__END__

=head1 NAME

PushPullRel.pm - class for moving releases between two local archives

=head1 DESCRIPTION

Provides an API to transfer releases between two local archives. (That is, non-encrypted archives,
accessible as standard disk drives from the PC). Used by C<pushenv>, C<pullenv>, C<pushrel>,
C<pullrel>.

=head1 INTERFACE

=head2 new

Creates a new object of this class. Takes five parameters. 1) An IniData object corresponding
to your local repository. 2) A foreign IniData object (or just a filename) describing the 
remote repository. 3) A boolean, saying whether you're pushing to the remote site. If false,
assumes you're pulling from the remote site. 4) Verbose. 5) Force (overwrites).

=head2 TransferRel

Takes a component name and version. Transfers that component.

=head2 TransferEnv
   
Takes a component name and version. Transfers the environment of that component.

=head2 PerformCopying

Takes a component name, version, to release and from release directory. Performs initial checks on the release directories passed and then calls _DoCopying.

=head2 Errors

Returns an arrayref of all the errors encountered during TransferEnv.

=head2 SummariseErrors

Optional input copyRel flag which indicates whether to this summary is for a copyrel or not. Prints all the errors encountered.

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

