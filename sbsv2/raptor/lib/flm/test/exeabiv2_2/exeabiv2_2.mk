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
## to demonstrate use of 1 call to a basic flm with two input files
## postconditions:
## test2.exe is written to the output directory $OUTPUTPATH/test2/test2.exe
## test1.o and test2.o are generated in $OUTPUTPATH/test1/test1.o and $OUTPUTPATH/test2/test2.exe


# Pull tools
include $(FLMHOME)/flmtools.mk

$(call vsave,OUTPUTPATH SOURCEPATH CDEFS SYSTEMINCLUDE)
# Pull in defaults for building test executables
include $(FLMTESTHOME)/exeabiv2_defaults.mk


TARGET:=exeabiv2_2
CDEFS:=$(CDEFS) __TESTNAME__=\"exeabiv2_2\"
OUTPUTPATH:=$(OUTPUTPATH)/$(TARGET)
SOURCEPATH:=$(SOURCEPATH)/exeabiv2_2
SOURCEFILES:=$(SOURCEPATH)/test.cpp $(SOURCEPATH)/test_function.cpp
SYSTEMINCLUDE:=$(SYSTEMINCLUDE) $(FLMTESTHOME)/include
UID3:=0x000002

include $(FLMHOME)/$(FLM)

$(call vrestore)
