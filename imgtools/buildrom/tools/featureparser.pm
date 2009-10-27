#
# Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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

# This package contains routines to read the information from the Feature List XML file.
package featureparser;  # Base class implementation of feature list xml parser

# Include the genericparser to use API to read from XML file.
use genericparser;
use strict;

#
# Class constructor
#
sub new {
	my $class = shift;

	my $object = {};
	
	# Class members
	$object->{_DEFAULT_RANGE} = [];        # Array of default ranges
	$object->{_DEFAULT_INCLUDE_COUNT} = 0;       # Default include range count
	$object->{_DEFAULT_EXCLUDE_COUNT} = 0;       # Default exclude range count
	
	$object->{_FILENAME} = undef;      # Current xml file parsing
	$object->{_ROOT_ELEMENT} = undef;  # Root element pointer of current xml file
	
	bless($object, $class);
	return $object;
}

#
# Public methods
#

# Get/Set the _DEFAULT_RANGE member value of this class
# @param : array of default ranges (optional for GET)
#
sub defaultRangeList 
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(defaultRangeList)));
	
	if (@_)
	{ 
		$object->{_DEFAULT_RANGE} = shift; 
	}
	return $object->{_DEFAULT_RANGE};
}

# Get/Set the _DEFAULT_INCLUDE_COUNT member value of this class
# @param : default include feature count (optional for GET)
#
sub defaultIncludeCount
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(defaultIncludeCount)));
	
	if (@_)
	{ 
		$object->{_DEFAULT_INCLUDE_COUNT} = shift; 
	}
	return $object->{_DEFAULT_INCLUDE_COUNT};
}

# Get/Set the _DEFAULT_EXCLUDE_COUNT member value of this class
# @param : default exclude feature count (optional for GET)
#
sub defaultExcludeCount 
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(defaultExcludeCount)));
	
	if (@_) 
	{ 
		$object->{_DEFAULT_EXCLUDE_COUNT} = shift; 
	}
	return $object->{_DEFAULT_EXCLUDE_COUNT};
}

# Get/Set the _FILENAME member value of this class
# @param : xml file name (optional for GET)
#
sub fileName 
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(fileName)));
	
	if (@_) 
	{ 
		$object->{_FILENAME} = shift; 
	}
	return $object->{_FILENAME};
}

# Get/Set the _ROOT_ELEMENT member value of this class
# @param : root element document pointer (optional for GET)
#
sub rootElement 
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(rootElement)));
	
	if (@_) 
	{ 
		$object->{_ROOT_ELEMENT} = shift; 
	}
	return $object->{_ROOT_ELEMENT};
}

# Parse the feature xml file
# @param : xml file name to parse
#
sub parseXMLFile 
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(parseXMLFile)));
	
	my $file = shift; # Get the featuredatabase XML filename
	$object->fileName($file);
	
	# Check for the existence of xml file
	if(!(-e $file)) 
	{
		ERROR($file." doesn\'t exist");
		return 0;
	}
	
	#Parse the file and Get root Element
	my $root = &genericparser::getRootElement($file);
	$object->rootElement($root);
	
	if($root)
	{
		#Read the <featureset>/<feature> elements
		if( !($object->createFeatureMap()) ) 
		{
			return 0;
		}
		#Read the <defaultfeaturerange> elements
		if( !($object->createDefaultRangeMap()) ) 
		{
			return 0;
		}
		
		return 1;
	}

	return -1;
}

# Read the <defaultfeaturerange> elements
# @param - input range attribute set
#
sub createDefaultRangeMap
{
	my ($object, @attrSet) = @_; 
	return 0 if(!&ISREF($object,"createDefaultRangeMap"));
	
	# Get the reference to the default feature range list from the object
	my $rangeList = $object->defaultRangeList();
	foreach my $currNode (@attrSet)
	{
		my ($min, $max);
		my %attrHashMap = ();

		# Get the range attributes
		$object->readRangeAttributes($currNode, \%attrHashMap);
		
		#Get the lower and higher uids
		$min = $attrHashMap{min};
		$max = $attrHashMap{max};
		
		#Validate it
		if((!&IsValidNum($min)) or (!&IsValidNum($max))) {
			&ERROR("Valid hexadecimal or decimal value expected in default range");
			return 0;
		}

		#Convert it to decimal
		$attrHashMap{min} = &ConvertHexToDecimal($min);
		$attrHashMap{max} = &ConvertHexToDecimal($max);
		if( $attrHashMap{min} > $attrHashMap{max} ) {
			&ERROR("Mininum/Lower UID value ".$min." is greater than Maximum/Higher UID value ".$max);
			return 0;
		}
	
		#Add it to the existing range list
		my $include = 1;
		foreach my $node (@$rangeList) { #Check the range already exists
			if(($node->{min} == $attrHashMap{min}) && ($node->{max} == $attrHashMap{max}) 
				&& ($node->{support} eq $attrHashMap{support})) {
				$include = 0;
			}
		}
		if($include) { # If it is a new range attribute then add it to the list
			push @$rangeList, \%attrHashMap;
			$object->defaultIncludeCount($object->defaultIncludeCount()+1) if(lc($attrHashMap{support}) eq "include");
			$object->defaultExcludeCount($object->defaultExcludeCount()+1) if(lc($attrHashMap{support}) eq "exclude");
		}
	}

	return 1;
}

