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

# This package contains routines to read the information from the Feature manager XML file.
package featuremanager; # Derived class for the feature manager xml parser

BEGIN {
	@ISA = qw(featureparser); # Derived from featuerParser
	require featureparser;
};

use constant STRICTCASE=>1; # To suppress the case conversion in genericparser routine

# Parse the featuredatabase XML file and generate the maps and counts
#
#featureset:
# {namespace}<namespace> - optional
# {ibyname}<ibyname> - optional
# {hfilename}<hfilename> - optional
# {hfileheader}<fileheader> - optional
# {interfacestatus}<interfacestatus> -optional
# {interfacevisibility}<interfacevisibility> - optional
# {feature_list}<nameuidmap>
# {feature} {<uid1>}{statusflags}<statusflag>
#					{name}<name>
#					{userdata}<userdata> - optional
#					{includemacro}<macro>
#					{excludemacro}<macro>
#					{infeaturesetiby}<yes/no> - optional
#					{comment}<comment> - optional
#			{<uid2>}{statusflags}<statusflag>
#					{name}<name>
#					{userdata}<userdata> - optional
#					{includemacro}<macro>
#					{excludemacro}<macro>
#					{infeaturesetiby}<yes/no> - optional
#					{comment}<comment>
#

#
# Class constructor
#
sub new
{
	my $class = shift;
	my $object = $class->SUPER::new();
	
	# Class members
	$object->{_OBJNAME} = "FeatureManager"; # Name of the object
	$object->{_FEAT_SET_LIST} = [];  # Array of <featureset> hash maps
	$object->{_FEAT_LIST} = {};      # Hash map of all feature name with uid
	$object->{_ALIAS_FEAT_LIST} = {}; # Hash map of all alias feature name with uid
	return $object;
}

#
# Private methods
#

# Private method to Get/Set the _FEAT_SET_LIST member value of this class
# @param : reference to the array of <featureset> hash maps (optional for GET)
#
my $featuresetList = sub 
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"featuresetList"));
	
	if (@_) 
	{ 
		$object->{_FEAT_SET_LIST} = shift; 
	}
	return $object->{_FEAT_SET_LIST};
};

# Private method to Get/Set the _FEAT_LIST member value of this class
# @param : reference to the fash map of feature name with uid (optional for GET)
#
my $featureList = sub 
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"featureList"));
	
	if (@_) 
	{ 
		$object->{_FEAT_LIST} = shift; 
	}
	return $object->{_FEAT_LIST};
};
# Private method ot Get/Set the _ALIAS_FEAT_LIST member value of this class
# @param: reference to the hash map of alias feature name with uid
my $aliasfeatureList = sub
{
	my $object = shift;
	return 0 if(!&featureparser::ISREF($object, "aliasfeatureList"));

	if(@_)
	{
		$object->{_ALIAS_FEAT_LIST} = shift;
	}
	return $object->{_ALIAS_FEAT_LIST};
};

# Read the attributes of <featureset> element
# @param : reference to the featureset
# @param : reference to the attributemap
#
my $fillFeatureSetAttributes = sub 
{
	my  $node = shift;
	my  $map = shift;
	$map->{ibyname} = &featureparser::getattrValue($node, "ibyname", STRICTCASE);
	$map->{hfilename} = &featureparser::getattrValue($node, "hfilename", STRICTCASE);
	$map->{namespace} = &featureparser::getattrValue($node, "namespace", STRICTCASE);
};

# Read the attributes of <hfileheader> element
# @param : reference to the featureset
# @param : reference to the attributemap
#
my $fillFileHeaderAttributes = sub 
{
	my $node = shift;
	my $map = shift;
	my @attribSet =  &featureparser::getnodefromTree($node, "hfileheader");
	
	foreach my $att_node (@attribSet) 
	{
		$map->{interfacestatus} = &featureparser::getattrValue($att_node, "interfacestatus",STRICTCASE);
		$map->{interfacevisibility} = &featureparser::getattrValue($att_node, "interfacevisibility",STRICTCASE);
		$map->{hfileheader} = &featureparser::getelementValue($att_node,STRICTCASE);
	}
};

