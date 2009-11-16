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
##


## Purpose:
## This is used to gauge perfomance 
## At least one "large" input file is built
## The input file has no dependencies so it really is just something for the compiler to "chew"


# Pull tools
include $(FLMHOME)/flmtools.mk

$(call vsave,OUTPUTPATH SOURCEPATH CDEFS SYSTEMINCLUDE)
# Pull in defaults for building test executables
include $(FLMTESTHOME)/exeabiv2_defaults.mk


TARGET:=exeabiv2_4
CDEFS:=$(CDEFS) __TESTNAME__=\"exeabiv2_4\"
OUTPUTPATH:=$(OUTPUTPATH)/$(TARGET)
SOURCEPATH:=$(SOURCEPATH)/exeabiv2_4
SOURCEFILES:=$(SOURCEPATH)/test.cpp $(SOURCEPATH)/test_big.cpp
SYSTEMINCLUDE:=$(SYSTEMINCLUDE) $(FLMTESTHOME)/include
UID3:=0x000004

include $(FLMHOME)/$(FLM)

$(call vrestore)
