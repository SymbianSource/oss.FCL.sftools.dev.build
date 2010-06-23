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
##
## Test 1 - build an ARM E32 DLL
## parameters relevant to the test.

## Purpose: To demonstrate the building of a trivial library
## Postconditions: dllabiv2_1.dll is written to the releasables directory

# Pull in defaults for building test executables

#Get the tools so we can save some variables
include $(FLMHOME)/flmtools.mk

$(call vsave,OUTPUTPATH SOURCEPATH CDEFS SYSTEMINCLUDE)
include $(FLMTESTHOME)/dllabiv2_defaults.mk

TARGET:=dllabiv2_1
CDEFS:=$(CDEFS) __TESTNAME__=\"dllabiv2_1\"
OUTPUTPATH:=$(OUTPUTPATH)/$(TARGET)
SOURCEPATH:=$(SOURCEPATH)/dllabiv2_1
SOURCEFILES:=$(SOURCEPATH)/test.cpp

include $(FLMHOME)/$(FLM)

# Restore the variables we modified
$(call vrestore)
