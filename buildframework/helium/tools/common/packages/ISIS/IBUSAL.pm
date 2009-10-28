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
# Name   : IBUSAL.pm
# Use    : description.

#
# Synergy :
# Perl %name: IBUSAL.pm % (%full_filespec:  IBUSAL.pm-1:perl:fa1s60p1#1 %)
# %derived_by:  wbernard %
# %date_created:  Thu Sep 22 15:47:08 2005 %
#
# Version History :
#
# v1.0 (20/09/2005) :
#  - Fist version of the package.
#------------------------------------------------------------------------------

package ISIS::IBUSAL;
use strict;

# ISIS constants.
use constant ISIS_VERSION 		=> '1.0';
use constant ISIS_LAST_UPDATE => '20/09/2005';


#------------------------------------------------------------------------------
# Package's subroutines
#------------------------------------------------------------------------------

################################################################################
#
#
#  XLoader for RnD
#
#		@param productname
#		@param hwid
#
################################################################################
sub CopyXLoader($$)
{
		my ($target,$hid) = @_;
		my ($asic,$asic_ver,$asic_key,$flash_size,$rom_size,$pi,$arm_ver,$sec_srvs) = &ReadConfFile($target,$hid);
		print "Copying prebuilt XLoader\n";
		system("copy /y /b \\spp_config\\product_config\\Ibusal\\Exports_Adaptation\\rombuild\\prebuilt_xloader_images\\xloader-ext?${target}_2_0_OEM1.fps8 \\epoc32\\INCLUDE\\$target\\PI$pi\\XLoader\\1710V$asic_ver\\udeb\\xloader-ext.fps8");
		system("copy /y /b \\spp_config\\product_config\\Ibusal\\Exports_Adaptation\\rombuild\\prebuilt_xloader_images\\xloader?${target}_2_0_OEM1.fps8 \\epoc32\\INCLUDE\\$target\\PI$pi\\XLoader\\1710V$asic_ver\\udeb\\xloader.fps8");
		system("copy /y /b \\spp_config\\product_config\\Ibusal\\Exports_Adaptation\\rombuild\\prebuilt_xloader_images\\xloader-ext?${target}_2_0_OEM1.fps8 \\epoc32\\INCLUDE\\$target\\PI$pi\\XLoader\\1710V$asic_ver\\urel\\xloader-ext.fps8");
		system("copy /y /b \\spp_config\\product_config\\Ibusal\\Exports_Adaptation\\rombuild\\prebuilt_xloader_images\\xloader?${target}_2_0_OEM1.fps8 \\epoc32\\INCLUDE\\$target\\PI$pi\\XLoader\\1710V$asic_ver\\urel\\xloader.fps8");
}




#########################################################################
#
#		Internal functions
#
#########################################################################
sub ReadConfFile
{
    my ($pname,$hid) = @_;
    if (not -e "\\epoc32\\rom\\$pname\\${pname}.conf")
    {
	print("ERROR: Can't open \\epoc32\\rom\\$pname\\${pname}.conf file\n");
	exit(0);
    }
    open INPUTOBYFILE,"\\epoc32\\rom\\$pname\\${pname}.conf" or die "ERROR: Can't open \\epoc32\\rom\\$pname\\${pname}.conf file\n";

    my ($InputObyFile,$hwid,$asic,$asic_ver,$asic_key,$flash_size,$rom_size,$pi,$arm_ver,$sec_srvs);
    while ( $InputObyFile = <INPUTOBYFILE> )
    {
        chomp $InputObyFile;

        ($hwid,$asic,$asic_ver,$asic_key,$flash_size,$rom_size,$pi,$arm_ver,$sec_srvs) = split(/\|+/,$InputObyFile);
        chomp($hwid,$asic,$asic_ver,$asic_key,$flash_size,$rom_size,$pi,$arm_ver,$sec_srvs);
        &trim($hwid,$asic,$asic_ver,$asic_key,$flash_size,$rom_size,$pi,$arm_ver,$sec_srvs);
        if ($hid eq $hwid)
        {
            close INPUTOBYFILE;
            return ($asic,$asic_ver,$asic_key,$flash_size,$rom_size,$pi,$arm_ver,$sec_srvs);
        }
    }
    close INPUTOBYFILE;
    &usage("ERROR: Hardware Id '$hid' not found in the conf file\n");
}

sub trim 
{
    for (@_) 
    {
        s/^\s*//; # trim leading spaces
        s/\s*$//; # trim trailing spaces
    }
    return @_;
}


1;
#------------------------------------------------------------------------------
# End of file.
#------------------------------------------------------------------------------
