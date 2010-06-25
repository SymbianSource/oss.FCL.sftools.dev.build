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

package CheckBc;


#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  my $bldInfDir1 = shift;
  my $bldInfDir2 = shift;
  Utils::AbsoluteFileName(\$bldInfDir1);
  Utils::AbsoluteFileName(\$bldInfDir2);
  $self->{verbose} = shift;
  $self->{compName} = shift;
  $self->{additionalHeaders} = shift;
  $self->{additionalIncludePaths} = shift;
  my $ignoreClasses = shift;
  foreach my $thisClass (@$ignoreClasses) {
    $self->{ignoreClasses}->{$thisClass} = 1;
  }
  $self->{ignoreR3Unused} = shift;
  $self->{bldInf1} = BldInf->New($bldInfDir1, $self->{verbose});
  $self->{bldInf2} = BldInf->New($bldInfDir2, $self->{verbose});
  return $self;
}

sub CheckAll {
  my $self = shift;
  my $passed = 1;
  unless ($self->CheckDefFiles()) {
    $passed = 0;
  }
  unless ($self->CheckClassSizes()) {
    $passed = 0;
  }
  unless ($self->CheckVTables()) {
    $passed = 0;
  }
  return $passed;
}

sub CheckDefFiles {
  my $self = shift;
  return $self->{bldInf1}->CheckDefFiles($self->{bldInf2}, $self->{ignoreR3Unused});
}

sub CheckClassSizes {
  my $self = shift;
  my $classSizes1 = $self->GetClassSizes($self->{bldInf1});
  my $classSizes2 = $self->GetClassSizes($self->{bldInf2});
  return $classSizes1->Check($classSizes2);
}

sub CheckVTables {
  my $self = shift;
  my $vtable1 = $self->GetVTable($self->{bldInf1});
  my $vtable2 = $self->GetVTable($self->{bldInf2});
  return $vtable1->Check($vtable2);
}


#
# Private.
#

sub GetClassSizes {
  my $self = shift;
  my $bldInf = shift;
  my $constructorsToCheck = $self->GetConstructorsToCheck($bldInf->ListConstructors());
  my @headers;
  if ($self->{additionalHeaders}) {
    push (@headers, @{$self->{additionalHeaders}});
  }
  foreach my $thisExport (@{$bldInf->ListExports()}) {
    if ($thisExport =~ /\.h$/i) {
      push (@headers, $thisExport);
    }
  }
  my $includes = $bldInf->ListIncludes();
  if ($self->{additionalIncludePaths}) {
    push (@$includes, @{$self->{additionalIncludePaths}});
  }
  return ClassSize->New($constructorsToCheck, \@headers, $includes, $self->{verbose}, $self->{compName}, $bldInf->{dir});
}

sub GetVTable {
  my $self = shift;
  my $bldInf = shift;
  my $constructorsToCheck = $self->GetConstructorsToCheck($bldInf->ListConstructors());
  return VTable->New($bldInf->{dir}, $constructorsToCheck, $self->{verbose});
}

sub GetConstructorsToCheck {
  my $self = shift;
  my $constructors = shift;
  my @constructorsToCheck;
  foreach my $thisConstructor (@$constructors) {
    unless (exists $self->{ignoreClasses}->{$thisConstructor}) {
      push (@constructorsToCheck, $thisConstructor);
    }
  }
  return \@constructorsToCheck;
}


#
# BldInf
#

package BldInf;


#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{dir} = shift;
  $self->{verbose} = shift;
  $self->Parse();
  return $self;
}

sub CheckDefFiles {
  my $self = shift;
  my $other = shift;
  my $ignoreR3Unused = shift;
  my $passed = 1;
  foreach my $thisMmp (keys %{$self->{mmps}}) {
    if (exists $other->{mmps}->{$thisMmp}) {
      unless ($self->{mmps}->{$thisMmp}->CheckDefFile($other->{mmps}->{$thisMmp}, $ignoreR3Unused)) {
	$passed = 0;
      }
    }
    else {
      print "Mmp file \"$thisMmp\" missing for bld.inf \"$other->{dir}\"\n";
      $passed = 0;
    }
  }
  return $passed;
}

