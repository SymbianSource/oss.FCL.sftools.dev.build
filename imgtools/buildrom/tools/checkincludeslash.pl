#!/usr/bin/perl

use Getopt::Long;

use constant TOOL_VERSION=>"0.1";

my $help;
my $dir;
my $convert;
my $logfile;
&processcmdline();

open (LOG, ">$logfile") or die "cannot open log file $logfile\n";
&checkdir($dir);
close LOG;

sub processcmdline
{
	GetOptions("h" => \$help, "l=s" => \$logfile, "c" => \$convert);
	
	if ($help)
	{
		print_usage();
		exit 0;
	}
	$logfile = "checkincludeslash.log" if (!defined $logfile);
	
	$dir = shift @ARGV;
	if (!defined $dir || !-d $dir)
	{
		print_usage();
		die "\nERROR: directory missing!!\n" if (!defined $dir);
		die "\nERROR: directory $dir does not exist!!\n" if (!-d $dir);
	}
}

sub checkdir 
{
  my $path = shift;
  return if (!-d $path);
  opendir(DIR,$path);   
  my @entries = readdir(DIR);   
  closedir(DIR);   
  my $entry;   
  foreach $entry (@entries) {   
	  next if (($entry eq ".") || ($entry eq ".."));
	  my $item = "$path/$entry";
  	if (-d $item) {
 	 		&checkdir($item);
	  }else {
	  	next if ($entry !~ /.*\.[a-z]by$/i);
	  	
		  &convobyfile($item, "$item.bak");
  	}   
  } 
}   

sub convobyfile
{
	my $src = shift;
	my $dst = shift;
	open (SRC, "<$src");
	open (DST, ">$dst") if($convert);

	my $line;
	while($line = <SRC>)
	{
		if ($line =~ /#\s*include\s*(<|\")(.*\\.*)(>|\")/)
		{
	  	print "Found content in file $src\n";
	  	print LOG "Found content in file $src\n";
	  	print "current line is $line";
	  	print LOG "current line is $line";
	  	if($convert)
	  	{
		  	my $path = $2;
		  	my $pathorg = $path;
		  	$pathorg =~ s-\\-\\\\-g;
		  	$path =~ s-\\-\/-g;
		  	$line =~ s-$pathorg-$path-g;
		  	print "converted line is $line";
		  	print LOG "converted line is  $line";
		  }
	  	print "\n";
	  	print LOG "\n";
		}
		print DST $line  if($convert);
	}
	close SRC;
	if($convert)
	{
		close DST;

	  unlink "$src";
  	rename ("$dst", "$src");
  }
}

sub print_usage
{
	print "\nCheckincludeslash - Check back slash tool V".TOOL_VERSION."\n";
	print "Copyright (c) 2010 Nokia Corporation.\n\n";
	print <<USAGE_EOF;
Usage:
  checkincludeslash.pl [-h] [-c] [-l <logfile>] <directory>

Check oby/iby files cursively in the <directory>. 
When it find back slash in include line in the files like \"\#include <dir\\file>\", 
it will report the line in log file. If with -c option it will convert the back slash
to forward slash like \"\#include <dir/file>\".
The <directory> is the directory contain all the oby/iby files.
Usually it should be /epoc32/rom/ and it will be checked cursively.

Options:
   -l <logfile>       - the log file to record the log, 
                        if not specfied it is \"checkincludeslash.log\"
   -h                 - displays this help
   -c                 - convert the back slash to forward slash.
USAGE_EOF
}