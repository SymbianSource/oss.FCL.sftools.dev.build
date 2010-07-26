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

package Utils;
use base qw(Exporter);
use strict;
use Win32;
use Win32::File;
use Win32::Console;
use File::stat;
use File::Path;
use File::Basename;
use File::Find;
use File::Temp;
use File::Spec;
use FindBin;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Cwd 'abs_path';
use Data::Dumper;
use Time::Local;
use IPC::Open2;
use Cwd;
use Symbian::IPR;

$|++;

#
# Constants.
#

use constant EPOC_RELATIVE => 1;
use constant SOURCE_RELATIVE => 2;
use constant MAX_OS_PATH_LENGTH => 255;
our @EXPORT = qw(EPOC_RELATIVE SOURCE_RELATIVE);

#
# Globals;
#

my $console; # Needs to be global because (for some reason) file descriptors get screwed up if it goes out of scope.
my $tempDir;
my $haveCheckedEpocRoot;
my $haveCheckedSrcRoot;
our %zipFileCache; # used to cache the Archive::Zip object of the last zip file used

#
# Subs.
#

sub StripWhiteSpace {
  my $a = shift;
  $$a =~ s/^\s*//;
  $$a =~ s/\s*$//;
}

sub TidyFileName {
  my $a = shift;
  $$a =~ s/\//\\/g;      # Change forward slashes to back slashes.
  $$a =~ s/\\\.\\/\\/g;  # Change "\.\" into "\".

  if ($$a =~ /^\\\\/) {  # Test for UNC paths.
    $$a =~ s/\\\\/\\/g;  # Change "\\" into "\".
    $$a =~ s/^\\/\\\\/;  # Add back a "\\" at the start so that it remains a UNC path.
  }
  else {
    $$a =~ s/\\\\/\\/g;  # Change "\\" into "\".
  }

  # Colapse '\..\' sequences.
  my $hasLeadingSlash = $$a =~ s/^\\//;
  my $hasTrailingSlash = $$a =~ s/\\$//;
  my @elements = split (/\\/, $$a);
  my @result; # An array to store the colapsed result in.
  foreach my $element (@elements) {
    if ($element eq '..') {
      my $last = pop @result;
      if ($last) {
	if ($last eq '..') { # Throw away the previous element, unless it's another '..'.
	  push (@result, $last);
	  push (@result, $element);
	}
	next;
      }
    }
    push (@result, $element);
  }
  if ($hasLeadingSlash) {
    $$a = '\\';
  }
  else {
    $$a = '';
  }
  $$a .= join ('\\', @result);
  if ($hasTrailingSlash) {
    $$a .= '\\';
  }
}

sub IsAbsolute {
  my $path = shift;
  if ($path =~ /^[\\\/]/) {
    return 1;
  }
  return 0;
}

sub AbsoluteFileName {
  my $fileName = shift;
  (my $base, my $path) = fileparse($$fileName);
  my $absPath = abs_path($path);
  $absPath =~ s/^\D://; # Remove drive letter.
  $$fileName = $absPath;
  unless ($$fileName =~ /[\\\/]$/) {
    $$fileName .= "\\";
  }
  $$fileName .= $base;
  TidyFileName($fileName);
}

sub AbsolutePath {
  my $path = shift;
  my $absPath = abs_path($$path);
  $absPath =~ s/^\D://; # Remove drive letter.
  $$path = $absPath;
  TidyFileName($path);
}

sub EpocRoot {
  my $epocRoot = $ENV{EPOCROOT};
  unless ($haveCheckedEpocRoot) {
    #use Carp qw/cluck/;
    #cluck "Checking for EpocRoot";
    die "Error: Must set the EPOCROOT environment variable\n" if (!defined($epocRoot));
    die "Error: EPOCROOT must not include a drive letter\n" if ($epocRoot =~ /^.:/);
    die "Error: EPOCROOT must be an absolute path without a drive letter\n" if ($epocRoot !~ /^\\/);
    die "Error: EPOCROOT must not be a UNC path\n" if ($epocRoot =~ /^\\\\/);
    die "Error: EPOCROOT must end with a backslash\n" if ($epocRoot !~ /\\$/);
    die "Error: EPOCROOT must specify an existing directory\n" if (!-d $epocRoot);
    $haveCheckedEpocRoot = 1;
  }
  return $epocRoot;
}

sub SourceRoot {
  my $srcRoot = $ENV{SRCROOT};
  unless ($haveCheckedSrcRoot) {
    if (defined $srcRoot) { # undefined SRCROOTs are OK
      die "Error: SRCROOT must not include a drive letter\n" if ($srcRoot =~ /^.:/);
      die "Error: SRCROOT must be an absolute path without a drive letter\n" if ($srcRoot !~ /^\\/);
      die "Error: SRCROOT must not be a UNC path\n" if ($srcRoot =~ /^\\\\/);
      die "Error: SRCROOT must end with a backslash\n" if ($srcRoot !~ /\\$/);
      die "Error: SRCROOT must specify an existing directory\n" if (!-d $srcRoot);
    }
    $haveCheckedSrcRoot = 1;
  }
  return $srcRoot || "\\";
}

sub CheckWithinEpocRoot {
  my $path = shift;
  die "Error: \"$path\" is not within EPOCROOT\n" unless (WithinEpocRoot($path));
}

sub WithinEpocRoot {
  my $path = shift;
  my $epocRoot = EpocRoot();
  return ($path =~ /^\Q$epocRoot\E/i);
}

sub PrependEpocRoot {
  my $path = shift;
  if (EpocRoot() ne "\\") {
    #use Carp qw/cluck/;
    #cluck "here";
    die "Error: EPOCROOT already present in \"$path\"\n" if ($path =~ /^\Q$ENV{EPOCROOT}\E/i);
  }
  $path =~ s!^[\\\/]!!; # Remove leading slash.
  return EpocRoot().$path;
}

sub RelativeToAbsolutePath {
	my $path = shift;
	my $iniData = shift;
	my $pathType = shift;

	if ( $pathType == SOURCE_RELATIVE ) {
		if( $iniData->HasMappings() && SourceRoot() eq "\\" ) {
			$path = $iniData->PerformMapOnFileName( $path );
		}
		else{
			$path = PrependSourceRoot( $path );
		}
	}
	else {
		$path = PrependEpocRoot( $path );
	}
	return $path;
}

sub RemoveEpocRoot {
  my $path = shift;
  unless ($path =~ s/^\Q$ENV{EPOCROOT}\E//i) {
    die "Error: Path does not contain EPOCROOT - EPOCROOT:\"$ENV{EPOCROOT}\" - Path:\"$path\"\n";
  }
  return $path;
}

