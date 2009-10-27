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
## Test 1 - build an ARM E32 EXE on Linux
## parameters relevant to the test.

## Purpose: To demonstrate use of 1 call to a basic flm with one input file
## Postconditions: test1.cia is written to the output directory $OUTPUTPATH/test1/test1.cia:

# Pull tools
include $(FLMHOME)/flmtools.mk


$(call vsave,OUTPUTPATH SOURCEPATH CDEFS SYSTEMINCLUDE)
# Pull in defaults for building test ciacutables
include $(FLMTESTHOME)/dllabiv2_defaults.mk

TARGET:=ciaabiv2_1
CDEFS:=$(CDEFS) __TESTNAME__=\"ciaabiv2_1\"
OUTPUTPATH:=$(OUTPUTPATH)/$(TARGET)
SOURCEPATH:=$(SOURCEPATH)/ciaabiv2_1
SYSTEMINCLUDE:=$(SYSTEMINCLUDE) $(FLMTESTHOME)/include
SOURCEFILES:=$(SOURCEPATH)/uc_exe.cia  $(SOURCEPATH)/uc_exe.cpp
UID3:=0x000001


include $(FLMHOME)/$(FLM)

$(call vrestore)
