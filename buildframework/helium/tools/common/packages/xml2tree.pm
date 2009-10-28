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
#****h*	lib/xml2tree.pm
#	NAME
#		xml2tree.pm
#	DESCRIPTION
#		This module	is used	to parse the data	from a xml file and convert it to tree like data structure for further processing
#  		Each node is connected two way and looks like as follows
#	   +---------+------+------------+------------+--------------+----------------------+
#	   |prev			|el_name	 |attr		  |value	  	 |next               	|
#	   |(Reference to 	|(Name of    |(Hash of the|(String value)|Reference of array to	|
#	   |the parent node)|the element)|atrributes) |		         |next child elements)	|
#	   +----------------+------------+------------+--------------+----------------------+	 
#	RETURN VALUE
#   	0 if successfull, 1 on error
# 	EXAMPLE
#		use xml2tree;
#		.
#		.
#   	my $pr = xml2tree->new();
#		$pr->parseFile(dct5_release_note.xml);
#		.
#		.
#		my $trees = $getNode('Document');
#	SEE ALSO
#		sbt/data//subcon/dct5_release_note.xml
#   	sbt/make_dct5_upload.pl
#   	sbt/lib/sbt_common.pm
#	HISTORY
#		Version			:	0.1
#		Date				:	
#		Author			:	rownak
#   TODO
#		Case insensitive search
#		Support non recursive search in case of attachment
#******




package	xml2tree;

use	strict;
use	XML::Parser;

    	
my %entities = ();
my %root;
my $parser;
my $curr_elem;

my $xml_file;
my $count=0;

#my @found_nodes;

#==========================================================
#		Intialization Part
#
#		Constructor. and others
#==========================================================

#usage(); 
#exit 0;

sub	new{
	
	$parser	= new	XML::Parser(ParseParamEnt	=> 1,Handlers	=> 
				{Entity	=> \&entityHandler,	
				 Char	=> \&charHandler,
				 Start =>	\&startHandler,
				 End =>	\&endHandler});

	 
	
}

#   Parse a given XML file.
sub parseFile{
     my $file = shift; 
     $parser->parsefile($file);
}		

#==========================================================
#		Data Processing Part
#
#		
#==========================================================

#   XML::Parser uses this function when it finds  an xml entity.
sub entityHandler{
    my ($p, $name, $val) = @_;
    		
    eval {$entities{$name} = $val;};
    die ("Error in handling xml characters " .
        "at line $p->current_line") if $@;
        
}

#   XML::Parser uses this function when it finds an xml element start entry.
sub startHandler{
    my ($p, $element, %attr) = @_;
    #Root of the tree
	
    if($element eq ''){
    	return;
	}
	$p->{cdata_buffer}='';
	#making a two way linked list of tree value
	if(not defined($curr_elem)){
    	$root{'el_name'} = $element;
    	$root{'attr'} = \%attr;
    	$root{'prev'} = 0;
    	$root{'next'} = 0;
    	$root{'value'}= 0;
    	
    	$curr_elem = \%root;
    }else{
	   	my %element;
		
		$element{'el_name'} = $element;
		$element{'attr'} = \%attr;
		$element{'prev'} = $curr_elem;
		$element{'next'} = 0;
		$element{'value'}= 0;
		if($curr_elem->{'next'} == 0){
			my @child_element;
			push(@child_element,\%element);	
			$curr_elem->{'next'}=\@child_element;
		
		}
		else{
			my $child_element = $curr_elem->{'next'};
			push(@$child_element,\%element);	
			$curr_elem->{'next'}=$child_element;
		
		}
	
		$curr_elem = \%element;
   	}
}

#   XML::Parser uses this function when it finds  an xml element end entry.
sub endHandler{
	my($p) = @_;
	$curr_elem->{'value'} = $p->{cdata_buffer} ;
	$curr_elem = $curr_elem->{'prev'};
}


#   XML::Parser uses this function when it finds an xml character entry.
sub charHandler{

	my ($p, $str) = @_;
    my $element;
    my @context = $p->context;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
	
	if($str eq ""){
		return;
	}
	$p->{cdata_buffer} .= $str;
	

}




##==========================================================
##		External interface part
##
##		This methods will be used by its client
##==========================================================