# Read the attributes of <feature> element
# @param : reference to the featureset
# @param : reference to the attributemap
#
my $fillFeatureAttributes = sub 
{
	my $node = shift; my $map = shift;
	
	my @attribSet =  &featureparser::getnodefromTree($node, "feature");
	
	my %nameUidMap = ();
	foreach my $att_node (@attribSet)
	{
		my ($uid_value, $feat_name, $attval);
		my (@macroSet, @commentSet);
		my %featureHash = ();
		
		#Read the feature name and its other attributes
		$feat_name = &featureparser::getattrValue($att_node, "name",STRICTCASE);
		
		# Validate Name
		if(!$feat_name) {
			&featureparser::ERROR("Feature name attribute is empty");
			return 0;
		}
		if(exists $nameUidMap{lc($feat_name)}) {
			&featureparser::ERROR("Feature entry \"".$feat_name."\" already exists");
			return 0;
		}
		
		#Read the uid value
		$uid_value = &featureparser::getattrValue($att_node, "uid");
		if(!&featureparser::IsValidNum($uid_value)) {
			&featureparser::ERROR("Valid hexadecimal or decimal value expected in UID entry for \"$feat_name\"");
			return 0;
		}
		$uid_value = &featureparser::ConvertHexToDecimal($uid_value);
		if((defined $map->{feature}) && (exists $map->{feature}{$uid_value})) {
			&featureparser::ERROR("UID entry for \"".$feat_name."\" already exists");
			return 0;
		}
		
		$attval = &featureparser::getattrValue($att_node, "statusflags");
		if(!&featureparser::IsValidNum($attval)) {
			&featureparser::ERROR("Valid hexadecimal or decimal value expected in STATUS_FLAGS entry for \"$feat_name\"");
			return 0;
		}
		$featureHash{statusflags} = $attval;
		
		$attval = &featureparser::getattrValue($att_node, "userdata");
		if(defined $attval) {
			if(!&featureparser::IsValidNum($attval)) {
				&featureparser::ERROR("Valid hexadecimal or decimal value expected in USER_DATA entry for \"$feat_name\"");
				return 0;
			}
		}
		$featureHash{name} = $feat_name;
		$featureHash{userdata} = $attval;
		
		#Read the attributes of <hrhmacro> element
		@macroSet = &featureparser::getnodefromTree($att_node, "hrhmacro");
		foreach my $nodeMac (@macroSet) {
			$featureHash{includemacro} = &featureparser::getattrValue($nodeMac,"include",STRICTCASE);
			$featureHash{excludemacro} = &featureparser::getattrValue($nodeMac,"exclude",STRICTCASE);
			
			#Read the attribute infeaturesetiby
			$attval = &featureparser::getattrValue($nodeMac,"infeaturesetiby");
			if(($attval eq undef) or (lc($attval) eq "yes")) {
				$featureHash{infeaturesetiby} = 1;
			}
			elsif(lc($attval) eq "no") {
				$featureHash{infeaturesetiby} = 0;
			}
			else {
				&featureparser::ERROR("(yes|no) value expected in infeaturesetiby attribute for \"$feat_name\"");
				return 0;
			}
		}
		
		#Read the <comment> element value
		@commentSet = &featureparser::getnodefromTree($att_node, "comment");
		foreach my $nodeCmt (@commentSet) {
			$featureHash{comment} =  &featureparser::getelementValue($nodeCmt,STRICTCASE);
		}
		
		#Add an entry to name->uid map for this feature
		$nameUidMap{lc($feat_name)} = $uid_value;
		#Add an entry to the global hash map with all the attributes of this feature
		$map->{feature}{$uid_value} = \%featureHash;
	}
	
	$map->{feature_list} = \%nameUidMap;
	
	return 1;
};
my $fillAliasAttributes = sub
{
	my $node = shift;
	my $map = shift;
	my %aliasnameUidMap = ();
	my $featureList = $map->{feature_list};
	my @attribSet = &featureparser::getnodefromTree($node, "featureoverride");
	foreach my $att_node (@attribSet)
	{
		my ($uid_value, $alias_name, $feat_name, $attval);
		my (@macroSet, @commentSet);
		my %featureHash = ();
		#read the alias name 
		$alias_name = &featureparser::getattrValue($att_node, "name", STRICTCASE);
		if(!$alias_name)
		{
			&featureparser::ERROR("Featureoverride name attribute is empty");
			return 0;
		}
		if(exists $featureList->{lc($alias_name)})
		{
			&featureparser::ERROR("Can't override <feature> \"".sprintf("0x%08x", $featureList->{lc($alias_name)})."\" in the same <featureset>");
			return 0;
		}
		if(exists $aliasnameUidMap{lc($alias_name)})
		{
			&featureparser::ERROR("Can't override <featureoverride> \"".sprintf("0x%08x", $aliasnameUidMap{lc($alias_name)})."\" in the same <featureset>");
			return 0;
		}
		$uid_value = &featureparser::getattrValue($att_node, "uid");
		if(!&featureparser::IsValidNum($uid_value))
		{
			&featureparser::ERROR("Valid hexadecimal or decimal value expected in UID entry for \"$alias_name\"");
			return 0;
		}
		$uid_value = &featureparser::ConvertHexToDecimal($uid_value);
		if((defined $map->{alias_feature}) && (exists $map->{alias_feature}{$uid_value}))
		{
			&featureparser::ERROR("Can't override <featureoverride> \"".sprintf("0x%08x", $uid_value)."\" in the same <featureset>");
			return 0;
		}
		if((defined $map->{feature}) && (exists $map->{feature}{$uid_value}))
		{
			&featureparser::ERROR("Can't override <feature> \"".sprintf("0x%08x", $uid_value)."\" in the same <featureset>");
			return 0;
		}
		$attval = &featureparser::getattrValue($att_node, "statusflags");
		if(defined $attval)
		{
			if(!&featureparser::IsValidNum($attval))
			{
				&featureparser::ERROR("Valid hexadecimal or decimal value expected in STATUS_FLAGS entry for \"$alias_name\"");
				return 0;
			}
		}
		$featureHash{statusflags} = $attval;

		$attval = &featureparser::getattrValue($att_node, "userdata");
		if(defined $attval)
		{
			if(!&featureparser::IsValidNum($attval))
			{
				&featureparser::ERROR("Valid hexadecimal or decimal value expected in USER_DATA entry for \"$alias_name\"");
				return 0;
			}
		}

		$featureHash{uid} = $uid_value;
		$featureHash{name} = $alias_name;
		$featureHash{userdata} = $attval;
		#read the attributes of <hrhmacro> element
		@macroSet = &featureparser::getnodefromTree($att_node,"hrhmacro");
		foreach my $nodeMac (@macroSet) 
		{
			$featureHash{includemacro} = &featureparser::getattrValue($nodeMac, "include", STRICTCASE);
			$featureHash{excludemacro} = &featureparser::getattrValue($nodeMac, "exclude", STRICTCASE);
			#read the attribute infeaturesetiby
			$attval = &featureparser::getattrValue($nodeMac, "infeaturesetiby");
			if(($attval eq undef) or (lc($attval) eq "yes"))
			{
				$featureHash{infeaturesetiby} = 1;
			}
			elsif(lc($attval) eq "no")
			{
				$featureHash{infeaturesetiby} = 0;
			}
			else
			{
				&featureparser::ERROR("(yes|no) value expected in infeaturesetiby attribute for \"$feat_name\"");
				return 0;
			}
		}
		#read the <comment> element value
		@commentSet = &featureparser::getnodefromTree($att_node, "comment");
		foreach my $nodeCmt (@commentSet)
		{
			$featureHash{comment} = &featureparser::getelementValue($nodeCmt, STRICTCASE);
		}
		#add an entry to alias->uid map for this feature
		$aliasnameUidMap{lc($alias_name)} = $uid_value;
		#add an entry to the global hash map with all the attributes of this alias feature
		$map->{alias_feature}{$uid_value} = \%featureHash;
	}
	$map->{alias_feature_list} = \%aliasnameUidMap;

	return 1;
};

