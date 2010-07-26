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


package EnvDb;

use strict;
use MLDBM::Sync;                       # this gets the default, SDBM_File
use MLDBM qw(DB_File Storable);        # use Storable for serializing
use MLDBM qw(MLDBM::Sync::SDBM_File);  # use extended SDBM_File, handles values > 1024 bytes
use Fcntl qw(:DEFAULT);                # import symbols O_CREAT & O_RDWR for use with DBMs
use Cwd;
use File::Find;
use File::Copy;
use File::Basename;
use File::Path;
use File::Spec;
use Fcntl;
use MrpData;
use RelData;
use DirHandle; # we're recursing in CrossCheckSourceDirectory, so this is slightly nicer than DIRHANDLEs
                # (though not actually necessary, as it happens)
use Utils;
use CatData;
use Carp;
use Symbian::CBR::Component::Manifest;

#
# Constants.
#

use constant DB_NAME => "\\epoc32\\relinfo\\envdb";
use constant STATUS_CLEAN => 0;
use constant STATUS_DIRTY => 1;
use constant STATUS_PENDING_RELEASE => 2;
use constant STATUS_INFORMATION_ONLY => 5;
use constant STATUS_NOT_INSTALLED => 3;
use constant STATUS_DIRTY_SOURCE => 4;
use constant STATUS_STRING_PASSED => "clean";
use constant STATUS_STRING_FAILED => "dirty";
use constant STATUS_STRING_MISSING => "missing";
use constant STATUS_STRING_PENDING_RELEASE => "pending release";
use constant STATUS_STRING_NOT_INSTALLED => "not installed";
use constant STATUS_STRING_DIRTY_SOURCE => "binaries clean, source dirty";
use constant STATUS_STRING_INFORMATION_ONLY => "Information only";
use constant SCAN_PROGRESS_TUNER => 50;
use constant ACCEPTABLE_EVALID_FAILURES => "abld.bat"; # this is a regexp - use | to add more items. It is case-insensitive.

#
# Public.
#

sub Open {
  my $pkg = shift;
  my $iniData = shift;
  my $verbose = shift;
  
  # Check that the environment is not on an illegal volume - INC105548
  Utils::CheckIllegalVolume($iniData);

  my $dbName = Utils::PrependEpocRoot(DB_NAME);
  my $dbDir = dirname($dbName);
  unless (-e $dbDir) {
    Utils::MakeDir($dbDir);
  }
  my $db;
  {
    local $^W = 0;
    tie (%{$db}, 'MLDBM::Sync', $dbName, O_CREAT|O_RDWR, 0666) || die "Couldn't open database DB_NAME: $!\n";
  }

  my $self = {iniData => $iniData,
	      db => $db,
        mrpcache => {},
	      verbose => ($verbose || 0)};
  bless $self, $pkg;
  return $self;
}

sub Close {
  my $self = shift;
  untie %{$self};
}

sub ComponentExistsInDatabase {
  my $self = shift;
  my $comp = shift;
  
  return 1 if (exists $self->{db}->{$comp});
}

sub Version {
  my $self = shift;
  my $comp = shift;
  my $includeInformationOnlyEntries = shift;
  
  $comp = lc($comp); # Note, component names are always stored in lower case.
  my $entry = $self->{db}->{$comp};
  
  if (defined $entry) {
    if (!$includeInformationOnlyEntries && $entry->{status} eq STATUS_INFORMATION_ONLY) {
      # Some callers are not interested in information only entries
      return undef;
    }
    
    return $entry->{ver};
  }
  return undef;
}

sub VersionInfo {
  my $self = shift;
  my $includeInformationOnlyEntries = shift;
  
  my $versionInfo;
  foreach my $thisKey (keys %{$self->{db}}) {
    if (!$includeInformationOnlyEntries) {
      # Some callers are not interested in information only entries
      next if ($self->{db}->{$thisKey}->{status} eq STATUS_INFORMATION_ONLY);
    }
    
    $versionInfo->{$thisKey} = $self->{db}->{$thisKey}->{ver};
  }
  return $versionInfo;
}

sub SetVersion {
  my $self = shift;
  my $comp = lc(shift);
  my $ver = shift;

  my $entry = $self->{db}->{$comp};
  if (defined $ver) {
    if (defined $entry->{ver} and $entry->{status} != STATUS_PENDING_RELEASE) {
      $self->DeleteSignature($comp, $entry->{ver});
    }
    $entry->{ver} = $ver;

    # Write entry to database.
    $self->{db}->{$comp} = $entry;
  }
  else {
    # undefined version, so remove entry from database (if it was present).
    if (defined $entry) {
      delete $self->{db}->{$comp}
    }
  }
}

sub InternalVersion {
  my $self = shift;
  my $comp = shift;
  $comp = lc($comp); # Note, component names are always stored in lower case.
  my $entry = $self->{db}->{$comp};
  if (defined $entry) {
    return $entry->{intVer};
  }
  return undef;
}

sub SetInternalVersion {
  my $self = shift;
  my $comp = lc(shift);
  my $intVer = shift;

  my $entry = $self->{db}->{$comp};
  unless (defined $entry) {
    die "Error: $comp not found in environment database\n";
  }
  $entry->{intVer} = $intVer;

  # Write entry to database.
  $self->{db}->{$comp} = $entry;
}

sub Status {
  my $self = shift;
  my $comp = lc(shift);

  my $entry = $self->{db}->{$comp};
  unless (defined $entry) {
    die "Error: $comp not found in environment database\n";
  }

  return $entry->{status};
}

sub SetStatus {
  my $self = shift;
  my $comp = lc(shift);
  my $status = shift;

  my $entry = $self->{db}->{$comp};
  unless (defined $entry) {
    die "Error: $comp not found in environment database\n";
  }
  $entry->{status} = $status;

  # Write entry to database.
  $self->{db}->{$comp} = $entry;
}

sub StatusString {
  my $status = shift;
  if ($status == STATUS_CLEAN) {
    return STATUS_STRING_PASSED;
  }
  elsif ($status == STATUS_DIRTY) {
    return STATUS_STRING_FAILED;
  }
  elsif ($status == STATUS_PENDING_RELEASE) {
    return STATUS_STRING_PENDING_RELEASE;
  }
  elsif ($status == STATUS_DIRTY_SOURCE) {
    return STATUS_STRING_DIRTY_SOURCE;
  }
  elsif ($status == STATUS_INFORMATION_ONLY) {
    return STATUS_STRING_INFORMATION_ONLY;
  }  
}

sub CheckCompName {
  my $self = shift;
  my $comp = shift;
  die "Error: Component name can't begin with .(dot) \"$comp\".\n" if ($comp =~ m/^\./);
}

sub MrpName {
  my $self = shift;
  my $comp = lc(shift);

  my $entry = $self->{db}->{$comp};
  unless (defined $entry) {
    die "Error: $comp not found in environment database\n";
  }

  return $entry->{mrpName};
}

sub SetMrpName {
  my $self = shift;
  my $comp = lc(shift);
  my $mrpName = shift;

  my $entry = $self->{db}->{$comp};
  unless (defined $entry) {
    die "Error: $comp not found in environment database\n";
  }

  $entry->{mrpName} = $mrpName;

  # Write entry to database.
  $self->{db}->{$comp} = $entry;
}

sub ComponentsPendingRelease {
  my $self = shift;
  my %comps;
  foreach my $thisComp (keys %{$self->{db}}) {
    my $thisEntry = $self->{db}->{$thisComp};
    if ($thisEntry->{status} == STATUS_PENDING_RELEASE) {
      $comps{$thisComp} = {mrpName => $thisEntry->{mrpName},
			   ver => $thisEntry->{ver},
			   intVer => $thisEntry->{intVer}};
    }
  }
  return \%comps;
}

sub GenerateSignature {
  my $self = shift;
  my $comp = lc (shift);
  my $ver = shift;
  my $sigName = SignatureName($comp, $ver);
  open (SIG, ">$sigName") or die "Error: Couldn't open $sigName: $!\n";
  foreach my $thisBinZip (@{$self->RelevantBinaryZips($comp, $ver)}) {
    foreach my $file (@{Utils::ListZip($thisBinZip, 1)}) {
      my $fileER = Utils::PrependEpocRoot($file);
      if (-f $fileER) {
        (my $mTime, my $size) = Utils::FileModifiedTimeAndSize($fileER);
        unless (defined $size) {
          die "Error: Problem reading stats of \"$fileER\"\n";
        }
        if ($self->{verbose} > 1) {
          print "Adding signature entry for \"$file\"\n";
          print "\tmTime: $mTime (", scalar gmtime($mTime), "\n";
          print "\tsize:  $size\n";
        }
        print SIG "$file\t$mTime\t$size\n";
      }
      else {
        print "Warning: Unexpected entry in \"$thisBinZip\": \"$file\"\n         $comp $ver could be corrupt or tampered with\n";
      }
    }
  }
  close (SIG);
}

sub GenerateFakeSignature {
# As GenerateSignature, except the mtime and size of each file is set to zero.
# This is intended to be used when validating against an external baseline.
  my $self = shift;
  my $comp = lc (shift);
  my $ver = shift;
  my $sigName = SignatureName($comp, $ver);
  open (SIG, ">$sigName") or die "Error: Couldn't open $sigName: $!\n";
  foreach my $thisBinZip (@{$self->RelevantBinaryZips($comp, $ver)}) {
    foreach my $file (@{Utils::ListZip($thisBinZip)}) {
      print SIG "$file\t0\t0\n";
    }
  }
  close (SIG);
}