sub CheckWithinSourceRoot {
  my $path = shift;
  die "Error: \"$path\" is not within SRCROOT\n" unless (WithinSourceRoot($path));
}

sub WithinSourceRoot {
  my $path = shift;
  my $sourceRoot = SourceRoot();
  return ($path =~ /^\Q$sourceRoot\E/i);
}

sub PrependSourceRoot {
  my $path = shift;
  my $sourceRoot = SourceRoot();
  if ($sourceRoot ne "\\") {
    die "Error: SRCROOT already present in \"$path\"\n" if ($path =~ /^\Q$sourceRoot\E/i);
  }

  $path =~ s!^[\\\/]!!; # Remove leading slash.
  return SourceRoot() . $path;
}

sub RemoveSourceRoot {
  my $path = shift;
  my $sourceRoot = SourceRoot();
  unless ($path =~ s/^\Q$sourceRoot\E//i) {
    die "Error: Couldn't remove \"$sourceRoot\" from \"$path\"\n";
  }
  return $path;
}

sub MakeDir ($) {
  my $dir = shift;
  $dir =~ s/\//\\/g; # Convert all forward slashes to back slashes in path.
  unless (-e $dir) {
    if ($dir =~ /^\\\\/) {
      # This is a UNC path - make path manually because UNC isn't supported by mkpath.
      my $dirToMake = '';
      my @dirs = split /\\/, $dir;
      shift @dirs;  # Get rid of undefined dir.
      shift @dirs;  # Get rid of undefined dir.
      my $server = shift @dirs;
      my $share = shift @dirs;
      $dirToMake .= "\\\\$server\\$share";
      unless (-e $dirToMake) {
	die "Error: Network share \"$dirToMake\" does not exist\n";
      }
      foreach my $thisDir (@dirs) {
	$dirToMake .=  "\\$thisDir";
	unless (-e $dirToMake) {
	  mkdir($dirToMake,0) or die "Error: Couldn't make directory $dirToMake: $!\n";
	}
      }
    }
    else {
      my @warnings;
      local $SIG{__WARN__} = sub {push @warnings, $!};
      
      eval {mkpath($dir)};
      if (@warnings) {
        die "Error: Couldn't make path \"$dir\": " . (join ', ', @warnings) . "\n";
      }
    }
  }
}

sub FileModifiedTime {
  my $file = shift;
  my $st = stat($file) or return 0;
  return TimeMinusDaylightSaving($st->mtime);
}

sub FileSize {
  my $file = shift;
  my $st = stat($file) or return 0;
  return $st->size;
}

sub FileModifiedTimeAndSize {
  my $file = shift;
  my $st = stat($file) or return 0;
  return (TimeMinusDaylightSaving($st->mtime), $st->size);
}

sub TimeMinusDaylightSaving {
  my $time = shift;
  (undef, undef, undef, undef, undef, undef, undef, undef, my $isDaylightSaving) = localtime;
  if ($isDaylightSaving) {
    $time -= 3600;
  }
  return $time;
}

sub TextTimeToEpochSeconds {
  my $textTime = shift;
  $textTime =~ /(\S+) (\S+) {1,2}(\d+) {1,2}(\d+):(\d+):(\d+) {1,2}(\d+)/;
  my $weekDay = $1;
  my $month = $2;
  my $monthDay = $3;
  my $hours = $4;
  my $minutes = $5;
  my $seconds = $6;
  my $year = $7 - 1900;

  if    ($month eq 'Jan') { $month = 0; }
  elsif ($month eq 'Feb') { $month = 1; }
  elsif ($month eq 'Mar') { $month = 2; }
  elsif ($month eq 'Apr') { $month = 3; }
  elsif ($month eq 'May') { $month = 4; }
  elsif ($month eq 'Jun') { $month = 5; }
  elsif ($month eq 'Jul') { $month = 6; }
  elsif ($month eq 'Aug') { $month = 7; }
  elsif ($month eq 'Sep') { $month = 8; }
  elsif ($month eq 'Oct') { $month = 9; }
  elsif ($month eq 'Nov') { $month = 10; }
  elsif ($month eq 'Dec') { $month = 11; }

  return timelocal($seconds, $minutes, $hours, $monthDay, $month, $year);
}

