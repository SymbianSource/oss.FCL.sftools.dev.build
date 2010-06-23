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

# check that the 5 stages happen in the right order relative to each other
# and relative to the MMP LIBRARY (LIB) and TARGET (BLD) stages.


VARIANT:=$(PLATFORM_PATH)_$(CFG_PATH)

GENERATED_C:=$(EPOCROOT)/epoc32/build/generated/tem_stages_generated.cpp
GENERATED_H:=$(EPOCROOT)/epoc32/include/tem_stages_generated.h
GENERATED_R:=$(EPOCROOT)/epoc32/include/tem_stages_generated_$(VARIANT).rsg
GENERATED_L:=$(EPOCROOT)/epoc32/include/tem_stages_generated_$(VARIANT).lib
GENERATED_B:=$(EPOCROOT)/epoc32/include/tem_stages_generated_$(VARIANT).bin
GENERATED_F:=$(EPOCROOT)/epoc32/include/tem_stages_generated_$(VARIANT).final

GENERATED:=$(GENERATED_C) $(GENERATED_H) $(GENERATED_R) $(GENERATED_L) $(GENERATED_B) $(GENERATED_F)

BUILT_LIB:=$(EPOCROOT)/epoc32/release/$(PLATFORM_PATH)/$(CFG_PATH)/tem_stages.lib
BUILT_EXE:=$(EPOCROOT)/epoc32/release/$(PLATFORM_PATH)/$(CFG_PATH)/tem_stages.exe
COPY_LIB:=$(EPOCROOT)/epoc32/release/$(PLATFORM_PATH)/$(CFG_PATH)/tem_stages.lib2
COPY_EXE:=$(EPOCROOT)/epoc32/release/$(PLATFORM_PATH)/$(CFG_PATH)/tem_stages.exe2

COPIED:=$(COPY_LIB) $(COPY_EXE)

DIRS:=$(dir $(GENERATED_H)) $(dir $(GENERATED_C))
$(DIRS):
	mkdir -p $@

# a header that is used by the EXE and LIB
# and a source file used by the EXE and LIB
#
MAKMAKE: | $(DIRS)
	echo "// dummy" > $(GENERATED_H)
	echo "// dummy" > $(GENERATED_C)


# check that our MAKMAKE happens before RESOURCE
#
RESOURCE: | $(DIRS)
	$(CP) $(GENERATED_H) $(GENERATED_R)


# check that our RESOURCE happens before LIB
#
LIB: | $(DIRS)
	$(CP) $(GENERATED_R) $(GENERATED_L)


# check that our LIB happens before BLD
# check that MMP LIB happens before BLD
#
BLD: | $(DIRS)
	$(CP) $(GENERATED_L) $(GENERATED_B)
	$(CP) $(BUILT_LIB) $(COPY_LIB)


# check that our BLD happens before FINAL
# check that MMP BLD happens before FINAL
#
FINAL: | $(DIRS)
	$(CP) $(GENERATED_B) $(GENERATED_F)
	$(CP) $(BUILT_EXE) $(COPY_EXE)

RELEASABLES:
	@echo $(BUILT_EXE) $(COPY_EXE) $(BUILT_LIB) $(COPY_LIB)


CLEAN:
	$(RM) $(GENERATED) $(COPIED)

CLEANLIB: ;

