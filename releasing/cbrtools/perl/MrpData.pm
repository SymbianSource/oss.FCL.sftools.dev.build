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


package MrpData;

use strict;
use base qw(Symbian::CBR::MRPInterface);
use File::Find;
use File::Copy;
use File::Basename;
use File::Spec;
use Utils;
use Cwd;
use Symbian::CBR::MRP::Reader;
use IniData;

use Carp;

use constant MAX_PATH_LENGTH => 245; #If a file name has a path > MAX_PATH_LENGTH an error will be produced.



use File::Path;
use XML::Simple;
use POSIX qw(strftime);
use Data::Dumper;


our $cache = {}; # Persistent (private) cache

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{mrpName} = shift;
  $self->{ver} = shift;
  $self->{intVer} = shift;
  $self->{iniData} = shift || IniData->New();
  $self->{verbose} = shift || 0;
  $self->{fixMissingLibs} = shift;
  $self->ExpandMrpName();
  
  # This will be used by the IPR stuff, so that it can popultate the MrpData object without circular stuff
  my $doNotRead = shift;
  
  #remove the / from mrpname
  $self->{mrpName} =~ s/^[\\\/]//;
  
  # Lowercase the MRP name so that the case is consistent when checking the cache
  my $lcMrpName = lc ($self->{mrpName});
  
  if ($cache->{$lcMrpName}) {
    $cache->{$lcMrpName}->{ver} = $self->{ver} if ($self->{ver});
    $cache->{$lcMrpName}->{intVer} = $self->{intVer} if ($self->{intVer});             
    return $cache->{$lcMrpName};
  }

  $cache->{$lcMrpName} = $self;
  
  if (!$doNotRead) {
    $self->ReadMrp();
  }
  
  return $self;
}

sub Populated {
  my $self = shift;
  
  return $self->{populated};
}


sub ExpandMrpName {
  my $self = shift;

  unless ($self->{mrpName} =~ /.mrp$/i) {
    $self->{mrpName} .= '.mrp';
  }
}

sub Component {
  my $self = shift;
  unless (exists $self->{comp}) {
    die "Error: Component name not found in mrp\n";
  }
  return $self->{comp};
}

sub MrpName {
  my $self = shift;
  return $self->{mrpName};
}

sub ExternalVersion {
  my $self = shift;
  return $self->{ver};
}

sub InternalVersion {
  my $self = shift;
  return $self->{intVer};
}

sub NotesSource {
  my $self = shift;
  unless (exists $self->{notes_src}) {
    die "Error: Notes source not found in mrp for $self->{comp}\n";
  }
  return $self->{notes_src};
}

sub ClassifySource {
  my $self = shift;
  return if defined $self->{src};

  foreach my $item (keys %{$self->{srcitems}}) {
    if (-d Utils::PrependSourceRoot($item)) {
      $self->HandleSourceDir($item);
    }
    elsif (-f Utils::PrependSourceRoot($item)) {
      $self->HandleSourceFile($item);
    }
    else {
      die "Error: \"$item\" is not a file or directory in $self->{mrpName}\n";
    }
  }
}

sub SourceCategories {
  my $self = shift;
  $self->ClassifySource();
  if (defined $self->{src}) {
    my @categories = keys %{$self->{src}};
    return \@categories;
  }
  return [];
}

sub Source {
  my $self = shift;
  my $category = uc(shift);
  $self->ClassifySource();
  unless (defined $category) {
    $category = 'unfiltered';
  }
  if (defined $self->{src}->{$category}) {
    return $self->{src}->{$category};
  }
  return [];
}

sub SourceFilterErrors {
  my $self = shift;
  $self->ClassifySource();
  if (defined $self->{sourceFilterErrors}) {
    return $self->{sourceFilterErrors};
  }
  return [];
}

sub BinaryCategories {
  my $self = shift;

  $self->ProcessBinaries();

  if ($self->{bins}) {
    my @categories = sort keys %{$self->{bins}};
    return \@categories;
  }
  return [];
}

sub Binaries {
  my $self = shift;
  my $category = shift;

  $self->ProcessBinaries();

  my @binList = ();
  if ($category) {
    die unless (exists $self->{bins}->{$category});
    foreach my $thisBin (sort keys %{$self->{bins}->{$category}}) {
      push (@binList, $self->{bins}->{$category}->{$thisBin});
    }
  }
  else {
    foreach my $thisCategory (@{$self->BinaryCategories()}) {
      push (@binList, @{$self->Binaries($thisCategory)});
    }
  }
  return \@binList;
}

sub ExportCategories {
  my $self = shift;
  if ($self->{iniData}->CategoriseExports()) {
    $self->ProcessExports();
    if ($self->{exports}) {
      my @categories = sort keys %{$self->{exports}};
      return \@categories;
    }
  }
  return [];
}

sub Exports {
  my $self = shift;
  my $category = uc(shift);

  $self->ProcessExports();

  my @exportList = ();
  if ($self->{iniData}->CategoriseExports()) {
    if ($category) {
      die unless (exists $self->{exports}->{$category});
      push (@exportList, @{$self->{exports}->{$category}});
    }
    else {
        foreach my $thisCategory (@{$self->ExportCategories()}) {
          push (@exportList, @{$self->Exports($thisCategory)});
        }
    }
  }
  elsif ($category) {
    die; # There are never any export categories if export categorisation is not enabled. Caller didn't call ExportCategories prior to this.
  }
  return \@exportList;
}


sub ClassifyAutomaticExports {
  # Classify exports that were specified using the 'exports' keyword.
  #
  # This is a bit ugly. The problem's root is that it's not possible to ask the build tools where exports originated
  # from. This information is needed to be able to categorise exports. To get it, the release tools therefore have
  # to go 'under the hood' of the build tools. Yuk!
  #
  # Implementation choices were a) Parse bld.inf files, and b) Parse the generated export makefiles. Option (b) was
  # chosen because bld.infs are notoriously difficult to robustly parse.

  my $self = shift;
  if (exists $self->{exports}->{automatic}) { # Only perform the classification if we haven't already done it.
    foreach my $thisAbldPath (@{$self->{exports}->{abldPaths}}) {
      $thisAbldPath = Utils::PrependSourceRoot($thisAbldPath);
      # Scan the makefile looking for the exports we're expecting (from invoking 'abld -w exports' in HandleExports).

      my $exportMakeFile;
      my $testExportMakeFile;
      $self->ExportMakeFile($thisAbldPath, \$exportMakeFile, \$testExportMakeFile);

      if ($exportMakeFile){
        $self->ProcessExportMakeFile($exportMakeFile, $thisAbldPath);

      }
      if ($testExportMakeFile){
        $self->ProcessExportMakeFile($testExportMakeFile, $thisAbldPath);
      }
    }

  }

  if (scalar(keys %{$self->{exports}->{automatic}}) > 0) {
    foreach my $unprocessed_export (keys %{$self->{exports}->{automatic}})
	{
		print "UNPROCESSED EXPORT: $unprocessed_export\n";
	}

    die "Error: Problem extracting export IPR categories for \"$self->{mrpName}\"\n";
  }

  delete $self->{exports}->{automatic};
  delete $self->{exports}->{abldPaths};
}

sub ProcessExportMakeFile {
	my $self = shift;
	my $exportMakeFile = shift;
        my $abldPath = shift;
        my $errors = 0;
        open (MAKEFILE, $exportMakeFile) or die "Error: Couldn't open \"$exportMakeFile\": $!\n";
        while (my $line = <MAKEFILE>) {
          $line =~ s/\\ / /g; # Get rid of escaped spaces.
          if ($line =~ /^(.*)\s+:\s+(.*)/) {
            # Found a possibility - need to see if it's one of the exports we're looking for.
            my $destination = $1;
            my $source = $2;
            if (Utils::WithinEpocRoot($destination)) {
              $destination = Utils::RemoveEpocRoot($destination);
            }
            if (exists $self->{exports}->{automatic}->{lc($destination)}) {
              $source = Utils::RemoveSourceRoot($source);
              # Add to exports to be processed - source and destination
              push @{$self->{exportsToBeProcessed}}, {source => $source,
                                                      destination => $destination,
                                                      abldPath => $abldPath};
              
              delete $self->{exports}->{automatic}->{lc($destination)};
            }
          }
          elsif ($line =~ /unzip\s+-u\s+-o\s+(.*)\s+-d\s+\"(.*)\"/) {
            # Looks like a zip file being exported - check contents.
            my $zipFileName = $1;
            my $destinationDir = $2;
            my $zipContents = Utils::ListZip($zipFileName);
            $zipFileName = Utils::RemoveSourceRoot($zipFileName);
            foreach my $thisExport (@$zipContents) {
              $thisExport = Utils::ConcatenateDirNames($destinationDir, $thisExport);
              if (Utils::WithinEpocRoot($thisExport)) {
                $thisExport = Utils::RemoveEpocRoot($thisExport);
              }
              if (exists $self->{exports}->{automatic}->{lc($thisExport)}) {
                # Add to exports to be processed - source and destination
                push @{$self->{exportsToBeProcessed}}, {source => $zipFileName,
                                                        destination => $thisExport,
                                                        abldPath => $abldPath};
                
                delete $self->{exports}->{automatic}->{lc($thisExport)};
              }
            }
          }
        }
        close (MAKEFILE);
}

