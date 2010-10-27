#!/usr/bin/perl

# Copyright (c) 2002-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# removebuild.pl - prepares a drive for a clean licensee build by removing
# all buildable files from the drive.
# 
#

my ($file) = readOpts(@ARGV);

exit remove($file);

sub readOpts(@)
	{
	my (@args) = @_;

	my $path = undef;

	foreach my $arg (@args)
		{
		if ($arg =~ /^-/)
			{
			if ((lc($arg) eq "--help")
			  ||(lc($arg) eq "-h")
			   )
			   	{
				showHelp();
				exit 0;
				}
			else
				{
				print STDERR "Option '$arg' not recognised.\n\n";
				print STDERR "Try 'removebuild --help' for help.\n";
				exit 1;
				}
			}
		else
			{
			if (defined($path))
				{
				print STDERR "Removebuild accepts only one argument.\n\n";
				print STDERR "Try 'removebuild --help' for help.\n";
				exit 1;
				}
			else
				{
				$path = $arg;
				}
			}
		}
	
	if (!defined($path))
		{
		print STDERR "Removebuild must be given a list of files to remove.\n\n";
		print STDERR "Try 'removebuild --help' for help.\n";
		exit 1;
		}
	
	return ($path);
	}

sub remove($)
	{
	my ($file) = @_;

	open(FILE, $file);

	my $dir = undef;
	my $failed = 0;
	my $worked = 0;
	my $hasentries = 0;

	foreach my $line (<FILE>)
		{
		chomp($line);
		$hasentries = 1;

		if ($line =~ /^\*/)
			{
			if ($line =~ /^\*DIR:/)
				{
				$dir = $line;
				$dir =~ s/^\*DIR:\s*//;

				$dir =~ s/[\/\\]*$//; # Remove trailing \/
				}
			else
				{
				close(FILE);
				die "'$file' is not a valid input.\n('$line' not recognised)\n";
				}
			}
		else
			{
			if (defined($dir))
				{
				$line =~ s/^[\/\\]*//; # Remove preceding \/

				# Attempt to delete '$dir\$line'

				$line = $dir."\\".$line;

				if (-e $line)
					{
					if (-d $line)
						{
						$failed = 1;
						print STDERR "ERROR: Could not remove file '$line' because $line is a directory\n";
						}
					else
						{
						if (!unlink($line))
							{
							$failed = 1;
							print STDERR "ERROR: Could not remove file '$line'. Make sure it is not write protected.\n";
							}
						else
							{
							$worked = 1;
							
							# Remove parent dirs if now empty
							my $empty = 1;
							while (($line =~ /[\/\\]/) && $empty)
								{
								$line =~ s/[\/\\][^\/\\]*$//; # Go to parent dir
								if (!rmdir($line))
									{
									# If it fails, the dir can't be empty
									$empty = 0;
									}
								}
							}
						}
					}
				}
			else
				{
				close(FILE);
				die "'$file' is not a valid input.\n(DIR must be set before '$line')\n";
				}
			}
		}
	
	close(FILE);

	if ($hasentries && (!$worked))
		{
		print STDERR "WARNING: No files listed in '$file' were found. Is the current directory correct?\n";
		}

	return $failed;
	}

sub showHelp()
	{
	print "removebuild [options] Filename\n";
	print " - prepares a drive for a 'build from clean' by removing\n";
	print "   all buildable files.\n\n";
	print "  Filename - The file listing the buildable files to be removed\n\n";
	print "Options:\n";
	print "  --help or -h - Display this message\n\n";
	}

