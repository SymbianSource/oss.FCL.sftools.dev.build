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

use strict;
use RelData;
use File::Spec;

package Cleaner;

sub New {
  my $class = shift;
  my $iniData = shift;
  my $remote = shift;
  my $verbose = shift;
  my $reallyClean = shift;
  
  die "Cleaner didn't get an inidata" unless $iniData;
  die "Must tell Cleaner whether you want remote or local!!!" unless defined $remote;
  
  my $self = {
    iniData => $iniData,
    remote => $remote,
    verbose => $verbose,
    reallyClean => $reallyClean,
    force => 0,
    relsToClean => {},
    relsToKeep => {},
    envsToKeep => {},
    relsToKeepAfter => {},
    envsToKeepAfter => {},
    keepAfter => undef,
    cleanTo => undef,
    remoteSite => undef,
    cleaningSubroutine => undef,
    expunge_already_cleaned => undef
  };

  bless $self, (ref $class || $class);

  $self->{remoteSite} = $iniData->RemoteSite if ($self->{remote});

  return $self;
}

sub SetCleaningSubroutine {
  my $self = shift;
  my $cleaningsub = shift;
  $self->{cleaningSubroutine} = $cleaningsub;
}

sub SetFinishingSubroutine {
  my $self = shift;
  $self->{finishingSubroutine} = shift;
}

sub SetRevertingSubroutine {
  my $self = shift;
  $self->{revertingSubroutine} = shift;
}

sub ProcessDescriptionLine {
  my $self = shift;
  my $descriptionFile = shift;
  my $keyWord = shift;
  my @operand = @_;

  if ($keyWord =~ /^keep_env$/) {
    unless ($#operand == 1) {
      die "Error: Incorrect number of arguments to \'$keyWord\' keyword in \"$descriptionFile\"\nSyntax: keep_env <component> <version>\n";
    }
    my $comp = lc($operand[0]);
    my $ver = lc($operand[1]);
    if (exists $self->{envsToKeep}->{$comp}->{$ver}) {
      die "Error: Environment \"$comp $ver\" specified for keeping more than once\n";
    }
    $self->{envsToKeep}->{$comp}->{$ver} = 1;
  }
  elsif ($keyWord =~ /^keep_rel$/) {
    unless ($#operand == 1) {
      die "Error: Incorrect number of arguments to \'$keyWord\' keyword in \"$descriptionFile\"\nSyntax: keep_rel <component> <version>\n";
    }
    my $comp = lc($operand[0]);
    my $ver = lc($operand[1]);
    $self->{relsToKeep}->{$comp}->{$ver} = 1;
  }
  elsif ($keyWord eq "keep_recent_env") {
    unless ($#operand == 1) {
      die "Error: Incorrect number of arguments to \'$keyWord\' keyword in \"$descriptionFile\"\nSyntax: keep_recent_env <component> <num_days>\n";
    }
    my $comp = lc($operand[0]);
    
    my $time = $operand[1];
    
    if ($time !~ /^\d+$/) {
      die "Error: The <num_days> argument for the '$keyWord' keyword must be a positive number\n";
    }
    
    $time = time - ($time * 60 * 60 * 24);   
    
    if (exists $self->{envsToKeepAfter}->{$comp}) {
      die "Error: keep_recent_env called more than once on component \'$comp\' in \"$descriptionFile\"\n";
    }
    $self->{envsToKeepAfter}->{$comp} = $time;
  }
  elsif ($keyWord eq "keep_recent_rel") {
    if ($#operand == 0) {
      if (defined $self->{keepAfter}) {
        die "Error: \'$keyWord\' keyword used more than once with no component name in \"$descriptionFile\"\n";
      }
      else {
        my $keepAfter = $operand[0];
        
        if ($keepAfter !~ /^\d+$/) {
          die "Error: The <num_days> argument for the '$keyWord' keyword must be a positive number\n";
        }

        $self->{keepAfter} = time - ($keepAfter * 60 * 60 * 24);
      }
    }
    elsif ($#operand == 1) {
      my $comp = lc($operand[0]);
      my $time = $operand[1];
      
      if ($time !~ /^\d+$/) {
        die "Error: Error: The <num_days> argument for the '$keyWord' keyword must be a positive number\n";
      }
      
      $time = time - ($time * 60 * 60 * 24);
      if (exists $self->{relsToKeepAfter}->{$comp}) {
        die "Error: keep_recent_rel called more than once on component \'$comp\' in \"$descriptionFile\"\n";
      }
      $self->{relsToKeepAfter}->{$comp} = $time;
    }
    else {
      die "Error: Incorrect number of arguments to \'$keyWord\' keyword in \"$descriptionFile\"\nSyntax: keep_recent_rel [<component>] <num_days>\n";
    }
  } 
  elsif ($keyWord =~ /^keep_recent$/) {
    unless ($#operand == 0) {
      die "Error: Incorrect number of arguments to \'$keyWord\' keyword in \"$descriptionFile\"\nSyntax: keep_recent <num_days>\n";
    }
    if (defined $self->{keepAfter}) {
      die "Error: \'$keyWord\' keyword used more than once in \"$descriptionFile\"\n";
    }
    
    my $keepAfter = $operand[0];
    
    if ($keepAfter !~ /^\d+$/) {
      die "Error: The <num_days> argument for the '$keyWord' keyword must be a positive number\n";
    }
    
    $self->{keepAfter} = time - ($keepAfter * 60 * 60 * 24);  
    print "Warning: The 'keep_recent' keyword has been deprecated, as it\nresults in broken environments. You can use the 'keep_recent_rel' keyword\nwithout a component name instead if you really mean this, to get rid of this\nwarning.\n";
  } elsif ($keyWord =~ /^force$/) {
    if (@operand) {
      die "Error: Incorrect number of arguments to \'$keyWord\' keyword in \"$descriptionFile\"\nSyntax: force\n";
    }
    if ($self->{force}) {
      die "Error: \'$keyWord\' keyword used more than once in \"$descriptionFile\"\n";
    }
    $self->{force} = 1;
  }
  else {
    return 0;
    
  }
  return 1;
}

