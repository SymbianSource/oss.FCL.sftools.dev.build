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
# Name   : Cellmo.pm
# Use    : description.

#
# Synergy :
# Perl %name: Cellmo.pm % (%full_filespec:  Cellmo.pm-6:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Fri Jul  7 15:15:47 2006 %
#
# Version History :
#
# v1.0 (29/11/2005) :
#  - Fist version of the package.
#------------------------------------------------------------------------------

package ISIS::Cellmo;
use strict;
use ISIS::Logger2;
use ISIS::Registry;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.0';
use constant ISIS_LAST_UPDATE => '29/11/2005';

# default configuration file
use constant ROOT_SCRIPTS_DIR   => "/isis_sw/build_config/";
use constant REG_CONFIG_FILE    => ROOT_SCRIPTS_DIR."registry.xml";

#------------------------------------------------------------------------------
# Package's subroutines
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# GetCellmo
#
# - Backward compatibility for CreatelocalisationROM.pl
# - Get Cellmo by product.
#------------------------------------------------------------------------------
sub GetCellmo
{
	my ( $product ) = @_;
	return undef unless ( $product );

	# Load the default configuration
	my $resgistry = new Registry( REG_CONFIG_FILE, { error_level => 1 });
	
	# Call method used by NAB
	return GetCellmoFromConfig($product, "undefined", "undefined",  $resgistry);
}

#------------------------------------------------------------------------------
# GetCellmoFromConfig
#------------------------------------------------------------------------------
sub GetCellmoFromConfig
{
	my ( $product, $buildtype, $flags, $registry ) = @_;
	
	my $id = $registry->{'cellmos'}->{$product}->{'id'};
	my $dir = $registry->{'cellmos'}->{$product}->{'dir'};

	return &__GetCellmoFromDir($dir, $id);
}


#------------------------------------------------------------------------------
# Internal
#------------------------------------------------------------------------------
sub __GetCellmoFromDir
{
	my ( $dir, $id ) = @_;
	
	my $entry;
		
	opendir ( DIRH, $dir )  or OUT2XML::Error ("couldn't open: $!", ERR::INVALID_PATH); 
	while ($entry  = readdir(DIRH)) {
		if ($entry =~ m/$id.*\.cmt/i)
		{
			return "$dir\\$entry";
		}			
	} 
	closedir ( DIRH ); 
	return undef;
}


1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
