#!perl
# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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

package CleanEnv;

use strict;

#
# Globals.
#

my $reallyClean = 0;
my $force = 0;
my $verbose = 0;


#
# Public.
#

sub CleanEnv {
  my $iniData = shift;
  $reallyClean = shift;
  $force = shift;
  $verbose = shift;
  my $envDb = EnvDb->Open($iniData, $verbose);
  (my $overallStatus, undef, my $dirtyComps, my $unaccountedItems, my $duplicates) = $envDb->CheckEnv(1, $reallyClean, 1);

  if ($overallStatus == EnvDb::STATUS_CLEAN) {
    print "Environment already clean\n";
    return 1;
  }
  else {
    my $cleaned = 1;
    if (scalar(@$unaccountedItems) > 0) {
      if (not $force or $verbose) {
        foreach my $line (@$unaccountedItems) {
          print "$line has unknown origin\n"; 
        }
      }
      if (Query("\nDelete above file(s)? [y/n] ")) {
        foreach my $file (@$unaccountedItems) {
          if ($verbose) { print "Deleting $file...\n"; }
          unlink $file or print "Warning: Couldn't delete $file: $!\n" if (-f $file);
          RemoveDirIfEmpty($file) if (-d $file);

          (my $dir) = Utils::SplitFileName($file);
          RemoveDirIfEmpty($dir) if (-d $dir);
        }
      }
      else {
        $cleaned = 0;
      }
    }
    if (scalar(@$dirtyComps) > 0) {
      print "\n";
      if (not $force or $verbose) {
        foreach my $comp (@$dirtyComps) {
          print "$comp->{comp} $comp->{ver} is dirty\n";
        }
      }
      if (Query("\nRe-install the above component(s)? [y/n] ")) {
        foreach my $comp (@$dirtyComps) {
          $envDb->RefreshComponent($comp->{comp});
        }
      }
      else {
        $cleaned = 0;
      }
    }
    if (scalar(@$duplicates) > 0) {
       print "\nThe following components are claiming the ownership of the same file:\n";

       # Compile a hash of conflicting components indexed by file
       my %duplicateFiles;
       foreach my $dup (@$duplicates) {
         # Each list item contains the filename, plus only two conflicting components.
         my $file = shift @$dup;
         $duplicateFiles{$file} = [] if !exists $duplicateFiles{$file};
         foreach my $comp (@$dup) {
           my $found = 0;
           foreach my $existingComp (@{$duplicateFiles{$file}}) {
             if ($existingComp eq $comp) {
               $found = 1;
               last;
             }
           }
           push @{$duplicateFiles{$file}}, $comp if !$found;
         }
       }

       foreach my $file (keys(%duplicateFiles)) {
         print join(", ", sort(@{$duplicateFiles{$file}})).": $file\n";
       }
       print "\nCleanEnv cannot resolve these duplicates.  To fix this, please remove one or\nmore of the conflicting components\n";
    }
    return $cleaned;
  }
}


#
# Private.
#

sub RemoveDirIfEmpty {
  my $dir = shift;
  if (DirEmpty($dir)) {
    rmdir $dir or print "Warning: Couldn't delete \"$dir\": $!\n";
    $dir =~ s/\\$//; # Remove trailing backslash.
    (my $parentDir) = Utils::SplitFileName($dir);
    RemoveDirIfEmpty($parentDir);
  }
}

sub DirEmpty {
  my $dir = shift;
  return (scalar @{Utils::ReadDir($dir)} == 0);
}

sub Query {
  my $question = shift;
  return 1 if $force;
  print $question;
  my $response = lc <STDIN>;
  chomp $response;
  return ($response eq 'y')?1:0;
}

1;

__END__

=head1 NAME

CleanEnv.pm - Provides an interface for cleaning environments.

=head1 INTERFACE

=head2 CleanEnv

Expects to be passed an C<IniData> reference, a flag indicating if a 'really clean' should be done, a flag indiacting of no user interaction (force) should be done, and a verbosity level. Cleans the environment accordingly. Returns true if the environment was cleaned (i.e. the user replied 'y' to all questions), false otherwise.

=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