sub PrintEnvsToKeep {
  my $self = shift;
  print "Environments to keep:\n";
  $self->TablePrintHash($self->{envsToKeep});
}

# Reads {envsToKeep} and {envsToKeepAfter}, updates {envsToKeep}, and fills out {relsToKeep}.
sub FindRelsToKeep {
  my $self = shift;

  # Convert envsToKeepAfter into a list of envsToKeep
  foreach my $keepEnv (keys %{$self->{envsToKeepAfter}}) {
    my $keepAfter = $self->{envsToKeepAfter}->{$keepEnv};

    foreach my $ver (keys %{$self->{archiveComponents}->{$keepEnv}}) {
      # Check reldata time
      my $timestamp;
      if ($self->{remote}) {
        my $file = $self->{iniData}->PathData->RemoteArchivePathForExistingComponent($keepEnv, $ver, $self->{iniData}->RemoteSite);
        die "Failed to find path for \"$keepEnv\" \"$ver\"\n" unless $file;
        $file .= "/$keepEnv$ver.zip";
        $timestamp = $self->{remoteSite}->FileModifiedTime($file);
        
      } elsif (-e File::Spec->catfile($self->GetPathForExistingComponent($keepEnv, $ver), 'reldata')) {
        my $relData = RelData->Open($self->{iniData}, $keepEnv, $ver, $self->{verbose});
        $timestamp = $relData->ReleaseTime();
      } else {
        next;
      }

      if ($timestamp >= $keepAfter) {
        $self->{envsToKeep}->{$keepEnv}->{$ver} = 1; # It's new; keep it
      }
    }
  }

  # Convert envsToKeep into a list of relsToKeep
  foreach my $thisComp (sort(keys %{$self->{envsToKeep}})) {
    foreach my $thisVer (sort(keys %{$self->{envsToKeep}->{$thisComp}})) {
      if ($self->{verbose}) { print "Reading release data from $thisComp $thisVer...\n"; }
   
      my $thisCompPath = $self->{iniData}->PathData->LocalArchivePathForExistingComponent($thisComp, $thisVer);
     
      if ($thisCompPath) {
        $thisCompPath = File::Spec->catfile($thisCompPath, 'reldata'); 
      } else {
        if ($self->{remote}) {
          die "Error: Unable to continue since cleanremote requires a corresponding version of '$thisComp $thisVer' in your local archive(s).  Please check that your CBR configuration file is in order and is pointing to the correct location for your local archive(s).  Failing this you will need to ensure you have a copy of '$thisComp $thisVer' in one of your configured local archives\n";      
        } else {
          die "Internal error:  Release not found in local archive when attempting to get environment for kept component\n";
        }
      }
      
      if (-e $thisCompPath) {  
        my $thisRelData = RelData->Open($self->{iniData}, $thisComp, $thisVer, $self->{verbose});
        my $thisRelEnv = $thisRelData->Environment();
   
        foreach my $compToKeep (keys %{$thisRelEnv}) {
          my $verToKeep = $thisRelEnv->{$compToKeep};
          $self->{relsToKeep}->{lc($compToKeep)}->{lc($verToKeep)} = 1;
          delete $self->{archiveComponents}->{$compToKeep}->{$verToKeep}; # saves time when finding components to remove
        }
      } elsif ($self->{remote}) {
        die "Error: Unable to continue because the environment for '$thisComp $thisVer' could not be identified (corrupt release; missing reldata file)\n";
      } else {
        print "Warning: Unable to identify the environment for '$thisComp $thisVer'. This may result in additional component releases being cleaned from the archive.  (Corrupt release; missing reldata file)\n";
      }
    }
  }
}