#
# Public methods
#

sub getAliasFeatureList
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getAliasFeatureList"));
	
	my $aliasfeatlist = $object->$aliasfeatureList();
	return $aliasfeatlist;
}
# To get the status flag attribute value of the given feature
# @param : feature name
#
sub getStatusFlag
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getStausFlag"));
	
	my $name = shift;
	my $namespace = shift;
	my $uid = $object->getFeatureUID($name, $namespace);
	if($uid)
	{
		my $feature = $object->getFeatureInfo($uid, $namespace);
		
		return ($feature->{statusflags}) if(exists $feature->{statusflags});
	}
	
	return undef;
}

# To get the user data attribute value of the given feature
# @param : feature name
#
sub getUserData
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getUserData"));
	
	my $name = shift;
	my $namespace = shift;
	my $uid = $object->getFeatureUID($name, $namespace);
	if($uid)
	{
		my $feature = $object->getFeatureInfo($uid, $namespace);
		
		return ($feature->{userdata}) if(exists $feature->{userdata});
	}
	
	return undef;
}

# To get the include macro attribute value of the given feature
# @param : feature name
#
sub getIncludeMacro
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getIncludeMacro"));
	
	my $name = shift;
	my $uid = $object->getfeatureUID($name);
	if($uid)
	{
		my $feature = $object->getfeatureInfo($uid);
		return $feature->{includemacro};
	}
	
	return undef;
}