sub GenerateEmptySignature {
  my $self = shift;
  my $comp = lc (shift);
  my $ver = shift;
  my $sigName = SignatureName($comp, $ver);
  open (SIG, ">$sigName") or die "Error: Couldn't open $sigName: $!\n";
  close (SIG);
}

sub RemoveComponent {
  my $self = shift;
  my $comp = lc(shift);

  # Read database entry.
  my $entry = $self->{db}->{$comp};

  if (defined $entry) {
    # Remove installed binaries.
    if ($self->{verbose}) { print "Removing binaries from $comp $entry->{ver}...\n"; }
    $self->DeleteFilesInSignature($comp, $entry->{ver});
    $self->DeleteSignature($comp, $entry->{ver});

    # Remove the database entry.
    delete $self->{db}->{$comp};
  }
  else {
    print "$comp not currently installed, aborting removal of binaries\n";
  }
}

sub RefreshComponent {
  my $self = shift;
  my $comp = lc(shift);
  my $overwrite = shift;

  # Read database entry.
  my $entry = $self->{db}->{$comp};

  if (!defined $entry) {
    print "$comp not currently installed; aborting refreshing of binaries\n";
  } elsif ($entry->{status} == STATUS_PENDING_RELEASE) {
    print "$comp is pending release and cannot be refreshed; use 'preprel' to remove it from your environment\n";
  } else {
    my $ver = $entry->{ver};

    my $relData = RelData->Open($self->{iniData}, $comp, $ver, $self->{verbose}); # Dies if release not in archive
    $relData->WarnIfReleaseTooNew();

    print "Removing $comp $ver..\n";
    if ($self->{verbose}) { print "Removing binaries from $comp $ver...\n"; }
    $self->DeleteFilesInSignature($comp, $entry->{ver});

    print "Installing $comp $ver...\n";
    $self->UnpackBinaries($comp, $ver, Utils::EpocRoot(), $overwrite);

    my $status = ($self->CheckComp($comp))[0];
    if ($status == STATUS_DIRTY) {
      print "WARNING: Installed component does not match existing signature; updating signature\n";
      $self->GenerateSignature($comp, $ver);
    }
  }
}

sub DeleteSource {
  my $self = shift;
  my $thisComp = shift;
  my $dryrun = shift;
  my $force = shift;

  my $ver = $self->Version($thisComp);

  if(!defined $ver) {
    die "ERROR: Unable to obtain version for $thisComp\n";
  }

  my $reldata = RelData->Open($self->{iniData}, $thisComp, $ver, $self->{verbose});

  my $srcitems = $reldata->SourceItems;
  foreach my $thisSrcItem (keys %$srcitems) {
    # If there are mappings and the source root is \\, perform mappings on filename. Otherwise prepend source root.
    if($self->{iniData}->HasMappings() && Utils::SourceRoot() eq "\\") {
      $thisSrcItem = $self->{iniData}->PerformMapOnFileName($thisSrcItem);
    }
    else{
      $thisSrcItem = Utils::PrependSourceRoot($thisSrcItem);
    }

    if ($self->{verbose} || $dryrun) {
      my $dir = (-d $thisSrcItem)?" (directory)":"";
      my $exists = (-e $thisSrcItem)?"":" (doesn't exist)";
      my $verb = $dryrun?"Would remove":"Removing";
      print "$verb $thisSrcItem$dir$exists\n";
    }
    {
        local $SIG{__WARN__} = sub {
            my $warn = shift;
	    $warn =~ s/ at .*?EnvDb\.pm line \d+//;
	    print STDERR "WARNING: $warn";
        };
        rmtree($thisSrcItem, 0, !$force) unless $dryrun;
    }
    my $directory = dirname($thisSrcItem);
	
	my @items = @{Utils::ReadDir($directory)};

	if (scalar @items == 1 && $items[0] =~ /^distribution\.policy$/i) {
	  unlink File::Spec->catdir($directory, shift @items) unless $dryrun;
	}

    if (-e $directory && (!scalar @items)) { # No items in dir or just a distribution.policy file in dir
      rmdir $directory or die "Error: Could not remove directory $directory: $!";
      while (($directory = dirname($directory)) && -e $directory && !scalar @{Utils::ReadDir($directory)}) {
        rmdir $directory or die "Error: Could not remove directory $directory: $!";
      }
    }
  }
}