sub ExportMakeFile {
  # Invoke 'bldmake bldfiles -v' to find the full path to the EXPORT.MAKE file.
  my $self = shift;
  my $abldPath = shift;
  my $exportMakeFileRef = shift;
  my $testExportMakeFileRef = shift;
  my $cwd = cwd();
  my $last = 0;
  chdir $abldPath or die "Error: Couldn't change working directory to \"$abldPath\": $!\n";
  open (BLDMAKE, 'bldmake bldfiles -v |') or die "Error: Couldn't run \"bldmake bldfiles -v |\" in \"abldPath\": $!\n";
  my $exportMakeFile;
  my $testExportMakeFile;
  while (my $line = <BLDMAKE>) {
    if ($line =~ /Creating \"(.*EXPORT.MAKE)\"/) {
      $exportMakeFile = $1;
      if ($last == 1){ # found both EXPORT.MAKE and EXPORTTEST.MAKE
        last;
      }
      $last = 1;
    }
    elsif ($line =~ /Creating \"(.*EXPORTTEST.MAKE)\"/) {
      $testExportMakeFile = $1;
      if ($last == 1){ # found both EXPORT.MAKE and EXPORTTEST.MAKE
        last;
      }
      $last = 1;
    }
  }
  close (BLDMAKE);
  chdir $cwd or die "Error: Couldn't change working directory to \"$cwd\": $!\n";
  unless ($exportMakeFile || $testExportMakeFile) {
    die "Error: Unable to find \"EXPORT.MAKE\" or \"EXPORTTEST.MAKE\" for \"$abldPath\"\n";
  }
  $$exportMakeFileRef = $exportMakeFile;
  $$testExportMakeFileRef = $testExportMakeFile;
}

sub ClassifyManualExports {
  my $self = shift;
  if (exists $self->{exports}->{manual}) { # Only perform the classification if we haven't already done it.
    foreach my $thisSource (keys %{$self->{exports}->{manual}}) {
      push @{$self->{exportsToBeProcessed}}, {source => $thisSource,
                                              destination => $self->{exports}->{manual}->{$thisSource}};
    }
    delete $self->{exports}->{manual};
  }
}

sub ExportInfoForCat {
  my $self = shift;
  my $category = uc(shift);

  $self->ProcessExports();

  return $self->{exportinfo}->{$category};
}

sub ExportSourceFileInfoForCat {
  my $self = shift;
  my $category = uc(shift);
  my $exportfile = shift;

  # In AddExport $category is called $class and $exportfile is $destination
  return $self->{exportinfo}->{$category}->{$exportfile};
}

sub AddExport {
  my $self = shift;
  my $source = shift;
  my $destination = shift;
  my $successfullyAdded = 0;

  my ($class) = Utils::ClassifyPath($self->{iniData}, $source, $self->{verbose}, 0, $self->Component());
  $class = uc($class);

  if ($class) {
    $successfullyAdded = 1;
    push (@{$self->{exports}->{$class}}, $destination);
  }
  else {
    print "Error: Can't find IPR category for export \"$destination\" in \"$self->{mrpName}\"
       It should correspond to source file \"$source\"\n";
  }

  # Need to record the src paths.
  $self->{exportinfo}->{$class}->{$destination} = $source;

  return $successfullyAdded;
}

sub BinariesAndExports {
  my $self = shift;
  # Exports need to be processed first.  If exports are not to be categorised then
  # they are treated as binary files.
  my $list = $self->Exports();
  push (@$list, @{$self->Binaries()});
  return $list;
}

sub SourceItems {
  my $self = shift;
  return $self->{srcitems};
}

sub ReadMrp {
  my $self = shift;
  my $mrpName = $self->{mrpName};
  my $cwd = cwd();
  # If there are mappings and the source root is \\, perform mappings on filename. Otherwise prepend source root.
  if($self->{iniData}->HasMappings() && Utils::SourceRoot() eq "\\") {
    $mrpName = $self->{iniData}->PerformMapOnFileName($mrpName);
  }
  else{
    $mrpName = Utils::PrependSourceRoot($mrpName);
  }
  
  my $mrpDir = dirname($mrpName);
  
  chdir($mrpDir) or die "Error: Couldn't change working directory to \"$mrpDir\": $!\n";
 
  my $reader = Symbian::CBR::MRP::Reader->instance();
  $reader->SetVerbose() if ($self->{verbose});

  $reader->ReadFile($mrpName, 'MRPDATA');
  
  chdir($cwd) or die "Error: Couldn't change working directory back to \"$cwd\": $!\n";
  if ($@) {
    die $@;
  }
}


sub HandleSourceFile {
  my $self = shift;
  my $srcFile = shift;

  my $logErrors = !$self->{iniData}->IgnoreSourceFilterErrors();
  my ($cat, $errors) = Utils::ClassifyPath($self->{iniData}, $srcFile, $self->{verbose}, $logErrors, $self->Component());

  if ($self->{verbose}) {
    print "Handling source file $srcFile...\n";
  }
  
  push @{$self->{sourceFilterErrors}}, @$errors if @$errors;
  push @{$self->{src}->{uc($cat)}}, $srcFile;
}

sub HandleSourceDir {
  my $self = shift;
  my $srcDir = Utils::PrependSourceRoot(shift);

  if ($self->{verbose}) {
    print "Filtering source directory $srcDir into categories...\n";
  }
 
  # Create function to handle files in a directory ($File::Find::dir)
  # Takes: List of items (files and dirs) in the directory 
  my $dirhandler = sub {
    my @entries = @_;
    my $hasdistpol = scalar(grep(lc($_) eq "distribution.policy", @entries));
    
    @entries = grep(lc($_) ne "distribution.policy", @entries); # remove distribution.policy entries
    
    foreach my $entry (@entries) {
      if (Utils::CheckForUnicodeCharacters($entry)) {
          die "Error: \"$File::Find::dir\\$entry\" contains unicode characters, which are incompatible with the CBR Tools. This file can not be included in this release.\n"; 
      }    
    }
    
    my @files = grep(-f File::Spec->catfile($File::Find::dir,$_), @entries);
    
    # Remove the abld entries from the source
    $self->RemoveAbldFromSource($File::Find::dir, \@files);
    
    if (scalar(@files) > 0) {    
      
      # Tag all the entries in this directory with that category
      foreach my $entry (@files) {
        next if $entry =~ /^\.\.?$/; # Skip . and ..
        my $entry = File::Spec->catfile($File::Find::dir, $entry);
        Utils::TidyFileName(\$entry);
        
        $entry = Utils::RemoveSourceRoot($entry); # remove source root path or it will be added twice!
        my ($category, $errors) = Utils::ClassifyPath($self->{iniData}, $entry, $self->{verbose}, $self->{iniData}->IgnoreSourceFilterErrors(), $self->Component());
        push @{$self->{sourceFilterErrors}}, @$errors; # There will be no errors in @$errors if IgnoreSourceFilterErrors was set
        
        # (Optionally) guard against unclassified source
        if (lc($category) eq "x" and $self->{iniData}->DisallowUnclassifiedSource()) {
          die "Error: \"$File::Find::dir\" contains unclassified source code\n";
        }
        
        push @{$self->{src}->{uc($category)}}, $entry;
      } 
    } else {
      # There are no files to categorise here
      if (($hasdistpol) and (!($self->{iniData}->IgnoreSourceFilterErrors()))) {
        push @{$self->{sourceFilterErrors}}, "Note: unnecessary policy file in $File::Find::dir\n";
      }
    }
    
    # Return full list of entries to continue scan
    return @entries;
  };

  # Traverse the directory tree in $srcDir calling &$dirhandler on all directories
  find({"wanted"=>sub{}, "preprocess"=>$dirhandler, "no_chdir" => 1}, $srcDir);
}

sub RemoveAbldFromSource {
  my $self = shift;
  my $dir = shift;
  my $files = shift;
  
  $dir = File::Spec->canonpath($dir);

  foreach my $entry (@{$self->{binaryStatements}}, @{$self->{exportsStatements}}) {
    if ($entry->{abldPath} eq $dir) {
      @$files = grep $_ !~ /abld.bat/i, @$files;
      return;
    }
  }  
}

sub HandleBinDirOrFile {
  my $self = shift;
  my $remove = shift;
  my $category = shift;
  my $file = shift;
  my $successRef = shift;

  if (-d $file) {
    $self->HandleBinDir($remove, $category, $file, $successRef);
  }
  elsif ($file) {
    $self->HandleBinFile($remove, $category, $file, $successRef);
  }
}

sub HandleBinFile {
  my $self = shift;
  my $remove = shift;
  my $category = shift;
  my $file = Utils::RemoveEpocRoot(shift);
  my $successRef = shift;

  my $lcFile = lc($file); # Note, duplicate check is performed on lower case file name. Original case is preserved within the hash.
  Utils::TidyFileName(\$file);

  die "No category was provided" unless $category;

  if ($remove) {
    foreach my $thisClassification (keys %{$self->{bins}}) {
      if (exists $self->{bins}->{$thisClassification}->{$lcFile}) {
        if ($self->{verbose} > 1) { print "Excluding binary file \"$file\" from $thisClassification...\n"; }
        delete $self->{bins}->{$thisClassification}->{$lcFile};
        $$successRef = 1;
      }
    }
  }
  else {
    unless ($self->IsDuplicateBin($file)) {
      if ($self->{verbose} > 1) { print "Adding binary file \"$file\" to category $category...\n"; }
      $self->{bins}->{$category}->{$lcFile} = $file;
      $$successRef = 1;
    }
  }

  }


sub HandleBinDir {
  my $self = shift;
  my $remove = shift;
  my $category = shift;
  my $binDir = shift;
  my $successRef = shift;

  find($self->ProcessBinFile($remove, $category, $successRef), $binDir);
}

sub ProcessBinFile {
  my $self = shift;
  my $remove = shift;
  my $category = shift;
  my $successRef = shift;
  return sub {
    my $file = $File::Find::name;
    
    if (Utils::CheckForUnicodeCharacters($file)) {
      die "Error: \"$file\" contains unicode characters, which are incompatible with the CBR Tools. This file can not be included in this release.\n"; 
    }    
    
    if (-f $file) {
      Utils::TidyFileName(\$file);
      $self->HandleBinFile($remove, $category, $file, $successRef);
    }
  }
}

