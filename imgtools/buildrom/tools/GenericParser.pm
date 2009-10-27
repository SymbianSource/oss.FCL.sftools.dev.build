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
# Provides generic methods retrieving data from the XML file.
# Internally uses DOM API. Uses XML Checker to validate the XML.
#

package genericparser;
require Exporter;
@ISA=qw(Exporter);

@EXPORT=qw(

	getRootElement
	getAttrValue
	getElementValue
	getSiblingElements
	getNodeAttributes
	getChildElements
	getNodeFromTree
	getElementsTagName
	getElementName
);

use strict;
use XML::DOM;
use XML::DOM::ValParser;#XML Validator

my $validxml; # XML validation status
$XML::Checker::FAIL = \&failhandler; # User defined fail handler

# User defined fail handler for the XML checker
sub failhandler
{
	my ($code, $msg, @context) = @_;
	print "ERROR: $msg\n";
	$validxml = 0;
}

#Returns the root element of the XML file
sub getRootElement() {
	my ($xmlfile) = shift;
	die "ERROR: XML File does not exists in the specified path $xmlfile\n" if (!-f $xmlfile);
	my $DOMParser = new XML::DOM::Parser(); #DOM Parser
	#Set the SGML_SEARCH_PATH to the path where the DTD files are found ($ENV{EPOCROOT}epoc32\\tools).
	XML::Checker::Parser::set_sgml_search_path ("$ENV{EPOCROOT}epoc32/tools");
	my $xmlValidator = new XML::Checker::Parser();#Validates XML against Schema
	$validxml = 1;
	$xmlValidator->parsefile($xmlfile);
	
	if($validxml)
	{
		my $document = $DOMParser->parsefile($xmlfile);#Parse XML file
		my $root = $document->getDocumentElement();
		return $root;
	}
	
	return 0;
}

#Returns the attribute value of the element
#Optional argument strictcaseflg does not convert the case of the attribute value
sub getAttrValue(){
	my ($elementname, $name, $strictcaseflg) = @_;
	my $attrVal =  $elementname->getAttribute($name) ;
	if ($attrVal eq "") {
  		return undef;
  	}
	if(!defined $strictcaseflg) {
		return lc($attrVal);
	}
	else {
		return $attrVal;
	}
}

#Returns the element value
#Optional argument strictcaseflg does not convert the case of the element value
sub getElementValue(){
	my ($elementname) = shift;
	my ($strictcaseflg)=shift;
	my $elementVal;
	if( !$elementname->hasChildNodes() )
	{
		return undef;
	}
	if ($elementname->getNodeType == XML::DOM::ELEMENT_NODE) {
		$elementVal =  $elementname->getFirstChild()->getData ;
	}
	
	if(!defined $strictcaseflg) {
		return lc($elementVal);
	}
	else {
		return $elementVal;
	}
}

#Returns the sibling elements for the given node
sub getSiblingElements {
	my $child = shift;
	my @nodeList;
	while($child) {
		if($child->getNodeType eq XML::DOM::ELEMENT_NODE) {
			@nodeList=(@nodeList,$child); 
		} 
		$child = $child->getNextSibling;
	}
	return 	@nodeList;
}

#Returns the attribute list reference for the given node
sub getNodeAttributes() {
	my $node = shift;
	my $attlist;
	if ($node->getNodeType() eq XML::DOM::ELEMENT_NODE)	{
		$attlist = $node->getAttributes;
	}
	return $attlist;
}

#Returns the children for the given node element
sub getChildElements {
	my $child = shift;
	my @childList;
	my @newChildList;	
		
	@childList=$child->getChildNodes;
	foreach my $node (@childList) {
		if($node->getNodeType eq XML::DOM::ELEMENT_NODE) {
			@newChildList=(@newChildList,$node); 
		}
	}
	return 	@newChildList;
}

#Returns the list of nodes that matches the specified node tree
sub getNodeFromTree(){

	my @resultNodes;
	my ($element, @nodeNames) = @_;
	my $nodeName;
	my @children = $element->getChildNodes();

	foreach my $child (@children) {
		if ($child->getNodeType eq XML::DOM::ELEMENT_NODE) {
			if (($child->getNodeName) eq $nodeNames[0]) {
				if ($#nodeNames) {
					$nodeName = shift @nodeNames;#Pop unmatched node
					push @resultNodes,&getNodeFromTree($child, @nodeNames);
					unshift @nodeNames, $nodeName;#Put back the nodes to proper level
				}
				else {
					push @resultNodes,$child;#Push matched node to the destination
				}
				
			}		

		}

	}
	
	return @resultNodes;
}

#Returns the list of elements whose node matches with the node name supplied
sub getElementsTagName{
	my ($node, $name) = @_;
	if ($node->getNodeType eq XML::DOM::ELEMENT_NODE) {
		my @taggedElements = $node->getElementsByTagName($name);
		return @taggedElements;
	}
}

#Returns the element name for the given node
sub getElementName{
	my $node = shift;
	if ($node->getNodeType eq XML::DOM::ELEMENT_NODE) {
		return lc($node->getNodeName);
	}
}

1;