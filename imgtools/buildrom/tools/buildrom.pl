#
# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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


use FindBin;		# for FindBin::Bin
my $PerlLibPath;    # fully qualified pathname of the directory containing our Perl modules

BEGIN {
# check user has a version of perl that will cope
	require 5.005_03;
# establish the path to the Perl libraries
    $PerlLibPath = $FindBin::Bin;	# X:/epoc32/tools
    $PerlLibPath =~ s/\//\\/g;	# X:\epoc32\tools
    $PerlLibPath .= "\\";
}


use  lib $PerlLibPath;
#Includes the validation perl modules for XML validation against the given DTD.
use lib "$PerlLibPath/build/lib";

use buildrom;	# for buildrom module
use externaltools; #To support External tool invocation


# Main block for buildrom module invocation
{
	# Processes the buildrom command line parameters.
	&process_cmdline_arguments;
	
	&image_content_processing_phase;

	#Processes intermediate oby files.  Also processes any new option added to the buildrom in future.
	&processobyfiles;

	# Suppress ROM/ROFS/DataDrive Image creation if "-noimage" option is provided.
	&suppress_image_generation;
	
	#Invokes ROMBUILD and ROFSBUILD
	&invoke_rombuild;
	
	&create_smrimage;

	#Process data drive image.
	&processData;
}


sub processobyfiles {

	
	# Creates intermediate tmp1.oby file. Preprocessing phase
	&preprocessing_phase;

	# Creates intermediate tmp2.oby file.  Predefined substitutions
	&substitution_phase;

	# Creates intermediate tmp3.oby file. Reorganises the ROM IMAGE[<ID>]
	&reorganize_phase;

	# Creates feature registry configuration file/features data file.
	&featurefile_creation_phase;

	# Run single Invocation external tool at InvocationPoint1

	&externaltools::runExternalTool("InvocationPoint1", &getOBYDataRef);
	
	# Creates intermediate tmp4.oby file. Avoids processing of REM ECOM_PLUGIN(xxx,yyy)
	&plugin_phase;
	
	# Creates intermediate tmp5.oby file. Multilinguify phase
	&multlinguify_phase;
	
	# Creates intermediate tmp6.oby file. SPI file creation phase
	&spi_creation_phase;

	# Run single Invocation external tool at InvocationPoint2
	&externaltools::runExternalTool("InvocationPoint2",&getOBYDataRef);
	
	# Creates intermediate tmp7.oby file. Problem Suppression phase
	&suppress_phase;

	#Process the patched dll data
	&process_dlldata;

	# Creates intermediate tmp8.oby file. For xip and non-xip images
	&bitmap_aif_converison_phase;
	
	# Creates intermediate tmp9.oby file. Cleaning unnecessary data for ROM image creation.
	&cleaning_phase;
	
	# Run single Invocation external tool at InvocationPoint2.5
	&externaltools::runExternalTool("InvocationPoint2.5",&getOBYDataRef);

	#Creates dump OBY file for final oby file
	&create_dumpfile;

	# Run single Invocation external tool at InvocationPoint3
	&externaltools::runExternalTool("InvocationPoint3",&getOBYDataRef);

	#ROM directory listing
	&create_dirlisting;

}