# Get the default include ranges of min and max values in 2dimensional array
#
sub getDefaultIncludeInfo()
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(getDefaultIncludeInfo)));
	
	my @result;	
	my %tempHash=();
	
	my $rangeList = $object->defaultRangeList();
	foreach my $range (@$rangeList)
	{
		if(lc($range->{"support"}) eq "include" )
		{
			my $min_value=$range->{"min"};
			my $max_value=$range->{"max"};
			$tempHash{$min_value} = $max_value;
		}				
	}

	my $index = 0;
	my @sortedHash = sort keys %tempHash;

	foreach my $key (@sortedHash)
	{
		push @{$result[$index]},$key;
		push @{$result[$index]},$tempHash{$key};	
		$index++;
	}	
	return @result;
}

# Get the default exclude ranges of min and max values in 2dimensional array
#
sub getDefaultExcludeInfo()
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(getDefaultExcludeInfo)));
	
	my @result;
	my %tempHash=();
	
	my $rangeList = $object->defaultRangeList();
	foreach my $range (@$rangeList)
	{
		if(lc($range->{"support"}) eq "exclude" )
		{
			my $min_value=$range->{"min"};
			my $max_value=$range->{"max"};
			$tempHash{$min_value} = $max_value;
		}				
	}

	my $index = 0;
	my @sortedHash = sort {$a <=> $b}(keys %tempHash);
	foreach my $key (@sortedHash){
		push @{$result[$index]},$key;
		push @{$result[$index]},$tempHash{$key};
		$index++;
	}
	return @result;
}

# Get the count of total number of ranges that are either included or excluded on the device as default
# 
sub getDefaultTotalCount()
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(getDefaultTotalCount)));
	
	return ($object->defaultIncludeCount() + $object->defaultExcludeCount());
}

# For a given uid value, this function checks if the given uid is within the default=present range.
# @param : UID to check
#
sub getRangeEntry
{
	my $object = shift; 
	return 0 if(!&ISREF($object,qw(getRangeEntry)));
	
	my $aUid = shift;
	my $length = $object->getDefaultTotalCount();
	my $pos = 0;
	my $rangeRef;

	my $rangeList = $object->defaultRangeList();
	foreach my $range (@$rangeList)
	{
		if ( (lc($range->{"support"}) eq "include") and ($range->{"min"} <= $aUid) and ($range->{"max"} >= $aUid) )
		{
			return $range;
		}
	}
	return undef;
}

# Get the list of features
#
sub getFeatures($$)
{
	my ($includeFeatureRef, $excludeFeatureRef) = @_;
	my %FeatureMap = ();
	my @FeatList = ();
	my $featRef;
	my $uid;

	foreach my $feat (@$excludeFeatureRef)
	{
		$uid = $feat->{uid};

		$featRef = $FeatureMap{$uid};

		if( $featRef->{include} == 1 )
		{
			&ERROR("The feature $feat->{name} was added into the exclude as well as include list");
			return 0;
		}
		elsif($featRef->{exclude} == 1)
		{
#			Already added to the final feature list
			next;
		}
		else
		{
			$FeatureMap{$uid} = $feat;
			push @FeatList, $feat;
		}
	}

	foreach my $feat (@$includeFeatureRef)
	{
		$uid = $feat->{uid};

		$featRef = $FeatureMap{$uid};

		if( $featRef->{exclude} == 1 )
		{
			&ERROR("The feature $feat->{name} was added into the exclude as well as include list");
			return 0;
		}
		elsif($featRef->{include} == 1)
		{
#			Already added to the final feature list
			next;
		}
		else
		{
			$FeatureMap{$uid} = $feat;
			push @FeatList, $feat;
		}
	}

	return \@FeatList;
}

# ========================================================================
# Wrappers for generic xml parser
# ========================================================================
sub featureparser::getnodefromTree 
{ 
	&genericparser::getNodeFromTree(@_); 
}

sub getattrValue 
{ 
	&genericparser::getAttrValue(@_); 
}

sub getelementValue 
{ 
	&genericparser::getElementValue(@_); 
}

# ========================================================================
# Utility sub routines
# ========================================================================
# Check whether the object is reference type
# @param : the object reference
#
sub ISREF 
{
	my ($object, $method) = @_;
	if(!ref($object)) 
	{ 
		&ERROR("**Object is not reference-type for the method($method)");
		return 0;
	}
	return 1;
}

# Parser debugging routines
#
sub WARN 
{ 
	print "WARNING: ".$_[0]."\n";
}
sub ERROR 
{ 
	print "ERROR: ".$_[0]."\n";
}

# Return Decimal value for the given Hexadecimal number.
# @param : HexaDecimal Value
#
sub ConvertHexToDecimal 
{
	my $val = shift;
	if(grep /^0x/i, $val) 
	{
		# Input is Hexadecimal value, convert to Decimal
		return hex($val);	 
	}
	else 
	{
		# Decimal value
		return $val;
	}
}

# Validate if the given value is a valid number
#
sub IsValidNum 
{
	my $num = shift;
	return 1 if($num =~ /^\d+$|^0[x][\da-f]+/i);
	return 0;
}

# Validate if the given UID value is a valid number (either decimal or hexadecimal number)
#
sub ValidateUIDValue 
{
	my $fuid = shift;
	# check to ensure that uid value contains only valid digits (decimal/hexadecimal)
	if(IsValidNum $fuid) 
	{
		return 1;
	}
	else 
	{
		&ERROR("Invalid UID value".$fuid."\n");
		return 0;
	}
}

1;