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
# changes the paging/unpaged configuration of binaries a generated
# OBY file according to the list in configpaging.lst
# use
# externaltool=configpaging.pm
# in oby file to enable
# use
# tool=configpaging \epoc32\rom\myconfigpaging.lst
# to change the default configpaging.lst
#

package configpaging;

use strict;

our @EXPORT=qw(
        configpaging_info
		configpaging_initialize
        configpaging_single
        configpaging_multiple
);
use Exporter;
our @ISA=qw(Exporter);

#
# Initialisation
#
use constant CONSTANT_UNPAGED => "unpaged";
use constant CONSTANT_PAGED => "paged";
use constant CONSTANT_UNPAGEDCODE => "unpagedcode";
use constant CONSTANT_PAGEDCODE => "pagedcode";
use constant CONSTANT_UNPAGEDDATA => "unpageddata";
use constant CONSTANT_PAGEDDATA => "pageddata";
use constant CONSTANT_CONFIG_PATH => "epoc32\\rom\\configpaging\\";
my $epocroot = $ENV{EPOCROOT};
my $configlist = $epocroot.CONSTANT_CONFIG_PATH."configpaging.cfg";


# routine to provide information about the tool
sub configpaging_info ()
{
    my %toolinfo;
    $toolinfo{'name'} = "configpaging";
    $toolinfo{'invocation'} = "InvocationPoint2";
	$toolinfo{'initialize'} = \&configpaging_initialize;
    $toolinfo{'multiple'} = \&configpaging_multiple;
    $toolinfo{'single'} = \&configpaging_single;
    return \%toolinfo;
}

sub configpaging_initialize
	{
	my ($cmdLine) = @_;
	if (defined ($cmdLine))
		{
		print "configpaging.pm: Initializing with $cmdLine\n";
		$configlist = $epocroot.CONSTANT_CONFIG_PATH.$cmdLine;
		}
	}

# routine to handle multiple invocation
sub configpaging_multiple
{
    my ($line) = @_;
	my @args=split /[=\s]/, $line;
	$configlist=$args[2];
    return "REM configpaging.pm: Using $configlist";
}


sub isobystatement
{
	my ($li) = @_;
	if ($li =~ /^\s*data(=|\s+)/i) { return 1;}
	if ($li =~ /^\s*file(=|\s+)/i) { return 1;}
	if ($li =~ /^\s*dll(=|\s+)/i) { return 1;}
	if ($li =~ /^\s*secondary(=|\s+)/i) { return 1;}

	return 0;
}