sub ListConstructors {
  my $self = shift;
  my @constructors = ();
  foreach my $thisMmp (keys %{$self->{mmps}}) {
    push (@constructors, @{$self->{mmps}->{$thisMmp}->ListConstructors()});
  }
  return \@constructors;
}

sub ListExports {
  my $self = shift;
  if (exists $self->{exports}) {
    return $self->{exports};
  }
  return [];
}

sub ListIncludes {
  my $self = shift;
  my %includes = ();
  foreach my $thisMmp (keys %{$self->{mmps}}) {
    foreach my $thisInclude (@{$self->{mmps}->{$thisMmp}->ListIncludes()}) {
      $includes{$thisInclude} = 1;
    }
  }
  my @includes = keys %includes;
  return \@includes;
}


#
# Private.
#

sub Parse {
  my $self = shift;
  if ($self->{verbose}) {  print "Parsing $self->{dir}\\bld.inf...\n"; }
  Utils::PushDir($self->{dir});
  my $fullName = "$self->{dir}\\bld.inf";
  unless (open (BLDINF, "cpp -DARM -DMARM $fullName|")) {
    Utils::PopDir();
    die "Error: Couldn't open \"cpp -DARM -DMARM $fullName\": $!\n";
  }
  my $foundMmps = 0;
  my $foundExports = 0;
  my $doDie = 0;
  my $currentDir = $self->{dir};
  while (my $line = <BLDINF>) {
    if ($line =~ /^# \d+ "(.*)" \d+?/) {
	my $newFile = $1;
	$newFile =~ s/\\\\/\\/g;
	$newFile =~ s/\\$//;
	Utils::AbsoluteFileName(\$newFile);
	($currentDir) = Utils::SplitFileName($newFile);
	next;
      }
    if ($line =~ /^#/ or $line =~ /^\s*$/) {	
	# Ignore lines starting with '#' or those filled with white space.
	next;
      }
    chomp $line;

    if ($line =~ /PRJ_MMPFILES/i) {
      $foundMmps = 1;
      $foundExports = 0;
      next;
    }
    elsif ($line =~ /PRJ_EXPORTS/i) {
      $foundMmps = 0;
      $foundExports = 1;
      next;
    }
    elsif ($line =~ /PRJ_/i) {
      $foundMmps = 0;
      $foundExports = 0;
      next;
    }
    if ($foundMmps) {
      if ($line =~ /makefile\s+(\S+)/i) {
	if ($self->{verbose}) { print "Info: \"makefile $1\" found in \"$self->{dir}\\bld.inf\", ignoring.\n"; }
	next;
      }

      $line =~ /\s*(\S+)/;
      my $mmpName = lc($1);
      if (not $mmpName =~ /\.mmp$/) {
	$mmpName .= '.mmp';
      }
      unless (-e $mmpName) {
	if (-e "$currentDir\\$mmpName") {
	  $mmpName = "$currentDir\\$mmpName";
	}
	elsif (-e "$self->{dir}\\$mmpName") {
	  $mmpName = "$self->{dir}\\$mmpName";
	}
	else {
	  print "Warning: Couldn't find location of \"$mmpName\n";
	  next;
	}
      }
      Utils::AbsoluteFileName(\$mmpName);
      (my $path, my $name, my $ext) = Utils::SplitFileName($mmpName);
      eval {
	$self->{mmps}->{lc("$name$ext")} = Mmp->New($mmpName, $self->{verbose});
      };
      if ($@) {
	$doDie = 1;
	print "$@";
      }
      next;
    }
    elsif ($foundExports) {
      my $thisExport;
      if ($line =~  /^\s*\"([^\"]*)/) {
	$thisExport = $1;
      }
      elsif ($line =~ /\s*(\S+)/) {
	$thisExport = $1;
      }
      else {
	die;
      }
      unless (-e $thisExport) {
	if (-e "$currentDir\\$thisExport") {
	  $thisExport = "$currentDir\\$thisExport";
	}
	elsif (-e "$self->{dir}\\$thisExport") {
	  $thisExport = "$self->{dir}\\$thisExport";
	}
	else {
	  print "Warning: Couldn't find location of \"$thisExport\n";
	  next;
	}
      }
      Utils::AbsoluteFileName(\$thisExport);
      push (@{$self->{exports}}, $thisExport);
    }
  }
  close (BLDINF);
  Utils::PopDir();
  if ($doDie) {
    die "Aborting due to above errors\n";
  }
}


