#! usr/bin/perl 

#============================================================================ 
#Name        : get_loc_files.pl 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description: 
#============================================================================
use strict;
use File::Copy;
use File::Find;
use File::Path;
use Cwd;

my $basedir = $ARGV[0];
my $locfiles = "locfiles";

find(\&copy_file, $basedir);

sub copy_file {
		my $filesrc = $File::Find::name;
		my $filedest = "output\\" . $_;
		my @subdir = split(/\//, $File::Find::dir);
	
		#copy the discovered .loc file to destination
		if ($_ =~ m/.*\.loc$/) {
			my $src = $filesrc;
			my $trg = $basedir . "/output/temp_build_files/locfiles/" . $subdir[-1] . "/" . $_;
			my $trgdir = $basedir . "/output/temp_build_files/locfiles/" . $subdir[-1];

			mkpath $trgdir;
			
			print "copying " . $src . " to " . $trg . "\n";
			if (-e $trg) {
				print "File already exists. Not copied!\n";
			}
			else
			{
				copy($src, $trg) or die "File cannot be copied.";
			}
		}
}