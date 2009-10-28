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
#------------------------------------------------------------------------------
# Name   : GenBuildTools.pm
# Use    : description.

#
# Synergy :
# Perl %name: GenBuildTools.pm % (%full_filespec:  GenBuildTools.pm-vc1s60p1#8:perl:fa1s60p1#1 %)
# %derived_by:  pmackay %
# %date_created:  Tue May 08 12:49:18 2007 %
#
# Version History :
#
# v1.2 (03/11/2006)
#  - Update BuildTBS to use Juno buildjob
#
# v1.1 (22/01/2006)
#  - Update txt file parser, change the drive on a general basis
#
# v1.0 (22/12/2005) :
#  - Fist version of the package.
#------------------------------------------------------------------------------

package GenBuildTools;

use strict;
use Cwd;
use ISIS::XMLManip;
use BuildJob;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.2';
use constant ISIS_LAST_UPDATE => '03/11/2005';
use constant DEBUGGING => 0;

#------------------------------------------------------------------------------
# Package's subroutines
#------------------------------------------------------------------------------

sub PreprocessAndCatInputs($$$$$)
{
	my ($arg, $inputs, $removes, $options, $output) = @_;
	
	my @list;	
	foreach my $f ( @{$inputs} )
	{
		my $output = $f;
		$output =~ s/\.txt/_parsed.txt/;
		PreprocessFile( $f , $output, $arg);
		push @list, $output;
	}
	my $res = &CatInputs ( \@list, $removes, $options, $output );
	foreach (@list)
	{
		unlink ( $_ );
	}
	return $res;
}


###############################################################################################
#
# CatInputs
#    @param @inputs
#    @param @removes
#    @param $output
#
###############################################################################################
sub CatInputs($$$$)
{
	print "@_\n" if (DEBUGGING);
	my ($inputs, $removes, $options, $output) = @_;
	
	my @full;
	my %toremove;
	foreach my $f ( @{$removes} )
	{
			print "Reading remove file: $f\n";
			if ( open (FILE, "<$f") )
			{
				while (<FILE>)
				{
					next if ( /^\s*\#.*$/ );
					next if ( /^\s*\/\/.*$/ );
					if ( /^\s*(\S+)\s*$/ )
					{
						$toremove{ lc("$1") } = 1;
					}
				}
				close FILE;
			}
			else
			{
				return 0;
			}
	}
	
	foreach my $f ( @{$inputs} )
	{
			print "Reading input file: $f\n";
			if ( open (FILE, "<$f") )
			{
				while (<FILE>)
				{
					if (/^\s*$/) {next;}
					chomp;
					s/^\s+//;         	  #Delete leading blanks
					s/\s+$//;            #Delete trailing blanks
					
					next if (/<option\s+\w+>/);
					next if (/^#.*/); # remove comments
					
					if (/^(\S+)\s+(\S+)$/)
					{
						my $pname = $1;
						my $pdir = $2;
						if  ( not exists ( $toremove{ lc($pname) } ) or not $toremove{ lc($pname) } )
						{
							$pdir =~ s/^\\(\S+)/$1/;
							push @full, "$pname    $pdir";
						}
						else
						{
							print "Removing: '$pname		$pdir'\n";
						}
					}
				}
				close FILE;
			}
			else
			{
				return 0;
			}
			
	}	
	unless ( open FILE, ">$output" ) {  print "Error opening '$output'\n"; return 0;}
	foreach ( @{$options} )
	{
		print FILE "<option $_>\n";
	}
	foreach ( @full )
	{
		print FILE "$_\n";
	}
	close FILE;
	return 1;
}

###############################################################################################
#
# PreprocessFile
#    @param $inputfile
#    @param $outputfile
#    @param $cpparg
#
###############################################################################################
sub PreprocessFile()
{
	my ($input, $output, $arg) = @_;
	my $drive = cwd(); $drive =~ /^(.:)/; $drive= "$1";
	
	$input = "$drive$input";
	$output = "$drive$output";
	$arg =~ s/<drive>/$drive/g;
	my $cmd = "cpp.exe -nostdinc -P -u $arg $input -o $output";
	print "$cmd\n" if (DEBUGGING);
	print `$cmd`;
	print "Preprocessing done.\n" if (DEBUGGING);
}

sub GenXML
{
	my ( $inputs , $output , $root) = @_;
	
	$root = "\\" unless ($root);
		
	my $files = "";
	foreach ( @{$inputs} )
	{
		$files .= " -d $_ ";
	}
	`call \\epoc32\\tools\\build\\genxml.pl $files -s $root -o ${output}.xml -l ${output}_xml_bld.log`;
	return 0 unless ( -e "${output}.xml" );
	return 1;
}

sub BuildTBS
{
	my ( $xmlfile, $logname ) = @_;

	$xmlfile =~ s/\.xml$//;
	$logname = $xmlfile unless ($logname);
	
	
	return 0 if ( not defined ($xmlfile) or not -e "$xmlfile.xml" );
	
	print "Starting clients\n";
	my $id = $ENV{ 'NUMBER_OF_PROCESSORS' } || 2;
	$id *= 2;
	print "Number of clients: $id\n";
	BuildJob::run("${xmlfile}.xml", "${logname}_bld.log", $id);
	print "Creating logs\n";
	unlink ("${logname}_scanlog.html") if (-e "${logname}_scanlog.html" );
	system ("call perl \\epoc32\\tools\\htmlscanlog.pl -l ${logname}_bld.log -o ${logname}_scanlog.html -v");
	return 1;
}


###############################################################################################
#
# CatXML
#    @param $output
#    @param @input
#
###############################################################################################
sub CatXML
{
	my $output = shift;
	my @list = @_;
	if (not defined($output) or not scalar(@list))
	{
		return 0;	
	}

	my $stage = 0;
	my $id = 0;

	#
	# Parsing the fisrt file
	#
	my $first = shift( @list );
	print "Parsing '$first'.\n";
	my $root = XMLManip::ParseXMLFile( $first );
	
	my $commandRoot = @{$root->Childs()}[0];
	$commandRoot->Unlock(); # unlock node for editing.
	my @a = @{$commandRoot->Childs()};
	
	$id = $a[scalar(@a)-1]->Attribute('ID');
	$stage = $a[scalar(@a)-1]->Attribute('Stage');
	
	foreach my $file ( @list )
	{
		my $maxstage = 0;
		my $maxid = 0;
	
		print "Parsing '$file'.\n";
	
		# parsing a file from list
		my $r = XMLManip::ParseXMLFile( $file );
		$r = @{$r->Childs()}[0];
		# for each command line.... 
		foreach my $cmd (@{$r->Childs()})
		{
			# is it and execute cmd
			if ($cmd->Type() eq "Execute")
			{
				$maxid = $cmd->Attribute("ID",  $id + $cmd->Attribute("ID"));
				$maxstage = $cmd->Attribute("Stage", $cmd->Attribute("Stage") + $stage );
			}
			
			# add this node to the root
			$commandRoot->PushChild( $cmd );
		}
		
		$stage = $maxstage;
		$id = $maxid;
	}
	
	print "Writing output file '$output'.\n";
	XMLManip::WriteXMLFile($root, $output);
	return 1;
}

1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------