#
# Mmp
#

package Mmp;


#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{name} = shift;
  $self->{verbose} = shift;
  $self->Parse();
  return $self;
}

sub CheckDefFile {
  my $self = shift;
  my $other = shift;
  my $ignoreR3Unused = shift;
  if ($self->{def}) {
    return $self->{def}->Check($other->{def}, $ignoreR3Unused);
  }
  return 1;
}

sub ListConstructors {
  my $self = shift;
  if ($self->{def}) {
    return $self->{def}->ListConstructors();
  }
  return [];
}

sub ListIncludes {
  my $self = shift;
  if (exists $self->{includes}) {
    my @includes = keys %{$self->{includes}};
    return \@includes;
  }
  return [];
}


#
# Private.
#

sub Parse {
  my $self = shift;
  if ($self->{verbose}) {  print "Parsing $self->{name}...\n"; }
  (my $path) = Utils::SplitFileName($self->{name});
  $path =~ s/(.*)\\.*/$1/; # Extract path.
  Utils::PushDir($path);
  unless (open (MMP, "cpp -DARM -DMARM $self->{name}|")) {
    Utils::PopDir();
    die "Error: Couldn't open \"cpp -DARM -DMARM $self->{name}\": $!\n";
  }
  my $noStrictDef = 0;
  my $targetType = '';
  while (my $line = <MMP>) {
    if ($line =~ /^#/ or $line =~ /^\s*$/) {	
	# Ignore lines starting with '#' or those filled with white space.
	next;
      }
    chomp $line;
    if ($line =~ /^\s*targettype\s+(\S*)\s*$/i) {
	$targetType = $1;
    }
    elsif ($line =~ /^\s*deffile\s+(\S*)\s*$/i) {
      die if exists $self->{defFileName};
      $self->{defFileName} = $1;
    }	 
    elsif ($line =~ /nostrictdef/i) {
      $noStrictDef = 1;
    }
    elsif ($line =~ /^\s*userinclude\s+(.+)/i) {
      my @userIncludes = split (/\s+/, $1);
      foreach my $thisUserInclude (@userIncludes) {
	$thisUserInclude =~ s/\+/$ENV{EPOCROOT}epoc32/;
	Utils::AbsoluteFileName(\$thisUserInclude);
	$self->{includes}->{lc($thisUserInclude)} = 1;
      }
    }
    elsif ($line =~ /^\s*systeminclude\s+(.+)/i) {
      my @systemIncludes = split (/\s+/, $1);
      foreach my $thisSystemInclude (@systemIncludes) {
	$thisSystemInclude =~ s/\+/$ENV{EPOCROOT}epoc32/;
	Utils::AbsoluteFileName(\$thisSystemInclude);
	$self->{includes}->{lc($thisSystemInclude)} = 1;
      }
    }
  }
  close (MMP);

  if ($targetType =~ /^(app|ani|ctl|ctpkg|epocexe|exe|exedll|fsy|kdll|kext|klib|ldd|lib|ecomiic|mda|mdl|notifier|opx|pdd|pdl|rdl|var|wlog)$/i) {
    # Don't bother looking for the deffile.
    Utils::PopDir();
    return;
  }
  
  (my $mmpPath, my $mmpBase) = Utils::SplitFileName($self->{name});
  if (exists $self->{defFileName}) {
    (my $path, my $base, my $ext) = Utils::SplitFileName($self->{defFileName});
    if ($base eq '') {
      $base = $mmpBase;
    }
    if ($ext eq '') {
      $ext = '.def';
    }
    if ($path eq '') {
      $path = $mmpPath;
    }
    unless ($noStrictDef) {
      $base .= 'u';
    }
    unless (-e "$path$base$ext") {
      $path = "$path..\\bmarm\\";
    }
    unless (-e "$path$base$ext") {
      $path = $mmpPath . $path;
    }
    $self->{defFileName} = "$path$base$ext";
    Utils::AbsoluteFileName(\$self->{defFileName});
  }
  else {
    # Assume default.
    $self->{defFileName} = $mmpBase;
    unless ($noStrictDef) {	
      $self->{defFileName} .= 'u';
    }
    $self->{defFileName} .= '.def';
    $self->AddDefaultDefFilePath();
  }

  if ($self->{defFileName}) {
    $self->{def} = Def->New($self->{defFileName}, $self->{verbose});
  }

  Utils::PopDir();
}