# To get the exclude macro attribute value of the given feature
# @param : feature name
#
sub getExcludeMacro
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getExcludeMacro"));
	
	my $name = shift;
	my $uid = $object->getfeatureUID($name);
	if($uid)
	{
		my $feature = $object->getfeatureInfo($uid);
		return $feature->{excludemacro};
	}
	
	return undef;
}

# Return the feature uid for the given feature name.
# @param : Feature Name
# @param : namespace of the featureset (optional)
#
sub getFeatureUID
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getFeatureUID"));
	
	my $feature = shift;
	my $namespace = shift;
	my $featuresetList = $object->$featuresetList;
	
	$feature = lc($feature);
	if($namespace eq undef)	{
		if(exists $$featuresetList[0]->{feature_list}{$feature}) {
			return $$featuresetList[0]->{feature_list}{$feature};
		}
		if(exists $$featuresetList[0]->{alias_feature_list}{$feature}) {
			return $$featuresetList[0]->{alias_feature_list}{$feature};
		}
	}
	else {
		foreach my $node (@$featuresetList)
		{
			if((lc($node->{namespace}) eq lc($namespace)) && ((exists $node->{feature_list}{$feature})||(exists $node->{alias_feature_list}{$feature}))) {
				return $node->{feature_list}{$feature} if (exists $node->{feature_list}{$feature});
				return $node->{alias_feature_list}{$feature} if (exists $node->{alias_feature_list}{$feature});
			}
		}
	}
	foreach my $node (@$featuresetList) {
		return $node->{feature_list}{$feature} if(exists $node->{feature_list}{$feature});
		return $node->{alias_feature_list}{$feature} if(exists $node->{alias_feature_list}{$feature});
	}
	return undef;
}

