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

# This package contains routines to create features data file.
use featurefile;
package featuresdat;

BEGIN
{
	@ISA = qw (featurefile);	# Declare this a child of featurefile class
}       

use featureparser;
use strict;

# Class constructor
sub new
{
	my ($class,$xmlDBHandle) = @_;
	my $object = $class->SUPER::new($xmlDBHandle); # Invoke base class new function
	
	$object->{_FEATURELIST} = undef;
	$object->{_FEATUREHASHMAP} = undef;	
	$object->{_FILEVERSION} = 0x0001;

	return $object;
}

# Subroutine to create feature map
# @param $object					- Object reference which is passed implicitly
sub createFeatureMap
{	
	my $object = shift;		
	
	foreach my $fidMain (@{$object->{_FEATURELIST}}) 
	{
		my $fid = $fidMain->{uid};
		
		# Check whether the feature is present in feature list XMl file or not.
		# If not, then generate an error message and discard this feature.
		if (!$object->isPresentInFeatureListXML($fidMain)) 
		{
			next;
		}
		
		# "0th" bit of the Status Flag is set depending on whether the feature is included by using "FEATURE" keyword or 
		# excluded using "EXCLUDE_FEATURE" keyword (i.e. "0th" bit will be set as '1' if the feature is included or else will
		# be set as '0' if feature is excluded).
		if ($fidMain->{include} == 1)
		{
			$fidMain->{SF} |= 1;
		}
		elsif ($fidMain->{exclude} == 1)
		{
			$fidMain->{SF} &= 0xFFFFFFFE;
		}

		$object->{_FEATUREHASHMAP}->{$fid} = { SF=>$fidMain->{SF}, UD=>$fidMain->{UD} };
	}	
}

# Subroutine to write the feature entries in the features data file.
# @param $object					- Object reference which is passed implicitly
sub writeFeatures
{
	my $object = shift;

	foreach my $featureId (sort {$a <=> $b} (keys %{$object->{_FEATUREHASHMAP}}))
	{
		$object->write2File($featureId);
		$object->write2File($object->{_FEATUREHASHMAP}->{$featureId}->{SF});			
		$object->write2File($object->{_FEATUREHASHMAP}->{$featureId}->{UD});
	}
}

# Subroutine to set the count of Default Support Range(D.S.R)
# @param $object					- Object reference which is passed implicitly
sub setDefaultRangeCount
{
	my $object = shift;
	
	# Set the Default Range Count only for core image feature database file.
	if ($object->{_FEATUREFILENAME} =~ /features.dat$/i ) 
	{
		$object->{_DEFAULTRANGECOUNT} = ($object->{_XMLDBHANDLE})->defaultIncludeCount();
	}
	else
	{
		$object->{_DEFAULTRANGECOUNT} = 0;
	}
}

1;