sub AddDefaultDefFilePath {
  my $self = shift;
  (my $path) = Utils::SplitFileName($self->{name});
  $self->{defFileName} = "$path\\..\\bmarm\\$self->{defFileName}";
  if (-e $self->{defFileName}) {
    Utils::AbsoluteFileName(\$self->{defFileName});
  }
  else {
    print "Warning: Unable to find def file in \"$self->{name}\"\n";
    delete $self->{defFileName};
  }
}


#
# Def
#

package Def;


#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{name} = shift;
  $self->{verbose} = shift;
  $self->Parse();
  $self->DemangleNames();
  return $self;
}

sub Check {
  my $self = shift;
  my $other = shift;
  my $ignoreR3Unused = shift;
  if ($self->{verbose}) { print "Checking DEF file \"$self->{name}\" against \"$other->{name}\"...\n"; }
  my $passed = 1;
  if (exists $self->{data}) {
    for (my $ii = 0; $ii < scalar(@{$self->{data}}); ++$ii) {
      my $ordinal = $ii + 1;
      if ($ii >= scalar @{$other->{data}}) {
	print "Failure reason: \"$self->{name}\" has more exports than \"$other->{name}\"\n";
	$passed = 0;
	last;
      }
      my $selfRaw = $self->{data}->[$ii]->{raw};
      my $otherRaw = $other->{data}->[$ii]->{raw};
      if ($ignoreR3Unused) {
	$selfRaw =~ s/R3UNUSED //;
	$otherRaw =~ s/R3UNUSED //;
      }
      unless ($selfRaw eq $otherRaw) {
	$passed = 0;
	print "Failure reason: Def file mismatch between \"$self->{name}\" and \"$other->{name}\" at $ordinal\n";
	if ($self->{verbose}) {
	  print "\t$self->{data}->[$ii]->{raw}\n\t$other->{data}->[$ii]->{raw}\n";
	}
      }
    }
  }
  return $passed;
}

