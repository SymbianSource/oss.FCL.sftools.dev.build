#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
#
#! perl

# Read a Schedule12 file and check the system_model items
# against a supplied System_Definition.xml

use strict;

use FindBin;
use lib ".";
use lib "./lib";
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/lib";
use XML::DOM;
use XML::DOM::ValParser;

# produces the "Use of uninitialized value in concatenation (.) or string" warning
use XML::XQL;
use XML::XQL::DOM;

# Read the command line to get the filenames

sub Usage($)
	{
	my ($reason) = @_;

	print "Usage: $reason\n" if ($reason);
	print <<USAGE_EOF;

Usage: validate_sch12_model.pl <params> [options]

params:
-s <schedule12>     XML version of Schedule 12
-m <system_model>   XML version of System Model

options:
-o <whats_left>     XML file showing unreferenced
                       parts of the System Model
-r                  Remove matched objects from -o output
-c <cbr_mapping>    Tab separated file showing the Schedule 12
                       component for each MRP file

USAGE_EOF
	exit(1);
	}
	
use Getopt::Long;

my $schedule12file = "Symbian_OS_v9.1_Schedule12.xml";
my $systemmodelfile = "System_Definition.xml";
my $whatsleftfile = "";
my $remove = 0;
my $cbrmappingfile = "";

Usage("Bad arguments") unless GetOptions(
  	's=s' => \$schedule12file, 
  	'm=s' => \$systemmodelfile,
  	'o=s' => \$whatsleftfile,
  	'r'   => \$remove,
  	'c=s' => \$cbrmappingfile);

Usage("Too many arguments") if (scalar @ARGV > 0);
Usage("Cannot find $schedule12file") if (!-f $schedule12file);
Usage("Cannot find $systemmodelfile") if (!-f $systemmodelfile);


# Don't print info messages
sub my_fail
	{
	my $code = shift;
	if ($code < 300)
		{
		XML::Checker::print_error ($code, @_);
		}
	}
$XML::Checker::FAIL = \&my_fail;

# Load the XML documents
my %expat_options = 
	(
	KeepCDATA => 1, 
    Handlers => [],
    );

my $xmlParser = new XML::DOM::ValParser(%expat_options); 
XML::DOM::ignoreReadOnly(1);

my $sch12path = ".";
my $modelpath = ".";
$sch12path = $1 if ($schedule12file  =~ /^(.+)\\[^\\]+$/);
$modelpath = $1 if ($systemmodelfile =~ /^(.+)\\[^\\]+$/);
$xmlParser->set_sgml_search_path($sch12path, $modelpath);

my $modelXML = $xmlParser->parsefile ($systemmodelfile);
my $sch12XML = $xmlParser->parsefile ($schedule12file);

# Collect the Schedule12 entries, checking for duplicates

my %sch12refs;
my %componenttype;
my ($sch12) = $sch12XML->getElementsByTagName("Schedule12");
Usage("No <Schedule12> in $schedule12file ?") if (!defined $sch12);

my @children = $sch12->getChildNodes;
foreach my $child (@children)
	{
	next if ($child->getNodeTypeName ne "ELEMENT_NODE");
	my $tagname = $child->getTagName;
	next if ($tagname eq "footnote");
	my $component = $child->getAttribute("name");
	$componenttype{$component} = $tagname;
	
	my @entries = $child->getElementsByTagName("system_model");
	if (scalar @entries == 0)
		{
		print STDERR "No system_model entries in $component\n";
		next;
		}
		
	foreach my $entry (@entries)
		{
		my $name = $entry->getAttribute("entry");
		if (defined $sch12refs{$name})
			{
			print STDERR "$name occurs in $sch12refs{$name} and $component\n";
			}
		else
			{
			$sch12refs{$name} = $component;
			}
		}
	}

# Find the Schedule12 entries in the XML file

my %modelnames;
sub match_names($);		# declare the prototype for recursive call
sub match_names($)
	{
	my ($node) = @_;

	my @children = $node->getChildNodes;
	foreach my $child (@children)
		{
		if ($child->getNodeTypeName ne "ELEMENT_NODE")
			{
			# text and comments don't count
			next;
			}
		my $tagname = $child->getTagName;
		if ($tagname eq "unit")
			{
			# units are detail inside the model, so they don't count
			next;
			}
		my $name = $child->getAttribute("name");
		if ($name)
			{
			if (defined $modelnames{$name})
				{
				print STDERR "Name $name occurs more than once in the System Model\n";
				}
			$modelnames{$name} = $tagname;
			
			if (defined $sch12refs{$name})
				{
				$child->setAttribute("MATCHED", $sch12refs{$name});
				$modelnames{$name} = "1";
				}
			}
		match_names($child);
		}
	}