sub IsDuplicateBin {
  my $self = shift;
  my $fileName = shift;
  my $fileNameLc = lc ($fileName);

  my $duplicate = 0;
  foreach my $thisCategory (keys %{$self->{bins}}) {
    if (exists $self->{bins}->{$thisCategory}->{$fileNameLc}) {
      # This file has already been handled once, so it must be a duplicate.
      # Therefore move it to the 'unclassified' category to ensure it doesn't get released twice.
      if ($thisCategory ne 'unclassified') {
	if ($self->{verbose} > 1) {
	  print "Moving binary file \"$fileName\" to from category $thisCategory to 'unclassified'...\n";
	}
	$self->{bins}->{unclassified}->{$fileNameLc} = $fileName;
	delete $self->{bins}->{$thisCategory}->{$fileNameLc};
      }
      $duplicate = 1;
      last;
    }
  }

  return $duplicate;
}

sub HandleBinSet {
  my $self = shift;
  my $remove = shift;
  my $test = shift;
  if ($test) {
    $test = 'test';
  }
  else {
    $test = '';
  }
  my $successRef = shift;
  my $abldPath = shift;
  $abldPath = SourceRootPath($abldPath);
  my $plat = shift;
  my $var = '';
  if ($_[0] and $_[0] =~ /(u?(?:deb|rel))/i) {
    $var = shift;
  }
  my $mmp = shift;
  unless ($mmp) {
    $mmp = '';
  }
  
  $self->ProcessCache($abldPath, $test) if (!exists($self->{abldcache}->{loaded}->{$abldPath}));

  my $plats = $self->ResolveAlias($abldPath, $plat);
  my $vars;
  foreach $plat (@$plats) {
    if ($var) {
      $vars = [$var];
    } elsif ($plat =~ /^tools2?$/i) {
      # Hard-coded and nasty
      $vars = [ 'deb', 'rel' ];
    } else {
      $vars = [ 'udeb', 'urel' ];
    }
    foreach $var (@$vars) {
      push @{$self->{binsets}}, {
        path => Utils::RemoveSourceRoot($abldPath),
        plat => $plat,
        var => $var,
        mmp => $mmp,
        test => $test
      } unless ($remove);

      $self->ReadBinaries($abldPath, $test, $plat, $var, $mmp, $remove, $successRef);
    }
  }
}


sub ProcessCache {
  my $self = shift;
  my $abldPath = shift;
  my $test = shift;
  
  $self->CheckBuildSystem($abldPath) if(!$self->{buildSystem});

  if($self->{buildSystem} == 2){
    print "current build system is Raptor...\n" if ($self->{verbose});
    $self->ProcessRaptorCache($abldPath, $test);
  }
  else{
    print "current build system is Abld...\n" if ($self->{verbose});
    $self->ProcessAbldCache($abldPath);
  }
}

#check which build system would be using
sub CheckBuildSystem {
  my $self = shift;
  my $abldPath = shift;
  my $buildSystem = $self->{iniData}->BuildSystemVersion($self->{verbose});

  if($buildSystem eq "1") {
    if ($self->AbldAvailable($abldPath)){
      $self->{buildSystem} = 1;
    }
    else{
      die "Abld build system isn't available.\n";
    }
  }
  else{
    if($buildSystem ne "2") {
	    print "Warning: the value of build system is neither 1 nor 2 so we try to use Raptor.\n" if ($self->{verbose});
    }
    
    if ($self->RaptorAvailable()){
      $self->{buildSystem} = 2;
    }
    elsif($buildSystem ne "2") {
      print "Warning: Raptor is not available and we try to use Abld.\n" if ($self->{verbose});
	  	
      if ($self->AbldAvailable($abldPath)){
        $self->{buildSystem} = 1;
      }
      else{
        die "Neither Abld nor Raptor is available.\n";
      }
    }
    else{
      die "Raptor build system is not available.\n";
    }
  }
}

sub ProcessAbldCache {
  my $self = shift;
  my $abldPath = shift;
  if (exists $ENV{ABLDCACHE}) {
    $self->{abldcache}->{loaded}->{$abldPath}= 1;
    my $cachefile=File::Spec->catdir($ENV{ABLDCACHE},$abldPath,"cache");
    if (-f $cachefile) {
      print "Reading ABLD Cache from $cachefile\n" if ($self->{verbose});
	
      open(CACHE, $cachefile) or die "Couldn't open abld cache data file '$cachefile'\n";
      my @cache = <CACHE>;
      close(CACHE);
      eval (join("",@cache)) or die "Error: Couldn't parse abld cache data in '$cachefile': $@\n";
    }
  }
}

sub ProcessRaptorCache {
  my $self = shift;
  my $abldPath = shift;
  my $test = shift;

  my $cwd = cwd();
  my $driver = $cwd;
  $driver =~ /^(.:)(.*)/;
  $driver = $1."\\raptorcache";
  my $logfile = File::Spec->catdir($driver.$abldPath,"info.xml");
  if(! -f $logfile){
    my $makefile = File::Spec->catdir($driver.$abldPath,"Makefile");
    print "execute SBS to create Raptor XML log file: $logfile\n" if($self->{verbose});
    chdir $abldPath or die "Error: Couldn't change working directory to \"$abldPath\": $!\n";
    my $cmd = $self->RaptorLogCmd($abldPath, $logfile, $makefile, $test);
    open (SBS, $cmd) or die "Error: Couldn't run \"$cmd\" in \"$abldPath\": $!\n";
    my $foundLog;
    my $errmsg;
    while (my $line = <SBS>) {
      $errmsg = $1 if ($line =~ /sbs : errors: (\d+)/ and $1 > 0);
      $foundLog = 1 if ($line =~ /sbs: build log in (\w+)/);
    }
    close (SBS);
			  
    if($errmsg){
      my $trycount = 50;
      my $errtag = 0;
      while($trycount > 0){
        print "try to run sbs again: $trycount\n";
        open (SBS, $cmd) or die "Error: Couldn't run \"$cmd\" in \"$abldPath\": $!\n";
        $errtag = 0;
        while (my $line = <SBS>) {
          if ($line =~ /sbs : errors: (\d+)/ and $1 > 0){
            $errtag = 1;
            $trycount = $trycount - 1;
          }
          $foundLog = 1 if ($line =~ /sbs: build log in (\w+)/);
        }
        $trycount =0 if($errtag < 1);
        close (SBS);
      }
      if($errtag == 1 and $trycount == 0) {
      	die "SBS Error: Couldn't run \"$cmd\" in \"$abldPath\"\n";
      }
    }
    chdir $cwd or die "Error: Couldn't change working directory to \"$cwd\": $!\n";
    unless ($foundLog) {
      die "Error: Unable to execute \"SBS\" in \"$abldPath\"\n";
    }
  }

  $self->ParseRaptorXmlLog($logfile);
  $self->PrintCache() if($self->{verbose});
  $self->{abldcache}->{loaded}->{$abldPath}= 1;
  print "cache is generated successfully\n" if($self->{verbose});
}

sub RaptorLogCmd {
  my $self = shift;
  my $abldPath = shift;
  my $logfile = shift;
  my $makefile = shift;
  my $test = shift;
  if ($test) {
    $test = 'test';
  }
  else {
    $test = '';
  }

  my $plat = "all";
  my $iniAll = $self->{iniData}->TargetPlatforms($plat);
  my $cmd = "SBS -b bld.inf -m $makefile -f $logfile -c default";
  $cmd = $cmd." -c default.test" if ($test ne '');
  foreach my $e (@$iniAll) {
    $cmd = $cmd." -c tools_rel -c tools_deb" if ($e eq "TOOLS");
    $cmd = $cmd." -c tools2_rel -c tools2_deb" if ($e eq "TOOLS2");
    $cmd = $cmd." -c armv5.smp" if ($e eq "ARMV5SMP");
  }
  $cmd = $cmd." WHAT |";
  print "Raptor command: $cmd\n";
  return $cmd;
}

#check whether Abld build system is available
sub AbldAvailable {
  my $self = shift;
  my $abldPath = shift;
  my $path = File::Spec->catdir($abldPath,"");
  my $foundPlats = 0;

  my $cwd = cwd();
  chdir $abldPath or die "Error: Couldn't change working directory to \"$abldPath\": $!\n";
  open (BLDMAKE, "bldmake bldfiles |") or die "Error: Couldn't run \"bldmake bldfiles\" in \"$abldPath\": $!\n";
  while (my $line = <BLDMAKE>) {
    chomp $line;
  }
  close(BLDMAKE);
	
  open (ABLD, "abld help |") or die "Error: Couldn't run \"abld help\" in \"$abldPath\": $!\n";
  while (my $line = <ABLD>) {
    chomp $line;
    $foundPlats = 1 if ($line =~ /project platforms:/);
  }
  close (ABLD);
  chdir $cwd or die "Error: Couldn't change working directory to \"$cwd\": $!\n";
  
  return $foundPlats;
}

#check whether Raptor build system is available
sub RaptorAvailable {
  my $self = shift;
  my $maxver = 0;
  my $midver = 0;
  my $minver = 0;
  
  return 0 if(!-f "\\epoc32\\data\\buildinfo.txt" and !-f "\\epoc32\\data\\kif.xml");

  open (SBS, "sbs -version |") or die "Error: Couldn't run \"sbs -version\": $!\n";
  while (my $line = <SBS>) {
    chomp $line;
    if ($line =~ /^sbs version (\d+)\.(\d+)\.(\d+)/){
      $maxver = $1;
      $midver = $2;
      $minver = $3;
    }
  }
  close (SBS);
  if ($maxver == 0 and $midver == 0 and $minver == 0) {
    return 0;
  }
  elsif ($maxver < 2 or ($maxver == 2 and $midver < 7)) {
    die "Error: Raptor build system version must be 2.7.0 or higher.\n";
  }
  return 1;
}

