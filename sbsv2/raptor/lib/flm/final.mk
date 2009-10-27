#
# Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
# final include file : this is included at the end of
# all generated makefiles
# INPUTS : assumes OSTYPE and FLMHOME are set.
#

# The final makefile is not a once-per-build file
# if the make tree is split into many files then
# final must be "included" many times

# Create all remaining buffered directories
#
$(call makepathfinalise)

# For users of SBSv2 who wish to add in their own final settings
# without modifying this file:
-include $(FLMHOME)/user/final.mk
