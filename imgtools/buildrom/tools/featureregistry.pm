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

# This package contains routines to read the information from the Feature registry XML file.
package featureregistry;  # Derived class implementation for feature registry xml file

BEGIN {
	@ISA = qw(featureparser); # Derived from featureparser
	require featureparser;
};

# Parse the featureregistry XML file and generate the maps and counts
#
#feature hash map:
# {<uid1>}{name}<name>
#		  {installable}<true\false> - optional
#

#
# Class constructor
#
sub new
{
	my $class = shift;
	my $object = $class->SUPER::new();
	
	# Class members
	$object->{_OBJNAME} = "FeatureRegistry";
	$object->{_FEAT_MAP} = {};           # Feature Info Hash map
	$object->{_FEAT_NAME_UID_MAP} = {};  # Hash map of feature name and uid
	return $object;
}

#
# Private methods
#

# Private method to Get/Set the _FEAT_MAP member value of this class
# @param : Feature Info Hash map (optional for GET)
#
my $featureHashMap = sub 
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"featureHashMap"));
	
	if (@_) 
	{ 
		$object->{_FEAT_MAP} = shift; 
	}
	return $object->{_FEAT_MAP};
};

#
# Public methods
#

# Get/Set the _FEAT_NAME_UID_MAP member value of this class
# @param : Hash map of feature name and uid (optional for GET)
#
sub featureNameUidMap 
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"featureNameUidMap"));
	
	if (@_) 
	{ 
		$object->{_FEAT_NAME_UID_MAP} = shift; 
	}
	return $object->{_FEAT_NAME_UID_MAP};
};


# Return the feature uid for the given feature name.
# @param : Feature Name
#
sub getFeatureUID
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getFeatureUID"));
	
	my $feature = shift;
	
	my $featureNameUidMap = $object->featureNameUidMap();
	$feature = lc($feature);
	if(exists $featureNameUidMap->{$feature}){
		return $featureNameUidMap->{$feature};
	}else{
		return undef;
	}
}

# Get the details of feature with given featureuid and other parameters
# This function only consider the feature UID only and that UID should be in decimal
# @param : Feature UID value
#
sub getFeatureInfo
{
	my $object = shift;
	return 0 if(!&featureparser::ISREF($object,"getFeatureInfo"));
	
	my $uid = shift;
	my $featureMap = $object->$featureHashMap();
	if(exists $featureMap->{$uid}) {
		return \%{$featureMap->{$uid}};
	}
	else {
		return undef;
	}
}

#
# Utility functions
#

# Update the feature hash map with the values from the xml feature registry file
#
sub createFeatureMap
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"createFeatureMap"));
	
	return 0 if($object->rootElement() < 0);
	
	# Get all <feature> Elements to @featureList
	my @featureList =  &featureparser::getnodefromTree($object->rootElement(), "features", "feature");

	if(@featureList)
	{
		my $featureNameUidMap = $object->featureNameUidMap();
		my $featureMap = $object->$featureHashMap();
		foreach my $node (@featureList)
		{		
			# Define local variables to hold attribute names and values for each $node
			my $uid_value = &featureparser::getattrValue($node, "uid");
			my $name_value = &featureparser::getattrValue($node, "name");
			
			# Validate Name
			if(!$name_value) {
				&featureparser::ERROR("Feature name attribute is empty");
				return 0;
			}
			
			# Validate UID
			if(&featureparser::IsValidNum($uid_value)) {
				$uid_value = &featureparser::ConvertHexToDecimal($uid_value);
			}
			else {
				&featureparser::ERROR("Valid hexadecimal or decimal value expected in UID entry for \"$name_value\"");
				return 0;
			}
			
			# Check the duplicate entry of feature
			if(exists $featureNameUidMap->{$name_value}) {
				&featureparser::ERROR("Feature entry \"".$name_value."\" already exists");
				return 0;
			}
			if(exists $featureMap->{$uid_value}) {
				&featureparser::ERROR("UID entry for \"".$name_value."\" already exists");
				return 0;
			}
			
			my $install_value = &featureparser::getattrValue($node, "installable");
			if ($install_value eq undef) {
				$install_value = "false";
			}

			# Store all key=values to global %featureHashMap & %featureNameUidMap
			$featureNameUidMap->{$name_value} = $uid_value;
			$featureMap->{$uid_value}{"name"} = &featureparser::getattrValue($node, "name",1);
			$featureMap->{$uid_value}{"installable"} = $install_value;
		}
		return 1;
	}
	
	return 0;
}

# Read the <defaultfeaturerange> element
#
sub createDefaultRangeMap
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"createDefaultRangeMap"));
	
	# Return error if the rootelement reference is NULL
	return 0 if($object->rootElement() < 0);
	
	# Get all the <defaultfeaturerange> elements
	my @attrSet =  &featureparser::getnodefromTree($object->rootElement(), "default", "range");
	
	# Add the defaultfeaturerange elements into the object
	return &featureparser::createDefaultRangeMap($object,@attrSet);
}

sub readRangeAttributes
{
	my ($object, $currNode, $range) = @_; 
	return 0 if(!&featureparser::ISREF($object,"readRangeAttributes"));	
	
	#Get the lower and higher uids
	$range->{min} = &featureparser::getattrValue($currNode, "min");
	$range->{max} = &featureparser::getattrValue($currNode, "max");

	#Read the support keyword
	$range->{support} = &featureparser::getattrValue($currNode, "support");
	
	#Read the installable element
	$range->{installable} = &featureparser::getattrValue($currNode, "installable");
}

1;