sub CheckEnv {
  my $self = shift;
  my $displayProgress = shift;
  my $ignoreStandardIgnores = shift;
  my $warnNotError = shift; # When validating the MrpData, warnings will be produced
                           # instead of errors when checking paths lengths DEF099673
  
  unless (defined $displayProgress) {
    $displayProgress = 0;
  }
  unless (defined $ignoreStandardIgnores) {
    $ignoreStandardIgnores = 0;
  }

  my $overallStatus = STATUS_CLEAN;
  my @dirtyComps;

  if ($displayProgress) {
    print "Scanning environment";
  }

  $self->InitIgnores($ignoreStandardIgnores);
  $self->ScanEnv($displayProgress);

  my @mrpData;
  my @errors;
  foreach my $thisComp (sort keys %{$self->{db}}) {
    (my $status, my $mrpData) = $self->CheckComp($thisComp, undef, $warnNotError);
    my $ver = $self->{db}->{$thisComp}->{ver};
    if ($status == STATUS_DIRTY || $status == STATUS_DIRTY_SOURCE) {
      $overallStatus = STATUS_DIRTY;
      push (@dirtyComps, {comp => $thisComp, ver => $ver});
    }
    elsif ($status == STATUS_PENDING_RELEASE) {
      unless ($overallStatus == STATUS_DIRTY) {
        $overallStatus = STATUS_PENDING_RELEASE;
      }
      if (defined $mrpData) {
        push @mrpData, $mrpData;
      }
      else {
        push @errors, "Error: Problem extracting mrp data from $thisComp\n";
      }
    }
    if ($displayProgress and not $self->{verbose}) {
      print '.';
    }
  }
  if ($displayProgress and not $self->{verbose}) {
    print "\n";
  }

  if ($#errors >= 0) {
    chomp $errors[$#errors];
    print @errors;
    die "\n";
  }

  $self->RemoveBinsToIgnore();

  my $unaccountedFiles = $self->UnaccountedEnvFiles();
  if (scalar(@$unaccountedFiles) >= 1) {
    $overallStatus = STATUS_DIRTY;
  }

  my $duplicates = $self->Duplicates(\@mrpData);
  if (scalar(@$duplicates) >= 1) {
    $overallStatus = STATUS_DIRTY;
  }

  return ($overallStatus, \@mrpData, \@dirtyComps, $unaccountedFiles, $duplicates);
}

sub CheckComp {
  my $self = shift;
  my $comp = lc(shift);
  my $keepGoing = shift;
  my $warnNotError = shift;
  
  unless (defined $keepGoing) {
    $keepGoing = 1;
  }

  my $entry = $self->{db}->{$comp};
  if (!defined $entry || $self->{db}->{$comp}->{status} == STATUS_INFORMATION_ONLY) {
    return (STATUS_NOT_INSTALLED);
  }
  my $oldstatus = $entry->{status};
  my $ver = $entry->{ver};
  die unless $ver;
  my $passed = 1;

  my $doCheck = sub {
    my $file = shift;
    my $sigMTime = shift;
    my $sigSize = shift;

    if (-e $file) { # Files might be installed in directories other than \epoc32, so do an explicit check.
      $self->CheckFileAgainstEnvScan($file);
      # Check the signature information against what is physically present in the environment.
      (my $actualMTime, my $actualSize) = Utils::FileModifiedTimeAndSize($file);
      if ($sigMTime != $actualMTime or $sigSize != $actualSize) {
        # File failed check.
        $passed = 0;
        if ($self->{verbose}) {
          print "$comp $ver $file failed check\n";
        }
        if ($self->{verbose} > 1) {
          my $printableActualMTime = gmtime($actualMTime);
          my $printableSigMTime = gmtime($sigMTime);
          print "\tcurrent mtime:   $printableActualMTime\n";
          print "\tsignature mtime: $printableSigMTime\n";
          print "\tcurrent size:    $actualSize\n";
          print "\tsignature size:  $sigSize\n";
        }
        unless ($keepGoing) {
          return 0;
        }
      }
      else {
        # File passed check.
        if ($self->{verbose} > 1) {
          print "$comp $ver $file passed\n";
        }
      }
    }
    else {
      # File missing.
      $passed = 0;
      if ($self->{verbose}) {
        print "$comp $ver $file missing\n";
      }
      unless ($keepGoing) {
        return 0;
      }
    }

    return 1;
  };

  my $mrpData;
  die unless defined $entry->{status};
  if ($entry->{status} == STATUS_PENDING_RELEASE) {
    eval {
      unless (defined $entry->{mrpName}) {
        die "Error: mrp name not specified for $comp\n";
      }
      $mrpData = $self->GetMrpData($comp);
      $mrpData->Validate($warnNotError);
      foreach my $thisBin (@{$mrpData->BinariesAndExports()}) {
	$thisBin = Utils::PrependEpocRoot($thisBin);
        $self->CheckFileAgainstEnvScan($thisBin);
      }
    };
    if ($@) {
      $mrpData = undef; # splat the MrpData in order to stop
                        # the envinfo/cleanenv.
                        # We need to do this because the only
                        # way we have of returning an error is to
                        # fail to return the MRP.
      if ($self->{verbose} == 0) {
        print "\n";
      }
      print "$comp: $@";
    }
  }
  else {
    ExecuteSignature(SignatureName($comp, $ver), $doCheck);

    if ($passed) {
      if ($oldstatus == STATUS_DIRTY) {
        $self->SetStatus($comp, STATUS_CLEAN);
      } else {
        # Here we return the original status from the environment database,
        # which is probably STATUS_CLEAN but might by STATUS_DIRTY_SOURCE
        $self->SetStatus($comp, $oldstatus);
      }
    }
    else {
      $self->SetStatus($comp, STATUS_DIRTY);
    }
  }

  return ($self->Status($comp), $mrpData);
}

sub ValidateEnv {
  my $self = shift;
  my $comp = lc(shift);
  my $ver = shift;
  my $validatesource = shift;
  my $fullbincheck = shift;

  my $validatingExternalEnv = 0;
  my $compsToValidate;
  if (defined $comp and defined $ver) {
    if (scalar (keys %{$self->{db}}) > 0) {
      die "Error: Can't validate against an external environment, because the current environment database is not empty\n";
    }
    $validatingExternalEnv = 1;
    my $relData = RelData->Open($self->{iniData}, $comp, $ver, $self->{verbose});
    $compsToValidate = $relData->Environment();
  }
  else {
    # Use the current environment.
    foreach my $thisComp (sort keys %{$self->{db}}) {
      $compsToValidate->{$thisComp} = $self->{db}->{$thisComp}->{ver};
    }
  }

  my @failedComps;
  foreach my $thisComp (sort keys %{$compsToValidate}) {
    my $thisVer = $compsToValidate->{$thisComp};
    my $result = $self->ValidateComp($thisComp, $thisVer, 0, $validatesource, 0, $fullbincheck);
    if ($result == STATUS_DIRTY || $result == STATUS_DIRTY_SOURCE) {
      push (@failedComps, $thisComp);
      if ($validatingExternalEnv) {
        # Add an entry even of components that failed. This makes it easier for the user to specify what needs to be re-released.
        $self->SetVersion($thisComp, $thisVer);
        if ($result == STATUS_DIRTY) {
          $self->GenerateFakeSignature($thisComp, $thisVer);
        } elsif ($result == STATUS_DIRTY_SOURCE) {
          $self->GenerateSignature($thisComp, $thisVer);
        }
        $self->SetStatus($thisComp, $result);
        my $relData = RelData->Open($self->{iniData}, $thisComp, $thisVer, $self->{verbose});
        $self->SetMrpName($thisComp, $relData->MrpName());
        $self->SetInternalVersion($thisComp, $relData->InternalVersion());
      }
    }
  }

  return \@failedComps;
}

sub ValidateCompOld {
  my $self = shift;
  my $comp = lc(shift);
  my $ver = shift;
  my $keepGoing = shift;
  my $validatesource = shift;
  my $keeptemp = shift;
  my $fullbincheck = shift;
  unless (defined $keepGoing) {
    $keepGoing = 1;
  }

  my $status = STATUS_CLEAN;
  die unless defined $ver;

  my $entry = $self->{db}->{$comp};
  if (defined $entry and $entry->{status} == STATUS_PENDING_RELEASE) {
    if ($ver eq $entry->{ver}) { # allow validation against other versions even if we're pending release
      return STATUS_PENDING_RELEASE;
    }
  }

  my $relData = RelData->Open($self->{iniData}, $comp, $ver, $self->{verbose});

  # Always validate binaries
  # I initially added an option to turn this off, but I decided that was overcomplexity
  # and I couldn't think of any use cases except tinkering with the release tools...
  print "Validating binaries $comp $ver...\n";
  Utils::InitialiseTempDir($self->{iniData});
  eval {
    # Get a temporary copy of the released binaries.
    my $tempDir = Utils::TempDir();
    $self->UnpackBinaries($comp, $ver, $tempDir, 1); # 1 = overwrite

    # Call evalid to compare these with those installed in the environment.
    # We now validate everything in the temp dir, not just \epoc32,
    # because some components release binaries outside \epoc32.
    my $clean = $self->EvalidateDirectories($tempDir, Utils::PrependEpocRoot('.'), $keepGoing);
    $status = ($clean)?(STATUS_CLEAN):(STATUS_DIRTY);

    if ($clean and $fullbincheck) {
      # Ask the current mrp file for a list of binaries (using abld -what)
      my $mrpData;

      my $mrpPath = $relData->MrpName();
      if($self->{iniData}->HasMappings() && Utils::SourceRoot() eq "\\") {
        $mrpPath = $self->{iniData}->PerformMapOnFileName($mrpPath);
      }
      else{
        $mrpPath = Utils::PrependSourceRoot($mrpPath);
      }
      if (!-f $mrpPath) {
        print "Not checking for new binaries; MRP file not present\n";
      } else {
        eval {
          $mrpData = New MrpData($relData->MrpName(), undef, undef, $self->{iniData}, $self->{verbose}); # undef = we're not preprel-ing it
        };

        if (!defined($mrpData)) {
          my $error = $@;
          $error =~ s/\s*$//;
          print "Not checking for new binaries; $error\n";
        } else {
          my @binaries = @{$mrpData->Binaries()};
          push @binaries, @{$mrpData->Exports()};

          # Get list of binaries in the temporary copy
          my %oldbinaries;

          my $sub = sub { # Subroutine to add files to %oldbinaries
            return if -d $_; # Check it's not a directory
            s/^\Q$tempDir\E[\/\\]?//; # Strip the temp dir path off
            s/\\/\//g; # Convert backslashes
            $oldbinaries{lc($_)}=1 unless (/^\.\.?$/) # Add to hash (unless it's .. or .)
          };

          find( {wanted=>$sub, no_chdir=>1}, $tempDir); # Use no_chdir and s/.../ to get a full relative path. Second s/.../ converts backslashes to normal slashes
          foreach my $binary (@binaries) {
            $binary = lc($binary);
            $binary =~ s/\\/\//g; # Convert backslashes to normal slashes
            if (exists $oldbinaries{$binary}) {
              delete $oldbinaries{$binary};
            } else {
              print "New binary file: $binary\n";
              $status = STATUS_DIRTY;
            }
          }
          foreach my $oldbinary (keys(%oldbinaries)) {
            print "Binary file no longer built: $oldbinary\n";
	    $status = STATUS_DIRTY;
          }
	}
      }
    }
  };

  if ($keeptemp) {
    print "Old release stored in \"".Utils::TempDir()."\"\n";
  } else {
    Utils::RemoveTempDir();
  }
  if ($@) {
    die $@;
  }

  # We need to check if the categories for exports has changed or not...
  if ($status == STATUS_CLEAN) {
    foreach my $thisBinZip (@{$self->RelevantBinaryZips($comp, $ver)}) {

      if($thisBinZip =~ /exports([a-z]).zip/i) {
        my $catInArchive = $1;
        # Open and read the corresponding exports category info file in the archive
        my $catData = CatData->Open($self->{iniData}, $comp, $ver, $catInArchive);
        my $catWriteInCatDataFile;

        # Obtain the category written the exports category info file, if unable to read skip check
        eval {
          $catWriteInCatDataFile = $catData->Category();
        };
        if ($@) {
          last;
        }
        # Check the categories match
        if($catInArchive !~ /^$catWriteInCatDataFile$/i){
          die "ERROR: Mismatch in category found in exports$catInArchive.txt for $comp $ver\n";
        }

        my $exportinfo = $catData->ExportInfo();
        my $destinationDirBuffer;

        # Using the export infomation as read for the exports category info file check the category of the export file.
        foreach my $export (sort(keys %{$exportinfo})) {
          my $destinationDir;
          my $classifySourceFlag = 1; # Classify source using function ClassifySourceFile only if set as 1;
          my $destination = $catData->ExportSource($export);

          # Consider any mappings if defined
          if($self->{iniData}->HasMappings()){
            $destination = $self->{iniData}->PerformMapOnFileName($destination);
          }

          if(defined $destinationDirBuffer){
            ($destinationDir) = Utils::SplitFileName($destination);

            if($destinationDirBuffer =~ /^\Q$destinationDir\E$/i){
              $classifySourceFlag = 0;
            }
          }

          my $absolute_path = Utils::PrependSourceRoot($destination);

    	  # validate only if source validation is requested or the source is present
    	  if($classifySourceFlag and ($validatesource or -e $absolute_path)){
                # Obtain the category from the source destinaton extracted for the exports category info file
    	    my ($catInEnv, $errors) = Utils::ClassifyPath($self->{iniData}, $destination, 0, 0, $comp); # verbose = 0 and logErrors = 0
    	    if ($catInEnv !~ /^$catInArchive$/i){
                  print "Change in category found (ENV) \"$catInEnv\" : (Archive) \"$catInArchive\" using $thisBinZip for file $export\n";
    	      $status = STATUS_DIRTY;
    	      last;
    	    }

    	    $destinationDirBuffer = Utils::SplitFileName($destination);
    	  }
        }
      }
    }
  }

  # We only bother validating source if we've discovered the binaries are clean.
  # This implies that STATUS_DIRTY means the binaries are dirty, but the status of
  # the source code is undefined.
  if ($validatesource && $status == STATUS_CLEAN) {
    print "Validating source for $comp $ver...\n";
    Utils::InitialiseTempDir($self->{iniData});
    eval {
      # Get a temporary copy of the released source.
      my $tempDir = Utils::TempDir();

      my $changeInCat = $self->UnpackSource($comp, $ver, $tempDir, 1, 0, 1); # 1 = overwrite, 0 = do not show progress, 1 = validate

      if($changeInCat){
	print "Change in category found for $comp...\n";
        $status = STATUS_DIRTY_SOURCE;
      }

      # The following code is the only place where a component can have its
      # status set to "dirty source code". This status was added when
      # the -s switch was added to ValidateEnv/Rel to validate source code.
      # It would have been simpler to just set a component to 'dirty' when
      # the source code was dirty, but this was not possible for the following
      # reason. When envinfo -f gathers the state information of a component
      # (or, for that matter, some other command checks the environment is clean)
      # this calls the CheckComp function. This ignores the status stored in
      # the environment database, and works it out afresh from the timestamps
      # on the individual files. Hence we needed to add a new status which
      # CheckComp would propagate through, so it can report the status
      # on envinfo. (Otherwise we would have to change CheckComp
      # so it also checked the status of each source code file eacb
      # time).
      #
      # It would be nice here to ensure we have all the source
      # installed, but I don't think there's a nice way of finding
      # out the directory that the source comes in. (Not without
      # unzipping the zip, and we might as well just evalidate it...)
      #
      # This grim \. thing is not homage to the Great Geek Website
      # It is because evalid gets grumpy if you give it either \ or ''
      # as an argument. The first time is because \\ isn't a valid
      # directory separator in Win32 (!!) and the second is because
      # Perl doesn't think '' is a valid directory (which is probably
      # fair enough). Rather than file a defect against Windows,
      # let's pass in slightly silly arguments to evalid.
      if ($status == STATUS_CLEAN) {
        print "Checking for changed or removed files\n" if ($self->{verbose});
        my $clean = $self->EvalidateDirectories($tempDir, Utils::PrependSourceRoot('.'), $keepGoing);
        $status = STATUS_DIRTY_SOURCE unless ($clean);
      }
      # The above checks will only have found changed or removed files.
      # Files that have been added to the source won't be in the $tempDir,
      # so evalid won't pick them up and test them. So we have to
      # explicitly check for added files.
      # Only bother doing this if we haven't found problems already.
      if ($status == STATUS_CLEAN) {
        # Recurse through each directory in the temp dir, listing the
        # equivalent dir on the drive (i.e. the latest source). If there
        # are more files on the drive than in the source tree, source
        # is dirty.
        print "Checking for added files\n" if ($self->{verbose});
        eval {
          $status = STATUS_DIRTY_SOURCE if ($self->CheckForAddedFiles($relData, $tempDir));
        };
        if ($@) {
          print "Warning: skipping the check for added files, for the component \"$comp\". All other source code validation checks passed. The reason is: $@";
        }
      }
    };
    Utils::RemoveTempDir();
    if ($@) {
      die $@;
    }
  }

  if ($status == STATUS_CLEAN) {
    # Previously this SetVersion line was wrapped in an "if", so that
    # it didn't happen if $entry was defined - i.e. it was already in the
    # environment database. After discussion with Joe and James this behaviour
    # has been changed.
    $self->SetVersion($comp, $ver);
    $self->SetStatus($comp, $status);
    $self->GenerateSignature($comp, $ver);
    $self->SetMrpName($comp, $relData->MrpName());
    $self->SetInternalVersion($comp, $relData->InternalVersion());
  }
  elsif ($entry && $entry->{status} &&
    $entry->{status} == STATUS_PENDING_RELEASE) {
    # Old status was pending release; so we don't do anything
  }
  elsif ($status == STATUS_DIRTY) {
    if (defined $entry) {
      # The component used to be in the environment database
      # We set its status in case it used to be STATUS_DIRTY_SOURCE
      # and it's now STATUS_DIRTY.
      $self->SetStatus($comp, $status);
    }
    # This component wasn't previously in the environment database;
    # do nothing
  }
  elsif ($status == STATUS_DIRTY_SOURCE) {
    if (defined $entry) {
      $self->SetStatus($comp, $status);
      $self->GenerateSignature($comp, $ver);
      # Because otherwise any 'envinfo' will reset a component status
      # to dirty, even if only its source is dirty
    }
  }
  print "Status ", StatusString($status), "\n";
  return $status;
}

sub ValidateComp {
	my $self = shift;
	my $comp = lc(shift);
	my $ver = shift;
	my $keepGoing = shift;
	my $validatesource = shift;
	my $keeptemp = shift;
	my $fullbincheck = shift;
	unless ( defined $keepGoing ) {
	  $keepGoing = 1;
	}
	my $manifestFromThisComponent = undef;
	my $status = STATUS_CLEAN;
	die unless defined $ver;

	my $entry = $self->{db}->{$comp};
	if (defined $entry and $entry->{status} == STATUS_PENDING_RELEASE) {
		if ($ver eq $entry->{ver}) { # allow validation against other versions even if we're pending release
			return STATUS_PENDING_RELEASE;
		}
	}

	#Create a relData object for retrieving the mrpPath required for building the manifest object
	my $relData = RelData->Open( $self->{iniData}, $comp, $ver, $self->{verbose} );

	#Find the archive location for release and build the file path for loading the manifest file from the location
	my $relDir = $relData->{iniData}->PathData->LocalArchivePathForExistingComponent( $comp, $ver );
	my $manifestPath = File::Spec->catfile( $relDir, MANIFEST_FILE );

	#Check if manifest file exists
	if (-e $manifestPath) {
	#Define callback to validate files which don't have checksum defined in manifest file.
	my $callback = sub {
		my $filesToValidate = shift;
		my $manifestObject = shift;
		my $keepGoing = shift;
		{
			local $" = ", ";
			print "No checksum found for file(s) @{$filesToValidate} - reverting to old evalid process.\n";
		}
		Utils::InitialiseTempDir($self->{iniData});
		my $tempDir = Utils::TempDir();
		my $epocFilePath = Utils::EpocRoot();
		my $sourceFilePath = Utils::SourceRoot();
		my $fullEvalidName = Utils::FindInPath('evalid.bat');
		my $clean = 1;
		my @files;
		foreach  my $thisFile (@{$filesToValidate}) {
			my $zipName;
			my $file;
			my $fileContentType = $manifestObject->GetFileInfo($thisFile, CONTENT_TYPE);
			if ($fileContentType  eq 'source' or $fileContentType  eq 'export') {
				my $cat = $manifestObject->GetFileInfo($thisFile, IPR_CATEGORY);
				if ($fileContentType eq 'source') {
					$zipName = "source".$cat;
					$file = File::Spec->catfile($sourceFilePath, $thisFile) 
				} else {
					$zipName = "exports".$cat;
					$file = File::Spec->catfile($epocFilePath, $thisFile);
				}
			}
			elsif ($fileContentType eq 'binary') {
				my $platForm = $manifestObject->{files}{$thisFile}{'platform'}; 
				if (defined $platForm) {
					$zipName = "binaries"."_".$platForm;
				}
				else {
					$zipName = "binaries";
				}
				$file = File::Spec->catfile($epocFilePath, $thisFile);
			}
			$zipName = $zipName.".zip";
			my $zipPath = File::Spec->catfile($relDir,$zipName);  
			Utils::UnzipSingleFile($zipPath,$thisFile, $tempDir, $self->{verbose}, 1, $comp); #overwrite = 1
			push @files, [$thisFile, $file];
		}
		foreach my $thisFile (@files) {
			my $firstPath = File::Spec->catfile($tempDir,shift(@$thisFile));
			my $secondPath = shift(@$thisFile);
			open EVALID, "$fullEvalidName -c $firstPath $secondPath|" or die "Error: Couldn't run EValid: $!\n";
			my $thisLine;
			my $acceptablefailures = ACCEPTABLE_EVALID_FAILURES;
			while ($thisLine = <EVALID>) {
				if ($thisLine =~ m/MISSING:|FAILED:|PROBLEM:/ && $thisLine !~ m/$acceptablefailures/i) {
					print $thisLine  if ($self->{verbose});
					$clean = 0;
					unless ($keepGoing) {
						Utils::RemoveTempDir();
						return $clean;
					}
				}
			}
		}
		Utils::RemoveTempDir();
		return $clean;
	};

	#Load the manifest file to create a manifest object
	my $manifestFromBaselineComponent = Symbian::CBR::Component::Manifest->new( $manifestPath );

	my $mrpPath = Utils::RelativeToAbsolutePath( $relData->MrpName(), $self->{iniData}, SOURCE_RELATIVE );

	if ($fullbincheck && -e $mrpPath) {
		$manifestFromThisComponent = Symbian::CBR::Component::Manifest->new($mrpPath);
	} else {
		if ($fullbincheck) {
			print "Not checking for new binaries; MRP file not present\n";
		}

		$manifestFromThisComponent = Symbian::CBR::Component::Manifest->new($manifestPath);
		$manifestFromThisComponent->RefreshMetaData($comp, $ver);
	}

	#Compare the manifest objects
	eval {$status = $manifestFromThisComponent->Compare($manifestFromBaselineComponent, $validatesource, $keepGoing,$callback)};

	#Check if Compare() completed without errors
	if (!$@) {

		#If $keeptemp set, unpack binaries to temp location
		if ( $keeptemp ) {

			Utils::InitialiseTempDir($self->{iniData});
			# Get a temporary copy of the released binaries.
			my $tempDir = Utils::TempDir();
			$self->UnpackBinaries($comp, $ver, $tempDir, 1); # 1 = overwrite

			#If $validatesource is set, get temp copy of released sources
			$self->UnpackSource($comp, $ver, $tempDir, 1, 0, 1) if $validatesource;

			print "Old release stored in \"".Utils::TempDir()."\"\n";
		}

		#If status is dirty, save manifest to temp location
		$self->SaveManifestToTempDir($comp, $manifestFromThisComponent) if $status == STATUS_DIRTY;

		#Update the environemnt as done by validatecompold
		$self->UpdateEnvironment( $status, $entry, $relData );

		print "Status ", StatusString($status), "\n";
		return $status;
	}

	else {
		print "$@Continuing with old validaterel process..\n";
	}

	}
	else {
		print "Manifest file does not exist in the version $ver for component $comp..\nContinuing with old validaterel process..\n";
	}

	#Call the old validaterel process if manifest comparison is not possible
	$status = $self->ValidateCompOld( $comp, $ver, $keepGoing, $validatesource, $keeptemp, $fullbincheck );

	#If status is dirty during validatecompold, still we want to save manifest to temp location
	if ( defined $manifestFromThisComponent and ($status == STATUS_DIRTY or $status == STATUS_DIRTY_SOURCE) ) {
		$self->SaveManifestToTempDir($comp, $manifestFromThisComponent);
	}

	return $status;
}

sub UpdateEnvironment {
	my $self = shift;
	my $status = shift;
	my $entry = shift;
	my $relData = shift;

	my $comp = $relData->Component();
	my $ver = $relData->Version();

	if ($status == STATUS_CLEAN) {
		# Previously this SetVersion line was wrapped in an "if", so that
		# it didn't happen if $entry was defined - i.e. it was already in the
		# environment database. After discussion with Joe and James this behaviour
		# has been changed.
		$self->SetVersion( $comp, $ver );
		$self->SetStatus( $comp, $status );
		$self->GenerateSignature( $comp, $ver );
		$self->SetMrpName( $comp, $relData->MrpName() );
		$self->SetInternalVersion( $comp, $relData->InternalVersion() );
	}
	elsif ($entry && $entry->{status} &&
		$entry->{status} == STATUS_PENDING_RELEASE) {
		# Old status was pending release; so we don't do anything
	}
	elsif ($status == STATUS_DIRTY) {
		if (defined $entry) {
			# The component used to be in the environment database
			# We set its status in case it used to be STATUS_DIRTY_SOURCE
			# and it's now STATUS_DIRTY.
			$self->SetStatus( $comp, $status );
		}
		# This component wasn't previously in the environment database;
		# do nothing
	}
	elsif ($status == STATUS_DIRTY_SOURCE) {
		if (defined $entry) {
			$self->SetStatus( $comp, $status );
			$self->GenerateSignature( $comp, $ver );
			# Because otherwise any 'envinfo' will reset a component status
			# to dirty, even if only its source is dirty
		}
	}
}

sub SaveManifestToTempDir {
	my $self = shift;
	my $comp = shift;
	my $manifestFromThisComponent = shift;

	my $manifestTempFile = "manifest_".$comp.".xml";
	my $manifestFile = $manifestFromThisComponent->Save( File::Spec->tmpdir(), $manifestTempFile );
#	my $manifestTempFile = File::Spec->catfile( File::Spec->tmpdir(), "manifest_".$comp.".xml" );
#	rename( $manifestFile, $manifestTempFile );
}

sub Duplicates {
  my $self = shift;
  my $mrpData = shift;
  my $installedComps = $self->VersionInfo();
  my %binHash;
  my @duplicates;

  # First cross-check against the components about to be released.
  foreach my $thisMrp (@{$mrpData}) {
    my $comp = lc($thisMrp->Component());
    my $bins = $thisMrp->BinariesAndExports();
    foreach my $thisBin (@$bins) {
      $thisBin = lc(Utils::PrependEpocRoot($thisBin));

      print "Checking $thisBin for duplicateness (pending release)\n" if ($self->{verbose}>1);
      if (exists $binHash{$thisBin}) {
 	push @duplicates, [$thisBin, $comp, $binHash{$thisBin}]; # $comp attempting to release $thisBin which has already been released by $binHash{$thisBin}";
      }
      else {
	$binHash{$thisBin} = $comp;
      }
    }
    delete $installedComps->{$comp};
  }

  # Now cross-check against the other components in the environment.
  foreach my $thisComp (keys %{$installedComps}) {
    my $doCheck = sub {
      my $file = lc(shift);
      print "Checking $file for duplicateness\n" if ($self->{verbose}>1);
      if (exists $binHash{$file}) {
	push @duplicates, [$file, $binHash{$file}, $thisComp]; #"$binHash{$file} attempting to release $file which has already been released by $thisComp";
      }
      else {
	$binHash{$file} = $thisComp;
      }
    };
    my $sigName = SignatureName($thisComp, $installedComps->{$thisComp});
    ExecuteSignature($sigName, $doCheck);
  }

  return \@duplicates;
}

sub BinaryInfo {
  my $self = shift;
  my $binary = shift;
  unless (-e $binary) {
    die "Error: \"$binary\" does not exist\n";
  }

  (my $currentMTime, my $currentSize) = Utils::FileModifiedTimeAndSize($binary);
  my $sigMTime;
  my $sigSize;
  my $sigName;

  my $findBin = sub {
    my $file = shift;
    if (lc($binary) eq lc($file)) {
      $sigMTime = shift;
      $sigSize = shift;
      $sigName = shift;
      return 0;
    }
    return 1; # Means continue;
  };
  ExecuteAllSignatures($findBin);

  my $comp;
  my $ver;
  my $pendingRelease = 0;

  if (defined $sigMTime and defined $sigName) {
    ($comp, $ver) = $self->DecodeSignatureName($sigName);
  }
  else {
    # Binary not found in the signatures, so check for components pending release.
    if (Utils::WithinEpocRoot($binary)) {
	      $binary = Utils::RemoveEpocRoot($binary); # remove EPOCROOT
    }
    $binary =~ s!^[\\\/]!!; # remove leading slash

    foreach my $thisComp (keys %{$self->{db}}) {
      if ($self->Status($thisComp) == STATUS_PENDING_RELEASE) {
        my $thisVer = $self->{db}->{$thisComp}->{ver};
        my $thisMrpData = $self->GetMrpData($thisComp);
        $thisMrpData->EnsureDoesNotExist();

        if (grep /^\Q$binary\E$/i, @{$thisMrpData->Binaries()}) {
          $pendingRelease = 1;
          $comp = $thisComp;
          $ver = $thisVer;
          last;
        }
        elsif (grep /^\Q$binary\E$/i, @{$thisMrpData->Exports()}) {
          $pendingRelease = 1;
          $comp = $thisComp;
          $ver = $thisVer;
          last;
        }
      }
    }
    unless (defined $comp and defined $ver) {
      my $ignoreList = $self->{iniData}->BinariesToIgnore();
      push (@$ignoreList, Utils::PrependEpocRoot('\\epoc32\\relinfo\\*'));
      foreach my $ignore (@$ignoreList) {
      $ignore =~ s/\\/\\\\/g;
      $ignore =~ s/\./\\\./g;
      $ignore =~ s/\*/\.\*/g;

      if ($binary !~ /^\\/) {
        $ignore =~ s/^\\*//;
      }

      if ($binary =~ /^$ignore$/i) {
        die "Error: no information available for \"$binary\". It is not part of any component, but it is ignored by the 'ignore_binary' rule '$ignore'. This rule might be in your reltools.ini, or it might be one of the standard ignores.\n";
      }
      }
      die "Error: No information available for \"$binary\". It's not even one of the files/directories that are ignored as standard.\n";
    }
  }

  my $info;
  push (@$info, ['Component:', $comp]);
  push (@$info, ['Version:', $ver]);
  if ($pendingRelease) {
    push (@$info, ['Status:', 'pending release']);
  }
  elsif ($currentMTime == $sigMTime and $currentSize == $sigSize) {
    push (@$info, ['Status:', 'clean']);
  }
  else {
    push (@$info, ['Status:', 'dirty']);
  }

  return $info;
}

sub ListBins {
  my $self = shift;
  my $comp = shift;
  my $ver = $self->Version($comp);
  die unless $ver;

  if ($self->Status($comp) == STATUS_PENDING_RELEASE) {
    $self->ListBinsPendingRelease($comp, $ver);
  } else {
    $self->ListBinsStandard($comp, $ver);
  }
}

sub GetMrpData {
  my $self = shift;
  my $compname = lc(shift);
  my $entry = $self->{db}->{$compname};
  die "Invalid component name \"$compname\"" unless $entry;

  my $name = $entry->{mrpName};
  unless ($self->{mrpcache}->{$name}) {
    my $mrpData = MrpData->New($entry->{mrpName}, $entry->{ver}, $entry->{intVer}, $self->{iniData}, $self->{verbose});
    my $namefrommrp = $mrpData->Component();
    die "Error: Component name in MRP file is \"$namefrommrp\" whilst the name of this component in the environment database is \"$compname\".\n" unless (lc $compname eq lc $namefrommrp);
    $self->{mrpcache}->{$name} = $mrpData;
  }
  return $self->{mrpcache}->{$name};
}


sub GetMRPLocations {
  my $self = shift;
  my $componentName = lc(shift);
  
  # If only the MRP location for a specified component is required...
  if ($componentName) {
    if (exists $self->{db}->{$componentName}) {
      return (Utils::PrependSourceRoot($self->{db}->{$componentName}->{mrpName}));
    }
    else {
      return undef;
    }
  }

  # Otherwise all MRP locations are returned to the caller
  my @mrpLocations;
  
  foreach my $component (keys %{$self->{db}}) {
    push @mrpLocations, Utils::PrependSourceRoot($self->{db}->{$component}->{mrpName});
  }
  
  return @mrpLocations;  
}

#
# Private.
#

sub ListBinsStandard {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  my $info;
  push (@$info, ['File', 'Status']);

  my $sigName = SignatureName($comp, $ver);
  my $gatherInfo = sub {
    my $file = shift;
    my $sigMTime = shift;
    my $sigSize = shift;

    if (-e $file) {
      (my $actualMTime, my $actualSize) = Utils::FileModifiedTimeAndSize($file);
      if (!defined $actualMTime or !defined $actualSize) {
	die "Error: Problem stating \"$file\"\n";
      }
      elsif ($sigMTime != $actualMTime or $sigSize != $actualSize) {
	push (@$info, [$file, STATUS_STRING_FAILED]);
      }
      else {
	push (@$info, [$file, STATUS_STRING_PASSED]);
      }
    }
    else {
      push (@$info, [$file, STATUS_STRING_MISSING]);
    }

    return 1; # Means continue with next line in signature.
  };

  ExecuteSignature($sigName, $gatherInfo);
  return $info;
}

sub ListBinsPendingRelease {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;

  my $mrpData = $self->GetMrpData($comp);

  my @info;
  push @info, ['File', 'Status', 'Category'];
  foreach my $cat (@{$mrpData->BinaryCategories()}) {
    foreach my $file (@{$mrpData->Binaries($cat)}) {
      push @info, [$file, 'pending release', $cat];
    }
  }
  foreach my $cat (@{$mrpData->ExportCategories()}) {
    foreach my $file (@{$mrpData->Exports($cat)}) {
      push @info, [$file, 'pending release', $cat];
    }
  }
  # To do ideally: add another column to report which bld.inf each binary
  # comes from (if any). This requires quite a lot of internal restructuring
  # of MrpData.pm so will probably never happen... It's not worth the benefits.
  return \@info;
}

sub DESTROY {
  my $self = shift;
  $self->Close();
}

sub EvalidateDirectories {
  my $self = shift;
  my $firstdirectory = shift;
  my $seconddirectory = shift;
  my $keepGoing = shift;

  my $clean = 1;
  my $fullEvalidName = Utils::FindInPath('evalid.bat');

  # Call evalid to compare these with those installed in the environment.
  if ($self->{verbose} > 1) {
    print "Evalid command is $fullEvalidName -c $firstdirectory $seconddirectory\n";
  }
  open EVALID, "$fullEvalidName -c $firstdirectory $seconddirectory|" or die "Error: Couldn't run EValid: $!\n";
  my $thisLine;
  while ($thisLine = <EVALID>) {
    my $acceptablefailures = ACCEPTABLE_EVALID_FAILURES;
    if ($thisLine =~ m/MISSING:|FAILED:|PROBLEM:/ && $thisLine !~ m/$acceptablefailures/i) {
      if ($self->{verbose}) { print $thisLine; }
      $clean = 0;
      unless ($keepGoing) {
        last;
      }
    }
    elsif ($self->{verbose} > 1) {
      print $thisLine;
    }
  }
  close EVALID;

  return $clean;
}

sub ScanEnv {
  my $self = shift;
  my $displayProgress = shift;
  my $progressTuner = 0;

  my $processFileSub = sub {
    if ($displayProgress) {
      ++$progressTuner;
      if ($progressTuner >= SCAN_PROGRESS_TUNER) {
        $progressTuner = 0;
        select STDOUT; $|=1;
        print ".";
      }
    }
    my $thisFile = lc($File::Find::name);
    Utils::TidyFileName(\$thisFile);
    if (-f $thisFile) {
      $self->{envFileList}->{$thisFile} = 1;
    }
    elsif (-d $thisFile and $self->CheckIgnoreDir($thisFile)) {
      $File::Find::prune = 1;
    }
    elsif (-d $thisFile && !@{Utils::ReadDir($thisFile)}) {
      # This is an empty directory.  It is not possible to own empty directories,
      #so this will be included in the unowned list
      $self->{envFileList}->{$thisFile} = 1;
    }
  };

  my $cwd = cwd();
  $cwd =~ s/:$/:\\/; # Needed because if at root, cwd() just returns drive_letter:
  find($processFileSub, Utils::PrependEpocRoot('\\epoc32'));
  chdir ($cwd);
  if ($displayProgress and $self->{verbose}) {
    print "\n";
  }
}

sub CheckIgnoreDir {
  my $self = shift;
  my $dir = shift;
  if (exists $self->{ignoreDirs}->{$dir}) {
    return 1;
  }
  return 0;
}

# Classify the ignores according to whether they correspond to directories or files. This allows the
# File::Find scan to prune directories to be ignored efficiently.
sub InitIgnores {
  my $self = shift;
  my $ignoreStandardIgnores = shift;
  my $ignoreList;
  unless ($ignoreStandardIgnores) {
    $ignoreList = $self->{iniData}->BinariesToIgnore();
  }
  push (@$ignoreList, '\\epoc32\\relinfo\\*'); # Need to always ignore \epoc32\relinfo since this contains the environment database.

  foreach my $thisIgnore (@$ignoreList) {
    if ($thisIgnore =~ /(.*)\\\*$/) {
      my $dir = $1;
      Utils::TidyFileName(\$dir);
      $self->{ignoreDirs}->{lc(Utils::PrependEpocRoot($dir))} = 1;  # Store dirs in a hash so they can be looked up fast.
    }
    else {
      push (@{$self->{ignoreFiles}}, Utils::PrependEpocRoot($thisIgnore));
    }
  }
}

sub CheckFileAgainstEnvScan {
  my $self = shift;
  my $file = lc(shift);
  my $ok = 1;

  if (exists $self->{envFileList}) {
    if (exists $self->{envFileList}->{$file}) {
      # Exists, so remove from envFileList hash - any file names left in here at the end will be reported to the user.
      delete $self->{envFileList}->{$file};
    }
    else {
      $ok = 0;
    }
  }
  elsif (not -e $file) {
    $ok = 0;
  }
  return $ok;
}

sub RemoveBinsToIgnore {
  my $self = shift;
  foreach my $thisIgnore (@{$self->{ignoreFiles}}) {
    $thisIgnore =~ s/\\/\\\\/g;
    $thisIgnore =~ s/\./\\\./g;
    $thisIgnore =~ s/\*/\.\*/g;
    foreach my $thisFile (keys %{$self->{envFileList}}) {
      if ($thisFile =~ /$thisIgnore/i) {
	delete $self->{envFileList}->{$thisFile};
      }
    }
  }
}

sub UnaccountedEnvFiles {
  my $self = shift;
  my @unaccountedFiles = sort keys %{$self->{envFileList}};
  return \@unaccountedFiles;
}

sub DeleteSignature {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  
  if ($self->{verbose} > 1) { print "Deleting signature file for $comp $ver\n"; }
  my $sigName = SignatureName($comp, $ver);
  unlink ($sigName) or print "Warning: Couldn't delete $sigName: $!\n";
}

sub ExecuteAllSignatures {
  my $sub = shift;

  opendir(DIR, Utils::PrependEpocRoot("\\epoc32\\relinfo")) or die "Error: Couldn't open directory \"" . Utils::PrependEpocRoot("\\epoc32\\relinfo") . "\": $!\n";
  while (defined(my $file = readdir(DIR))) {
    if ($file =~ /\.sig$/) {
      my $continue = ExecuteSignature(Utils::PrependEpocRoot("\\epoc32\\relinfo\\$file"), $sub);
      unless ($continue) {
	last;
      }
    }
  }
  closedir(DIR);
}

sub ExecuteSignature {
# For each line in the signature file, parse and call the given subroutine with the parsed variables.

  my $sigName = shift;
  my $filessub = shift;
  my $directoriesSub = shift;

  my %directories;

  my $continue = 1;
  open (SIG, $sigName) or die "Couldn't open $sigName for reading: $!\n";
  while (my $line = <SIG>) {
    # Parse signature line.
    (my $file, my $mTime, my $size) = split (/\t/, $line);
    unless (defined $file and defined $mTime and defined $size) {
      die "Error: Invalid line in signature file $sigName\n";
    }
    $directories{dirname($file)} = 1;
    # Call subroutine.
    $continue = &$filessub(Utils::PrependEpocRoot($file), $mTime, $size, $sigName);
    unless ($continue) {
      last;
    }
  }
  close (SIG);

  if ($directoriesSub) {
    foreach my $directory (sort keys %directories) {
      &$directoriesSub(Utils::PrependEpocRoot($directory), $sigName);
    }
  }

  return $continue;
}

sub DeleteFilesInSignature {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $sigName = SignatureName($comp, $ver);
  my $filesDeletionSub = sub {
    my $file = shift;
    if (-e $file) {
      if ($self->{verbose} > 1) { print "Deleting \"$file\"...\n"; }
      unlink ($file) or die "Error: Couldn't delete \"$file\": $!\n";
    }
    return 1;
  };
  my $directoriesDeletionSub = sub {
    my $directory = shift;

    if (-e $directory && !scalar @{Utils::ReadDir($directory)} ) {
      print "Removing directory $directory...\n" if ($self->{verbose});
      rmdir $directory or die "Error: Could not remove directory $directory: $!\n";
      while (($directory = dirname($directory)) && -e $directory && !scalar @{Utils::ReadDir($directory)}) {
        print "Removing directory $directory...\n" if ($self->{verbose});
        rmdir $directory or die "Error: Could not remove directory $directory: $!\n";
      }
    }
  };

  ExecuteSignature($sigName, $filesDeletionSub, $directoriesDeletionSub);
}

sub InstallComponent {
  my $self = shift;
  my $comp = lc(shift);
  my $ver = shift;
  my $overwrite = shift;

  my $relData = RelData->Open($self->{iniData}, $comp, $ver, $self->{verbose});
  $relData->WarnIfReleaseTooNew();
  $self->UnpackBinaries($comp, $ver, Utils::EpocRoot(), $overwrite);
  $self->GenerateSignature($comp, $ver);
  $self->SetVersion($comp, $ver);
  $self->SetMrpName($comp, $relData->MrpName());
  $self->SetInternalVersion($comp, $relData->InternalVersion());
  $self->SetStatus($comp, STATUS_CLEAN);
}

sub UnpackBinaries {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $where = shift;
  my $overwrite = (shift || $self->{overwrite});
  foreach my $thisBinZip (@{$self->RelevantBinaryZips($comp, $ver)}) {
    $overwrite = Utils::Unzip($thisBinZip, $where, $self->{verbose}, $overwrite);
  }
  
  $self->{overwrite} = $overwrite;
}

sub RelevantBinaryZips {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  $self->PathData()->CheckReleaseExists($comp, $ver);

  my $requiredBinaries = $self->{iniData}->RequiredBinaries($comp);
  my $relDir = $self->PathData->LocalArchivePathForExistingOrNewComponent($comp, $ver);
  my @relevantBinaries = ();
  foreach my $thisRelFile (@{Utils::ReadDir($relDir)}) {
    if ($thisRelFile eq 'binaries.zip') {
      push (@relevantBinaries, "$relDir\\$thisRelFile");
      next;
    }
    if ($thisRelFile =~ /^binaries_(.*)\.zip$/) {
      my $category = $1;
      if ($requiredBinaries) {
	foreach my $requiredBinary (@$requiredBinaries) {
	  if (($category =~ /^$requiredBinary\_/) || ($category eq $requiredBinary)) {
	    push (@relevantBinaries, "$relDir\\$thisRelFile");
	    last;
	  }
	}
      }
      else {
	push (@relevantBinaries, "$relDir\\$thisRelFile");
      }
    }
    elsif ($thisRelFile =~ /^exports[a-z].zip$/i) {
      push (@relevantBinaries, "$relDir\\$thisRelFile");
    }
  }
  return \@relevantBinaries;
}

sub UnpackSource {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $where = shift;
  my $overwrite = shift;
  my $skipinstall = 0;
  unless (defined $overwrite) {
    $overwrite = 0;
  }
  my $showProgress = shift;
  unless (defined $showProgress) {
    $showProgress = 0;
  }
  my $toValidate = shift;
  unless (defined $toValidate) {
    $toValidate = 0;
  }

  my $changeInCat = 0;

  $self->PathData()->CheckReleaseExists($comp, $ver);

  if ($where eq "\\") {
    $where = Utils::SourceRoot();
  }

  # Unpack all categories of source code that are available.
  my $relDir = $self->PathData->LocalArchivePathForExistingOrNewComponent($comp, $ver);

  opendir(RELDIR, $relDir) or die "Error: can't opendir $relDir\n";
  my @srcZipNames = grep {/source[a-z]\.zip/i} map {"$relDir\\$_"} readdir(RELDIR);
  close RELDIR;

  if ($self->{verbose} and scalar(@srcZipNames) == 0) {
    print "No source available for $comp $ver\n";
  }
  else {
    unless ($overwrite) {
      my $checkFailed = 0;
      foreach my $thisSrcZip (@srcZipNames) {
        if (Utils::CheckZipFileContentsNotPresent($thisSrcZip, $where, $self->{iniData})) {
          $checkFailed = 1;
        }
      }
      if ($checkFailed) {
        warn "Warning: Above errors found, skipping the unpacking of $comp zips...\n";
        $skipinstall = 1;
      }
    }

    unless($skipinstall){
      foreach my $thisSrcZip (@srcZipNames) {
        if ($showProgress) {
          my $significantDir = Utils::SignificantZipDir($thisSrcZip);
          my $unzipDir  = Utils::ConcatenateDirNames($where, $significantDir);

          if($self->{iniData}->HasMappings()){
            $unzipDir = $self->{iniData}->PerformMapOnFileName($unzipDir);
          }

          print "\tUnpacking \"$thisSrcZip\" into \"$unzipDir\"...\n";
        }

        $changeInCat = Utils::UnzipSource($thisSrcZip, $where, $self->{verbose}, $overwrite, $self->{iniData}, $toValidate, $comp);
        if($changeInCat==1 && $toValidate ==1) {
          last;
	}
      }
    }
  }

  return $changeInCat; # 1 = change in cat found, 0 = change in cat not found. Return value only used for validation.
}

sub SignatureName {
  my $comp = shift;
  my $ver = shift;
  croak unless defined $ver;
  return Utils::PrependEpocRoot("\\epoc32\\relinfo\\$comp.$ver.sig");
}

sub DecodeSignatureName {
  my $self = shift;
  my $sigName = shift;
  my $comp;
  my $ver;
  my $name = $sigName;
  $name =~ s/.*\\epoc32\\relinfo\\(.*)\.sig/$1/;
  foreach my $thisComp (keys %{$self->{db}}) {
    my $thisVer = $self->{db}->{$thisComp}->{ver};
    if ("$thisComp.$thisVer" eq $name) {
      $comp = $thisComp;
      $ver = $thisVer;
    }
  }

  unless (defined $comp and defined $ver) {
    die "Error: Couldn't decode signature name \"$sigName\"\n";
  }

  return ($comp, $ver);
}

sub ComponentDir {
  require Carp;
  Carp->import;
  confess ("Obsolete method called");
}

sub ReleaseDir {
  require Carp;
  Carp->import;
  confess ("Obsolete method called");
}

sub PathData {
  my $self = shift;
  return $self->{iniData}->PathData();
}

sub CheckForAddedFiles {
  my $self = shift;
  my $reldata = shift;
  my $tempdir = shift;

  # Here we have been asked to search for files that exist in the real source directory,
  # but don't exist in the temporary source directory.

  my $foundextra = 0; # let's hope this stays zero
  foreach my $item (keys %{$reldata->SourceItems}) {
    $item = Utils::PrependSourceRoot($item);
    next unless -d $item; # we're only checking for added files, so we don't care unless this
                          # is a directory in which there ought to be files.

    print "Looking for added files inside \"$item\"\n" if ($self->{verbose});
    # Ah, the lovely Find::File
    find(sub {
      my $tempfile = Utils::ConcatenateDirNames($tempdir, Utils::RemoveSourceRoot($File::Find::name));
      # Be careful with that line - an extra \\ anywhere and it breaks, such is DOS...

      print "Checking existence of \"$tempfile\"\n" if ($self->{verbose}>1);
      unless (-e $tempfile) {
        print "\"$File::Find::name\" only exists in new source code.\n" if ($self->{verbose});
        $foundextra++;
        $File::Find::prune = 1 unless ($self->{verbose}); # skip some of the rest
      }
    }, $item);

    return $foundextra if ($foundextra && !$self->{verbose});
        # don't bother scanning other directories unless it's verbose
  }
    return $foundextra;
}

sub GetReleaseSize {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  $self->{relsize}->{$comp}->{$ver} = $self->AddUpReleaseSize($comp, $ver) unless defined $self->{relsize}->{$comp}->{$ver};
  return $self->{relsize}->{$comp}->{$ver};
}

sub AddUpReleaseSize {
  my $self = shift;
  my $comp = shift;
  my $version = shift;
  my $pathdata = $self->{iniData}->PathData();
  my $path = $pathdata->LocalArchivePathForExistingComponent($comp, $version);
  die "Component $comp $version didn't exist\n" unless $path;
  opendir(DIR, $path) or die "Couldn't open directory \"$path\" because $!";
  my @entries = grep { ! m/^\./ } readdir(DIR);
  closedir DIR;
  my $size = 0;
  print "Adding up size of $comp $version\n" if ($self->{verbose});
  foreach my $file (@entries) {
    my $full = $path . "\\" . $file;
    $size += -s $full;
  }
  return $size;
}

sub GetEnvironmentSize {
  my $self = shift;
  my $comp = shift;
  my $ver = shift;
  my $deltasize = shift;
  $self->{envsize}->{$comp}->{$ver} = $self->AddUpEnvSize($comp, $ver, $deltasize) if (!exists $self->{envsize}->{$comp}->{$ver});
  return $self->{envsize}->{$comp}->{$ver};
}

sub AddUpEnvSize {
  my $self = shift;
  my $maincomp = shift;
  my $mainver = shift;
  my $deltasize = shift;
  my $relData = RelData->Open($self->{iniData}, $maincomp, $mainver, $self->{verbose});
  die "Component $maincomp version $mainver didn't exist\n" unless $relData;
  my $compsToValidate = $relData->Environment();
  my $size = 0;
  while ((my $comp, my $ver) = each %$compsToValidate) {
    # If a delta size is requested and the component version does not
    # match the main component version then don't increment the size
    next if ($deltasize && ($mainver ne $ver));
    
    $size += $self->GetReleaseSize($comp, $ver);
  }
  return $size;
}

1;

__END__

=head1 NAME

EnvDb.pm - A database to keep track of component versions installed on a development drive.

=head1 DESCRIPTION

The database is implemented as a tied hash. It provides a persistent store of component / version pairs. Also provides facilities for checking and validating the contents of an environemnt.

Each component has a status associated with it. The possible values are as follows:

=over 4

=item C<STATUS_CLEAN>: the binaries on disk match those in the release packet

=item C<STATUS_DIRTY>: the binaries on disk don't appear to match those in the release packet

=item C<STATUS_DIRTY_SOURCE>: the binaries match, but the source code doesn't

=item C<STATUS_PENDING_RELEASE>: the component has been set to 'pending release'

=back

=head1 INTERFACE

=head2 Object Management

=head3 Open

Expects to be passed an C<IniData> reference and a verbosity level. Opens the C<EnvDb> on the current drive. If not already present, an empty databse is created. This must be done before any of the following interfaces are used.

=head3 Close

Closes the database file.

=head2 Data Management

=head3 Version

Expects to be passed a component name. Returns the version of the component that is currently installed. Returns undef if there is no version currently installed.

=head3 VersionInfo

Returns a reference to an in memory hash containing component component name / version pairs for every entry in the database.

=head3 SetVersion

Expects to be passed a component name and a optionally a version. If the version is specified, a database entry for the component is created, or, if it is already present, updated. If the version is not specified, and a database entry for the component entry exists, it is deleted.

=head3 InternalVersion

Expects to be passed a component name. Returns the internal version of the component that is currently installed. Returns undef if the component is not currently installed.

=head3 SetInternalVersion

Expects to be passed a component name and an internal version. Dies if an entry for the component is not already present in the database. Store the component's internal version.

=head3 Status

Expects to be passed a component name. Dies if an entry for the component is not already present in the database. Returns the component's last recorded status (which may be C<STATUS_CLEAN>, C<STATUS_DIRTY> or C<STATUS_PENDING_RELEASE>).

=head3 SetStatus

Expects to be passed a component name and a status integer. Dies if an entry for the component is not already present in the database. Updates the component's database entry with the new status.

=head3 MrpName

Expects to be passed a component name. Dies if an entry for the component is not already present in the database. Returns the corresponding F<mrp> name.

=head3 SetMrpName

Expects to be passed a component name and an F<mrp> name. Dies if an entry for the component is not already present in the database. Stores of the F<mrp> name of the component.

=head3 ComponentsPendingRelease

Returns a reference to a hash of hash references. The primary hash key is component name. The secondary hashes each containing details a component that is pending release. The secondary hashes contain the following keys:

 mrpName
 ver
 intVer

=head3 BinaryInfo

Expects to be passed the name of a binary file. Searches for this file name within the component signatures. If it is not found there, then checks for components that are pending release. C<MrpData> objects are then created for each of these to see if the binary file is about to be released. Dies if the file is still not found. Otherwise, returns a two dimentional array containing the component name, verion and current file status.

=head3 ListBins

Expects to be passed a component name. Returns a 2D array containing all the file names owned by component and their current status. These facts will be in the first and second column; subsequent columns may hold further information. The table contains a header row describing what each column is.

=head2 Environment Scans

=head3 CheckEnv

Performs a scan of the F<\epoc32> tree building a hash of all file names. Calls C<CheckComp> for all the components installed on the drive. C<CheckComp> will remove files that pass the check from the F<\epoc32> tree hash. Any file names left in the hash after all components have been checked will be printed to warn the user, since their origin is unknown to the release tools. The F<reltools.ini> keyword C<ignore_binary> my be used to specify (using file names with DOS style wild characters) binary files to be ignored in the checking process. As standard, the following are ignored:

 \epoc32\relinfo\*
 \epoc32\build\*
 \epoc32\wins\c\*
 \epoc32\release\*.ilk
 \epoc32\release\*.bsc
 \epoc32\data\emulator\epoc.sys.ini

Returns the overall status of the environement after the check (which may be of value C<STATUS_CLEAN>, C<STATUS_DIRTY> or C<STATUS_PENDING_RELEASE>), a reference to a list of C<MrpData> objects that are pending release, a reference to a list of component that failed their check, and a reference to a list of unaccounted files.

=head3 CheckComp

Expects to be passed a component name and optionally a scalar flag indicating if the check should continue after the first failure is found (true means continue). Details of any files that fail their check will be printed. Returns the status of the component after the check (which may be of value C<STATUS_CLEAN>, C<STATUS_DIRTY>, C<STATUS_DIRTY_SOURCE> or C<STATUS_PENDING_RELEASE>), and a reference to an C<MrpData> object if the status is C<STATUS_PENDING_RELEASE>.

CheckComp does not check the source code files. In fact, if it determines the binaries match, then it returns either C<STATUS_CLEAN> or C<STATUS_DIRTY_SOURCE> depending on what the environment database says. A component will only ever attain the status of C<STATUS_DIRTY_SOURCE> through the operation of ValidateComp: effectively CheckComp just passes that information through, if the component otherwise appears clean.

=head3 ValidateEnv

Calls C<ValidateComp> for all the components installed on the drive that don't have a status of I<pending release>. Returns a reference to a list of components names that failed. May optionally be passed a component name and version of an external environment against which to validate. This mode may only be used when the current environment database is empty. It causes a complete set of database entries to be written corresponding to the external environment. However, a dummy signature file will be generated for components that fail their validation which contains the names of the binaries released in the external environment, but zero last modified times and sizes. This is to ensure that C<CheckEnv> continues to report these components as C<STATUS_DIRTY>.

=head3 ValidateComp

Expects to be passed a component name, a version and optionally two scalar flags indicating:

=over 4

=item whether validation should continue after the first failure is found (true means continue)

=item whether source code should be validated

=back

Makes use of Manifest.pm and constructs manifest object of the current environment using the mrp file for the components and another manifest object using the manifest file available in the archive location of the previous release for the component. These objects are compared for their similarity and shall return STATUS_CLEAN if everything validates OK and returns STATUS_DIRTY otherwise.

If for some reasons, validation through manifest objects is not possible, then the call is transferred to the old process of validation described herewith as follows:

The process returns the overall status of the release, which is C<STATUS_DIRTY> if there are dirty binaries, C<STATUS_DIRTY_SOURCE> if the binaries are clean but there is dirty source code, or C<CLEAN> if everything validates OK. C<STATUS_DIRTY_SOURCE> will only ever be set if source code validation is turned on; otherwise all components will be set to either C<CLEAN> or C<DIRTY>.

If the validation passes, but there is currently no entry for the release in the database, an entry is created with details corresponding to the version being validated. Whether or not an entry previously existed, if the validation passes, the component's status is set to C<STATUS_CLEAN> and a signature file is generated. If the validation failed and there is already an entry in the database for the component, it's status is set to C<STATUS_DIRTY> or C<STATUS_DIRTY_SOURCE> as appropriate.

If the overall process results in validating the component status as DIRTY, then the manifest information for the current environment will be generated and saved as a manifest file in a temporary location within local file system for use during release processes.

=head2 Environment Management

=head3 InstallComponent

Expects to be passed a component name, and a version. Unpacks the component's binaries, and creates (or updates) a complete database entry from the provided version and information read out of the release's C<RelData> object.

=head3 RemoveComponent

Expects to be passed a component name. Removes all the binary files associated with the installed version of the component, the component's signature file and the component's environment database record.

=head3 DeleteSource

Expects to be passed a component name, a dryrun and a force flag. Removes all the source files associated with the installed version of the component. If dryrun is used the script just reports what it would do. If force is used the script would delete write-protected files.

=head3 UnpackBinaries

Expects to be passed a component name, a version and a directory in which the release should be installed. Unpacks the component's binaries into the specified directory. The environment database is neither consulted, nor modified by this interface. It is intended to allow a set of released binaries to be temporarily unpacked (for example, for validation purposes)

=head3 UnpackSource

Expects to be passed a component name, a version, a directory in which the release should be installed, a flag which represents the verbose level, a flag which represents to overwrite or not, an inidata and a flag which represent whether this process is for validation or not. Unpacks the component's source into the specified directory. The environment database is neither consulted, nor modified by this interface. Returns a change in category flag, when flag is 1 a change in category has been found. Change in category flag is only uses when a validation occurs.

=head3 GetReleaseSize

Takes a component name and a version number. Returns the total size (in bytes) of the zips in the local archive making up a release.

=head3 GetEnvironmentSize

Takes a component name and a version number. Returns the total size (in bytes) of the zips in the local archive making up the environment.

=head2 Notable private methods

=head3 EvalidateDirectories

Expects to be passed two directory names; it will then run C<EValid> over the two. Returns a Boolean (whether the two directories match), and prints the results according to the verbosity level. If the verbosity level is 1 or greater, details of failures are printed. If the verbosity level is greater than 1, all C<EValid> output is printed.

=head3 CheckForAddedFiles

This method checks to see if any files have been added to a component since it was packetised. It's part of source validation. It uses C<Find::File> to list all the files that are in a component's source code directory, then checks each of them are in a temporary directory which has been unzipped from the release packet.

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