sub Clean {
  my $self = shift;

  # remoteSite may be defined, or it may not...
  # If not, then this will operate on the local archive  
  foreach my $archiveComponent (@{$self->{iniData}->PathData->ListComponents($self->{remoteSite})}) {
    map {$self->{archiveComponents}->{$archiveComponent}->{$_} = 1} $self->{iniData}->PathData->ListVersions($archiveComponent, $self->{remoteSite});
  }

  $self->FindRelsToKeep();

  if ($self->{verbose} > 1) {
    print "Releases to keep:\n";
    $self->TablePrintHash($self->{relsToKeep});
  }

  $self->FindRelsToClean();
  
  if (%{$self->{relsToClean}}) {
    print "About to clean the following releases:\n";
    $self->TablePrintHash($self->{relsToClean});
    if ($self->Query("Continue?")) {
      $self->CleanReleases();
    }
    else {
      print "Aborting...\n";
      exit;
    }
  }
  else {
    print "Nothing to clean\n";
  }
}

# Walks the archive, filling out %relsToClean with releases that are not present in %relsToKeep.
sub FindRelsToClean {
  my $self = shift;

  select STDOUT; $|=1;
  
  foreach my $thisArchComp (keys %{$self->{archiveComponents}}) {
    foreach my $ver (keys %{$self->{archiveComponents}->{$thisArchComp}}) {
      $self->CheckComp($thisArchComp, $ver);
    }
  }
}

sub CheckComp {
  my $self = shift;
  my $comp = lc(shift);
  my $thisVer = shift;

  unless (exists $self->{relsToKeep}->{$comp}->{lc($thisVer)}) {
    my $timestamp;
    if ($self->{remote}) {
      my $file = $self->{iniData}->PathData->RemoteArchivePathForExistingComponent($comp, $thisVer, $self->{iniData}->RemoteSite);
      die "Failed to find path for \"$comp\" \"$thisVer\"\n" unless $file;
      $file .= "/$comp$thisVer.zip";
      $timestamp = $self->{remoteSite}->FileModifiedTime($file);
    } elsif (-e File::Spec->catfile($self->GetPathForExistingComponent($comp, $thisVer), 'reldata')) {
          my $relData = RelData->Open($self->{iniData}, $comp, $thisVer, $self->{verbose});
          $timestamp = $relData->ReleaseTime();
    } elsif (!$self->{reallyClean}) {
          print "Warning: $comp $thisVer is not a complete release in " . $self->GetPathForExistingComponent($comp, $thisVer) . '.' .
          "\nThe component may be in the process of being released into the archive or it may be corrupt." .
          "\nRe-run with the -r option to remove this release from the archive.\n";
          return;
    }
    else {
          $self->{relsToClean}->{$comp}->{lc($thisVer)} = $thisVer;
          return;
    }
         
    if ($self->{keepAfter} && $timestamp >= $self->{keepAfter}) {
      print "Not cleaning $comp $thisVer - too new\n";
      return;
    }
    if (exists($self->{relsToKeepAfter}->{$comp}) && $timestamp >= $self->{relsToKeepAfter}->{$comp}) {
      print "Not cleaning $comp $thisVer - too new\n";
      return;
    }
    $self->{relsToClean}->{$comp}->{lc($thisVer)} = $thisVer;
  }
}

sub TablePrintHash {
  my $self = shift;
  my $hash = shift;
  my @tableData;
  foreach my $thisComp (sort keys %{$hash}) {
    foreach my $thisVer (sort keys %{$hash->{$thisComp}}) {
      push (@tableData, [$thisComp, $thisVer]);
    }
  }
  $self->{iniData}->TableFormatter->PrintTable(\@tableData);
  print "\n";
}

