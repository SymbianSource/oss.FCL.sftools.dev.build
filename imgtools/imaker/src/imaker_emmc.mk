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
# Description: iMaker eMMC (Embedded Mass Memory) image configuration
#



###############################################################################
#      __  __ __  __  ___
#  ___|  \/  |  \/  |/ __|
# / -_) |\/| | |\/| | (__
# \___|_|  |_|_|  |_|\___|
#

EMMC_TITLE       = eMMC

EMMC_DRIVE       = E
EMMC_FATTYPE     = 32# FAT32
EMMC_SIZE        = 16777216# kB (= 16 GB)
EMMC_CLUSTERSIZE = 16# kB
EMMC_FATTABLE    = 2

EMMC_SWVERFILE   = $(EMMC_DATADIR)/Resource/Versions/User Content Package_Mass_Memory.txt
EMMC_SWVERINFO   = # Don't generate sw version file
EMMC_EXCLFILE    = # Don't generate exclude list


# END OF IMAKER_EMMC.MK