sub ListConstructors {
  my $self = shift;
  my @constructors = ();
  if (exists $self->{data}) {
    my $ordinal = 0;
    foreach my $thisEntry (@{$self->{data}}) {
      $ordinal++;
      die unless (exists $thisEntry->{function});
      if ($thisEntry->{function} =~ /(.+)::(.+)\(/) {
	if ($1 eq $2) {
	  push (@constructors, $1);
	}
      }
    }
  }
  return \@constructors;
}


#
# Private.
#

sub Parse {
  my $self = shift;
  open (DEF, $self->{name}) or die "Error: Couldn't open \"$self->{name}\" for reading: $!\n";
  my $lineNum = 0;
  while (my $thisLine = <DEF>) {
    ++$lineNum;
    chomp $thisLine;
    if ($thisLine =~ /^(EXPORTS|;|\s*$)/) {
      next;
    }
	my $entry = {};
    $entry->{raw} = $thisLine;
	     
    push (@{$self->{data}}, $entry);
  }
      close (DEF);
}

sub DemangleNames {
  my $self = shift;
  open (FILT, "type $self->{name} | c++filt |") or die "Error: Couldn't open \"type $self->{name} | c++filt |\": $!\n";
  my $lineNum = 0;
  while (my $line = <FILT>) {
    ++$lineNum;
    chomp $line;
    next if ($line =~ /^(EXPORT|;|\s*$)/);
    if ($line =~ /^\s+(\"(.+)\"|(.+)) @ (\d+)/) {
      my $function;
      if ($2) {
	$function = $2;
      }
      else {
	die unless $3;
	$function = $3;
      }
      my $ordinal = $4;
      $self->{data}->[$ordinal - 1]->{function} = $function;
    }
    else {
      die "Error: Unable to parse c++filt output for \"$self->{name}\" at line $lineNum\n";
    }
  }
  close (FILT);
}


#
# ClassSize
#

package ClassSize;


#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{classes} = shift;
  $self->{headers} = shift;
  $self->{includes} = shift;
  $self->{verbose} = shift;
  $self->{compName} = shift;
  $self->{bldInfDir} = shift;
  if (scalar @{$self->{classes}} > 0) {
    $self->GetClassSizes();
  }
  return $self;
}

sub Check {
  my $self = shift;
  my $other = shift;
  if ($self->{verbose}) { print "Comparing class sizes of \"$self->{bldInfDir}\" against \"$other->{bldInfDir}\"..\n"; }
  my $passed = 1;
  foreach my $thisClass (keys %{$self->{classSizes}}) {
    if ($self->{verbose}) { print "Examining class sizes of \"$thisClass\"...\n"; }
    unless (exists $other->{classSizes}->{$thisClass}) {
      print "Failure reason: \"$thisClass\" not found (possibly renamed)\n";
      $passed = 0;
      next;
    }
    unless ($self->{classSizes}->{$thisClass} == $other->{classSizes}->{$thisClass}) {
      $passed = 0;
      print "Failure reason: Class \"$thisClass\" has changed size from $self->{classSizes}->{$thisClass} to $other->{classSizes}->{$thisClass}\n";
    }
  }
  return $passed;
}


#
# Private.
#

sub GetClassSizes {
  my $self = shift;
  eval {
    $self->GenerateCode();
    $self->CompileCode();
    $self->GetOutput();
  };
  $self->CleanUp();
  if ($@) {
    die $@;
  }
}

sub GenerateCode {
  my $self = shift;
  open (CODE, '>__ClassSize.cpp') or die "Error: Couldn't open \"__ClassSize.cpp\" for writing: $!\n";
  print CODE "#include <stdio.h>\n";
  print CODE "#include <e32std.h>\n";
  print CODE "#include <e32def.h>\n";
  print CODE "#include <e32base.h>\n";
  foreach my $thisHeader (@{$self->{headers}}) {
    print CODE "#include <$thisHeader>\n";
  }
  print CODE "int main(int argc, char* argv[]) {\n";
  foreach my $thisClass (@{$self->{classes}}) {
    print CODE "\tprintf(\"$thisClass\\t%d\\n\", sizeof($thisClass));\n";
  }
  print CODE "\treturn 0; }\n";
  close (CODE);
}

sub CompileCode {
  my $self = shift;
  my $command = 'cl ';
  foreach my $thisInclude (@{$self->{includes}}) {
    $command .= " /I$thisInclude";
  }
  $command .= " /D__VC32__ /D__WINS__ /D__SYMBIAN32__ /DWIN32 /D_WINDOWS /D_UNICODE __ClassSize.cpp";
  unless ($self->{verbose}) {
    $command .= ' /nologo 2>&1 > NUL';
  }
  if (system ($command)) {
    if (exists $self->{compName} and $self->{compName}) {
      rename ("__ClassSize.cpp", "$self->{compName}.cpp");
    }
    else {
      rename ("__ClassSize.cpp", "unknown.cpp");
    }
    die "Error: Problem executing \"$command\"\n";
  }
}

sub GetOutput {
  my $self = shift;
  open (OUTPUT, '__ClassSize.exe|') or die "Error: Couldn't run \"__ClassSize.exe\": $!\n";
  while (my $thisLine = <OUTPUT>) {
    chomp $thisLine;
    next if ($thisLine =~ /^\s*$/);
    if ($thisLine =~ /^(\S+)\t(\d+)$/) {
      $self->{classSizes}->{$1} = $2;
    }
    else {
      die "Error: Problem parsing output of \"__ClassSize.exe\"\n";
    }
  }
  close (OUTPUT);
}

sub CleanUp {
  my $self = shift;
  DeleteFile('__ClassSize.cpp');
  DeleteFile('__ClassSize.obj');
  DeleteFile('__ClassSize.exe');
}

sub DeleteFile {
  my $file = shift;
  if (-e $file) {
    unlink ($file) or die "Error: Couldn't delete \"$file\"\n";
  }
}


#
# VTable
#

package VTable;


#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{bldInfDir} = shift;
  my $classes = shift;
  foreach my $class (@$classes) {
    $self->{classes}->{$class} = 1;
  }
  $self->{verbose} = shift;

  Utils::PushDir($self->{bldInfDir});
  eval {
    $self->BuildAssemblerListings();
    $self->ParseAssemblerListings();
    $self->DeleteAssemblerListings();
    };
  Utils::PopDir();
  if ($@) {
    die $@;
  }
  return $self;
}

