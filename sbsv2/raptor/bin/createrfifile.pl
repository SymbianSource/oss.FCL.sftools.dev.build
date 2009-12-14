#
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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

use strict;
use File::Basename;
use Getopt::Long;

my $verbose = 0;
my ($rfifile, $excludepath) = "";
GetOptions ('v' => \$verbose, 'o=s' => \$rfifile, 'x=s' => \$excludepath);

if (!$rfifile || @ARGV < 1)
	{
	print (STDERR "\ncreaterfifile.pl\n");
	print STDERR << 'END_OF_HELP';

Usage: createrfifile.pl [-v] -o outputfile.rfi [-x excludepath] rss_cpp_deps_file_1.d rss_cpp_deps_file_n.d

Takes one or more files containing CPP dependency output from the preprocessing of a .rss file and
generates a "combined resource" .rfi that can  be consumed by CDB.
Optionally takes an exclusion path under which "found" dependencies can be ignored.

END_OF_HELP
	exit(0);
	}

my @depfiles = @ARGV;

my $exclude = $excludepath;
if ($exclude)
	{
	$exclude =~ s/\\/\//g;			# Ensure consistent slashes
	$exclude =~ s/\/\//\//g;		# Remove double slashes
	$exclude = quotemeta($exclude);	# Convert for regex match
	}

print ("RFI : exclude under - \"$exclude\"\n") if ($verbose);

my @resources;
my %loggedresources;
foreach my $depfile (@depfiles)
	{
	open DEPFILE, "< $depfile" or die "\nRFI : Cannot read \"$depfile\"!\n\n";
	while (<DEPFILE>)
		{
		# .d file format - whitespace at front is key, path format varies depending on platform
		# the aim is to get a list of the "real" files. Missing files can appear "unpathed"
		#
		#Audio.rsc: M:/src/common/techview/apps/audio/Src/Audio.rss \
		#  M:/epoc32/include/variant/Symbian_OS.hrh \
		#  M://epoc32/include/techview/eikon.rh \
		#  M://epoc32/include/techview/eikon.hrh M://epoc32/include/uikon.hrh \
		#  M://epoc32/include/techview/controls.hrh \
		#  M://epoc32/include/eikcolor.hrh \
		#  M://epoc32/include/techview/techview.hrh M://epoc32/include/uikon.rh \
		#  M://epoc32/include/badef.rh M://epoc32/include/baerrrsvr.rh \
		#  M://epoc32/include/techview/controls.rh M://epoc32/include/gulftflg.hrh \
		#  M://epoc32/include/eikcore.rsg M://epoc32/include/eikcoctl.rsg \
		#  M://epoc32/include/eikctl.rsg M://epoc32/include/eikfile.rsg \
		#  M://epoc32/include/eikprint.rsg M://epoc32/include/audio.mbg \
		#  M:/src/common/techview/apps/audio/Src/Audio.hrh \
		#  M:/src/common/techview/apps/audio/Src/NewAudio.rls
		
		s/^.*\.\w+\://;
		s/\\$//;
		s/^\s+//;
		s/\s+$//;
		s/\/\//\//g;
		chomp $_;
		next if !/\S/;	
	
		my @dependencies = split;	
		foreach my $dependency (@dependencies)
			{
			next if ($exclude && $dependency =~ /^$exclude/i);
			print ("WARNING: Could not find dependency \"$dependency\" in \"$depfile\"\n") if (!-e $dependency and $verbose);		
			print ("RFI : processing - \"$dependency\"\n") if ($verbose);
			
			if (!defined $loggedresources{$dependency})
				{
				push @resources, $dependency;
				$loggedresources{$dependency} = 1;
				}
			}
		}
	close DEPFILE;
	}

open RFIFILE, "> $rfifile" or die "\nRFI : Cannot write \"$rfifile\"!\n\n";
foreach my $resource (@resources)
	{
	print RFIFILE "\n\n/* GXP ***********************\n";
	print RFIFILE " * ".basename($resource)."\n";
	print RFIFILE " ****************************/\n\n";
	
	open RESOURCE, "< $resource" or die "\nCannot read \"$resource\"!\n\n";
	print RFIFILE $_ while (<RESOURCE>);
	close RESOURCE;
	}
close RFIFILE;