sub ParseRaptorXmlLog {
  my $self = shift;
  my $xmlfile = shift;

  my $xmldata;
  my $trycount = 20;

  while ($trycount > 0) {
    eval {
      $xmldata = XMLin($xmlfile);
    };
    if ($@) {
      $trycount = $trycount - 1;
      print "Try to open raptor log file [$trycount]: $xmlfile\n";
    }
    else{
      $trycount = 0;
    }
  }

  my $whatLogElements = $self->WrapVarToArray($xmldata->{whatlog});
  foreach  my $whatLogElement (@$whatLogElements) {
    $self->ProcessWhatLogElement($whatLogElement);
  }
  
  foreach my $param (keys %{$self->{abldcache}->{exports}}) {
    foreach my $destination (keys %{$self->{abldcache}->{exports}->{$param}}) {
      push @{$self->{abldcache}->{$param}}, [$destination, $self->{abldcache}->{exports}->{$param}->{$destination}];
    }
  }
  delete $self->{abldcache}->{exports};
  
  foreach my $param (keys %{$self->{abldcache}->{builds}}) {
    foreach my $buildItem (keys %{$self->{abldcache}->{builds}->{$param}}) {
      push @{$self->{abldcache}->{$param}}, $buildItem;
    }
  }
  delete $self->{abldcache}->{builds};
  
  foreach my $platform (keys %{$self->{abldcache}->{platforms}}) {
    push @{$self->{abldcache}->{plats}}, uc($platform);
  }
  delete $self->{abldcache}->{platforms};
}

sub ProcessWhatLogElement {
  my $self = shift;
  my $aWhatLogElement = shift;
  
  my $bldinf = $aWhatLogElement->{bldinf};
  my $bldinfDir = $bldinf;
  $bldinfDir =~ s/\//\\/g;
  $bldinfDir =~ /^.:(.+)\\(.*)/;
  $bldinfDir = $1;
  
  my $mmp = $aWhatLogElement->{mmp};
  my $config = $aWhatLogElement->{config};
  
  my $platform = "";
  my $variant = "";
  my $test;
  
  if ($config =~ /^(\w+)_(\w+)\.test/){
    $platform = $1;
    $variant = $2;
    $test = "test";
  }
  elsif ($config =~ /^(\w+)_(\w+)*/){
    $platform = $1;
    $variant = $2;
  }

  if($aWhatLogElement->{export}){
    my $exports = $self->WrapVarToArray($aWhatLogElement->{export});
    foreach  my $export (@$exports) {
      $self->StoreExportItem ($bldinfDir, $export->{source}, $export->{destination}, $test);
    }
  }
  if($aWhatLogElement->{archive}){
    my $archives = $self->WrapVarToArray($aWhatLogElement->{archive});
    foreach my $archive (@$archives){
      foreach  my $member (@{$archive->{member}}) {
        $self->StoreExportItem ($bldinfDir, $archive->{zipfile}, $member, $test);
      }
    }
  }
  if($aWhatLogElement->{build}){
    my $buildItems = $self->WrapVarToArray($aWhatLogElement->{build});
    foreach  my $buildItem (@$buildItems) {
      $self->StoreBuildItem ($bldinfDir, $buildItem, $platform, $variant, $test);
    }
  }
  if($aWhatLogElement->{resource}){
    my $resources = $self->WrapVarToArray($aWhatLogElement->{resource});
    foreach  my $buildItem (@$resources) {
      if($buildItem =~ /[\\|\/]epoc32[\\|\/]release[\\|\/]winscw[\\|\/](urel|udeb)[\\|\/]/g){
        $variant = $1;
      }
      else{
        $variant = "ALL"; 
      }
      $self->StoreBuildItem ($bldinfDir, $buildItem, $platform, $variant, $test);
    }
  }
  if($aWhatLogElement->{bitmap}){
    my $bitmaps = $self->WrapVarToArray($aWhatLogElement->{bitmap});
    foreach  my $buildItem (@$bitmaps) {
      $self->StoreBuildItem ($bldinfDir, $buildItem, $platform, "ALL", $test);
    }
  }
  if($aWhatLogElement->{stringtable}){
    my $stringTables = $self->WrapVarToArray($aWhatLogElement->{stringtable});
    foreach  my $buildItem (@$stringTables) {
      $self->StoreBuildItem ($bldinfDir, $buildItem, $platform, $variant, $test);
    }
  }
  
  $self->{abldcache}->{platforms}->{$platform} = 1 if($platform ne "ALL");

  my $param = "$bldinfDir ";
  $param = $param."test " if ($test);
  $param = $param."export -what";
  if(!$self->{abldcache}->{$param}){
    pop @{$self->{abldcache}->{$param}};
  }
}

sub StoreExportItem {
  my $self = shift;
  my $bldinfDir = shift;
  my $aSource = shift;
  my $aDestination =shift;
  my $test = shift;
  $aSource = $self->ReleasableItem($aSource);
  $aDestination = $self->ReleasableItem($aDestination);
  my $param = "$bldinfDir ";
  $param = $param."test " if ($test);
  $param = $param."export -what";
  $self->{abldcache}->{exports}->{$param}->{$aDestination} = $aSource;
}

sub StoreBuildItem {
  my $self = shift;
  my $bldinfDir = shift;
  my $aBuildItem = shift;
  my $aPlatform = shift;
  my $aVariant = shift;
  my $test = shift;
	
  if($aPlatform ne "ALL" and $aVariant eq "ALL"){
    $self->StoreBuildItem($bldinfDir, $aBuildItem, $aPlatform, "urel", $test);
    $self->StoreBuildItem($bldinfDir, $aBuildItem, $aPlatform, "udeb", $test);
  }
  else{
    $aBuildItem = $self->ReleasableItem($aBuildItem);
    my $param = "$bldinfDir ";
    $param = $param."test " if ($test);
    $param = $param."target $aPlatform $aVariant -what";
    $self->{abldcache}->{builds}->{$param}->{$aBuildItem} = 1;
    $self->{abldcache}->{platforms}->{$aPlatform} = 1 if($aPlatform ne "ALL");
  }
}

sub ReleasableItem {
  my $self = shift;
  my $aBuildItem = shift;
  $aBuildItem =~ s/\/\//\\/g;
  $aBuildItem =~ s/\//\\/g;
  $aBuildItem =~ s/\"//g;
  $aBuildItem =~ /^.:(.+)/;
  return $1;
}


sub WrapVarToArray {
  my $self = shift;
  my $var = shift;
  my @result;
  
  if($var){
    if($var =~/^ARRAY*/){
      return $var;	
    }
    else{
      push (@result, $var);
    }
  }
  return \@result;
}

sub PrintCache {
  my $self = shift;
  print "print cache content\n" if($self->{verbose});
  foreach my $item (keys %{$self->{abldcache}}) {
    if($item ne "loaded"){
      print "\$self->{abldcache}->{\'$item\'} =\n";
      print " [\n";
      my $first = 1;
      
      foreach my $cachedata (@{$self->{abldcache}->{$item}}) {
      	print ",\n" if($first > 1);
      	$first = $first+1;
        if($cachedata=~/^ARRAY*/){
    	    print " [\'@$cachedata[0]\', \'@$cachedata[1]\']";
        }
        else{
    	    print " \'$cachedata\'";
        } 
      }
      print "\n ];\n\n";
    }
  }
}

# Support for target alias file
# If the MRP specifies 'ALL' then the intersection of the
# definition of 'ALL' and the output of abld help is used
# as the platform list
sub ResolveAlias {
  my $self = shift;
  my $abldPath = shift;
  my $plat = shift;
  my @plats = ();

  if (lc $plat eq 'all' || $self->{iniData}->HasTargetPlatforms($plat)) {
    if ($self->{iniData}->HasTargetPlatforms($plat)) {
      if (lc $plat eq 'all') {
        # ALL and HasTargetPlatforms()
        # Do the set intersection with the output of abld help
        my $iniAll = $self->{iniData}->TargetPlatforms($plat);
        my $abldHelp = $self->GetPlatforms($abldPath);
        my %count;
        foreach my $e (@$iniAll) {
          $count{$e} = 1;
        }
        foreach my $e (@$abldHelp) {
          if (exists $count{$e} and $count{$e} == 1) {
            push @plats, $e;
          }
        }
        $self->RemoveIDEPlatforms(\@plats);
        if ($self->{verbose} > 1) {
          print "Intersection of \"ALL\" alias and abld help is \"@plats\"\n";
        }
      } else {
        # NOT ALL and HasTargetPlatforms()
        # Use the list of platforms from the iniData and this alias
        @plats = @{$self->{iniData}->TargetPlatforms($plat)};
        if ($self->{verbose} > 1) {
          print "Resolution of \"$plat\" alias is \"@plats\"\n";
        }
      }
    } else {
      # ALL and NOT HasTargetPlatforms() so just use
      # the results of abld help
      @plats = @{$self->GetPlatforms($abldPath)};
      $self->RemoveIDEPlatforms(\@plats);
      if ($self->{verbose} > 1) {
        print "Resolution of \"ALL\" alias from abld help is \"@plats\"\n";
      }
    }
  } else {
    # NOT ALL and NOT HasTargetPlatforms() so use this as the platform
    @plats = $plat;
    if ($self->{verbose} > 1) {
      print "Platform specified is \"@plats\"\n";
    }
  }
  return \@plats;
}

sub RemoveIDEPlatforms {
  my $self = shift;
  my $plats = shift;

  # Ugly hard-coded yukkiness
  @$plats = grep { !m/^cw_ide$/i && !m/^vc\d/i } @$plats;
}

