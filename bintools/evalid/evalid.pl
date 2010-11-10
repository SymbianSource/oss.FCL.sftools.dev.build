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
# Validate releasables
# See below for usage
#

use Getopt::Long;
use Cwd;
use FindBin;
use File::Path;
use lib "$FindBin::Bin";
use EvalidMD5 0.01;
use EvalidCompare;

my $passed=0;
my $failed=0;

GetOptions("c", "v", "l=s", "k", "g", "f", "m", "u", "x=s@", "i=s@", "d=s");
$opt_v = $opt_v; # To keep -w quiet.
$opt_g = $opt_g; # To keep -w quiet.
$opt_f = $opt_f; # To keep -w quiet.
$opt_m = $opt_m; # To keep -w quiet.
$opt_u = $opt_u; # To keep -w quiet.
$opt_d = $opt_d; # To keep -w quiet.
$opt_k = $opt_k; # To keep -w quiet.

unless ((@ARGV > 1) && (@ARGV < 4))
	{
#........1.........2.........3.........4.........5.........6.........7.....
	print <<USAGE_EOF;

Usage:
  evalid [opts]    file1    file2       -- compare two files
  evalid [opts]    dir1     dir2        -- recursively compare two trees
  
MD5 Usage: 
  evalid [opts] -g dir1     file1       -- recursively generate MD5 checksums
  evalid [opts] -f listfile dir1  file1 -- create MD5 checksums of listed files
  evalid [opts] -m file1    file2       -- compare two MD5 datafiles

The recursive form will take each file in the tree rooted at dir1, 
determine its type, and using the appropriate comparison attempt to
compare it with the corresponding file in the tree rooted at dir2.

  evalid file1 dir2   =>  evalid file1      dir2\\file1
  evalid dir1  file2  =>  evalid dir1\\file1 file2
  
The opts parameter controls where the output goes:

	-v            -- verbose information about failed comparisons
	-c            -- print results to standard output
	-l <logfile>  -- append results to <logfile>
	-k            -- keep going

The default is equivalent to "-l evalid.lis"


MD5 Options in addition to standard options:

MD5 Generation options
  -g            -- generate MD5 of the dir1 and write to file1
  -f            -- generate MD5 of the files listed files and write to file1
                   The listfile must contain a list of files, one per line.
                   They should be specified relative to dir1 but should not
                   start in a directory seperator (\\)

Sub options for -g and -f
  -x            -- exclude a reqular expression from the list of files
  -i            -- include a regular expression in to the list of files
  -d dump_dir   -- generate the output used in the processing of dir1 content
                   into files of the same name, within the same directory
                   structure, under dump_dir.  This option permits the manual
                   examination of the data EVALID uses for its comparison work. 

MD5 Comparison option
  -m            -- compare the MD5's of the file1 against to file2
  -u            -- alternate output formats for comparison
                   suitable for upgrading the directory defined by file1
                   to have the same contents as the directory defined by file2

Note:  The inclusion takes precedence over the exclusion.
Note:  Standard option (-v) has no effect on MD5 operations.
Note:  Standard option (-l) has no effect on the -u option.

USAGE_EOF
	exit 1;
	}

# Generate checksum option
if ($opt_g)
{
  # Check $ARGV[0] is a directory
  die "$ARGV[0] is not a directory" unless (-d $ARGV[0]);
  # Check $ARGV[1] does not exist
  die "$ARGV[1] already exisits" if (-e $ARGV[1]);
  &EvalidMD5::MD5Generate($ARGV[0], $ARGV[1], \@opt_x, \@opt_i, undef, $opt_d);
  exit (0);
}

if ($opt_f)
{
  # Check $ARGV[0] is a directory
  die "$ARGV[0] does not exist" unless (-e $ARGV[0]);
  # Check $ARGV[1] is a directory
  die "$ARGV[1] is not a directory" unless (-d $ARGV[1]);
  # Check $ARGV[2] does not exist
  die "$ARGV[2] already exists" if (-e $ARGV[2]);
  &EvalidMD5::MD5Generate($ARGV[1], $ARGV[2], \@opt_x, \@opt_i, $ARGV[0], $opt_d);
  exit (0);
}

# Compare checksum file option (alternate format for upgrades)
if ($opt_u)
{
  my ($iCommon, $iLeftHeaders, $iRightHeaders, $iDiff);
  # Check $ARGV[0] file exists
  die "$ARGV[0] is not a file" unless (-f $ARGV[0]);
  # Check $ARGV[1] does not exist
  die "$ARGV[1] is not a file" unless (-f $ARGV[1]);
  ($iCommon, $iLeftHeaders, $iRightHeaders, $iDiff) = &EvalidMD5::MD5Compare($ARGV[0], $ARGV[1]);
  $failed = &EvalidMD5::MD5CompareZipDel($iCommon, $iDiff, $ARGV[0], $ARGV[1]);
  exit ($failed);
}