sub Check {
  my $self = shift;
  my $other = shift;
  if ($self->{verbose}) { print "Comparing vtable layout of \"$self->{bldInfDir}\" against \"$other->{bldInfDir}\"..\n"; }
  my $passed = 1;
  foreach my $class (keys %{$self->{vtables}}) {
    if (exists $other->{vtables}->{$class}) {
      if ($self->{verbose}) { print "Examining vtable of class \"$class\"...\n"; }
      for (my $ii = 0; $ii < scalar (@{$self->{vtables}->{$class}}); ++$ii) {
	my $thisVTableEntry = $self->{vtables}->{$class}->[$ii];
	if ($ii >= scalar (@{$other->{vtables}->{$class}})) {
	  print "Failure reason: Unexpected vtable entry \"$thisVTableEntry\"\n";
	  $passed = 0;
	  last;
	}
	my $otherVTableEntry = $other->{vtables}->{$class}->[$ii];
	if ($thisVTableEntry eq $otherVTableEntry) {
	  if ($self->{verbose}) { print "\tMatched vtable entry \"$thisVTableEntry\"\n"; }
	}
	else {
	  print "Failure reason: Mismatched vtable entries in class \"$class\"\n\t$thisVTableEntry\n\t$otherVTableEntry\n";
	  $passed = 0;
	}
      }
    }
    else {
      print "Failure reason: Vtable for \"$class\" missing from $other->{bldInfDir}\n";
      $passed = 0;
    }
  }
  return $passed;
}



#
# Private.
#

sub BuildAssemblerListings {
  my $self = shift;
  if ($self->{verbose}) { print "Calling \"bldmake bldfiles\" in \"$self->{bldInfDir}\"\n"; }
  open (BLDMAKE, "bldmake bldfiles 2>&1 |") or die "Error: Couldn't run \"bldmake bldfiles\" in \"$self->{bldInfDir}\": $!\n";
  while (my $line = <BLDMAKE>) {
    if ($line) {
      if ($self->{verbose}) { print "\t$line"; }
      die "Error: Problem running \"bldmake bldfiles\" in \"$self->{bldInfDir}\"\n";
    }
  }
  close (BLDMAKE);

  if ($self->{verbose}) { print "Calling \"abld makefile arm4\" in \"$self->{bldInfDir}\"\n"; }
  open (ABLD, "abld makefile arm4 2>&1 |") or die "Error: Couldn't run \"abld makefile arm4\" in \"$self->{bldInfDir}\": $!\n";
  while (my $line = <ABLD>) {
    if ($line) {
      if ($self->{verbose}) { print "\t$line"; }
    }
  }
  close (ABLD);
  
  if ($self->{verbose}) { print "Calling \"abld listing arm4 urel\" in \"$self->{bldInfDir}\"\n"; }
  open (ABLD, "abld listing arm4 urel 2>&1 |") or die "Error: Couldn't run \"abld listing arm4 urel\" in \"$self->{bldInfDir}\": $!\n";
  while (my $line = <ABLD>) {
    if ($line) {
      if ($self->{verbose}) { print "\t$line"; }
      if ($line =~ /^Created (.*)/) {
	my $listingFile = $1;
	push (@{$self->{listingFiles}}, $listingFile);
      }
    }
  }
  close (ABLD);
}

