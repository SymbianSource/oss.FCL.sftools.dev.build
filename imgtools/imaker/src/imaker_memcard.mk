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
# Description: iMaker Memory MMC/SD card image configuration
#



###############################################################################
#  __  __           ___             _
# |  \/  |___ _ __ / __|__ _ _ _ __| |
# | |\/| / -_) '  \ (__/ _` | '_/ _` |
# |_|  |_\___|_|_|_\___\__,_|_| \__,_|
#

MCARD_TITLE       = MemCard

MCARD_DRIVE       = F
MCARD_FATTYPE     = 32# FAT32
MCARD_SIZE        = 2097152# kB (= 2 GB)
MCARD_CLUSTERSIZE = 16# kB
MCARD_FATTABLE    = 2

MCARD_SWVERFILE   = #$(MCARD_DATADIR)/Resource/Versions/User Content Package_Mass_Memory.txt
MCARD_SWVERINFO   = # Don't generate sw version file
MCARD_EXCLFILE    = # Don't generate exclude list


# END OF IMAKER_MEMCARD.MK