#codepaging is codepagingoverride setting
#datapaging is datapagingoverride setting
#listref is ref to an associated array keyed by <executable regex>, 
#and the value is another associated array keyed (un)?paged(code|data)?
#the value is 1 if set, undeffed if not.
sub readConfigFile
	{
	my ($codepagingref, $datapagingref, $listref, $configfilename) = @_;
	my $filecodepaging = "";
	my $filedatapaging = "";

	local *FILE; # need a filehandle local to this invocation
	if(!open FILE, $configfilename)
		{
		print ("Configpaging Warning: Can't open $configfilename\n");
		return;
		}

	# parse the configfilename
	# insert the files listed into the listref and set the paging info accordingly.
	while (my $line=<FILE>)
		{
		if ($line !~ /\S/ ) { next; }
		if ($line =~ /^\s*#/ ) { next; }
		chomp $line;
		if ($line =~ /^\s*(code|data)?pagingoverride=(.*)\s*/i) {
			if ($1 eq undef) {
				if (lc($2) eq "defaultpaged") {
					$$codepagingref = CONSTANT_PAGED;
					$$datapagingref = CONSTANT_PAGED;
				} elsif (lc($2) eq "defaultunpaged") {
					$$codepagingref = CONSTANT_UNPAGED;
					$$datapagingref = CONSTANT_UNPAGED;
				} else {
					print ("Configpaging Warning: invalid pagingoverride setting:$2\n");
				}
			} elsif (lc($1) eq "code") {
				if (lc($2) eq "defaultpaged") {
					$$codepagingref = CONSTANT_PAGED;
				} elsif (lc($2) eq "defaultunpaged") {
					$$codepagingref = CONSTANT_UNPAGED;
				} else {
					print ("Configpaging Warning: invalid codepagingoverride setting:$2\n");
				}
			} elsif ($1 eq "data") {
				if (lc($2) eq "defaultpaged") {
					$$datapagingref = CONSTANT_PAGED;
				} elsif (lc($2) eq "defaultunpaged") {
					$$datapagingref = CONSTANT_UNPAGED;
				} else {
					print ("Configpaging Warning: invalid datapagingoverride setting:$2\n");
				}
			} else {
				print ("configpaging Warning: invalid keyword: $1" . "pagingoverride\n");
			}
		}
		elsif ($line =~ /^\s*(un)?paged(code|data)?(\s+(un)?paged(code|data)?)?:/i ) {
			$filecodepaging = "";
			$filedatapaging = "";
			if ($1 eq undef) {
				if ($2 eq undef) {
					$filecodepaging = CONSTANT_PAGED;
					$filedatapaging = CONSTANT_PAGED;
				}elsif (lc($2) eq "code") {
					$filecodepaging = CONSTANT_PAGED;
				} elsif(lc($2) eq "data") {
					$filedatapaging = CONSTANT_PAGED;
				} else {
					print ("Configpaging Warning: unrecognized line:$line\n");
				}
			} elsif (lc($1) eq "un") {
				if ($2 eq undef) {
					$filecodepaging = CONSTANT_UNPAGED;
					$filedatapaging = CONSTANT_UNPAGED;
				}elsif (lc($2) eq "code") {
					$filecodepaging = CONSTANT_UNPAGED;
				} elsif(lc($2) eq "data") {
					$filedatapaging = CONSTANT_UNPAGED;
				} else {
					print ("Configpaging Warning: unrecognized line:$line\n");
				}
			} else {
				print ("Configpaging Warning: unrecognized line:$line\n");
			}
			if ($3 ne undef){		
				if ($4 eq undef) {
					if ($5 eq undef) {
						$filecodepaging = CONSTANT_PAGED;
						$filedatapaging = CONSTANT_PAGED;
					}elsif (lc($5) eq "code") {
						$filecodepaging = CONSTANT_PAGED;
					} elsif(lc($5) eq "data") {
						$filedatapaging = CONSTANT_PAGED;
					} else {
						print ("Configpaging Warning: unrecognized line:$line\n");
					}
				} elsif (lc($4) eq "un") {
					if ($5 eq undef) {
						$filecodepaging = CONSTANT_UNPAGED;
						$filedatapaging = CONSTANT_UNPAGED;
					}elsif (lc($5) eq "code") {
						$filecodepaging = CONSTANT_UNPAGED;
					} elsif(lc($5) eq "data") {
						$filedatapaging = CONSTANT_UNPAGED;
					} else {
						print ("Configpaging Warning: unrecognized line:$line\n");
					}
				} else {
					print ("Configpaging Warning: unrecognized line:$line\n");
				}
			}
		}
		elsif ($line =~ /^\s*include\s*\"(.*)\"/i)
			{ readConfigFile($codepagingref, $datapagingref, $listref, $epocroot.CONSTANT_CONFIG_PATH.$1); } # go recursive
		elsif ($line =~ /\s*(\S+)(\s+(un)?paged(code|data)?(\s+(un)?paged(code|data)?)?)?/i){
			my %element;
			$element{code} = $$codepagingref;
			$element{data} = $$datapagingref;
			if ($2 eq undef){
				if ($filecodepaging ne "") {
					$element{code} = $filecodepaging;
				}
				if ($filedatapaging ne "") {
					$element{data} = $filedatapaging;
				}
			} else {
				if ($4 eq undef){
					if ($3 eq undef) {
						$element{code} = CONSTANT_PAGED; 
						$element{data} = CONSTANT_PAGED; 
					} elsif (lc($3) eq "un") {
						$element{code} = CONSTANT_UNPAGED; 
						$element{data} = CONSTANT_UNPAGED; 
					}
				} elsif (lc($4) eq "code") {
					if ($3 eq undef) {
						$element{code} = CONSTANT_PAGED;
					} elsif (lc($3) eq "un") {
						$element{code} = CONSTANT_UNPAGED;
					}
				} elsif (lc($4) eq "data") {
					if ($3 eq undef) {
						$element{data} = CONSTANT_PAGED;
					} elsif (lc($3) eq "un") {
						$element{data} = CONSTANT_UNPAGED;
					}
				} else {
					print ("Configpaging Warning: unrecognized attribute in line: $line\n");
		}
				if ($5 ne undef){
					if ($7 eq undef){
						if ($6 eq undef) {
							$element{code} = CONSTANT_PAGED; 
							$element{data} = CONSTANT_PAGED; 
						} elsif (lc($6) eq "un") {
							$element{code} = CONSTANT_UNPAGED; 
							$element{data} = CONSTANT_UNPAGED; 
						}
					} elsif (lc($7) eq "code") {
						if ($6 eq undef) {
							$element{code} = CONSTANT_PAGED;
						} elsif (lc($6) eq "un") {
							$element{code} = CONSTANT_UNPAGED;
						}
					} elsif (lc($7) eq "data") {
						if ($6 eq undef) {
							$element{data} = CONSTANT_PAGED;
						} elsif (lc($6) eq "un") {
							$element{data} = CONSTANT_UNPAGED;
						}
					} else {
						print ("Configpaging Warning: unrecognized attribute in line: $line\n");
					}
				}
			}	
			$$listref{$1} = \%element;
		} else {
			print ("ConfigPaging Warning: unrecognized line:$line\n");
		}
	}
	close FILE;
	}

# routine to handle single invocation
sub configpaging_single
{
	my $codepaging="";
	my $datapaging="";
	my %list;
	my @keys;
    my ($oby) = @_;

	print "configpaging.pm: Modifying demand paging configuration using $configlist\n";
	readConfigFile(\$codepaging, \$datapaging, \%list, $configlist);
	# read the oby file that was handed to us
	# find matches between each oby line and any files  in the paged or unpaged list
	# modify the attributes of the oby line as appropriate
	my @newlines;
	my %element;
	@keys = keys %list;
	foreach my $line (@$oby)
		{
		my $codepagingadd="";
		my $datapagingadd="";
		chomp $line;
		if (isobystatement($line))
			{
			my $lcline = lc($line);
			for(my $index=@keys - 1; $index>=0; $index--) {
				my $match = $keys[$index];
				if ($lcline =~ /(\s+|\"|\\|=)$match(\s+|\"|$)/) {
					%element = %{$list{$match}};
					if ($element{code} eq CONSTANT_PAGED) {
						$codepagingadd .= " " . CONSTANT_PAGEDCODE;
					} elsif  ($element{code} eq CONSTANT_UNPAGED) {
						$codepagingadd .= " " . CONSTANT_UNPAGEDCODE;
					} 
					if ($element{data} eq CONSTANT_PAGED) {
						$datapagingadd .= " " . CONSTANT_PAGEDDATA;
					} elsif  ($element{data} eq CONSTANT_UNPAGED) {
						$datapagingadd .= " " . CONSTANT_UNPAGEDDATA;
					}
					last;
				}
			}
			if (!$codepagingadd and $codepaging) {
				$codepagingadd = " " . $codepaging . "code";
			}
			if (!$datapagingadd and $datapaging) {
				$datapagingadd = " " . $datapaging . "data";
					}
			if ($codepagingadd and !$datapagingadd){
				if ($line =~ /\b(un)?paged(data)?\b\s*$/) {
					$datapagingadd = " " . $1 . "pageddata";
				}
			} elsif ($datapagingadd and !$codepagingadd) {
				if ($line =~ /\b(un)?paged(code)?\b\s*$/) {
					$codepagingadd = " " . $1 . "pagedcode";
			}
				}
			if ($datapagingadd or $datapagingadd) {
				$line =~ s/\b(un)?paged(code|data)?\b/ /ig;
				}
			}
		push @newlines, "$line$codepagingadd$datapagingadd\n";
		}
	@$oby = @newlines;
}

1;