sub GetPlatforms {
  my $self = shift;
  my $bldInfDir = shift;

  if (exists $self->{abldcache}->{"plats"}) {
    return $self->{abldcache}->{"plats"};
  }
  $self->CallBldMakeIfNecessary($bldInfDir);

 TRYAGAIN:
  my $foundPlats = 0;
  my @plats;
  my @errorLines;

  my @abldOutput = `($bldInfDir\\abld help | perl -pe "s/^/stdout: /") 2>&1`; # Adds 'stdout: ' to the beginning of each STDOUT line, nothing is added to output on STDERR.

  foreach my $line (@abldOutput) {
    chomp $line;
      
    if ($line =~ s/^stdout: //) { # Output from STDOUT
      if ($foundPlats) {
        if ($self->{verbose}) { print "Found platforms: $line\n"; }
        $line =~ s/^\s*//; # Strip off leading whitespace.
        # Force platforms to upper case to match IniData::TargetPlatforms()
        $line = uc $line;
        @plats = split /\s+/, $line;
        last;
      }
      if ($line =~ /project platforms:/) {
        $foundPlats = 1;
      }
    }
 
    else { # Output from STDERR
      if ($line =~ m/project bldmake directory.*does not exist/i) {
        $self->CallBldMake($bldInfDir);
        goto TRYAGAIN;
      }  
      elsif ($line =~ /Can't find ABLD.PL on PATH/i) {
        push @errorLines, "Error: Couldn't run $bldInfDir\\abld: $line\n";      
      }
      else {
        push @errorLines, "$line\n";
      }
    }
  }

  if (scalar @errorLines > 0) {
    die @errorLines;
  }

  die "Error: didn't find any platforms\n" unless $foundPlats;

  $self->{abldcache}->{"plats"} = \@plats;

  return \@plats;
}

sub ReadBinaries {
  my $self = shift;
  my $abldPath = shift;
  my $test = lc(shift);
  my $plat = lc(shift);
  my $var = lc(shift);
  my $mmp = shift;
  my $remove = shift;
  my $successRef = shift;
  my $command = "target";
  my $opts = "-what";
  $command = "$test $command" if $test;
  $opts = "$mmp $opts" if $mmp;
  if ($self->{verbose}) { print "Extracting target info from \"$abldPath\\abld.bat\" using \"$command $plat $var\"...\n";  }

  my $bins = $self->GatherAbldOutput($abldPath, $plat, $command, $var, $test, $opts);
  my $category = 'unclassified';
  if ($self->{iniData}->CategoriseBinaries() and not $plat =~ /^tools2?$/i) {
    $category = $plat . '_' . $var;
    if ($test) {
      $category = $test . '_' . $category;
    }
  }

  $self->AddBins($remove, $category, $bins, $successRef);
}

sub HandleExports {
  my $self = shift;
  my $abldPath = shift;
  my $test = shift;

  $test = $test?"test ":"";

  if ($self->{verbose}) {
    print "Extracting ${test}export info from $abldPath\\abld.bat...\n";
  }

  my $exports = $self->GatherAbldOutput($abldPath, "", "${test}export", "", $test, "-what");
  if ($self->{iniData}->CategoriseExports()) {
    foreach my $thisExport (@$exports) {
      if ($self->{verbose} > 1) { print "Found export \"$thisExport\"...\n"; }
      if (Utils::WithinEpocRoot($thisExport)) {
	$thisExport = Utils::RemoveEpocRoot($thisExport);
      }
      else {
	print "Warning: Exported file \"$thisExport\" is not within EPOCROOT\n";
      }

      # Note, the hash key is case lowered to ensure duplicates are rejected.
      # The original case is preserved in the hash values.
      my $thisExportLc = lc($thisExport);
      Utils::TidyFileName(\$thisExportLc);

      # Note, the exports are not yet classified because this is done using the source code classifications.
      # At this point we don't know if we've handled all the 'source' mrp keywords yet. Classification will
      # occur when the exports are asked for.
      $self->{exports}->{automatic}->{$thisExportLc} = $thisExport;
    }
    Utils::AbsolutePath(\$abldPath);
    push (@{$self->{exports}->{abldPaths}}, Utils::RemoveSourceRoot($abldPath));
  }
  else {
    # Handle exports treating them as binary files. Note, for a short while this code was changed to handle
    # exported directories (not just files). This functionality has been removed because bldmake doesn't
    # appear to cope with exported directories (it concatenates all the files in the specified directory into
    # a single file due to weird use of the 'copy' command).
    foreach my $thisExport (@$exports) {
      $self->HandleBinFile(0, 'unclassified', $thisExport); # 0 = don't remove.
    }
  }
}

sub HandleExportFile {
  my $self = shift;
  my $source = shift;
  my $destination = shift;
  my $remove = shift;

  if ($self->{iniData}->CategoriseExports()) {
    if ($remove) {
      my $destinationLc = lc(Utils::RemoveEpocRoot($destination));
      Utils::TidyFileName(\$destinationLc);
      if (exists $self->{exports}->{automatic}->{$destinationLc}) {
	print "Excluding export \"$destination\"...\n" if ($self->{verbose});
	delete $self->{exports}->{automatic}->{$destinationLc};
      } else {
        my $comp = $self->{comp} || "component name unknown";
        print "Warning: ($comp) -export_file: could not remove $destination, as it hadn't been added. Perhaps the lines in your MRP are in the wrong order, or you meant -binary?\n";
      }
    }
    else {
      Utils::CheckExists($source);
      Utils::CheckIsFile($source);
      Utils::CheckExists($destination);
      Utils::CheckIsFile($destination);
      $self->{exports}->{manual}->{Utils::RemoveSourceRoot($source)} = Utils::RemoveEpocRoot($destination);
    }
  }
  else {
    $self->HandleBinFile($remove, 'unclassified', $destination);
  }
}

sub AddBins {
  my $self = shift;
  my $remove = shift;
  my $category = shift;
  my $bins = shift;
  my $successRef = shift;

  foreach my $file (@$bins) {
    $self->HandleBinDirOrFile($remove, $category, $file, $successRef);
  }
}

sub EnsureDoesNotExist {
  my $self = shift;

  my $relDir = $self->{iniData}->PathData->LocalArchivePathForExistingOrNewComponent($self->{comp}, $self->{ver});
  if (-e $relDir) {
    die "Error: $self->{comp} $self->{ver} already exists\n";
  }
}

sub Validate {
  my $self = shift;
  my $warnNotError = shift; # produce warnings instead of errors for some messages

  return if $self->{validated};
  $self->{validated} = 1;

  $self->EnsureDoesNotExist;

  unless (defined $self->{comp}) {
    die "Error: No 'component' keyword specified in $self->{mrpName}\n";
  }

  $self->NotesSource(); # will die if we can't find a notes_source tag

  my @errors;
  my @warnings;
  
  foreach my $bin (@{$self->Binaries()}) {    
    my $file = Utils::PrependEpocRoot(lc($bin));
    
    if (my $result = $self->CheckPathLength($file)) {
      if ($warnNotError) {
        push (@warnings, "Warning: $result\n");
      } else { 
        push (@errors, "Error: $result\n");
      }
    }
    
    if ($self->{fixMissingLibs}) {
      unless (-e $file) {
        if ($file =~ /$ENV{EPOCROOT}epoc32\\release\\armi\\(\S+)\\(\S+\.lib)/) {
          my $fileToCopy = "$ENV{EPOCROOT}epoc32\\release\\thumb\\$1\\$2";
          print "Copying $fileToCopy to $file...\n";
          copy ($fileToCopy, $file) or push (@errors, "Error: Problem copying \"$fileToCopy\" to \"$file\": $!\n");
        }
        else {
          push (@errors, "Error: \"$file\" does not exist\n");
        }
      }
    }
    else {
      unless (-e $file) {
        push (@errors, "Error: \"$file\" does not exist\n");
      }
    }
  }

  foreach my $thisCategory (@{$self->ExportCategories()}) {
    foreach my $thisExport (@{$self->Exports($thisCategory)}) {
      $thisExport = Utils::PrependEpocRoot($thisExport); 
      
      if (my $result = $self->CheckPathLength($thisExport)) {
        if ($warnNotError) {
          push (@warnings, "Warning:  $result\n");
        } else { 
          push (@errors, "Error:  $result\n");
        }
      }

      unless (-e $thisExport) {
        push (@errors, "Error: \"$thisExport\" does not exist\n");
      }
    }
  }
 
  foreach my $thisSourceCategory (@{$self->SourceCategories()}) {
    foreach my $thisSourceFile (@{$self->Source($thisSourceCategory)}) {
      if (my $result = $self->CheckPathLength($thisSourceFile)) {
        if ($warnNotError) {
          push (@warnings, "Warning:  $result\n");
        } else { 
          push (@errors, "Error:  $result\n");
        }
      }
    }
  }
  
  if (@warnings) {
    print @warnings;
  }
  
  if (@errors and $#errors != -1) {
    if ($#errors == 0) {
      die $errors[0];
    }
    else {
      print @errors;
      my $firstError = $errors[0];
      chomp $firstError;
      die "Multiple errors (first - $firstError)\n";
    }
  }
}

sub CallBldMakeIfNecessary {
  my $self = shift;
  my $abldPath = shift;
  if (-e "$abldPath\\abld.bat") {
    # Check to see if bld.inf has been modifed since bldmake was last run.
    my $abldMTime = Utils::FileModifiedTime("$abldPath\\abld.bat");
    my $bldInfMTime = Utils::FileModifiedTime("$abldPath\\bld.inf");
    if ($bldInfMTime > $abldMTime) {
      $self->CallBldMake($abldPath);
    }
  }
  else {
    $self->CallBldMake($abldPath);
  }
}