# Redirect output
if ($opt_c)
	{
	$log = \*STDOUT;
	}
else
	{
	if (!$opt_l)
		{
		$opt_l = "evalid.lis";
		}
	open LOG, ">>$opt_l" or die "Cannot open logfile $opt_l\n";
	$log = \*LOG;
	}

# Compare checksum file option
if ($opt_m)
{
  my ($iCommon, $iLeftHeaders, $iRightHeaders, $iDiff);
  # Check $ARGV[0] file exists
  die "$ARGV[0] is not a file" unless (-f $ARGV[0]);
  # Check $ARGV[1] does not exist
  die "$ARGV[1] is not a file" unless (-f $ARGV[1]);
  ($iCommon, $iLeftHeaders, $iRightHeaders, $iDiff) = &EvalidMD5::MD5Compare($ARGV[0], $ARGV[1]);
  $failed = &EvalidMD5::MD5ComparePrint($iCommon, $iLeftHeaders, $iRightHeaders, $iDiff, $log);
  exit ($failed);
}


# Make the comparison(s) Old Style

compare($ARGV[0], $ARGV[1]);

# Summarise the results

my $total=$passed+$failed;

if ($total > 1)
	{
	print $log "\nResults of evalid  $ARGV[0]  $ARGV[1]\n";
	}

if (@missing)
	{
	if ($total>1)
		{
		printf $log "\n%d missing files\n\n", scalar @missing;
		}
	map {
		print $log "MISSING: $_\n";
		} @missing;
	}

if (@failures)
	{
	if ($total>1)
		{
		printf $log "\n%d failed comparisons\n\n", scalar @failures;
		}
	map {
		my ($left, $right, $type) = @{$_};
		print $log "FAILED: $left\tand $right  ($type)\n";
		} @failures;
	}

if ($total>1)
	{
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
	printf $log "\n----------------\n%02d:%02d %02d/%02d/%04d\n", $hour, $min, $mday, $mon+1, $year+1900;
	print $log "evalid  $ARGV[0]  $ARGV[1]\n";
	if ($failed==0)
		{
		print $log "Passed all $total comparisons\n";
		}
	else
		{
		print $log "Failed $failed of $total comparisons\n";
		}
	
	print $log "----------------\n\n";
	}

exit($failed==0);

#---------------------------------
sub identical
	{
	my ($left, $right, $type)=@_;
	print $log "OK: $left\tand $right  ($type)\n";
	$passed+=1;
	}

sub different
	{
	my ($left, $right, $type)=@_;
	push @failures, [$left, $right, $type];
	$failed+=1;
	}

sub warning
	{
	my ($message)=@_;
	print $log "WARNING: $message\n";
	if (!$opt_c)
		{
		print "WARNING: $message\n";
		}
	# not a test failure as such
	}

sub problem
	{
	my ($message)=@_;
	print $log "PROBLEM: $message\n";
	$failed+=1;
	}

sub missing
	{
	my ($left) = @_;
	push @missing, $left;
	$failed+=1;
	}

sub compare
	{
	my ($left, $right, $recursing) = @_;
	if (-d $left && -d $right)
		{
		# Read all of the directory entries except . and ..
		# in to a local list.
		opendir LEFTDIR, $left or print "Cannot read directory $left\n" and return;
		my @list = grep !/^\.\.?$/, readdir LEFTDIR;
		closedir LEFTDIR;
		# recurse
		map { 
			compare($left."\\".$_, $right."\\".$_, 1);
			} @list;
		return;
		}
	if (-d $left)
		{
		if ($recursing)
			{
			if (-e $right)
				{
				problem("File $right should be a directory");
				}
			else
				{
				problem("Directory $right does not exist");
				}
			return;
			}
		compare($left."\\".$right,$right);
		return;
		}
	if (-d $right)
		{
		if ($recursing)
			{
			problem("Directory $right should be a file");
			return;
			}
		compare($left,$right."\\".$left);
		return;
		}
	# comparing files
	if (-e $left && !-e $right)
		{
		missing($right);
		return;
		}
	if (!-e $left && -e $right)
		{
		problem("File $left does not exist");
		return;
		}

	my ($same, $type) = EvalidCompare::CompareFiles($left, $right, $opt_v, $log, $opt_k);
	if ($same)
		{
		identical($left, $right, $type);
		}
	else
		{
		different($left, $right, $type);
		}
}