#

sub usage
{
   
    print"\n\n";
    print "Functionality: \n";
    print"======================\n";
    print "it parse any xml and convert the data into a two way trre like linked list \n\n";
    print "use xml2tree\n";
	print "\.\n";
	print "\.\n";
   	print 'my $pr = xml2tree->new()'."\n";
	print '$pr->parseFile(dct5_release_note.xml)'."\n";
	print "\.\n";
	print "\.\n";
	print 'my $trees = $getNode(\'Document\')'."\n";
        
}

#Depending on the search criteria it returns array of nodes.
# Input is 
# 	el_name    => element name of searching node(compulsory)
# 	attributes => Hash input of attributes to be searched. It will retun true even if it is a subset.(optional)
# 	value      => value of the element(optional)
#
#Output is 
#	Array of nodes that has been found . Each node has following type of structure
#	   +---------+------+------------+------------+--------------+----------------------+
#	   |prev			|el_name	 |attr		  |value	  	 |next               	|
#	   |(Reference to 	|(Name of    |(Hash of the|(String value)|Reference of array to	|
#	   |the parent node)|the element)|atrributes) |		         |next child elements)	|
#	   +----------------+------------+------------+--------------+----------------------+	 
sub getNode{
	my $tmp_el_name  = shift;
	my $tmp_attr     = shift;
	my $tmp_value    = shift;
	my @found_nodes=();	
	if ($tmp_el_name eq '0' ){
		return;	
	}
	
	if(not defined $tmp_attr){$tmp_attr=0;}
	if(not defined $tmp_value){$tmp_value=0;}
	
	
	
	searchTree($root{'next'},$tmp_el_name,$tmp_attr,  $tmp_value,\@found_nodes);
	
	return \@found_nodes; 
}

sub getPrevSibling{
	my $curr_element = shift;
	my $parent = $curr_element->{'prev'}; 	
	my $child_array = $parent->{'next'};
	my $prevSibling=undef;
	foreach my $tmp_sibling (@$child_array){
		if ($tmp_sibling == $curr_element){
			last;	
			
		}
	} 
	return $prevSibling
} 
sub getEntities{
	return \%entities;
}

sub getRoot{
	return \%root;
}
##==========================================================
##		Private functions part
##
##		This functions  will be used by external interface part
##==========================================================

#
sub searchTree{
	my $xml_sub_tree = shift;
	my $tmp_el_name  = shift;
	my $tmp_attr     = shift;
	my $tmp_value    = shift;
	my $found_nodes_ref = shift;
	my $is_attr_exist = 0; 
	my $is_value_exists=0;
	my $is_el_name_exists=0;
	if($xml_sub_tree eq '0'){return;}
	foreach my $node (@$xml_sub_tree){
			
		my $prev_node = $node->{'prev'}; 
		my $tmp_attr_node= $node->{'attr'};
		if($tmp_attr ne '0'){
			$is_attr_exist = is_LsubsetR($tmp_attr,$tmp_attr_node); 
		}
		
		if((($tmp_el_name eq '0')||(($tmp_el_name ne '0') && ($node->{'el_name'} eq $tmp_el_name))) &&
			(($tmp_value eq '0')||(($tmp_value ne '0') && ($node->{'value'} eq $tmp_value)))&&
			(($tmp_attr eq '0')||(($tmp_attr ne '0') && $is_attr_exist))){
			
			push (@$found_nodes_ref, $node)		
	    }
		  
		searchTree ($node->{'next'}, $tmp_el_name, $tmp_attr, $tmp_value, $found_nodes_ref);
	}
}


sub is_LsubsetR(){
	my $left_hash  = shift;
	my $right_hash = shift;
	if ((keys(%$left_hash) == 0) || (keys(%$right_hash) ==0)){
		return 0;	
		
	}
	my $is_match=1;
	my $is_match_single;
	
	while(my($key, $value) = each(%$left_hash)){
		$is_match_single=0;
		while(my ($r_key,$r_value) = each(%$right_hash)){
			if(($key eq $r_key ) && ($value eq $r_value)){
				$is_match_single=1;
			}
		}
		$is_match = $is_match & $is_match_single;
	} 
	return $is_match;
}


1;