my ($model) = $modelXML->getElementsByTagName("systemModel");

match_names($model);

# Report on the accuracy of Schedule 12
print STDERR "\n";
my @allnames = ();
my $unmatched = 0;
foreach my $name (sort keys %sch12refs)
	{
	next if (defined $modelnames{$name});
	push @allnames, "$name\t(Sch12 $sch12refs{$name})\n";
	print STDERR "No match for $name (associated with $sch12refs{$name})\n";
	$unmatched += 1;
	}
if ($unmatched == 0)
	{
	print STDERR "All Schedule 12 entries matched in System Model\n";
	}
else
	{
	printf STDERR "%d Schedule 12 entry references not matched (from a total of %d)\n", $unmatched, scalar keys %sch12refs; 
	}

# Remove the matched elements to leave the unmatched parts,
# and accumulate the MRP files for each Sch12 component

my %sch12bymrp;
my %locationbymrp;

sub list_mrps($$$);		# declare the prototype for recursive call
sub list_mrps($$$)
	{
	my ($node,$location,$sch12name) = @_;
	my @children = $node->getChildNodes;
	my $nodename = $node->getAttribute("name");

	my $sublocation = $nodename;
	$sublocation = "$location/$nodename" if ($location ne "");
	
	foreach my $child (@children)
		{
		if ($child->getNodeTypeName ne "ELEMENT_NODE")
			{
			# text and comments don't count
			next;
			}
		my $tagname = $child->getTagName;
		if ($tagname eq "unit" || $tagname eq "package" || $tagname eq "prebuilt")
			{
			# these elements have the mrp information, but no substructure
			my $mrp = $child->getAttribute("mrp");
			$mrp = $1 if ($mrp =~ /\\([^\\]+)\.mrp$/i);
			$sch12bymrp{$mrp} = $sch12name;
			$locationbymrp{$mrp} = "$location\t$nodename";
			next;
			}
		my $submatch = $child->getAttribute("MATCHED");
		if ($submatch)
			{
			list_mrps($child,$sublocation,$submatch);
			}
		else
			{
			list_mrps($child,$sublocation,$sch12name);
			}
		}
	}

sub delete_matched($$);		# declare the prototype for recursive call
sub delete_matched($$)
	{
	my ($node, $location) = @_;
	my $nodename = $node->getAttribute("name");

	my $sublocation = $nodename;
	$sublocation = "$location/$nodename" if ($location ne "");

	my @children = $node->getChildNodes;
	return 0 if (scalar @children == 0);
	my $now_empty = 1;
	foreach my $child (@children)
		{
		if ($child->getNodeTypeName ne "ELEMENT_NODE")
			{
			# text and comments don't count
			next;
			}
		my $sch12name = $child->getAttribute("MATCHED");
		if ($sch12name)
			{
			list_mrps($child, $sublocation, $sch12name);
			$node->removeChild($child) if ($remove);
			}
		else
			{
			if (delete_matched($child,$sublocation) == 1)
				{
				# Child was empty and can be removed
				$node->removeChild($child) if ($remove);
				}
			else
				{
				list_mrps($child, $sublocation, "*UNREFERENCED*");
				$now_empty = 0;		# something left in due to this child
				}
			}
		}
	return $now_empty;
	}

# scan the tagged model, recording various details as a side-effect

my $allgone = delete_matched($model,"");

if ($whatsleftfile ne "")
	{
	if ($allgone)
		{
		print STDERR "System Model is completely covered by Schedule 12\n";
		}
	else
		{
		$modelXML->normalize;
		$modelXML->printToFile($whatsleftfile);
		print STDERR "Remains of System Model written to $whatsleftfile\n";
		}
	}

if ($cbrmappingfile ne "")
	{
	$componenttype{"*UNREFERENCED*"} = "??";
	open CBRMAP, ">$cbrmappingfile" or die("Unable to write to $cbrmappingfile: $!\n");
	foreach my $mrp (sort keys %sch12bymrp)
		{
		my $component = $sch12bymrp{$mrp};
		my $comptype = $componenttype{$component};
		my $location = $locationbymrp{$mrp};
		print CBRMAP "$mrp\t$location\t$component\t$comptype\n";
		}
	close CBRMAP;
	print STDERR "MRP -> Schedule 12 mapping written to $cbrmappingfile\n";
	}

exit 0;
