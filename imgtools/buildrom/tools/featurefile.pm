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

# This package contains common routines required for the creation of feature registry configuration/
# features data file.
package featurefile;

# Include Module package
use FileHandle;
use WRITER;

use strict;

# Class constructor
sub new 
{
	my ($class,$xmlDBHandle) = @_;

	my $object = {};
	$object->{_FEATUREFILENAME} = undef;
	$object->{_FILEHANDLE} = undef;
	$object->{_FILEVERSION} = undef;
	$object->{_FEATCOUNT} = 0;
	$object->{_DEFAULTRANGECOUNT} = 0;
	$object->{_XMLDBHANDLE} = $xmlDBHandle;
	
	bless($object, $class);
	return $object;
}

# Subroutine to create feature registry configuration/features data file
# @param $object					- Object reference which is passed implicitly
# @param _FEATUREFILENAME			- Feature registry configuration/features data filename
# @param _FEATURELIST				- The complete List of features which are either to be included or excluded
sub createFile
{
	my $object = shift;
	$object->{_FEATUREFILENAME} = shift;
	$object->{_FEATURELIST} = shift;
		
	# Open feature file for writing	
	if (!$object->openFile())
	{
		return 0;
	}

	# Create feauture map
	$object->createFeatureMap();
	
	# Set feature count
	$object->setFeatureCount();

	# Set Default Range Count
	$object->setDefaultRangeCount();
	
	# Write feature file header
	$object->writeHeader();	

	# Create feature entry for the listed features
	$object->writeFeatures();

	# Write Default Supported Range 
	$object->writeDefault();
	
	# Close feature file.
	$object->closeFile();

	return 1;
}

# Subroutine to open feature file 
# @param $object					- Object reference which is passed implicitly
sub openFile
{
	my $object = shift;	

	open (CONFIG_FH, ">$object->{_FEATUREFILENAME}");
	binmode(CONFIG_FH);
	$object->{_FILEHANDLE} = *CONFIG_FH;

	if(!defined $object->{_FILEHANDLE})
	{
		print "\nError in creating the $object->{_FEATUREFILENAME}, check for the accessability of File / Drive\n";
		return 0;
	}
	return 1;
}

# Subroutine to write feature file header
# @param $object					- Object reference which is passed implicitly
sub writeHeader
{
	my $object = shift;

	$object->write2File(0x74616566);
	$object->write2File($object->{_FILEVERSION});
	$object->write2File($object->{_FEATCOUNT});
	$object->write2File($object->{_DEFAULTRANGECOUNT});
}

# Subroutine to check if the feature is present in feature databse XML file
# @param $object					- Object reference which is passed implicitly
sub isPresentInFeatureListXML
{
	my $object = shift;
	my $fidMain= shift;	
	
	# If the feature is not found, generate an error message.
	if(!defined $fidMain->{uid})
	{
		print "Error:Feature $fidMain->{name} not found in feature list XML \n";
		return 0;
	}	
	return 1;
}

# Subroutine to set the count of listed features in feature file
# @param $object					- Object reference which is passed implicitly
sub setFeatureCount
{
	my $object = shift;

	$object->{_FEATCOUNT} = scalar (keys %{$object->{_FEATUREHASHMAP}});	
}

# Subroutine to set the count of Default Support Range(D.S.R)
# @param $object					- Object reference which is passed implicitly
sub setDefaultRangeCount
{
	my $object = shift;
	
	$object->{_DEFAULTRANGECOUNT} = ($object->{_XMLDBHANDLE})->defaultIncludeCount();
}

# Write the default=present featureUID ranges (min/lowerruid,max/higheruid) to the feature file 
# @param $object					- Object reference which is passed implicitly
sub writeDefault
{
	my $object = shift;

	if ($object->{_DEFAULTRANGECOUNT}) 
	{
		my @defaultFeatures = ($object->{_XMLDBHANDLE})->getDefaultIncludeInfo();
		for my $i ( 0 .. $#defaultFeatures )
		{
			my $minuid = $defaultFeatures[$i][0];
			my $maxuid = $defaultFeatures[$i][1];		
			$object->write2File($minuid);
			$object->write2File($maxuid);
		}
	}
}

# Subroutine to close feature file. 
# @param $object					- Object reference which is passed implicitly
sub closeFile
{
	my $object = shift;

	close $object->{_FILEHANDLE};
}

# Subroutine to write the bytes to the binary file. 
# @param $object					- Object reference which is passed implicitly
# @param $bytes						- 32-bit value which is to be writen in binary file.
sub write2File
{
	my $object = shift;
	my $bytes = shift;

	&WRITER::write32($object->{_FILEHANDLE}, $bytes);
}

1;