# Get the details of feature with given featureuid and other parameters
# This function only consider the feature UID only and that UID should be in decimal
# @param : Feature UID
# @param : namespace of the featureset (optional)
#
sub getFeatureInfo
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getFeatureInfo"));
	
	my $uid = shift;
	my $namespace = shift;
	my $featuresetList = $object->$featuresetList;

	if($namespace eq undef)	{
		foreach my $node (@$featuresetList) {
			return $node->{alias_feature}{$uid} if(exists $node->{alias_feature}{$uid});
		}
		if(exists $$featuresetList[0]->{feature}{$uid}) {
			return $$featuresetList[0]->{feature}{$uid};
		}
		if(exists $$featuresetList[0]->{alias_feature}{$uid}) {
			return $$featuresetList[0]->{alias_feature}{$uid};
		}
	}
	else {
		foreach my $node (@$featuresetList)
		{
			if((lc($node->{namespace}) eq lc($namespace)) && ((exists $node->{feature}{$uid})||(exists $node->{alias_feature}{$uid}))) {
				return $node->{feature}{$uid} if (exists $node->{feature}{$uid});
				return $node->{alias_feature}{$uid} if (exists $node->{alias_feature}{$uid});
			}
		}
	}
	foreach my $node (@$featuresetList) {
		return $node->{feature}{$uid} if(exists $node->{feature}{$uid});
	}
	return undef;
}


# Get the Feature set info as a hash
# @param: namespace of the featureset
#
sub getFeaturesetInfo 
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getFeaturesetInfo"));
	
	my $namespace = shift;
	
	my $featuresetList = $object->$featuresetList;
	if($namespace eq undef)	{
		if(exists $$featuresetList[0]) {
			return $$featuresetList[0];
		}
	}
	else {
		foreach my $node (@$featuresetList)
		{
			if((lc($node->{namespace}) eq lc($namespace))) {
				return $node;
			}
		}
	}
	return undef;
}

# Get the Featureset namespaces as an array
#
sub getFeatureset
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"getFeatureset"));
	
	my @featureSet=();
	
	my $featuresetList = $object->$featuresetList;
	foreach my $node (@$featuresetList) {
		push @featureSet, $node;
	}
	return \@featureSet;
}

# Add feature registry object contents to feature manager object
# @param : feature registry object
#
sub addFeatureRegistry
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"addFeatureRegistry"));
	
	my $registryobj = shift;
	my %attribHash = ();
	my $nameuidmap;
	my $newRangeList;
	my $rangeList;
	
	# Adding default range list
	$newRangeList = $registryobj->defaultRangeList();
	$rangeList = $object->defaultRangeList();

	foreach my $newnode (@$newRangeList) {
		my $include = 1;
		foreach my $node (@$rangeList) { #Check if the range is already exists
			if(($node->{min} == $newnode->{min}) && ($node->{max} == $newnode->{max}) 
				&& ($node->{support} eq $newnode->{support})) {
				$include = 0;
			}
		}
		
		if($include) { # Add it if it is new range
			push @$rangeList, $newnode;
			$object->defaultIncludeCount($object->defaultIncludeCount()+1) if(lc($newnode->{support}) eq "include");
			$object->defaultExcludeCount($object->defaultExcludeCount()+1) if(lc($newnode->{support}) eq "exclude");
		}
	}
	
	# Adding feature list
	$nameuidmap = $registryobj->featureNameUidMap();
	$attribHash{namespace} = undef;
	$attribHash{feature_list} = $nameuidmap;
	
	foreach my $name (keys %$nameuidmap) {
		my $uid = $nameuidmap->{$name};
		my %featureinfo = ();
		
		$featureinfo{name} = $name;
		# Default values for statusflags and userdata
		$featureinfo{statusflags} = "0x00000001";
		$featureinfo{userdata} = "0x00000000";
		
		$attribHash{feature}{$uid} = \%featureinfo;
	}
	
	# add the featureset into the feature manager object
	return 0 if(! &addFeatureSet($object, \%attribHash));

	return 1;
}

