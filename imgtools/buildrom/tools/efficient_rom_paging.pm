#
# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# efficent_rom_paging.pm
# changes the paging/unpaged configuration of binaries a generated
# OBY file
# use
# externaltool=efficient_rom_paging
# in oby file to enable
# ## TODO
# ## keyword alias isn't handled
#

package efficient_rom_paging;
use strict;

our @EXPORT=qw(
    efficient_rom_paging_info
    efficient_rom_paging_single
    efficient_rom_paging_multiple
);
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();


my @moved_entry; # Holds all entries that has been moved without their dependencies

my %seen; # Holds all dependencies to entries in moved_entry
use File::Basename;

# routine to provide information about the tool
sub efficient_rom_paging_info ()
{
    my %toolinfo;
    $toolinfo{'name'} = "efficient_rom_paging";
    $toolinfo{'invocation'} = "InvocationPoint2.5";
    $toolinfo{'multiple'} = \&efficient_rom_paging_multiple;
    $toolinfo{'single'} = \&efficient_rom_paging_single;
    return \%toolinfo;
}

# routine to handle multiple invocation
sub efficient_rom_paging_multiple
{
    my ($line) = @_;
    my @args=split /[=\s]/, $line;
    return "REM efficient_rom_paging.pm";
}


#
# Hash of all executables and their paged attribute
#
my %executables;


sub is_oby_statement
{
	my ($li) = @_;
	if ($li =~ /\s*data\s*=/) { return 1;}
	if ($li =~ /\s*file\s*=/) { return 1;}
	if ($li =~ /\s*dll\s*=/) { return 1;}
	if ($li =~ /\s*secondary\s*=/) { return 1;}

	return 0;
}

