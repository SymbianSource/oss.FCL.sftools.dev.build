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
###############################################################################
###############################################################################
###############################################################################
# FWID creation
ENABLE_FWID?=0
FWID_CORE_IBY=$(WORKNAME)_core_fwid.iby
FWID_VARIANT_IBY=$(WORKNAME)_variant_fwid.iby
FWID_FILE=$(WORKNAME)_fwid$(FWID_ROFSID).txt

# A step to generate fwidX.txt
CLEAN_CREATE_FWID_FILE = del | $(FWID_FILE)
BUILD_CREATE_FWID_FILE = \
  echo  | Generating file: $(FWID_FILE)\n | \
  writeu | $(FWID_FILE) | id=$(FWID$(FWID_ROFSID)_ID)\nversion=$(FWID$(FWID_ROFSID)_VERSION)\n

# fwid.iby creation 
CLEAN_VARIANTFWIDIBY = del | $(FWID_VARIANT_IBY)
BUILD_VARIANTFWIDIBY = \
    echo  | Generating the $(FWID_VARIANT_IBY)\n | \
  write | $(FWID_VARIANT_IBY) | // Generated iby for fwid inclusion\n\
    \n\#ifndef __GENERATED_VARIANT_FWID_IBY__\
  \n\#define __GENERATED_VARIANT_FWID_IBY__\n\
  $(foreach FWID_ROFSID,2 3,\nROM_IMAGE[$(FWID_ROFSID)] data=$(FWID_FILE)   RESOURCE_FILES_DIR\versions\fwid$(FWID_ROFSID).txt)\
  \n\n\#endif // __GENERATED_VARIANT_FWID_IBY__\n
  
CLEAN_COREFWIDIBY = del | $(FWID_CORE_IBY)
BUILD_COREFWIDIBY = \
    echo  | Generating the $(FWID_CORE_IBY)\n | \
  write | $(FWID_CORE_IBY) | // Generated iby for fwid inclusion\n\
    \n\#ifndef __GENERATED_CORE_FWID_IBY__\
  \n\#define __GENERATED_CORE_FWID_IBY__\n\
  $(foreach FWID_ROFSID,1,\nROM_IMAGE[$(FWID_ROFSID)] data=$(FWID_FILE) RESOURCE_FILES_DIR\versions\fwid$(FWID_ROFSID).txt)\
  \n\n\#endif // __GENERATED_CORE_FWID_IBY__\n

# creates the all fwid file need file - CORE
CLEAN_CREATE_FWID_FILES=echo | Cleaning up fwids\n $(foreach FWID_ROFSID,$1,| $(CLEAN_CREATE_FWID_FILE))
BUILD_CREATE_FWID_FILES=echo | Generating fwids\n $(foreach FWID_ROFSID,$1,| $(BUILD_CREATE_FWID_FILE))

CLEAN_VARBLDPRE += $(call iif,$(ENABLE_FWID), | $(call CLEAN_CREATE_FWID_FILES,2 3) | $(CLEAN_VARIANTFWIDIBY),)
BUILD_VARBLDPRE += $(call iif,$(ENABLE_FWID), | $(call BUILD_CREATE_FWID_FILES,2 3) | $(BUILD_VARIANTFWIDIBY),)
CLEAN_COREBLDPRE += $(call iif,$(ENABLE_FWID), | $(call CLEAN_CREATE_FWID_FILES,1) | $(CLEAN_COREFWIDIBY),)
BUILD_COREBLDPRE += $(call iif,$(ENABLE_FWID), | $(call BUILD_CREATE_FWID_FILES,1) | $(BUILD_COREFWIDIBY),)
BLDROM_OPTPROD += $(call iif,$(ENABLE_FWID),$(FWID_CORE_IBY),)
# pass this only to var creation could not configure option for variant and core separately
BLDROM_VAROBY += $(call iif,$(and $(call iif,$(SOS_VARIANT),1,),$(call iif,$(ENABLE_FWID),1,)),$(FWID_VARIANT_IBY),)
###############################################################################
###############################################################################
###############################################################################