sub TextDateToEpochSeconds {
  my $textDate = shift;
  (my $day, my $month, my $year) = split (/\//, $textDate, 3);
  unless ($day and $month and $year) {
    die "Error: Invalid date specification: \"$textDate\"\n";
  }
  return timelocal(0, 0, 0, $day, $month - 1, $year - 1900);
}

sub SetFileReadOnly {
  my $file = shift;
  Utils::TidyFileName(\$file);
  system "attrib +r $file";
}

sub SetFileWritable {
  my $file = shift;
  Utils::TidyFileName(\$file);
  system "attrib -r $file";
}

sub SplitFileName {
  my $fileName = shift;
  my $path = '';
  my $base = '';
  my $ext = '';

  if ($fileName =~ /\\?([^\\]*?)(\.[^\\\.]*)?$/) {
    $base = $1;
  }
  if ($fileName =~ /^(.*\\)/) {
    $path = $1;
  }
  if ($fileName =~ /(\.[^\\\.]*)$/o) {
    $ext =  $1;
  }

  unless ($fileName eq "$path$base$ext") {
    my $prob = ($^V eq "v5.6.0")?" There is a known defect in Perl 5.6.0 which triggers this issue with filenames with two extensions (e.g. .exe.map). Please upgrade to Perl 5.6.1.":"";
    die "Couldn't parse filename \"$fileName\".$prob";
  }
  return ($path, $base, $ext);
}

sub SplitQuotedString {
  my $string = shift;
  my $original = $string;
  my @output = ();
  $string =~ s/^\s+//; # Remove leading delimiter if present.
  while ($string) {
    if ($string =~ s/^\"(.*?)\"//    # Match and remove next quoted string
	or $string =~ s/^(.*?)\s+//  # or, match and remove next (but not last) unquoted string
	or $string =~ s/^(.*)$//) {  # or, match and remove last unquoted string.
      push (@output, $1);
      $string =~ s/^\s+//; # Remove delimiter if present.
    }
    else {
      die "Error: Unable to decode string \"$original\"\n";
    }
  }
  return @output;
}

sub ConcatenateDirNames {
  my $dir1 = shift;
  my $dir2 = shift;
  TidyFileName(\$dir1);
  TidyFileName(\$dir2);
  $dir1 =~ s/([^\\]$)/$1\\/;
  $dir2 =~ s/^\\//;
  return $dir1.$dir2;
}

sub FindInPath {
  my $file = shift;
  unless (exists $ENV{PATH}) {
    die "Error: No path environment variable\n";
  }
  foreach my $dir (split (/;/, $ENV{PATH})) {
    if (-e "$dir\\$file") {
      return "$dir\\$file";
    }
  }
  die "Error: \"$file\" not found in path\n";
}

sub ReadDir {
  my $dir = shift;
  my @dir;
  opendir(DIR, $dir) or die "Error: Couldn't open directory \"$dir\": $!\n";
  while (defined(my $file = readdir(DIR))) {
    next if ($file eq '.' or $file eq '..');
    push (@dir, $file);
  }
  closedir(DIR);
  return \@dir;
}

sub ReadGlob {
  my $glob = shift;
  (my $path, my $base, my $ext) = SplitFileName($glob);
  $glob = "$base$ext";
  $glob =~ s/\./\\\./g; # Escape '.'
  $glob =~ s/\*/\.\*/g; # '*' -> '.*'
  $glob =~ s/\?/\./g;   # '?' -> '.'
  my @entries;
  foreach my $entry (@{ReadDir($path)}) {
    if ($entry =~ /$glob/) {
      push (@entries, "$path$entry");
    }
  }
  return \@entries;
}

sub ReadDirDescendingDateOrder {
  my $dir = shift;
  my $unsortedList = ReadDir($dir);
  my %mtimeHash;
  foreach my $entry (@$unsortedList) {
    my $mTime = FileModifiedTime("$dir\\$entry");
    while (exists $mtimeHash{$mTime}) {
      ++$mTime;
    }
    $mtimeHash{$mTime} = $entry;
  }
  my @dir;
  foreach my $key (sort { $b <=> $a } keys %mtimeHash) {
    push (@dir, $mtimeHash{$key});
  }
  return \@dir;
}

sub SignificantDir {
  my $dir = shift;
  my $significantSubDirs = FindSignificantSubDirs($dir);
  my $commonDir = CommonDir($significantSubDirs);
  return $commonDir;
}


# For a given directory, find which sub-directories contain files (rather than just other sub-directories).
sub FindSignificantSubDirs {
  my $dir = shift;
  my $dirContents = ReadDir($dir);
  my @files;
  my @dirs;
  foreach my $thisEntry (@$dirContents) {
    if (-f "$dir\\$thisEntry") {
      push (@files, "$dir\\$thisEntry");
    }
    elsif (-d "$dir\\$thisEntry") {
      push (@dirs, "$dir\\$thisEntry");
    }
  }
  if (scalar @files > 0) {
    # This directory contains some files, so it is significant.
    return [$dir];
  }
  elsif (scalar @dirs > 0) {
    # Only sub-directories in this directory, so recurse.
    my @significantSubDirs;
    foreach my $thisDir (@dirs) {
      push (@significantSubDirs, @{FindSignificantSubDirs($thisDir)});
    }
    return \@significantSubDirs;
  }
  else {
    # Nothing of interest;
    return [];
  }
}

sub CrossCheckDirs {
  my $dir1 = shift;
  my $dir2 = shift;
  my $matched = CrossCheckDirsOneWay($dir1, $dir2);
  if ($matched) {
    $matched = CrossCheckDirsOneWay($dir2, $dir1);
  }
  return $matched;
}

sub CrossCheckDirsOneWay {
  my $dir1 = shift;
  my $dir2 = shift;

  my $matched = 1;
  opendir(DIR1, $dir1) or die "Error: Couldn't open directory $dir1: $!\n";
  while (defined(my $dir1File = readdir(DIR1))) {
    next if ($dir1File eq '.' or $dir1File eq '..');
    $dir1File = "$dir1\\$dir1File";
    (my $dir1MTime, my $dir1Size) = Utils::FileModifiedTimeAndSize($dir1File);
    (undef, my $base, my $extension) = Utils::SplitFileName($dir1File);
    my $dir2File = "$dir2\\$base$extension";
    if (-e $dir2File) {
      (my $dir2MTime, my $dir2Size) = Utils::FileModifiedTimeAndSize($dir2File);
      unless ($dir2MTime == $dir1MTime and $dir2Size == $dir1Size) {
	print "\"$dir1File\" does not match modified time and size of \"$dir2File\"\n";
	$matched = 0;
      }
    }
    else {
      print "\"$dir2File\" not found\n";
      $matched = 0;
    }
  }
  closedir(DIR1);

  return $matched;
}

sub ZipSourceList {
  my $zipName = shift;
  my $list = shift;
  my $verbose = shift;
  my $relativeTo = shift;
  my $iniData = shift;

  if (scalar(@$list) == 0) {
    if ($verbose) { print "No files to put into $zipName...\n"; }
    return;
  }

  my $dirName = dirname($zipName);
  unless (-d $dirName) {
    MakeDir($dirName) || die "ERROR: Unable to create directory.";
  }

  if ($verbose) { print "Creating $zipName...\n"; }

  my $zip = Archive::Zip->new() or die "ERROR: Unable to create new zip.\n";
  
  my $processedDirs = {};

  foreach my $file (@$list) {
    my $fileToZip = $file;
    $file = "$relativeTo"."$file";

    if(-f $file) {
	  # We need to add distribution policy files for each directory
	  my $dirname = dirname($file);
	  
	  if (!exists $processedDirs->{$dirname}) {
		if (-e File::Spec->catdir($dirname, 'distribution.policy')) {
		  push @$list, Utils::RemoveSourceRoot(File::Spec->catdir($dirname, 'distribution.policy'));
		  $processedDirs->{$dirname} = 1;
		}
	  }
	  
      if($iniData->HasMappings()){
        $fileToZip = $iniData->PerformReverseMapOnFileName($file);
        $fileToZip = Utils::RemoveSourceRoot($fileToZip);
      }
      my $member = $zip->addFile($file, $fileToZip);
      if (!defined $member) {
        die "ERROR: Cannot add file '$file' to new zip.\n";
      }
      $member->fileAttributeFormat(FA_MSDOS);
      my $attr = 0;
      Win32::File::GetAttributes($file, $attr);
      $member->{'externalFileAttributes'} |= $attr; # preserve win32 attrs
    }
    elsif(-e $file){}
    else {
      die "ERROR: $file does not exist, so can not add to $zipName.\n";
    }
  }

  # Warning message appears when an error code (which is a non zero) is returned.

  my $returnVal = $zip->writeToFileNamed($zipName);

  if ($returnVal) {
    die "Error: Failed to write ZIP file '$zipName'\n";
  }
}

sub ZipList {
  my $zipName = shift;
  my $list = shift;
  my $verbose = shift;
  my $noCompress = shift;
  my $relativeTo = shift;

  if (scalar(@$list) == 0) {
    if ($verbose) { print "No files to put into $zipName...\n"; }
    return;
  }

  my $dirName = dirname($zipName);
  unless (-e $dirName) {
    MakeDir($dirName);
  }

  if ($verbose) { print "Creating $zipName...\n"; }

  my $cwd = Cwd::cwd();
  if ($relativeTo) {
    chdir($relativeTo) or die "Error: Couldn't change working directory to \"$relativeTo\": $!\n";
  }

  my @opts = ('-@');;
  if ($verbose == 0) {
    push @opts, '-qq';
  }
  elsif ($verbose == 1) {
    push @opts, '-q';
  }
  elsif ($verbose > 1) {
    push @opts, '-v';
  }
  if ($noCompress) {
    push @opts, '-0';
  }
  
  my $missing = 0;
  my $retval;
  my $count = 0;
  do{
     open(ZIP, "| \"$FindBin::Bin\\zip\" @opts $zipName") or die "Error: Couldn't execute _zip.exe - $!\n";

     foreach my $file (@$list) {
       unless (-e $file) {
         $missing = $file;
         last;
       }
       $file =~ s/\[/\[\[\]/g;
       print ZIP "$file\n";
     }
     close(ZIP);
     
     $count ++;
     $retval = $? >> 8;
     if (!$missing && $retval > 1){
       print "Warning: Zipping failed with error code $retval for the $count times.\n";
     }
     
  }while(!$missing && $retval > 1 && $count < 10);
  
  if ($relativeTo) {
    chdir($cwd) or die "Error: Couldn't change working directory back to \"$cwd\": $!\n";
  }

  if ($missing) {
    die "Error: \"" . Utils::ConcatenateDirNames($relativeTo, $missing) . "\" does not exist\n";
  }

  die "Zipping failed with error code $retval\n" if $retval > 1; # 1 is warnings only
}

# So EnvDb::UnpackBinaries can be called from the test suite, use %INC to find path instead of FindBin::Bin
sub UnzipPath {
    my $unzippath;
    my $envdbpath = $INC{'EnvDb.pm'};
    if(defined $envdbpath) {
	# find the unzip binary
	$envdbpath =~ s/\\/\//g;
	$envdbpath =~ s/\/[^\/]+$//;
	$unzippath .= $envdbpath;
    } else {
	$unzippath .= $FindBin::Bin;
    }
    $unzippath .= "\\unzip";
    $unzippath = "\"$unzippath\"";

    return $unzippath;
}

sub UnzipSource {
  my $zipName = shift;
  my $destinationPath = shift;
  my $verbose = shift;
  my $overwrite = shift;
  my $iniData = shift;
  my $toValidate = shift;
  my $comp = shift;
  
  unless(defined $overwrite) {
    $overwrite = 0;
  }

  if($verbose) {
    print "Unpacking ";
    if($overwrite) {
      print "[in overwrite mode] ";
    }
    print "$zipName...\n";
  }

  my $catInArchive;
  my $changeInCat = 0;
  my $fileDirBuffer;

  # Sets $catInArchive to the category found on the source zip.
  if($toValidate==1 && $zipName =~ /source(.*).zip/){
    $catInArchive = $1;
  }

  my $zip = Archive::Zip->new($zipName);
  my @members = $zip->members();

  # Only print warning message if validation is not being performed, destination path is \\ and verbose is set.

  if($toValidate==0 && $destinationPath ne "\\" && $verbose) {
    print "Warning: Ignoring all mappings defined since either source path or SRCROOT is set as $destinationPath.\n";
  }

  foreach my $member (@members) {

    my $fileName = $member->fileName();

    $fileName =~ s/\//\\/g;

    if($fileName !~ /^\\/) {
      $fileName = "\\$fileName";
    }

    $iniData->CheckFileNameForMappingClash($fileName);

    my $newFileName;

    # PerfromMapOnFileName is only used for an validation and if the destintionPath is \\.

    if($toValidate==1 || $destinationPath eq "\\") {
      $newFileName = $iniData->PerformMapOnFileName($fileName);
    }
    else {
      $newFileName = $fileName;
    }

    # Check if the category has changed. Only occurs for validation.
    if(defined $catInArchive && -e $newFileName && $toValidate==1) {
      my $fileDir;
      my $classifySourceFlag = 1; # Classify source using function ClassifySourceFile only if set as 1 and not when set as 0;

      if(defined $fileDirBuffer) {
        ($fileDir) = SplitFileName($newFileName);

        if($fileDirBuffer =~ /^\Q$fileDir\E$/i){
          $classifySourceFlag = 0;
        }
      }

      if($classifySourceFlag){
        my ($catInEnv, $errors) = ClassifyPath($iniData, $newFileName, 0, 0, $comp); # verbose = 0 and logErrors = 0
        if($catInArchive !~ /$catInEnv/i){
          $changeInCat = 1;
        }
        ($fileDirBuffer) = SplitFileName($newFileName);
      }
    }
    ExtractFile($destinationPath, $newFileName, $member, $toValidate, $overwrite, $verbose);
  }

  return $changeInCat;
}


sub ExtractFile {
  my $destinationPath = shift;
  my $newFileName = shift;
  my $member = shift;
  my $toValidate = shift;
  my $overwrite = shift;
  my $verbose = shift;
  my $unzipRetVal = shift; # The return value from unzip if it has already been tried
  my $extractFlag = 0;
  
  my $attr;

  # If the file is a distribution.policy file then set the overwrite flag to true
  if ($newFileName =~ /distribution\.policy/i) {
	$overwrite = 1;
  }

  # If extracting file for validation or destination path is not equal to \\ unzip file to $destinationPath.

  if($toValidate==1 || $destinationPath ne "\\") {
    $newFileName = File::Spec->catfile($destinationPath, $newFileName);
  }

  CheckPathLength($newFileName);

  # If the file exists need to check if file is to be overwritten.

  if(-f $newFileName) {
    if($overwrite) {
      if((Win32::File::GetAttributes($newFileName, $attr)) && ($attr & HIDDEN)){
      	Win32::File::SetAttributes($newFileName, ARCHIVE|NORMAL) || die "ERROR: Unable to overwrite the hidden file $newFileName: $!";
	  }
	  elsif(!-w $newFileName){
        chmod(0777,$newFileName) || die "ERROR: Unable to overwrite the read-only file $newFileName: $!";
      }
      $extractFlag = 1;
    }
    else {
      if($verbose) {
        print "Ignoring the file $newFileName, as this is already present.\n";
      }
    }
  }
  else{
    $extractFlag = 1;
  }

  if($extractFlag){
    {
      #DEF122018
      # Invalid paths will cause Archive::Zip to give an error.  We capture the error and re-format it.
      my @warnings;
      local $SIG{__WARN__} = sub {
        push @warnings, $!;
      };
      
      eval { mkpath(dirname($newFileName)) };
  
      if (@warnings) {
        die "Error: Unable to make the directory \"$newFileName\": " . (join "\n", @warnings) . "\n";
      }
    }

    # A non-zero is returned if there is a problem with extractToFileNamed().
    if($member->extractToFileNamed($newFileName)) {
      warn "ERROR: Failed to extract $newFileName.\n";
      CheckUnzipError($unzipRetVal);
      die;
    }
    utime($member->lastModTime(), $member->lastModTime(), $newFileName);
    my $newattr = $member->externalFileAttributes() & 0xFFFF;
    Win32::File::SetAttributes($newFileName, $newattr); # reapply win32 attrs
  }
}

sub Unzip {
  my $zipName = shift;
  my $destinationPath = shift;
  my $verbose = shift;
  my $overwrite = shift || '';
  
  $overwrite = '-o' if $overwrite eq '1'; # Some callers to this method may send a boolean value rather then an unzip option
  
  if ($verbose) {
    print "Unpacking ";
    if ($overwrite) {
      print "[in overwrite mode] ";
    }
    print "$zipName...\n";
  }

  my $v;
  if ($verbose == 0) {
    $v = "-qq";
  }
  elsif ($verbose == 1) {
    $v = "-q";
  }
  if ($verbose > 1) {
    $v = "";
  }

  # Here we check that the files in the zip file are not so long they can not be unpacked
  my $zip = Archive::Zip->new($zipName);
  my @members = $zip->members();

  foreach my $member (@members) {
    my $fileName = File::Spec->catdir('\.', $destinationPath, $member->fileName());
    CheckPathLength($fileName);
  }

  MakeDir($destinationPath);
  
  # prepare command
  my $cmd = "unzip $overwrite $v $zipName -d $destinationPath 2>&1";
  
  # run $cmd, fetching io handles for it
  my $pid = open2(\*IN, \*OUT, $cmd);
  
  # one character per read
  local $/ = \1;
  
  # command output line buffer
  my $line = '';
  
  while (<IN>) {
    # accumulate line data
    $line .= $_;
    
    # look for expected output
    if ($line =~ /^(?:(replace).*\[r\]ename|new name): $/) {
      # dump line buffer so user can read prompt
      print $line and $line = '';
      
      # read whole lines for user response
      local $/ = "\n";
      
      # read user's response
      chomp(my $response = <STDIN>);
      
      if (defined $1) { # matched "replace"
	# set overwrite mode if the user chooses to replace [A]ll
	$overwrite = '-o' if $response =~ /^A/;
	
	# set no-overwrite mode if the user chooses to replace [N]one
	$overwrite = '-n' if $response =~ /^N/;
      }
      
      # convey response to the command
      print OUT "$response\n";
    }
    
    # dump line buffer at EOL
    print $line and $line = '' if $line =~ /\n$/;
  }
  
  close (OUT);
  close (IN);
  
  waitpid($pid,0);

  CheckUnzipError($?);  
  
  return $overwrite;
}

sub CheckUnzipError {
  my $retval = shift;
  $retval = $retval >> 8;
  # Error numbers found in unzip (Info-ZIP) source code: there doesn't
  # seem to be a manual. Common with return values from PKZIP so
  # unlikely to change
  # Error 1 is just a warning, so we only care about those > 1
  die "Unzip reported an out-of-memory error ($retval)\n" if ($retval>3 && $retval<9);
  die "Unzip reported a problem with the zip file ($retval)\n" if ($retval>1 && $retval<4);
  die "Unzip reported disk full (though this might mean it's trying to overwrite files in use) ($retval)\n" if ($retval==50);
  die "Unzip reported error code ($retval)" if ($retval>1 && $retval<52);
  warn "Warning: Unzip returned an unexpected error code ($retval)\n" if ($retval >51)
}

sub UnzipSingleFile {
  my $zipName = shift;
  my $file = shift;
  my $destinationPath = shift;
  my $verbose = shift;
  my $overwrite = shift;
  my $comp = shift;
  
  unless (defined $overwrite) {
    $overwrite = 0;
  }

  if ($verbose) {
    print "Unpacking ";
    if ($overwrite) {
      print "[in overwrite mode] ";
    }
    print "\"$file\" from \"$zipName\"...\n";
  }


  my $v;
  if ($verbose == 0) {
    $v = "-qq";
  }
  elsif ($verbose == 1) {
    $v = "-q";
  }
  if ($verbose > 1) {
    $v = "";
  }

  my $o = "";
  if ($overwrite) {
    $o = "-o";
  }

  MakeDir($destinationPath);
  my $retval = system(UnzipPath()." $o $v \"$zipName\" \"$file\" -d \"$destinationPath\"");

  unless (-e ConcatenateDirNames($destinationPath, $file)) {
    #Fallback to using archive::zip
    print "Unable to extract $file using unzip. Trying alternative extraction method...\n";
    
    my $zip = GetArchiveZipObject($zipName, $comp);

    my $fileWithForwardSlashes = $file;
    $fileWithForwardSlashes =~ s/\\/\//g; # Archive::Zip stores file names with forward slashes
  
    my $member = $zip->memberNamed($fileWithForwardSlashes);
    
    if (!defined $member) {
      # Archive::Zip is also case-sensitive.  If it doesn't find the required file we compile the filename into
      # a case insensitive regex and try again.  This takes longer than just calling memberNamed.
      my $fileNameRegEx = qr/$fileWithForwardSlashes/i;
      ($member) = $zip->membersMatching($fileNameRegEx);
      
      # If it still can't find the file then it doesn't exist in the zip file
      if (!defined $member) {
        warn "Unable to find $file in $zipName\n";
        CheckUnzipError($retval);
        die;
      }
    }
  
    ExtractFile($destinationPath, $file, $member, 0, $overwrite, $verbose, $retval);
    print "Successfully extracted $file\n";
  }
}

sub ListZip {
  my $zipName = shift;
  my @list;

  my $zipper = Archive::Zip->new();
  unless ($zipper->read($zipName) == AZ_OK) {
    die "Error: problem reading \"$zipName\"\n";
  }

  my @members = $zipper->members();
  foreach my $thisMember (@members) {
    my $file = $thisMember->fileName();
    TidyFileName(\$file);
    unless ($file =~ /^\\/) {
      $file = "\\$file";
    }
    push (@list, $file);
  }

  return \@list;
}

sub CheckZipFileContentsNotPresent {
  my $zipName = shift;
  my $where = shift;
  my $iniData = shift;
  my $checkFailed = 0;
  foreach my $thisFile (@{ListZip($zipName)}) {
    if ($thisFile =~ /\\$/) {
      next;
    }
    my $fullName = ConcatenateDirNames($where, $thisFile);

    if($iniData->HasMappings()){
      $fullName = $iniData->PerformMapOnFileName($fullName);
    }

	if ($fullName =~ /distribution\.policy$/i) {
	  return $checkFailed;
	}

    if (-e $fullName) {
      print "Error: \"$fullName\" would be overwritten by unpacking \"$zipName\"\n";
      $checkFailed = 1;
    }
  }
  return $checkFailed;
}

sub SignificantZipDir {
  my $zipName = shift;

  my $zipper = Archive::Zip->new();
  unless ($zipper->read($zipName) == AZ_OK) {
    die "Error: problem reading \"$zipName\"\n";
  }

  my %dirs;
  my @members = $zipper->members();
  foreach my $thisMember (@members) {
    my $file = $thisMember->fileName();
    my $dir = lc(dirname($file));
    TidyFileName(\$dir);
    unless (exists $dirs{$dir}) {
      $dirs{$dir} = 1;
    }
  }

  my @dirs = sort keys %dirs;
  return CommonDir(\@dirs);
}

# Given an array of directories, find the common directory they share.
sub CommonDir {
  my $dirs = shift;
  my $disectedDirs = DisectDirs($dirs);
  my $numDirs = scalar @$dirs;
  if ($numDirs == 1) {
	# if there is only one signifigant directory then this has to be
	# the common one so return it.
	return $dirs->[0];
  }
  my $commonDir = '';
  my $dirLevel = 0;
  while (1) {
    my $toMatch;
    my $allMatch = 0;
    for (my $ii = 0; $ii < $numDirs; ++$ii, ++$allMatch) {
      if ($dirLevel >= scalar @{$disectedDirs->[$ii]}) {
        $allMatch = 0;
        last;
      }
      if (not $toMatch) {
        $toMatch = $disectedDirs->[0][$dirLevel];
      }
      elsif ($disectedDirs->[$ii][$dirLevel] ne $toMatch) {
        $allMatch = 0;
        last;
      }
    }
    if ($allMatch) {
      if ($toMatch =~ /^[a-zA-Z]:/) {
        $commonDir .= $toMatch;
      }
      else {
        $commonDir .= "\\$toMatch";
      }
      ++$dirLevel;
    }
    else {
      last;
    }
  }
  return $commonDir;
}

sub DisectDirs {
  my $dirs = shift;
  my $disectedDirs;
  my $numDirs = scalar @$dirs;
  for (my $ii = 0; $ii < $numDirs; ++$ii) {
    my $thisDir = $dirs->[$ii];
    $thisDir =~ s/^\\//; # Remove leading backslash to avoid first array entry being empty.
    my @thisDisectedDir = split(/\\/, $thisDir);
    push (@$disectedDirs, \@thisDisectedDir);
  }
  return $disectedDirs;
}

sub CheckExists {
  my $file = shift;
  unless (-e $file) {
    die "Error: $file does not exist\n";
  }
}

sub CheckIsFile {
  my $file = shift;
  unless (-f $file) {
    die "Error: $file is not a file\n";
  }
}

sub CurrentDriveLetter {
  my $drive = Win32::GetCwd();
  $drive =~ s/^(\D:).*/$1/;
  return $drive;
}

sub InitialiseTempDir {
  my $iniData = shift;
  
  if (defined $iniData->TempDir) {
    $tempDir = mkdtemp($iniData->TempDir().'\_XXXX');
  }
  else {
    my $fstempdir = File::Spec->tmpdir;
    $fstempdir =~ s/[\\\/]$//;
    $tempDir = mkdtemp($fstempdir.'\_XXXX');
  }
  
  die "Error: Problem creating temporary directory \"$tempDir\": $!\n" if (!$tempDir);
}

sub RemoveTempDir {
  die unless $tempDir;
  rmtree $tempDir or die "Error: Problem emptying temporary directory \"$tempDir\": $!\n";
  undef $tempDir;
}

sub TempDir {
  die unless $tempDir;
  return $tempDir;
}

sub ToolsVersion {
  my $relPath = shift;
  unless (defined $relPath) {
    $relPath = '';
  }
  my $file = "$FindBin::Bin/$relPath" . 'version.txt';
  open (VER, $file) or die "Error: Couldn't open \"$file\": $!\n";
  my $ver = <VER>;
  chomp $ver;
  close (VER);
  return $ver;
}

sub QueryPassword {
  unless ($console) {
    $console = Win32::Console->new(STD_INPUT_HANDLE);
  }
  my $origMode = $console->Mode();
  $console->Mode(ENABLE_PROCESSED_INPUT);
  my $pw = '';
  my $notFinished = 1;
  while ($notFinished) {
    my $char = $console->InputChar();
    if ($char and $char eq "\r") {
      print "\n";
      $notFinished = 0;
    }
    elsif ($char and $char eq "\b") {
      if ($pw) {
	$pw =~ s/.$//;
	print "\b \b";
      }
    }
    else {
      $pw .= $char;
      print '*';
    }
  }
  $console->Mode($origMode);
  return $pw;
}

sub PrintDeathMessage {
  my $exitCode = shift;
  my $msg = shift;
  my $relPath = shift;
  
  my $ver = ToolsVersion($relPath);
  print "$msg\nLPD Release Tools version $ver\n";
  exit $exitCode;
}

sub PrintTable {
  my $data = shift;
  my $doHeading = shift;

  require IniData;
  my $iniData = New IniData;
  my $tf = $iniData->TableFormatter;
  $tf->PrintTable($data, $doHeading);
}

sub QueryUnsupportedTool {
  my $warning = shift; # optional
  my $reallyrun = shift; # optional - value of a '-f' (force) flag or similar
  return if $reallyrun;

  $warning ||= <<GUILTY;
Warning: this tool is unsupported and experimental. You may use it, but there
may be defects. Use at your own risk, and if you find a problem, please report
it to us. Do you want to continue? (y/n)
GUILTY

  print $warning."\n";
  my $resp = <STDIN>;
  chomp $resp;
  die "Cancelled. You typed \"$resp\".\n" unless $resp =~ m/^y/i;
}

sub CompareVers($$) {
  my ($version1, $version2) = @_;

  # New format or old format?
  my $style1 = (($version1 =~ /^(\d+\.\d+)/) and ($1 >= 2.8));
  my $style2 = (($version2 =~ /^(\d+\.\d+)/) and ($1 >= 2.8));

  # Validate version strings
  if ($style1 == 1) {
    $version1 = ValidateNewFormatVersion($version1);
  } else {
    ValidateOldFormatVersion($version1);
  }

  if ($style2 == 1) {
    $version2 = ValidateNewFormatVersion($version2);
  } else {
    ValidateOldFormatVersion($version2);
  }

  # Compare version strings
  if ($style1 != $style2) {
    return $style1-$style2; # New format always beats old format
  } else  {
    return CompareVerFragment($version1, $version2);
  }
}

sub ValidateOldFormatVersion($) {
  my ($version) = @_;

  if (($version !~ /^\d[\.\d]*$/) or ($version !~ /\d$/)) {
    die "Error: $version is not a valid version number\n";
  }
  
  return $version;
}

sub ValidateNewFormatVersion($) {
  my ($version) = @_;
  
  my $ver; 
  if ($version !~ /^(\d+\.\d+)\.(.+)$/) {
    die "Error: $version is not a valid version number; patch number must be given\n";
  } else {
    $ver = $1;
    my $patch = $2;
    
    if (($patch =~ /^\d*$/) and ($patch > 9999)) {
      die "Error: Version number $version has an invalid patch number\n";
      
    } elsif ($patch =~ /\./) {
      die "Error: Version number $version has an invalid patch number\n";
      
    }
  }
  
  return $ver; # Return significant version number only
}

sub CompareVerFragment($$) {
  # 1.xxx = 01.xxx, while .1.xxx = .10.xxx
  my ($frag1, $frag2) = @_;

  my $isfrag1 = defined($frag1) ? 1 : 0;
  my $isfrag2 = defined($frag2) ? 1 : 0;

  my $compare;

  if ($isfrag1 and $isfrag2) {
    my ($rest1, $rest2);

    $frag1=~s/^(\.?\d+)(\..*)$/$1/ and $rest1=$2; # If pattern fails, $rest1 is undef
    $frag2=~s/^(\.?\d+)(\..*)$/$1/ and $rest2=$2;

    $compare = $frag1-$frag2; # Numeric comparison: .1=.10 but .1>.01

    if ($compare == 0) {
      $compare = &CompareVerFragment($rest1, $rest2);
    }
  }
  else {
    $compare = $isfrag1-$isfrag2;
  }
  return $compare;
}

sub ClassifyPath {
  my $iniData = shift;
  my $path = shift;
  if (!WithinSourceRoot($path)){
   $path = Utils::PrependSourceRoot($path);
  }
  my $verbose = shift;
  my $logDistributionPolicyErrors = shift; # 0 = no, 1 = yes
  my $component = shift;

  if ($verbose) {
    print "Finding category of source file $path...\n";
  }
  
  Utils::TidyFileName(\$path);
  
  my $cat = '';
  my $errors = [];
  
  my $symbianIPR = Symbian::IPR->instance($iniData->UseDistributionPolicyFilesFirst(), $iniData->DisallowUnclassifiedSource(), 'MRPDATA', $verbose, $logDistributionPolicyErrors);
  $symbianIPR->PrepareInformationForComponent($component);
  eval {($cat, $errors) = $symbianIPR->Category($path)};
  
  if ($@) {
    print $@;
  }

  if (uc $cat eq "X" and $iniData->DisallowUnclassifiedSource()) {
    die "Error: \"$path\" contains unclassified source code\n";
  }

  if ($verbose) {
    print "ClassifySource for $path: returning cat $cat";
    if (scalar (@$errors) > 0) {
      print " and errors @$errors";
    }
    print "\n";
  }
  
  return uc($cat), $errors; # copy of $errors
}

sub ClassifyDir {
  return ClassifyPath(IniData->New(), @_);  
}

sub ClassifySourceFile {
  return ClassifyPath(@_);
}

sub CheckForUnicodeCharacters {
  my $filename = shift;
  
  # Unicode characters in filenames are converted to ?'s 
  $filename =~ /\?/ ? return 1 : return 0; 
}

sub CheckIllegalVolume {
  my $iniData = shift;
  
  my ($volume) = File::Spec->splitpath(cwd());
  $volume =~ s/://; # remove any : from $volume
  
  # Check that the environment is not on an illegal volume - INC105548
  if (grep /$volume/i, $iniData->IllegalWorkspaceVolumes()) {
    die "Error: Development is not permitted on an excluded volume: " . (join ',', $iniData->IllegalWorkspaceVolumes()) . "\n";
  }
}
sub ListAllFiles {
  my $directory = shift;
  my $list = shift;
  find(sub { push @{$list}, $File::Find::name if (! -d);}, $directory);
}

sub CheckPathLength {
  my $path = shift;

  if (length($path) > MAX_OS_PATH_LENGTH) {
    my $extraMessage = '';
    
    if ($tempDir && $path =~ /^\Q$tempDir\E/) {
      $extraMessage = "\nThe folder you are extracting to is under your temp folder \"$tempDir\". Try reducing the size of your temp folder by using the temp_dir <folder> keyword in your reltools.ini file.";
    }
    
    die "Error: The path \"$path\" contains too many characters and can not be extracted.$extraMessage\n"; 
  }  
}

sub GetArchiveZipObject {
  my $zipName = shift;
  my $comp = lc(shift);
  
  my $zip;
  
  if ($comp) { # If $comp is defined then we need to cache Archive::Zip objects by component
    if (exists $zipFileCache{$comp}) {
      if (defined $zipFileCache{$comp}->{$zipName}) {
        $zip = $zipFileCache{$comp}->{$zipName};
      }
      else {
	$zip = Archive::Zip->new($zipName);
	$zipFileCache{$comp}->{$zipName} = $zip;
      }
    }
    else { # New component
      %zipFileCache = (); # Delete the cache as it is no longer required
      $zip = Archive::Zip->new($zipName);
      $zipFileCache{$comp}->{$zipName} = $zip;
    }
  }
  else {
    $zip = Archive::Zip->new($zipName);
  }
  
  return $zip;
}

sub CheckDirectoryName {
  my $dirName = shift;
  
  my @dirParts = split /[\\\/]/, $dirName;
  
  foreach my $dirPart (@dirParts) {
    next if ($dirPart =~ /^\w:$/ && $dirName =~ /^$dirPart/);
    
    if ($dirPart =~ /[:\?\*\"\<\>\|]/) {
      die "Error: The directory \"$dirName\" can not contain the characters ? * : \" < > or |\n";
    }
  }
}


1;

__END__

=head1 NAME

Utils.pm - General utility functions.

=head1 INTERFACE

=head2 StripWhiteSpace

Expects a reference to a string. Strips white space off either end of the string.

=head2 TidyFileName

Expects a reference to a string. Changes any forward slashes to back slashes. Also changes "\.\" and "\\" to "\" (preserving the "\\" at the start of UNC paths). This is necessary to allow effective comparison of file names.

=head2 AbsoluteFileName

Expects a reference to a string containing a file name. Modifies the string to contain the corresponding absolute path version of the file name (without the drive letter). For example, the string ".\test.txt" would generate a return value of "\mydir\test.txt", assuming the current directory is "\mydir".

=head2 AbsolutePath

Expects a reference to a string containing a path. Modifies the string to contain the corresponding absolute path (without the drive letter).

=head2 FileModifiedTime

Expects a filename, returns C<stat>'s last modified time. If there's a problem getting the stats for the file, an C<mtime> of zero is returned.

=head2 FileSize

Expects a filename, returns the file's size.

=head2 FileModifiedTimeAndSize

Expects a filename. Returns a list containing the file's last modified time and size.

=head2 SetFileReadOnly

Expects to be passed a file name. Sets the file's read only flag.

=head2 SetFileWritable

Expects to be passed a file name. Clear the file's read only flag.

=head2 SplitFileName

Expects to be passed a file name. Splits this into path, base and extension variables (returned as a list in that order). For example the file name C<\mypath\mybase.myextension> would be split into C<mypath>, C<mybase> and C<.myextension>. An empty string will be returned for segments that don't exist.

=head2 SplitQuotedString

Expects to be passed a string. Splits this string on whitespace, ignoring whitespace between quote (C<">) characters. Returns an array containing the split values.

=head2 ConcatenateDirNames

Expects to be passed a pair of directory names. Returns a string that contains the two directory names joined together. Ensures that there is one (and only one) back slash character between the two directory names.

=head2 MakeDir

Expects to be passed a directory name. Makes all the directories specified. Can copy with UNC and DOS style drive letter paths.

=head2 ReadDir

Expects to be passed a directory name. Returns an array of file names found within the specified directory.

=head2 ReadGlob

Expects to be passed a scalar containing a file name. The file name path may relative or absolute. The file specification may contains C<*> and/or C<?> characters. Returns a reference to an array of file names that match the file specification.

=head2 SignificantDir

Expects to be passed a directory name. Returns the name of the deepest sub-directory that contains all files.

=head2 CrossCheckDirs

Expects to be passed a pair of directory names. Checks that the contents of the directories are identical as regards file names, their last modified times and their size. Returns false if any checks fail, otherwise true.

=head2 ZipList

Expects to be passed a zip filename and a reference to a list of file to be put into the zip file. The zip filename may contain a full path - missing directories will be created if necessary.

=head2 Unzip

Expects to be passed a zip filename, a destination path, a verbosity level, and optionally a flag indicating whether exisitng files should be overwritten or not. Unpacks the named zip file in the specified directory.

=head2 UnzipSingleFile

Expects to be passed a zip filename, a filename to unpack, a destination path, a verbosity level, and optionally a flag indicating whether existing files should be overwritten or not. Unpacks only the specified file from the zip file into the specified directory.

=head2 ListZip

Expects to be passed a zip filename. Returns a reference to a list containing the names of the files contained in the zip file.

=head2 CheckZipFileContentsNotPresent

Expects to be passed a zip filename and a destination path. Prints errors to C<STDOUT> for each file contained within the zip that would overwrite an existing file in the destination path. Returns true if any errors were printed, false otherwise.

=head2 SignificantZipDir

Expects to be passed a zip filename. Returns the name of the deepest sub-directory that contains all the files within the zip.

=head2 CheckExists

Expects to be passed a filename. Dies if the file is not present.

=head2 CheckIsFile

Expects to be passed a filename. Dies if the filename isn't a file.

=head2 CurrentDriveLetter

Returns a string containing the current drive letter and a colon.

=head2 InitialiseTempDir

Creates an empty temporary directory.

=head2 RemoveTempDir

Removes the temporary directory (recursively removing any other directories contained within it).

=head2 ToolsVersion

Returns the current version of the release tools. This is read from the file F<version.txt> in the directory the release tools are running from.

=head2 QueryPassword

Displays the user's input as '*' characters. Returns the password.

=head2 PrintDeathMessage

Expects to be passed a message. Dies with the message plus details of the current tools version.

=head2 PrintTable

Expects to be passed a reference to a two dimentional array (a reference to an array (the rows) of referrences to arrays (the columns)). May optionally be passed a flag requesting that a line break be put between the first and second rows (useful to emphasise headings). Prints the data in a left justified table.

=head2 TextTimeToEpochSeconds

Convert a human readable time/date string in the format generated by C<scalar localtime> into the equivalent number of epoch seconds.

=head2 TextDateToEpochSeconds

Convert a date string in the format C<dd/mm/yyyy> into the equivalent number of epoc seconds.

=head2 QueryUnsupportedTool

Warns the user that the tool is unsupported, and asks whether they wish to continue. Takes two parameters, both optional. The first is the text to display (instead of a default). It must finish with an instruction asking the user to type y/n. The second is an optional flag for a 'force' parameter.

=head2 CompareVers

Takes two version numbers in the form of a dot separated list of numbers (e.g 2.05.502) and compares them, returning 0 if they are equivalent, more than 0 if the first version given is greater or less than 0 if the first version is lesser. Dies if versions are not of the required format.

=head2 CompareVerFragment

The main code behind C<CompareVers()>. This is not meant to be called directly because it assumes version numbers only consist of numbers and dots.

=head2 ZipSourceList

Expects to be passed a zip filename and a reference to a list of source files to be put into the zip file.

=head2 UnzipSource

Expects to be passed a source zip filename, a destination path, a verbosity level, a flag indicating whether existing files should be overwritten or not, an inidata and a flag indicating whether this operation is for a validation or not. Unpacks the named source zip file to the specified directory. If for validation, a check for change in category occurs. Returns a change in category flag, when flag is 1 a change in category has been found.

=head2 ExtractFile

Expects to be passed a destination path, a file name, a member and a flag indicating whether existing files should be overwritten or not. Is used to extract a file from a zip file to a specified location.

=head2 ClassifySourceFile

Expects to be passed an iniData, a source filename, a verbosity level, and log error flag. Is used to calculate the category of the source file passed. Returns the category calculated.

=head2 ListAllFiles

Expects to be passed a directory path and an array reference. Lists all files from the directory specified and sub directories into an array reference. Entries in the array contain full path of the file, not just file name.

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