#
# Utility functions
#
# Add the featureset into the hash map
# @param : reference to the atrribute hash map of featureset
#
sub addFeatureSet
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"addFeatureSet"));
	
	my $newSet = shift;
	my $featSetList = $object->$featuresetList();
	my $newfeatList = $newSet->{feature_list};
	my $newaliasfeatList = $newSet->{alias_feature_list};

	# Check for the duplicate featue names in the existing list
	foreach my $name (keys %$newfeatList)
	{
		if(exists $object->$featureList()->{$name})
		{
			&featureparser::ERROR("\(".$object->fileName()."\) Feature \"".uc($name)."\" already exists");
			return 0;
		}
		else
		{
			my $uid = $newfeatList->{$name};
			$object->$featureList()->{$name} = $uid; #Add it to global featue name list
		}
	}
	
	# Check for the duplicate UIDs in the existing list
	if(@$featSetList) 
	{	
		foreach my $set (@$featSetList)
		{
			foreach my $name (keys %$newfeatList)
			{
				my $uid = $newfeatList->{$name};
				if(exists $set->{feature}{$uid})
				{
					&featureparser::ERROR("\(".$object->fileName()."\) UID \"".sprintf("0x%08x",$uid)."\" for the feature \"".uc($name)."\" already exists");
					return 0;
				}
			}
		}
	}
	#check for the duplicate alias feature names in the existing list
	foreach my $alias_name (keys %$newaliasfeatList)
	{
		if(exists $object->$featureList()->{$alias_name})
		{
			&featureparser::ERROR("\(".$object->fileName."\) Can't override <feature> \"".sprintf("0x%08x", $newaliasfeatList->{$alias_name})."\" with the same feature name ".$alias_name);
			return 0;

		}
		if(exists $object->$aliasfeatureList()->{$alias_name})
		{
			&featureparser::ERROR("\(".$object->fileName."\) Can't override <featureoverride> \"".sprintf("0x%08x", $newaliasfeatList->{$alias_name})."\" with the same feature name ".$alias_name);
			return 0;
		}
		else
		{
			my $uid = $newaliasfeatList->{$alias_name};
			# add it to global alias feature name list
			$object->$aliasfeatureList()->{$alias_name} = $uid;
		}
	}
	#check if the original feature has existed in other feature set.
	foreach my $alias_name (keys %$newaliasfeatList)
	{
		my $featHash;
		my $uid = $newaliasfeatList->{$alias_name};
		foreach my $set (@$featSetList)
		{
			if(exists $set->{feature}{$uid})
			{
				$featHash = $set->{feature}{$uid};
				last;
			}
			if(exists $set->{alias_feature}{$uid})
			{
				$featHash = $set->{alias_feature}{$uid};
				last;
			}
		}
		if(!$featHash)
		{
			&featureparser::ERROR("original feature definition does not exist.");
			return 0;
		}

		my $aliasfeatHash = $newSet->{alias_feature}{$uid};

		if(($aliasfeatHash->{includemacro}) || ($aliasfeatHash->{excludemacro}))
		{
			if(($featHash->{includemacro}) || ($featHash->{excludemacro}))
			{
				&featureparser::WARN("the value of attribute hrhmacro has been overrided in ogrinal feature ".sprintf("0x%08x", $uid));
				undef $featHash->{includemacro};
				undef $featHash->{excludemacro};
			}
		}
		elsif($featHash->{includemacro} || $featHash->{excludemacro})
		{
			&featureparser::WARN("the original value of attribute hrhmacro will be used for featureoverride ".sprintf("0x%08x", $uid));
			$aliasfeatHash->{includemacro} = $featHash->{includemacro};
			$aliasfeatHash->{excludemacro} = $featHash->{excludemacro};
		}
		if($aliasfeatHash->{statusflags})
		{
			if(($featHash->{statusflags}) && !($aliasfeatHash->{statusflags} eq $featHash->{statusflags}))
			{
				&featureparser::WARN("the value of attribute statusflags has been overrided in ogrinal feature ".sprintf("0x%08x", $uid));
			}
		}
		elsif($featHash->{statusflags})
		{
			$aliasfeatHash->{statusflags} = $featHash->{statusflags};
			&featureparser::WARN("the original value of attribute statusflags will be used for featureoverride ".sprintf("0x%08x", $uid));
		}
		if($aliasfeatHash->{userdata})
		{
			if(($featHash->{userdata}) && !($aliasfeatHash->{userdata} eq $featHash->{userdata}))
			{
				&featureparser::WARN("the value of attribute userdata has been overrided in ogrinal feature ".sprintf("0x%08x", $uid));
			}
		}
		elsif($featHash->{userdata})
		{
			$aliasfeatHash->{userdata} = $featHash->{userdata};
			&featureparser::WARN("the original value of attribute userdata will be used for featureoverride ".sprintf("0x%08x", $uid));
		}
		if($aliasfeatHash->{infeaturesetiby})
		{
			if(($featHash->{infeaturesetiby}) && ($aliasfeatHash->{infeaturesetiby} != $featHash->{infeaturesetiby}))
			{
				&featureparser::WARN("the value of attribute infeautresetiby has been overrided in ogrinal feature ".sprintf("0x%08x", $uid));
			}
		}
		elsif(defined($featHash->{infeaturesetiby}))
		{
			$aliasfeatHash->{infeaturesetiby} = $featHash->{infeaturesetiby};
			&featureparser::WARN("the original value of attribute infewaturesetiby will be used for featureoverride ".sprintf("0x%08x", $uid));
		}
	}
	# Add the unique featureset into the list
	push @$featSetList, $newSet;
	return 1;
}