sub ParseAssemblerListings {
  my $self = shift;
  foreach my $listing (@{$self->{listingFiles}}) {
    open (LISTING, $listing) or die "Error: Couldn't open \"$listing\" for reading: $!\n";
    while (my $line = <LISTING>) {
      if ($line =~ /^\s.\d+\s+__vt_\d+(\D+):$/) {  # If start of vtable section.
	my $class = $1;
	if (exists $self->{classes}->{$class}) { # If one of the classes we're interested in.
	  while (my $line2 = <LISTING>) {
	    if ($line2 =~ /^\s.\d+\s[\da-fA-F]{4}\s[\da-fA-F]{8}\s+\.word\s+(.*)/) {  # If this is a valid vtable entry.
	      my $vtableEntry = $1;
	      push (@{$self->{vtables}->{$class}}, $vtableEntry);
	    }
	    else {
	      last;
	    }
	  }
	}
      }
    }
    close (LISTING);
  }
}

sub DeleteAssemblerListings {
  my $self = shift;
  foreach my $listing (@{$self->{listingFiles}}) {
    unlink $listing or die "Error: Unable to delete \"$listing\": $!\n";
  }
}


#
# Utils.
#

package Utils;

use File::Basename;
use Cwd 'abs_path', 'cwd';
use Win32;

sub AbsoluteFileName {
  my $fileName = shift;
  unless (-e $$fileName) {
    die "Error: \"$$fileName\" does not exist\n";
  }
  (my $base, my $path) = fileparse($$fileName);
  my $absPath = abs_path($path);
  $$fileName = $absPath;
  unless ($$fileName =~ /[\\\/]$/) {
    $$fileName .= "\\";
  }
  $$fileName .= $base;
  TidyFileName($fileName);
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

  die unless ($fileName eq "$path$base$ext");
  return ($path, $base, $ext);
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
}

my @dirStack;

sub PushDir {
  my $dir = shift;
  my $cwd = cwd();
  chdir ($dir) or die "Error: Couldn't change working directory to \"$dir\": $!\n";
  push (@dirStack, $cwd);
}

sub PopDir {
  if (scalar @dirStack > 0) {
    my $dir = pop @dirStack;
    chdir ($dir) or die "Error: Couldn't change working directory to \"$dir\": $!\n";
  }
  else {
    die "Error: Directory stack empty";
  }
}


1;

=head1 NAME

CheckBc.pm - A module that runs some simple tests to see if one component source tree is backwards compatible another.

=head1 SYNOPSIS

  my $checkBc = CheckBc->New('\branch1\comp\group', '\branch2\comp\group', 0);
  unless ($checkBc->CheckAll()) {
    print "Check failed\n";
  }

=head1 DESCRIPTION

C<CheckBc> does the following checks to see if a backwards compatibility breaking change has been introduced:

=over 4

=item 1

Compares the ARM F<.def> files to ensure that only new lines have been added to the end of the file.

=item 2

Compares the sizes of any classes that have an exported C++ constructor. This is done by compiling some generated C++ code that uses the C<sizeof> operator to print the relevant class sizes to C<STDOUT>. Compilation is done using the MSVC++ compiler.

=item 3

Compares the v-table layouts of any classes that have an exported C++ constructor. This is done by compiling each source code set to ARM4 assembler listings, comparing the v-table sections.

=back

=head1 LIMITATIONS

=over 4

=item 1

The component's headers must compile using Microsoft's Visual C++ compiler.

=item 2

The component's exported headers must compile when they are all #include'd into a single F<.cpp> file. If this is not the case, then additional headers and include paths can be passed into the constructor.

=item 3

Declarations of the component's exported C++ constructors must be found in one of the exported headers.

=item 4

F<.def> file lines are expected to be identical. This can lead to checks failing falsely because, for example, the name of a function may be changed without breaking BC provided the F<.def> file is carefully edited.

=item 5

The components must compile as ARM4. This is likely to mean that each set of source code needs to be accompanied with a suitable F<\epoc32> tree that allows it to be built. The simplest way to acheive this is to prepare a pair of subst'd drives.

=back

=head1 KNOWN BUGS

F<bld.inf>, F<.mmp> and F<.def> file parsing is probably not as industrial strength as it should be.

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