# Scan OBY file and move ROM_IMAGE[1] paged executables to ROM_IMAGE[0] part
sub efficient_rom_paging_single
{
	my ($oby) = @_;
	
	print "efficient_rom_paging.pm: Making paging more efficient.\n";
	
	my $rofs_start = 0;
	#Find ROFS partition
	foreach my $line (@$oby)
	{
		if ($line =~ /ROM_IMAGE\[1\]/i)
		{
			last;
		}
		$rofs_start++;
	}

	my @rom_core_partition = @$oby[0 .. $rofs_start-1];
	my @rofs_partition = @$oby[$rofs_start .. $#$oby];
	
	if (is_pagingoverride_nopaged($oby))
	{
		move_all_paged_and_default_nonexecutables_to_core(\@rom_core_partition, \@rofs_partition);
		move_all_aliases_to_core(\@rom_core_partition, \@rofs_partition);
		@$oby = (@rom_core_partition, @rofs_partition);
		print "\n";
		return;
	}

	setup_pageable_attribute_array(\@rofs_partition);

	if (is_pagingoverride_defaultpaged($oby))
	{
		move_all_default_executables_to_core(\@rom_core_partition, \@rofs_partition);
	}

	move_all_paged_and_default_nonexecutables_to_core(\@rom_core_partition, \@rofs_partition);

	if (is_pagingoverride_alwayspage($oby))
	{
		move_all_executables_to_core(\@rom_core_partition, \@rofs_partition);
		move_all_aliases_to_core(\@rom_core_partition, \@rofs_partition);
		@$oby = (@rom_core_partition, @rofs_partition);
		print "\n";
		return;
	}
	
	move_all_paged_executables_to_core(\@rom_core_partition, \@rofs_partition);
	move_all_dependencies_to_core(\@rom_core_partition, \@rofs_partition, $oby);
	move_all_aliases_to_core(\@rom_core_partition, \@rofs_partition);
	move_all_renames_to_core(\@rom_core_partition, \@rofs_partition);
	move_all_patchdata_to_core(\@rom_core_partition, \@rofs_partition);
	
	@$oby = (@rom_core_partition, @rofs_partition);
	print "\n";
}

sub is_pagingoverride_nopaged
{
	my ($oby) = @_;
	
	for my $line (@$oby)
	{
		if ($line =~ /pagingoverride\s+nopaging/i)
		{
			return 1;
		}
	}
	return 0;
}

sub is_pagingoverride_defaultpaged
{
	my ($oby) = @_;
	
	for my $line (@$oby)
	{
		if ($line =~ /pagingoverride\s+defaultpaged/i)
		{
			return 1;
		}
	}
	return 0;
}

sub is_pagingoverride_alwayspage
{
	my ($oby) = @_;
	
	for my $line (@$oby)
	{
		if ($line =~ /pagingoverride\s+alwayspage/i)
		{
			return 1;
		}
	}
	return 0;
}



sub setup_pageable_attribute_array
{
	my ($rofs_partition) = @_;
	my $counter = 0;
	for my $line (@$rofs_partition)
	{
		if (is_oby_statement($line))
		{
			my $executable;
			$line =~ /file=(\S+)/i;
			$executable = $1;

			open DUMP, "ELFTRAN -dump h $executable |" or die "Can't execute ELFTRAN\n";
			while (my $line=<DUMP>)
			{
				if ($line =~ /pageability : (\S+)/i)
				{
					$executables{$executable} = $1;
					print "." if (($counter++ % 10) == 0);
				}
			}
			
			close DUMP;
		}
	}
}


sub move_all_paged_executables_to_core
{
	my ($rom_core, $rofs) = @_;
	
	my @rofs_execs = grep {$_ =~ /file\s*=/i} @$rofs;

	for my $line (@rofs_execs)
	{
		my $executable;
		$line =~ /file=(\S+) /;
		$executable = $1;

		if ($line =~ /\s+paged$/i || ($line !~ /\s+unpaged$/i && lc($executables{$executable}) eq 'paged'))
		{

			push @$rom_core, $line; # Add line to rom core.
			# Save the executables in a list. Will be used as a cache when dependencies are searched for.
			push @moved_entry, $executable; 
			@$rofs = grep {$_ ne $line} @$rofs; # Remove line from rofs partition
		}
	}
}

sub move_all_paged_nonexecutables_to_core
{
	my ($rom_core_partition, $rofs_partition) = @_;
	
	my @rofs_data = grep {$_ =~ /data\s*=\s*\S+\s+\S*\s+paged/i} @$rofs_partition;
	
	for my $line (@rofs_data)
	{
		push @$rom_core_partition, $line;
		@$rofs_partition = grep {$_ ne $line} @$rofs_partition;
	}
}

sub move_all_paged_and_default_nonexecutables_to_core
{
	my ($rom_core_partition, $rofs_partition) = @_;
	
	move_all_paged_nonexecutables_to_core($rom_core_partition, $rofs_partition);

	my @rofs_data = grep {$_ =~ /data=\s*/} @$rofs_partition;
	@rofs_data = grep {$_ !~ /unpaged/ } @rofs_data;
	
	for my $line (@rofs_data)
	{
		push @$rom_core_partition, $line;
		@$rofs_partition = grep {$_ ne $line} @$rofs_partition;
	}
}

sub move_all_default_executables_to_core
{
	my ($rom_core_partition, $rofs_partition) = @_;
	
	my @rofs_execs = grep {$_ =~ /file\s*=/i} @$rofs_partition;
	
	# If they have been set to unpaged in the oby file, they shouldn't be moved over.
	for my $executable (sort keys %executables)
	{
		if ($executables{$executable} =~ /default/i)
		{
			for my $line (@rofs_execs)
			{
				if ($line !~ /unpaged\s*$/i)
				{
					my $rofs_executable = $line;
					$rofs_executable =~ /file\s*=\s*(\S+)/i;
					$rofs_executable = $1;
					
					if ($rofs_executable eq $executable)
					{
						push @moved_entry, $executable; 
						push @$rom_core_partition, $line;
						@$rofs_partition = grep {$_ ne $line} @$rofs_partition;
						last;
					}
				}
			}
		}
	}
}

sub move_all_executables_to_core
{
	my ($rom_core_partition, $rofs_partition) = @_;
	
	my @all_executables = grep {$_ =~ /file\s*=/i} @$rofs_partition;
	
	for my $line (@all_executables)
	{
		push @$rom_core_partition, $line;
		push @moved_entry, $line;
		@$rofs_partition = grep {$_ ne $line} @$rofs_partition;
	}
}

sub move_all_aliases_to_core
{
	my ($rom_core_partition, $rofs_partition) = @_;
	
	my @all_aliases = grep {$_ =~ /^alias\s+\S+\s+\S+/i} @$rofs_partition;
	
	for my $line (@all_aliases)
	{
		$line =~ /^alias\s+(\S+)\s+\S+/i;
		my $alias = $1;
		$alias = basename($alias);

		my @file_stmt = grep {$_ =~ /^\s*(extension|device|file|data)(\[\S+\])?\s*=\s*\S+\s+\S*($alias)(\")?[\s+|\r](\s+\S+)*\s*$/i} @$rom_core_partition;
 		if(scalar @file_stmt)
		{
			push @$rom_core_partition, $line;
			@$rofs_partition = grep {$_ ne $line} @$rofs_partition;
		}
	}
}

sub move_all_renames_to_core
{
	my ($rom_core_partition, $rofs_partition) = @_;
	
	my @all_renames = grep {$_ =~ /^rename\s+\S+\s+\S+/i} @$rofs_partition;
	
	for my $line (@all_renames)
	{
		$line =~ /^rename\s+(\S+)\s+\S+/i;
		my $rename = $1;
		$rename = basename($rename);

		for (my $i=0; $i < scalar @$rom_core_partition; $i++)
		{
			if ($rename =~ $$rom_core_partition[$i])
			{
				splice(@$rom_core_partition, $i+1, 0, $line);
				@$rofs_partition = grep {$_ ne $line} @$rofs_partition;
				last;
			}
		}
	}
}

sub move_all_patchdata_to_core
{
	my ($rom_core_partition, $rofs_partition) = @_;
	
	my @all_patchdata = grep {$_ =~ /^patchdata\s+\S+\s+\S+\s+/i} @$rofs_partition;
	
	for my $line (@all_patchdata)
	{
		$line =~ /^patchdata\s+(\S+)\s+\S+\s+/i;
		my $patchdata = $1;
		$patchdata = basename($patchdata);

		if (grep($patchdata, @$rom_core_partition))
		{
			push @$rom_core_partition, $line;
			@$rofs_partition = grep {$_ ne $line} @$rofs_partition;
		}
	}
}

sub move_all_dependencies_to_core
{
	my ($rom_core_partition, $rofs_partition, $oby) = @_;
	my $counter = 0;
	
	for my $d (@moved_entry) 
	{
		if (!exists $seen{$d})
		{
			$seen{$d}=();
			listcomp("", $d, $oby);
			$counter++;
			print "." if (($counter % 10) == 0);
		}
	}
	
	# delete all dependencies that have already been moved to core rom.		
	for my $exec (@moved_entry)
	{
		if (exists $seen{$exec})
		{
			delete $seen{$exec};
		}
	}
	# move all dependencies to rom core
	my @rofs_execs = grep {$_ =~/file\s*=/i} @$rofs_partition;
	
	for my $exec (keys %seen)
	{
		for my $line (@rofs_execs)
		{
			my $rofs_exec = $line;
			$rofs_exec =~ /file\s*=\s*\S+\s+(\S+)/i;
			$rofs_exec = $1;
			$rofs_exec =~ s/"//g;
			
			if (basename(lc($exec)) eq basename(lc($rofs_exec)))
			{
				push @$rom_core_partition, $line;
				push @moved_entry, $line;
				@$rofs_partition = grep {$_ ne $line} @$rofs_partition;
				last;
			}
		}
	}
}

# for each exe, list the dependencies

sub listcomp
{
	my ($deps, $comp, $oby) = @_;
	# find dependencies of comp
	my @ar=getdeps($comp, $oby);
	# recurse over new dependencies
	foreach my $d (@ar)
	{
		$d=lc($d);
		if (!exists $seen{$d})
		{
 			# recurse
			$seen{$d}=();
			listcomp($deps, $d, $oby);
		}
	}
}

sub getdeps
{
	my ($comp, $oby) = @_;
	my @list=();
	my $hw_base_name = basename($comp);
	for my $line (@$oby)
	{
		if (is_oby_statement($line))
		{
			if ($line =~ /\\$hw_base_name/i)
			{
				$line =~ /\s*=\s*(\S+)\s*/;
				$comp = $1;
				last;
			}
		}
	}
	
	open DUMP, "ELFTRAN -dump i $comp |" or die "Can't execute ELFTRAN\n";
	while (my $line=<DUMP>)
	{
		if ($line =~ /imports from (\S+)/i)
		{
			my $d = $1;
			$d =~ s/\{\S{8}\}//; # remove {00000000}
			$d =~ s/\[\S{8}\]//; # remove [00000000]

			push @list, "$d";
		}
	}
	close DUMP;
	return @list;
}

1;
