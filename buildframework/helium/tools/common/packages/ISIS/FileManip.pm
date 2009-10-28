#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#!/usr/bin/perl -w
#--------------------------------------------------------------------------------------------------
# Name   : FileManip.pm
# Use    : File manipulation routines.

#
# Version History :
# v1.02 (17/01/2006) :
#  - Minor fixes.
#
# v1.01 (30/11/2005) :
#  - Updated CopyDir to support 'recursive' flag.
#  - Updated CopyDir to support 'regex' flag.
#  - Fix where CopyDir did not return correct number of copied files.
#
# v1.00 (18/10/2005) :
#  - Fist version of the module.
#--------------------------------------------------------------------------------------------------

package FileManip;

use File::Basename;
use File::Compare;
use File::Copy;
use File::Find;
use File::Spec;
use File::stat;
use Cwd;
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(UpdateDelimiters CountNbFiles CountNbDirs MakeDir CopyDir Explore GetEntries $Name $Dir);

use constant ISIS_VERSION     => '1.02';
use constant ISIS_LAST_UPDATE => '17/01/2006';

#--------------------------------------------------------------------------------------------------
# UpdateDelimiters :
#--------------------------------------------------------------------------------------------------
sub UpdateDelimiters
{
  my($string) = (shift);
  
  @folders = map { !/(?:\/|\\)/ ? $_ : () } split(/(\/|\\)/, $string);
  push(@folders, "") if($string =~ /.*(?:\/|\\)$/);
  return File::Spec->catfile(@folders);
}

#--------------------------------------------------------------------------------------------------
# CountNbFiles :
#--------------------------------------------------------------------------------------------------
sub CountNbFiles
{
  my ($nbFiles, @dirNames) = (0, @_ ? @_ : ('.'));
  my $filter = shift @dirNames if(ref $dirNames[0] eq 'CODE');

  @dirNames = map { &UpdateDelimiters($_) } @dirNames;  
  Explore({ process => sub { $nbFiles += (-d $_ ? 0 : 1) }, preprocess => sub { grep{ /$filter/ } @_; }}, @dirNames);
  #find({ wanted => sub { $nbFiles += (-d $_ ? 0 : 1) }, preprocess => $filter }, @dirNames);

  return $nbFiles;
}

#--------------------------------------------------------------------------------------------------
# CountNbDirs :
#--------------------------------------------------------------------------------------------------
sub CountNbDirs
{
  my ($nbDirs, @dirNames) = (0, @_ ? @_ : ('.'));
  my $filter = shift @dirNames if(ref $dirNames[0] eq 'CODE');

  @dirNames = map { &UpdateDelimiters($_) } @dirNames;
  Explore({ process => sub { $nbDirs += (-d $_ ? 0 : 1) }, preprocess => sub { grep{ /$filter/ } @_; }}, @dirNames);
  #find({ wanted => sub { $nbDirs += (-d $_ ? 1 : 0) }, preprocess => $filter }, @dirNames);

  return $nbDirs - 1;
}

#--------------------------------------------------------------------------------------------------
# MakeDir :
#--------------------------------------------------------------------------------------------------
sub MakeDir
{
  my ($string, $current) = (shift, undef);
  my @folders = map { !/(?:\/|\\)/ ? $_ : () } split(/(\/|\\)/, &UpdateDelimiters($string));
  
  $current = shift @folders;
  return 0 if(not mkdir(File::Spec->catfile($current)) and not -e $current);
  
  foreach (@folders)
  {
    $current = File::Spec->catfile($current, $_);
    return 0 if(not mkdir($current) and not -e $current);
  }
  
  return 1;
}

#--------------------------------------------------------------------------------------------------
# CopyDir :
#--------------------------------------------------------------------------------------------------
sub CopyDir
{
  my ($src, $dst, $flags, $res) = (shift, shift, shift, 0);

	my $verbose   = ($flags =~ /verbose/i);
  my $recursive = ($flags =~ /recursive/i);
  my $force     = ($flags =~ /force/i);
  my $regex     = ($flags =~ /regex/i);
  my $regexpr   = ".*";

	if($regex)
	{
		print " src is \'".$src."\'\n" if($verbose);
		($src, $regexpr) = ($src =~ /(.*\\{2})(.*?)$/);
		print " regular expression is \'".$regexpr."\'\n" if($verbose);
	}

  $src =~ s/^\.([^\.].*|)$/@{[&getcwd()]}$1/;
  $dst =~ s/^\.([^\.].*|)$/@{[&getcwd()]}$1/;
  $flags = "" if(not defined $flags);

  $src = &UpdateDelimiters($src);
  $dst = &UpdateDelimiters($dst);

  if($src !~ /^.*(?:\/|\\)$/)
  {
    my ($fulldir, $dir) = ($src =~ /^(.*(?:\/|\\))(.*?)$/);
    return 0 if($fulldir ne "" and not -e $fulldir);
    $dst = &UpdateDelimiters($dst.'/'.$dir);
  }
  
  print "Creating dir \'".$dst."\' ... " if($verbose);
  $res = MakeDir($dst);
  print "".($res == 1 ? 'Done' : "Error : $!")."\n" if($verbose);

  opendir(DIR_HANDLE, $src) or return 0;
  my (@files, @dirs);
  foreach (readdir(DIR_HANDLE))
  {
    next if(/^\.\.?$/);
    if(-d &UpdateDelimiters($src.'/'.$_)) { push @dirs, $_; }
    elsif($regex)                         { push @files, $_ if(/^$regexpr$/); }
    else                                  { push @files, $_; }
  }
  closedir(DIR_HANDLE);

  foreach (@files)
  {
    my $uSrc = &UpdateDelimiters($src.'/'.$_);
    my $uDst = &UpdateDelimiters($dst.'/'.$_);

    print " - Copying file ".$uSrc." to \'".$uDst."\' ... " if($verbose);
    my $res = copy($uSrc, $uDst);
    print "".($res == 1 ? 'Done' : "Error : $!")."\n" if($verbose);
  }
  
  my $total = 0;
  
  if($recursive)
  {
  	foreach (@dirs)
  	{
   	  print "------------------------\n" if($verbose);
   	  print " <> Exploring subdirectory \'".&UpdateDelimiters($src.'/'.$_)."\'\n" if($verbose);
   	  $total += CopyDir(&UpdateDelimiters($src.'/'.$_), $dst, $flags);
  	}
  }

  return scalar(@files) + $total;
}

