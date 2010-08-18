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
# Defaults for ABIv2 EXE build tests

## Purpose: To enable all test makefiles to be updated rapidly


include $(FLMHOME)/e32abiv2.mk


DEBUG:=1

CAPABILITY:=LocalServices ReadDeviceData ReadUserData
UID1:=0x1000007a
UID2:=0x100039ce
UID3:=0x000001
VID:=0x000001
SID:=0x10003a5c
EXETARGET:=
TARGETTYPE:=EXE
MAPFILENAME:=
BMPS:=
EPOCDATA:=

VARIANTARCH:=ARMV5
FULLVARIANTPATH=$(VARIANTARCH)/$(VARIANTTYPE)
STATIC_LIBS_PATH:=$(call fromnativepath,$(RVCT22LIB))/armlib
RUNTIME_LIBS_PATH=$(RELEASEPATH)/$(VARIANTARCH)/LIB
RELEASEPATH:=$(EPOCROOT)/epoc32/release
FLM:=e32abiv2exe.flm
CDEFS:=$(CDEFS) __EXE__