sub GatherAbldOutput {
  my $self = shift;
  my $abldPath = shift;
  my $plat = shift;
  my $abldCmnd = shift;
  my $var = shift;
  my $test = shift;
  my $opts = shift;
  my @output;

  my $abldParms = $abldCmnd;
  $abldParms .= " $plat" if $plat;
  $abldParms .= " $var" if $var;
  $abldParms .= " $opts" if $opts;

  $abldPath=~s/\//\\/s; # Normalise all slashes to backslashes

  $self->ProcessCache($abldPath, $test) if (!exists($self->{abldcache}->{loaded}->{$abldPath}));
  
  if ($self->{abldcache}->{$abldPath." ".$abldParms}) {
    # Why do we bother with a cache?
    # Because you might see this in an MRP:
    #   binary \blah all
    #   -binary \blah mfrumpy
    # The "all" will be expanded to multiple calls to GatherAbldOutput, if we've got CategoriseBinaries on
    
    # The codes below are added to make MakeCBR follow cachefiles created by Raptor
    if($abldCmnd eq "export" and $opts eq "-what"){
        my $exports = $self->{abldcache}->{$abldPath." ".$abldParms};
        if(@$exports[0]){
          my $firstExportFile = @$exports[0];
          if($firstExportFile=~/^ARRAY*/){
            foreach my $thisExport (@$exports) {
                push (@output, @$thisExport[0]);
                push @{$self->{exportsToBeProcessed}}, {source => @$thisExport[1],
                                                        destination => @$thisExport[0],
                                                        abldPath => Utils::PrependSourceRoot($abldPath)};
            }
            $self->{raptorcache} = 1;
            return \@output;
          }
        }
    }
    
    return $self->{abldcache}->{$abldPath." ".$abldParms};
  }

  # Remove repeat guards - these stop CallBldMake and CallMakMake from being called
  #                        forever if a fatal error occurs with a build script.
  delete $self->{bldMakeCalled};
  delete $self->{"makMakeCalled_$plat"};

  $self->CallBldMakeIfNecessary($abldPath);

 TRYAGAIN:

  my @errorLines; # Used to store the error

  my $cmd = "$abldPath\\abld $abldParms";
  print "Executing command: $cmd\n" if $self->{verbose} > 1;

  my @abldOutput = `($cmd | perl -pe "s/^/stdout: /") 2>&1`;

  foreach my $line (@abldOutput) {
    chomp $line;

    if ($line =~ s/^stdout: //) { # Output from STDOUT 
      if ($self->{verbose} > 1) { print "ABLD: $line\n"; }    
      
      if ($line =~ /(^(make|make\[\d+\]): .*)/) {
        print "Warning: $1\n";
      }
      elsif ($line =~ /given more than once in the same rule/) {
        print "$line\n";      
      }
      elsif ($line =~ m/\.\./) {
        my $oldpath = cwd();
        eval {
          chdir($abldPath);
          Utils::AbsoluteFileName(\$line);
        };
        chdir($oldpath);
        if ($@) {
          print "Warning: could not convert path \"$line\" to an absolute path because: $@\n";
          # Do nothing. We just can't convert it to an absolute path. We'll push it onto the
          # output anyway because in some circumstances it will work out OK.
        }
        push (@output, $line);
      } else {
        # Lines without .. we don't bother making absolute, because it involves 4 chdir operations
        # so is a bit heavyweight.
        push (@output, $line);
      }
    }

    else { # Output from STDERR
      if ($self->{verbose} > 1) { print "ABLD: $line\n"; }    
  
      # Catch errors that look like the makefile isn't present.
      # Note, different versions of the build tools produce different things, so the regular expression below is a bit evil.
      if ($line =~ /^(U1052|make\[1\]: (?i:\Q$ENV{EPOCROOT}\EEPOC32\\BUILD\\.*): No such file or directory|make: \*\*\* \[.*\] Error 2)$/) {
  
        # Makefile not present, so generate it.
  
        $self->CallMakMake($abldPath, $plat, $test);
  
        goto TRYAGAIN;
      }        
      elsif ($line =~ /^ABLD ERROR: Project Bldmake directory .* does not exist$/
          or $line =~ /^ABLD ERROR: .* not yet created$/
          or $line =~ /abld\.bat does not exist/) {
  
        #BldMake needs to be run.
        $self->CallBldMake($abldPath);
        goto TRYAGAIN;
      }
      elsif ($line =~ /^This project does not support platform/) {
        push @errorLines, "Error: Platform \"$plat\" not supported\n";
      }
      elsif ($line =~ /^MISSING:/) {
        print "$line\n";
      }
      elsif ($line =~ /Can't find ABLD.PL on PATH/i) {
        push @errorLines, "Error: Couldn't run abld $abldParms: $line\n";      
      }
      else {
        push @errorLines, "$line\n";
      }
    }
  }
  
  if (scalar @errorLines > 0) {
    die @errorLines;
  }
  
  $self->{abldcache}->{$abldPath." ".$abldParms} = \@output;

  return \@output;
}

sub CallBldMake {
  my $self = shift;
  my $abldPath = shift;

  if (exists $self->{bldMakeCalled}) {
    die "Error: Problem calling bldmake in \"$abldPath\"\n";
  }
  else {
    $self->{bldMakeCalled} = 1;
  }

  if ($self->{verbose}) {
    print "Calling bldmake in $abldPath...\n";
  }
  my $cwd = cwd();
  chdir $abldPath or die "Error: Couldn't change working directory to $abldPath: $!\n";
  system "bldmake bldfiles";
  chdir $cwd;
  die "Error: \"bldmake bldfiles\" failed in \"$abldPath\" (exit status $?)\n" if ($?);
}

sub CallMakMake {
  my $self = shift;
  my $abldPath = shift;
  my $plat = shift;
  my $test = shift;

  my $repeatGuard = "makMakeCalled_$plat";
  if ($test) {
    $test = 'test';
    $repeatGuard .= '_test';
  }
  else {
    $test = '';
  }

  if (exists $self->{$repeatGuard}) {
    if ($test) {
      die "Error: Problem generating makefile for $test $plat in \"$abldPath\"\n";
    }
    else {
      die "Error: Problem generating makefile for $plat in \"$abldPath\"\n";
    }
  }
  else {
    $self->{$repeatGuard} = 1;
  }

  if ($self->{verbose}) {
    if ($test) {
      print "Generating makefile for $test $plat...\n";
    }
    else {
      print "Generating makefile for $plat...\n";
    }
  }
  system "$abldPath\\abld $test makefile $plat > NUL";
}

sub BinSets {
  my $self = shift;
  
  $self->ProcessBinaries();
  
  return $self->{binsets};
}

sub SourceRootPath {
  my $fileName = shift;
  if (Utils::IsAbsolute($fileName)) {
    $fileName = Utils::PrependSourceRoot($fileName);
  }
  else {
    Utils::AbsoluteFileName(\$fileName);
  }
  Utils::CheckWithinSourceRoot($fileName);
  $fileName =~ s/\\.$//;
  return $fileName;
}

sub WarnRedundantMRPLine {
  my $self = shift;
  my $remove = shift;
  my $line = shift;
  my $comp = $self->{comp} || "component name unknown";
  my $sign = "";
  my $action = "add";

  if($remove) {
    $action = "remove";
  }
  print "Remark: ($comp) The MRP line \"$line\" does not $action any files. Therefore is this line necessary?\n";
}

sub CheckPathLength {
  my $self = shift;
  my $path = shift;
  
  if (length ($path) > MAX_PATH_LENGTH) {
     return "The component \"$self->{comp}\" is pending release and contains a path which is " . length($path) . " characters long and will prevent the component from being released: \"$path\"."
  }

  return 0;
}

sub SetIPR {
    my $self = shift;
    my $category = shift;
    my $path = shift || 'default';
    my $exportRestricted = (shift) ? 1 : 0;
    
    if (!$category || shift) {
      # caller(0))[3] gives the package and the method called, e.g. MrpData::SetIPR
      croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }

    $path = File::Spec->canonpath($path); # Normalise the path
    
    # remove trailing slashes
    $path =~ s/[\\\/]$//;
    
    if ($path ne 'default') {
      $path = SourceRootPath($path);
    }

    if($self->{iniData}->HasMappings()){
      $path = $self->{iniData}->PerformMapOnFileName($path);
    }
    
    $path = Utils::RemoveSourceRoot($path) if ($path ne 'default');
    
    if (exists $self->{unresolvedIPR}->{$path}) {
      return 0;
    }
    
    $self->{unresolvedIPR}->{$path} = {
                    category => uc($category),
                    exportRestricted => $exportRestricted};
    
    return 1;
}

sub SetComponent {
    my $self = shift;
    my $operand = shift;

    croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n" if (shift);

    if (exists $self->{comp}) {
        return 0;
    }
    
    $self->{comp} = $operand;
    
    return 1;
}

