#
# Copyright (c) 1999-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# Relinks the debug exe/dlls in a ROM if the make file is present
#

require 5.003_07;
use strict;
no strict 'vars';
use English;
use Cwd;
use FindBin;		# for FindBin::Bin

my $PerlLibPath;    # fully qualified pathname of the directory containing our Perl modules

BEGIN {
# check user has a version of perl that will cope
	require 5.005_03;
# establish the path to the Perl libraries: currently the same directory as this script
	$PerlLibPath = $FindBin::Bin;	# X:/epoc32/tools
	$PerlLibPath =~ s/\//\\/g;	# X:\epoc32\tools
	$PerlLibPath .= "\\";
}

use lib $PerlLibPath;
use Modload;
Load_SetModulePath($PerlLibPath);

# Globals
my $debug = 0;
my $rombuild;
my @executables = ( 'euser' );

cwd =~ /^(.:)/o;
my $drive = $1;

# get EPOCROOT for searching directories
my $epocroot = lc $ENV{EPOCROOT};

&args;
&main;

exit 0;


#
# main
#
sub main
  {
	my $file;
	my $text;
	my $data;
	my $bss;
	my $textlen;
	my $datalen;
	my $bsslen;

	open (ROM, "<$rombuild")
	  or die "ERROR: Can't open rombuild log file \"$rombuild\"\n";

	die "ERROR: \"$rombuild\" isn't a rombuild log file\n"
	  unless ((<ROM> =~ /^ROMBUILD/) || (<ROM> =~ /^ROMBUILD/));
	
	# build up a hash of all the make files indexed by build and exe name
	#
	# do this in a more directed way based on the map files for the
	# executables we are interested in.

	%map = ();
	&dirsearch($epocroot . "EPOC32\\", "BUILD");

	while (<ROM>)
	  {
		if (/^Writing Rom image/)
		  {
		  # stop at end of first ROM, ignoring any extension ROMs
		  # This is necessary because the same file could appear
		  # at different places in different extensions.
		  #
		  last;
		  } 
		if (/^Processing file (.*)/)
		  {
			my $datalen;
			my $skip;
			
			$file = lc $1;
			$text = $bss = $data = $datalen = 0;
			
			# Work out final addresses of sections
			while (defined($_=<ROM>) && !/^$/)
			  {
				if (/^Code start addr:\s+(\w+)/)
				  {
					$text = hex($1);
				  }
				elsif (/^DataBssLinearBase:\s+(\w+)/)
				  {
					$data = hex($1);
				  }
				elsif (/^Code size:\s+(\w+)/)
				  {
					$textlen = hex($1);
				  }
				elsif (/^Data size:\s+(\w+)/)
				  {
					$datalen = hex($1);
					$bss = $data + $datalen;
				  }
				elsif (/^BssSize:\s+(\w+)/)
				  {
					$bsslen = hex($1);
				  }
			  }
			
			# Sanity check - text section can't be zero (other sections may be)
			die "ERROR: Can't find rombuild info for \"$file\"\n"
			  if (!$text);
			
			# get the build and exe name
			# protect $epocroot with \Q and \E to stop it 
			# using \ as a special character
			if ($file =~ /^\Q$epocroot\Eepoc32\\release\\(.*)\\(.*)\\(.*)$/o)
			  {
				$build = lc $1;
				$debrel = uc $2;
				$executablefile = lc $3;
			  }
			
			# Only relink this file if it's kernel-side or matches the regexp
			if ($build =~ /^(M|S)/i)
			  {
				$skip = 0;
			  }
			else
			  {
				$skip = 1;
				foreach $re (@executables)
				  {
					$skip = 0 if ($file =~ /$re/i);
				  }
			  }
			print "$file - skipped\n" if ($skip && $debug);
			next if ($skip);

			if (! defined $map{"$build $executablefile"})
			    {
			    print "$file - no makefile\n";
			    next;
			    }
			if ($debrel ne "UDEB")
			    {
			    print "$file - can't fixup $debrel\n";
			    next;
			    }

			# relink this file
			print "$file";
			
			# lookup the makefile name
			($makepath, $workdir) = @{$map{"$build $executablefile"}};

			# only relink if we have a makefile
			if ($makepath && $workdir)
			  {
				# optimisation: don't relink if already at correct address
				$file =~ /(.+\.)[^\.]+/;
				my $symfile = $drive.$1."sym";
				my $buf;
				my $elffile;
				open SYMFILE, $symfile or print"\nCannot open $symfile\n";	
				read SYMFILE, $buf, 4;
				if ($buf =~/^\x7F\x45\x4C\x46/){
					$elffile = $buf;
				}
				close SYMFILE;
				if ($elffile){
					if ((-e $file) && (-e $symfile) &&
						open (CHILD, "fromelf -v $symfile |"))
					{
						my $oldtext;
						my $olddata;
						my $foundcode = 0;
						my $founddata = 0;
						while (<CHILD>)
						{
							if (/ER_RO/)
							{
								$foundcode = 1;
							}
							if (/ER_RW/)
							{
								$founddata = 1;
							}
                
							if (/Addr : 0x\w+/)
							{
								$_=~tr/0-9//dc;
								if ($founddata == 1)
								{
									$founddata = 0;
									$olddata = hex($_);
								}
                
								if ($foundcode == 1)
								{
									$foundcode = 0;
									$oldtext = hex($_);
								}
							}
						}
						close CHILD;
						$skip = 1 if ((!$textlen || ($text == $oldtext)) && (!$datalen || ($data == $olddata)));
					}
				}
				else {
					if ((-e $file) && (-e $symfile) &&
						open (CHILD, "objdump --headers $symfile |"))
					{
						my $oldtext;
						my $olddata;
						my $oldbss;
						while (<CHILD>)
						{
							if (/^\s+\d+\s+(\.\w+)\s+[0-9a-fA-F]+\s+([0-9a-fA-F]+)\s/)
							{
								if ($1 eq '.text')
								{
									$oldtext = hex($2);
								}
								elsif ($1 eq '.data')
								{
									$olddata = hex($2);
								}
								elsif ($1 eq '.bss')
								{
									$oldbss = hex($2);
								}
							}
						}
						close CHILD;
						$skip = 1 if ((!$textlen || ($text == $oldtext)) &&
									(!$datalen || ($data == $olddata)) &&
									(!$bsslen	 || ($bss  == $oldbss)));
						print " - current" if ($skip && $debug);
					}
				}
				
				if (!$skip)
				  {
					chdir $workdir
					  or die "Can't cd to build directory \"$workdir\"\n";

					# save executable in case relink fails
					rename $file, "$file.bak"
					  or die "Can't rename \"$file\": $ERRNO\n"
						if -e $file;
						
						$makepath = &fixMakefile($makepath);
						my $command;
						if ($elffile){
							if($makepath =~ /\.gcce/i){
								$command =
									sprintf ("make -r -s -f \"$makepath\" $debrel " .
									"USERLDFLAGS=\"-Ttext 0x%lx -Tdata 0x%lx\"", $text, $data);
							}
							else {
								$command =
									sprintf ("make -r -s -f \"$makepath\" $debrel " .
									"USERLDFLAGS=\"--ro-base 0x%lx --rw-base 0x%lx\"", $text, $data);
							}
						}
						else {
							$command =
								sprintf ("make -r -s -f \"$makepath\" $debrel " .
								"USERLDFLAGS=\"--image-base 0 -Ttext 0x%lx " .
								"-Tdata 0x%lx -Tbss 0x%lx\"",
								$text, $data, $bss);
						}
						print "\n\"$command\"" if ($debug);

					open (CHILD, "$command |")
					  or die "\nERROR: Can't run \"$command\": $ERRNO\n";
					close CHILD;

					unlink $makepath;
					if (-e $file)
					  {
						unlink "$file.bak";
					  }
					else	# relink failed for some reason - restore saved
					  {
						rename "$file.bak", $file;
					  }
				  }

				print "\n";
			  }
			else
			  {
				print " - can't fixup\n";
			  }
		  }
	  }
	close ROM;
  }