# Read the <featureset> element
# 
sub createFeatureMap
{
	my $object = shift; 
	return 0 if(!&featureparser::ISREF($object,"createFeatureMap"));
	
	# Return error if the rootelement reference is NULL
	return 0 if($object->rootElement() < 0);
	
	# Get all the <featureset> elements
	my @attrSet =  &featureparser::getnodefromTree($object->rootElement(), "featureset");
	
	if(@attrSet)
	{
		foreach my $currNode (@attrSet)
		{
			my %attrHashMap = ();
			
			# Get the <featureset> attributes
			$fillFeatureSetAttributes->($currNode,\%attrHashMap);
			# Get the <hfileheader> attributes
			$fillFileHeaderAttributes->($currNode,\%attrHashMap);
			
			# Get the <feature> attributes
			return 0 if( !($fillFeatureAttributes->($currNode,\%attrHashMap)) );
			# Get the <alias> attributes
			return 0 if( !($fillAliasAttributes->($currNode, \%attrHashMap)) );
			
			# Add the featureset into the object
			if(! &addFeatureSet($object,\%attrHashMap))
			{
				return 0;
			}
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
	my @attrSet =  &featureparser::getnodefromTree($object->rootElement(), "defaultfeaturerange");
	
	# Add the defaultfeaturerange elements into the object
	return &featureparser::createDefaultRangeMap($object,@attrSet);
}

# Read the attributes of the <defaultfeaturerange> element
# @param - <defaultfeaturerange> node reference
# @param - reference to the range attributes
#
sub readRangeAttributes
{
	my ($object, $currNode, $range) = @_; 
	my @commentSet;
	return 0 if(!&featureparser::ISREF($object,"readRangeAttributes"));	
	
	#Get the lower and higher uids
	$range->{min} = &featureparser::getattrValue($currNode, "loweruid");
	$range->{max} = &featureparser::getattrValue($currNode, "higheruid");

 	#Always supported/included for FM. Keep this value for compatible with FR
 	$range->{support} = "include";
	#Read the <comment> element
	@commentSet = &featureparser::getnodefromTree($currNode, "comment");
	foreach my $node (@commentSet) {
		$range->{comment} =  &featureparser::getelementValue($node,STRICTCASE);
	}
}

1;