#--------------------------------------------------------------------------------------------------
# Explore :
#--------------------------------------------------------------------------------------------------
our ($Name, $Dir);

sub Explore
{
  my ($rHash, @src) = (shift, @_);
  
  foreach my $src (@src)
  {
    opendir(DIR_HANDLE, $src) or return 0;
    my @entries = grep{ !/^\.\.?$/ } readdir(DIR_HANDLE);
    closedir(DIR_HANDLE);

    if(exists $$rHash{preprocess})
    {
      if(exists $$rHash{args}) { @entries = &{$$rHash{preprocess}}($src, @entries, $$rHash{args}); }
      else                     { @entries = &{$$rHash{preprocess}}($src, @entries, undef); }
    }

    foreach (@entries)
    {
      $Name = &UpdateDelimiters($src.'/'.$_);
      $Dir  = &UpdateDelimiters($src);
      if(exists $$rHash{args}) { &{$$rHash{process}}($$rHash{args}); }
      else                     { &{$$rHash{process}}(); }
    }

    if(exists $$rHash{postprocess})
    {
      if(exists $$rHash{args}) { @entries = &{$$rHash{postprocess}}($src, @entries, $$rHash{args}); }
      else                     { @entries = &{$$rHash{postprocess}}($src, @entries, undef); }
    }

    foreach (@entries)
    {
      my $fullDir = &UpdateDelimiters($src.'/'.$_);
      Explore($rHash, $fullDir) if($rHash{recursive} && -d $fullDir);
    }
  }
}

#--------------------------------------------------------------------------------------------------
# GetEntries.
#--------------------------------------------------------------------------------------------------
sub GetEntries
{
	my ($dir, $regex, @files) = (shift, shift);

	opendir(DIR_HANDLE, $dir) or ();
  @files = map { /$regex/ ? $dir.'\\'.$_ : () } readdir(DIR_HANDLE);
  closedir(DIR_HANDLE);
  
  return @files;
}

1; # End of FileManip package.

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

ISIS::FileManip - A set of platform independant file manipulation subroutines

=head1 SYNOPSIS

	my $correctPath = &UpdateDelimiters('/usr/bin/perl');
	
	print "number of files in dir \'/usr/bin/\'", &CountNbFiles('/usr/bin/'), "\n";
	print "number of dirs in dir \'/usr/bin/\'", &CountNbDirs('/usr/bin/'), "\n";
	
	MakeDir('/tmp/my_tmp_folder/try_1/');

	CopyDir('/code/src/[\w]+_\d\d\.cpp', '/code/backup', 'recursive verbose regex');

=head1 DESCRIPTION

=head2 UpdateDelimiters( PATH ) :

Updates the passed string representing a path to the right representation for the current
platform the script is running on.
 - param 0 : String to update.
 - return  : String formatted for the current platform.

=head2 CountNbFiles( PATH ) :

Recursive function. Counts number of files in full directory tree exploring each subfolder.
 - param 0 : Directories to explore. If not specified, current directory will be explored.
 - return  : Number of files in specified folder (recursive).
 
=head2 CountNbDirs( PATH ) :

Recursive function. Counts number of files in full directory tree exploring each subfolder.
 - param 0 : Directories to explore. If not specified, current directory will be explored.
 - return  : Number of subdirectories in specified folder (recursive), -1 if string passed as
             argument was not a valid directory.

=head2 MakeDir( PATH ) :

Recursive function. Creates a directory tree.
 - param 0 : Directory tree to create.
 - return  : True if successful, false otherwise.

=head2 CopyDir( SOURCE, DESTINATION, FLAGS ) :

Recursive function. Copies the content of a folder or the folder itself.
 - param 0 : Directory to copy. If source directory ends with a slash, the directory will be
             copied to the destination. If source directory does not end with a slash, the
             content of the directory will be copied to the destination.
 - param 1 : Destination directory to copy to.
 - param 2 : String containing copy flags. "recursive" will also copy subdirectories. "force"
             will copy files even if they exist in destination directory. "verbose" will print
             to standard output the operation details. "regex" 
 - return  : Number of copied files.

=head2 Explore( CALLBACKS ) :

Runs through a full directory tree, applying the passed subroutines at the different steps of
progress.
 - param 0 : Reference to a hash table containing information on the actions to take during the
             tree run-through.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------