#
# args - get command line args
#
sub args
  {
	my $arg;
	my @args;
	my $flag;
	
	&help if (!@ARGV);
	
	while (@ARGV)
	  {
		$arg = shift @ARGV;
		
		if ($arg=~/^[\-\/](\S*)$/)
		  {
			$flag=$1;
			
			if ($flag=~/^[\?h]$/i)
			  {
				&help;
			  }
			else
			  {
				print "\nERROR: Unknown flag \"-$flag\"\n";
				&usage;
				exit 1;
			  }
		  }
		else
		  {
			push @args,$arg;
		  }
	  }
	
	$rombuild = shift @args;
	
	if (@args)
	  {
		foreach $file (@args)
		  {
			push @executables, quotemeta($file);
		  }
	  }
  }


# recursive directory search
sub dirsearch
	{
	my ($input_path, $dir) = @_;
	my $searchpath = "$input_path$dir\\";
	my $workdir;

	return unless (opendir DIRHANDLE, $searchpath);
	my @allfiles = grep !/^\.\.?$/, readdir DIRHANDLE;
	closedir DIRHANDLE;

	# Breadth first search: scan files and collect list of subdirectories
	my @dirlist;
	foreach $entry (@allfiles)
		{
		my $entrypath = "$searchpath$entry";
		if (-d $entrypath)
			{
			# don't look in udeb & urel directories which contain objects and binaries
			push @dirlist, $entry unless ($entry =~ /(deb|rel)$/i);
			}
		elsif ($entry =~ /$dir$/i)
			{
			# ARM4/xxx.ARM4 => generated makefile
			my $liney;
			open (FILE, "<$entrypath");
			while ($liney=<FILE>)
				{
				if ($liney =~ /^\# CWD\s(.+)\\/)
					{
					$workdir = lc $1;
					}
				if ($liney =~ /^\# Target\s(.*)$/)
					{
					my $target = lc $1;
 
					# add to the hash table
					my $build = lc $dir;
					$map{"$build $target"} = [lc "$entrypath", $workdir];
					$workdir = undef;
					last;
					}
				}
			close FILE;
			}
		}
	undef @allfiles;
	# Now process the subdirectories...
	foreach $entry (@dirlist)
		{
		&dirsearch ($searchpath,$entry);
		}
	undef @dirlist;
	}
	
sub help ()
  {
	my $build;
	
	&Load_ModuleL('E32TPVER');
	print "\nfixupsym - " .
	  "Fix up executables with locations taken from a ROM image (Build ",
	  &E32tpver, ")\n";
	&usage;
	exit 0;
  }
	
sub usage ()
  {
	print <<EOF
		  
Usage:
  fixupsym <logfile> [<executables>]

Where:
  <logfile>     Log file from rombuild tool.
  <executables> Names of additional executables to fix up.
                ASSP-specific executables and EUSER are always included.

Example:
  fixupsym rombuild.log efile efsrv .fsy
EOF
  ;
	exit 0;
  }
sub fixMakefile()
  {
	my $makefile = shift @_;
	my $tmpMakfile = $makefile.".TMP";
	open (FILEIN, $makefile) or die "Can't open file \"$makefile\" \n";
	open (FILEOUT, ">".$tmpMakfile) or die "Can't create file \"$tmpMakfile\" \n";
	while(<FILEIN>) {
		if ($_ =~ /^\s*elf2e32/){
			print FILEOUT "#".$_;
		}
		else {
			print FILEOUT $_;
		}
	}
	close FILEIN;
	close FILEOUT;
	$tmpMakfile;
  }