sub SetNotesSource {
    my $self = shift;
    my $operand = shift;
   
    if (!$operand || shift) {
      croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    if (exists $self->{notes_src}) {
        return 0;
    }

    $operand = File::Spec->canonpath($operand); # Normalise the path
    
    $operand = SourceRootPath($operand);
    
    if($self->{iniData}->HasMappings()){
        $operand = $self->{iniData}->PerformMapOnFileName($operand);
    }
    
    Utils::CheckExists($operand);
    Utils::CheckIsFile($operand);
    $self->{notes_src} = Utils::RemoveSourceRoot($operand);
    
    return 1;
}

sub SetSource {
    my $self = shift;
    my $operand = shift;
    
    croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n" if (shift);

    if ($operand =~ /distribution\.policy$/i) {
      print "\nREMARK: Distribution Policy file included as source in \"$self->{mrpName}\"\n";
      return 1;
    }

    $operand = File::Spec->canonpath($operand); # Normalise the path
        
    #remove trailing slashes
    $operand =~ s/[\\\/]$//;
    
    $operand = SourceRootPath($operand);

    if($self->{iniData}->HasMappings()){
      $operand = $self->{iniData}->PerformMapOnFileName($operand);
    }
    
    Utils::CheckExists($operand);
    $self->{srcitems}->{Utils::RemoveSourceRoot($operand)} = 1;
    # No longer classify the source. We do this on-demand later.
    
    return 1;
}

sub SetBinary {
    my $self = shift;
    my @words =  @{shift()};
    my $test = (shift) ? 1 : 0;
    my $remove = (shift) ? 1 : 0;

    croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n" if (shift);

    my $path = shift @words;

    $path = File::Spec->canonpath($path); # Normalise the path
    
    # tranfer to absolute path
    $path = SourceRootPath($path);

    if (scalar @words) {
        if($self->{iniData}->HasMappings()){
            $path = $self->{iniData}->PerformMapOnFileName($path);
        }
    }

    push @{$self->{binaryStatements}}, {
                        abldPath => $path,
                        test     => $test,
                        remove   => $remove,
                        words    => [@words]};
}

sub SetExports {
    my $self = shift;
    my $abldPath = shift;
    my $test = (shift) ? 1 : 0;
    my $dependantComponent = shift;

    if (!$abldPath || shift) {
        croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n";
    }
    
    if ($dependantComponent) {
    	push (@{$self->{_dependantComponents}->{$dependantComponent}}, $abldPath);
    }

    $abldPath = File::Spec->canonpath($abldPath); # Normalise the path
        
    $abldPath = SourceRootPath($abldPath);

    if($self->{iniData}->HasMappings()){
      $abldPath = $self->{iniData}->PerformMapOnFileName($abldPath);
    }

    Utils::CheckExists($abldPath);
    
    push @{$self->{exportsStatements}}, { abldPath => $abldPath,
                                           test => $test};
}

sub SetExportFile {
    my $self = shift;
    my $source = shift;
    my $destination = shift;
    my $remove = (shift) ? 1 : 0;
    my $dependantComponent = shift;
 
    croak "Invalid number of arguments passed to " . (caller(0))[3] . "\n" if (shift);
        
    unless ($source and $destination) {
	croak "Error: Incorrect syntax to 'export_file' keyword in \"$self->{mrpName}\"\n";
    }

    if ($dependantComponent) {
    	push (@{$self->{_dependantComponents}->{$dependantComponent}}, $source);
    }
    
    $source = File::Spec->canonpath($source); # Normalise the path
    $destination = File::Spec->canonpath($destination);
        
    $source = SourceRootPath($source);

    if($self->{iniData}->HasMappings()){
      $source = $self->{iniData}->PerformMapOnFileName($source);
      $destination = $self->{iniData}->PerformMapOnFileName($destination);
    }

    $destination = Utils::PrependEpocRoot($destination);
    
    push @{$self->{unprocessedExportFiles}}, { source => $source,
                                           destination => $destination,
                                           remove => $remove};
}

sub GetIPRInformation {
    my $self = shift;
    
    if (exists $self->{IPR}) {
        return $self->{IPR};
    }
    else {
        return {};
    }
}

sub GetExportComponentDependencies {
    my $self = shift;	

    if (defined $self->{_dependantComponents}) {
            return (keys %{$self->{_dependantComponents}}); # Return an array of the dependencies
    }
    
    return undef;
}

sub ValidateParsing {
    my $self = shift;
    
    # This flag stops the reader from trying to populate the object more than once
    $self->{populated} = 1;
    
    if (exists $self->{srcitems} && !exists $self->{unresolvedIPR}) {
        # If no IPR information exists in the MRP file then we set the IPR category
        # for each source item to undef.  This is so that incorrect IPR information is
        # not returned.  A flag is also set to indicate that IPR information exists.  The
        # flag will be used to ensure other parts other parts of validation should will
        # not be performed (e.g. validating exports).
        
        $self->{noIprInformation} = 1;
        
        foreach my $sourceItem (keys %{$self->{srcitems}}) {
            $self->{IPR}->{$sourceItem} = {
                                           category => undef,
                                           exportRestricted => undef,
                                           };
        }
    }
    else {
        # Reconcile the IPR information here so that any warnings are produced sooner...
        # IPR information can only be included if it matches a source line in the MRP file
        # All other IPR lines will be ignored.  The reconciliation is done here as IPR
        # lines may appear before source lines in the MRP file.

        if (!defined $self->{srcitems} && exists $self->{unresolvedIPR}->{default}) {
            carp "Warning: The default IPR entry does not apply to any source statements in \"$self->{mrpName}\"\n";
        }
       
        # Match IPR against source statement by using the length...
        foreach my $sourceItem (keys %{$self->{srcitems}}) {
            # The sort below sorts by longest line first, not shortest line first. Note $b <=> $a, not $a <=> $b...
            # This allows us to match the most relevant line first, based on longest length/best match 
            foreach my $iprItem (sort {length($b) <=> length($a)} keys %{$self->{unresolvedIPR}}) {
                next if ($iprItem eq 'default');
                # If the source item contains the IPR path then it is a match 
                if ($sourceItem =~ m/^\Q$iprItem\E([\\\/]|$)/i) {
                    $self->{IPR}->{$sourceItem} = $self->{unresolvedIPR}->{$iprItem};
                    
                    last;   
                }
            }
                 
            # If it didn't match an IPR then we assign the default
            if (!exists $self->{IPR}->{$sourceItem}) {
                $self->{IPR}->{$sourceItem} = $self->{unresolvedIPR}->{default};
            }
        }

        delete $self->{unresolvedIPR}->{default};
	    
        # Find IPR entries which do live under a source folder...
        foreach my $iprItem (keys %{$self->{unresolvedIPR}}) {
            next if (exists $self->{IPR}->{$iprItem});
	    
            foreach my $sourceItem (keys %{$self->{srcitems}}) {
                if ($iprItem =~ /^\Q$sourceItem\E/i) {
                    $self->{IPR}->{$iprItem} = $self->{unresolvedIPR}->{$iprItem};
                    last;
                }
            }
	    
            if (!grep /\Q$iprItem\E/i, (keys %{$self->{IPR}})) {
                # Otherwise this IPR statement does not apply to this MRP file...
                carp "Warning: The IPR entry for \"$iprItem\" does not apply to any source statements in \"$self->{mrpName}\"\n";
            }
        }    
    }
  
    delete $self->{unresolvedIPR};
}


sub ProcessExports {
  my $self = shift;
  my $confirmExportIprInformation = shift;
  
  return if ($self->{exportsProcessed});
  
  $self->{exportsProcessed} = 1;
  
  foreach my $export (@{$self->{exportsStatements}}) {
    $self->HandleExports($export->{abldPath}, $export->{test});
  }
  
  foreach my $exportFile (@{$self->{unprocessedExportFiles}}) {    
    if($self->{raptorcache}){
      my $isHandle = 0;
      foreach my $export (@{$self->{exportsToBeProcessed}}) {
        if($export->{source} eq $exportFile->{source}){
          if (exists $self->{exports}->{automatic}->{lc(Utils::RemoveEpocRoot($export->{destination}))}) {
            $self->HandleExportFile($export->{source}, $export->{destination}, $exportFile->{remove});
            $isHandle = 1;
          }
        }
      }
      if($isHandle == 0){
        foreach my $export (@{$self->{exportsToBeProcessed}}) {
          if(lc($export->{destination}) eq lc($exportFile->{destination})){
            foreach my $tempExport (@{$self->{exportsToBeProcessed}}) {
              if($export->{source} eq $tempExport->{source}){
                if (exists $self->{exports}->{automatic}->{lc(Utils::RemoveEpocRoot($tempExport->{destination}))}) {
                  $self->HandleExportFile($tempExport->{source}, $tempExport->{destination}, $exportFile->{remove});
                }
              }
            }
          }
        }
      }
    }
    else{
      $self->HandleExportFile($exportFile->{source}, $exportFile->{destination}, $exportFile->{remove});
    } 
  }
  
  delete $self->{unprocessedExportFiles};
  
  # If exports are to be classified, or the caller wants to confirm the IPR information for exports is correct...
  if ($self->{iniData}->CategoriseExports() || $confirmExportIprInformation) {
      $self->ClassifyManualExports();
      
      # The codes below are changed to make MakeCBR follow cachefiles created by Raptor
      if(!$self->{raptorcache}){
        $self->ClassifyAutomaticExports();
      }
      else{
        my @tempExports;
        foreach my $export (@{$self->{exportsToBeProcessed}}) {
          if (exists $self->{exports}->{automatic}->{lc(Utils::RemoveEpocRoot($export->{destination}))}) {
            push @tempExports, $export;
          }
        }
        @{$self->{exportsToBeProcessed}} = @tempExports;
		
        delete $self->{exports}->{automatic};
        delete $self->{exports}->{abldPaths};
      }
      delete $self->{raptorcache};
      
      # If no IPR information exists in the MRP file then we do not validate the exports as we don't care about if
      # we need dependant components
      if (!$self->{noIprInformation}) {
        # Check to see if the exports are owned by the component, or dependant components have been specified...
        foreach my $export (@{$self->{exportsToBeProcessed}}) {
          # check if the exports are included as source in this component
          if (!grep keys %{$self->{srcitems}}, $export->{source}) {
            # If not then check if another dependant component for the export has been specified
            
            # A dependant component is specified for either the export source or the exports abld path
            my $whatToTest = 'source';
            $whatToTest = 'abldPath' if (exists $export->{abldPath});
       
            my $dependencyExists = 0;
  
            foreach my $dependantComponent (keys %{$self->{_dependantComponents}}) {
              if (grep /\Q$export->{$whatToTest}\E/i, (@{$self->{_dependantComponents}->{$dependantComponent}})) {
                $dependencyExists = 1;
              }            
            }
            
            if (!$dependencyExists) {
              # If no dependency exists...
              warn "Warning: ".$self->Component()." contains an export '". $export->{source} ."' which is not included as source for this component, and does not contain dependencies on another component\n";
            }
          }
        }
      }
      
      # If we only processed exports to that we can confirm the IPR information, but
      # we don't actually want to categorise exports then we delete them
      if (!$self->{iniData}->CategoriseExports() && $confirmExportIprInformation) {
        delete $self->{exportsToBeProcessed};
      }
  }

  my $errors;
  
  foreach my $export (@{$self->{exportsToBeProcessed}}) {
    if (!$self->AddExport($export->{source}, $self->RemoveRoot($export->{destination}))) {
      $errors = 1;
    }        
  }
  if ($errors) {
    die "Aborting due to above error(s)\n";
  }  

  delete $self->{exportsToBeProcessed};

  if ($self->{binariesProcessed}) {
    # if binaries and exports have been processed then we delete the abldcach as
    # it is no longer required and takes up a lot of memory
    delete $self->{abldcache};
  }
}

sub RemoveRoot {
  my $self = shift;
  my $path = shift;
  return $1 if($path =~ /^\\(.+)/);
  return $path;
}

sub ProcessBinaries {
  my $self = shift;
  
  return if ($self->{binariesProcessed});
  
  $self->{binariesProcessed} = 1;  
  
  foreach my $binary (@{$self->{binaryStatements}}) {
  
    my $success = 0;

    if (!scalar(@{$binary->{words}})) {
        $binary->{abldPath} = Utils::PrependEpocRoot($binary->{abldPath});
        # Pass a reference of $success to HandleBinDirOrFile which can only be changed in HandleBinFile if the operation is successful.
        $self->HandleBinDirOrFile($binary->{remove}, "unclassified", $binary->{abldPath}, \$success);
        if ($success == 0 )
        {
            my $line;
            $line = 'test' if ($binary->{test});
            $line .=  'binary ' . join ' ', @{$binary->{words}};
            $self->WarnRedundantMRPLine($binary->{remove}, $line);
        }
    }
    else {
        # Pass a reference of $success to HandleBinSet which can only be changed in HandleBinFile if the operation is successful.
        $self->HandleBinSet($binary->{remove}, $binary->{test}, \$success, $binary->{abldPath}, @{$binary->{words}});
        if ($success == 0 )
        {
            my $line;
            $line = 'test' if ($binary->{test});
            $line .=  'binary ' . join ' ', @{$binary->{words}};
            $self->WarnRedundantMRPLine($binary->{remove}, $line);
        }
    }
  }
  
  if ($self->{exportsProcessed}) {
    # if binaries and exports have been processed then we delete the abldcache as
    # it is no longer required and takes up a lot of memory
    delete $self->{abldcache};
  }
}


1;

__END__

=head1 NAME

MrpData.pm - Provides an interface to the contents of a component's MakeRel project (mrp) file.

=head1 DESCRIPTION

Once a C<MrpData> object has been created using the C<New> method, the remaining methods can be used to access the F<.mrp> data.

=head1 INTERFACE

=head2 New

Expects to be passed the name of the mrp file. This doesn't necessarily have to have a F<.mrp> extension. The parser supports the following keyword / value pairs:

  component    <component_name>
  source       <source_file|source_directory>
  binary       [<abld_path> <platform> [<variant> <program>]] | [<binary_file>] | [<binary_directory>]
  -binary      [<abld_path> <platform> [<variant> <program>]] | [<binary_file>] | [<binary_directory>]
  testbinary   <abld_path> <platform> [<variant> <program>]
  -testbinary  <abld_path> <platform> [<variant> <program>]
  exports      <abld_path>
  notes_source <release_notes_source_path>
  ipr          [<export-restricted>] type [<directory>]

=head2 Component

Returns a string containing the name of the component.

=head2 MrpName

Returns a string containing the full path name of the component's F<mrp> file.

=head2 ExternalVersion

Returns a string containing the external version of the component to be released.

=head2 InternalVersion

Returns a string containing the internal version of the component to be released.

=head2 SourceCategories

Returns a reference to a list of source IPR categories present in the component. Each of these may be used as an input to C<Source>. These categories are defined in 'distribution.policy' files.

=head2 Source

Expects to be passed a scalar containing the required source category. Returns a reference to a list of source files corresponding to the specified category for this component.

=head2 SourceItems

Expects no arguments. Returns a list of the operands of all the "source" statements found in the MRP file. This is then stored in the RelData file and is later used by validation to work out which director(y|ies) to check for added files.

=head2 BinaryCategories

Returns a reference to a list of binary categories present in the component. Each of these may be used as an input to C<Binaries>. The binary categories are determined by the structure of the F<mrp> file. For example, the statement C<binary \mycomp thumb urel> will result in the associated binaries being classified and C<thumb_urel>. The statement C<testbinary \mycomp arm4> will generate two categories - C<test_arm4_udeb> and C<test_arm4_urel>. Any binary files or directories that are explictly referenced (e.g. C<binary \epoc32\myfile.txt> or C<binary \epoc32\mydir>) are categorised as C<unclassified>. Also, any binary files that are found to be common between any two categories and re-categorised as C<unclassified>. This is to ensure that each binary F<zip> file contains a unique set of files.

If the C<categorise_binaries> keyword has not been specified in the user's F<reltools.ini> file, this interface will always return a reference to a list with a single entry in it - C<unclassified>.

=head2 Binaries

Returns a reference to a list of binary files for this component. May optionally be passed a scalar containing the required binary category, in which case it returns a list of just the binaries in the specified category. Dies if the requested category is not present.

=head2 ExportCategories

Returns a reference to a list of export categories present in the component. If the C<categorise_exports> keyword has not been specified in the user's F<reltools.ini> file, this list will contain a single entry - C<unclassified>. Otherwise, each exported file will be categorised according to the rules used for categorising source code. The returned list will in this case contain the set of exported source categories present in the component. Elements in this list may be used as inputs to the method below (C<Exports>).

=head2 Exports

Returns a reference to a list of exported file for this component. May optionally be passed a scalar containing the required export category, in which case it returns a list of just the exports in the specified category. Dies if the requested category is not present.

=head2 ExportInfoForCat

Expects a category to be passed. Returns the exportinfo for the category.

=head2 BinariesAndExports

Returns a reference to a list of all the binaries and exports of this component. Note, unlike the methods C<Binaries> and C<Exports>, this method does not allow a category to be specified. This is because binaries are categorised according to build type and exports are categorised according to source intellectual property rights rules. They two types of categorisation are incompatible.

=head2 NotesSource

Returns a string containing the path and name of the release notes source file for this component.

=head2 BinSets

Returns a reference to an array of hashes, representing each "binary <path> <platform> <variant>" line. The hashes have these fields: path, plat, var, mmp (often ''), and test (a Boolean). This method is used by C<MakeRel> and C<MakeEnv> to build the component before release.

=head2 EnsureDoesNotExist

Checks that the version given does not already exist in an archive.

=head2 Validate

Checks that all the files shown in the MRP do actually exist.

=head2 ClassifyAutomaticExports

Classify exports that were specified using the 'exports' or 'testexports' keyword in the mrp file.

=head2 ProcessExportMakeFile

Expect EXPORT.MAKE/EXPORTTEST.MAKE file, classify exports that were specified using the 'exports'/'testexports' keyword in the mrp file.

=head2 WarnRedundantMRPLine

Output warnings about redundant MRP lines (full redundancy).

=head2 GetIPRInformation()

Returns a hash containing the IPR information for the component.

The format is the returned data is a hash:

    Path = (
                    category = char,
                    exportRestricted = boolean
            )

=head2 SetBinary(@arguments, test, remove)

Sets the binary information.  @arguments is an array containing the arguments
from the MRP line, in the order in which they appeared.  

=head2 SetComponent(componentName)

Sets the name of the component to componentName.

=head2 SetExportFile(source, destination, remove, dependantComponent)

Sets the export file information.  The source and destination arguments are both
required, if they are not specified a fatal error will be produced.  The source
file will also be checked to see if it exists and that it has not already been
specified as an export file.

If the export file is not included as source for the current MRP component then
the dependant component will also need to be specified.

=head2 SetExports(path, test, dependantComponent)

Sets the location of the bld.inf from where the export information can be derived.
The location will be checked to see if it exists and that it has not already been
specified.

If the exports are not included as source for the current MRP component then
the dependant component will also need to be specified.

=head2 SetIPR(category, path, exportRestricted)

Sets the IPR information for the component.  If no path is specified then the
IPR category is set to be the default category for the component.  The
exportRestricted argument is boolean.

If the same path is specified more than once a fatal error will be produced.

=head2 SetNotesSource(noteSourcePath)

Sets the notes source to the notesSourcePath specified.  If the notes source has
already been set, or the path does not exist, a fatal error will be produced.

=head2 SetSource(sourcePath)

Adds the sourcePath to the list of included source entries for the component.
If the source path does not exist or the path has already been added then a
fatal error will be produced.

=head2 ValidateParsing()

This method needs to be called once the parser has finished setting all the
information.  Currently this method reconciles IPR statements against the
components source, and also checks that required dependant components have
been set.

If this method is not run then IPR information will be unavailable.

=head2 GetExportComponentDependencies()

Returns an array containing the any components which the current component has
dependencies on.

=head2 Populated()

The MRP file is parsed by a reader, which then populates this MRP object.  The
Populated method returns a boolean value indicating if the object has been
populated.

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