sub CleanReleases {
  my $self = shift;

  my $cleaningsub = $self->{cleaningSubroutine};
  die "No execution sub provided" unless ref $cleaningsub;

  my $failed = 0;
  my $cleaned = {};

  print "Cleaning...\n";

  foreach my $thisComp (sort keys %{$self->{relsToClean}}) {
    foreach my $thisVer (sort values %{$self->{relsToClean}->{$thisComp}}) { # use values to get correct case
      my $path = $self->GetPathForExistingComponent($thisComp, $thisVer);
      if (!defined($path)) {
        print "Unable to get path for $thisComp $thisVer: possible disconnection of FTP site?\n";
        $failed = 1;
        last;
      }
      elsif (&$cleaningsub($thisComp, $thisVer, $path)) {
        # Cleaning worked
        $cleaned->{$thisComp}->{lc($thisVer)} = [$thisVer, $path];
      }
      else {
        print "Unable to delete $thisComp $thisVer from $path\n";
        $failed = 1;
        last;
      }
    }
    if ($failed) {
      last;
    }
  }

  if ($failed) {
    my $revertsub = $self->{revertingSubroutine};
    if (ref $revertsub) {
      # Attempt to roll back
      print "Warning: Cleaning failed. Rolling back...\n";
      $failed = 0;
      foreach my $undoComp (sort keys %$cleaned) {
	my @vers = map( $_->[0], values %{$cleaned->{$undoComp}} );
        foreach my $undoVer (sort @vers) {
          my $path = $cleaned->{$undoComp}->{lc($undoVer)}->[1];
          if (!&$revertsub($undoComp, $undoVer, $path)) {
            $failed = 1;
	  }
	}
      }
      if ($failed) {
        die "Warning: Cleaning failed and rollback also failed - the archive may have been left in an indeterminate state\n";
      }
    }
    else {
      # No rollback routine
      die "Warning: Cleaning failed - the archive may have been left in an indeterminate state\n";
    }
  }
  else {
    my $finishingsub = $self->{finishingSubroutine};
    if (ref $finishingsub) {
      # Finish the job
      foreach my $thisComp (sort keys %{$cleaned}) {
	my @vers = map( $_->[0], values %{$cleaned->{$thisComp}} );
        foreach my $thisVer (sort @vers) {
          my $path = $cleaned->{$thisComp}->{lc($thisVer)}->[1];
          if (!&$finishingsub($thisComp, $thisVer, $path)) {
            print "Warning: Failed to complete cleaning of $thisComp at version $thisVer\n";
            $failed = 1;
          }
        }
      }
    }
    if (!$failed) {
      print "Cleaning complete.\n";
    }
  }
}

sub GetPathForExistingComponent {
  my $self = shift;
  my $thisComp = shift;
  my $thisVer = shift;
  my $path;
  if ($self->{remote}) {
    $path = $self->{iniData}->PathData->RemoteArchivePathForExistingComponent($thisComp, $thisVer, $self->{remoteSite});
  } else {
    $path = $self->{iniData}->PathData->LocalArchivePathForExistingComponent($thisComp, $thisVer);
  }
  return $path;
}

sub Query {
  my $self = shift;
  my $msg = shift;

  if ($self->{force}) {
    print "Skipping question \"$msg\" because of \"force\" keyword - assuming \"yes\"\n" if ($self->{verbose});
    return 1;
  }

  print "$msg [yes/no] ";
  my $response = <STDIN>;
  chomp $response;
  return ($response =~ m/^y/i);
}

1;

__END__

=head1 NAME

Cleaner.pm - A module to clean an archive

=head1 DESCRIPTION

A module to clean an archive. Supposed to implement the common bits between C<cleanlocalarch> and C<cleanremote>, but the first of those commands has been temporarily suspended. The basic plan is: let it process the lines of your cleaning description file, then give it a subroutine to operate on the releases that should be cleaned. It will do the intervening stages of working out what releases should be kept, and which should be clean.

=head1 INTERFACE

=head2 New

Pass it an IniData object, and a 0 or 1 to indicate whether it should act locally or remotely. If it's acting remotely, it will get a RemoteSite object from the IniData object.

=head2 SetCleaningSubroutine

Pass in a reference to a subroutine to actually do the first phase of cleaning. The subroutine will be passed the component name, the version number and the path. If this phase passes, the optional finishing routine will be called next. If it fails at any point, the reverting routine (if defined) will be called on each component which was 'cleaned'.

=head2 SetFinishingSubroutine

Pass in a reference to a 'finishing' subroutine to complete the cleaning (see L<SetCleaningSubroutine|setcleaningsubroutine>). If this routine has not been called then no finishing routine will be set up, and the clean will be said to have completed once the first phase is done. The finishing subroutine will be passed the component name, the version number and the path.

=head2 SetRevertingSubroutine

Pass in a reference to a 'reverting' subroutine to undo any 'cleaned' components (see L<SetCleaningSubroutine|setcleaningsubroutine>). If this routine has not been called then the cleaner will not attempt to revert changes if cleaning fails. The reverting subroutine will be passed the component name, the version number and the (original) path.

=head2 ProcessDescriptionLine

This should be passed the name of the description file (for error messages only), then a keyword, then an array of operands. It will interpret lines keep_rel, keep_env, force, and keep_recent. If it understands a line it returns 1; otherwise it returns 0.

=head2 PrintEnvsToKeep

This just prints a list of the environments it is going to keep.

=head2 Clean

This actually does the cleaning. It first finds the releases to keep, then finds the releases to clean, then runs the cleaning subroutine for each one.

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
