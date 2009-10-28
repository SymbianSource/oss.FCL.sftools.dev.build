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
# SW version string handling
ENABLE_SW_STRING?=0
CORE_SW_VERSION_STRING=v 0.00.0\\\n$(TODAY)\\\nRM-XXX
MODEL_SW_VERSION_STRING=N00
LP_SW_VERSION_STRING=v 0.00.0 (00)\\\n$(TODAY)\\\nRM-XXX
CUSTOMER_SW_VERSION_STRING=to be defined
TODAY:=$(shell perl -e "use POSIX qw(strftime); print strftime(\"%%d-%%m-%%y\", localtime());")

# Internal names
CORE_OVERRIDE_SW_VERSION_IBY=$(CORE_NAME)_override_core_version.iby
MODEL_OVERRIDE_SW_VERSION_IBY=$(CORE_NAME)_override_model_version.iby
LP_OVERRIDE_SW_VERSION_IBY=$(ROFS2_NAME)_override_lp_version.iby
CUSTOMER_OVERRIDE_SW_VERSION_IBY=$(ROFS3_NAME)_override_customer_version.iby
CORE_SW_VERSION_FILE=$(CORE_NAME)_sw.txt
MODEL_SW_VERSION_FILE=$(CORE_NAME)_model.txt
LP_SW_VERSION_FILE=$(ROFS2_NAME)_langsw.txt
CUSTOMER_SW_VERSION_FILE=$(ROFS3_NAME)_customersw.txt


CLEAN_CREATE_SW_VERSION_FILE = echo | Deleting $($(1)_SW_VERSION_FILE)\n | del | $($(1)_SW_VERSION_FILE)
BUILD_CREATE_SW_VERSION_FILE = \
  echo  | Generating file: $($(1)_SW_VERSION_FILE)\n | \
  writeu | $($(1)_SW_VERSION_FILE) | $(call quote,$($(1)_SW_VERSION_STRING))

CLEAN_CREATE_CORE_OVERRIDE_SW_VERSION_IBY = echo | Deleting $(CORE_OVERRIDE_SW_VERSION_IBY)\n | del | $(CORE_OVERRIDE_SW_VERSION_IBY)
BUILD_CREATE_CORE_OVERRIDE_SW_VERSION_IBY = \
    echo  | Generating the $(CORE_OVERRIDE_SW_VERSION_IBY)\n | \
    write | $(CORE_OVERRIDE_SW_VERSION_IBY) | // Generated iby for sw string inclusion\n\
    \n\#ifndef __GENERATED_CORE_OVERRIDE_VERSION_IBY__\
    \n\#define __GENERATED_CORE_OVERRIDE_VERSION_IBY__\n\
    \ndata-override=$(CORE_SW_VERSION_FILE)     resource\versions\sw.txt\
    \n\n\#endif // __GENERATED_CORE_OVERRIDE_VERSION_IBY__\n

CLEAN_CREATE_MODEL_OVERRIDE_SW_VERSION_IBY = echo | Deleting $(MODEL_OVERRIDE_SW_VERSION_IBY)\n | del | $(MODEL_OVERRIDE_SW_VERSION_IBY)
BUILD_CREATE_MODEL_OVERRIDE_SW_VERSION_IBY = \
    echo  | Generating the $(MODEL_OVERRIDE_SW_VERSION_IBY)\n | \
    write | $(MODEL_OVERRIDE_SW_VERSION_IBY) | // Generated iby for sw string inclusion\n\
    \n\#ifndef __GENERATED_MODEL_OVERRIDE_VERSION_IBY__\
    \n\#define __GENERATED_MODEL_OVERRIDE_VERSION_IBY__\n\
    \ndata-override=$(MODEL_SW_VERSION_FILE)    resource\versions\model.txt\
    \n\n\#endif // __GENERATED_MODEL_OVERRIDE_VERSION_IBY__\n

CLEAN_CREATE_LP_OVERRIDE_SW_VERSION_IBY = echo | Deleting $(LP_OVERRIDE_SW_VERSION_IBY)\n | del | $(LP_OVERRIDE_SW_VERSION_IBY)
BUILD_CREATE_LP_OVERRIDE_SW_VERSION_IBY = \
    echo  | Generating the $(LP_OVERRIDE_SW_VERSION_IBY)\n | \
    write | $(LP_OVERRIDE_SW_VERSION_IBY) | // Generated iby for sw string inclusion\n\
    \n\#ifndef __GENERATED_LP_OVERRIDE_VERSION_IBY__\
    \n\#define __GENERATED_LP_OVERRIDE_VERSION_IBY__\n\
    \nROM_IMAGE[2] data-override=$(LP_SW_VERSION_FILE)      resource\versions\langsw.txt\
    \n\n\#endif // __GENERATED_LP_OVERRIDE_VERSION_IBY__\n

