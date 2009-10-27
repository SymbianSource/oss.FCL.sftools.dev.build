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
# featureregistry.pm
#

# This package contains routines to create the feature registry file.
use featurefile;
package featurecfg;

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
	$object->{_FILEVERSION} = 0;

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
		
#		Check whether the feature is present in feature list XMl file or not.
#		If not, then generate an error message and discard this feature.
		if (!$object->isPresentInFeatureListXML($fidMain)) 
		{
			next;
		}	

#		Initialise the status bit
		$fidMain->{status} = 0;

#		If a feature is to be included in Rom, then set the 0th bit.
#		If a feature is explicitly to be excluded from ROM, then nothing is to be done, 
#		since the 0th bit is already set to zero.
		if ($fidMain->{include} == 1)
		{
			$fidMain->{status} |= 1;
		}

		my $featInfoRef = ($object->{_XMLDBHANDLE})->getFeatureInfo($fid);

#		Check if the individual feature is installable, If so, set the 1st bit.
		if($featInfoRef->{installable} eq "true")
		{
			$fidMain->{status} |= 2;
		}
		
		$object->{_FEATUREHASHMAP}->{$fid} = $fidMain->{status};
	}	
}

# Subroutine to write the feature entries in the feature registry configuration file.
# @param $object					- Object reference which is passed implicitly
sub writeFeatures
{
	my $object = shift;

	foreach my $featureId (sort {$a <=> $b} (keys %{$object->{_FEATUREHASHMAP}}))
	{
		$object->write2File($featureId);
		$object->write2File($object->{_FEATUREHASHMAP}->{$featureId});
	}
}

1;