CLEAN_CREATE_CUSTOMER_OVERRIDE_SW_VERSION_IBY = echo | Deleting $(CUSTOMER_OVERRIDE_SW_VERSION_IBY)\n | del | $(CUSTOMER_OVERRIDE_SW_VERSION_IBY)
BUILD_CREATE_CUSTOMER_OVERRIDE_SW_VERSION_IBY = \
    echo  | Generating the $(CUSTOMER_OVERRIDE_SW_VERSION_IBY)\n | \
    write | $(CUSTOMER_OVERRIDE_SW_VERSION_IBY) | // Generated iby for sw string inclusion\n\
    \n\#ifndef __GENERATED_CUSTOMER_OVERRIDE_VERSION_IBY__\
    \n\#define __GENERATED_CUSTOMER_OVERRIDE_VERSION_IBY__\n\
    \nROM_IMAGE[3] data-override=$(CUSTOMER_SW_VERSION_FILE)    resource\versions\customersw.txt\
    \n\n\#endif // __GENERATED_CUSTOMER_OVERRIDE_VERSION_IBY__\n

CLEAN_CORESWSTING  = $(call iif,$(ENABLE_SW_STRING), $(foreach type,CORE MODEL, | $(call CLEAN_CREATE_SW_VERSION_FILE,$(type)) | $(CLEAN_CREATE_$(type)_OVERRIDE_SW_VERSION_IBY)),)
BUILD_CORESWSTING  = $(call iif,$(ENABLE_SW_STRING), $(foreach type,CORE MODEL, | $(call BUILD_CREATE_SW_VERSION_FILE,$(type)) | $(BUILD_CREATE_$(type)_OVERRIDE_SW_VERSION_IBY)),)
CLEAN_ROFS2SWSTING = $(call iif,$(ENABLE_SW_STRING), $(foreach type,LP, | $(call CLEAN_CREATE_SW_VERSION_FILE,$(type)) | $(CLEAN_CREATE_$(type)_OVERRIDE_SW_VERSION_IBY)),)
BUILD_ROFS2SWSTING = $(call iif,$(ENABLE_SW_STRING), $(foreach type,LP, | $(call BUILD_CREATE_SW_VERSION_FILE,$(type)) | $(BUILD_CREATE_$(type)_OVERRIDE_SW_VERSION_IBY)),)
CLEAN_ROFS3SWSTING = $(call iif,$(ENABLE_SW_STRING), $(foreach type,CUSTOMER, | $(call CLEAN_CREATE_SW_VERSION_FILE,$(type)) | $(CLEAN_CREATE_$(type)_OVERRIDE_SW_VERSION_IBY)),)
BUILD_ROFS3SWSTING = $(call iif,$(ENABLE_SW_STRING), $(foreach type,CUSTOMER, | $(call BUILD_CREATE_SW_VERSION_FILE,$(type)) | $(BUILD_CREATE_$(type)_OVERRIDE_SW_VERSION_IBY)),)

CLEAN_COREPRE += $(CLEAN_CORESWSTING)
BUILD_COREPRE += $(BUILD_CORESWSTING)
CLEAN_ROFS2PRE += $(CLEAN_ROFS2SWSTING)
BUILD_ROFS2PRE += $(BUILD_ROFS2SWSTING)
CLEAN_ROFS3PRE += $(CLEAN_ROFS3SWSTING)
BUILD_ROFS3PRE += $(BUILD_ROFS3SWSTING)

CORE_OBY += $(if $(filter-out 0,$(ENABLE_SW_STRING)),$(CORE_OVERRIDE_SW_VERSION_IBY) $(MODEL_OVERRIDE_SW_VERSION_IBY),)
ROFS2_OBY += $(if $(filter-out 0,$(ENABLE_SW_STRING)),$(LP_OVERRIDE_SW_VERSION_IBY),)
ROFS3_OBY += $(if $(filter-out 0,$(ENABLE_SW_STRING)),$(CUSTOMER_OVERRIDE_SW_VERSION_IBY),)
###############################################################################
###############################################################################
###############################################################################

